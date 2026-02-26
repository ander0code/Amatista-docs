"""
Script: migrate_04_subir_imagenes_r2.py
Sube las imágenes locales de productos a Cloudflare R2
y actualiza url_publica + tamano_bytes en media_archivos.

Ejecutar con:
    /opt/anaconda3/bin/python3 migrate_04_subir_imagenes_r2.py
"""

import os
import json
import boto3
import psycopg2
from pathlib import Path

# ── Configuración ────────────────────────────────────────────────────────────
IMAGENES_DIR = Path(
    "/Users/joshsaune/Proyectos-J/J-soluciones/Amatista-docs/imagenes_descargadas"
)
MAPEO_JSON = IMAGENES_DIR / "mapeo_imagenes.json"

R2_ACCOUNT_ID = "d425012ba26f036cd67d95557fc4cf9b"
R2_ACCESS_KEY_ID = "996316ed50b960a2d89536bf312f2ce5"
R2_SECRET_ACCESS_KEY = (
    "467efb174b566b401441ebaa29b3bcbd5d97ddaa52003c3774b621be05a87d30"
)
R2_ENDPOINT_URL = "https://d425012ba26f036cd67d95557fc4cf9b.r2.cloudflarestorage.com"
R2_BUCKET = "amatista-dev"
# URL pública del bucket (sin trailing slash)
R2_PUBLIC_URL = "https://pub-d425012ba26f036cd67d95557fc4cf9b.r2.dev"

DB = dict(
    dbname="Amatista_dev",
    user="root",
    password="123456789",
    host="localhost",
    port=5432,
)

# ── Mapeo nombre_producto → archivo_local (del JSON) ──────────────────────────
with open(MAPEO_JSON) as f:
    mapeo_raw = json.load(f)

# nombre_amatista (lowercase) → archivo_local
nombre_a_archivo = {
    item["nombre_amatista"].lower().strip(): item["archivo_local"] for item in mapeo_raw
}


# ── MIME types ────────────────────────────────────────────────────────────────
def mime_from_ext(filename):
    ext = Path(filename).suffix.lower()
    return {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
        ".gif": "image/gif",
    }.get(ext, "application/octet-stream")


# ── Clientes ──────────────────────────────────────────────────────────────────
s3 = boto3.client(
    "s3",
    endpoint_url=R2_ENDPOINT_URL,
    aws_access_key_id=R2_ACCESS_KEY_ID,
    aws_secret_access_key=R2_SECRET_ACCESS_KEY,
    region_name="auto",
)

conn = psycopg2.connect(**DB)
cur = conn.cursor()

# ── Leer media_archivos + nombre del producto ─────────────────────────────────
cur.execute("""
    SELECT ma.id, ma.r2_key, ma.bucket_name, p.nombre
    FROM media_archivos ma
    JOIN productos p ON p.id = ma.entidad_id
    WHERE ma.entidad_tipo = 'producto'
    ORDER BY p.nombre
""")
rows = cur.fetchall()

print(f"Total imágenes a procesar: {len(rows)}\n")

ok = 0
fail = 0

for ma_id, r2_key, bucket_name, prod_nombre in rows:
    nombre_key = prod_nombre.lower().strip()
    archivo_local = nombre_a_archivo.get(nombre_key)

    if not archivo_local:
        print(f"  [SKIP] Sin mapeo para: '{prod_nombre}'")
        fail += 1
        continue

    local_path = IMAGENES_DIR / archivo_local
    if not local_path.exists():
        print(f"  [SKIP] Archivo no encontrado: {local_path}")
        fail += 1
        continue

    tamano = local_path.stat().st_size
    mime = mime_from_ext(archivo_local)

    try:
        # Subir a R2
        with open(local_path, "rb") as fh:
            s3.put_object(
                Bucket=R2_BUCKET,
                Key=r2_key,
                Body=fh,
                ContentType=mime,
            )

        # URL pública: https://pub-xxx.r2.dev/<r2_key>
        url_publica = f"{R2_PUBLIC_URL}/{r2_key}"

        # Actualizar DB
        cur.execute(
            """
            UPDATE media_archivos
            SET url_publica = %s, tamano_bytes = %s, updated_at = now()
            WHERE id = %s
        """,
            (url_publica, tamano, ma_id),
        )

        print(f"  [OK] {prod_nombre} → {r2_key} ({tamano:,} bytes)")
        ok += 1

    except Exception as e:
        print(f"  [ERROR] {prod_nombre}: {e}")
        fail += 1

conn.commit()
cur.close()
conn.close()

print(f"\n{'=' * 60}")
print(f"Subidas OK:     {ok}")
print(f"Fallidas/Skip:  {fail}")
print(f"{'=' * 60}")
