-- ============================================================================
--  DATOS SINTÉTICOS (100% ficticios) para poblar el laboratorio.
--  ----------------------------------------------------------------------------
--  Las contraseñas se guardan como MD5 a propósito (débil y crackeable en clase).
--
--  CLAVES EN CLARO (para el profesor — los alumnos deben "descubrirlas"):
--    Conductores (lod.driver_credentials / lod.drivers.password_hash):
--      crojas      -> 123456        mfuentes  -> password
--      vsoto       -> qwerty        jmunoz    -> camion123
--      adiaz       -> antonia       bcastro   -> flota2025
--      jmorales    -> javiera1      sreyes    -> santiago
--      fvega       -> fernanda      therrera  -> tomas2025
--    Admin (lod.admin_accounts):
--      admin       -> admin123      operaciones -> flota2025
--      ti.soporte  -> password      auditor     -> 123456
-- ============================================================================

SELECT setseed(0.4242);   -- random() reproducible dentro de este archivo

-- ----------------------------------------------------------------------------
-- Clientes
-- ----------------------------------------------------------------------------
INSERT INTO lod.customers
  (customer_id, customer_name, customer_type, credit_terms_days, primary_freight_type, account_status, contract_start_date, annual_revenue_potential) VALUES
  ('CUS001','Cencosud Logística S.A.','retail',     45,'Paletizado seco','active', '2021-03-01', 1850000000),
  ('CUS002','Falabella Retail',        'retail',     60,'Paletizado seco','active', '2020-07-15', 2400000000),
  ('CUS003','Minera Andes Norte',      'mining',     30,'Carga industrial','active','2022-01-10', 3100000000),
  ('CUS004','Viña Central Valley',     'agriculture',30,'Refrigerado',     'active','2021-11-05',  920000000),
  ('CUS005','CCU Distribución',        'beverage',   45,'Paletizado seco', 'active','2019-05-20', 1500000000),
  ('CUS006','Sodimac Construcción',    'retail',     60,'Carga sobredimensionada','hold','2023-02-01', 780000000);

-- ----------------------------------------------------------------------------
-- Conductores (con columnas sensibles). password_hash se rellena más abajo.
-- ----------------------------------------------------------------------------
INSERT INTO lod.drivers
  (driver_id, first_name, last_name, hire_date, license_number, license_state, date_of_birth, home_terminal, employment_status, cdl_class, years_experience, national_id, personal_phone, home_address, base_salary_clp) VALUES
  ('DRV001','Camila','Rojas',     '2018-04-10','LIC-1001','RM', '1990-06-12','Santiago',   'active','A5',  9,'12.345.678-9','+56 9 8112 3344','Av. Vicuña Mackenna 1234, Ñuñoa',     1450000),
  ('DRV002','Matías','Fuentes',   '2016-09-22','LIC-1002','RM', '1985-02-03','Santiago',   'active','A5', 13,'10.222.333-4','+56 9 7765 1122','Pasaje Los Aromos 56, Maipú',         1680000),
  ('DRV003','Valentina','Soto',   '2020-01-15','LIC-1003','VAL','1993-11-30','Valparaíso', 'active','A4',  6,'15.987.654-3','+56 9 9988 7766','Subida Ecuador 880, Valparaíso',      1320000),
  ('DRV004','Joaquín','Muñoz',    '2014-06-01','LIC-1004','ANT','1982-08-19','Antofagasta','active','A5', 17,'8.765.432-1', '+56 9 6543 2211','Av. Argentina 455, Antofagasta',      1890000),
  ('DRV005','Antonia','Díaz',     '2021-08-30','LIC-1005','RM', '1996-04-25','Santiago',   'active','A4',  4,'18.456.789-0','+56 9 5432 9988','Calle Maturana 210, Santiago Centro', 1280000),
  ('DRV006','Benjamín','Castro',  '2017-02-14','LIC-1006','BIO','1988-12-09','Concepción', 'active','A5', 11,'13.111.222-3','+56 9 8877 6655','Barros Arana 990, Concepción',        1560000),
  ('DRV007','Javiera','Morales',  '2019-10-05','LIC-1007','RM', '1991-07-17','Santiago',   'active','A4',  7,'14.555.666-7','+56 9 7711 2299','Gran Avenida 4521, San Miguel',       1410000),
  ('DRV008','Sebastián','Reyes',  '2013-03-19','LIC-1008','COQ','1980-01-28','La Serena',  'active','A5', 18,'7.654.321-0', '+56 9 6622 3344','Av. del Mar 1500, La Serena',         1950000),
  ('DRV009','Fernanda','Vega',    '2022-05-11','LIC-1009','LAG','1997-09-08','Puerto Montt','active','A4', 3,'19.876.543-2','+56 9 5566 7788','Av. Diego Portales 75, Puerto Montt', 1230000),
  ('DRV010','Tomás','Herrera',    '2015-11-23','LIC-1010','ARA','1986-03-14','Temuco',     'active','A5', 14,'11.333.444-5','+56 9 8899 0011','Av. Alemania 320, Temuco',            1720000);

-- ----------------------------------------------------------------------------
-- Camiones (12)
-- ----------------------------------------------------------------------------
INSERT INTO lod.trucks
  (truck_id, unit_number, make, model_year, vin, acquisition_date, acquisition_mileage, fuel_type, tank_capacity_gallons, status, home_terminal)
SELECT
  'TRK' || lpad(i::text,3,'0'),
  'U' || (1000 + i),
  (ARRAY['Freightliner','Volvo','Scania','Kenworth','Mercedes-Benz','International'])[1 + (i % 6)],
  2017 + (i % 7),
  'VIN' || lpad(i::text,3,'0') || 'H' || (100000 + i * 37),
  date '2019-01-01' + (i * 53),
  50000 + i * 1234,
  (ARRAY['Diesel','Diesel','Diesel','GNL'])[1 + (i % 4)],
  (ARRAY[120,150,200])[1 + (i % 3)],
  (ARRAY['Active','Active','Active','Active','Maintenance','Inactive'])[1 + (i % 6)],
  (ARRAY['Santiago','Antofagasta','Concepción'])[1 + (i % 3)]
FROM generate_series(1, 12) AS s(i);

-- ----------------------------------------------------------------------------
-- Rutas (8)
-- ----------------------------------------------------------------------------
INSERT INTO lod.routes
  (route_id, origin_city, origin_state, destination_city, destination_state, typical_distance_miles, base_rate_per_mile, fuel_surcharge_rate, typical_transit_days) VALUES
  ('RTE001','Santiago','RM','Valparaíso','VAL',  120, 2.10, 0.180, 1),
  ('RTE002','Santiago','RM','Concepción','BIO',  500, 1.95, 0.220, 1),
  ('RTE003','Antofagasta','ANT','Santiago','RM',1360, 1.80, 0.250, 2),
  ('RTE004','Santiago','RM','La Serena','COQ',   470, 1.98, 0.210, 1),
  ('RTE005','Puerto Montt','LAG','Santiago','RM',1020, 1.85, 0.240, 2),
  ('RTE006','Santiago','RM','Rancagua','OHI',     87, 2.30, 0.150, 1),
  ('RTE007','Calama','ANT','Antofagasta','ANT',  215, 2.05, 0.200, 1),
  ('RTE008','Temuco','ARA','Santiago','RM',      680, 1.90, 0.230, 1);

-- ----------------------------------------------------------------------------
-- Cargas (30)
-- ----------------------------------------------------------------------------
INSERT INTO lod.loads
  (load_id, customer_id, route_id, load_date, load_type, weight_lbs, pieces, revenue, fuel_surcharge, accessorial_charges, load_status, booking_type)
SELECT
  'LD' || lpad(i::text, 4, '0'),
  'CUS' || lpad((1 + (i % 6))::text, 3, '0'),
  r.route_id,
  date '2025-07-01' + ((i * 6) % 170),
  (ARRAY['Paletizado seco','Refrigerado','Carga industrial','Sobredimensionado'])[1 + (i % 4)],
  (8000 + random() * 32000)::int,
  (4 + random() * 26)::int,
  round((r.typical_distance_miles * r.base_rate_per_mile * (0.9 + random() * 0.4))::numeric, 2),
  round((r.typical_distance_miles * r.fuel_surcharge_rate)::numeric, 2),
  round((random() * 250)::numeric, 2),
  (ARRAY['delivered','delivered','delivered','in_transit','booked'])[1 + (i % 5)],
  (ARRAY['contract','spot'])[1 + (i % 2)]
FROM generate_series(1, 30) AS s(i)
JOIN lod.routes r ON r.route_id = 'RTE' || lpad((1 + (i % 8))::text, 3, '0');

-- ----------------------------------------------------------------------------
-- Viajes (30) — uno por carga
-- ----------------------------------------------------------------------------
INSERT INTO lod.trips
  (trip_id, load_id, driver_id, truck_id, dispatch_date, actual_distance_miles, actual_duration_hours, fuel_gallons_used, average_mpg, idle_time_hours, trip_status)
SELECT
  'TRP' || lpad(i::text, 4, '0'),
  'LD'  || lpad(i::text, 4, '0'),
  'DRV' || lpad((1 + (i % 10))::text, 3, '0'),
  'TRK' || lpad((1 + (i % 12))::text, 3, '0'),
  l.load_date + 1,
  dist.miles,
  round((dist.miles / (45 + random() * 10))::numeric, 2),
  round((dist.miles / (5.5 + random() * 2))::numeric, 2),
  round((5.5 + random() * 2)::numeric, 2),
  round((random() * 6)::numeric, 2),
  (ARRAY['completed','completed','completed','in_progress','planned'])[1 + (i % 5)]
FROM generate_series(1, 30) AS s(i)
JOIN lod.loads l  ON l.load_id  = 'LD' || lpad(i::text, 4, '0')
JOIN lod.routes rt ON rt.route_id = l.route_id
CROSS JOIN LATERAL (SELECT (rt.typical_distance_miles + (random() * 80 - 40))::int AS miles) AS dist;

-- ----------------------------------------------------------------------------
-- Mantenimientos (2 por camión)
-- ----------------------------------------------------------------------------
INSERT INTO lod.maintenance_records
  (maintenance_id, truck_id, maintenance_date, maintenance_type, odometer_reading, labor_hours, labor_cost, parts_cost, total_cost, facility_location, downtime_hours, service_description)
SELECT
  'MNT' || lpad((row_number() OVER ())::text, 4, '0'),
  t.truck_id,
  date '2025-07-15' + ((row_number() OVER ())::int * 11 % 150),
  (ARRAY['Cambio de aceite','Frenos','Neumáticos','Motor','Inspección DOT'])[1 + (n % 5)],
  120000 + (random() * 250000)::int,
  round((2 + random() * 6)::numeric, 2),
  round((80000 + random() * 220000)::numeric, 2),
  round((50000 + random() * 400000)::numeric, 2),
  round((150000 + random() * 600000)::numeric, 2),
  t.home_terminal,
  round((4 + random() * 40)::numeric, 2),
  'Servicio programado de flota'
FROM lod.trucks t
CROSS JOIN generate_series(1, 2) AS g(n);

-- ----------------------------------------------------------------------------
-- Compras de combustible (1 por viaje)
-- ----------------------------------------------------------------------------
INSERT INTO lod.fuel_purchases
  (fuel_purchase_id, trip_id, truck_id, driver_id, purchase_date, location_city, location_state, gallons, price_per_gallon, total_cost, fuel_card_number)
SELECT
  'FP' || lpad((row_number() OVER ())::text, 4, '0'),
  tr.trip_id,
  tr.truck_id,
  tr.driver_id,
  tr.dispatch_date + (random() * 2)::int,
  (ARRAY['Santiago','Antofagasta','Concepción','La Serena','Temuco'])[1 + ((row_number() OVER ())::int % 5)],
  (ARRAY['RM','ANT','BIO','COQ','ARA'])[1 + ((row_number() OVER ())::int % 5)],
  round((60 + random() * 100)::numeric, 2),
  round((0.9 + random() * 0.3)::numeric, 3),
  round((80000 + random() * 120000)::numeric, 2),
  '5412' || lpad(((random() * 9999)::int)::text, 4, '0')
FROM lod.trips tr;

-- ----------------------------------------------------------------------------
-- Métricas mensuales por camión (12 camiones x 6 meses)
-- ----------------------------------------------------------------------------
INSERT INTO lod.truck_utilization_metrics
  (truck_id, month, trips_completed, total_miles, total_revenue, average_mpg, maintenance_events, maintenance_cost, downtime_hours, utilization_rate)
SELECT
  t.truck_id,
  m.month,
  (2 + random() * 7)::int,
  (3000 + random() * 9000)::int,
  round((4000000 + random() * 9000000)::numeric, 2),
  round((5.5 + random() * 2)::numeric, 2),
  (random() * 2)::int,
  round((random() * 800000)::numeric, 2),
  round((random() * 60)::numeric, 2),
  round((0.6 + random() * 0.35)::numeric, 3)
FROM lod.trucks t
CROSS JOIN (
  SELECT generate_series(date '2025-07-01', date '2025-12-01', interval '1 month')::date AS month
) m;

-- ----------------------------------------------------------------------------
-- Métricas mensuales por conductor (10 conductores x 6 meses)
-- ----------------------------------------------------------------------------
INSERT INTO lod.driver_monthly_metrics
  (driver_id, month, trips_completed, total_miles, total_revenue, average_mpg, total_fuel_gallons, on_time_delivery_rate, average_idle_hours)
SELECT
  d.driver_id,
  m.month,
  (3 + random() * 8)::int,
  (3500 + random() * 9000)::int,
  round((4500000 + random() * 8000000)::numeric, 2),
  round((5.5 + random() * 2)::numeric, 2),
  round((500 + random() * 1500)::numeric, 2),
  round((0.82 + random() * 0.17)::numeric, 3),
  round((random() * 8)::numeric, 2)
FROM lod.drivers d
CROSS JOIN (
  SELECT generate_series(date '2025-07-01', date '2025-12-01', interval '1 month')::date AS month
) m;

-- ============================================================================
--  DATOS SENSIBLES
-- ============================================================================

-- Credenciales de conductores (MD5 débil a propósito)
INSERT INTO lod.driver_credentials
  (credential_id, driver_id, username, password_hash, role, mfa_secret, last_login_at, must_reset) VALUES
  ('CRED001','DRV001','crojas',   md5('123456'),   'driver','JBSWY3DPEHPK3PXP', '2026-06-10 08:14:00', false),
  ('CRED002','DRV002','mfuentes', md5('password'), 'driver','KRSXG5CTMVRXEZLU', '2026-06-12 19:02:00', false),
  ('CRED003','DRV003','vsoto',    md5('qwerty'),   'driver','MFRGGZDFMZTWQ2LK', '2026-06-11 07:45:00', true),
  ('CRED004','DRV004','jmunoz',   md5('camion123'),'driver_lead','NBSWY3DPEB3W64TM','2026-06-09 22:31:00', false),
  ('CRED005','DRV005','adiaz',    md5('antonia'),  'driver','ONSWG4TFOQ',        '2026-06-13 06:10:00', false),
  ('CRED006','DRV006','bcastro',  md5('flota2025'),'driver','PEBGC5LTMVRXEZLU',  '2026-06-08 14:55:00', false),
  ('CRED007','DRV007','jmorales', md5('javiera1'), 'driver','QFRGGZDFMZTWQ2LK',  '2026-06-12 11:20:00', false),
  ('CRED008','DRV008','sreyes',   md5('santiago'), 'driver_lead','RFSWY3DPEB3W64TM','2026-06-10 17:40:00', false),
  ('CRED009','DRV009','fvega',    md5('fernanda'), 'driver','SBSWY3DPEHPK3PXP',  '2026-06-13 05:30:00', true),
  ('CRED010','DRV010','therrera', md5('tomas2025'),'driver','TBSWY3DPEHPK3PXP',  '2026-06-11 20:05:00', false);

-- Sincroniza el hash en lod.drivers (otro lugar donde el alumno puede hallarlo)
UPDATE lod.drivers d
   SET password_hash = c.password_hash
  FROM lod.driver_credentials c
 WHERE c.driver_id = d.driver_id;

-- Cuentas administrativas del backoffice
INSERT INTO lod.admin_accounts
  (admin_id, username, password_hash, full_name, email, role, is_superuser, last_login_at) VALUES
  ('ADM001','admin',       md5('admin123'), 'Administrador del Sistema','admin@transandes.cl',      'superadmin', true,  '2026-06-15 09:00:00'),
  ('ADM002','operaciones', md5('flota2025'),'Jefe de Operaciones',      'operaciones@transandes.cl','ops',       false, '2026-06-14 18:22:00'),
  ('ADM003','ti.soporte',  md5('password'), 'Soporte TI',               'soporte@transandes.cl',    'support',    false, '2026-06-13 12:45:00'),
  ('ADM004','auditor',     md5('123456'),   'Auditoría Externa',        'auditor@externo.cl',       'readonly',   false, '2026-06-01 10:10:00');

-- Operaciones clasificadas (carga real vs. declarada, contratos reservados)
INSERT INTO lod.classified_operations
  (op_id, trip_id, client_codename, declared_cargo_description, real_cargo_description, security_level, escort_required, contract_value_clp, special_instructions, clearance_required) VALUES
  ('OP001','TRP0003','PROYECTO ATACAMA','Insumos industriales','Concentrado de cobre de alta ley','restricted', true,  240000000,'Escolta armada Calama-Antofagasta. No detenerse en zona norte.','nivel_3'),
  ('OP002','TRP0007','CLIENTE GAMMA',   'Equipos electrónicos', 'Servidores y respaldos bancarios','confidential',true, 180000000,'Ruta alterna por seguridad. GPS silencioso.','nivel_2'),
  ('OP003','TRP0011','VITIS',           'Productos agrícolas',  'Vino premium para exportación',   'internal',  false,  95000000,'Cadena de frío estricta 4°C.','nivel_1'),
  ('OP004','TRP0015','PROYECTO ANDES',  'Maquinaria',           'Explosivos para minería (ANFO)',  'restricted', true, 320000000,'Permiso DGMN vigente. Cuadrilla certificada.','nivel_3'),
  ('OP005','TRP0019','CLIENTE OMEGA',   'Mercadería general',   'Lingotes — traslado interbancario','confidential',true,510000000,'Convoy de 2 vehículos. Seguro especial.','nivel_3'),
  ('OP006','TRP0023','RETAIL PLUS',     'Electrodomésticos',    'iPhones y notebooks (alto valor)','internal', false, 145000000,'Entrega solo en bodega central con firma.','nivel_1');
