import Foundation
import Testing
@testable import KayucoCore

private func fixture(_ name: String) throws -> String {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Fixtures"))
    return try String(contentsOf: url, encoding: .utf8)
}

private let rolesTable = """
| Rol | Cuándo | Claude | Equivalente en otros agentes |
|---|---|---|---|
| **Explore** | a | Haiku · low | x |
| **implementador** | b | Sonnet · medium | y |
| **implementador-critico** | c | Opus · high | z |
| **revisor** | d | Opus · high | w |
"""

@Suite("Ruteo modelos")
struct RuteoModelosTests {
    @Test(arguments: [
        ("Haiku · low", "Haiku", Effort.low),
        ("Opus·HIGH", "Opus", Effort.high),
        ("  Sonnet  ·  medium ", "Sonnet", Effort.medium),
        ("Fable · xhigh", "Fable", Effort.xhigh),
    ])
    func modelChoiceValid(text: String, model: String, effort: Effort) {
        #expect(ModelChoice(parsing: text) == ModelChoice(model: model, effort: effort))
    }

    @Test(arguments: ["Opus", "Opus · turbo", " · low", "", "A · low · high"])
    func modelChoiceInvalid(text: String) {
        #expect(ModelChoice(parsing: text) == nil)
    }

    @Test func modelChoiceDescriptionAndEffortOrder() {
        #expect(ModelChoice(model: "Haiku", effort: .low).description == "Haiku · low")
        #expect(Effort.low < .medium && Effort.high < .xhigh && Effort.xhigh < .max)
    }

    @Test(arguments: [
        ("on-device", Orchestrator.onDevice),
        ("Foundation Models", .onDevice),
        ("Private Cloud Compute", .privateCloudCompute),
        ("PCC", .privateCloudCompute),
        ("host", .host),
        ("HOST", .host),
        ("Claude Haiku · low", .claude(ModelChoice(model: "Haiku", effort: .low))),
        ("GPT 5 mini", .gpt("5 mini")),
        ("Gemini Flash", .gemini("Flash")),
        ("local llama3", .local("llama3")),
    ])
    func orchestratorValid(text: String, expected: Orchestrator) {
        #expect(Orchestrator(parsing: text) == expected)
    }

    @Test(arguments: ["", "GPT", "gpt ", "Claude Haiku", "Claude ", "magia", "local"])
    func orchestratorInvalid(text: String) {
        #expect(Orchestrator(parsing: text) == nil)
    }

    @Test(arguments: [
        ("Explore", Role.explore), ("**Explore**", .explore), ("`implementador`", .implementador),
        (" **implementador-critico** ", .implementadorCritico), ("REVISOR", .revisor),
    ])
    func roleValid(text: String, expected: Role) {
        #expect(Role(name: text) == expected)
    }

    @Test(arguments: ["", "planner", "implementador critico"])
    func roleInvalid(text: String) {
        #expect(Role(name: text) == nil)
    }

    @Test func jsonRoundTrip() throws {
        let policy = try RoutingPolicyParser.parse(fixture("routing-kayuco"))
        let data = try JSONEncoder().encode(policy)
        let decoded = try JSONDecoder().decode(RoutingPolicy.self, from: data)
        #expect(decoded == policy)
        let orchestrator = Orchestrator.claude(ModelChoice(model: "Opus", effort: .high))
        let back = try JSONDecoder().decode(Orchestrator.self, from: JSONEncoder().encode(orchestrator))
        #expect(back == orchestrator)
    }

    @Test func decodingWithoutAllRolesFails() throws {
        let json = #"{"roles":[],"overrides":[]}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RoutingPolicy.self, from: Data(json.utf8))
        }
    }
}

@Suite("Ruteo fixtures")
struct RuteoFixturesTests {
    @Test func realRoutingFile() throws {
        let policy = try RoutingPolicyParser.parse(fixture("routing"))
        #expect(policy.roles.count == 4)
        #expect(policy.modelChoice(for: .explore) == ModelChoice(model: "Haiku", effort: .low))
        #expect(policy.modelChoice(for: .implementador) == ModelChoice(model: "Sonnet", effort: .medium))
        #expect(policy.modelChoice(for: .implementadorCritico) == ModelChoice(model: "Opus", effort: .high))
        #expect(policy.modelChoice(for: .revisor) == ModelChoice(model: "Opus", effort: .high))
        for rule in policy.roles.values {
            #expect(!rule.when.isEmpty)
            #expect(!rule.otherAgents.isEmpty)
        }
        #expect(policy.orchestrator == nil)
        #expect(policy.orchestrator(for: "iphone") == nil)
        #expect(policy.overrides.isEmpty)
    }

    @Test func kayucoPolicy() throws {
        let policy = try RoutingPolicyParser.parse(fixture("routing-kayuco"))
        #expect(policy.orchestrator == OrchestratorPolicy(
            cheap: .onDevice,
            strong: .claude(ModelChoice(model: "Opus", effort: .high)),
            minAccuracy: 0.9))
        #expect(policy.orchestrator(for: "iPhone")?.cheap == .host)
        #expect(policy.orchestrator(for: "mac")?.cheap == .onDevice)
        #expect(policy.orchestrator(for: nil)?.cheap == .onDevice)
        #expect(policy.modelChoice(for: .explore, device: "iphone") == ModelChoice(model: "Sonnet", effort: .low))
        #expect(policy.modelChoice(for: .explore) == ModelChoice(model: "Haiku", effort: .low))
        #expect(policy.modelChoice(for: .revisor, device: "watch") == ModelChoice(model: "Sonnet", effort: .medium))
        #expect(policy.modelChoice(for: .revisor, device: "iphone") == ModelChoice(model: "Opus", effort: .high))
        #expect(policy.overrides.map(\.device) == ["iphone", "watch"])
    }
}

@Suite("Ruteo errores")
struct RuteoErroresTests {
    private func parse(_ md: String) throws -> RoutingPolicy { try RoutingPolicyParser.parse(md) }

    @Test func missingRolesTable() {
        #expect(throws: RoutingPolicyError.missingRolesTable) { try parse("# Nada\n\ntexto") }
    }

    @Test func missingColumn() {
        #expect(throws: RoutingPolicyError.missingColumn("Claude")) {
            try parse("| Rol | Cuándo |\n|---|---|\n| Explore | x |")
        }
        let md = rolesTable + "\n\n## Overrides por dispositivo\n\n| Dispositivo | Rol |\n|---|---|\n| a | Explore |"
        #expect(throws: RoutingPolicyError.missingColumn("Valor")) { try parse(md) }
    }

    @Test func unknownRole() {
        let md = rolesTable.replacingOccurrences(of: "**revisor**", with: "**planner**")
        #expect(throws: RoutingPolicyError.unknownRole("**planner**", line: 6)) { try parse(md) }
    }

    @Test func invalidModelChoice() {
        let md = rolesTable.replacingOccurrences(of: "Sonnet · medium", with: "Sonnet")
        #expect(throws: RoutingPolicyError.invalidModelChoice("Sonnet", line: 4)) { try parse(md) }
    }

    @Test func duplicateRole() {
        let md = rolesTable + "\n| **Explore** | e | Haiku · low | x |"
        #expect(throws: RoutingPolicyError.duplicateRole(.explore, line: 7)) { try parse(md) }
    }

    @Test func missingRole() {
        let md = rolesTable.split(separator: "\n").dropLast().joined(separator: "\n")
        #expect(throws: RoutingPolicyError.missingRole(.revisor)) { try parse(md) }
    }

    @Test func invalidOrchestrator() {
        let md = rolesTable + "\n\n## Orquestador\n\n- **barato:** magia\n- **fuerte:** host"
        #expect(throws: RoutingPolicyError.invalidOrchestrator("magia", line: 10)) { try parse(md) }
    }

    @Test func missingStrongOrchestrator() {
        let md = rolesTable + "\n\n## 8. Orquestador\n\n- barato: host"
        #expect(throws: RoutingPolicyError.missingStrongOrchestrator) { try parse(md) }
    }

    @Test(arguments: ["abc", "1.5", "-0.1"])
    func invalidThreshold(value: String) {
        let md = rolesTable + "\n\n## Orquestador\n\n- **fuerte**: host\n- umbral: \(value)"
        #expect(throws: RoutingPolicyError.invalidThreshold(value, line: 11)) { try parse(md) }
    }

    @Test func overrideWithoutOrchestrator() {
        let md = rolesTable + "\n\n## Overrides por dispositivo\n\n| Dispositivo | Rol | Valor |\n|---|---|---|\n| iphone | orquestador | host |"
        #expect(throws: RoutingPolicyError.overrideWithoutOrchestrator(line: 12)) { try parse(md) }
    }

    @Test func duplicateOverride() {
        let md = rolesTable + "\n\n## Overrides por dispositivo\n\n| Dispositivo | Rol | Valor |\n|---|---|---|\n| iphone | Explore | Sonnet · low |\n| iPhone | explore | Opus · low |"
        #expect(throws: RoutingPolicyError.duplicateOverride(device: "iPhone", role: "Explore", line: 13)) {
            try parse(md)
        }
    }

    @Test func optionalColumnsAndSectionEnd() throws {
        let md = "| Rol | Claude |\n|---|---|\n| Explore | Haiku · low |\n| implementador | Sonnet · medium |\n| implementador-critico | Opus · high |\n| revisor | Opus · high |\n\n## Orquestador\n- fuerte: PCC\n# Otro\n- barato: host"
        let policy = try parse(md)
        #expect(policy.roles[.explore]?.when == "")
        #expect(policy.roles[.explore]?.otherAgents == "")
        #expect(policy.orchestrator == OrchestratorPolicy(cheap: nil, strong: .privateCloudCompute))
    }
}
