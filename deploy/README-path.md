# 🛣️ Deploy bajo un PATH del host de faro (`/sqli-lab`)

Sirve el lab en `https://<host-de-faro>/sqli-lab` reutilizando el **nginx-proxy**
que ya enruta a faro. El app fue hecho *base-path aware* (variable `BASE_PATH`),
así que funciona bajo una sub-ruta sin romper enlaces ni estáticos.

> ⚠️ Recuerda: corre en el **mismo host/origin que faro producción**. La SQLi no
> escala a RCE (rol no-superusuario, verificado), pero por mismo-origen un XSS en
> el lab podría tocar `/faro/api/*` con la sesión de un usuario logueado. Por eso
> un **subdominio** (ver `README.md`) es más seguro. Si igual vas por path:
> activa la **auth básica**, usa **time-box** y **resetea** entre clases.

## 1) Levanta los contenedores del lab

La BD queda aislada en su red privada; el app se une además a `nginx-proxy` solo
para que el proxy de faro pueda alcanzarlo. Nada publica puertos al host.

```bash
cd sqli-lab/deploy
cp .env.example .env          # define POSTGRES_PASSWORD, LAB_BASIC_AUTH, BASE_PATH
docker compose -f docker-compose.path.yml --env-file .env up -d --build
```

> La red externa `nginx-proxy` ya existe (la creó el stack de faro). Si tu red
> tiene otro nombre, ajústalo en `docker-compose.path.yml`.

## 2) Agrega el ruteo al nginx de faro

Son dos piezas, calcadas de las de faro (`nginx/faro.conf` y `nginx/faro.upstream`):

| Archivo | Dónde va | Contexto nginx |
|---|---|---|
| [`nginx/sqli-lab.upstream`](nginx/sqli-lab.upstream) | junto a `faro.upstream` | nivel `http { }` |
| [`nginx/sqli-lab.conf`](nginx/sqli-lab.conf) | en el `vhost.d` del VIRTUAL_HOST de faro, junto al `location /faro` | dentro de `server { }` |

Es decir: ponlos **donde ya montas los de faro** en tu nginx-proxy y recarga:

```bash
docker exec <contenedor-nginx-proxy> nginx -t && \
docker exec <contenedor-nginx-proxy> nginx -s reload
```

Listo: `https://<host-de-faro>/sqli-lab` pide la clave del curso y entra al panel.

## Cómo encaja

```
navegador ──/sqli-lab──▶ nginx-proxy de faro ──(red nginx-proxy)──▶ sqli-lab-app:4000
                                                                         │ (red sqli-internal)
                                                                         ▼
                                                                    sqli-lab-db  (aislada)
```

- `proxy_pass http://sqli-lab;` **sin** barra final ⇒ nginx **no** recorta el
  prefijo; el app recibe `/sqli-lab/...` y lo maneja con `BASE_PATH=/sqli-lab`.
- `BASE_PATH` (compose) y el `location /sqli-lab` (nginx) **deben coincidir**.

## Operación

```bash
# Bajar (conserva datos):
docker compose -f docker-compose.path.yml down
# Resetear la base entre secciones:
docker compose -f docker-compose.path.yml down -v
```

Y quita el `location /sqli-lab` del nginx cuando termines la actividad.
