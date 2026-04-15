# Sesiones Importantes — Guía Completa

**Subsistema:** Sesiones Importantes
**Ubicación:** `docs/sessions/`
**Automatización:** `tools/sessions/harvest-sessions.sh`
**Última actualización:** 2026-04-14

---

## ¿Qué es este subsistema?

El subsistema de Sesiones Importantes es el sistema centralizado de CloneWatch para
**capturar, indexar y preservar las transcripciones y registros de todos los agentes externos**
que trabajan en el proyecto: Claude Code, Codex, Claude Cowork, ChatGPT, y cualquier
agente futuro.

### Problema que resuelve

Cada agente externo tiene memoria limitada:
- **Codex** arranca cada sesión desde cero y depende exclusivamente de lo que está en el proyecto.
- **Claude Code** auto-elimina sesiones pasados 30 días.
- **Claude Cowork** guarda audit logs con permisos globales de lectura que pueden borrarse accidentalmente.
- **Claude Chat** guarda conversaciones solo en la nube de Anthropic.

Sin este subsistema, el conocimiento generado en cada sesión se pierde. Con él, cualquier agente puede consultar lo que realmente ocurrió en sesiones anteriores, no solo lo que los documentos del proyecto dicen que ocurrió.

### Lo que hace el sistema

1. **Descubre** sesiones en los ubicaciones nativas de cada agente.
2. **Extrae** metadata estructurada (fecha, agente, duración, estadísticas de mensajes).
3. **Genera** un resumen en Markdown legible por humanos y agentes.
4. **Registra** una referencia al archivo raw (sin copiar archivos grandes por defecto).
5. **Indexa** todas las sesiones en un índice consultable.
6. **Alerta** sobre sesiones en riesgo de cleanup (Claude Code: 30 días).

---

## Guía de uso rápido

### Cosechar todas las sesiones

```bash
cd /Users/Shared/Pruebas/CloneWatch
tools/sessions/harvest-sessions.sh
```

### Ver qué agentes están registrados

```bash
tools/sessions/harvest-sessions.sh --list
```

### Cosechar solo un agente específico

```bash
tools/sessions/harvest-sessions.sh --agent claude-code
tools/sessions/harvest-sessions.sh --agent codex
tools/sessions/harvest-sessions.sh --agent claude-cowork
```

### Ver sesiones ya cosechadas

```bash
tools/sessions/harvest-sessions.sh --status
```

### Preview sin escribir nada

```bash
tools/sessions/harvest-sessions.sh --dry-run
```

### Cosechar solo desde una fecha

```bash
tools/sessions/harvest-sessions.sh --since 2026-04-14
```

---

## Dónde vive cada tipo de sesión (For Dummies)

### 1. Claude Code

**Qué es:** Las sesiones de Claude cuando trabajás con él en el terminal / Claude Desktop en modo Code.

**Dónde viven los archivos:**
```
~/.claude/projects/{nombre-proyecto}/{uuid-sesion}.jsonl
```

El nombre del proyecto reemplaza `/` por `-`. El proyecto CloneWatch está en:
```
~/.claude/projects/-Users-Shared-Pruebas-CloneWatch--claude-worktrees-ecstatic-noether/
```

**Formato:** JSONL — cada línea es un JSON con `type`, `timestamp`, `sessionId`, `content`.

**⚠ RIESGO:** Se auto-eliminan pasados **30 días**. Hay que cosechar antes de ese límite.

**Tamaño típico:** 1–10 MB por sesión.

**Cómo preservar una sesión específica:**
```bash
# Ver dónde está
ls ~/.claude/projects/-Users-Shared-Pruebas-CloneWatch--claude-worktrees-ecstatic-noether/

# Copiar a archivo permanente
cp ~/.claude/projects/.../6e5936df-...jsonl ~/Documents/clonewatch-sessions/claude-code-2026-04-14.jsonl

# Convertir a HTML legible
uvx claude-code-transcripts
```

---

### 2. ChatGPT Codex

**Qué es:** Las sesiones de Codex cuando trabaja en el repo como co-desarrollador.

**Dónde viven los archivos:**
```
~/.codex/sessions/YYYY/MM/DD/rollout-{timestamp}-{uuid}.jsonl
```

La sesión del 2026-04-14 está en:
```
~/.codex/sessions/2026/04/14/rollout-2026-04-14T02-17-48-019d8b11-6cb8-7290-b66a-9015d83bdd23.jsonl
```

**Formato:** JSONL — cada línea tiene `timestamp`, `type`, `payload`. Los tipos incluyen `session_meta`, `human_turn`, `assistant_turn`, `tool_call`, `tool_result`.

**Tamaño:** Típicamente **50–500 MB** — muy grandes. La sesión de hoy pesa 209 MB con 6365 líneas.

**⚠ NO tiene cleanup automático**, pero los archivos grandes acumulan espacio.

**Recursos adicionales:**
```
~/.codex/session_index.jsonl  — índice liviano de todas las sesiones
~/.codex/logs_2.sqlite        — base de datos SQLite con logs indexados
```

**Cómo extraer solo mensajes humanos:**
```bash
grep '"type":"human_turn"' ~/.codex/sessions/2026/04/14/rollout-*.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    d = json.loads(line)
    content = d.get('payload', {}).get('content', '')
    if isinstance(content, list):
        for c in content:
            if isinstance(c, dict) and c.get('type') == 'text':
                print('---')
                print(c.get('text', '')[:500])
                break
    else:
        print('---')
        print(str(content)[:500])
"
```

---

### 3. Claude Cowork (Agent mode)

**Qué es:** Las sesiones de Claude cuando opera en modo agente autónomo desde Claude Desktop.

**Dónde viven los archivos:**
```
~/Library/Application Support/Claude/local-agent-mode-sessions/{session-id}/
├── audit.jsonl          — transcripción completa + chain-of-thought
└── screenshot-*.jpg     — capturas tomadas durante la sesión
```

**Formato:** JSONL en `audit.jsonl` con tipos `task_start`, `tool_invocation`, `tool_result`, `model_output`.

**⚠ Seguridad:** `audit.jsonl` tiene **permisos de lectura global** — cualquier usuario del Mac puede leerlo. Contiene el chain-of-thought del modelo. Manejar con cuidado.

**⚠ Persistencia:** Los archivos persisten incluso si eliminás la sesión desde la UI de Cowork. Para eliminar completamente:
```bash
rm -rf ~/Library/Application\ Support/Claude/local-agent-mode-sessions/{session-id}/
```

---

### 4. Claude Chat (Desktop / Web)

**Qué es:** Las conversaciones de chat normal con Claude (no Code, no Cowork).

**Dónde viven:** Solo en la nube de Anthropic. **No hay archivos locales.**

**Para exportar:**
1. Abrí Claude Desktop
2. Hacé clic en tu avatar (abajo a la izquierda)
3. Settings > Privacy > Export data
4. Descargá el ZIP en las próximas 24 horas

**Luego importar al sistema:**
```bash
tools/sessions/harvest-sessions.sh --agent claude-chat --input ~/Downloads/claude-export-YYYY-MM-DD.zip
```

---

## Estructura del archivo de sesión cosechada

```
docs/sessions/archive/
└── YYYY-MM-DD/
    └── {agent-id}-{short-session-id}/
        ├── metadata.json    ← Metadata estructurada (siempre)
        ├── summary.md       ← Resumen en Markdown (siempre)
        └── raw-ref.txt      ← Referencia al archivo raw (sin copiar)
            [raw.jsonl]      ← Copia del raw (solo si --copy-raw)
```

### metadata.json (schema v1.0)

```json
{
  "schema_version": "1.0",
  "agent_id": "claude-code",
  "agent_display_name": "Claude Code",
  "format_id": "claude-code-jsonl-v1",
  "session_id": "6e5936df-...",
  "date": "2026-04-14",
  "harvested_at": "2026-04-14T22:00:00Z",
  "raw_path": "/Users/piqui/.claude/projects/.../6e5936df.jsonl",
  "raw_size": "3.5M",
  "raw_lines": 678,
  "summary_one_line": "Claude Code session — ...",
  "cleanup_risk": "HIGH — auto-deleted in 30 days"
}
```

---

## Cuándo cosechar (protocolo recomendado)

| Cuándo | Por qué |
|--------|---------|
| Al final de cada sesión de trabajo con un agente | Captura mientras el contexto está fresco |
| Antes del día 25 desde una sesión de Claude Code | Margen de 5 días antes del cleanup de 30 días |
| Antes de una sesión nueva de Codex | Asegurate de tener la sesión anterior archivada |
| Mensualmente para Codex y Cowork | Mantenimiento regular |
| Antes de un handoff importante | El agente receptor puede leer la sesión anterior |

---

## Agregar un nuevo agente (future-proof)

El sistema está diseñado para incorporar nuevos agentes sin modificar el script principal.

1. **Crear el importer script** en `tools/sessions/importers/{agent-id}.sh`
   - El script recibe `--agent-json`, `--archive-dir`, `--since`, `--repo-root`
   - Debe generar `metadata.json` y `summary.md` en `$ARCHIVE_DIR/$date/$agent-id-$short_id/`
   - Ver `importers/claude-code.sh` como ejemplo canónico

2. **Registrar el agente** en `tools/sessions/sessions-config.json`
   - Agregar una entrada en el array `agents`
   - Agregar el `format_id` en `format_registry`

3. **Documentar el formato** en `docs/sessions/importers/{agent-id}-spec.md`
   - Dónde viven los archivos
   - Estructura del JSONL / formato del archivo
   - Notas de seguridad y cleanup

4. **Probar:**
   ```bash
   tools/sessions/harvest-sessions.sh --agent {agent-id} --dry-run
   tools/sessions/harvest-sessions.sh --agent {agent-id} --since today
   ```

---

## Herramientas de terceros útiles

```bash
# Convertir sesiones de Claude Code a HTML legible
pip install claude-code-transcripts
# o sin instalar:
uvx claude-code-transcripts

# Ver sesiones de Claude Code con la API/SDK
# TypeScript: listSessions(), getSessionMessages()
# Python: list_sessions(), get_session_messages()
```

---

## Archivos relacionados

| Archivo | Propósito |
|---------|-----------|
| `tools/sessions/harvest-sessions.sh` | Script principal de cosecha |
| `tools/sessions/sessions-config.json` | Registro de agentes y formatos |
| `tools/sessions/importers/` | Importers por tipo de agente |
| `docs/sessions/index.md` | Índice auto-generado de sesiones |
| `docs/sessions/records/` | Registros manuales de sesiones importantes |
| `docs/sessions/archive/` | Sesiones cosechadas automáticamente |
| `docs/sessions/protocols/` | Protocolos e procedimientos |
| `docs/sessions/importers/` | Especificaciones de formato por agente |
| `docs/sessions/schema/` | JSON schemas |
