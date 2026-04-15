# Harvest Protocol — Sesiones Importantes

**Versión:** 1.0
**Fecha:** 2026-04-14

---

## Propósito

Este protocolo define cuándo, cómo y quién es responsable de cosechar sesiones
de agentes externos al subsistema Sesiones Importantes. Es vinculante para todos
los agentes (Claude, Codex, Cowork) y para el usuario/owner del proyecto.

---

## Reglas

### R1 — Toda sesión significativa debe cosecharse

Una sesión es significativa si:
- Resultó en cambios al código o a documentos del proyecto
- Incluye decisiones de arquitectura, diseño o priorización
- Resolvió un problema o incidente
- Produjo un handoff para otro agente
- El usuario lo indica explícitamente

### R2 — Ventana de cosecha para Claude Code: 25 días

Las sesiones de Claude Code se auto-eliminan a los 30 días. El protocolo exige cosecharlas
antes del día 25 para garantizar un margen de seguridad.

### R3 — Codex: cosechar antes de cada nueva sesión

Las sesiones de Codex no se auto-eliminan, pero pueden ser muy grandes (50–500MB).
Antes de iniciar una nueva sesión de Codex, verificar que la sesión anterior esté cosechada.

### R4 — El script es la fuente de verdad operacional

Los registros manuales en `docs/sessions/records/` son curación humana.
El harvest automatizado en `docs/sessions/archive/` es la fuente técnica completa.
Ambos deben existir para sesiones importantes.

### R5 — No modificar archivos en archive/ manualmente

Los archivos en `docs/sessions/archive/` son generados por el script. Solo el script
los modifica. Las notas editoriales van en `docs/sessions/records/`.

---

## Proceso estándar (paso a paso)

### Al finalizar una sesión de trabajo

```bash
# 1. Desde el directorio del proyecto
cd /Users/Shared/Pruebas/CloneWatch

# 2. Cosechar el agente de la sesión actual
tools/sessions/harvest-sessions.sh --agent {claude-code|codex|claude-cowork}

# 3. Verificar que se generó la entrada
tools/sessions/harvest-sessions.sh --status

# 4. Si hay cambios en archive/, incluirlos en el commit de cierre de sesión
git add docs/sessions/archive/ docs/sessions/index.md
git commit -m "docs(sessions): harvest {agent} session {date}"
```

### Cosecha de emergencia (sesión de Claude Code cerca del día 25)

```bash
# Ver todas las sesiones en ~/.claude/projects/
ls -lt ~/.claude/projects/-Users-Shared-Pruebas-CloneWatch--claude-worktrees-ecstatic-noether/

# Cosechar todas las que no estén en archive aún
tools/sessions/harvest-sessions.sh --agent claude-code

# Opcional: copiar raw para preservación permanente
cp ~/.claude/projects/.../{uuid}.jsonl ~/Documents/clonewatch-sessions-permanent/
```

### Cosecha periódica mensual

```bash
# Primer lunes de cada mes — cosechar todo
tools/sessions/harvest-sessions.sh

# Verificar status
tools/sessions/harvest-sessions.sh --status

# Commit los nuevos archives
git add docs/sessions/archive/ docs/sessions/index.md
git commit -m "docs(sessions): monthly session harvest"
```

---

## Responsabilidades

| Quién | Qué |
|-------|-----|
| Claude Code | Ejecutar harvest al final de cada sesión propia |
| Codex | Ejecutar harvest antes de cerrar su sesión (incluye la sesión actual) |
| Usuario | Exportar Claude Chat periódicamente (Settings > Privacy) |
| Cualquier agente | Alertar si detecta sesiones de Claude Code con más de 20 días de antigüedad |

---

## Qué hacer si el script falla

1. **Leer el error** — el script emite mensajes descriptivos.
2. **Verificar dependencias:** `jq`, `python3`, `bash` deben estar disponibles.
3. **Verificar paths:** Los directorios fuente deben existir.
4. **Fallback manual:** Si el script falla, copiar manualmente:
   ```bash
   mkdir -p docs/sessions/archive/YYYY-MM-DD/manual-{agent}-{date}/
   # Copiar el archivo de sesión y crear metadata.json manualmente
   # Ver schema en docs/sessions/protocols/format-registry.md
   ```
5. **Reportar el problema** como un issue en el proyecto.
