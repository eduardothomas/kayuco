/// Datos del cliente que se presenta al host.
public struct ClientInfo: Codable, Sendable, Hashable {
    public var id: String
    public var kind: DeviceKind
    public var appVersion: String
    public var environment: BuildEnvironment

    public init(id: String, kind: DeviceKind, appVersion: String, environment: BuildEnvironment) {
        self.id = id
        self.kind = kind
        self.appVersion = appVersion
        self.environment = environment
    }
}

/// Datos del host.
public struct HostInfo: Codable, Sendable, Hashable {
    public var id: String
    public var name: String
    public var appVersion: String
    public var environment: BuildEnvironment

    public init(id: String, name: String, appVersion: String, environment: BuildEnvironment) {
        self.id = id
        self.name = name
        self.appVersion = appVersion
        self.environment = environment
    }
}

/// Saludo del cliente. En JSON `protocolVersion` va como `"protocol"`.
public struct ClientHello: Codable, Sendable, Hashable {
    public var protocolVersion: Int
    public var client: ClientInfo

    public init(protocolVersion: Int, client: ClientInfo) {
        self.protocolVersion = protocolVersion
        self.client = client
    }

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol"
        case client
    }
}

/// Saludo del host. En JSON `protocolVersion` va como `"protocol"`.
public struct HostHello: Codable, Sendable, Hashable {
    public var protocolVersion: Int
    public var minClient: Int
    public var host: HostInfo

    public init(protocolVersion: Int, minClient: Int, host: HostInfo) {
        self.protocolVersion = protocolVersion
        self.minClient = minClient
        self.host = host
    }

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol"
        case minClient
        case host
    }
}

/// Resultado de evaluar la compatibilidad entre cliente y host.
public enum HandshakeResult: Equatable, Sendable {
    case compatible(negotiated: Int)
    case clientMustUpdate(minClient: Int)
    case environmentMismatch(client: BuildEnvironment, host: BuildEnvironment)
}

public enum Handshake {
    /// Orden: entorno, versión mínima, y por último la versión negociada (el mínimo de ambas).
    public static func evaluate(client: ClientHello, host: HostHello) -> HandshakeResult {
        if client.client.environment != host.host.environment {
            return .environmentMismatch(client: client.client.environment, host: host.host.environment)
        }
        if client.protocolVersion < host.minClient {
            return .clientMustUpdate(minClient: host.minClient)
        }
        return .compatible(negotiated: min(client.protocolVersion, host.protocolVersion))
    }
}
