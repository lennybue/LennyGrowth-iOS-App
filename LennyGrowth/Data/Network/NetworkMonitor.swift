import Foundation
import Network

/// Monitors network reachability and publishes connectivity state changes.
/// Uses Apple's Network framework (NWPathMonitor) — no third-party dependencies.
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.lennardbuessow.lennygrowth.network-monitor")

    enum ConnectionType {
        case wifi, cellular, ethernet, unknown

        var displayName: String {
            switch self {
            case .wifi:     return "WLAN"
            case .cellular: return "Mobilfunk"
            case .ethernet: return "Ethernet"
            case .unknown:  return "Unbekannt"
            }
        }
    }

    init() {
        start()
    }

    deinit {
        monitor.cancel()
    }

    private func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.connectionType = self.resolveType(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func resolveType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi)     { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .ethernet }
        return .unknown
    }
}
