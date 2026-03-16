import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("权限") {
                NavigationLink(destination: Text("HealthKit 授权 - 待实现")) {
                    Text("HealthKit")
                }
                NavigationLink(destination: Text("通知设置 - 待实现")) {
                    Text("通知")
                }
            }

            Section("高级") {
                Text("同步 (CloudKit) - 待实现")
            }
        }
        .navigationTitle("设置")
    }
}
