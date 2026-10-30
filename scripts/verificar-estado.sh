#!/usr/bin/env bash
# Verifica que un PR que cambia código también actualice estado-del-proyecto.md (regla 25).
# Uso: scripts/verificar-estado.sh <rama-base>   (por ejemplo: origin/main)
# Requiere el historial de la rama base (checkout con fetch-depth 0).
set -euo pipefail

base="${1:?Indica la rama base, por ejemplo origin/main}"
estado="estado-del-proyecto.md"

cambios="$(git diff --name-only "$base"...HEAD)"

if [[ -z "$cambios" ]]; then
  echo "Sin cambios respecto a $base."
  exit 0
fi

if grep -qx "$estado" <<<"$cambios"; then
  echo "OK: $estado se actualizó en este PR."
  exit 0
fi

# Cambios solo de documentación (Markdown) no exigen actualizar el estado.
if ! grep -qv '\.md$' <<<"$cambios"; then
  echo "OK: solo cambió documentación."
  exit 0
fi

echo "ERROR: este PR cambia código pero no actualiza $estado."
echo "Actualiza la última sesión, el trabajo en curso y la bitácora (regla 25 del estándar)."
exit 1
