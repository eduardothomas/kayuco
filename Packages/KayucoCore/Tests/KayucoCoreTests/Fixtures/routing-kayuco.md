# Política de ruteo de Kayuco

## 3. Delegación

| Rol | Cuándo | Claude | Equivalente en otros agentes |
|---|---|---|---|
| **Explore** | Leer, buscar y resumir; solo lectura | Haiku · low | el modelo más barato del proveedor |
| **implementador** | Implementar con spec clara y pruebas | Sonnet · medium | modelo medio |
| **implementador-critico** | Dinero, seguridad, concurrencia | Opus · high | modelo fuerte |
| **revisor** | Revisar un diff en contexto limpio | Opus · high | modelo fuerte, solo lectura |

## Orquestador

- **barato:** Foundation Models
- **fuerte:** Claude Opus · high
- **umbral:** 0.9

## Overrides por dispositivo

| Dispositivo | Rol | Valor |
|---|---|---|
| iphone | orquestador | host |
| iphone | Explore | Sonnet · low |
| watch | revisor | Sonnet · medium |
