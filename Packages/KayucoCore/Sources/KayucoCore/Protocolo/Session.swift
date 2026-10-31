import Foundation

/// Sesión de un agente ACP.
public struct Session: Codable, Sendable, Hashable {
    public var id: SessionID
    /// Identificador del agente ACP, por ejemplo "opencode".
    public var agent: String
    public var title: String?
    public var workingDirectory: String
    public var state: SessionState
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: SessionID, agent: String, title: String? = nil, workingDirectory: String,
                state: SessionState, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.agent = agent
        self.title = title
        self.workingDirectory = workingDirectory
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Mensaje dentro de una sesión.
public struct Message: Codable, Sendable, Hashable {
    public var id: MessageID
    public var sessionID: SessionID
    public var role: MessageRole
    public var text: String
    public var createdAt: Date

    public init(id: MessageID, sessionID: SessionID, role: MessageRole, text: String, createdAt: Date) {
        self.id = id
        self.sessionID = sessionID
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

/// Petición de un cliente para enviar un prompt a una sesión.
public struct PromptRequest: Codable, Sendable, Hashable {
    public var sessionID: SessionID
    public var text: String

    public init(sessionID: SessionID, text: String) {
        self.sessionID = sessionID
        self.text = text
    }
}
