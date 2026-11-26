import SwiftUI
import CoreMotion

@main
struct WatchMouseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    private let motion = CMMotionManager()

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "computermouse")
                .font(.system(size: 40))

            Text("WatchMouse")
                .font(.headline)

            Text("Ready to connect")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
