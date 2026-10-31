/// Versión del protocolo host↔clientes (ADR 0007). Los cambios son aditivos;
/// si rompen, sube `minClient`.
public enum KayucoProtocol {
    /// Versión que habla esta build.
    public static let current = 1
    /// Versión mínima de cliente que esta build del host acepta.
    public static let minClient = 1
}

/// Entorno de la build. Un cliente dev solo ve hosts dev.
public enum BuildEnvironment: String, Codable, Sendable, Hashable {
    case dev, prod
}
