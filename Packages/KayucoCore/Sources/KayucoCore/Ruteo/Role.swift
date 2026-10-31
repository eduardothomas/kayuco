import Foundation

/// Rol de delegación fijo de la política de ruteo (`agents/routing.md`, sección 3).
public enum Role: String, Codable, Sendable, Hashable, CaseIterable {
    case explore = "Explore"
    case implementador = "implementador"
    case implementadorCritico = "implementador-critico"
    case revisor = "revisor"

    /// Interpreta el nombre de una celda: quita `**`, espacios y backticks; sin distinguir mayúsculas.
    public init?(name: String) {
        let cleaned = name
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let role = Role.allCases.first(where: { $0.rawValue.lowercased() == cleaned }) else {
            return nil
        }
        self = role
    }
}

/// Nivel de esfuerzo, de menor a mayor.
public enum Effort: String, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case low, medium, high, xhigh, max

    private var order: Int { Effort.allCases.firstIndex(of: self) ?? 0 }

    public static func < (lhs: Effort, rhs: Effort) -> Bool { lhs.order < rhs.order }
}
