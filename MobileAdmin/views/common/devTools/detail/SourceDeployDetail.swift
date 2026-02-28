import SwiftUI

struct SourceDeployDetail: View {
    @EnvironmentObject var deployViewModel: DeployViewModel
    var selectedDeploy: SourceInfoProjectInfo
    @State private var stageList: [SourceDeployStageInfoProject] = []
    @State private var historyList: [SourceDeployHistoryInfoHistoryList] = []
    @State private var scenarioList: [SourceDeployScenarioInfoProject] = []
    @State private var isConfirm: Bool = false
    @State private var isLoaded: Bool = false
    @State private var stageId: Int = 0
    @State var scenarioId: Int = 0

    var body: some View {
        List {
            Section("배포 프로젝트") {
                InfoRow(title: "명칭", value: selectedDeploy.name)
            }
            Section("Stage") {
                Picker("Stage", selection: $stageId) {
                    ForEach(stageList, id: \.id) { Text($0.name) }
                }
                .onChange(of: stageId) { _, _ in getScenario() }
            }
            Section("Scenario") {
                Picker("Scenario", selection: $scenarioId) {
                    ForEach(scenarioList, id: \.id) { Text($0.name) }
                }
            }
            Section("기능") {
                Button { getStage(); getHistory() } label: {
                    Label("재조회", systemImage: "arrow.clockwise")
                }
                Button(action: { isConfirm = true }) {
                    Label("배포 실행하기", systemImage: "paperplane.fill")
                }
                .confirmationDialog("실행확인", isPresented: $isConfirm) {
                    Button(action: { runSourceDeploy(); getHistory() }) { Text("실행확인") }
                }
            }
            Section("배포 이력") {
                if isLoaded {
                    ProgressView()
                } else {
                    ForEach(historyList, id: \.id) { item in
                        DevHistoryItem(
                            statusColor: AppColor.deployStatus(item.status),
                            status: item.status,
                            beginTime: Util.convertFromDateIntoString(item.startTime),
                            endTime: ""
                        )
                    }
                }
            }
        }
        .navigationTitle(selectedDeploy.name)
        .onChange(of: selectedDeploy.id) { _, _ in getStage(); getHistory() }
        .onAppear { getStage(); getHistory() }
    }

    func runSourceDeploy() {
        Task {
            withAnimation { isLoaded = true }
            await deployViewModel.runSourceDeploy(selectedDeploy.id, stageId, scenarioId)
            isConfirm = false
            withAnimation { isLoaded = false }
        }
    }

    func getStage() {
        Task {
            withAnimation { isLoaded = true }
            let response = await deployViewModel.fetchSourceDeployStageInfo(selectedDeploy.id)
            stageList = response.result?.stageList ?? []
            if let first = stageList.first { stageId = first.id }
            getScenario()
            withAnimation { isLoaded = false }
        }
    }

    func getScenario() {
        Task {
            let response = await deployViewModel.fetchSourceDeployScenarioInfo(selectedDeploy.id, stageId)
            scenarioList = response.result?.scenarioList ?? []
            if let first = scenarioList.first { scenarioId = first.id }
        }
    }

    func getHistory() {
        Task {
            withAnimation { isLoaded = true }
            let response = await deployViewModel.fetchSourceDeployHistoryInfo(selectedDeploy.id)
            historyList = Array((response.result?.historyList?.sorted { $0.id > $1.id } ?? []).prefix(5))
            withAnimation { isLoaded = false }
        }
    }
}

#Preview {
    SourceDeployDetail(selectedDeploy: SourceInfoProjectInfo(1138, "oauth-resource-server"))
        .environmentObject(DeployViewModel())
}
