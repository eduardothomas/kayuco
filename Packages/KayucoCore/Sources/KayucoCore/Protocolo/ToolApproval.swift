import Foundation

/// Errores del protocolo.
public enum ProtocolError: Error, Equatable, Sendable {
    case unknownOption(String)
}

/// Opción que ofrece el agente al pedir permiso.
public struct PermissionOption: Codable, Sendable, Hashable {
    public var id: String
    public var name: String
    public var kind: PermissionOptionKind

    public init(id: String, name: String, kind: PermissionOptionKind) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}

/// Solicitud de aprobación de una herramienta.
public struct ToolApprovalRequest: Codable, Sendable, Hashable {
    public var id: ApprovalID
    public var sessionID: SessionID
    public var toolName: String
    public var summary: String
    public var options: [PermissionOption]
    public var requestedAt: Date

    public init(id: ApprovalID, sessionID: SessionID, toolName: String, summary: String,
                options: [PermissionOption], requestedAt: Date) {
        self.id = id
        self.sessionID = sessionID
        self.toolName = toolName
        self.summary = summary
        self.options = options
        self.requestedAt = requestedAt
    }
}

/// Resultado de una aprobación: opción elegida o cancelada.
/// JSON: `{"outcome":"selected","optionID":"..."}` o `{"outcome":"cancelled"}`.
public enum ToolApprovalOutcome: Codable, Sendable, Hashable {
    case selected(optionID: String)
    case cancelled
    /// Resultado que esta versión no conoce (p. ej. "expired"); se conserva tal cual.
    case unknown(String)

    private enum CodingKeys: String, CodingKey {
        case outcome, optionID
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let outcome = try c.decode(String.self, forKey: .outcome)
        switch outcome {
        case "selected":
            self = .selected(optionID: try c.decode(String.self, forKey: .optionID))
        case "cancelled":
            self = .cancelled
        default:
            self = .unknown(outcome)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .selected(let optionID):
            try c.encode("selected", forKey: .outcome)
            try c.encode(optionID, forKey: .optionID)
        case .cancelled:
            try c.encode("cancelled", forKey: .outcome)
        case .unknown(let raw):
            try c.encode(raw, forKey: .outcome)
        }
    }
}

/// Decisión tomada por un cliente. `decidedBy` es el `ClientInfo.id`.
public struct ToolApprovalDecision: Codable, Sendable, Hashable {
    public var requestID: ApprovalID
    public var outcome: ToolApprovalOutcome
    public var decidedBy: String
    public var decidedAt: Date

    public init(requestID: ApprovalID, outcome: ToolApprovalOutcome, decidedBy: String, decidedAt: Date) {
        self.requestID = requestID
        self.outcome = outcome
        self.decidedBy = decidedBy
        self.decidedAt = decidedAt
    }
}

extension ToolApprovalRequest {
    /// Elige una opción; lanza `unknownOption` si no pertenece a `options`.
    public func decide(optionID: String, by clientID: String, at date: Date) throws(ProtocolError) -> ToolApprovalDecision {
        guard options.contains(where: { $0.id == optionID }) else {
            throw .unknownOption(optionID)
        }
        return ToolApprovalDecision(requestID: id, outcome: .selected(optionID: optionID),
                                    decidedBy: clientID, decidedAt: date)
    }

    /// Cancela la solicitud.
    public func cancel(by clientID: String, at date: Date) -> ToolApprovalDecision {
        ToolApprovalDecision(requestID: id, outcome: .cancelled, decidedBy: clientID, decidedAt: date)
    }
}
