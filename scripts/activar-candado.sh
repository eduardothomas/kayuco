#!/usr/bin/env sh
# Activa el candado de .githooks/pre-push en este clon (regla 26).
# Node: se llama solo desde "prepare" en package.json ("prepare": "sh scripts/activar-candado.sh").
# Otros stacks: correrlo una vez después de clonar.
# Fuera de un repo de git (por ejemplo, en el build del hosting) no hace nada y nunca falla.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git config core.hooksPath .githooks
fi
exit 0
