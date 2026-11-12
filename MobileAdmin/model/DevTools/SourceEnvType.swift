//
//  SourceEnvType.swift
//  MobileAdmin
//
//  소스빌드/배포/파이프라인 프로젝트 이름으로 환경(운영/스테이징/DR/개발)을 구분한다.
//

import SwiftUI

enum SourceEnvType: String, CaseIterable, Identifiable {
    case prod
    case stg
    case dr
    case dev

    var id: String { rawValue }

    /// 화면 표시용 이름
    var title: String {
        switch self {
        case .prod: return "운영"
        case .stg:  return "스테이징"
        case .dr:   return "DR"
        case .dev:  return "개발"
        }
    }

    var iconName: String {
        switch self {
        case .prod: return Util.getDevTypeImg("prod")
        case .stg:  return "flag.checkered"
        case .dr:   return "externaldrive.badge.timemachine"
        case .dev:  return Util.getDevTypeImg("dev")
        }
    }

    var color: Color {
        switch self {
        case .prod: return AppColor.envType("prod")
        case .stg:  return .orange
        case .dr:   return .purple
        case .dev:  return AppColor.envType("dev")
        }
    }

    /// 프로젝트 이름으로 환경 판별
    /// - 우선순위: DR > 스테이징 > 운영 > 개발 (예: "xxx-prod-dr" 은 DR)
    /// - "dr" 은 "android" 같은 단어에 포함되지 않도록 구분자(-, _, . 공백 등)로 나눈 토큰 단위로만 비교
    static func of(_ name: String) -> SourceEnvType {
        let lower = name.lowercased()
        let tokens = lower.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)

        if tokens.contains(where: { $0.hasPrefix("dr") && $0.dropFirst(2).allSatisfy(\.isNumber) }) {
            return .dr
        }
        if lower.contains("stg") || lower.contains("stage") || lower.contains("staging") {
            return .stg
        }
        if lower.contains("prod") {
            return .prod
        }
        return .dev
    }

    /// 검색어 매칭: 이름 또는 환경 이름(운영/스테이징/DR/개발, prod/stg/dr/dev)
    static func matches(name: String, searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return true }
        if name.localizedCaseInsensitiveContains(query) { return true }
        let env = of(name)
        return env.title.localizedCaseInsensitiveContains(query)
            || env.rawValue.localizedCaseInsensitiveContains(query)
    }
}
