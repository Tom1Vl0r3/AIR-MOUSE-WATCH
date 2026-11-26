import SwiftUI
import CoreMotion

@MainActor
final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()

    @Published var roll = 0.0
    @Published var pitch = 0.0
    @Published var yaw = 0.0
    @Published var isTracking = false

    func start() {
        guard manager.isDeviceMotionAvailable else { return }

        manager.deviceMotionUpdateInterval = 1.0 / 30.0

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion, error == nil else { return }

            Task { @MainActor in
                self?.roll = motion.attitude.roll * 180 / .pi
                self?.pitch = motion.attitude.pitch * 180 / .pi
                self?.yaw = motion.attitude.yaw * 180 / .pi
                self?.isTracking = true
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        isTracking = false
    }
}

struct ContentView: View {
    @StateObject private var motion = MotionManager()

    var body: some View {
        VStack(spacing: 8) {
            Text("WatchMouse")
                .font(.headline)

            Text(motion.isTracking ? "Tracking" : "Not tracking")
                .font(.caption)
                .foregroundStyle(motion.isTracking ? .green : .secondary)

            Text("Roll: \(motion.roll, specifier: "%.1f")°")
            Text("Pitch: \(motion.pitch, specifier: "%.1f")°")
            Text("Yaw: \(motion.yaw, specifier: "%.1f")°")

            Button(motion.isTracking ? "Stop" : "Start") {
                if motion.isTracking {
                    motion.stop()
                } else {
                    motion.start()
                }
            }
        }
        .padding()
    }
}

@main
struct WatchMouseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
