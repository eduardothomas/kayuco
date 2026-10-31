/// Versión del protocolo host↔clientes (ADR 0007). Los cambios son aditivos;
/// si rompen, sube `minClient`.
public enum KayucoProtocol {
    /// Versión que habla esta build.
    public static let current = 1
    /// Versión mínima de cliente que esta build del host acepta.
    public static let minClient = 1
}

/// Entorno de la build. Un cliente dev solo ve hosts dev.
public enum BuildEnvironment: OpenStringEnum {
    case dev, prod
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .dev: "dev"
        case .prod: "prod"
        case .unknown(let raw): raw
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "dev": self = .dev
        case "prod": self = .prod
        default: self = .unknown(rawValue)
        }
    }
}
