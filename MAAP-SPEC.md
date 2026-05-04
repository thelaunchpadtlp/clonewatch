# MULTI-AI AGENT PARTY — ESPECIFICACIÓN TÉCNICA UNIFICADA
**Proyecto:** `multiaiagentparty` (evolución de `geminicodexparty`)  
**Versión:** 1.0 — Mayo 2026  
**Stack principal:** Google Cloud · Google AI Studio · Google Workspace · GitHub  
**Plataformas objetivo:** Mac (primaria) · iPhone · iPad  
**Uso de este documento:** contexto para Gemini CLI en Google Cloud Shell

---

## ÍNDICE

1. [Visión y Leyes de Diseño](#1-visión-y-leyes-de-diseño)
2. [Arquitectura del Sistema](#2-arquitectura-del-sistema)
3. [Sistema de Diseño TUI — Omni-Console v2.0](#3-sistema-de-diseño-tui--omni-console-v20)
4. [Arquitectura Multi-Orquestador](#4-arquitectura-multi-orquestador)
5. [Persistencia de Sesión y Autenticación](#5-persistencia-de-sesión-y-autenticación)
6. [Integración con el Ecosistema Apple](#6-integración-con-el-ecosistema-apple)
7. [Compatibilidad Multi-Entorno](#7-compatibilidad-multi-entorno)
8. [Integración GCP y Google Workspace](#8-integración-gcp-y-google-workspace)
9. [Estructura del Repositorio](#9-estructura-del-repositorio)
10. [Hoja de Ruta y Hitos](#10-hoja-de-ruta-y-hitos)
11. [QA y Criterios de Éxito](#11-qa-y-criterios-de-éxito)
12. [Preguntas de Investigación Abiertas](#12-preguntas-de-investigación-abiertas)

---

## 1. Visión y Leyes de Diseño

### 1.1 Qué es esto

Una **plataforma soberana de orquestación multi-AI supervisada por humanos**, con un TUI cinematográfico como núcleo. El sistema hace que un equipo coordinado de agentes AI — Gemini Preview, Gemini Nightly, Claude, Claude Code, ChatGPT, Codex, Grok, Perplexity, Deepseek, Qwen, Mistral, Cohere, Ollama, Manus, Meta AI, ElevenLabs, HeyGen, Stable Diffusion, y cualquier proveedor futuro — sea accesible permanentemente desde una única superficie unificada en Mac Terminal, IDE, Google Cloud Shell e iPad, sin re-autenticación, sin restricción a APIs, y sin perder el estado de sesión.

**El humano es siempre el principal.** El orquestador coordina los agentes AI como un equipo de backstage; el humano ve una interfaz elegante y cinematográfica.

### 1.2 Leyes de Diseño (No Negociables)

| # | Ley | Implicación práctica |
|---|-----|----------------------|
| 1 | **Determinismo primero** | Toda interacción que pueda ser determinística via código y algoritmos debe serlo. La IA solo cubre los huecos que el determinismo no puede. |
| 2 | **Humano en el loop siempre** | Sin loops autónomos nocturnos. Sin automatización masiva headless. Toda acción consecuente requiere aprobación humana. |
| 3 | **Gratis o casi gratis** | Arquitectura sobre tier gratuito de Google, Cloudflare, Apple APIs nativas, y open-source. Recursos de pago solo cuando es inevitable. |
| 4 | **Apple-first UX** | Mac es el dispositivo primario. Todo funciona en iPhone e iPad. Nada requiere configuración para empezar. |
| 5 | **ToS-safe por diseño** | Capa de automatización personal, nunca un servicio. Cada suscripción de proveedor es la del usuario. Patrones de tráfico dentro de límites "humano rápido". |

---

## 2. Arquitectura del Sistema

### 2.1 Los Cuatro Procesos Core (Mac como Nodo Edge)

El Mac (M1/M2/M4, 8GB+ RAM) ejecuta cuatro procesos cooperantes de forma permanente:

```
┌─────────────────────────────────────────────────────────────────┐
│  PROCESO A — Chrome for Testing (Chromium sidecar)             │
│  --user-data-dir=~/Library/Application Support/MAAP/main       │
│  --remote-debugging-port=9222 (solo 127.0.0.1)                │
│  LaunchAgent: auto-restart en crash o reboot                   │
│  Tabs: claude.ai · chatgpt.com · perplexity.ai · x.ai · etc. │
│  Cookies: AES-CBC-128, cifradas por macOS Keychain             │
└──────────────────────────┬──────────────────────────────────────┘
                           │ chrome.debugger / CDP
┌──────────────────────────▼──────────────────────────────────────┐
│  PROCESO B — Fabric Bridge (Extensión Chrome MV3)              │
│  Permisos: cookies, tabs, scripting, debugger, nativeMessaging │
│  Service worker: health de sesión, detección de 401            │
│  Refs estables (@e1, @e2) via snapshots del árbol a11y        │
│  WebSocket offscreen → endpoint localhost                       │
└──────────────────────────┬──────────────────────────────────────┘
                           │ JSON 32-bit length-prefixed (NMH)
┌──────────────────────────▼──────────────────────────────────────┐
│  PROCESO C — Native Messaging Host (Rust, ~5MB)                │
│  Registrado: ~/Library/.../NativeMessagingHosts/io.maap.json  │
│  Unix socket: ~/.maap/bridge.sock                              │
│  Traduce NMH ↔ MCP JSON-RPC                                   │
│  HTTP wrapper en :8080 → Cloudflare Tunnel → Cloud Shell      │
│  Secrets: macOS Keychain via security-framework crate          │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Eventos + notificaciones
┌──────────────────────────▼──────────────────────────────────────┐
│  PROCESO D — Tauri 2 (.app + ítem de barra de menú)            │
│  Tiles de sesión por proveedor (verde/amarillo/rojo)           │
│  Botones de re-login protegidos con Touch ID                   │
│  Motor de sonido, animaciones, routing de notificaciones       │
│  App Intents expuestos a Siri / Apple Intelligence             │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Capa Cloud

```
GCP Free Tier / Cloud Shell ($HOME persistente 5GB)
  └── Gemini CLI (host MCP, ~1.000 req/día gratis)
        └── MCP servers via ~/.gemini/settings.json
              ├── "maap-fabric"   → cloudflared → Mac NMH → Chromium
              ├── "vertex-mcp"    → Vertex AI Express Mode (90 días gratis)
              └── "cloud-run-mcp" → coordinador e2-micro always-on
```

**Cloudflare Tunnel** conecta Cloud Shell con el NMH HTTP del Mac. Los service tokens de acceso viven en GCP Secret Manager. Costo: $0.

### 2.3 Configuración MCP (Lo que todo Gemini ve)

```jsonc
// ~/.gemini/settings.json
{
  "mcpServers": {
    "maap": {
      "command": "/usr/local/bin/maap-bridge",
      "args": ["--socket", "/Users/<USUARIO>/.maap/bridge.sock"]
    }
  }
}
```

**Herramientas expuestas:**

```
claude.ask                chatgpt.ask               codex.run
gemini_preview.ask        gemini_nightly.ask         grok.ask
perplexity.deep_research  deepseek.ask               qwen.ask
mistral.ask               cohere.ask                 ollama.local_complete
heygen.create_video       elevenlabs.tts             stable_diffusion.generate
manus.delegate            meta_ai.ask                maap.session_status
maap.switch_active_ai     maap.feedback_collect
```

### 2.4 Federación de Identidad — Lo que Realmente Funciona

Google Identity Services emite tokens por `client_id` — **no son portables entre proveedores**. Lo que SÍ es portable es la sesión upstream de la cuenta Google (`SID`/`HSID`/`__Secure-1PSIDTS` cookies en `.google.com`).

**Estrategia:**
- **Bootstrap una vez, manualmente:** Login en cada proveedor dentro del perfil dedicado de Chrome for Testing. Los proveedores con "Continue with Google" (Claude, Perplexity, HeyGen, ElevenLabs, Mistral, Cohere) se re-autentican silenciosamente cuando las sesiones expiran.
- **Proveedores sin Google** (Grok, Deepseek, Qwen, Moonshot): Login manual una vez, almacenado en el cookie store cifrado del perfil dedicado.
- **Passkeys FIDO2:** Añadidos via CDP `WebAuthn.addVirtualAuthenticator`, persistidos en `Web Data` SQLite del perfil. No se necesita TOTP nunca más.
- **GCP Secret Manager:** Solo para secrets de aplicación (credenciales Cloudflare, SA keys de GCP). Nunca cookies de sesión del navegador.

### 2.5 Capa de Interacción Determinística

Tres técnicas, usadas en orden de preferencia:

| Prioridad | Técnica | Tokens/interacción | Determinismo |
|-----------|---------|-------------------|--------------|
| 1 | **WebMCP** (donde esté disponible) | ~50–100 | Absoluto (schema-validated RPC) |
| 2 | **Hash-Anchored A11y Tree Refs** (@e1, @e2) | ~200–400 | Alto (ref es el elemento) |
| 3 | **Stagehand v3 act/observe** (fallback) | ~500–1000 primera vez, ~0 siguientes | Alto (cache CDP post-primera ejecución) |

**Auto-reparación via Gemini Nano:** Cuando una ref se rompe (rediseño del proveedor), Gemini Nano (corre localmente en Chrome, ~0ms latencia) analiza el vecindario DOM y calcula un selector de reemplazo. Sin round-trip a la nube.

---

## 3. Sistema de Diseño TUI — Omni-Console v2.0

### 3.1 Filosofía Central

El TUI no es una interfaz de chat terminal simple. Es un **sistema cinematográfico, con estado, multi-panel** con estas invariantes:
- Todo mensaje de cualquier AI viene envuelto en doble timestamp (antes y después del cuerpo)
- El AI activo controla el tema visual de toda la interfaz
- Los mensajes se revelan progresivamente — el lector debe avanzarlos
- El scroll funciona perfectamente en todos los entornos, incluyendo hasta el inicio de sesión
- El input nunca requiere cajas con Tab-para-enfocar

### 3.2 Sistema de Personas AI — Skins TUI Diferenciados

Cada agente AI tiene una identidad visual distinta que toma el control del TUI cuando está activo.

| Agente | Paleta ANSI | Avatar ASCII | Estilo de borde | Animación |
|--------|-------------|--------------|-----------------|-----------|
| **Gemini Preview** | Cian/Azul | `◈ GEMINI ◈` | Doble `╔═╗` | Puntos pulsantes `⠋⠙⠹⠸` |
| **Gemini Nightly** | Púrpura/Índigo | `◉ G-NIGHT ◉` | Punteado `┌─┐` | Estrella rotando `✦✧` |
| **Claude** | Naranja cálido | `⟨ CLAUDE ⟩` | Redondeado `╭─╮` | Ola suave `▁▂▃▄▅▆▇█` |
| **Claude Code** | Naranja+Verde | `⟨ CC ⟩` | Redondeado + gutter | Cursor de código |
| **ChatGPT** | Verde azulado | `[ GPT ]` | Cuadrado `┌┐` | Spinner `⣾⣽⣻⢿` |
| **Codex** | Azul eléctrico | `{ CDX }` | Grueso `┏━┓` | Barra de progreso |
| **Grok** | Blanco/Plata | `⚡ GROK ⚡` | Fino `╌╌╌` | Flash de rayo |
| **Deepseek** | Azul profundo | `≋ DSK ≋` | Ola | Caracteres de ola oceánica |
| **Perplexity** | Púrpura/Violeta | `◎ PRPLX ◎` | Punteado `·─·` | Pulso de búsqueda |
| **Manus** | Rojo/Carmesí | `⦿ MANUS ⦿` | Pesado `▐█▌` | Indicador de acción |
| **Mistral** | Naranja/Rojo | `≈ MSTR ≈` | Estilo viento | Animación brisa |
| **Meta AI** | Gradiente azul | `⊕ META ⊕` | Estándar | Loop infinito |
| **Ollama** | Verde/Bosque | `⊞ LOCAL ⊞` | Doble `║` | Pulso local |

**Gemini Preview vs Gemini Nightly** son individuos distintos aunque estén conectados a la misma cuenta Google simultáneamente. Se diferencian por: string de versión del modelo en la respuesta CDP, tabs separados en el perfil Chrome, directorios de sesión separados, personas TUI distintas, y reglas de routing distintas.

### 3.3 Formato de Envelope de Mensaje (Doble Timestamp, Obligatorio)

Todo mensaje de cualquier AI — sin excepción — viene envuelto en este formato exacto:

```
╭────────────────────────────────────────────────────────────────╮
│ ◈ GEMINI PREVIEW · Sábado, 2 de Mayo de 2026 · 15:47          │
╰────────────────────────────────────────────────────────────────╯

[CUERPO DEL MENSAJE — revelado progresivamente, ver §3.4]

╭────────────────────────────────────────────────────────────────╮
│ ◈ GEMINI PREVIEW · Sábado, 2 de Mayo de 2026 · 15:47          │
╰────────────────────────────────────────────────────────────────╯
```

El timestamp aparece **antes Y después** de cada mensaje. Crea una pista de auditoría inequívoca y hace las sesiones legibles por máquinas.

### 3.4 Revelación Progresiva de Mensajes — El Sistema "Unravel"

Los mensajes largos **nunca se vuelcan de golpe**. Se segmentan en chunks lógicos (párrafo, bloque de código, lista, diagrama) y el humano avanza con una tecla.

**Mecanismo:**
1. El mensaje llega completo del backend AI
2. El sistema lo segmenta determinísticamente: límites de párrafo, fences de código, ítems de lista
3. Renderiza el primer segmento
4. Muestra: `[ ESPACIO o → para continuar · ESC para ir al final · ↑ para volver ]`
5. Cada tecla revela el siguiente segmento con un fade-in de ~80ms usando manipulación de cursor ANSI
6. `ESC` o `FIN` revela todo el contenido restante de inmediato
7. Tras la revelación completa: `[ ↑/↓ para scrollear · R para releer desde el inicio ]`

**Implementación:** Terminal puro — secuencias de escape ANSI, sin dependencia de frameworks. Funciona en Apple Terminal, iTerm2, Google Cloud Shell, Termius, Blink, terminal integrada de VS Code.

### 3.5 Resuelto: El Problema del Scroll

**Causa raíz:** El modo de pantalla alternada (`smcup`/`rmcup`) descarta el historial de scrollback al salir. Todos los frameworks TUI completos (blessed, bubbletea, etc.) lo usan por defecto. Por eso en Gemini web no se puede hacer scroll al inicio de sesión.

**Solución — Arquitectura de Scroll Híbrida:**

```
MODO INLINE (por defecto):
  Los mensajes se escriben en el buffer primario de pantalla con \n
  → Se acumulan en el scrollback nativo del terminal
  → El usuario puede scrollear al inicio de sesión con shift+pageup
  → El input se captura sin pantalla alternada

MODO PANEL (opt-in con Ctrl+K, Ctrl+G, etc.):
  Un panel delgado de pantalla alternada se abre en la PARTE INFERIOR
  (altura fija, ej. 14 líneas)
  → El historial de mensajes permanece en el buffer primario arriba
  → Q o ESC cierra el panel, restaurando el scrollback completo
```

Esta arquitectura híbrida significa que **el historial de sesión siempre está en el scrollback nativo del terminal** — nunca se pierde en pantalla alternada. Las apps de terminal para iPad (iSH, a-Shell, Blink Shell, Termius) soportan scrollback nativo, por lo que funciona sin configuración.

**Detalle técnico:** La captura de input inline usa `stty raw -echo` + manejo de señales, no curses. El cursor se posiciona en una línea de input fija al fondo via ANSI `\033[{row};1H`, mientras el scrollback arriba queda intacto.

### 3.6 Resuelto: El Problema de los Cuadros de Input con Tab

**El problema estándar:** Requiere que el usuario sepa que Tab mueve el foco. Se siente como un formulario web roto. Invisible en muchos terminales.

**Solución — Prompt Inline Contextual:**

No hay cuadro. La línea de input está siempre al fondo del viewport, precedida por un **indicador de prompt dinámico** que cambia según el AI activo:

```
◈ › _
```

El indicador es el símbolo del AI activo. Se escribe inmediatamente — sin Tab, sin clic, sin ceremonia de foco.

**Comandos de teclado disponibles como acordes** (no requieren Tab):

| Acorde | Acción |
|--------|--------|
| `Ctrl+P` | Abrir selector de proveedor |
| `Ctrl+L` | Limpiar pantalla, mantener historial en scrollback |
| `Ctrl+T` | Abrir selector de sesiones Time Travel |
| `Ctrl+K` | Abrir panel Live Pulse (logs) |
| `Ctrl+G` | Abrir visualizador de costo y tokens |
| `Ctrl+F` | Modo pantalla completa (entornos navegador) |
| `Ctrl+A` | Cambiar AI activo (cicla por el roster) |
| `Ctrl+R` | Modo de feedback (AI pide opinión sobre su output) |
| `↑`/`↓` | Historial de comandos (cuando la línea de input está vacía) |
| `Ctrl+↑`/`↓` | Scrollear historial de sesión sin salir del input |
| `Option+Enter` | Insertar newline en input (Mac) |
| `Enter` | Enviar |

### 3.7 Módulo: Live Pulse — Panel de Logs en Streaming

Activado con `Ctrl+K`. Panel de 14 líneas al fondo, no rompe el scrollback:

```
┌─ LIVE PULSE ──────────────────────────── [Q] cerrar · [↑↓] scroll ─┐
│ 15:47:32 [MAAP] fabric.claude.ask → despachando                     │
│ 15:47:32 [CDP]  tab claude.ai activo, cookie válida                 │
│ 15:47:33 [NET]  claude.ai /api/completion → 200 OK (1.2s)          │
│ 15:47:33 [GCP]  Cloud Shell heartbeat OK                            │
│ 15:47:34 [MAAP] respuesta recibida, 847 tokens                      │
│ 15:47:34 [AUD]  cost tracker +$0.0023                               │
│ 15:47:35 [SESS] perplexity.ai session refresh → OK                  │
│ 15:47:36 [IDLE] chatgpt.com último activo hace 4m                   │
│ ▸ streaming desde maap-bridge.sock · 0 errores · uptime 3h 42m      │
└─────────────────────────────────────────────────────────────────────┘
```

Fuentes: stream de eventos del Unix socket NMH, `gcloud logging read` (via subproceso), eventos de red CDP. Buffer circular de 500 líneas, completamente scrolleable.

### 3.8 Módulo: Visualizador de Costo y Tokens

Activado con `Ctrl+G`:

```
┌─ GASTO AI & USO ──────────────────────────────── total sesión ──────┐
│ Claude        ████████████░░░░  2.847 tok  $0.034  ↑ tendencia      │
│ ChatGPT       ███░░░░░░░░░░░░░    891 tok  $0.018  → estable        │
│ Gemini (free) ████████████████  3.200 tok   GRATIS ✓ cuota ok       │
│ Perplexity    ██░░░░░░░░░░░░░░    420 tok  $0.009  ↓ poco uso       │
│ ElevenLabs    █░░░░░░░░░░░░░░░    120 chars $0.002 → estable        │
│ ──────────────────────────────────────────────────────────────────── │
│ TOTAL SESIÓN  ░░░░░░░░░░░░░░░░  7.478 tok  $0.063  (24h: $0.41)    │
│ [R] reiniciar · [E] exportar a Drive · [A] configurar alerta        │
└─────────────────────────────────────────────────────────────────────┘
```

Datos: contador de tokens del NMH (cuenta tokens in/out por tool call) + endpoints de uso de proveedores (polling cada 5 min) + ledger SQLite local en `~/.maap/usage.db`.

### 3.9 Módulo: Time Travel — Selector de Sesiones

Activado con `Ctrl+T`:

```
┌─ TIME TRAVEL — sesiones recientes ──────────────────────────────────┐
│ ▸ [1] Hoy 15:42    "Gemini + Claude → revisión de arquitectura"    │
│   [2] Hoy 11:08    "Pipeline ElevenLabs voice + HeyGen video"      │
│   [3] Ayer         "Deepseek code review session"                  │
│   [4] Abr 30       "Perplexity research: especificación WebMCP"    │
│   [5] Abr 28       "Test multimodal con Gemini Nightly"            │
│                                                                      │
│ [↑↓] navegar · [Enter] cargar · [Del] archivar · [ESC] cancelar   │
└─────────────────────────────────────────────────────────────────────┘
```

Las sesiones se guardan en `~/.maap/sessions/` como JSONL estructurado.

### 3.10 Módulo: Loop de Feedback Visual del AI

Tras cualquier mensaje que contenga output visual generado (infografía, branding, animación, ilustración, paleta de colores), el sistema agrega un widget de micro-feedback:

```
◈ Feedback rápido sobre este output:
  [1] Me encanta  [2] Bien  [3] Meh  [4] Fuera de marca  [5] Rehacer
  [S] Omitir todo feedback de esta sesión
```

El feedback se registra en `~/.maap/feedback/visual-prefs.jsonl`. Un módulo Rust lee el historial de feedback y construye un perfil de preferencias que se inyecta en el system prompt para solicitudes de generación visual futuras. Aprendizaje determinístico — sin ML adicional.

### 3.11 Dashboard TUI (Espejo del Dashboard GUI)

Invocado con `/dashboard`:

```
┌─ MAAP DASHBOARD ──────────────────────────────── Ctrl+Q para salir ─┐
│ SESIONES          USO HOY           TAREAS ACTIVAS                   │
│ ● Claude   OK     Claude  ████ 2.8k ▸ Code review (claude)          │
│ ● ChatGPT  OK     GPT     ██░░  891 ▸ Investigación (perplexity)    │
│ ● Gemini   OK     Gemini  ████ 3.2k ▸ Idle (4 proveedores)          │
│ ● Grok     OK     Grok    █░░░  234                                  │
│ ◐ Deepseek LAG    EL      █░░░  120                                  │
│ ● Perplxty OK     Total   $0.063                                     │
│────────────────────────────────────────────────────────────────────  │
│ LOG DE ROUTING            SALUD DEL SISTEMA                          │
│ 15:47 → claude (código)   NMH bridge:     ● UP  3h42m               │
│ 15:44 → perplexity        Chrome CFT:     ● UP  reiniciado 1x       │
│ 15:41 → swarm(8)          Cloudflare:     ● UP  50ms RTT            │
│ 15:38 → elevenlabs        Cloud Shell:    ● UP  conectado           │
└──────────────────────────────────────────────────────────────────────┘
```

Mismos datos, mismo lenguaje de layout, mismos atajos de teclado que el dashboard GUI.

---

## 4. Arquitectura Multi-Orquestador

### 4.1 El Modelo de Coordinación

Gemini (Preview o Nightly — el que sea primario) actúa como **cerebro de routing**. Todos los demás AIs son herramientas. El humano habla con el cerebro de routing, que decide — determinísticamente con reglas explícitas — qué proveedores llamar, en qué orden, si en paralelo o serial, y cómo fusionar los resultados.

```
Prompt del humano
       │
       ▼
MAAP Router (motor de reglas determinístico, escrito en Rust)
       │
       ├── ROUTE: single-provider → despacha a un AI
       ├── ROUTE: consensus     → despacha a N AIs en paralelo, fusiona
       ├── ROUTE: pipeline      → A → resultado alimenta B → resultado alimenta C
       └── ROUTE: specialist    → despacha al proveedor con capacidad específica
```

**El Router NO es un LLM.** Es un motor de matching de reglas con una tabla de routing explícita.

### 4.2 Ejemplo de routing.toml

```toml
# ~/.maap/routing.toml

[[route]]
pattern = ["code review", "debug", "swift", "rust", "python"]
providers = ["claude", "codex"]
mode = "parallel"
fuse = "merge-disagreements"

[[route]]
pattern = ["voice", "audio", "tts", "narrar"]
providers = ["elevenlabs"]
mode = "single"

[[route]]
pattern = ["investigar", "buscar", "últimas noticias"]
providers = ["perplexity"]
mode = "single"

[[route]]
pattern = ["tres perspectivas", "comparar", "opiniones"]
providers = ["claude", "chatgpt", "gemini"]
mode = "parallel"
fuse = "summarize-disagreements"

[[route]]
pattern = ["video", "avatar", "talking head"]
providers = ["heygen"]
mode = "single"

[[route]]
pattern = ["local", "privado", "sensible", "offline"]
providers = ["ollama"]
mode = "single"
```

Cuando no hay match, el AI activo maneja directamente. El usuario puede sobrescribir con prefijos explícitos: `@claude: explica esto`, `@grok: qué piensas`, `@all: tres perspectivas`.

### 4.3 Gemini Preview vs Gemini Nightly — Dos Individuos

Aunque ambos estén conectados a la misma cuenta Google simultáneamente:

| Dimensión | Gemini Preview | Gemini Nightly |
|-----------|---------------|----------------|
| Identificación | String de versión en respuesta CDP | Diferente string de versión |
| Tab del navegador | Tab separado en el perfil Chrome | Tab separado |
| Directorio de sesión | `~/.maap/sessions/gemini-preview/` | `~/.maap/sessions/gemini-nightly/` |
| Persona TUI | Cian/Azul, `◈ GEMINI ◈` | Púrpura, `◉ G-NIGHT ◉` |
| Casos de uso | Tareas de producción estables | Experimental, cutting-edge |
| Tool handle | `gemini_preview.ask` | `gemini_nightly.ask` |

### 4.4 Modo Swarm

Para tareas que se benefician de muchas perspectivas en paralelo:

```
Usuario: /swarm "¿Es sólida esta arquitectura?"

MAAP Swarm Engine:
  despachando a 8 proveedores en paralelo...

  ◈ Claude      → [recibido 2.1s]  ▓▓▓▓▓▓▓▓▓▓▓░░
  ◈ ChatGPT     → [recibido 3.4s]  ▓▓▓▓▓▓▓▓▓▓▓▓▓
  ◈ Grok        → [recibido 1.8s]  ▓▓▓▓▓▓▓▓░░░░░
  ◈ Deepseek    → [recibido 4.2s]  ▓▓▓▓▓▓▓▓▓▓▓▓▓
  ◈ Perplexity  → [recibido 5.1s]  ▓▓▓▓▓▓▓▓▓▓▓▓▓
  ◈ Mistral     → [recibido 2.9s]  ▓▓▓▓▓▓▓▓▓▓░░░
  ◈ Qwen        → [recibido 3.7s]  ▓▓▓▓▓▓▓▓▓▓▓▓▓
  ◈ G-Preview   → [recibido 2.3s]  ▓▓▓▓▓▓▓▓▓░░░░

  fusionando via Gemini Flash (modelo de bajo costo)...
```

Las barras de progreso se animan en tiempo real. El paso de fusión usa el modelo más barato capaz (Gemini Flash).

---

## 5. Persistencia de Sesión y Autenticación

### 5.1 Stack de Autenticación de Tres Capas

**Capa 1 — Cuenta Google (Piedra Angular de Identidad)**  
Una sesión de cuenta Google vive en el perfil Chrome dedicado. Desbloquea re-auth silenciosa para todos los proveedores "Continue with Google". Nunca expira mientras el perfil persiste.

**Capa 2 — Sesiones por Proveedor**  
Cada tab de proveedor mantiene sus propias cookies de sesión, actualizadas automáticamente por actividad normal de página. El bridge monitorea salud via `chrome.cookies` API. No se extraen cookies a disco.

**Capa 3 — Passkeys FIDO2**  
Añadidos una vez via CDP:
```json
{
  "protocol": "ctap2",
  "transport": "internal",
  "hasResidentKey": true,
  "hasUserVerification": true,
  "automaticPresenceSimulation": true
}
```
Clave privada almacenada en `Web Data` SQLite del perfil dedicado. Sobrevive reinicios. Elimina TOTP para proveedores que acepten passkey-as-2FA.

### 5.2 Máquina de Estado de Salud de Sesión

```
HEALTHY ──(401/403 detectado)──▶ DEGRADED
   ▲                                  │
   │                     (¿Cookies upstream Google presentes?)
   │                          SÍ              NO
   │                           │               │
   │                    SILENT_REAUTH    HUMAN_NEEDED
   │                           │               │
   └──────(reauth OK)──────────┘    (notificación Mac + iPhone)
                                     human toca "Fix it"
                                     → tab Chrome al frente
                                     → login manual
                                     → vuelve a HEALTHY
```

El sistema **nunca intenta recuperación autónoma de login** que pudiera activar detección anti-bot.

### 5.3 Credenciales del Authenticator Virtual CDP

```javascript
// Ejecutado una vez via CDP durante setup de cada proveedor
await cdpSession.send('WebAuthn.enable');
const { authenticatorId } = await cdpSession.send(
  'WebAuthn.addVirtualAuthenticator', {
    options: {
      protocol: 'ctap2',
      transport: 'internal',
      hasResidentKey: true,
      hasUserVerification: true,
      automaticPresenceSimulation: true,
      isUserVerified: true
    }
  }
);
// Persistido en Web Data SQLite del perfil → sobrevive reinicios
```

---

## 6. Integración con el Ecosistema Apple

### 6.1 Mac Helper App (.app + Barra de Menú)

En el primer lanzamiento en Mac Terminal o cualquier IDE, MAAP detecta macOS e instala el helper automáticamente:

```bash
maap --install-helper
# → Copia MAAP.app a /Applications
# → Registra LaunchAgent para Chrome for Testing
# → Registra LaunchAgent para daemon NMH
# → Agrega ítem a barra de menú
# → Solicita permiso de Centro de Notificaciones
```

**Capacidades adicionales del Mac App (más allá del TUI):**
- Animaciones a calidad de video que coinciden con la persona del AI activo (SwiftUI Canvas)
- Audio espacial: sonidos ambientales específicos por proveedor
- Sonidos de notificación distintos por AI para completar respuesta
- Comentario opcional hablado (via AVSpeechSynthesizer) — sardónico, breve, contextual
- Ventana de dashboard con gráficos de uso de tokens (SwiftUI Charts)
- Música de fondo ambient por tipo de flujo de trabajo (coding, investigación, creativo, review)

### 6.2 Cinco Atajos de Apple Shortcuts

| Atajo | Función | Trigger |
|-------|---------|---------|
| **Preguntar a MAAP** | Texto seleccionado → MAAP → respuesta en notificación | Botón de Acción / Share Sheet |
| **Comparar 3 Modelos** | Prompt → Claude + ChatGPT + Gemini → resumen | Siri: "Compara tres modelos" |
| **Generar Voz** | Texto → ElevenLabs TTS → guardado en Archivos | Share Sheet |
| **Generar Video** | Guión → HeyGen → link devuelto | Siri: "Haz un video" |
| **Estado MAAP** | Consultar salud de sesiones → JSON para widget | Widget en pantalla de inicio |

**En iPad (sin cliente SSH para uso básico):** Shortcuts usa la acción "Run Script Over SSH" para llegar al Mac Mini. Clave SSH almacenada en el keychain de Shortcuts. Configuración única, luego cero configuración para siempre.

### 6.3 App Intents (Siri / Apple Intelligence)

```swift
struct AskFabricIntent: AppIntent {
    @Parameter(title: "Prompt") var prompt: String
    @Parameter(title: "Proveedor", default: "auto") var provider: String
}

struct SwitchActiveAIIntent: AppIntent {
    @Parameter(title: "Nombre del AI") var aiName: String
}

struct GetSessionStatusIntent: AppIntent {}
```

Aparecen en Spotlight, Siri y la app Shortcuts automáticamente.

### 6.4 Widget de Pantalla de Inicio / Bloqueo

MAAP Status exporta un JSON legible por widget a iCloud Drive cada 5 minutos:

```json
{
  "timestamp": "2026-05-02T15:47:00Z",
  "active_ai": "claude",
  "session_health": {
    "claude": "ok", "chatgpt": "ok",
    "gemini": "ok", "perplexity": "degraded"
  },
  "today_cost": 0.063,
  "today_tokens": 7478,
  "active_tasks": 2
}
```

---

## 7. Compatibilidad Multi-Entorno

### 7.1 Detección de Terminal y Auto-Configuración

Al lanzarse, MAAP ejecuta `maap detect` — un probe determinístico de entorno:

```
detectado: Apple Terminal 2.14 / macOS 26.0
  ✓ 256-color ANSI
  ✓ Unicode (emoji: no, box-drawing: sí)
  ✓ itálicas via \033[3m
  ✓ scrollback nativo (no pantalla alternada)
  ✓ true color
  → perfil: apple-terminal-optimal
```

### 7.2 Perfiles de Entorno

| Entorno | Perfil | Adaptaciones clave |
|---------|--------|--------------------|
| Apple Terminal | `apple-terminal` | True color, box chars, no emoji, scrollback nativo |
| iTerm2 | `iterm2` | Emoji completo, imágenes via imgcat, integración tmux |
| Terminal VS Code | `vscode` | True color, manejo de clics, hints de panel integrado |
| Google Cloud Shell (navegador) | `cloud-shell-browser` | 256-color, chars anchos, inyección CSS full-screen |
| Termius (Mac) | `termius-mac` | SSH-aware, true color, hints de gestos táctiles |
| Blink Shell (Mac/iPad) | `blink` | Mosh-aware, paneles compactos, acordes touch-optimized |
| Cursor IDE | `cursor` | Perfil VS Code + consciencia de modo agente |
| Codex CLI | `codex` | Decoración mínima, output amigable con tool-calls |
| a-Shell (iPad) | `a-shell` | Fallback ASCII, layout compacto |
| iSH (iPad) | `ish` | Mínimo, 80 cols forzadas, display de acordes touch-friendly |

### 7.3 Modo Pantalla Completa en Navegador (Cloud Shell / Safari / Chrome)

Cuando corre en Google Cloud Shell, `Ctrl+F` dispara el modo inmersivo de pantalla completa:

```javascript
// Inyectado via API postMessage de Cloud Shell
document.querySelector('.cloud-shell-nav').style.display = 'none';
document.querySelector('.terminal-container').style.height = '100vh';
document.documentElement.requestFullscreen();
```

En Safari/iOS: inyecta un override CSS que oculta todo el chrome del navegador y fija el terminal a `position: fixed; inset: 0`. La barra de dirección/pestañas se oculta automáticamente al scroll, logrando casi pantalla completa.

### 7.4 Acceso iPad sin Configuración

**Opción A (Preferida):** Apple Shortcuts → "Run Script Over SSH" — intercambio de clave SSH una vez, luego Siri/Botón de Acción funciona para siempre.

**Opción B (Cero configuración):** Cloudflare Tunnel expone una terminal web (via `ttyd`) en `https://console.tudominio.com`. El usuario navega en Safari en iPad. Cloudflare Access requiere login con cuenta Google — un toque en iPad.

**Opción C:** SSH estándar al Mac Mini via Termius o Blink. MAAP auto-detecta el perfil y adapta el layout para uso táctil.

---

## 8. Integración GCP y Google Workspace

### 8.1 Presupuesto Tier Gratuito

| Recurso | Asignación gratuita | Uso MAAP |
|---------|---------------------|----------|
| Gemini CLI | ~1.000 req/día | Orquestador primario |
| Vertex AI Express | 90 días, 10 agent engines | Agentes en background |
| Cloud Shell | 5GB persistente, 50h/semana | Home permanente para CLI |
| Compute Engine e2-micro | 720h/mes (us-east1) | Coordinador NMH HTTP |
| Cloud Storage | 5GB | Backups de config, exports de sesión |
| Firestore | 1GB/día | Mirror de ledger de uso |
| Firebase Realtime DB | 1GB | Log de stream de eventos |
| GCP Secret Manager | 6 primeros secrets gratis | Credenciales del túnel |
| Cloudflare Tunnel | Gratis para siempre | Bridge Mac ↔ Cloud |
| Cloudflare Access | Gratis (50 usuarios) | Auth para el túnel |

**Costo mensual total en estado estable: ~$0**

### 8.2 Configuración de Cloud Shell

```bash
# ~/.bashrc en Cloud Shell — ejecutado automáticamente
export MAAP_TUNNEL_URL="https://fabric.tudominio.com"

# Obtener service token de Secret Manager al inicio
export CF_CLIENT_ID=$(gcloud secrets versions access latest \
  --secret="maap-cf-client-id")
export CF_CLIENT_SECRET=$(gcloud secrets versions access latest \
  --secret="maap-cf-client-secret")

# Configurar Gemini CLI con el MCP server de MAAP
cat > ~/.gemini/settings.json << 'EOF'
{
  "mcpServers": {
    "maap": {
      "command": "curl",
      "args": [
        "-H", "CF-Access-Client-Id: ${CF_CLIENT_ID}",
        "-H", "CF-Access-Client-Secret: ${CF_CLIENT_SECRET}",
        "${MAAP_TUNNEL_URL}/mcp"
      ]
    }
  }
}
EOF
```

### 8.3 Pipeline de Logging Firebase

```json
// Estructura de evento en Firebase Realtime Database
{
  "events": {
    "2026-05-02T15:47:32Z": {
      "type": "tool_call",
      "tool": "claude.ask",
      "tokens_in": 234,
      "tokens_out": 847,
      "latency_ms": 1247,
      "session_id": "sess-20260502-154732",
      "ai_active": "gemini-preview",
      "cost_usd": 0.0023
    }
  }
}
```

Nota: **solo metadatos** (tokens, latencia, routing). El contenido de las respuestas AI nunca se registra en Firebase.

### 8.4 Pipeline de QA de Vertex AI

Cuando una conexión de proveedor se degrada:

1. Firebase detecta anomalía (tasa de error > 5% en ventana de 10 min)
2. Cloud Run job obtiene los últimos 50 eventos del proveedor
3. Vertex AI (Gemini Pro) analiza el patrón de fallo
4. Genera diagnóstico y actualización recomendada del skill-file
5. Diagnóstico escrito a Google Drive (`MAAP-QA/incidents/YYYY-MM-DD.md`)
6. Notificación macOS al usuario: "Conector Claude degradado — revisión recomendada"

### 8.5 Archivado de Sesiones a Google Drive

Las sesiones completadas se exportan en dos formatos:
- **JSONL** (`~/.maap/sessions/YYYY-MM-DD-HHMMSS.jsonl`) — legible por máquinas
- **Google Doc** (via Workspace API) — legible por humanos, buscable

---

## 9. Estructura del Repositorio

### 9.1 GitHub: `multiaiagentparty` (nuevo repo separado)

```
multiaiagentparty/
├── README.md
├── MAAP-SPEC.md                     ← ESTE DOCUMENTO
├── CHANGELOG.md
├── LICENSE
│
├── maap-bridge/                     # Rust — Native Messaging Host
│   ├── src/
│   │   ├── main.rs                  # Entrada NMH + servidor Unix socket
│   │   ├── mcp.rs                   # Implementación MCP JSON-RPC
│   │   ├── keychain.rs              # macOS Keychain via security-framework
│   │   ├── router.rs                # Motor de routing determinístico
│   │   ├── session_monitor.rs       # Máquina de estado de salud
│   │   └── usage_ledger.rs          # Rastreador de costo SQLite
│   └── Cargo.toml
│
├── maap-extension/                  # Extensión Chrome MV3
│   ├── manifest.json
│   ├── background/
│   │   ├── service-worker.js
│   │   ├── session-health.js
│   │   └── cdp-bridge.js
│   └── skill-files/                 # Selectores determinísticos por proveedor
│       ├── claude.yaml
│       ├── chatgpt.yaml
│       ├── perplexity.yaml
│       └── ...
│
├── maap-tui/                        # TypeScript — Motor TUI
│   ├── src/
│   │   ├── console.ts               # Punto de entrada TUI principal
│   │   ├── personas/                # Definiciones de persona por AI
│   │   ├── panels/                  # Live Pulse, Cost Viz, Time Travel
│   │   ├── input/                   # Sistema de prompt inline, Unravel
│   │   ├── scroll/                  # Arquitectura de scroll híbrida
│   │   ├── feedback/                # Colección de feedback + aprendizaje
│   │   └── env-detect/              # Selector de perfil de entorno
│   └── package.json
│
├── maap-helper/                     # Swift — Mac .app + barra de menú
│   ├── Sources/
│   │   ├── MenuBarController.swift
│   │   ├── DashboardView.swift
│   │   ├── SoundEngine.swift
│   │   ├── AnimationEngine.swift
│   │   └── AppIntents/
│   └── Resources/
│       ├── Sounds/
│       └── Animations/
│
├── maap-shortcuts/                  # Apple Shortcuts (.shortcut files)
│   ├── Ask-MAAP.shortcut
│   ├── Compare-3-Models.shortcut
│   ├── Generate-Voice.shortcut
│   ├── Generate-Video.shortcut
│   └── MAAP-Status.shortcut
│
├── deploy/
│   ├── launchd/                     # Plists LaunchAgent de macOS
│   ├── cloudflare/tunnel-config.yaml
│   └── gcp/
│       ├── cloud-shell-init.sh      ← Script de bootstrap para Cloud Shell
│       └── secret-manager-setup.sh
│
└── .github/workflows/
    ├── ci.yml                       # Build + test en runner macOS
    ├── skill-file-audit.yml         # Verificación semanal de regresión de UI
    └── security-scan.yml
```

---

## 10. Hoja de Ruta y Hitos

### Fase 0 — Fundación (Semanas 1–2)
- [ ] Crear repo GitHub `multiaiagentparty`
- [ ] Chrome for Testing instalado, todos los proveedores con login, cookies verificadas persistentes
- [ ] Esqueleto Rust `maap-bridge`: lee de extensión, expone Unix socket
- [ ] Esqueleto extensión Chrome MV3: conecta a NMH, polling de salud
- [ ] Esqueleto `maap-tui`: prompt inline, sistema de personas, envelope doble timestamp, motor Unravel
- [ ] Arquitectura de scroll híbrida validada en Apple Terminal, iTerm2, Cloud Shell

### Fase 1 — Sistema Core Funcionando (Semanas 3–6)
- [ ] Todos los proveedores principales cableados como herramientas MCP (claude, chatgpt, gemini, grok, perplexity, deepseek)
- [ ] Motor de routing determinístico con `routing.toml`
- [ ] Panel Live Pulse en streaming
- [ ] Visualizador de Costo y Tokens con ledger SQLite local
- [ ] Selector de sesiones Time Travel
- [ ] Integración Cloudflare Tunnel → Cloud Shell
- [ ] `maap detect` con perfiles de entorno para los 9 entornos terminales

### Fase 2 — Ecosistema Apple (Semanas 7–10)
- [ ] Esqueleto de app helper Tauri 2
- [ ] Ítem de barra de menú con indicadores de salud de sesión
- [ ] Mac helper `.app` con motor de sonido y animaciones básicas
- [ ] Cinco Apple Shortcuts publicados
- [ ] App Intents registrados para Siri
- [ ] Widget de pantalla de inicio via Scriptable

### Fase 3 — Calidad e Inteligencia (Semanas 11–16)
- [ ] Loop de feedback visual + aprendizaje de preferencias
- [ ] Auto-reparación de localizadores via Gemini Nano
- [ ] Logging Firebase + pipeline QA de Vertex AI
- [ ] Archivado de sesiones a Google Drive
- [ ] Modo Swarm
- [ ] Setup de authenticator virtual FIDO2 para todos los proveedores compatibles
- [ ] CI de regresión de skill-files

### Fase 4 — Polish y Features Frontier (Semanas 17–24)
- [ ] Dashboard GUI completo en Mac (SwiftUI Charts, timeline de sesión)
- [ ] Animaciones de persona a calidad de video en app Mac
- [ ] Modo pantalla completa en navegador (Cloud Shell + Safari)
- [ ] App acompañante iOS/iPadOS básica
- [ ] Widget de iPhone con estado de sesión en vivo
- [ ] Release público en GitHub con script de instalación

---

## 11. QA y Criterios de Éxito

### 11.1 Definición de Hecho — Sistema Core

| Criterio | Medición |
|----------|----------|
| Persistencia de sesión | Todos los proveedores permanecen con login por 7+ días sin re-auth humana |
| Latencia de input | Tecla presionada a caracter en pantalla: < 10ms en todos los entornos |
| Revelación de mensaje | Primer chunk mostrado < 200ms tras completar respuesta API |
| Corrección de scroll | `shift+pageup` alcanza inicio de sesión en Apple Terminal, iTerm2, Cloud Shell |
| Paridad multi-entorno | Mismo conjunto de features disponible en los 9 entornos detectados |
| iPad cero configuración | Shortcut funciona en iPad nuevo con solo intercambio de clave SSH |
| Precisión de costo | Ledger de uso dentro del 5% de la facturación real del proveedor |
| Determinismo de routing | El mismo prompt siempre enruta al mismo proveedor(es), cero aleatoriedad |

### 11.2 Checklist de Seguridad

- [ ] Cookies de navegador nunca escritas a disco fuera del perfil Chrome cifrado
- [ ] Wrapper HTTP NMH fuerza headers `CF-Access-Client-Id`/`Secret` independientemente
- [ ] Secrets de GCP Secret Manager nunca registrados ni mostrados
- [ ] SQLite de ledger de uso cifrado en reposo (SQLCipher)
- [ ] Todo el tráfico de red a proveedores solo via HTTPS
- [ ] Contenido de respuestas AI nunca registrado en Firebase (solo metadatos)
- [ ] Service token de Cloudflare Access rotado cada 90 días

### 11.3 Checklist de Cumplimiento ToS

- [ ] Marcador de User-Agent de extensión propio (no suplantando ningún cliente oficial)
- [ ] Tasa de tráfico < 1 solicitud/2s a cualquier proveedor
- [ ] Sin loops autónomos corriendo después de las 23:00 hora local
- [ ] Sin acceso compartido a suscripciones de proveedores con terceros
- [ ] UI de proveedores no embebida en ventana Tauri (link externo al navegador)
- [ ] Cada sesión de proveedor es la suscripción propia y paga del usuario

---

## 12. Preguntas de Investigación Abiertas

1. **Identificación Gemini Preview vs Nightly:** Necesita pruebas empíricas para confirmar que el string de modelo está de forma fiable en la respuesta CDP. Fallback: usar patrón de URL del tab.

2. **Interacción DBSC con perfil Chrome dedicado:** DBSC se está desplegando progresivamente. Si `claude.ai` habilita DBSC, las cookies de sesión se vuelven device-bound a la clave TPM del perfil — el enfoque del túnel Cloudflare aún funciona porque el navegador del Mac ejecuta todas las solicitudes.

3. **Timeline de adopción de WebMCP:** Actualmente experimental. El sistema de skill-files es el fallback que funciona hoy. La integración WebMCP debe agregarse como capa de capacidad una vez que los proveedores la adopten.

4. **Límites de velocidad del tier gratuito de Gemini:** Con el modo swarm llamando a 8 proveedores, el límite de ~1.000 req/día puede agotarse con el paso de fusión. Investigación: usar Gemini Flash (tier más barato) para fusión, reservar Gemini Pro para consultas directas de usuario.

5. **Background fetch iOS/iPadOS para widget:** El widget Scriptable requiere que el Shortcut se ejecute manualmente o via automatización. El widget nativo requiere la app acompañante iOS. Investigar si Background App Refresh puede mantener el JSON de estado actualizado sin interacción del usuario.

---

## Comandos Rápidos para Gemini CLI en Cloud Shell

```bash
# Bootstrap completo en Cloud Shell
curl -sLO https://raw.githubusercontent.com/TU_ORG/multiaiagentparty/main/deploy/gcp/cloud-shell-init.sh && bash cloud-shell-init.sh

# Usar MAAP via Gemini CLI
gemini --prompt "use maap.session_status"
gemini --prompt "use claude.ask: revisa este código"
gemini --prompt "use maap.switch_active_ai: gemini-nightly"

# Ver logs en tiempo real
gemini --prompt "use maap.live_pulse: últimos 50 eventos"

# Swarm mode
gemini --prompt "/swarm ¿Cuál es la mejor arquitectura para este problema?"

# Verificar salud
gemini --prompt "use maap.session_status" | jq '.providers[] | select(.status != "ok")'
```

---

*Este documento es la fuente de verdad para el proyecto `multiaiagentparty`.*  
*Última actualización: Mayo 2, 2026*  
*Para usar como contexto en Gemini CLI: `gemini --context MAAP-SPEC.md`*
