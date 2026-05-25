import Foundation

public enum WarpStatus: Sendable, Equatable {
    case connected(reason: String?, mode: String?)
    case disconnected(reason: String?, mode: String?)
    case connecting
    case disconnecting
    case unavailable(String)
    case unknown(String)

    public static func from(statusText: String, reason: String?, mode: String?) -> WarpStatus {
        let normalized = statusText.lowercased()

        if normalized.contains("disconnecting") {
            return .disconnecting
        }

        if normalized.contains("connecting") || normalized.contains("reconnecting") {
            return .connecting
        }

        if normalized.contains("connected") && !normalized.contains("disconnected") {
            return .connected(reason: reason, mode: mode)
        }

        if normalized.contains("disconnected") || normalized.contains("disabled") || normalized == "off" {
            return .disconnected(reason: reason, mode: mode)
        }

        return .unknown(statusText)
    }

    public var canToggle: Bool {
        switch self {
        case .connected, .disconnected:
            return true
        case .connecting, .disconnecting, .unknown, .unavailable:
            return false
        }
    }

    public var prefersDisconnect: Bool {
        if case .connected = self { return true }
        return false
    }
}
