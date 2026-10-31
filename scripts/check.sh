#!/usr/bin/env bash
# Comando único de validación (regla 26): candado pre-push, CI y build.
# Mismo resultado en Mac, PC y nube. Se corre desde cualquier lugar; trabaja desde la raíz del repo.
set -euo pipefail
cd "$(dirname "$0")/.."

# Documentos base y ADR numerados: siempre.
for f in README.md AGENTS.md CLAUDE.md estado-del-proyecto.md docs/vision.md docs/infraestructura.md; do
  [[ -f "$f" ]] || { echo "check.sh: falta $f" >&2; exit 1; }
done
ls docs/adr/[0-9][0-9][0-9][0-9]-*.md >/dev/null 2>&1 || { echo "check.sh: no hay ADR en docs/adr/" >&2; exit 1; }

# Cada paquete Swift en Packages/ (y uno en la raíz si algún día existe): swift build && swift test.
shopt -s nullglob
paquetes=()
[[ -f Package.swift ]] && paquetes+=(.)
for p in Packages/*/Package.swift; do paquetes+=("$(dirname "$p")"); done

if [[ ${#paquetes[@]} -eq 0 ]]; then
  echo "check.sh: documentación base completa (aún sin paquetes Swift)."
  exit 0
fi

for p in "${paquetes[@]}"; do
  echo "check.sh: $p → swift build && swift test"
  swift build --package-path "$p"
  swift test --package-path "$p"
done
echo "check.sh: todo pasó (${#paquetes[@]} paquete(s))."
