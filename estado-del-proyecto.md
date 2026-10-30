# Estado del proyecto

**Proyecto:** Kayuco  
**Repositorio:** https://github.com/eduardothomas/kayuco  
**Estándar adoptado:** software-development-standard v1.10  
**Plataforma:** GitHub  
**Última actualización:** 2026-10-30 por Claude

> Léelo al iniciar cualquier sesión y actualízalo al cerrarla (regla 25 del estándar). El trabajo que aún no se integra se describe en el Traspaso de su PR.

## Resumen
Cabina nativa Apple sobre agentes de código (ACP). Arranque: visión, ADRs y base del repo listos; todavía sin código Swift. Repo hermano privado: `kayuco-apps`.

## Trabajo en curso
| Rama | PR | Quién | Estado | Siguiente paso |
|---|---|---|---|---|
| docs/vision-y-arranque | (ver PR) | Claude | en revisión | Eduardo revisa y fusiona (squash) |

## Última sesión
- **Fecha y actor:** 2026-10-30 · Claude (Fable, high), sesión en claude.ai
- **Rama / PR:** docs/vision-y-arranque
- **Hecho:** visión, 7 ADRs, README, AGENTS/CLAUDE, inventario de infraestructura, CI, candado, CONTRIBUTING (DCO), SECURITY, THIRD_PARTY_NOTICES.
- **Pruebas:** `bash scripts/check.sh` → valida documentación base (sin Package.swift aún).
- **Quedó en:** base documental completa.
- **Siguiente paso:** fase 0 en Claude Code desde la Mac personal: `Package.swift` con `KayucoCore` (protocolo host↔clientes y modelo de política de ruteo) y un host mínimo que hable ACP con OpenCode.
- **Espera a Eduardo:** fusionar este PR; comprar dominio (`kayuco.app` / `kayuco.dev`); decidir y documentar términos de proveedores (ADR 0005) antes del primer adaptador.

## Funcionalidades terminadas
- [ ] (ninguna todavía)

## Fuera del repositorio
- Repo `eduardothomas/kayuco-apps` (privado) creado el 2026-10-30.
- Dominio: pendiente de verificar y comprar.
- Xcode Cloud, App Store Connect, CloudKit: pendientes.

## Decisiones importantes
- 2026-10-30 Capa sobre agentes, no motor (ADR 0001); ACP como contrato (ADR 0002); open core Apache-2.0 + apps de pago (ADR 0003); ruteo configurable y medido (ADR 0004); sin credenciales de terceros y respeto a términos (ADR 0005); dos repos (ADR 0006); dev/prod conviviendo y compatibilidad (ADR 0007).

## Riesgos o bloqueos
- Términos de uso de suscripciones de proveedores (Anthropic restringe OAuth de suscripción en terceros): la ruta para Claude es API key u observación por hooks; revisar antes de cada adaptador (ADR 0005).
- Riesgo Apple: Xcode 27 orquesta agentes dentro de Xcode; defensa: agnóstico de IDE y stack, y presencia en iPhone/iPad/Watch.
- Alcance: muchas capacidades posibles; una historia publicada a la vez.

## Pendientes
- [ ] Fase 0 (ver `docs/vision.md`).
- [ ] `docs/proveedores.md` con el término aplicable de cada proveedor.
- [ ] Dominio y marca (DIGERPI).
- [ ] Lista de espera / TestFlight público cuando exista la app.

## Bitácora (últimas 5 sesiones)
- 2026-10-30 · Claude · docs/vision-y-arranque · Visión, ADRs y base del repo.
