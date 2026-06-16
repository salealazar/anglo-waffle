/* ===========================================================================
 * TransAndes Analytics — Panel de Flota (LABORATORIO DE INYECCIÓN SQL)
 * ---------------------------------------------------------------------------
 * App de demostración para una actividad de seguridad. La mayoría de las
 * páginas usan consultas PARAMETRIZADAS (seguras). La página "Buscar" arma la
 * consulta concatenando texto del usuario => VULNERABLE a SQL injection.
 *
 * No usar con datos reales. No desplegar en producción. Es a propósito inseguro.
 * ===========================================================================*/

const path = require('path');
const express = require('express');
const { pool } = require('./db');

const app = express();
const PORT = process.env.PORT || 4000;

// Base path para servir la app detrás de nginx como sub-ruta (p.ej. "/sqli-lab").
// Vacío => se sirve en la raíz (modo local). Sin barra final.
const BASE_PATH = (process.env.BASE_PATH || '').replace(/\/+$/, '');
app.locals.base = BASE_PATH;

// ---------------------------------------------------------------------------
// Auth básica OPCIONAL — pensada para exponer el lab en Internet detrás de TLS.
// Se activa solo si existe la variable LAB_BASIC_AUTH="usuario:clave".
// Sin esa variable (uso local) la app queda abierta como antes.
// No protege contra la SQLi (es a propósito vulnerable): solo evita que bots y
// curiosos de Internet lleguen a la superficie del laboratorio.
// ---------------------------------------------------------------------------
if (process.env.LAB_BASIC_AUTH) {
  const idx = process.env.LAB_BASIC_AUTH.indexOf(':');
  const user = process.env.LAB_BASIC_AUTH.slice(0, idx);
  const pass = process.env.LAB_BASIC_AUTH.slice(idx + 1);
  const expected = 'Basic ' + Buffer.from(`${user}:${pass}`).toString('base64');
  app.use((req, res, next) => {
    const got = req.headers.authorization || '';
    // Comparación de largo constante para no filtrar la clave por timing.
    const a = Buffer.from(got);
    const b = Buffer.from(expected);
    if (a.length === b.length && require('crypto').timingSafeEqual(a, b)) return next();
    res.set('WWW-Authenticate', 'Basic realm="TransAndes Analytics (laboratorio)"');
    return res.status(401).send('Autenticación requerida.');
  });
}

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(BASE_PATH || '/', express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));

// Todas las rutas viven en este router, que luego se monta bajo BASE_PATH.
const router = express.Router();

// Helper de formato para las plantillas
app.locals.fmt = (n) =>
  n === null || n === undefined ? '—' : Number(n).toLocaleString('es-CL');
app.locals.clp = (n) =>
  n === null || n === undefined
    ? '—'
    : '$' + Math.round(Number(n)).toLocaleString('es-CL');

/* ---------------------------------------------------------------------------
 * Dashboard
 * -------------------------------------------------------------------------*/
router.get('/', async (req, res, next) => {
  try {
    const kpis = (
      await pool.query(`
        SELECT
          (SELECT count(*) FROM lod.trucks)                                AS trucks,
          (SELECT count(*) FROM lod.trucks WHERE status = 'Active')        AS trucks_active,
          (SELECT count(*) FROM lod.drivers WHERE employment_status='active') AS drivers,
          (SELECT count(*) FROM lod.trips)                                 AS trips,
          (SELECT COALESCE(sum(total_miles),0)   FROM lod.truck_utilization_metrics) AS total_miles,
          (SELECT COALESCE(sum(total_revenue),0) FROM lod.truck_utilization_metrics) AS total_revenue
      `)
    ).rows[0];

    const byMonth = (
      await pool.query(`
        SELECT to_char(month,'YYYY-MM') AS m,
               sum(total_revenue)        AS revenue,
               sum(total_miles)          AS miles
        FROM lod.truck_utilization_metrics
        GROUP BY month ORDER BY month
      `)
    ).rows;

    const byStatus = (
      await pool.query(`
        SELECT status, count(*) AS n FROM lod.trucks GROUP BY status ORDER BY status
      `)
    ).rows;

    const topRoutes = (
      await pool.query(`
        SELECT origin_city || ' → ' || destination_city AS label, total_revenue
        FROM app.v_route_economics
        ORDER BY total_revenue DESC LIMIT 6
      `)
    ).rows;

    res.render('dashboard', {
      active: 'dashboard',
      kpis,
      charts: {
        months: byMonth.map((r) => r.m),
        revenue: byMonth.map((r) => Number(r.revenue)),
        miles: byMonth.map((r) => Number(r.miles)),
        statusLabels: byStatus.map((r) => r.status),
        statusValues: byStatus.map((r) => Number(r.n)),
        routeLabels: topRoutes.map((r) => r.label),
        routeValues: topRoutes.map((r) => Number(r.total_revenue)),
      },
    });
  } catch (e) {
    next(e);
  }
});

/* ---------------------------------------------------------------------------
 * Flota (vista app.v_fleet_overview) — filtro PARAMETRIZADO (seguro)
 * -------------------------------------------------------------------------*/
router.get('/flota', async (req, res, next) => {
  try {
    const status = (req.query.status || '').toString();
    let sql = 'SELECT * FROM app.v_fleet_overview';
    const params = [];
    if (status) {
      params.push(status);
      sql += ` WHERE status = $${params.length}`;
    }
    sql += ' ORDER BY total_miles DESC';
    const rows = (await pool.query(sql, params)).rows; // $1 => no inyectable

    const statuses = (
      await pool.query('SELECT DISTINCT status FROM app.v_fleet_overview ORDER BY 1')
    ).rows.map((r) => r.status);

    res.render('fleet', { active: 'flota', rows, statuses, status });
  } catch (e) {
    next(e);
  }
});

/* ---------------------------------------------------------------------------
 * Conductores (vista app.v_driver_leaderboard) — filtro PARAMETRIZADO (seguro)
 * -------------------------------------------------------------------------*/
router.get('/conductores', async (req, res, next) => {
  try {
    const terminal = (req.query.terminal || '').toString();
    let sql = 'SELECT * FROM app.v_driver_leaderboard';
    const params = [];
    if (terminal) {
      params.push(terminal);
      sql += ` WHERE home_terminal = $${params.length}`;
    }
    sql += ' ORDER BY trips_completed DESC';
    const rows = (await pool.query(sql, params)).rows;

    const terminals = (
      await pool.query('SELECT DISTINCT home_terminal FROM app.v_driver_leaderboard ORDER BY 1')
    ).rows.map((r) => r.home_terminal);

    res.render('drivers', { active: 'conductores', rows, terminals, terminal });
  } catch (e) {
    next(e);
  }
});

/* ---------------------------------------------------------------------------
 * Rutas (vista app.v_route_economics) — seguro
 * -------------------------------------------------------------------------*/
router.get('/rutas', async (req, res, next) => {
  try {
    const rows = (
      await pool.query('SELECT * FROM app.v_route_economics ORDER BY total_revenue DESC')
    ).rows;
    res.render('routes', { active: 'rutas', rows });
  } catch (e) {
    next(e);
  }
});

/* ===========================================================================
 * Buscar camión — ¡¡VULNERABLE A SQL INJECTION!!
 * ---------------------------------------------------------------------------
 * El término de búsqueda se concatena directo dentro de la consulta. Como NO
 * se usan parámetros, node-postgres usa el "simple query protocol", que además
 * permite consultas apiladas (stacked queries) => se puede leer Y modificar.
 *
 * Así NO se debe programar. Es el corazón de la actividad.
 * ===========================================================================*/
function buildSearchSql(q) {
  // OJO: el WHERE y el ORDER BY van en la MISMA línea a propósito. Así un
  // comentario `--` inyectado alcanza a anular el ORDER BY, habilitando tanto
  // UNION como consultas apiladas (stacked queries). Es justo lo frágil que
  // resulta concatenar la entrada del usuario dentro del SQL.
  return (
    'SELECT unit_number, make, model_year::text AS model_year, ' +
    'status, total_miles::text AS total_miles ' +
    'FROM app.v_fleet_overview ' +
    "WHERE (unit_number || ' ' || make || ' ' || home_terminal) ILIKE '%" +
    q +
    "%' ORDER BY unit_number"
  );
}

router.get('/buscar', async (req, res) => {
  const submitted = req.query.q !== undefined;
  const q = (req.query.q || '').toString();

  let rows = [];
  let columns = [];
  let error = null;

  if (submitted) {
    const sql = buildSearchSql(q); // <-- concatenación insegura, a propósito
    try {
      const result = await pool.query(sql);
      // Con stacked queries pg puede devolver un arreglo de resultados;
      // tomamos el último que tenga filas/columnas para mostrar algo útil.
      const r = Array.isArray(result)
        ? [...result].reverse().find((x) => x && x.fields && x.fields.length) || result[result.length - 1]
        : result;
      rows = (r && r.rows) || [];
      columns = ((r && r.fields) || []).map((f) => f.name);
    } catch (e) {
      error = e.message; // mostramos el error de la BD (pista de la vulnerabilidad)
    }
  }

  res.render('search', { active: 'buscar', q, submitted, rows, columns, error });
});

// La app real de faro tenía /login; aquí no existe. Redirige al panel para que
// la URL histórica (…/faro/login) caiga en el dashboard del lab.
router.get('/login', (req, res) => res.redirect((BASE_PATH || '') + '/'));

// Monta el router bajo el base path (o en la raíz si BASE_PATH está vacío).
app.use(BASE_PATH || '/', router);

// Comodidad: si entras a la raíz y hay BASE_PATH definido, redirige al panel.
if (BASE_PATH) app.get('/', (req, res) => res.redirect(BASE_PATH + '/'));

/* ---------------------------------------------------------------------------
 * Manejo de errores
 * -------------------------------------------------------------------------*/
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).render('error', { active: '', message: err.message });
});

app.listen(PORT, () => {
  console.log(`TransAndes Analytics escuchando en http://localhost:${PORT}`);
});
