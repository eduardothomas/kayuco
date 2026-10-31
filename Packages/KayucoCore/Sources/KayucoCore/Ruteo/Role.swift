import Foundation

/// Clave de codificación de un `Role`: permite `[Role: X]` como objeto JSON.
struct RoleCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// Rol de delegación de la política de ruteo (`agents/routing.md`, sección 3).
/// Abierto: un rol nuevo se conserva como `.unknown`.
public enum Role: OpenStringEnum, CodingKeyRepresentable {
    case explore, implementador, implementadorCritico, revisor
    case unknown(String)

    /// Los 4 roles que toda política debe definir.
    public static let required: [Role] = [.explore, .implementador, .implementadorCritico, .revisor]

    public var rawValue: String {
        switch self {
        case .explore: "Explore"
        case .implementador: "implementador"
        case .implementadorCritico: "implementador-critico"
        case .revisor: "revisor"
        case .unknown(let raw): raw
        }
    }

    /// Coincidencia exacta con un rol conocido; si no, `.unknown(rawValue)`.
    public init(rawValue: String) {
        self = Role.required.first { $0.rawValue == rawValue } ?? .unknown(rawValue)
    }

    /// Interpreta el nombre de una celda: quita `**`, espacios y backticks. Conocidos sin
    /// distinguir mayúsculas; si no, `.unknown(limpio)`. Nil si queda vacío.
    public init?(name: String) {
        let cleaned = name
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let lowered = cleaned.lowercased()
        self = Role.required.first { $0.rawValue.lowercased() == lowered } ?? .unknown(cleaned)
    }

    public var isKnown: Bool {
        if case .unknown = self { return false }
        return true
    }

    public var codingKey: any CodingKey { RoleCodingKey(stringValue: rawValue) }

    public init?<T: CodingKey>(codingKey: T) {
        self.init(rawValue: codingKey.stringValue)
    }
}

/// Nivel de esfuerzo. Abierto: uno nuevo se conserva como `.unknown`.
public enum Effort: OpenStringEnum {
    case low, medium, high, xhigh, max
    case unknown(String)

    /// Los esfuerzos conocidos, de menor a mayor.
    public static let known: [Effort] = [.low, .medium, .high, .xhigh, .max]

    public var rawValue: String {
        switch self {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .xhigh: "xhigh"
        case .max: "max"
        case .unknown(let raw): raw
        }
    }

    public init(rawValue: String) {
        self = Effort.known.first { $0.rawValue == rawValue } ?? .unknown(rawValue)
    }

    /// Recorta; vacío da nil; un conocido (sin distinguir mayúsculas) da ese caso; el resto, `.unknown`.
    public init?(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lowered = trimmed.lowercased()
        self = Effort.known.first { $0.rawValue == lowered } ?? .unknown(trimmed)
    }

    /// Posición entre los conocidos (mayor = más esfuerzo); nil si es desconocido.
    public var rank: Int? { Effort.known.firstIndex(of: self) }

    public var isKnown: Bool { rank != nil }
}
