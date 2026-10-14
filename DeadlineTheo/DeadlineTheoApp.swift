import SwiftUI
import FamilyControls

@main
struct DeadlineTheoApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 16) {
                Text("Deadline Theo").font(.title.bold())
                Text("Prototype 0.1 · Signing verification")
                Text("本次只验证安装与签名。尚未启用 App 限制。")
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
