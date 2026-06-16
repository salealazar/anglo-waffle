-- ============================================================================
--  TABLAS SENSIBLES — el "tesoro" del laboratorio
--  ----------------------------------------------------------------------------
--  Estas tablas NO se muestran en ninguna parte de la app y NINGUNA vista las
--  expone. Representan información que la empresa guarda en la misma base de
--  datos pero que jamás debería ser pública:
--
--    * lod.driver_credentials  -> usuarios y hashes de los conductores
--    * lod.admin_accounts       -> cuentas administrativas del backoffice
--    * lod.classified_operations-> operaciones reservadas (carga real, escoltas)
--
--  El objetivo del alumno es descubrir que existen (enumerando el catálogo),
--  leer su contenido vía UNION y, como el rol de la app está sobre-privilegiado,
--  incluso MODIFICARLAS con consultas apiladas (stacked queries).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Credenciales de los conductores (portal del conductor)
-- ----------------------------------------------------------------------------
CREATE TABLE lod.driver_credentials (
    credential_id  varchar(15) PRIMARY KEY,
    driver_id      varchar(15) REFERENCES lod.drivers(driver_id),
    username       varchar(40) NOT NULL,
    password_hash  varchar(64) NOT NULL,   -- MD5 (¡débil a propósito!)
    password_algo  varchar(20) DEFAULT 'md5',
    role           varchar(20) DEFAULT 'driver',
    mfa_secret     varchar(40),
    failed_logins  integer     DEFAULT 0,
    last_login_at  timestamp,
    must_reset     boolean     DEFAULT false
);

-- ----------------------------------------------------------------------------
-- Cuentas administrativas del panel interno
-- ----------------------------------------------------------------------------
CREATE TABLE lod.admin_accounts (
    admin_id       varchar(15) PRIMARY KEY,
    username       varchar(40) NOT NULL UNIQUE,
    password_hash  varchar(64) NOT NULL,   -- MD5 (¡débil a propósito!)
    full_name      varchar(100),
    email          varchar(120),
    role           varchar(30),
    is_superuser   boolean DEFAULT false,
    last_login_at  timestamp,
    created_at     timestamp DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- Operaciones clasificadas (logística reservada)
--   La carga "declarada" es lo que aparece en papeles públicos; la "real" y el
--   valor del contrato son confidenciales.
-- ----------------------------------------------------------------------------
CREATE TABLE lod.classified_operations (
    op_id                       varchar(15) PRIMARY KEY,
    trip_id                     varchar(15) REFERENCES lod.trips(trip_id),
    client_codename             varchar(40),
    declared_cargo_description  varchar(150),
    real_cargo_description      varchar(150),
    security_level              varchar(20),
    escort_required             boolean,
    contract_value_clp          numeric(14,2),
    special_instructions        varchar(255),
    clearance_required          varchar(20)
);
