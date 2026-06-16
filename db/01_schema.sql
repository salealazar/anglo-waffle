-- ============================================================================
--  LAB DE INYECCIÓN SQL — Esquema "lod" (logística de flota)
--  ----------------------------------------------------------------------------
--  Réplica SIMPLIFICADA y con DATOS SINTÉTICOS del esquema real de camiones.
--  NADA de esto son datos reales: es un laboratorio para enseñar SQL injection.
--
--  Este archivo crea el esquema `lod` con las tablas "de negocio". Las columnas
--  sensibles de conductores (national_id, salario, password_hash, ...) viven
--  aquí pero NO se exponen en la app: las 3 vistas de `app` las esconden.
--  Lo divertido del lab es que el rol de la app igual puede leerlas/escribirlas
--  si encuentras por dónde inyectar.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS lod;

-- ----------------------------------------------------------------------------
-- Clientes
-- ----------------------------------------------------------------------------
CREATE TABLE lod.customers (
    customer_id              varchar(15)  PRIMARY KEY,
    customer_name            varchar(150) NOT NULL,
    customer_type            varchar(30),
    credit_terms_days        integer,
    primary_freight_type     varchar(50),
    account_status           varchar(20),
    contract_start_date      date,
    annual_revenue_potential numeric(12,2)
);

-- ----------------------------------------------------------------------------
-- Conductores
--   Ojo: agregamos columnas SENSIBLES que un panel público jamás debería
--   mostrar (RUN, dirección, sueldo y el hash de la contraseña del conductor).
--   Las vistas de `app` las omiten a propósito.
-- ----------------------------------------------------------------------------
CREATE TABLE lod.drivers (
    driver_id          varchar(15) PRIMARY KEY,
    first_name         varchar(50) NOT NULL,
    last_name          varchar(50) NOT NULL,
    hire_date          date,
    termination_date   date,
    license_number     varchar(20),
    license_state      varchar(10),
    date_of_birth      date,
    home_terminal      varchar(50),
    employment_status  varchar(20),
    cdl_class          varchar(5),
    years_experience   integer,
    -- === columnas sensibles añadidas para el lab ===
    national_id        varchar(20),   -- RUN / documento de identidad
    personal_phone     varchar(30),
    home_address       varchar(150),
    base_salary_clp    numeric(12,2),
    password_hash      varchar(64)    -- hash (MD5) de la clave del portal del conductor
);

-- ----------------------------------------------------------------------------
-- Camiones
-- ----------------------------------------------------------------------------
CREATE TABLE lod.trucks (
    truck_id              varchar(15) PRIMARY KEY,
    unit_number           varchar(20),
    make                  varchar(50),
    model_year            integer,
    vin                   varchar(20) UNIQUE,
    acquisition_date      date,
    acquisition_mileage   integer,
    fuel_type             varchar(20),
    tank_capacity_gallons integer,
    status                varchar(20),
    home_terminal         varchar(50)
);

-- ----------------------------------------------------------------------------
-- Rutas
-- ----------------------------------------------------------------------------
CREATE TABLE lod.routes (
    route_id               varchar(15) PRIMARY KEY,
    origin_city            varchar(80) NOT NULL,
    origin_state           varchar(10) NOT NULL,
    destination_city       varchar(80) NOT NULL,
    destination_state      varchar(10) NOT NULL,
    typical_distance_miles integer,
    base_rate_per_mile     numeric(6,2),
    fuel_surcharge_rate    numeric(5,3),
    typical_transit_days   integer
);

-- ----------------------------------------------------------------------------
-- Cargas
-- ----------------------------------------------------------------------------
CREATE TABLE lod.loads (
    load_id             varchar(15) PRIMARY KEY,
    customer_id         varchar(15) NOT NULL REFERENCES lod.customers(customer_id),
    route_id            varchar(15) NOT NULL REFERENCES lod.routes(route_id),
    load_date           date,
    load_type           varchar(40),
    weight_lbs          integer,
    pieces              integer,
    revenue             numeric(12,2),
    fuel_surcharge      numeric(10,2),
    accessorial_charges numeric(10,2),
    load_status         varchar(20),
    booking_type        varchar(20)
);

-- ----------------------------------------------------------------------------
-- Viajes
-- ----------------------------------------------------------------------------
CREATE TABLE lod.trips (
    trip_id               varchar(15) PRIMARY KEY,
    load_id               varchar(15) UNIQUE REFERENCES lod.loads(load_id),
    driver_id             varchar(15) REFERENCES lod.drivers(driver_id),
    truck_id              varchar(15) REFERENCES lod.trucks(truck_id),
    dispatch_date         date,
    actual_distance_miles integer,
    actual_duration_hours numeric(6,2),
    fuel_gallons_used     numeric(8,2),
    average_mpg           numeric(5,2),
    idle_time_hours       numeric(6,2),
    trip_status           varchar(20)
);

-- ----------------------------------------------------------------------------
-- Mantenimiento
-- ----------------------------------------------------------------------------
CREATE TABLE lod.maintenance_records (
    maintenance_id      varchar(15) PRIMARY KEY,
    truck_id            varchar(15) REFERENCES lod.trucks(truck_id),
    maintenance_date    date,
    maintenance_type    varchar(40),
    odometer_reading    integer,
    labor_hours         numeric(6,2),
    labor_cost          numeric(10,2),
    parts_cost          numeric(10,2),
    total_cost          numeric(10,2),
    facility_location   varchar(80),
    downtime_hours      numeric(6,2),
    service_description varchar(150)
);

-- ----------------------------------------------------------------------------
-- Compras de combustible
-- ----------------------------------------------------------------------------
CREATE TABLE lod.fuel_purchases (
    fuel_purchase_id varchar(15) PRIMARY KEY,
    trip_id          varchar(15) REFERENCES lod.trips(trip_id),
    truck_id         varchar(15) REFERENCES lod.trucks(truck_id),
    driver_id        varchar(15) REFERENCES lod.drivers(driver_id),
    purchase_date    timestamp,
    location_city    varchar(80),
    location_state   varchar(10),
    gallons          numeric(8,2),
    price_per_gallon numeric(6,3),
    total_cost       numeric(10,2),
    fuel_card_number varchar(20)
);

-- ----------------------------------------------------------------------------
-- Métricas mensuales por camión
-- ----------------------------------------------------------------------------
CREATE TABLE lod.truck_utilization_metrics (
    truck_id           varchar(15) NOT NULL REFERENCES lod.trucks(truck_id),
    month              date        NOT NULL,
    trips_completed    integer,
    total_miles        integer,
    total_revenue      numeric(12,2),
    average_mpg        numeric(5,2),
    maintenance_events integer,
    maintenance_cost   numeric(12,2),
    downtime_hours     numeric(6,2),
    utilization_rate   numeric(5,3),
    PRIMARY KEY (truck_id, month)
);

-- ----------------------------------------------------------------------------
-- Métricas mensuales por conductor
-- ----------------------------------------------------------------------------
CREATE TABLE lod.driver_monthly_metrics (
    driver_id             varchar(15) NOT NULL REFERENCES lod.drivers(driver_id),
    month                 date        NOT NULL,
    trips_completed       integer,
    total_miles           integer,
    total_revenue         numeric(12,2),
    average_mpg           numeric(5,2),
    total_fuel_gallons    numeric(10,2),
    on_time_delivery_rate numeric(5,3),
    average_idle_hours    numeric(5,2),
    PRIMARY KEY (driver_id, month)
);
