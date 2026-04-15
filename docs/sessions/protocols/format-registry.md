# Format Registry — Sesiones Importantes

**Versión:** 1.0
**Fecha:** 2026-04-14

Este documento es el registro de todos los formatos de sesión conocidos. Cuando un agente o
herramienta cambia su formato de almacenamiento, se agrega una nueva versión aquí. Los
importers hacen referencia a este registro para detectar y manejar versiones.

---

## Principio de versionado

Cada formato tiene un `format_id` con la convención `{agente}-{tipo}-v{número}`.

- Cuando el formato cambia de forma **retrocompatible** (nuevos campos, no eliminación): se documenta como una nota en la misma versión.
- Cuando el formato cambia de forma **incompatible** (campos eliminados, estructura reorganizada): se crea una nueva versión `v{N+1}` y se marca la versión anterior como deprecated.

Los importers deben:
1. Detectar la versión del archivo (por estructura del primer registro, por path, o por metadata embed)
2. Seleccionar el parser correspondiente
3. Si la versión es desconocida, procesar en modo "best-effort" y registrar el formato como `unknown-vX`

---

## Formatos registrados

---

### claude-code-jsonl-v1

| Campo | Valor |
|-------|-------|
| Agente | Claude Code |
| Vendor | Anthropic |
| Introducido | 2026-04-14 |
| Deprecated | — |
| Path patrón | `~/.claude/projects/{project-dir}/{uuid}.jsonl` |

**Estructura de cada línea:**

```json
{
  "type": "queue-operation",
  "operation": "enqueue",
  "timestamp": "2026-04-14T17:37:48.751Z",
  "sessionId": "6e5936df-08ce-4e2a-8745-b235e0083df7",
  "content": "texto del mensaje"
}
```

**Tipos de línea conocidos:**

| `type` | Significado |
|--------|-------------|
| `queue-operation` con `operation: "enqueue"` | Mensaje del usuario |
| `assistant` | Respuesta de Claude |
| `tool_result` | Resultado de una llamada a herramienta |
| `system` | Mensaje de sistema / instrucciones |
| `summary` | Resumen compactado de contexto |

**Notas:**
- El `sessionId` es consistente a lo largo de toda la sesión.
- Los mensajes de usuario van en el campo `content` como string.
- Los bloques de herramientas van como objetos en `content`.
- Cleanup: auto-eliminados pasados `cleanupPeriodDays` (default 30). Configurable en `~/.claude/settings.json`.

**Detección:**
```bash
head -1 {file} | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print('claude-code-v1' if 'sessionId' in d else 'unknown')"
```

---

### codex-jsonl-v1

| Campo | Valor |
|-------|-------|
| Agente | ChatGPT Codex |
| Vendor | OpenAI |
| Introducido | 2026-04-14 |
| Deprecated | — |
| Path patrón | `~/.codex/sessions/YYYY/MM/DD/rollout-{timestamp}-{uuid}.jsonl` |

**Estructura de la primera línea (session_meta):**

```json
{
  "timestamp": "2026-04-14T08:17:51.629Z",
  "type": "session_meta",
  "payload": {
    "id": "019d8b11-6cb8-7290-b66a-9015d83bdd23",
    "timestamp": "2026-04-14T08:17:48.245Z",
    "cwd": "/Users/Shared/Pruebas/CloneWatch",
    "originator": "Codex Desktop",
    "cli_version": "0.119.0-alpha.28",
    "source": "vscode",
    "model_provider": "openai",
    "base_instructions": { "text": "..." }
  }
}
```

**Tipos de línea conocidos:**

| `type` | Significado |
|--------|-------------|
| `session_meta` | Primera línea — metadatos de sesión |
| `human_turn` | Mensaje del usuario |
| `assistant_turn` | Respuesta del asistente |
| `tool_call` | Llamada a herramienta (bash, file read, etc.) |
| `tool_result` | Resultado de herramienta |
| `compaction` | Evento de compactación de contexto |

**Notas:**
- Los archivos son muy grandes (50–500MB). No copiar por defecto.
- El UUID está en el path del archivo y en `payload.id` de session_meta.
- También existe `~/.codex/session_index.jsonl` con un índice liviano.
- `~/.codex/logs_2.sqlite` contiene los mismos datos en formato relacional.

**Detección:**
```bash
head -1 {file} | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print('codex-v1' if d.get('type')=='session_meta' else 'unknown')"
```

---

### claude-cowork-jsonl-v1

| Campo | Valor |
|-------|-------|
| Agente | Claude Cowork (Agent mode) |
| Vendor | Anthropic |
| Introducido | 2026-04-14 |
| Deprecated | — |
| Path patrón | `~/Library/Application Support/Claude/local-agent-mode-sessions/{id}/audit.jsonl` |

**Notas:**
- Formato exacto pendiente de documentación detallada (investigar en próxima sesión de Cowork).
- Contiene tool invocations, model outputs, y chain-of-thought.
- Los screenshots en `screenshot-*.jpg` son parte del "archivo de sesión" aunque no son JSONL.
- **Seguridad:** permisos de lectura global. Contiene chain-of-thought del modelo.

**Detección:**
- El archivo se llama `audit.jsonl` y está dentro de un directorio bajo `local-agent-mode-sessions/`.

---

### claude-chat-export-v1

| Campo | Valor |
|-------|-------|
| Agente | Claude Chat (Desktop / Web) |
| Vendor | Anthropic |
| Introducido | 2026-04-14 |
| Deprecated | — |
| Fuente | Export manual desde Settings > Privacy > Export data |
| Formato | ZIP con archivos JSON internos |

**Notas:**
- No hay archivo local automático — solo exportación manual.
- El ZIP contiene múltiples archivos JSON, uno por conversación o por período.
- Estructura interna del ZIP puede cambiar con versiones del export de Anthropic.
- No confundir con sesiones de Claude Code (que sí son locales y automáticas).

---

## Agregar un nuevo formato

Al descubrir un nuevo formato de sesión de cualquier agente:

1. **Documentar la estructura** con una muestra de 3–5 líneas del archivo real.
2. **Identificar el `format_id`**: `{agente}-{tipo}-v{N}`.
3. **Agregar entrada aquí** con todos los campos de la tabla.
4. **Actualizar `sessions-config.json`** con el `format_id` en el agente correspondiente.
5. **Actualizar el importer** si el cambio es incompatible.
6. **Marcar la versión anterior como deprecated** con fecha.

---

## Formatos desconocidos (fallback)

Si el importer encuentra un archivo que no puede identificar:
- Genera `metadata.json` con `format_id: "unknown-v0"`.
- Copia los primeros 100 lines del archivo a `dest_dir/sample.jsonl`.
- Registra un warning en el output del harvest.
- El formato queda pendiente de documentación en este registro.
