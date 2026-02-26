"""
MIGRACIÓN PARTE 1 — Amatista MySQL → ERP PostgreSQL
Tablas: roles, usuarios, perfiles_usuario, transportistas
Ejecutar: python migrate_01_roles_usuarios_transportistas.py
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

USERS_MYSQL = [
    # (id, name, email, rol, password_bcrypt, password_changed_at, created_at, updated_at)
    (
        1,
        "Administrador",
        "amatista@gmail.com",
        "admin",
        "$2y$12$D7ptRKWAcxeRZOlj6gNdS.GuBhqBcp5RXPoG4uonw1QgT9iQuRtey",
        None,
        "2026-02-07 20:29:27",
        "2026-02-07 20:29:27",
    ),
    (
        2,
        "rachely",
        "delevery@detallesamatista.com",
        "vendedor",
        "$2y$12$WCNIhUiyCyst/tsZxOx2cu9ruU33eFLz.Uuca8wwTe7UZTTdVkROu",
        None,
        "2026-02-07 20:58:00",
        "2026-02-09 19:42:18",
    ),
    (
        3,
        "Eneas",
        "detallesamatista01@gmail.com",
        "produccion",
        "$2y$12$5vWIy8/rQt43dfS5ctGUjua2z6.stHZOu9J6eh.CsMW6WQj7p3N/i",
        None,
        "2026-02-09 16:18:20",
        "2026-02-16 15:59:50",
    ),
    (
        4,
        "yamile",
        "detallesamatista86@gmail.com",
        "vendedor",
        "$2y$12$inZgqXwe5XPfnKkNy9ffyeQbSPtHfxxCO3PCzmevLP.FDMmbSjl3O",
        None,
        "2026-02-09 16:19:25",
        "2026-02-09 16:19:25",
    ),
    (
        5,
        "Tito",
        "tsaune@icloud.com",
        "produccion",
        "$2y$12$EGlhGyyXR9wl1M4VHiFvIOor7YqUyhrSEtyssiLgv9IO7nwkE8Try",
        None,
        "2026-02-13 17:19:55",
        "2026-02-13 17:19:55",
    ),
]

CONDUCTORES_MYSQL = [
    # (id, nombre, telefono, activo, last_lat, last_lng, last_location_at, preferencia_distrito, token, created_at, updated_at)
    (
        1,
        "Alejandro Canales",
        "990036869",
        1,
        -11.9052153,
        -77.0429542,
        "2026-02-14 19:42:04",
        "Cono Norte",
        "d966ea3e-2665-4dd7-9c4e-69f6798171e9",
        "2026-02-09 20:32:48",
        "2026-02-14 19:42:04",
    ),
    (
        2,
        "Cesar rivas",
        "987954662",
        1,
        None,
        None,
        None,
        "Cono Norte",
        "3b5c80ce-3181-4d63-b548-f0295229f73d",
        "2026-02-09 20:47:38",
        "2026-02-09 22:12:20",
    ),
    (
        3,
        "Christian Alexander",
        "904466705",
        1,
        None,
        None,
        None,
        "Conor Sur y Cercado",
        "b7070fa1-dbbc-432f-a7b8-fe109dffa7a6",
        "2026-02-12 16:04:59",
        "2026-02-12 16:04:59",
    ),
    (
        4,
        "Johan",
        "928649325",
        1,
        None,
        None,
        None,
        "Cono Norte y Cercado de Lima",
        "18bcfb21-0f81-4424-9ead-6310993c9550",
        "2026-02-12 16:05:55",
        "2026-02-12 16:05:55",
    ),
    (
        5,
        "joshymar saune",
        "933339798",
        1,
        -12.1151404,
        -77.0179744,
        "2026-02-13 17:37:01",
        "la molina",
        "2cfba198-36ff-40d3-b100-96b67c0170e3",
        "2026-02-12 20:48:34",
        "2026-02-13 17:37:01",
    ),
    (
        6,
        "Rafael Varela (MOTO)",
        "968652189",
        1,
        None,
        None,
        None,
        None,
        "62613ff5-e6d4-45d6-ae58-3fb3b4077559",
        "2026-02-13 20:45:01",
        "2026-02-14 00:13:25",
    ),
    (
        7,
        "Yesenia Aguirre",
        "932951056",
        1,
        -12.0588195,
        -77.0291782,
        "2026-02-14 18:58:35",
        "Conor Sur,Cono Norte.",
        "11c94784-4c82-4165-87d1-3f8c7a8d3075",
        "2026-02-14 00:18:54",
        "2026-02-14 18:58:35",
    ),
    (
        8,
        "Juan Carlos Tafur",
        "942130654",
        1,
        -12.0986204,
        -77.0354556,
        "2026-02-14 16:59:55",
        None,
        "e232126b-d549-4a5a-9c2b-97f4da564d3c",
        "2026-02-14 11:10:44",
        "2026-02-14 16:59:55",
    ),
    (
        9,
        "Luis Enrique",
        "944475324",
        1,
        None,
        None,
        None,
        None,
        "df42017f-2279-4385-ad48-0081b7ee0c18",
        "2026-02-14 13:53:56",
        "2026-02-14 13:53:56",
    ),
    (
        10,
        "fiorella sanchez",
        "982767685",
        1,
        -12.1184805,
        -76.9950784,
        "2026-02-14 16:59:59",
        None,
        "dfc6190d-2748-491f-91fb-77a47fb2463b",
        "2026-02-14 13:55:24",
        "2026-02-14 16:59:59",
    ),
    (
        11,
        "jose luis",
        "942349803",
        1,
        None,
        None,
        None,
        None,
        "4b55865c-9f64-4a68-bf96-d9b48e4ed850",
        "2026-02-21 15:08:49",
        "2026-02-21 15:08:49",
    ),
]


def parse_ts(ts_str):
    """Convierte string timestamp MySQL a datetime UTC."""
    if ts_str is None:
        return None
    dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
    return dt.replace(tzinfo=timezone.utc)


def convert_bcrypt(laravel_hash):
    """
    Laravel usa $2y$, Django bcrypt espera bcrypt$$2b$ (hashlib compatible).
    Django tiene soporte para $2y$ via django.contrib.auth.hashers.BCryptSHA256PasswordHasher
    pero el prefijo que guarda es 'bcrypt$$2b$...'.
    Cambiamos $2y$ → $2b$ y prefijamos 'bcrypt$'.
    """
    if laravel_hash.startswith("$2y$"):
        h = "$2b$" + laravel_hash[4:]
        return "bcrypt$" + h
    return laravel_hash


def split_name(full_name):
    parts = full_name.strip().split(" ", 1)
    first = parts[0]
    last = parts[1] if len(parts) > 1 else ""
    return first, last


def main():
    conn = psycopg2.connect(**DB_CONFIG)
    conn.autocommit = False
    cur = conn.cursor()

    print("=" * 60)
    print("MIGRACIÓN PARTE 1: roles, usuarios, perfiles, transportistas")
    print("=" * 60)

    # ── PASO 1: Crear roles ────────────────────────────────────────
    print("\n[1] Creando roles...")
    roles = [
        ("admin", "Administrador", "Acceso total al sistema."),
        ("vendedor", "Vendedor", "Gestión de pedidos y clientes."),
        ("produccion", "Producción", "Vista y gestión del estado de producción."),
    ]
    rol_id_map = {}  # codigo → uuid
    for codigo, nombre, descripcion in roles:
        rid = str(uuid.uuid4())
        rol_id_map[codigo] = rid
        cur.execute(
            """
            INSERT INTO roles (id, codigo, nombre, descripcion, is_active, created_at, updated_at)
            VALUES (%s, %s, %s, %s, TRUE, NOW(), NOW())
        """,
            (rid, codigo, nombre, descripcion),
        )
        print(f"   ✓ rol '{codigo}' → {rid}")

    # ── PASO 2: Migrar users → usuarios ───────────────────────────
    print("\n[2] Migrando usuarios...")
    user_id_map = {}  # mysql_id → uuid
    for (
        mysql_id,
        name,
        email,
        rol,
        password,
        pwd_changed_at,
        created_at,
        updated_at,
    ) in USERS_MYSQL:
        uid = str(uuid.uuid4())
        user_id_map[mysql_id] = uid
        first_name, last_name = split_name(name)
        is_admin = rol == "admin"
        django_password = convert_bcrypt(password)
        date_joined = parse_ts(created_at)

        cur.execute(
            """
            INSERT INTO usuarios (id, email, password, first_name, last_name,
                                  is_active, is_staff, is_superuser, date_joined)
            VALUES (%s, %s, %s, %s, %s, TRUE, %s, %s, %s)
        """,
            (
                uid,
                email,
                django_password,
                first_name,
                last_name,
                is_admin,
                is_admin,
                date_joined,
            ),
        )
        print(f"   ✓ usuario '{name}' ({email}) → {uid}")

    # ── PASO 3: Migrar users → perfiles_usuario ───────────────────
    print("\n[3] Creando perfiles de usuario...")
    for (
        mysql_id,
        name,
        email,
        rol,
        password,
        pwd_changed_at,
        created_at,
        updated_at,
    ) in USERS_MYSQL:
        uid = user_id_map[mysql_id]
        rol_uuid = rol_id_map.get(rol, rol_id_map["vendedor"])
        pid = str(uuid.uuid4())
        password_changed_at_dt = parse_ts(pwd_changed_at)
        updated_at_dt = parse_ts(updated_at)

        cur.execute(
            """
            INSERT INTO perfiles_usuario (id, usuario_id, rol_id, telefono,
                                          totp_enabled, totp_secret,
                                          password_changed_at, is_active,
                                          created_at, updated_at)
            VALUES (%s, %s, %s, '', FALSE, '', %s, TRUE, NOW(), %s)
        """,
            (pid, uid, rol_uuid, password_changed_at_dt, updated_at_dt),
        )
        print(f"   ✓ perfil para '{name}' (rol={rol})")

    # ── PASO 4: Migrar conductores → transportistas ───────────────
    print("\n[4] Migrando transportistas...")
    transportista_id_map = {}  # mysql_id → uuid
    for (
        mysql_id,
        nombre,
        telefono,
        activo,
        last_lat,
        last_lng,
        last_location_at,
        preferencia_distrito,
        token_str,
        created_at,
        updated_at,
    ) in CONDUCTORES_MYSQL:
        tid = str(uuid.uuid4())
        transportista_id_map[mysql_id] = tid

        # Validar UUID del token
        try:
            token_uuid = str(uuid.UUID(token_str))
        except (ValueError, AttributeError):
            token_uuid = str(uuid.uuid4())

        is_active = bool(activo)
        last_lat_r = round(float(last_lat), 7) if last_lat is not None else None
        last_lng_r = round(float(last_lng), 7) if last_lng is not None else None
        loc_at = parse_ts(last_location_at)
        pref_zona = preferencia_distrito or ""
        created_at_dt = parse_ts(created_at)
        updated_at_dt = parse_ts(updated_at)
        telefono_limpio = telefono.replace(" ", "")

        cur.execute(
            """
            INSERT INTO transportistas (
                id, nombre, telefono, email,
                tipo_vehiculo, placa, limite_pedidos_diario,
                is_active, last_lat, last_lng, last_location_at,
                preferencia_zona, token, app_nombre, tipo_transportista,
                created_at, updated_at
            ) VALUES (
                %s, %s, %s, '',
                '', '', 20,
                %s, %s, %s, %s,
                %s, %s, '', 'propio',
                %s, %s
            )
        """,
            (
                tid,
                nombre,
                telefono_limpio,
                is_active,
                last_lat_r,
                last_lng_r,
                loc_at,
                pref_zona,
                token_uuid,
                created_at_dt,
                updated_at_dt,
            ),
        )
        print(f"   ✓ transportista '{nombre}' → {tid}")

    conn.commit()
    print("\n✅ PARTE 1 completada exitosamente.")

    # Imprimir mappings para las siguientes partes
    print("\n── USER ID MAP (mysql_id → uuid) ──")
    for k, v in user_id_map.items():
        print(f"   {k} → {v}")
    print("\n── TRANSPORTISTA ID MAP (mysql_id → uuid) ──")
    for k, v in transportista_id_map.items():
        print(f"   {k} → {v}")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
