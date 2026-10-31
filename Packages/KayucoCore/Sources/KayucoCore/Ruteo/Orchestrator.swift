import Foundation

/// Quien clasifica y delega (ADR 0004).
public enum Orchestrator: Codable, Sendable, Hashable {
    case onDevice
    case privateCloudCompute
    /// Clasifica el host de la Mac; para dispositivos sin modelo on-device.
    case host
    case claude(ModelChoice)
    case gpt(String)
    case gemini(String)
    /// Modelo local (MLX u Ollama).
    case local(String)

    /// Interpreta el texto de una política, sin distinguir mayúsculas. Nil si no se reconoce.
    public init?(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed.lowercased() {
        case "on-device", "foundation models": self = .onDevice; return
        case "private cloud compute", "pcc": self = .privateCloudCompute; return
        case "host": self = .host; return
        default: break
        }
        func rest(after prefix: String) -> String? {
            guard trimmed.lowercased().hasPrefix(prefix) else { return nil }
            let value = trimmed.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        if let value = rest(after: "claude ") {
            guard let choice = ModelChoice(parsing: value) else { return nil }
            self = .claude(choice)
        } else if let value = rest(after: "gpt ") {
            self = .gpt(value)
        } else if let value = rest(after: "gemini ") {
            self = .gemini(value)
        } else if let value = rest(after: "local ") {
            self = .local(value)
        } else {
            return nil
        }
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
