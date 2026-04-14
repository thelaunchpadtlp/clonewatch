#!/usr/bin/env python3
"""
CloneWatch: herramienta de monitorización de clonación entre dos directorios.

Escanea dos árboles de directorios (A y B), calcula tamaños, compara presencia y
tamaños de archivos, calcula el porcentaje de copia y produce un informe HTML y
JSON apto para abrir en tu iPhone vía Google Drive o un servidor local.

Configura las rutas ROOT_A, ROOT_B, OUTPUT_DIR y, si querés generar un enlace
para abrir el informe a través de un servidor local, definí IP_ADDR con la IP
de tu Mac en la red local.
"""

import os
import json
import time
import socket
from pathlib import Path
from collections import defaultdict

# 🟡 AJUSTÁ ESTAS RUTAS SEGÚN TU CASO:
ROOT_A = Path("/Volumes/1D3")        # Directorio fuente (1D3A)
ROOT_B = Path("/Users/Shared/1D3")   # Directorio destino (1D3B)

# Carpeta de Google Drive sincronizada con tu iPhone
OUTPUT_DIR = Path(
    "/Users/piqui/Library/CloudStorage/GoogleDrive-joaquin.munoz@thelaunchpadtlp.education/"
    "My Drive/FUE - Fuentes - TLP - The Launch Pad - TLP"
)

# Dirección IP de tu Mac para generar un enlace .webloc (opcional).
# Si la dejás vacía, no se generará el enlace.
IP_ADDR = ""

def fmt_bytes(n):
    if n is None:
        return "—"
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(n)
    for unit in units:
        if size < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(size)} {unit}"
            return f"{size:.2f} {unit}"
        size /= 1024
    return f"{n} B"

def safe_stat_size(path: Path):
    try:
        if path.is_symlink():
            return 0
        if path.is_file():
            return path.stat().st_size
        if path.is_dir():
            total = 0
            with os.scandir(path) as it:
                for entry in it:
                    try:
                        entry_path = path / entry.name
                        if entry.is_symlink():
                            continue
                        if entry.is_file():
                            total += entry.stat().st_size
                        elif entry.is_dir():
                            size = safe_stat_size(entry_path)
                            if size is not None:
                                total += size
                    except Exception:
                        pass
            return total
    except Exception:
        return None
    return None

def build_index(root: Path):
    index = {}
    if not root.exists():
        return index
    index["."] = {
        "path": ".",
        "name": root.name,
        "level": 1,
        "type": "dir",
        "size": safe_stat_size(root),
    }
    for dirpath, dirnames, filenames in os.walk(root, topdown=True):
        current = Path(dirpath)
        try:
            rel_current = current.relative_to(root)
        except ValueError:
            continue
        for d in dirnames:
            p = current / d
            try:
                rel = p.relative_to(root)
                index[rel.as_posix()] = {
                    "path": rel.as_posix(),
                    "name": d,
                    "level": len(rel.parts) + 1,
                    "type": "dir",
                    "size": safe_stat_size(p),
                }
            except Exception:
                pass
        for f in filenames:
            p = current / f
            try:
                rel = p.relative_to(root)
                size = None
                try:
                    size = p.stat().st_size
                except Exception:
                    pass
                index[rel.as_posix()] = {
                    "path": rel.as_posix(),
                    "name": f,
                    "level": len(rel.parts) + 1,
                    "type": "file",
                    "size": size,
                }
            except Exception:
                pass
    return index

def compare_indexes(idx_a, idx_b):
    all_keys = sorted(set(idx_a.keys()) | set(idx_b.keys()))
    rows = []
    for key in all_keys:
        a = idx_a.get(key)
        b = idx_b.get(key)
        a_size = a["size"] if a else None
        b_size = b["size"] if b else None
        r_type = (a or b)["type"] if (a or b) else "unknown"
        if a and b:
            status = "same-size" if a_size == b_size else "different-size"
        elif a and not b:
            status = "only-in-A"
        elif b and not a:
            status = "only-in-B"
        else:
            status = "unknown"
        rows.append({
            "path": key,
            "type": r_type,
            "level_a": a["level"] if a else None,
            "level_b": b["level"] if b else None,
            "a_size": a_size,
            "b_size": b_size,
            "status": status,
        })
    return rows

def categorize_app_externalizer(rows):
    from collections import defaultdict
    categories = defaultdict(lambda: {
        "count_a": 0, "count_b": 0, "size_a": 0, "size_b": 0
    })
    prefix = "Applications/.app-externalizer"
    for row in rows:
        if row["type"] != "file":
            continue
        path = row["path"]
        if not (path == prefix or path.startswith(prefix + "/")):
            continue
        fname = Path(path).name.lower()
        size_a = row["a_size"] or 0
        size_b = row["b_size"] or 0
        if "electron framework" in fname:
            cat = "core_framework"
        elif fname.endswith("locale.pak"):
            cat = "locale_pack"
        elif fname.endswith(".pak"):
            cat = "resource_pack"
        elif fname.endswith(".dat") or "snapshot" in fname:
            cat = "data_resource"
        elif size_a <= 100 and size_b <= 100:
            cat = "tiny_placeholder"
        else:
            cat = "other"
        categories[cat]["count_a"] += 1 if row["a_size"] is not None else 0
        categories[cat]["count_b"] += 1 if row["b_size"] is not None else 0
        categories[cat]["size_a"] += size_a
        categories[cat]["size_b"] += size_b
    return categories

def build_html(a_sum, b_sum, progress_pct, comparison, categories):
    same_size = sum(1 for r in comparison if r["status"] == "same-size")
    different_size = sum(1 for r in comparison if r["status"] == "different-size")
    only_a = sum(1 for r in comparison if r["status"] == "only-in-A")
    only_b = sum(1 for r in comparison if r["status"] == "only-in-B")
    cat_rows = []
    for cat, data in sorted(categories.items(), key=lambda x: x[0]):
        cat_rows.append(
            f"<tr><td>{cat}</td><td>{data['count_a']}</td><td>{fmt_bytes(data['size_a'])}</td>"
            f"<td>{data['count_b']}</td><td>{fmt_bytes(data['size_b'])}</td></tr>"
        )
    cat_table = "\n".join(cat_rows)
    summary_rows = []
    for r in comparison[:30]:
        summary_rows.append(
            f"<tr class='{r['status']}'><td><code>{r['path']}</code></td>"
            f"<td>{r['type']}</td><td>{fmt_bytes(r['a_size'])}</td><td>{fmt_bytes(r['b_size'])}</td>"
            f"<td>{r['status']}</td></tr>"
        )
    summary_table = "\n".join(summary_rows)
    html = f"""<!doctype html>
<html lang='es'>
<head>
  <meta charset='utf-8'>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <title>CloneWatch Informe</title>
  <style>
    body {{ background:#0b1020; color:#eef2ff; font-family:-apple-system,BlinkMacSystemFont,system-ui,sans-serif; margin:0; padding:0; }}
    header, section {{ padding:16px; }}
    h1 {{ margin-top:0; }}
    .cards {{ display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:12px; margin-bottom:16px; }}
    .card {{ background:#121a33; border:1px solid #2a3d71; border-radius:12px; padding:12px; box-shadow:0 4px 12px rgba(0,0,0,0.2); }}
    table {{ width:100%; border-collapse:collapse; margin-top:12px; font-size:0.9rem; }}
    th, td {{ border-bottom:1px solid #24345f; padding:6px 8px; text-align:left; }}
    thead th {{ background:#132042; position:sticky; top:0; }}
    .same-size td {{ background:rgba(40,167,69,0.10); }}
    .different-size td {{ background:rgba(255,193,7,0.10); }}
    .only-in-A td {{ background:rgba(220,53,69,0.10); }}
    .only-in-B td {{ background:rgba(13,110,253,0.10); }}
    .progress {{ font-size:2rem; font-weight:bold; }}
  </style>
</head>
<body>
  <header>
    <h1>CloneWatch</h1>
    <p>Informe generado el {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
    <p>Directorio A: <code>{ROOT_A}</code><br>Directorio B: <code>{ROOT_B}</code></p>
  </header>
  <section>
    <div class='cards'>
      <div class='card'><strong>Tamaño total A</strong><br>{fmt_bytes(a_sum['total_size'])}</div>
      <div class='card'><strong>Tamaño total B</strong><br>{fmt_bytes(b_sum['total_size'])}</div>
      <div class='card'><strong>Progreso de copia</strong><br><span class='progress'>{progress_pct:.2f}%</span></div>
      <div class='card'><strong>Ítems solo en A</strong><br>{only_a}</div>
      <div class='card'><strong>Ítems solo en B</strong><br>{only_b}</div>
      <div class='card'><strong>Mismo tamaño</strong><br>{same_size}</div>
      <div class='card'><strong>Distinto tamaño</strong><br>{different_size}</div>
    </div>
  </section>
  <section>
    <h2>Contenido de Applications/.app-externalizer</h2>
    <table>
      <thead><tr><th>Categoría</th><th>Ficheros en A</th><th>Tamaño en A</th><th>Ficheros en B</th><th>Tamaño en B</th></tr></thead>
      <tbody>{cat_table}</tbody>
    </table>
  </section>
  <section>
    <h2>Comparación (primeras 30 rutas)</h2>
    <table>
      <thead><tr><th>Ruta</th><th>Tipo</th><th>Tamaño A</th><th>Tamaño B</th><th>Estado</th></tr></thead>
      <tbody>{summary_table}</tbody>
    </table>
    <p>... el informe JSON contiene todas las rutas; solo se muestran las primeras 30 en la versión HTML.</p>
  </section>
  <section>
    <p>Para abrir este informe desde tu iPhone, sincronizá el archivo con Google Drive y abrilo en Safari desde la app Drive o Archivos. Si definís IP_ADDR, se generará un fichero .webloc para abrir el informe a través de un servidor local (python3 -m http.server 8000).</p>
  </section>
</body>
</html>"""
    return html

def create_webloc(ip: str, output_dir: Path):
    url = f"http://{ip}:8000/report.html"
    content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>URL</key>
    <string>{url}</string>
</dict>
</plist>"""
    webloc_path = output_dir / "CloneWatch.webloc"
    webloc_path.write_text(content, encoding="utf-8")
    print(f"Generado archivo .webloc en {webloc_path}")

def main():
    print("Escaneando directorio A...")
    idx_a = build_index(ROOT_A)
    print(f"Entradas en A: {len(idx_a)}")
    print("Escaneando directorio B...")
    idx_b = build_index(ROOT_B)
    print(f"Entradas en B: {len(idx_b)}")
    comparison = compare_indexes(idx_a, idx_b)
    a_total = idx_a.get(".", {}).get("size", 0) or 0
    b_total = idx_b.get(".", {}).get("size", 0) or 0
    progress = (b_total / a_total * 100) if a_total else 0.0
    a_sum = {
        "total_size": a_total,
        "files": sum(1 for v in idx_a.values() if v["type"] == "file"),
        "dirs": sum(1 for v in idx_a.values() if v["type"] == "dir"),
    }
    b_sum = {
        "total_size": b_total,
        "files": sum(1 for v in idx_b.values() if v["type"] == "file"),
        "dirs": sum(1 for v in idx_b.values() if v["type"] == "dir"),
    }
    categories = categorize_app_externalizer(comparison)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    report_json_path = OUTPUT_DIR / "report.json"
    report_html_path = OUTPUT_DIR / "report.html"
    json_data = {
        "generated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "root_a": str(ROOT_A),
        "root_b": str(ROOT_B),
        "summary_a": a_sum,
        "summary_b": b_sum,
        "progress_percentage": progress,
        "comparison": comparison,
        "categories": categories,
    }
    report_json_path.write_text(json.dumps(json_data, indent=2), encoding="utf-8")
    html_content = build_html(a_sum, b_sum, progress, comparison, categories)
    report_html_path.write_text(html_content, encoding="utf-8")
    print(f"Informe generado: {report_html_path}")
    print(f"Resumen JSON: {report_json_path}")
    if IP_ADDR:
        create_webloc(IP_ADDR, OUTPUT_DIR)
    print("Proceso completado.")

if __name__ == "__main__":
    main()
