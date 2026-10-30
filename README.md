# Kayuco

Cabina nativa Apple para trabajar con agentes de código. Ve, dirige, aprueba y mide lo que hacen OpenCode, Claude Code, Codex o cualquier agente que hable Agent Client Protocol, desde Mac, iPhone e iPad, en cualquier proyecto. Visión completa en [`docs/vision.md`](docs/vision.md).

> Estado: arranque (octubre 2026). Aún no hay código Swift; este repo contiene la visión, las decisiones y la base del proyecto.

## Inicio rápido

**Requisitos:** macOS 26 + Xcode 27 (host y menu bar); Swift 6.1 (paquetes). Linux basta para `KayucoCore`.

```bash
git clone https://github.com/eduardothomas/kayuco
cd kayuco
sh scripts/activar-candado.sh   # activa el candado pre-push (regla 26)
bash scripts/check.sh           # pruebas y build; hoy valida la documentación base
```

## Accesos

| Qué | Enlace | Se actualiza |
|---|---|---|
| Producción (releases del host) | No aplica todavía | Al etiquetar un tag en `main` (con aprobación) |
| Apps (TestFlight / App Store) | Repo privado `kayuco-apps` | — |
| CI | https://github.com/eduardothomas/kayuco/actions | En cada push y PR |
| Repositorio | https://github.com/eduardothomas/kayuco | — |
| Sitio | No aplica todavía | — |

Cuentas, recursos y secretos (sin valores): [`docs/infraestructura.md`](docs/infraestructura.md).

## Contenido del proyecto

```
docs/vision.md        qué es Kayuco, para quién, qué no es, fases
docs/adr/             decisiones registradas (una por archivo)
docs/infraestructura.md  inventario de cuentas y secretos sin valores
scripts/check.sh      comando único de validación
.github/              CI y plantilla de PR
```

Estructura prevista del código (fase 0): `Packages/KayucoCore` (protocolo host↔clientes, política de ruteo, cliente ACP), `Packages/KayucoRunners` (simulador iOS, emulador Android, navegador) y `Host/` (daemon y menu bar de Mac). Las apps de iPhone, iPad y Watch viven en `kayuco-apps`.

## Pruebas y build

```bash
bash scripts/check.sh   # swift build && swift test cuando exista Package.swift
```

## Despliegue
- Host de Mac: binario firmado y notarizado publicado en GitHub Releases y Homebrew, compilado en Xcode Cloud.
- Apps: TestFlight y App Store desde `kayuco-apps`.
- Producción solo con autorización de Eduardo.

## Flujo de cambios
Ramas de trabajo y PR según el Estándar de Desarrollo de Software de Eduardo (v1.10). Rama base `main`; squash merge. Detalles para agentes en `AGENTS.md`. Contribuciones externas: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Volver a una versión estable
Revertir el commit en `main` o reinstalar el release anterior desde GitHub Releases. Las apps siguen la regla de compatibilidad del [ADR 0007](docs/adr/0007-entornos-dev-prod-y-compatibilidad.md).

## Licencia
Apache-2.0. Avisos de terceros en [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
