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

    @Test(arguments: ["Opus", "Opus · ", " · low", "", "A · low · high"])
    func modelChoiceInvalid(text: String) {
        #expect(ModelChoice(parsing: text) == nil)
    }

    @Test func modelChoiceDescriptionAndEffortOrder() {
        #expect(ModelChoice(model: "Haiku", effort: .low).description == "Haiku · low")
        #expect(Effort.low.rank! < Effort.medium.rank! && Effort.xhigh.rank! < Effort.max.rank!)
        #expect(Effort.unknown("turbo").rank == nil && !Effort.unknown("turbo").isKnown)
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
        ("GPT-5 mini", .gpt("GPT-5 mini")),
        ("Gemini-2.5-flash", .gemini("Gemini-2.5-flash")),
        ("Gemini Flash", .gemini("Flash")),
        ("local llama3", .local("llama3")),
    ])
    func orchestratorValid(text: String, expected: Orchestrator) {
        #expect(Orchestrator(parsing: text) == expected)
    }

    @Test(arguments: ["", "   "])
    func orchestratorEmpty(text: String) {
        #expect(Orchestrator(parsing: text) == nil)
    }

    @Test(arguments: ["GPT", "Claude Haiku", "Claude", "magia", "local", "gpt-", "Mistral Large"])
    func orchestratorUnknown(text: String) {
        #expect(Orchestrator(parsing: text) == .unknown(text))
        #expect(Orchestrator(parsing: text)?.isKnown == false)
    }

    @Test func orchestratorUnknownEffort() {
        let parsed = Orchestrator(parsing: "Claude Opus · ultra")
        #expect(parsed == .claude(ModelChoice(model: "Opus", effort: .unknown("ultra"))))
        #expect(parsed?.isKnown == false)
    }

    @Test(arguments: [
        Orchestrator.onDevice, .privateCloudCompute, .host,
        .claude(ModelChoice(model: "Opus", effort: .high)),
        .claude(ModelChoice(model: "Opus", effort: .unknown("ultra"))),
        .gpt("GPT-5 mini"), .gpt("5 mini"), .gemini("Gemini-2.5-flash"), .gemini("Flash"),
        .local("llama3"), .unknown("Mistral Large"),
    ])
    func orchestratorDescriptionRoundTrip(value: Orchestrator) {
        #expect(Orchestrator(parsing: value.description) == value)
    }

    @Test func modelChoiceUnknownEffort() {
        let choice = ModelChoice(parsing: "Opus · turbo")
        #expect(choice == ModelChoice(model: "Opus", effort: .unknown("turbo")))
        #expect(choice?.isKnown == false)
    }

    @Test(arguments: [("Effort", " HIGH "), ("Effort", "turbo")])
    func effortParsing(_: String, text: String) {
        let effort = Effort(parsing: text)
        #expect(effort == (text.contains("HIGH") ? .high : .unknown("turbo")))
        #expect(Effort(parsing: "  ") == nil)
    }

    @Test func roleNameUnknownAndEmpty() {
        #expect(Role(name: " **Diseñador** ") == .unknown("Diseñador"))
        #expect(Role(name: "  ") == nil)
        #expect(Role(rawValue: "explore") == .unknown("explore"))
        #expect(Role.unknown("x").isKnown == false && Role.revisor.isKnown)
    }

    @Test(arguments: [
        ("Explore", Role.explore), ("**Explore**", .explore), ("`implementador`", .implementador),
        (" **implementador-critico** ", .implementadorCritico), ("REVISOR", .revisor),
    ])
    func roleValid(text: String, expected: Role) {
        #expect(Role(name: text) == expected)
    }

    @Test(arguments: ["", "  ", "****"])
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
        let policy = try? RoutingPolicyParser.parse(md.replacingOccurrences(of: "**planner**", with: "**revisor**"))
        #expect(policy != nil)
    }

    @Test func invalidModelChoice() {
        let md = rolesTable.replacingOccurrences(of: "Sonnet · medium", with: "Sonnet")
        #expect(throws: RoutingPolicyError.invalidModelChoice("Sonnet", line: 4)) { try parse(md) }
        #expect(throws: RoutingPolicyError.invalidModelChoice("Sonnet", line: 4)) {
            try RoutingPolicyParser.parse(md, mode: .tolerant)
        }
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

    @Test func crlfMatchesLf() throws {
        let lf = try fixture("routing")
        let crlf = lf.replacingOccurrences(of: "\n", with: "\r\n")
        #expect(try RoutingPolicyParser.parse(crlf) == RoutingPolicyParser.parse(lf))
        let kayuco = try fixture("routing-kayuco")
        let cr = kayuco.replacingOccurrences(of: "\n", with: "\r")
        #expect(try RoutingPolicyParser.parse(cr) == RoutingPolicyParser.parse(kayuco))
    }

    @Test func codeFenceIsIgnored() throws {
        let md = rolesTable + "\n\n## Orquestador\n\n- fuerte: host\n```\n# ejemplo\n| a | b |\n```\n- **umbral:** 0.9\n~~~\n## Overrides por dispositivo\n~~~"
        let policy = try parse(md)
        #expect(policy.orchestrator?.minAccuracy == 0.9)
        #expect(policy.overrides.isEmpty)
    }

    private let overridesHead = "\n\n## Overrides por dispositivo\n\n"

    @Test func notesTableBeforeOverridesIsIgnored() throws {
        let md = rolesTable + "\n\n## Orquestador\n- fuerte: host" + overridesHead
            + "| Nota | Texto |\n|---|---|\n| a | b |\n\n| Dispositivo | Rol | Valor |\n|---|---|---|\n| iphone | Explore | Sonnet · low |"
        let policy = try parse(md)
        #expect(policy.overrides.map(\.device) == ["iphone"])
    }

    @Test func overridesWithoutDeviceColumn() {
        let md = rolesTable + overridesHead + "| Nota | Texto |\n|---|---|\n| a | b |"
        #expect(throws: RoutingPolicyError.missingColumn("Dispositivo")) { try parse(md) }
    }

    @Test func strayRowAfterBlankLine() {
        let md = rolesTable + overridesHead
            + "| Dispositivo | Rol | Valor |\n|---|---|---|\n| iphone | Explore | Sonnet · low |\n\n| watch | revisor | Sonnet · medium |"
        #expect(throws: RoutingPolicyError.strayTableRow(line: 14)) { try parse(md) }
    }

    @Test func strayDeviceTable() {
        let md = rolesTable + overridesHead
            + "| Dispositivo | Rol | Valor |\n|---|---|---|\n| iphone | Explore | Sonnet · low |\n\n| Dispositivo | Rol | Valor |\n|---|---|---|\n| watch | revisor | Sonnet · medium |"
        #expect(throws: RoutingPolicyError.strayTableRow(line: 14)) { try parse(md) }
    }

    @Test func emptyDevice() {
        let md = rolesTable + overridesHead
            + "| Dispositivo | Rol | Valor |\n|---|---|---|\n|  | Explore | Sonnet · low |"
        #expect(throws: RoutingPolicyError.emptyDevice(line: 12)) { try parse(md) }
    }
}


@Suite("Ruteo abiertos")
struct RuteoAbiertosTests {
    @Test func strictAndTolerantAgreeOnRealFile() throws {
        let md = try fixture("routing")
        #expect(try RoutingPolicyParser.parse(md, mode: .strict) == RoutingPolicyParser.parse(md, mode: .tolerant))
    }

    private func table(explore: String = "Haiku · low", extraRow: String = "") -> String {
        """
        | Rol | Cuándo | Claude | Equivalente |
        |---|---|---|---|
        | Explore | a | \(explore) | x |
        | implementador | b | Sonnet · medium | y |
        | implementador-critico | c | Opus · high | z |
        | revisor | d | Opus · high | w |
        \(extraRow)
        """
    }

    @Test func unknownEffortInRolesTable() throws {
        let md = table(explore: "Sonnet · ultra")
        #expect(throws: RoutingPolicyError.invalidModelChoice("Sonnet · ultra", line: 3)) { try RoutingPolicyParser.parse(md) }
        let policy = try RoutingPolicyParser.parse(md, mode: .tolerant)
        #expect(policy.modelChoice(for: .explore) == ModelChoice(model: "Sonnet", effort: .unknown("ultra")))
    }

    @Test func unknownRoleInRolesTable() throws {
        let md = table(extraRow: "| diseñador | e | Sonnet · low | v |")
        #expect(throws: RoutingPolicyError.unknownRole("diseñador", line: 7)) { try RoutingPolicyParser.parse(md) }
        let policy = try RoutingPolicyParser.parse(md, mode: .tolerant)
        #expect(policy.modelChoice(for: .unknown("diseñador")) == ModelChoice(model: "Sonnet", effort: .low))
        #expect(policy.modelChoice(for: .unknown("otro")) == nil)
    }

    @Test func unknownOrchestrator() throws {
        let md = table() + "\n\n## Orquestador\n\n- barato: Mistral Large\n- fuerte: Claude Opus · high"
        #expect(throws: RoutingPolicyError.invalidOrchestrator("Mistral Large", line: 11)) { try RoutingPolicyParser.parse(md) }
        let policy = try RoutingPolicyParser.parse(md, mode: .tolerant)
        #expect(policy.orchestrator?.cheap == .unknown("Mistral Large"))
        #expect(policy.orchestrator(for: nil)?.cheap == nil)
        #expect(policy.orchestrator(for: nil)?.strong == .claude(ModelChoice(model: "Opus", effort: .high)))
    }

    @Test func structuralErrorsApplyInTolerantMode() {
        #expect(throws: RoutingPolicyError.invalidModelChoice("Sonnet", line: 3)) {
            try RoutingPolicyParser.parse(table(explore: "Sonnet"), mode: .tolerant)
        }
        let md = table() + "\n\n## Orquestador\n\n- fuerte:"
        #expect(throws: RoutingPolicyError.invalidOrchestrator("", line: 11)) {
            try RoutingPolicyParser.parse(md, mode: .tolerant)
        }
        let missing = table().split(separator: "\n").dropLast().joined(separator: "\n")
        #expect(throws: RoutingPolicyError.missingRole(.revisor)) {
            try RoutingPolicyParser.parse(missing, mode: .tolerant)
        }
    }

    @Test func unknownInOverridesStrictAndTolerant() throws {
        let head = table() + "\n\n## Orquestador\n- fuerte: host\n- barato: on-device\n\n## Overrides por dispositivo\n\n| Dispositivo | Rol | Valor |\n|---|---|---|\n"
        let badRole = head + "| iphone | diseñador | Sonnet · low |"
        #expect(throws: RoutingPolicyError.unknownRole("diseñador", line: 17)) { try RoutingPolicyParser.parse(badRole) }
        _ = try RoutingPolicyParser.parse(badRole, mode: .tolerant)
        let badEffort = head + "| iphone | Explore | Sonnet · ultra |"
        #expect(throws: RoutingPolicyError.invalidModelChoice("Sonnet · ultra", line: 17)) { try RoutingPolicyParser.parse(badEffort) }
        let badOrch = head + "| iphone | orquestador | Mistral Large |"
        #expect(throws: RoutingPolicyError.invalidOrchestrator("Mistral Large", line: 17)) { try RoutingPolicyParser.parse(badOrch) }
    }

    @Test func resolutionFallbacks() throws {
        let rules = Dictionary(uniqueKeysWithValues: Role.required.map {
            ($0, RoleRule(role: $0, when: "w", claude: ModelChoice(model: "M", effort: .low), otherAgents: "o"))
        })
        let ultra = ModelChoice(model: "S", effort: .unknown("ultra"))
        let unknownOrch = Orchestrator.unknown("Mistral Large")
        let overrides = [DeviceOverride(device: "iphone", roles: [.explore: ultra], cheapOrchestrator: unknownOrch)]

        let p1 = try RoutingPolicy(roles: rules,
            orchestrator: OrchestratorPolicy(cheap: .onDevice, strong: .host), overrides: overrides)
        #expect(p1.modelChoice(for: .explore, device: "iphone") == ModelChoice(model: "M", effort: .low))
        #expect(p1.orchestrator(for: "iphone")?.cheap == .onDevice)

        let p2 = try RoutingPolicy(roles: rules,
            orchestrator: OrchestratorPolicy(cheap: unknownOrch, strong: .host))
        #expect(p2.orchestrator(for: nil)?.cheap == nil)

        let p3 = try RoutingPolicy(roles: rules,
            orchestrator: OrchestratorPolicy(cheap: .onDevice, strong: unknownOrch))
        #expect(p3.orchestrator(for: nil) == nil)
    }

    @Test func goldenJSON() throws {
        func rule(_ r: Role) -> RoleRule {
            RoleRule(role: r, when: "w", claude: ModelChoice(model: "Sonnet", effort: .low), otherAgents: "o")
        }
        let policy = try RoutingPolicy(
            roles: Dictionary(uniqueKeysWithValues: Role.required.map { ($0, rule($0)) }),
            orchestrator: OrchestratorPolicy(
                cheap: .onDevice, strong: .claude(ModelChoice(model: "Opus", effort: .high)), minAccuracy: 0.9),
            overrides: [DeviceOverride(
                device: "iphone", roles: [.explore: ModelChoice(model: "Sonnet", effort: .low)],
                cheapOrchestrator: .host)])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let json = try #require(String(data: encoder.encode(policy), encoding: .utf8))
        #expect(json.contains(#""orchestrator":{"cheap":"on-device","minAccuracy":0.9,"strong":"Claude Opus · high"}"#))
        #expect(json.contains(#""overrides":[{"cheapOrchestrator":"host","device":"iphone","roles":{"Explore":{"effort":"low","model":"Sonnet"}}}]"#))
        #expect(json.contains(#""roles":{"Explore":{"claude":{"effort":"low","model":"Sonnet"},"#))
        #expect(try JSONDecoder().decode(RoutingPolicy.self, from: Data(json.utf8)) == policy)
    }

    @Test func unknownValuesSurviveJSON() throws {
        let json = """
        {"roles":{"Explore":R,"implementador":R,"implementador-critico":R,"revisor":R,"diseñador":R},
         "orchestrator":{"cheap":"Mistral Large","strong":"Claude Opus · ultra"},
         "overrides":[]}
        """.replacingOccurrences(of: "R", with: #"{"claude":{"effort":"ultra","model":"X"},"otherAgents":"","role":"Explore","when":""}"#)
        let policy = try JSONDecoder().decode(RoutingPolicy.self, from: Data(json.utf8))
        #expect(policy.roles[.unknown("diseñador")] != nil)
        #expect(policy.orchestrator?.cheap == .unknown("Mistral Large"))
        let again = try JSONDecoder().decode(RoutingPolicy.self, from: JSONEncoder().encode(policy))
        #expect(again == policy)
        let text = try #require(String(data: JSONEncoder().encode(policy), encoding: .utf8))
        #expect(text.contains("Mistral Large") && text.contains("ultra") && text.contains("diseñador"))
    }

    @Test func missingRequiredRoleInJSONFails() {
        let json = #"{"roles":{"Explore":{"claude":{"effort":"low","model":"X"},"otherAgents":"","role":"Explore","when":""}},"overrides":[]}"#
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(RoutingPolicy.self, from: Data(json.utf8)) }
    }

    @Test func emptyOrchestratorStringFailsToDecode() {
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Orchestrator.self, from: Data(#""""#.utf8)) }
    }
}
