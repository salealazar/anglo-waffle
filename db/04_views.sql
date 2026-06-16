-- ============================================================================
--  VISTAS PÚBLICAS (esquema `app`)
--  ----------------------------------------------------------------------------
--  La aplicación SOLO consulta estas 3 vistas. Están diseñadas para mostrar
--  estadísticas agregadas y ESCONDER la información sensible de los conductores
--  (RUN, dirección, sueldo, hash de contraseña, apellido completo, etc.).
--
--  La trampa pedagógica: las vistas esconden columnas, pero NO protegen la base.
--  Si el endpoint de búsqueda concatena texto del usuario, un UNION puede leer
--  cualquier tabla que el rol de la app alcance — vistas incluidas o no.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS app;

-- ----------------------------------------------------------------------------
-- 1) Resumen de flota por camión  (sin datos de conductor)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW app.v_fleet_overview AS
SELECT
    t.unit_number,
    t.make,
    t.model_year,
    t.status,
    t.home_terminal,
    COALESCE(SUM(m.trips_completed), 0)        AS trips_completed,
    COALESCE(SUM(m.total_miles), 0)            AS total_miles,
    COALESCE(ROUND(AVG(m.average_mpg), 2), 0)  AS avg_mpg,
    COALESCE(ROUND(AVG(m.utilization_rate), 3),0) AS utilization_rate
FROM lod.trucks t
LEFT JOIN lod.truck_utilization_metrics m ON m.truck_id = t.truck_id
GROUP BY t.unit_number, t.make, t.model_year, t.status, t.home_terminal;

-- ----------------------------------------------------------------------------
-- 2) Ranking de conductores  (PII oculta: solo nombre + inicial del apellido)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW app.v_driver_leaderboard AS
SELECT
    'CL-' || substr(d.driver_id, 4)                       AS driver_code,
    d.first_name || ' ' || left(d.last_name, 1) || '.'    AS display_name,
    d.home_terminal,
    COALESCE(SUM(m.trips_completed), 0)                   AS trips_completed,
    COALESCE(SUM(m.total_miles), 0)                       AS total_miles,
    COALESCE(ROUND(AVG(m.on_time_delivery_rate), 3), 0)   AS on_time_rate,
    COALESCE(ROUND(AVG(m.average_mpg), 2), 0)             AS avg_mpg,
    COALESCE(ROUND(SUM(m.total_fuel_gallons), 1), 0)      AS total_fuel_gallons
FROM lod.drivers d
LEFT JOIN lod.driver_monthly_metrics m ON m.driver_id = d.driver_id
GROUP BY d.driver_id, d.first_name, d.last_name, d.home_terminal;

-- ----------------------------------------------------------------------------
-- 3) Economía por ruta  (agregado de cargas)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW app.v_route_economics AS
SELECT
    r.route_id                                AS route_code,
    r.origin_city,
    r.origin_state,
    r.destination_city,
    r.destination_state,
    r.typical_distance_miles                  AS distance_miles,
    COUNT(l.load_id)                          AS loads_count,
    COALESCE(ROUND(SUM(l.revenue), 0), 0)     AS total_revenue,
    COALESCE(ROUND(AVG(l.revenue), 0), 0)     AS avg_revenue,
    r.typical_transit_days                    AS avg_transit_days
FROM lod.routes r
LEFT JOIN lod.loads l ON l.route_id = r.route_id
GROUP BY r.route_id, r.origin_city, r.origin_state, r.destination_city,
         r.destination_state, r.typical_distance_miles, r.typical_transit_days;
