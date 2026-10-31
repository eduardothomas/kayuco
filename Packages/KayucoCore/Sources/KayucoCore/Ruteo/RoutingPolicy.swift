/// Errores al leer una política de ruteo. Las líneas empiezan en 1 y son del archivo completo.
public enum RoutingPolicyError: Error, Equatable, Sendable {
    case missingRolesTable
    case missingColumn(String)
    case unknownRole(String, line: Int)
    case invalidModelChoice(String, line: Int)
    case duplicateRole(Role, line: Int)
    case missingRole(Role)
    case invalidOrchestrator(String, line: Int)
    case missingStrongOrchestrator
    case invalidThreshold(String, line: Int)
    case overrideWithoutOrchestrator(line: Int)
    case duplicateOverride(device: String, role: String, line: Int)
    case strayTableRow(line: Int)
    case emptyDevice(line: Int)
}

/// Política de ruteo: reglas por rol, orquestador opcional y overrides por dispositivo.
public struct RoutingPolicy: Codable, Sendable, Hashable {
    public let roles: [Role: RoleRule]
    /// Nil: no hay orquestador configurado y decide la sesión del agente.
    public let orchestrator: OrchestratorPolicy?
    public let overrides: [DeviceOverride]

    /// Lanza `missingRole` si falta alguno de los 4 roles.
    public init(
        roles: [Role: RoleRule],
        orchestrator: OrchestratorPolicy? = nil,
        overrides: [DeviceOverride] = []
    ) throws(RoutingPolicyError) {
        for role in Role.allCases where roles[role] == nil {
            throw .missingRole(role)
        }
        self.roles = roles
        self.orchestrator = orchestrator
        self.overrides = overrides
    }

    private enum CodingKeys: String, CodingKey { case roles, orchestrator, overrides }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let roles = try container.decode([Role: RoleRule].self, forKey: .roles)
        for role in Role.allCases where roles[role] == nil {
            throw DecodingError.dataCorruptedError(
                forKey: .roles, in: container, debugDescription: "Falta el rol \(role.rawValue)")
        }
        self.roles = roles
        self.orchestrator = try container.decodeIfPresent(OrchestratorPolicy.self, forKey: .orchestrator)
        self.overrides = try container.decodeIfPresent([DeviceOverride].self, forKey: .overrides) ?? []
    }

    private func override(for device: String?) -> DeviceOverride? {
        guard let device else { return nil }
        let key = device.lowercased()
        return overrides.first { $0.device.lowercased() == key }
    }

    /// Modelo y esfuerzo del rol; el override del dispositivo (si lo hay) gana sobre la regla base.
    public func modelChoice(for role: Role, device: String? = nil) -> ModelChoice {
        if let choice = override(for: device)?.roles[role] { return choice }
        // Las 4 reglas base existen por construcción (init y decodificación lo validan).
        return roles[role]!.claude
    }

    /// Orquestador base con el barato reemplazado por el del dispositivo, si lo tiene.
    public func orchestrator(for device: String? = nil) -> OrchestratorPolicy? {
        guard var base = orchestrator else { return nil }
        if let cheap = override(for: device)?.cheapOrchestrator { base.cheap = cheap }
        return base
    }
}
