-- ============================================================================
--  ROL DE LA APLICACIÓN  (la mala configuración intencional del lab)
--  ----------------------------------------------------------------------------
--  La app web se conecta como `fleet_app`. En un diseño correcto este rol solo
--  tendría SELECT sobre las 3 vistas de `app`. Aquí, a propósito, está
--  SOBRE-PRIVILEGIADO:
--
--    * SELECT sobre TODO el esquema `lod`  -> permite leer tablas sensibles
--      vía UNION (credenciales, operaciones clasificadas, etc.).
--    * INSERT/UPDATE/DELETE sobre `lod`    -> permite MODIFICAR esos datos con
--      consultas apiladas (stacked queries) una vez que se conoce el nombre
--      de la tabla.
--
--  Moraleja para los alumnos: las vistas esconden columnas, pero si el rol de
--  la app puede tocar las tablas base y el código concatena entradas, las
--  vistas no protegen nada.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fleet_app') THEN
    CREATE ROLE fleet_app LOGIN PASSWORD 'fleet_app_pw';
  END IF;
END
$$;

-- Acceso a los esquemas
GRANT USAGE ON SCHEMA app TO fleet_app;
GRANT USAGE ON SCHEMA lod TO fleet_app;

-- Lo "esperado": leer las vistas públicas
GRANT SELECT ON ALL TABLES IN SCHEMA app TO fleet_app;

-- El exceso de privilegios (la vulnerabilidad de fondo):
--   leer y escribir directamente sobre las tablas base, incluidas las sensibles
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA lod TO fleet_app;

-- Por si en el futuro se agregan tablas/secuencias al esquema lod
ALTER DEFAULT PRIVILEGES IN SCHEMA lod
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO fleet_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA lod TO fleet_app;
