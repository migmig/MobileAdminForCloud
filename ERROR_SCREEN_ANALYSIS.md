# 오류조회 화면 개선점 분석

**분석 일자:** 2026-02-15
**분석 범위:** iOS & macOS 공통 오류 모니터링 화면

---

## 📋 목차
1. [현재 구조](#현재-구조)
2. [발견된 개선점](#발견된-개선점)
3. [우선순위별 개선안](#우선순위별-개선안)
4. [기술적 권장사항](#기술적-권장사항)

---

## 현재 구조

### 파일 구성
| 파일 | 역할 | 플랫폼 |
|------|------|--------|
| `ErrorListViewForIOS.swift` | 오류 목록 화면 | iOS |
| `ErrorSidebar.swift` | 오류 필터 & 목록 (3-column 사이드바) | macOS |
| `ErrorCloudItemView.swift` | 오류 상세 화면 (공통) | Both |
| `TraceDetailView.swift` | 스택 트레이스 분석 화면 | Both |
| `ErrorCloudListItem.swift` | 목록 아이템 렌더링 | Both |
| `ErrorCloudItem.swift` | 데이터 모델 | Both |

### 주요 기능
- ✅ 날짜 범위 기반 오류 조회
- ✅ 오류 설명 텍스트 검색
- ✅ 스택 트레이스 상세 보기 (검색, 줄바꿈, 접기 기능)
- ✅ 사용자 ID 기반 오류 추적
- ✅ 오류 삭제 기능
- ✅ 사용자 로그 다운로드 (macOS)
- ✅ macOS: 5초 자동 새로고침

---

## 발견된 개선점

### 🔴 High Priority (기능 결함)

#### 1. **요청 정보(Request Info) 표시 문제**
- **현재 상태:** `Util.formatRequestInfo()`로 포맷팅하지만 실제 결과가 명확하지 않음
- **문제:** 복잡한 JSON/QueryString이 한 줄로 표시되어 가독성 저하
- **영향:** 디버깅 시 요청 내용 파악 어려움
- **위치:** `ErrorCloudItemView.swift:34`

```swift
// 현재: 한 줄 표시
InfoRowIcon(iconName: "info.circle", title: "Request Info",
            value: Util.formatRequestInfo(errorCloudItem.requestInfo ?? ""))

// 개선 필요: 펼칠 수 있는 형태
```

#### 2. **오류 심각도(Severity) 정보 부재**
- **현재 상태:** ErrorCloudItem에 severity 필드 없음
- **문제:** 모든 오류가 동일하게 표시됨 (우선순위 없음)
- **영향:** 중대한 오류를 쉽게 놓칠 수 있음
- **필요 개선:**
  - 서버 API에서 severity 정보 받기
  - UI에서 severity별 색상 구분 (Critical, High, Medium, Low)

#### 3. **에러 중복 발생 여부 미표시**
- **현재 상태:** 같은 오류가 몇 번 발생했는지 알 수 없음
- **문제:** 한 번 발생한 오류와 100번 발생한 오류를 구별 불가
- **영향:** 오류 우선순위 판단 어려움
- **권장:** `ErrorCloudItem`에 `count` 필드 추가

---

### 🟡 Medium Priority (UX 개선)

#### 4. **정렬 및 필터링 옵션 부재**
- **현재 상태:** 기본 오류 목록만 표시 (날짜순 정렬도 수동 설정 필요)
- **문제:**
  - 최신 오류를 우선 확인하려면 직접 오류를 스크롤
  - 특정 사용자의 오류만 필터링 불가
  - 특정 오류 코드별 그룹화 없음

**개선 안:**
```
정렬 옵션:
- 날짜 (최신순 / 오래된순)
- 오류 코드
- 사용자 ID
- 발생 빈도

필터링 옵션:
- 사용자별 필터
- 오류 코드별 필터
- 심각도별 필터
```

#### 5. **iOS/macOS 기능 불일치**
- **macOS 전용 기능:**
  - 5초마다 자동 새로고침 (토글)
  - 진행도 표시 (timerProgress)
  - 로그 다운로드 버튼

- **iOS 없는 기능:**
  - 자동 새로고침 기능
  - 직접 로그 다운로드 불가 (context menu에만 있음)

- **개선:**
  - iOS에도 자동 새로고침 옵션 추가
  - 일관된 UX 제공

#### 6. **검색 기능 제한**
- **현재:** `description` 필드의 텍스트 검색만 가능
- **미지원:**
  - 오류 코드 검색
  - 사용자 ID 검색
  - 요청 URL 검색
  - 정규식(regex) 검색

**권장 개선:**
```swift
// 현재 코드
filteredErrorItems: [ErrorCloudItem] {
    if searchText.isEmpty {
        return viewModel.errorItems
    }else{
        return viewModel.errorItems.filter{
            $0.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

// 개선: 다중 필드 검색 + 필드 선택
@State private var searchField: SearchField = .description // .code, .userId, .url 등

filteredErrorItems: [ErrorCloudItem] {
    if searchText.isEmpty { return viewModel.errorItems }

    return viewModel.errorItems.filter { item in
        switch searchField {
        case .description:
            return item.description?.localizedCaseInsensitiveContains(searchText) == true
        case .code:
            return item.code?.localizedCaseInsensitiveContains(searchText) == true
        case .userId:
            return item.userId?.localizedCaseInsensitiveContains(searchText) == true
        case .url:
            return item.restUrl?.localizedCaseInsensitiveContains(searchText) == true
        case .all:
            return (item.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (item.code?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (item.userId?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                   (item.restUrl?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}
```

#### 7. **빈 상태 메시지 개선**
- **현재:** 모든 경우 "오류가 없습니다" (동일)
- **문제:** 사용자가 다음 행동을 모름
  - 조회 중인지?
  - 날짜 범위를 잘못 설정한 건 아닌지?
  - 실제로 오류가 없는 건지?

**개선:**
```swift
// 상황별 메시지 분리
if isLoading {
    EmptyStateView(systemImage: "hourglass",
                   title: "조회 중입니다...",
                   description: "잠깐만 기다려주세요")
} else if filteredErrorItems.isEmpty && !viewModel.errorItems.isEmpty {
    EmptyStateView(systemImage: "magnifyingglass.circle",
                   title: "검색 결과 없음",
                   description: "검색 조건을 변경해주세요")
} else if viewModel.errorItems.isEmpty {
    EmptyStateView(systemImage: "checkmark.shield",
                   title: "오류가 없습니다",
                   description: "조회 기간을 변경해 보세요")
}
```

---

### 🟢 Low Priority (사용성 향상)

#### 8. **대량 작업(Bulk Actions) 미지원**
- **현재:** 오류 하나씩만 삭제 가능
- **개선:**
  - 다중 선택
  - 선택된 오류 일괄 삭제
  - 선택된 오류 일괄 내보내기

#### 9. **오류 통계 대시보드 없음**
- **개선 아이디어:**
  - 일일 오류 발생 추이 그래프
  - 상위 오류 코드 목록
  - 사용자별 오류 분포
  - 요청 URL별 오류 분포

#### 10. **Request Info 전개/축소 기능**
- **현재:** 긴 QueryString/JSON이 truncated 됨
- **개선:** InfoRowIcon에 "더보기" 버튼 또는 expandable section

#### 11. **타이밍 정보 개선**
- **현재:** 등록 시간만 표시
- **개선:**
  - 오류 발생 후 경과 시간 표시 ("5분 전")
  - 사용자가 해당 오류를 본 시간

#### 12. **컨텍스트 메뉴 확장**
```swift
// 현재: Copy User ID, Log Download만 있음

// 개선 추가:
.contextMenu {
    Button("Copy User ID") { ... }
    Button("Copy Error Code") { ... }
    Button("Copy Request URL") { ... }
    Button("Copy Entire Trace") { ... }
    Divider()
    Button("Export as JSON") { ... }
    Button("Open in Browser") { ... } // URL이 있을 경우
}
```

---

## 우선순위별 개선안

### Phase 1: Critical Fixes (1-2주)
| # | 개선사항 | 예상 난이도 | 영향도 |
|---|---------|-----------|--------|
| 1 | Request Info 가독성 개선 | 중간 | 높음 |
| 2 | 빈 상태 메시지 개선 | 낮음 | 중간 |
| 3 | iOS/macOS 자동새로고침 일치 | 낮음 | 중간 |
| 4 | 검색 필드 선택 기능 추가 | 중간 | 높음 |

### Phase 2: Core Features (2-3주)
| # | 개선사항 | 예상 난이도 | 영향도 |
|---|---------|-----------|--------|
| 5 | 정렬/필터링 옵션 추가 | 중간 | 높음 |
| 6 | 에러 심각도(Severity) 필드 추가 | 높음 | 높음 |
| 7 | 에러 발생 횟수 추적 | 높음 | 높음 |
| 8 | 일괄 삭제 기능 | 중간 | 중간 |

### Phase 3: Enhancement (3-4주)
| # | 개선사항 | 예상 난이도 | 영향도 |
|---|---------|-----------|--------|
| 9 | 통계 대시보드 | 높음 | 높음 |
| 10 | Request Info 전개/축소 | 낮음 | 낮음 |
| 11 | 컨텍스트 메뉴 확장 | 낮음 | 낮음 |

---

## 기술적 권장사항

### 1. 데이터 모델 확장
```swift
struct ErrorCloudItem: Codable, Identifiable, Hashable {
    // 기존 필드
    var code: String?
    var description: String?
    var id: Int?
    var msg: String?
    var registerDt: String?
    var requestInfo: String?
    var restUrl: String?
    var traceCn: String?
    var userId: String?

    // 추가 필드 (서버에서 지원해야 함)
    var severity: ErrorSeverity? // critical, high, medium, low
    var count: Int? // 같은 오류 발생 횟수
    var lastOccurredAt: String? // 마지막 발생 시간
    var category: String? // 오류 분류
    var tags: [String]? // 오류 태그
}

enum ErrorSeverity: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}
```

### 2. 정렬/필터링 ViewModel 확장
```swift
@Published var sortBy: SortOption = .dateDescending
@Published var filterBySeverity: ErrorSeverity? = nil
@Published var filterByUserId: String? = nil
@Published var filterByCode: String? = nil

enum SortOption {
    case dateDescending, dateAscending
    case countDescending, countAscending
    case codeAscending
}

var filteredAndSortedErrors: [ErrorCloudItem] {
    var result = errorItems

    // Apply filters
    if let severity = filterBySeverity {
        result = result.filter { $0.severity == severity }
    }
    if let userId = filterByUserId {
        result = result.filter { $0.userId == userId }
    }
    if let code = filterByCode {
        result = result.filter { $0.code?.contains(code) == true }
    }

    // Apply sorting
    switch sortBy {
    case .dateDescending:
        result.sort {
            (Date(from: $0.registerDt ?? "") ?? Date.distantPast) >
            (Date(from: $1.registerDt ?? "") ?? Date.distantPast)
        }
    case .countDescending:
        result.sort { ($0.count ?? 1) > ($1.count ?? 1) }
    // ... other cases
    }

    return result
}
```

### 3. Request Info 파싱 개선
```swift
extension Util {
    // 현재: 단순 포맷팅
    // 개선: JSON 또는 QueryString 파싱 및 포매팅

    static func parseAndFormatRequestInfo(_ info: String) -> [(key: String, value: String)] {
        // JSON 형식 감지
        if let data = info.data(using: .utf8),
           let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return jsonDict.map { (key: String($0.key), value: String(describing: $0.value)) }
        }

        // QueryString 형식 감지
        if info.contains("=") && info.contains("&") {
            return info.split(separator: "&").compactMap { pair in
                let parts = pair.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (key: String(parts[0]), value: String(parts[1]))
            }
        }

        // 기타: 그대로 반환
        return [(key: "Raw", value: info)]
    }
}
```

### 4. 색상 시스템 확장 (AppDesign.swift)
```swift
extension AppColor {
    // 기존: buildStatus, pipelineStatus, deployStatus, closeDeptStatus, envType

    // 추가: 에러 심각도 색상
    static func errorSeverity(_ severity: String?) -> Color {
        switch severity {
        case "critical": return Color.red
        case "high":     return Color.orange
        case "medium":   return Color.yellow
        case "low":      return Color.blue
        default:         return Color.gray
        }
    }
}
```

### 5. TraceDetailView 개선
- **라인별 선택 및 복사:** 드래그 선택해서 선택 부분만 복사
- **파일로 내보내기:** Trace 전체를 .txt 또는 .log 파일로 저장
- **정규식 검색:** 현재 case-insensitive 텍스트만 지원하는데 regex 지원

---

## 요약 및 결론

오류조회 화면은 **기본 기능은 잘 구현**되어 있으나 다음 영역에서 개선이 필요합니다:

| 영역 | 현 상태 | 개선 필요도 |
|------|--------|-----------|
| 기본 조회 및 표시 | ✅ 좋음 | ⭐⭐ |
| 스택 트레이스 분석 | ✅ 좋음 | ⭐ |
| 검색/필터링 | ⚠️ 제한적 | ⭐⭐⭐⭐ |
| 정렬 옵션 | ❌ 없음 | ⭐⭐⭐⭐ |
| 오류 심각도 표시 | ❌ 없음 | ⭐⭐⭐⭐⭐ |
| 통계/분석 | ❌ 없음 | ⭐⭐⭐⭐ |
| iOS/macOS 일치성 | ⚠️ 부분 불일치 | ⭐⭐⭐ |
| 요청 정보 표시 | ⚠️ 가독성 낮음 | ⭐⭐⭐⭐ |

**권장 개선 순서:**
1. **Request Info 가독성** (빠른 개선, 높은 영향)
2. **검색 필드 선택** (중간 난이도, 높은 영향)
3. **오류 심각도** (서버 연동 필요, 높은 영향)
4. **정렬/필터링** (중간 난이도, 높은 영향)
5. **통계 대시보드** (장기 프로젝트, 높은 영향)

