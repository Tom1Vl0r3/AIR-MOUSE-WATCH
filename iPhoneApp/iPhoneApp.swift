
import Foundation
import SwiftUI
import WatchConnectivity

final class PhoneConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    @Published var roll = 0.0
    @Published var pitch = 0.0
    @Published var yaw = 0.0
    @Published var connectionStatus = "Starting..."

    private var lastRoll: Double?
    private var lastPitch: Double?

    private let receiverURL = URL(string: "http://172.20.10.3:8765")!

    override init() {
        super.init()

        guard WCSession.isSupported() else {
            connectionStatus = "WatchConnectivity unavailable"
            return
        }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.connectionStatus = error == nil
                ? "Watch connection ready"
                : "Connection error"
        }
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        guard
            let newRoll = message["roll"] as? Double,
            let newPitch = message["pitch"] as? Double
        else {
            return
        }

        let newYaw = message["yaw"] as? Double ?? 0

        if let previousRoll = lastRoll,
           let previousPitch = lastPitch {

            let dx = Int((newRoll - previousRoll) * 8)
            let dy = Int((newPitch - previousPitch) * 8)

            if dx != 0 || dy != 0 {
                sendMovement(x: dx, y: dy)
            }
        }

        lastRoll = newRoll
        lastPitch = newPitch

        DispatchQueue.main.async {
            self.roll = newRoll
            self.pitch = newPitch
            self.yaw = newYaw
        }
    }

    private func sendMovement(x: Int, y: Int) {
        var request = URLRequest(url: receiverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Int] = [
            "x": x,
            "y": y
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request).resume()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}

struct ContentView: View {
    @StateObject private var connection = PhoneConnectivity()

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "computermouse")
                .font(.system(size: 45))

            Text("WatchMouse")
                .font(.largeTitle.bold())

            Text(connection.connectionStatus)
                .foregroundStyle(.secondary)

            Text("Roll: \(connection.roll, specifier: "%.1f")°")
            Text("Pitch: \(connection.pitch, specifier: "%.1f")°")
            Text("Yaw: \(connection.yaw, specifier: "%.1f")°")
        }
        .padding()
    }
}

@main
struct WatchMouseiPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
