/* Pool de conexiones a PostgreSQL.
 *
 * La app se conecta como el rol `fleet_app`, que está SOBRE-PRIVILEGIADO a
 * propósito (puede leer/escribir todo el esquema `lod`). Ver db/05_roles.sql.
 */
const { Pool } = require('pg');

const pool = new Pool({
  connectionString:
    process.env.DATABASE_URL ||
    'postgresql://fleet_app:fleet_app_pw@localhost:5434/fleetdb',
  max: 5,
});

pool.on('error', (err) => {
  console.error('Error inesperado en el pool de PostgreSQL:', err.message);
});

module.exports = { pool };
