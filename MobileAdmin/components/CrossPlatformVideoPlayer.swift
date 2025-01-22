//
//  VideoPlayerContainer.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/11/24.
//

import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: View {
    let videoURL: URL

    var body: some View {
        CrossPlatformVideoPlayer(videoURL: videoURL)
            .edgesIgnoringSafeArea(.all)
    }
}

#if os(iOS)
struct CrossPlatformVideoPlayer: UIViewControllerRepresentable {
    @StateObject private var viewModel = VideoPlayerViewModel()
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: videoURL)
        let controller = AVPlayerViewController()
        controller.player = player
        viewModel.observePlayerStatus(for: player)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) { }
    	
    func makeCoordinator() -> some View {
        ZStack{
            VideoPlayerView(videoURL: videoURL)
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
    }
}
#elseif os(macOS)
struct CrossPlatformVideoPlayer: NSViewRepresentable {
    @StateObject private var viewModel = VideoPlayerViewModel()
    typealias NSViewType = AVPlayerView
    let videoURL: URL
    func makeNSView(context: Context) -> AVPlayerView {
        let player = AVPlayer(url: videoURL)
        let controller = AVPlayerView()
        controller.player = player
        viewModel.observePlayerStatus(for: player)
        return controller
    }
    func updateNSView(_ nsViewController: AVPlayerView, context: Context) { }
    
    func makeCoordinator() -> some View {
        ZStack{
            VideoPlayerView(videoURL: videoURL)
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
    }
}
#endif


class VideoPlayerViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    private var playerItemStatusObserver: AnyCancellable?
    
    func observePlayerStatus(for player: AVPlayer) {
        playerItemStatusObserver = player.publisher(for: \.currentItem?.status)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        self?.isLoading = false
                    case .failed:
                        // 오류가 발생했을 때 처리할 내용
                        print("Failed to load video")
                        self?.isLoading = false
                    default:
                        self?.isLoading = true
                    }
                }
            }
    }
}
