import Foundation

/// Quien clasifica y delega (ADR 0004). Abierto: lo no reconocido se conserva como `.unknown`.
/// En JSON es un string simple (su `description`, el texto canónico de Markdown).
public enum Orchestrator: Sendable, Hashable, CustomStringConvertible, Codable {
    case onDevice
    case privateCloudCompute
    /// Clasifica el host de la Mac; para dispositivos sin modelo on-device.
    case host
    case claude(ModelChoice)
    case gpt(String)
    case gemini(String)
    /// Modelo local (MLX u Ollama).
    case local(String)
    case unknown(String)

    /// Interpreta el texto de una política, sin distinguir mayúsculas. Nil solo si está vacío;
    /// lo no reconocido da `.unknown(recortado)`.
    public init?(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lowered = trimmed.lowercased()
        switch lowered {
        case "on-device", "foundation models": self = .onDevice; return
        case "private cloud compute", "pcc": self = .privateCloudCompute; return
        case "host": self = .host; return
        default: break
        }
        func rest(after prefix: String) -> String? {
            guard lowered.hasPrefix(prefix) else { return nil }
            let value = trimmed.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        if let value = rest(after: "claude "), let choice = ModelChoice(parsing: value) {
            self = .claude(choice)
        } else if let value = rest(after: "gpt ") {
            self = .gpt(value)
        } else if rest(after: "gpt-") != nil {
            self = .gpt(trimmed)
        } else if let value = rest(after: "gemini ") {
            self = .gemini(value)
        } else if rest(after: "gemini-") != nil {
            self = .gemini(trimmed)
        } else if let value = rest(after: "local ") {
            self = .local(value)
        } else {
            self = .unknown(trimmed)
        }
    }

    /// Texto canónico de Markdown; `Orchestrator(parsing: o.description) == o`.
    public var description: String {
        switch self {
        case .onDevice: "on-device"
        case .privateCloudCompute: "Private Cloud Compute"
        case .host: "host"
        case .claude(let choice): "Claude \(choice)"
        case .gpt(let name): name.lowercased().hasPrefix("gpt-") ? name : "GPT \(name)"
        case .gemini(let name): name.lowercased().hasPrefix("gemini-") ? name : "Gemini \(name)"
        case .local(let name): "local \(name)"
        case .unknown(let text): text
        }
    }

    /// Falso si es `.unknown` o un `.claude` con esfuerzo desconocido.
    public var isKnown: Bool {
        switch self {
        case .unknown: false
        case .claude(let choice): choice.isKnown
        default: true
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let value = Orchestrator(parsing: text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Orquestador vacío")
        }
        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// Orquestador de dos niveles: el barato decide lo de bajo riesgo y escala al fuerte.
public struct OrchestratorPolicy: Codable, Sendable, Hashable {
    public var cheap: Orchestrator?
    public var strong: Orchestrator
    /// Acierto mínimo (0...1) para adoptar el barato.
    public var minAccuracy: Double?

    public init(cheap: Orchestrator? = nil, strong: Orchestrator, minAccuracy: Double? = nil) {
        self.cheap = cheap
        self.strong = strong
        self.minAccuracy = minAccuracy
    }
}

/// Ajustes para una clase o id de dispositivo (por ejemplo «iphone»).
public struct DeviceOverride: Codable, Sendable, Hashable {
    public var device: String
    public var roles: [Role: ModelChoice]
    public var cheapOrchestrator: Orchestrator?

    public init(device: String, roles: [Role: ModelChoice] = [:], cheapOrchestrator: Orchestrator? = nil) {
        self.device = device
        self.roles = roles
        self.cheapOrchestrator = cheapOrchestrator
    }
}
