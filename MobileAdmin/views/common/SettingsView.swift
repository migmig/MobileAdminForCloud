
import SwiftUI

struct SettingsView: View {
    @AppStorage("serverType") var serverType: EnvironmentType = .development

    init() {
        EnvironmentConfig.current = serverType
    }

    var body: some View {
        #if os(macOS)
        SettingsDetailsView()
            .frame(minWidth: 450)
        #else
        SettingsDetailsView()
        #endif
    }
}

#Preview {
    SettingsView()
}
