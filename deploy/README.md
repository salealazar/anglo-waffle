# 🌐 Deploy del laboratorio en Internet (endurecido)

Esta carpeta sirve para exponer el lab a Internet **con resguardos**, porque es
una app **vulnerable a propósito**. Si puedes evitarlo, prefiere que cada alumno
lo corra local o ponlo solo en la red interna/VPN. Si igual lo expones, sigue
esto al pie de la letra.

## Lo que ya está contenido (verificado)

El rol con el que la app habla a la base, `fleet_app`, **no es superusuario** y:

- ❌ no puede `COPY … TO PROGRAM` → **no hay RCE** por la inyección,
- ❌ no puede leer archivos del servidor (`pg_read_file` denegado),
- ✅ solo puede leer/escribir la base `fleetdb`, que tiene **datos sintéticos**.

Es decir: lo peor que logra un atacante por la SQLi es **ensuciar la base del
propio lab**, y eso se resetea en segundos.

## Lo que este deploy agrega

| Riesgo | Mitigación en este compose |
|---|---|
| Puerto de Postgres expuesto (= superusuario = RCE) | La base **no publica ningún puerto**; solo vive en la red interna. |
| App abierta a bots/escáneres de Internet | **Auth básica** (clave del curso) vía `LAB_BASIC_AUTH`. |
| Tráfico/clave en texto plano | **TLS automático** (Let's Encrypt) en Caddy; solo 80/443 expuestos. |
| Superusuario con clave por defecto | `POSTGRES_PASSWORD` fuerte desde `.env`. |

## Reglas NO negociables

1. **Host desechable y aislado.** Una VM dedicada que puedas destruir; sin acceso
   a la red interna sensible, ni a la base real de faro, ni a credenciales de
   nube. Idealmente con egress restringido.
2. **Time-box.** Enciéndelo para la clase y **bájalo al terminar**
   (`docker compose -f docker-compose.deploy.yml down`).
3. **Resetea entre secciones** con `down -v`.
4. **No reutilices** el proxy ni el Postgres de faro de producción.

## Pasos

```bash
cd sqli-lab/deploy
cp .env.example .env
# edita .env: LAB_DOMAIN, LAB_BASIC_AUTH (usuario:clave del curso), POSTGRES_PASSWORD
#   openssl rand -base64 24   # para generar claves

# DNS: apunta LAB_DOMAIN (registro A/AAAA) a la IP pública de este host.
# Abre 80 y 443 en el firewall/security group (Caddy necesita ambos para el cert).

docker compose -f docker-compose.deploy.yml --env-file .env up -d --build
```

Listo: `https://<LAB_DOMAIN>` pide la clave del curso y entra al panel.

```bash
# Apagar al terminar la clase (conserva datos):
docker compose -f docker-compose.deploy.yml down
# Resetear la base por completo:
docker compose -f docker-compose.deploy.yml down -v
```

## Si no tienes dominio (solo IP)

Caddy necesita un dominio para el certificado de Let's Encrypt. Con solo IP, o
bien pones Caddy en modo certificado interno (el navegador mostrará advertencia),
o frenteas el app con el proxy TLS que ya use tu universidad apuntándolo a
`app:4000`. En ese caso la auth básica del app igual te protege.

## Endurecimiento opcional (recomendado para público)

- **Lista blanca de IPs** en el `Caddyfile` (deja entrar solo las redes del curso).
- **Logs:** revisa los accesos con `docker compose -f docker-compose.deploy.yml logs -f caddy`.
- **Snapshot de la VM** antes de la clase para restaurar al instante.
