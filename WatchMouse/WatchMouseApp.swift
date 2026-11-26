
import SwiftUI
import CoreMotion
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendMotion(roll: Double, pitch: Double, yaw: Double) {
        let session = WCSession.default

        guard session.activationState == .activated,
              session.isReachable else {
            return
        }

        session.sendMessage([
            "roll": roll,
            "pitch": pitch,
            "yaw": yaw
        ], replyHandler: nil, errorHandler: nil)
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
}

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
                guard let self else { return }

                self.roll = motion.attitude.roll * 180 / .pi
                self.pitch = motion.attitude.pitch * 180 / .pi
                self.yaw = motion.attitude.yaw * 180 / .pi

                WatchConnectivityManager.shared.sendMotion(
                    roll: self.roll,
                    pitch: self.pitch,
                    yaw: self.yaw
                )
            }
        }

        isTracking = true
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
