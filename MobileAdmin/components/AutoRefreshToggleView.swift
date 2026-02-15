//
//  AutoRefreshToggleView.swift
//  MobileAdmin
//
//  자동새로고침 토글 + 진행도 표시 컴포넌트 (iOS/macOS 공용)
//

import SwiftUI

struct AutoRefreshToggleView: View {
    @Binding var isAutoRefresh: Bool
    @Binding var timerProgress: Double
    @Binding var isFetching: Bool
    var toastManager: ToastManager
    let timeInterval: Double = 0.01
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if isAutoRefresh {
                HStack {
                    GeometryReader { geometry in
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(
                                    width: CGFloat(timerProgress / 5) * geometry.size.width * 0.8,
                                    height: 12
                                )
                        }
                        .frame(height: 12)
                        .padding(.horizontal)
                    }
                    .frame(height: 12)

                    Text("자동 새로고침 진행: \(Int((timerProgress / 5) * 100))%")
                        .font(AppFont.monoDigit)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            } else {
                Spacer()
            }

            Toggle("자동 조회", isOn: $isAutoRefresh)
                .onChange(of: isAutoRefresh) { _, newValue in
                    if newValue {
                        toastManager.showToast(message: "자동 새로고침이 시작되었습니다.")
                        startAutoRefresh()
                    } else {
                        toastManager.showToast(message: "자동 새로고침이 종료되었습니다.")
                        stopAutoRefresh()
                    }
                }
        }
        .padding(AppSpacing.md)
        .onDisappear {
            stopAutoRefresh()
        }
    }

    private func startAutoRefresh() {
        timerProgress = 0
        isFetching = false
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            timerProgress += timeInterval
            if timerProgress >= 5 && !isFetching {
                isFetching = true
                timerProgress = 0
                // Caller will handle the actual refresh logic via onChange
            }
        }
    }

    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
        timerProgress = 0
        isFetching = false
    }
}

#Preview {
    AutoRefreshToggleView(
        isAutoRefresh: .constant(true),
        timerProgress: .constant(2.5),
        isFetching: .constant(false),
        toastManager: ToastManager()
    )
    .padding()
}
