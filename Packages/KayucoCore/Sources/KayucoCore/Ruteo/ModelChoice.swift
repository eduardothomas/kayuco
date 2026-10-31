import Foundation

/// Modelo y esfuerzo elegidos, por ejemplo «Haiku · low».
public struct ModelChoice: Codable, Sendable, Hashable, CustomStringConvertible {
    public var model: String
    public var effort: Effort

    public init(model: String, effort: Effort) {
        self.model = model
        self.effort = effort
    }

    /// Interpreta «Modelo · esfuerzo» (punto medio U+00B7). Nil si falta alguna parte; un esfuerzo nuevo se conserva como `.unknown`.
    public init?(parsing text: String) {
        let parts = text.split(separator: "\u{00B7}", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        let model = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty, let effort = Effort(parsing: String(parts[1])) else { return nil }
        self.init(model: model, effort: effort)
    }

    public var description: String { "\(model) · \(effort.rawValue)" }

    /// Falso si el esfuerzo es desconocido para este cliente.
    public var isKnown: Bool { effort.isKnown }
}

/// Fila de la tabla de roles.
public struct RoleRule: Codable, Sendable, Hashable {
    public var role: Role
    public var when: String
    public var claude: ModelChoice
    public var otherAgents: String

    public init(role: Role, when: String, claude: ModelChoice, otherAgents: String) {
        self.role = role
        self.when = when
        self.claude = claude
        self.otherAgents = otherAgents
    }
}
