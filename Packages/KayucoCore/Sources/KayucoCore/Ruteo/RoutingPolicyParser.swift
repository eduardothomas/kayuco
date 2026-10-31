import Foundation

/// Lee una política de ruteo desde Markdown con la forma de `agents/routing.md`.
///
/// Limitación: no se soportan `\|` escapados dentro de las celdas de las tablas.
///
/// Reglas:
/// - Se normalizan `\r\n` y `\r` a `\n` antes de leer.
/// - Las líneas dentro de bloques de código (``` o ~~~) se ignoran por completo: no cuentan
///   como encabezados, tablas ni viñetas (los números de línea se conservan).
/// - En `## Overrides por dispositivo` se usa la primera tabla con columna «Dispositivo». Si la
///   sección tiene líneas `|` pero ninguna tabla así, `missingColumn("Dispositivo")`.
/// - Cualquier línea `|` posterior a esa tabla (p. ej. tras una línea en blanco) que no pertenezca
///   a otra tabla con encabezado y fila separadora es `strayTableRow`; también lo es otra tabla
///   con columna «Dispositivo». Un encabezado `#` da por terminada la revisión.
public enum RoutingPolicyParser {
    /// `.strict` en el host al cargar o editar el archivo del usuario (detecta errores de dedo);
    /// `.tolerant` en los clientes al leer la copia sincronizada (un valor nuevo no tumba la política).
    /// Siempre se parsea de forma tolerante; `.strict` añade rechazar roles, esfuerzos y
    /// orquestadores desconocidos. Los errores estructurales aplican en ambos modos.
    public enum ParseMode: Sendable { case strict, tolerant }

    private struct Line {
        let number: Int   // base 1, del archivo completo
        let text: String  // recortado
    }

    private struct Table {
        let header: [String]
        let rows: [(line: Int, cells: [String])]
        let lastLine: Int
    }

    public static func parse(_ markdown: String, mode: ParseMode = .strict) throws(RoutingPolicyError) -> RoutingPolicy {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var fence: String?
        let lines: [Line] = normalized.split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .map { offset, raw in
                let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                let marker = text.hasPrefix("```") ? "```" : (text.hasPrefix("~~~") ? "~~~" : nil)
                if let open = fence {
                    if marker == open { fence = nil }
                    return Line(number: offset + 1, text: "")
                }
                if let marker {
                    fence = marker
                    return Line(number: offset + 1, text: "")
                }
                return Line(number: offset + 1, text: text)
            }

        let orchestratorSection = section(titled: "orquestador", in: lines)
        let overridesSection = section(titled: "overrides por dispositivo", in: lines)

        // La tabla de roles se busca fuera de la sección de overrides.
        var roleLines = lines
        if let overridesSection {
            roleLines = lines.filter { !overridesSection.contains($0.number) }
        }
        let roles = try parseRoles(tables(in: roleLines), mode)

        var orchestrator: OrchestratorPolicy?
        if let orchestratorSection {
            orchestrator = try parseOrchestrator(lines.filter { orchestratorSection.contains($0.number) }, mode)
        }

        var overrides: [DeviceOverride] = []
        if let overridesSection {
            let sectionLines = lines.filter { overridesSection.contains($0.number) }
            let found = tables(in: sectionLines)
            if let table = found.first(where: { column("dispositivo", in: $0.header) != nil }) {
                try checkStrayRows(after: table, in: sectionLines)
                overrides = try parseOverrides(table, hasOrchestrator: orchestrator != nil, mode)
            } else if sectionLines.contains(where: { $0.text.hasPrefix("|") }) {
                throw .missingColumn("Dispositivo")
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
                result.append(Table(header: cells(of: first.text), rows: rows, lastLine: block.last!.number))
            }
            block = []
        }
        for line in lines {
            if line.text.hasPrefix("|") { block.append(line) } else { flush() }
        }
        flush()
        return result
    }

    /// Lanza `strayTableRow` si tras `table` hay líneas `|` que no forman otra tabla válida.
    private static func checkStrayRows(after table: Table, in lines: [Line]) throws(RoutingPolicyError) {
        let rest = lines.filter { $0.number > table.lastLine }
        var i = 0
        while i < rest.count {
            let line = rest[i]
            if line.text.hasPrefix("#") { return }
            if line.text.hasPrefix("|") {
                var j = i
                while j < rest.count, rest[j].text.hasPrefix("|") { j += 1 }
                let block = rest[i..<j]
                let hasSeparator = block.count >= 2 && isSeparator(cells(of: block[block.startIndex + 1].text))
                if !hasSeparator || column("dispositivo", in: cells(of: line.text)) != nil {
                    throw .strayTableRow(line: line.number)
                }
                i = j
            } else {
                i += 1
            }
        }
    }

    private static func column(_ name: String, in header: [String]) -> Int? {
        header.firstIndex { $0.lowercased().replacingOccurrences(of: " ", with: "") == name }
    }

    private static func cell(_ cells: [String], _ index: Int?) -> String {
        guard let index, index < cells.count else { return "" }
        return cells[index]
    }

    // MARK: - Roles

    private static func parseRoles(_ tables: [Table], _ mode: ParseMode) throws(RoutingPolicyError) -> [Role: RoleRule] {
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
            guard let role = Role(name: roleText), role.isKnown || mode == .tolerant else {
                throw .unknownRole(roleText, line: row.line)
            }
            let claudeText = cell(row.cells, claudeColumn)
            guard let choice = ModelChoice(parsing: claudeText), choice.isKnown || mode == .tolerant else {
                throw .invalidModelChoice(claudeText, line: row.line)
            }
            if roles[role] != nil { throw .duplicateRole(role, line: row.line) }
            roles[role] = RoleRule(
                role: role, when: cell(row.cells, whenColumn), claude: choice,
                otherAgents: cell(row.cells, otherColumn))
        }
        for role in Role.required where roles[role] == nil { throw .missingRole(role) }
        return roles
    }

    // MARK: - Orquestador

    private static func parseOrchestrator(_ lines: [Line], _ mode: ParseMode) throws(RoutingPolicyError) -> OrchestratorPolicy {
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
                guard let parsed = Orchestrator(parsing: value), parsed.isKnown || mode == .tolerant else {
                    throw .invalidOrchestrator(value, line: line.number)
                }
                cheap = parsed
            case "fuerte":
                guard let parsed = Orchestrator(parsing: value), parsed.isKnown || mode == .tolerant else {
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
        _ table: Table, hasOrchestrator: Bool, _ mode: ParseMode
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
            if device.isEmpty { throw .emptyDevice(line: row.line) }
            let key = device.lowercased()
            var entry = byDevice[key] ?? DeviceOverride(device: device)

            let isOrchestrator = roleText.replacingOccurrences(of: "**", with: "")
                .trimmingCharacters(in: .whitespaces).lowercased() == "orquestador"
            if isOrchestrator {
                guard hasOrchestrator else { throw .overrideWithoutOrchestrator(line: row.line) }
                guard let parsed = Orchestrator(parsing: value), parsed.isKnown || mode == .tolerant else {
                    throw .invalidOrchestrator(value, line: row.line)
                }
                if entry.cheapOrchestrator != nil {
                    throw .duplicateOverride(device: device, role: "orquestador", line: row.line)
                }
                entry.cheapOrchestrator = parsed
            } else {
                guard let role = Role(name: roleText), role.isKnown || mode == .tolerant else {
                throw .unknownRole(roleText, line: row.line)
            }
                guard let choice = ModelChoice(parsing: value), choice.isKnown || mode == .tolerant else {
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
