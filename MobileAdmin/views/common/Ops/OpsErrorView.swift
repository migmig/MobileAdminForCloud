//
//  OpsErrorView.swift
//  MobileAdmin
//
//  운영 기능 오류 표시 — 오류 종류별 제목/설명/아이콘 매핑, 인라인 배너
//

import SwiftUI

/// 오류 → 화면 표시 문구 매핑
struct OpsErrorPresentation {
    let title: String
    let message: String
    let systemImage: String

    /// - notFoundHint: 404일 때 덧붙일 안내 (예: 사용자 로그 → 번호/경로 확인)
    init(error: Error, notFoundHint: String? = nil) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unsupportedEndpoint:
                title = "지원하지 않는 서버"
                message = "현재 연결된 서버에 이 기능이 없습니다. 환경 설정의 서버 주소를 확인하세요."
                systemImage = "exclamationmark.icloud"
            case .server(let code, let serverMessage, _):
                let detail = serverMessage ?? "HTTP 오류 \(code)"
                switch code {
                case 404:
                    title = "찾을 수 없음"
                    message = [detail, notFoundHint].compactMap { $0 }.joined(separator: "\n")
                    systemImage = "questionmark.folder"
                case 401, 403:
                    title = "인증 실패"
                    message = detail
                    systemImage = "lock.slash"
                case 400..<500:
                    title = "잘못된 요청"
                    message = detail
                    systemImage = "exclamationmark.triangle"
                default:
                    title = "서버 오류"
                    message = detail
                    systemImage = "xmark.octagon"
                }
            default:
                title = "오류"
                message = networkError.localizedDescription
                systemImage = "exclamationmark.triangle"
            }
        } else if let urlError = error as? URLError {
            title = urlError.code == .timedOut ? "응답 시간 초과" : "연결 실패"
            message = urlError.localizedDescription
            systemImage = "wifi.exclamationmark"
        } else {
            title = "오류"
            message = error.localizedDescription
            systemImage = "exclamationmark.triangle"
        }
    }

    /// 한 줄 요약 (상태 바 / 인라인 표시용)
    var summary: String { "\(title): \(message)" }
}

/// 전체 영역 오류 상태 + 다시 시도
struct OpsErrorView: View {
    let error: Error
    var notFoundHint: String? = nil
    var retry: (() -> Void)? = nil

    var body: some View {
        let presentation = OpsErrorPresentation(error: error, notFoundHint: notFoundHint)
        VStack(spacing: AppSpacing.md) {
            EmptyStateView(systemImage: presentation.systemImage,
                           title: presentation.title,
                           description: presentation.message)
            if let retry {
                Button(action: retry) {
                    Label("다시 시도", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

/// 목록 위 인라인 배너 (경고 / 오류)
struct OpsBanner: View {
    let systemImage: String
    let text: String
    var tint: Color = .orange

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(text)
                .font(AppFont.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.sm)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
    }
}

/// 작은 캡슐 태그 (예: "최근 1000줄만 표시")
struct OpsTag: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(AppFont.captionSmall)
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

extension OpsBanner {
    /// 서버 응답 base가 NAS가 아닐 때 경고
    static func nasFallback(basePath: String) -> OpsBanner {
        OpsBanner(systemImage: "externaldrive.badge.exclamationmark",
                  text: "NAS가 마운트되지 않아 서버의 로컬 경로를 표시 중입니다: \(basePath)")
    }

    static func error(_ error: Error) -> OpsBanner {
        let presentation = OpsErrorPresentation(error: error)
        return OpsBanner(systemImage: presentation.systemImage, text: presentation.summary, tint: .red)
    }
}

#Preview {
    VStack {
        OpsBanner.nasFallback(basePath: "/app/.nas/logs/mobileid")
        OpsErrorView(error: NetworkError.server(statusCode: 404, message: "Log file not found", url: ""),
                     notFoundHint: "사용자 번호와 로그 경로를 확인하세요.") {}
    }
    .padding()
}
