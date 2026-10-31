/// Enum abierto: un valor desconocido se conserva como `.unknown(raw)` para que
/// un cliente viejo no se rompa con valores nuevos y pueda reenviarlos igual.
public protocol OpenStringEnum: Codable, Sendable, Hashable {
    var rawValue: String { get }
    init(rawValue: String)
}

extension OpenStringEnum {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Tipo de dispositivo cliente.
public enum DeviceKind: OpenStringEnum {
    case mac, iphone, ipad, watch
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .mac: "mac"
        case .iphone: "iphone"
        case .ipad: "ipad"
        case .watch: "watch"
        case .unknown(let raw): raw
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "mac": self = .mac
        case "iphone": self = .iphone
        case "ipad": self = .ipad
        case "watch": self = .watch
        default: self = .unknown(rawValue)
        }
    }
}

/// Estado de una sesión de agente.
public enum SessionState: OpenStringEnum {
    case starting, running, awaitingApproval, idle, finished, failed
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .starting: "starting"
        case .running: "running"
        case .awaitingApproval: "awaitingApproval"
        case .idle: "idle"
        case .finished: "finished"
        case .failed: "failed"
        case .unknown(let raw): raw
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "starting": self = .starting
        case "running": self = .running
        case "awaitingApproval": self = .awaitingApproval
        case "idle": self = .idle
        case "finished": self = .finished
        case "failed": self = .failed
        default: self = .unknown(rawValue)
        }
    }
}

/// Quién escribió un mensaje.
public enum MessageRole: OpenStringEnum {
    case user, agent, system
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .user: "user"
        case .agent: "agent"
        case .system: "system"
        case .unknown(let raw): raw
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "user": self = .user
        case "agent": self = .agent
        case "system": self = .system
        default: self = .unknown(rawValue)
        }
    }
}

/// Tipo de opción de permiso (refleja ACP `session/request_permission`).
public enum PermissionOptionKind: OpenStringEnum {
    case allowOnce, allowAlways, rejectOnce, rejectAlways
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .allowOnce: "allow_once"
        case .allowAlways: "allow_always"
        case .rejectOnce: "reject_once"
        case .rejectAlways: "reject_always"
        case .unknown(let raw): raw
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "allow_once": self = .allowOnce
        case "allow_always": self = .allowAlways
        case "reject_once": self = .rejectOnce
        case "reject_always": self = .rejectAlways
        default: self = .unknown(rawValue)
        }
    }
}
