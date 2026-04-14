# Agent Onboarding Protocol — Sesiones Importantes

**Versión:** 1.0
**Fecha:** 2026-04-14

Este documento define el proceso para incorporar un nuevo tipo de agente, IDE, o app externa
al subsistema Sesiones Importantes. Aplica cuando se incorpora al proyecto cualquier herramienta
que genera sesiones de trabajo (Cursor, Gemini, Replit, Lovable, Perplexity, etc.).

---

## Checklist de onboarding para un nuevo agente

### Paso 1 — Investigar la sesión

Antes de escribir código, responder estas preguntas:

- [ ] ¿Dónde guarda sus sesiones/logs el agente? (path exacto en macOS)
- [ ] ¿Qué formato usa? (JSONL, SQLite, JSON puro, otro)
- [ ] ¿Cuál es la estructura de una línea del archivo?
- [ ] ¿Tiene cleanup automático? ¿Cada cuántos días?
- [ ] ¿El archivo puede ser grande (>50MB)? ¿Cuánto?
- [ ] ¿Hay permisos de seguridad relevantes?
- [ ] ¿Hay una API o SDK para acceder a las sesiones programáticamente?
- [ ] ¿Hay herramientas de terceros para convertir el formato?

### Paso 2 — Registrar en sessions-config.json

Agregar la entrada al array `agents` en `tools/sessions/sessions-config.json`:

```json
{
  "id": "{agent-id}",
  "display_name": "{Nombre completo}",
  "app": "{Nombre de la aplicación}",
  "vendor": "{Empresa}",
  "enabled": false,
  "source_paths": ["{ruta en macOS}"],
  "source_path_note": "{explicación del path}",
  "session_glob": "{patron glob para encontrar archivos}",
  "format_id": "{agent-id}-{tipo}-v1",
  "importer_script": "importers/{agent-id}.sh",
  "cleanup_days": null,
  "size_typical": "{rango}"
}
```

Y agregar el `format_id` al objeto `format_registry`:

```json
"{agent-id}-{tipo}-v1": {
  "description": "{descripción}",
  "line_schema": {"campo1": "tipo", "campo2": "tipo"},
  "key_types": ["tipo1", "tipo2"],
  "introduced": "{fecha}",
  "deprecated": null
}
```

### Paso 3 — Documentar el formato

Crear `docs/sessions/importers/{agent-id}-spec.md` con:

- Path donde viven los archivos
- Estructura detallada del formato (con ejemplos reales)
- Tipos de línea / eventos
- Notas de seguridad
- Cleanup policy
- Herramientas de acceso disponibles

### Paso 4 — Crear el importer script

Crear `tools/sessions/importers/{agent-id}.sh` siguiendo el template de `claude-code.sh`.

El script debe:
1. Recibir `--agent-json`, `--archive-dir`, `--since`, `--repo-root` como argumentos
2. Descubrir sesiones nuevas (no ya en archive)
3. Por cada sesión: crear `$dest_dir/{fecha}/{agent-id}-{short_id}/`
4. Generar `metadata.json` con schema v1.0
5. Generar `summary.md` en Markdown legible
6. Generar `raw-ref.txt` con referencia al archivo original
7. (Opcional) Copiar raw si `--copy-raw` está presente
8. Emitir `echo "[{agent-id}] Harvested: {short_id}"` por sesión procesada
9. Exit 0 en éxito, Exit 1 en error

### Paso 5 — Probar

```bash
# Test en modo dry-run
tools/sessions/harvest-sessions.sh --agent {agent-id} --dry-run

# Test real con fecha específica
tools/sessions/harvest-sessions.sh --agent {agent-id} --since {fecha}

# Verificar que el status muestra la sesión
tools/sessions/harvest-sessions.sh --status
```

### Paso 6 — Habilitar en producción

Una vez que el importer funciona correctamente, cambiar `"enabled": true` en `sessions-config.json`.

### Paso 7 — Documentar en CLAUDE.md

Agregar una nota en `CLAUDE.md` indicando que el nuevo agente está en el proyecto y cómo cosechar sus sesiones.

---

## Template de importer script

```bash
#!/usr/bin/env bash
# =============================================================================
# importers/{agent-id}.sh — {Agent Name} session importer
# =============================================================================
# Discovers {Agent} sessions in {source_path} and generates structured
# summaries for the Sesiones Importantes subsystem.
#
# Format: {format_id}
# Source: {path_pattern}
# =============================================================================

set -euo pipefail

ARCHIVE_DIR="" SINCE="" REPO_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-json) shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

TODAY="$(date -u +%Y-%m-%d)"
SOURCE_DIR="{source_path}"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "[{agent-id}] Source not found: $SOURCE_DIR — skipping."
  exit 0
fi

HARVESTED=0

# TODO: discover sessions, iterate, generate metadata.json + summary.md

echo "[{agent-id}] Total harvested: $HARVESTED session(s)"
```

---

## Decisiones de diseño (para entender el sistema)

**¿Por qué scripts shell y no Python?**
Los shell scripts no tienen dependencias externas más allá de `bash`, `jq`, y `python3` (para parsing JSON). Todos estos existen en cualquier Mac con Xcode Command Line Tools. Un script Python requeriría un entorno virtual o instalación global.

**¿Por qué no copiar los archivos raw por defecto?**
Las sesiones de Codex pueden pesar 500MB. Copiarlas todas al repo o incluso a un directorio de archive local llenaría el disco rápidamente. La política es: guardar referencia + summary, y copiar raw solo cuando explícitamente necesario (`--copy-raw`).

**¿Por qué formato_id versionado?**
Los agentes externos pueden cambiar su formato de almacenamiento sin previo aviso. Al versionar los formatos, podemos detectar cambios y actualizar solo el importer afectado sin romper los demás.

**¿Por qué `enabled: false` por defecto?**
Un agente registrado pero no habilitado puede ser investigado y documentado sin que el harvest script intente procesarlo y falle.
