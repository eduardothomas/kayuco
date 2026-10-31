import Foundation

/// Codificadores del cable: fechas ISO 8601 con milisegundos (se acepta sin fracción al leer) y llaves ordenadas.
public enum KayucoWire {
    public static func makeEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
        }
        e.outputFormatting = [.sortedKeys]
        return e
    }

    public static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(raw) { return date }
            if let date = try? Date.ISO8601FormatStyle().parse(raw) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Fecha ISO 8601 inválida: \(raw)"))
        }
        return d
    }
}

private enum EnvelopeKeys: String, CodingKey {
    case type, payload
}

/// Mensajes del host a los clientes. JSON `{"type": ..., "payload": ...}`.
public enum HostMessage: Codable, Sendable, Equatable {
    case hello(HostHello)
    case sessionUpdated(Session)
    case message(Message)
    case approvalRequested(ToolApprovalRequest)
    /// Avisa a los demás dispositivos que alguien ya decidió.
    case approvalResolved(ToolApprovalDecision)
    case unknown(type: String)

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: EnvelopeKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "hello": self = .hello(try c.decode(HostHello.self, forKey: .payload))
        case "sessionUpdated": self = .sessionUpdated(try c.decode(Session.self, forKey: .payload))
        case "message": self = .message(try c.decode(Message.self, forKey: .payload))
        case "approvalRequested": self = .approvalRequested(try c.decode(ToolApprovalRequest.self, forKey: .payload))
        case "approvalResolved": self = .approvalResolved(try c.decode(ToolApprovalDecision.self, forKey: .payload))
        default: self = .unknown(type: type)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: EnvelopeKeys.self)
        switch self {
        case .hello(let p): try c.encode("hello", forKey: .type); try c.encode(p, forKey: .payload)
        case .sessionUpdated(let p): try c.encode("sessionUpdated", forKey: .type); try c.encode(p, forKey: .payload)
        case .message(let p): try c.encode("message", forKey: .type); try c.encode(p, forKey: .payload)
        case .approvalRequested(let p): try c.encode("approvalRequested", forKey: .type); try c.encode(p, forKey: .payload)
        case .approvalResolved(let p): try c.encode("approvalResolved", forKey: .type); try c.encode(p, forKey: .payload)
        case .unknown(let type): try c.encode(type, forKey: .type)
        }
    }
}

/// Mensajes de los clientes al host. JSON `{"type": ..., "payload": ...}`.
public enum ClientMessage: Codable, Sendable, Equatable {
    case hello(ClientHello)
    case sendPrompt(PromptRequest)
    case decideApproval(ToolApprovalDecision)
    case unknown(type: String)

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: EnvelopeKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "hello": self = .hello(try c.decode(ClientHello.self, forKey: .payload))
        case "sendPrompt": self = .sendPrompt(try c.decode(PromptRequest.self, forKey: .payload))
        case "decideApproval": self = .decideApproval(try c.decode(ToolApprovalDecision.self, forKey: .payload))
        default: self = .unknown(type: type)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: EnvelopeKeys.self)
        switch self {
        case .hello(let p): try c.encode("hello", forKey: .type); try c.encode(p, forKey: .payload)
        case .sendPrompt(let p): try c.encode("sendPrompt", forKey: .type); try c.encode(p, forKey: .payload)
        case .decideApproval(let p): try c.encode("decideApproval", forKey: .type); try c.encode(p, forKey: .payload)
        case .unknown(let type): try c.encode(type, forKey: .type)
        }
    }
}
