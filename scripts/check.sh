#!/usr/bin/env bash
# Comando único de validación (regla 26): candado pre-push, CI y build.
# Mismo resultado en Mac, PC y nube. Mientras no exista código Swift, valida la documentación.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f Package.swift ]]; then
  swift build
  swift test
  exit 0
fi

# Sin código todavía: verificar que los documentos base existan y que los ADR estén numerados.
for f in README.md AGENTS.md CLAUDE.md estado-del-proyecto.md docs/vision.md docs/infraestructura.md; do
  [[ -f "$f" ]] || { echo "check.sh: falta $f" >&2; exit 1; }
done
ls docs/adr/[0-9][0-9][0-9][0-9]-*.md >/dev/null 2>&1 || { echo "check.sh: no hay ADR en docs/adr/" >&2; exit 1; }
echo "check.sh: documentación base completa (aún sin Package.swift)."
