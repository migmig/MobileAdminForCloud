//
//  WebView.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 2/13/25.
//
import SwiftUI
import WebKit

#if os(macOS)
// WebView를 SwiftUI에서 사용할 수 있도록 UIViewRepresentable 구현
struct WebViewForMac: NSViewRepresentable {
    let urlString: String

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
}
#endif
