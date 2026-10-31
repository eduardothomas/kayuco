import Foundation

/// Lee una política de ruteo desde Markdown con la forma de `agents/routing.md`.
///
/// Limitación: no se soportan `\|` escapados dentro de las celdas de las tablas.
public enum RoutingPolicyParser {
    private struct Line {
        let number: Int   // base 1, del archivo completo
        let text: String  // recortado
    }

    private struct Table {
        let header: [String]
        let rows: [(line: Int, cells: [String])]
    }

    public static func parse(_ markdown: String) throws(RoutingPolicyError) -> RoutingPolicy {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .map { Line(number: $0.offset + 1, text: $0.element.trimmingCharacters(in: .whitespacesAndNewlines)) }

        let orchestratorSection = section(titled: "orquestador", in: lines)
        let overridesSection = section(titled: "overrides por dispositivo", in: lines)

        // La tabla de roles se busca fuera de la sección de overrides.
        var roleLines = lines
        if let overridesSection {
            roleLines = lines.filter { !overridesSection.contains($0.number) }
        }
        let roles = try parseRoles(tables(in: roleLines))

        var orchestrator: OrchestratorPolicy?
        if let orchestratorSection {
            orchestrator = try parseOrchestrator(lines.filter { orchestratorSection.contains($0.number) })
        }

        var overrides: [DeviceOverride] = []
        if let overridesSection {
            let sectionLines = lines.filter { overridesSection.contains($0.number) }
            if let table = tables(in: sectionLines).first {
                overrides = try parseOverrides(table, hasOrchestrator: orchestrator != nil)
            }
        }
        return try RoutingPolicy(roles: roles, orchestrator: orchestrator, overrides: overrides)
    }

    // MARK: - Secciones

    /// Rango de números de línea (sin el encabezado) de la sección de nivel 2 con ese título.
    private static func section(titled title: String, in lines: [Line]) -> ClosedRange<Int>? {
        func level(_ text: String) -> Int? {
            let hashes = text.prefix(while: { $0 == "#" }).count
            guard hashes >= 1, text.dropFirst(hashes).first == " " else { return nil }
            return hashes
        }
        guard let start = lines.firstIndex(where: { line in
            guard level(line.text) == 2 else { return false }
            var heading = line.text.dropFirst(2).drop(while: { $0 == " " })
            heading = heading.drop(while: { $0.isNumber })
            if heading.first == "." { heading = heading.dropFirst() }
            return heading.trimmingCharacters(in: .whitespaces).lowercased() == title
        }) else { return nil }
        let end = lines[(start + 1)...].first(where: { (level($0.text) ?? 3) <= 2 })?.number
            ?? (lines.last!.number + 1)
        return (lines[start].number + 1)...max(lines[start].number + 1, end - 1)
    }

    // MARK: - Tablas

    private static func cells(of text: String) -> [String] {
        var body = Substring(text)
        if body.hasPrefix("|") { body = body.dropFirst() }
        if body.hasSuffix("|") { body = body.dropLast() }
        return body.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func isSeparator(_ cells: [String]) -> Bool {
        !cells.isEmpty && cells.allSatisfy { cell in
            !cell.isEmpty && cell.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " }
        }
    }

    /// Bloques consecutivos de líneas que empiezan con `|`; el primero es el encabezado.
    private static func tables(in lines: [Line]) -> [Table] {
        var result: [Table] = []
        var block: [Line] = []
        func flush() {
            if let first = block.first {
                let rows = block.dropFirst()
                    .map { (line: $0.number, cells: cells(of: $0.text)) }
                    .filter { !isSeparator($0.cells) }
                result.append(Table(header: cells(of: first.text), rows: rows))
            }
            block = []
        }
        for line in lines {
            if line.text.hasPrefix("|") { block.append(line) } else { flush() }
        }
        flush()
        return result
    }

    private static func column(_ name: String, in header: [String]) -> Int? {
        header.firstIndex { $0.lowercased().replacingOccurrences(of: " ", with: "") == name }
    }

    private static func cell(_ cells: [String], _ index: Int?) -> String {
        guard let index, index < cells.count else { return "" }
        return cells[index]
    }

    // MARK: - Roles

    private static func parseRoles(_ tables: [Table]) throws(RoutingPolicyError) -> [Role: RoleRule] {
        let table: Table
        let roleColumn: Int
        let claudeColumn: Int
        if let found = tables.first(where: { column("rol", in: $0.header) != nil && column("claude", in: $0.header) != nil }) {
            table = found
            roleColumn = column("rol", in: found.header)!
            claudeColumn = column("claude", in: found.header)!
        } else if let partial = tables.first(where: { column("rol", in: $0.header) != nil || column("claude", in: $0.header) != nil }) {
            // Tabla con solo una de las dos columnas obligatorias.
            throw .missingColumn(column("rol", in: partial.header) == nil ? "Rol" : "Claude")
        } else {
            throw .missingRolesTable
        }
        let whenColumn = column("cuándo", in: table.header)
        let otherColumn = table.header.firstIndex { $0.lowercased().hasPrefix("equivalente") }

        var roles: [Role: RoleRule] = [:]
        for row in table.rows {
            let roleText = cell(row.cells, roleColumn)
            guard let role = Role(name: roleText) else { throw .unknownRole(roleText, line: row.line) }
            let claudeText = cell(row.cells, claudeColumn)
            guard let choice = ModelChoice(parsing: claudeText) else {
                throw .invalidModelChoice(claudeText, line: row.line)
            }
            if roles[role] != nil { throw .duplicateRole(role, line: row.line) }
            roles[role] = RoleRule(
                role: role, when: cell(row.cells, whenColumn), claude: choice,
                otherAgents: cell(row.cells, otherColumn))
        }
        for role in Role.allCases where roles[role] == nil { throw .missingRole(role) }
        return roles
    }

    // MARK: - Orquestador

    private static func parseOrchestrator(_ lines: [Line]) throws(RoutingPolicyError) -> OrchestratorPolicy {
        var cheap: Orchestrator?
        var strong: Orchestrator?
        var threshold: Double?
        for line in lines {
            guard line.text.hasPrefix("- ") || line.text.hasPrefix("* ") else { continue }
            let item = line.text.dropFirst(2)
            guard let colon = item.firstIndex(of: ":") else { continue }
            let key = item[..<colon].filter { $0 != "*" && $0 != " " }.lowercased()
            let value = item[item.index(after: colon)...]
                .drop(while: { $0 == "*" || $0 == " " })
                .trimmingCharacters(in: .whitespaces)
            switch key {
            case "barato":
                guard let parsed = Orchestrator(parsing: value) else {
                    throw .invalidOrchestrator(value, line: line.number)
                }
                cheap = parsed
            case "fuerte":
                guard let parsed = Orchestrator(parsing: value) else {
                    throw .invalidOrchestrator(value, line: line.number)
                }
                strong = parsed
            case "umbral":
                guard let number = Double(value), (0...1).contains(number) else {
                    throw .invalidThreshold(value, line: line.number)
                }
                threshold = number
            default:
                continue
            }
        }
        guard let strong else { throw .missingStrongOrchestrator }
        return OrchestratorPolicy(cheap: cheap, strong: strong, minAccuracy: threshold)
    }

    // MARK: - Overrides

    private static func parseOverrides(
        _ table: Table, hasOrchestrator: Bool
    ) throws(RoutingPolicyError) -> [DeviceOverride] {
        guard let deviceColumn = column("dispositivo", in: table.header) else { throw .missingColumn("Dispositivo") }
        guard let roleColumn = column("rol", in: table.header) else { throw .missingColumn("Rol") }
        guard let valueColumn = column("valor", in: table.header) else { throw .missingColumn("Valor") }

        var order: [String] = []
        var byDevice: [String: DeviceOverride] = [:]
        for row in table.rows {
            let device = cell(row.cells, deviceColumn)
            let roleText = cell(row.cells, roleColumn)
            let value = cell(row.cells, valueColumn)
            let key = device.lowercased()
            var entry = byDevice[key] ?? DeviceOverride(device: device)

            let isOrchestrator = roleText.replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: .whitespaces).lowercased() == "orquestador"
            if isOrchestrator {
                guard hasOrchestrator else { throw .overrideWithoutOrchestrator(line: row.line) }
                guard let parsed = Orchestrator(parsing: value) else {
                    throw .invalidOrchestrator(value, line: row.line)
                }
                if entry.cheapOrchestrator != nil {
                    throw .duplicateOverride(device: device, role: "orquestador", line: row.line)
                }
                entry.cheapOrchestrator = parsed
            } else {
                guard let role = Role(name: roleText) else { throw .unknownRole(roleText, line: row.line) }
                guard let choice = ModelChoice(parsing: value) else {
                    throw .invalidModelChoice(value, line: row.line)
                }
                if entry.roles[role] != nil {
                    throw .duplicateOverride(device: device, role: role.rawValue, line: row.line)
                }
                entry.roles[role] = choice
            }
            if byDevice[key] == nil { order.append(key) }
            byDevice[key] = entry
        }
        return order.compactMap { byDevice[$0] }
    }
}
