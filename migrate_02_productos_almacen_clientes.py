"""
MIGRACIÓN PARTE 2 — Amatista MySQL → ERP PostgreSQL
Tablas: almacenes, productos, stock, clientes
REQUIERE: haber ejecutado migrate_01 primero (para tener perfiles_usuario para creado_por_id)
Ejecutar: python migrate_02_productos_almacen_clientes.py
"""

import psycopg2
import uuid
from datetime import datetime, timezone

DB_CONFIG = {
    "dbname": "Amatista_dev",
    "user": "root",
    "password": "123456789",
    "host": "localhost",
    "port": 5432,
}

# ─── DATOS DEL DUMP MySQL ──────────────────────────────────────────────────────

PRODUCTOS_MYSQL = [
    # (id, nombre, precio, stock, imagen, activo, created_at, updated_at)
    (
        1,
        "pasion eterna",
        299.00,
        10,
        "productos/FjGzfxDINlOjpiNXChkEYF4TOkMtvSl6EW7bJvHG.jpg",
        1,
        "2026-02-07 21:10:00",
        "2026-02-14 18:59:21",
    ),
    (
        2,
        "encanto rojo",
        260.00,
        None,
        "productos/htgyMeo4x0PJhuzQhn4qNYlBJeSMmZMVmDtycaur.jpg",
        1,
        "2026-02-07 21:10:33",
        "2026-02-09 22:26:24",
    ),
    (
        3,
        "box 50 rosas premiun",
        299.00,
        9,
        "productos/t7VfVVOEwkE4ymlGPn5OXsH7VfDJxDqtEy8148Mw.jpg",
        1,
        "2026-02-07 21:11:30",
        "2026-02-23 19:38:13",
    ),
    (
        4,
        "bouquet 50 rosas rojas",
        179.00,
        20,
        "productos/E7iWeA86pVw2tOJs6GwGlpcddQ2LIViANCCKXngM.jpg",
        1,
        "2026-02-07 21:12:00",
        "2026-02-23 19:37:50",
    ),
    (
        5,
        "bouquet amor supremo",
        299.00,
        9,
        "productos/fkvsSndpD4inrV1X5F9GKULag2EMzPYKv8OjlD3h.webp",
        1,
        "2026-02-07 21:12:15",
        "2026-02-14 00:36:32",
    ),
    (
        6,
        "bouquet 12 rosas pasion",
        99.00,
        38,
        "productos/TVvVOXhaK7pHcpWqDjqq6o0H8fOZAZAeyks39quS.jpg",
        1,
        "2026-02-07 21:12:40",
        "2026-02-23 19:37:59",
    ),
    (
        7,
        "ramo sol radiante",
        169.00,
        None,
        "productos/WiWsS0QiUh8umBWM7CKNOkGmP2LE687yv9afbeK1.jpg",
        1,
        "2026-02-07 21:13:37",
        "2026-02-13 15:14:40",
    ),
    (
        8,
        "cesta amor infinito",
        499.00,
        None,
        "productos/KLWJhSFjBYDf6aVX1o7zHUaUgySCdKgLWfsgvjqd.jpg",
        1,
        "2026-02-07 21:14:04",
        "2026-02-09 22:24:51",
    ),
    (
        9,
        "box oso enamorado",
        229.00,
        None,
        "productos/vhNum9iowVArDcmmjzqYoQH3yCNu3RBKlO7EQifH.jpg",
        1,
        "2026-02-07 21:14:22",
        "2026-02-09 22:23:56",
    ),
    (
        10,
        "globo corona de amor",
        199.00,
        None,
        "productos/kHioMQHCjZP9IeS8Nz2VY2eM60oseAVfTmNuKl7V.jpg",
        1,
        "2026-02-07 21:14:52",
        "2026-02-13 16:01:47",
    ),
    (
        11,
        "box princess",
        109.00,
        None,
        "productos/Ty6Y6tfT7PVRwS6dcim0Q0xBhZAyUhROd6k75GAc.jpg",
        1,
        "2026-02-09 15:09:40",
        "2026-02-23 19:38:22",
    ),
    (
        12,
        "box princess red",
        109.00,
        None,
        "productos/5ZJs7GxDfXrD2CTm8YKjSrPBsSnrkdLtPzDs6mjk.jpg",
        1,
        "2026-02-09 15:21:33",
        "2026-02-23 19:38:33",
    ),
    (
        13,
        "lluvia de tulipanes",
        279.00,
        None,
        "productos/p8T9b0XJhBZSUFdDvasqAQlSGZpVy303EtWxMBdt.jpg",
        1,
        "2026-02-09 15:25:58",
        "2026-02-13 20:15:43",
    ),
    (
        14,
        "orquidea blanca",
        199.00,
        None,
        "productos/g1kTnED1Wlaf3ta3lH7mAHs0CSUh6zZP7ENwZM2Y.jpg",
        1,
        "2026-02-09 15:37:53",
        "2026-02-09 22:27:03",
    ),
    (
        15,
        "orquidea lila",
        199.00,
        None,
        "productos/eOU1vroCZOLYv6rWJhMHVebDF5vkDIMSQzQvSdBO.jpg",
        1,
        "2026-02-09 15:38:13",
        "2026-02-09 22:27:13",
    ),
    (
        16,
        "ramo 10 tulipanes",
        165.00,
        17,
        "productos/SwnaOQyVIqj9iUOGaSijGuZktXuVkCu3nV3x2gak.jpg",
        1,
        "2026-02-09 15:39:51",
        "2026-02-18 15:47:43",
    ),
    (
        17,
        "dulce romance",
        305.00,
        None,
        "productos/yesFPZEKCsFgIGjyc3U5t4oBGvfjj1HP8aan3Xbh.jpg",
        1,
        "2026-02-09 15:41:33",
        "2026-02-09 22:25:18",
    ),
    (
        18,
        "dulzura en burbuja",
        169.00,
        None,
        "productos/fePr8K2PSUBlCOLCtUp4HlC9jeoPM1XmlxyqnBYA.jpg",
        1,
        "2026-02-09 15:42:24",
        "2026-02-09 22:25:47",
    ),
    (
        19,
        "chocolate ferrero roche",
        36.00,
        None,
        "productos/UanZDSt7NGYY9BZTsxL3Y7FhfDgAWVTo2W5dSQg2.jpg",
        1,
        "2026-02-11 23:38:24",
        "2026-02-11 23:38:24",
    ),
    (
        20,
        "chocolate hershey rosado",
        36.00,
        None,
        "productos/OWPhfSJCBGMjfKKr9yIihJjecoRvVRYy42Mf7F37.jpg",
        1,
        "2026-02-11 23:39:09",
        "2026-02-11 23:39:09",
    ),
    (
        21,
        "chocolate hersheys rojo",
        36.00,
        None,
        "productos/XPNHvWsaSYWYXJqlQy7kDEuQhBkj2PLPGxr9wPmW.jpg",
        1,
        "2026-02-11 23:39:28",
        "2026-02-11 23:39:28",
    ),
    (
        22,
        "love in and box red princess",
        119.00,
        6,
        "productos/utZQvyctJV3mOifvJOVGrTxbKJ6V30plSdERLuJo.jpg",
        1,
        "2026-02-12 20:08:07",
        "2026-02-14 16:28:37",
    ),
    (
        23,
        "caja de tulipanes",
        199.00,
        None,
        "productos/fJdMyrdeNua44Dr9DgvlYd3CDeloss0POhqIfuNI.webp",
        1,
        "2026-02-13 00:42:27",
        "2026-02-13 00:42:27",
    ),
    (
        24,
        "globo burbuja",
        30.00,
        None,
        "productos/kjqav9ASiCCMeq0fIYGVgIq2gWrv7xIjrT9ALxlq.jpg",
        1,
        "2026-02-13 22:05:55",
        "2026-02-13 22:05:55",
    ),
    (
        25,
        "lleno de amor",
        170.00,
        None,
        "productos/dovoAL56qz6lD8EzA5PeFfwKdG7easdqEnqjP0gE.jpg",
        1,
        "2026-02-18 19:41:31",
        "2026-02-18 19:41:31",
    ),
    (
        26,
        "locura de amor",
        269.00,
        None,
        "productos/SoW7tG0ngGzZaMxo9O8Dv03GJrbfgvqYKOiiiRmk.jpg",
        1,
        "2026-02-19 14:47:15",
        "2026-02-19 14:47:15",
    ),
    (
        27,
        "Juntos y felices",
        217.00,
        None,
        "productos/gyvrJWHQzZp0nU2zrknMw3vK8NRxRKy9Z7z66TbU.jpg",
        1,
        "2026-02-20 13:25:36",
        "2026-02-20 13:25:36",
    ),
    (
        28,
        "happy birthaday",
        185.00,
        None,
        "productos/xdaPZ2j7hn2IzNRdyh8jYoTwl5nUlhDRBtawK9UN.jpg",
        1,
        "2026-02-20 20:36:45",
        "2026-02-20 20:36:45",
    ),
    (
        29,
        "jardin de emosiones",
        199.00,
        None,
        "productos/cJC5RnqcNCffYJOuIDPrs8petuni2FU0GWhiJceA.jpg",
        1,
        "2026-02-21 19:09:53",
        "2026-02-21 19:09:53",
    ),
    (
        30,
        "versos de amor",
        125.00,
        None,
        "productos/SQepzb7rmRWzFk5br1yN0I3VvkQ9rWTuhwlBHNow.jpg",
        1,
        "2026-02-21 19:11:05",
        "2026-02-21 19:11:05",
    ),
    (
        31,
        "caja de 12 rosas",
        70.00,
        None,
        "productos/7eWw2xLqb2HrIUgjgJWgEPIvwvanyE9DVnnnOQcI.jpg",
        1,
        "2026-02-21 20:14:26",
        "2026-02-21 20:14:26",
    ),
    (
        32,
        "arreglo personalizado",
        213.92,
        None,
        "productos/o4MbbEO7OyTXKkgFtV4ge3VjMEWPYf6uF2kiU9Z9.jpg",
        1,
        "2026-02-21 21:28:10",
        "2026-02-21 23:30:55",
    ),
    (
        33,
        "ramo de 6 rosas",
        60.00,
        None,
        "productos/CNkkpQrrKeRPpbFRNQqyVWNfLUrTpFVpeVyZ3SOi.jpg",
        1,
        "2026-02-24 17:09:06",
        "2026-02-24 17:09:06",
    ),
    (
        34,
        "atardecer de rosas",
        199.00,
        None,
        "productos/UlT9sEBNaYyP8iFBYtDLOYu2QcWoL1j687nMYZST.jpg",
        1,
        "2026-02-24 19:55:12",
        "2026-02-24 19:55:12",
    ),
    (
        35,
        "rayo de sol",
        49.00,
        None,
        "productos/3WS1liV1tzJqsMaamiNZuh8AyXGnwcDIywwvknb5.jpg",
        1,
        "2026-02-25 13:40:30",
        "2026-02-25 13:40:30",
    ),
]

# Clientes únicos de reporte_entregas, deduplicados por teléfono normalizado
# Formato: (nombre_cliente, telefono_cliente_raw, created_at_primer_pedido)
REPORTE_ENTREGAS_CLIENTES = [
    # telefono normalizado → (nombre, telefono_raw, created_at)
    ("WG", "958690844", "2026-02-09 15:58:03"),
    ("nelson tasayco", "944269091", "2026-02-09 16:02:39"),
    ("gary", "994707723", "2026-02-09 16:09:45"),
    ("Juantxo Guibelalde", "949699075", "2026-02-09 19:07:18"),
    ("Marcelo Zamora", "994747887", "2026-02-09 22:19:06"),
    ("Rafa", "929282696", "2026-02-09 23:43:06"),
    ("Ricardo Aguilar", "946583545", "2026-02-10 19:35:13"),
    ("gerar", "913801174", "2026-02-10 20:15:05"),
    ("ramon deheza", "998178066", "2026-02-11 17:51:56"),
    ("rodrigo lara", "953844607", "2026-02-11 18:10:43"),
    ("luis morales", "18313321425", "2026-02-11 18:32:56"),
    ("marcela  ruiz gonzales", "987768037", "2026-02-11 20:56:21"),
    ("wilson", "929625071", "2026-02-11 23:43:58"),
    ("sin nombre", "906946932", "2026-02-11 23:54:00"),
    ("Wilmer Matos", "953844397", "2026-02-12 00:49:30"),
    ("jhon mejias", "941958045", "2026-02-12 15:59:46"),
    ("roberto blados", "940233983", "2026-02-12 17:25:01"),
    ("Ernesto Jaimes", "993453058", "2026-02-12 20:19:59"),
    ("Jorge Hoyos", "978725040", "2026-02-12 20:24:29"),
    ("Darwib", "989271457", "2026-02-12 21:17:36"),
    ("klein", "943550891", "2026-02-12 22:10:06"),
    ("Bruno Francisco", "946540193", "2026-02-13 00:34:24"),
    ("alain", "997893193", "2026-02-13 00:47:22"),
    ("Carlos Paredes", "993136116", "2026-02-13 01:31:01"),
    ("Erick Chinchayau", "949559787", "2026-02-13 01:47:58"),
    ("cristian", "996890207", "2026-02-13 02:32:43"),
    ("Rogger", "991128850", "2026-02-13 03:32:05"),
    ("piero paz", "992495184", "2026-02-13 14:04:13"),
    ("miguel", "991117104", "2026-02-13 15:25:28"),
    ("arom", "998809922", "2026-02-13 15:29:13"),
    ("Pame", "992898130", "2026-02-13 15:37:17"),
    ("anonimo", "99999999", "2026-02-13 16:04:21"),
    ("franz", "983702130", "2026-02-13 16:45:47"),
    ("ricardo", "981449594", "2026-02-13 17:07:04"),
    ("juanga", "912474371", "2026-02-13 17:47:11"),
    ("carlos", "945869800", "2026-02-13 18:09:51"),
    ("breña zorritos", "932191291", "2026-02-13 19:07:49"),
    ("Ernesto Laq Puente", "980100419", "2026-02-13 19:09:43"),
    ("agente", "939621548", "2026-02-13 19:18:36"),
    ("TANIA", "913947574", "2026-02-13 19:30:57"),
    ("nicolas paz", "932908282", "2026-02-13 19:39:46"),
    ("MICAHEL", "935736037", "2026-02-13 20:16:34"),
    ("jhony gomesz", "900740395", "2026-02-13 20:35:06"),
    ("Johan Chauca", "943955117", "2026-02-13 20:48:52"),
    ("Renzo", "981541936", "2026-02-13 20:55:19"),
    ("GIAN CARLO FLORES CACERES", "99999999", "2026-02-13 21:00:49"),
    ("mathias sanchez", "964306164", "2026-02-13 21:57:36"),
    ("quintana", "989208168", "2026-02-13 22:04:30"),
    ("anonimo", "992369179", "2026-02-13 22:08:24"),
    ("lucero", "929159042", "2026-02-13 22:24:24"),
    ("newstor valdivia", "943546986", "2026-02-13 22:49:55"),
    ("juan carlos", "990034988", "2026-02-13 23:39:26"),
    ("anonimo", "921138185", "2026-02-14 00:14:17"),
    ("jose manuel", "982017029", "2026-02-14 00:43:09"),
    ("marcos", "999972573", "2026-02-14 01:29:02"),
    ("kimen alex", "963835734", "2026-02-14 01:54:51"),
    ("siu tong", "936819963", "2026-02-14 02:00:38"),
    ("carla", "19543933252", "2026-02-14 02:20:57"),
    ("bryan", "986825774", "2026-02-14 02:23:37"),
    ("alfredo Davalos", "983407372", "2026-02-14 02:27:47"),
    ("jose alejandro", "986689732", "2026-02-14 02:30:05"),
    ("mi vida eres tu", "953564975", "2026-02-14 02:32:39"),
    ("nat", "992655004", "2026-02-14 03:03:12"),
    ("oscar", "942450199", "2026-02-14 13:37:26"),
    ("jose luis", "992254283", "2026-02-14 14:52:49"),
    ("joaquin", "934809674", "2026-02-14 15:00:29"),
    ("ciente anonimo", "932988132", "2026-02-14 15:54:21"),
    ("Juan Veliz", "959182533", "2026-02-14 15:56:54"),
    ("richie orozco", "992148873", "2026-02-14 17:31:28"),
    ("CD Eddi garcia", "951300093", "2026-02-14 17:50:31"),
    ("tomas morales", "961826327", "2026-02-14 18:04:01"),
    ("sanme", "953501678", "2026-02-14 18:18:04"),
    ("oscar jamas  chacceri", "977839215", "2026-02-14 19:18:50"),
    ("j torres", "981550874", "2026-02-14 19:19:50"),
    ("benjamin peña", "966083511", "2026-02-14 19:32:15"),
    ("dam hnt", "966261626", "2026-02-14 19:35:57"),
    ("raul", "17023021204", "2026-02-16 15:08:23"),
    ("jesus", "943882488", "2026-02-16 15:31:32"),
    ("dennis", "980446179", "2026-02-18 14:44:18"),
    ("dana ross", "968095082", "2026-02-18 19:44:28"),
    ("Andrea Lozada", "947275559", "2026-02-19 14:50:35"),
    ("fghjjv", "941260085", "2026-02-20 13:28:09"),
    ("Juan Mayo", "34637193919", "2026-02-21 19:18:44"),
    ("Luis Angel", "996006943", "2026-02-21 20:21:35"),
    ("edwin", "990336012", "2026-02-21 21:30:43"),
    ("rossana ciccia", "994226352", "2026-02-23 19:41:03"),
    ("ej de rita", "34681262397", "2026-02-24 16:57:43"),
    ("diego TMM", "961499562", "2026-02-24 16:59:39"),
    ("karin quijada", "937009402", "2026-02-24 17:08:32"),
    ("tori", "976564025", "2026-02-24 19:57:18"),
    ("Aaron", "998809922", "2026-02-25 13:42:37"),
    ("cristian palomino", "988653793", "2026-02-25 13:44:54"),
]


def parse_ts(ts_str):
    if ts_str is None:
        return None
    dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
    return dt.replace(tzinfo=timezone.utc)


def normalize_phone(phone):
    """Quita espacios, +51 y +."""
    p = phone.replace(" ", "").replace("-", "")
    if p.startswith("+51"):
        p = p[3:]
    elif p.startswith("+"):
        p = p[1:]
    return p[:20]


def mime_from_path(path):
    if path and path.lower().endswith(".webp"):
        return "image/webp"
    return "image/jpeg"


def get_admin_perfil_id(cur):
    """Obtiene el UUID del perfil del administrador (para creado_por_id)."""
    cur.execute("""
        SELECT pu.id FROM perfiles_usuario pu
        JOIN usuarios u ON u.id = pu.usuario_id
        WHERE u.email = 'amatista@gmail.com'
        LIMIT 1
    """)
    row = cur.fetchone()
    if row:
        return str(row[0])
    return None


def main():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    cur = conn.cursor()

    print("=" * 60)
    print("MIGRACIÓN PARTE 2: almacén, productos, stock, clientes")
    print("=" * 60)

    # Obtener creado_por_id (admin)
    admin_perfil_id = get_admin_perfil_id(cur)
    if not admin_perfil_id:
        print(
            "ERROR: No se encontró perfil del administrador. Ejecutar parte 1 primero."
        )
        conn.close()
        return

    print(f"\n   Admin perfil_id: {admin_perfil_id}")

    # ── PASO 5: Crear almacén principal ──────────────────────────
    print("\n[5] Creando almacén principal...")
    almacen_id = str(uuid.uuid4())
    cur.execute(
        """
        INSERT INTO almacenes (id, nombre, direccion, sucursal, es_principal, is_active, created_at, updated_at)
        VALUES (%s, 'Almacén Principal', '', '', TRUE, TRUE, NOW(), NOW())
    """,
        (almacen_id,),
    )
    print(f"   ✓ Almacén Principal → {almacen_id}")

    # ── PASO 6: Migrar productos ──────────────────────────────────
    print("\n[6] Migrando productos...")
    producto_id_map = {}  # mysql_id → uuid
    for (
        mysql_id,
        nombre,
        precio,
        stock,
        imagen,
        activo,
        created_at,
        updated_at,
    ) in PRODUCTOS_MYSQL:
        pid = str(uuid.uuid4())
        producto_id_map[mysql_id] = pid
        sku = f"PROD-{mysql_id:03d}"
        is_active = bool(activo)
        stock_maximo = float(stock) if stock is not None else 0.0
        created_at_dt = parse_ts(created_at)
        updated_at_dt = parse_ts(updated_at)

        cur.execute(
            """
            INSERT INTO productos (
                id, sku, nombre, descripcion, codigo_barras,
                categoria_id, unidad_medida,
                precio_compra, precio_venta,
                codigo_afectacion_igv,
                stock_minimo, stock_maximo,
                requiere_lote, requiere_serie,
                is_active, creado_por_id, actualizado_por_id,
                created_at, updated_at
            ) VALUES (
                %s, %s, %s, '', '',
                NULL, 'NIU',
                0, %s,
                '10',
                0, %s,
                FALSE, FALSE,
                %s, %s, NULL,
                %s, %s
            )
        """,
            (
                pid,
                sku,
                nombre,
                float(precio),
                stock_maximo,
                is_active,
                admin_perfil_id,
                created_at_dt,
                updated_at_dt,
            ),
        )
        print(f"   ✓ producto [{mysql_id}] '{nombre}' → {pid}")

    # ── PASO 7: Crear registros de stock ──────────────────────────
    print("\n[7] Creando registros de stock...")
    for (
        mysql_id,
        nombre,
        precio,
        stock,
        imagen,
        activo,
        created_at,
        updated_at,
    ) in PRODUCTOS_MYSQL:
        pid = producto_id_map[mysql_id]
        cantidad = float(stock) if stock is not None else 0.0
        sid = str(uuid.uuid4())
        cur.execute(
            """
            INSERT INTO stock (id, producto_id, almacen_id, cantidad, created_at, updated_at)
            VALUES (%s, %s, %s, %s, NOW(), NOW())
        """,
            (sid, pid, almacen_id, cantidad),
        )
    print(f"   ✓ {len(PRODUCTOS_MYSQL)} registros de stock creados")

    # ── PASO 8: Registrar imágenes en media_archivos (sin subir a R2) ──
    print("\n[8] Registrando imágenes en media_archivos (path origen, sin R2)...")
    for (
        mysql_id,
        nombre,
        precio,
        stock,
        imagen,
        activo,
        created_at,
        updated_at,
    ) in PRODUCTOS_MYSQL:
        if not imagen:
            continue
        pid = producto_id_map[mysql_id]
        nombre_archivo = imagen.split("/")[-1]
        mime = mime_from_path(imagen)
        mid = str(uuid.uuid4())
        # r2_key y url_publica vacíos — pendiente de subida manual a R2
        cur.execute(
            """
            INSERT INTO media_archivos (
                id, entidad_tipo, entidad_id, tipo_archivo,
                nombre_original, r2_key, url_publica,
                mime_type, tamano_bytes, es_principal,
                orden, alt_text, bucket_name, r2_metadata,
                is_active, created_at, updated_at
            ) VALUES (
                %s, 'producto', %s, 'imagen',
                %s, %s, '',
                %s, 1, TRUE,
                0, %s, '', NULL,
                TRUE, NOW(), NOW()
            )
        """,
            (mid, pid, nombre_archivo, imagen, mime, nombre),
        )
    print(
        f"   ✓ {len(PRODUCTOS_MYSQL)} imágenes registradas en media_archivos (r2_key = path origen)"
    )

    # ── PASO 9: Extraer clientes únicos de reporte_entregas ───────
    print("\n[9] Migrando clientes únicos...")
    cliente_phone_map = {}  # telefono_normalizado → uuid
    numero_doc_counter = 10000000  # base para docs temporales únicos

    # Deduplicar por teléfono normalizado (primer registro gana)
    seen_phones = {}
    for nombre, telefono_raw, created_at_str in REPORTE_ENTREGAS_CLIENTES:
        tel_norm = normalize_phone(telefono_raw)
        if tel_norm not in seen_phones:
            seen_phones[tel_norm] = (nombre, telefono_raw, created_at_str)

    for tel_norm, (nombre, telefono_raw, created_at_str) in seen_phones.items():
        cid = str(uuid.uuid4())
        cliente_phone_map[tel_norm] = cid
        numero_doc = str(numero_doc_counter)
        numero_doc_counter += 1
        created_at_dt = parse_ts(created_at_str)

        cur.execute(
            """
            INSERT INTO clientes (
                id, tipo_documento, numero_documento,
                razon_social, nombre_comercial,
                telefono, email, direccion, ubigeo,
                segmento, limite_credito, is_active,
                creado_por_id, actualizado_por_id,
                created_at, updated_at
            ) VALUES (
                %s, '0', %s,
                %s, %s,
                %s, '', '', '',
                'nuevo', 0, TRUE,
                %s, NULL,
                %s, %s
            )
        """,
            (
                cid,
                numero_doc,
                nombre[:200],
                nombre[:200],
                tel_norm[:20],
                admin_perfil_id,
                created_at_dt,
                created_at_dt,
            ),
        )

    print(f"   ✓ {len(seen_phones)} clientes únicos migrados")

    conn.commit()
    print("\n✅ PARTE 2 completada exitosamente.")
    print(f"\n   Almacén ID: {almacen_id}")
    print(f"   Productos migrados: {len(producto_id_map)}")
    print(f"   Clientes migrados: {len(cliente_phone_map)}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
