//
//  ErrorSidebar.swift
//  MobileAdmin
//
//  Created by mig_mac_air_m2 on 11/4/24.
//

import SwiftUI

struct ErrorSidebar: View {
    @EnvironmentObject var errorViewModel: ErrorViewModel
    @Binding var selectedErrorItem:ErrorCloudItem?
    @State private var searchText = ""
    @State var isLoading:Bool = false
    @State var dateFrom:Date = Date()
    @State var dateTo:Date = Date()
    @State var autoRefresh:Bool = false
    @State var timerProgress: Double = 0 // 슬라이더 값
    @State var timer: Timer? = nil // 타이머 객체
    @State private var isFetching: Bool = false // 자동 조회 중복 방지
    @ObservedObject var toastManager = ToastManager()
    @State private var userIdForLog: String = ""
    @State private var isDownloadingLog: Bool = false
    var timeInterval:Double = 0.01 // 타이머 간격

   var filteredErrorItems: [ErrorCloudItem] {
       if searchText.isEmpty {
           return errorViewModel.errorItems
       } else {
           let query = searchText.lowercased()
           return errorViewModel.errorItems.filter { item in
               item.description?.localizedCaseInsensitiveContains(query) == true
               || item.msg?.localizedCaseInsensitiveContains(query) == true
               || item.code?.localizedCaseInsensitiveContains(query) == true
               || item.userId?.localizedCaseInsensitiveContains(query) == true
               || item.restUrl?.localizedCaseInsensitiveContains(query) == true
           }
       }
   }

    var body: some View {
        VStack{

            SearchArea(dateFrom: $dateFrom,
                       dateTo: $dateTo,
                       isLoading: $isLoading,
                       clearAction: {searchText = ""}){
                Task{
                    await errorViewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo)
                }
            }
            .padding()
            .searchable(text: $searchText, placement: .automatic, prompt: "설명, 코드, 사용자, URL 검색")

            // 빠른 날짜 프리셋
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    DatePresetButton(label: "오늘") {
                        dateFrom = Calendar.current.startOfDay(for: Date())
                        dateTo = Date()
                        await fetchErrors()
                    }
                    DatePresetButton(label: "최근 3일") {
                        dateFrom = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                        dateTo = Date()
                        await fetchErrors()
                    }
                    DatePresetButton(label: "최근 7일") {
                        dateFrom = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        dateTo = Date()
                        await fetchErrors()
                    }
                    DatePresetButton(label: "최근 30일") {
                        dateFrom = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        dateTo = Date()
                        await fetchErrors()
                    }
                }
                .padding(.horizontal)
            }

            // MARK: - 사용자 로그 다운로드
            DisclosureGroup("사용자 로그 다운로드") {
                HStack {
                    TextField("사용자 아이디 입력", text: $userIdForLog)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { triggerUserLogDownload() }
                    Button(action: triggerUserLogDownload) {
                        if isDownloadingLog {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("다운로드", systemImage: "square.and.arrow.down.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(userIdForLog.isEmpty || isDownloadingLog)
                }
                .padding(.vertical, 4)
            }
            .padding(.horizontal)

            HStack{
                if autoRefresh{
                    HStack {
                        GeometryReader { geometry in
                            ZStack {
                                // 진행도 바
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
                        .frame(height: 12) // 고정된 높이 설정

                        // 슬라이더 설명 텍스트
                        Text("자동 새로고침 진행: \(Int((timerProgress / 5) * 100))%")
                            .font(AppFont.monoDigit)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)
                }else{
                    Spacer()
                }
                Toggle("5초마다 자동 조회", isOn: $autoRefresh)
                .onChange(of: autoRefresh) { _, newValue in
                    if newValue {
                        toastManager.showToast(message: "자동 새로고침이 시작되었습니다.")
                        startAutoRefresh()
                    } else {
                        toastManager.showToast(message: "자동 새로고침이 종료되었습니다.")
                        stopAutoRefresh()
                    }
                }
                .padding(.horizontal)
            }
            ScrollViewReader { proxy in
                List(filteredErrorItems,selection:$selectedErrorItem){entry in
                    NavigationLink(value:entry){
                        ErrorCloudListItem(errorCloudItem: entry)
                    }
                }
                .overlay {
                    if !isLoading && filteredErrorItems.isEmpty {
                        EmptyStateView(
                            systemImage: "checkmark.shield",
                            title: "오류가 없습니다",
                            description: searchText.isEmpty ? "조회 기간을 변경해 보세요" : "검색어를 변경해 보세요"
                        )
                    }
                }
                .navigationTitle("오류 조회")
                #if os(macOS)
                .navigationSubtitle(searchText.isEmpty
                    ? "  \(filteredErrorItems.count)개의 오류"
                    : "  \(filteredErrorItems.count)/\(errorViewModel.errorItems.count)개의 오류"
                )
                #endif
                .navigationSplitViewColumnWidth(min:200,ideal: 200)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .loadingTask(isLoading: $isLoading) {
                    await errorViewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo)
                }
                .onChange(of: errorViewModel.errorItems) { _, _ in
                    proxy.scrollTo(errorViewModel.errorItems.first, anchor: .top)
                }
            }
        }
    }

    private func fetchErrors() async {
        isLoading = true
        await errorViewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo)
        isLoading = false
    }

    private func triggerUserLogDownload() {
        guard !userIdForLog.isEmpty else { return }
        isDownloadingLog = true
        Task {
            do {
                let fileURL = try await errorViewModel.downloadUserLog(userIdForLog)
                #if os(macOS)
                NSWorkspace.shared.open(fileURL)
                #endif
                toastManager.showToast(message: "다운로드 완료: \(fileURL.lastPathComponent)")
            } catch {
                toastManager.showToast(message: "로그 다운로드 실패: \(userIdForLog)")
            }
            isDownloadingLog = false
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
                Task { @MainActor in
                    await errorViewModel.fetchErrors(startFrom: dateFrom, endTo: dateTo)
                    isFetching = false
                }
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
    ErrorSidebar(selectedErrorItem: .constant(nil))
        .environmentObject(ErrorViewModel())
}
