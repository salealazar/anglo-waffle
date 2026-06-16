# 🔎 Actividad: Auditoría de seguridad de *TransAndes Analytics*

> **Modalidad:** laboratorio práctico de inyección SQL · **Duración sugerida:** 90–120 min
> **Formato de entrega:** informe de auditoría (ver plantilla al final)

---

## 🎭 Escenario

La empresa de transporte **TransAndes Logística** acaba de terminar un panel web
interno, *TransAndes Analytics*, para visualizar estadísticas de su flota
(camiones, viajes, rutas, conductores). Antes de publicarlo, te contrataron como
**auditor/a de seguridad** para responder una pregunta:

> ¿Es seguro poner esta aplicación en producción?

Tu trabajo es **auditarla**, encontrar fallas, **demostrar el impacto real** con
evidencia, y entregar un informe con tu recomendación.

## ⚖️ Reglas y ética

- Trabaja **solo** sobre la aplicación de este laboratorio, en el entorno que te
  indique el/la docente. **URL del lab:** `__________________________`
  (ej. `http://localhost:4000`).
- Las técnicas que aprenderás son **delito** si se usan sobre sistemas ajenos sin
  autorización por escrito. Aquí tienes autorización **explícita y acotada** a esta app.
- No ataques la red, el host ni otros servicios: **solo la aplicación web**.

## 🎯 Objetivos de aprendizaje

Al terminar serás capaz de: identificar puntos de inyección SQL, confirmar la
vulnerabilidad, usar `UNION` para extraer datos no expuestos, enumerar el esquema
de la base, exfiltrar credenciales, crackear hashes débiles y demostrar impacto de
**integridad** (modificación de datos) — todo documentado como una auditoría.

## 🧰 Necesitarás

- Un navegador.
- (Opcional) `curl` o Burp/ZAP para automatizar peticiones.
- Para crackear hashes: [CrackStation](https://crackstation.net), o `hashcat`/`john`.
- Un editor para ir redactando tu informe.

---

# Fase 1 — ¿Dónde podría estar la vulnerabilidad?

**Objetivo:** mapear todas las entradas de la aplicación y formular una hipótesis
sobre cuál es la más propensa a inyección SQL.

**Manos a la obra**
1. Navega por **todas** las secciones del panel.
2. Haz un inventario de cada lugar donde **tú** envías datos (campos de texto,
   menús desplegables, parámetros en la URL…).
3. Para cada entrada, pregúntate: *¿este valor probablemente se mete dentro de una
   consulta SQL? ¿es texto libre o una opción fija?*

<details><summary>💡 Pista</summary>

Los **menús desplegables** suelen enviar valores controlados (una lista cerrada),
así que son más difíciles de manipular. Un **campo de texto libre** que “busca”
algo dentro de los datos es mucho más sospechoso: ese texto casi siempre termina
formando parte de un `WHERE`.
</details>

**Para tu informe:** lista las entradas encontradas y **cuál sospechas** y por qué.

---

# Fase 2 — Probar la hipótesis

**Objetivo:** confirmar (o descartar) que la entrada sospechosa es inyectable.

**Manos a la obra**
1. Piensa qué carácter “rompe” una cadena de texto dentro de SQL.
2. Envíalo en la entrada sospechosa y **observa la reacción** de la aplicación.
3. Prueba el **mismo** carácter en las otras entradas (los filtros desplegables):
   ¿se comportan igual? La diferencia es la clave de la auditoría.

<details><summary>💡 Pista</summary>

El carácter que delimita los textos en SQL es la **comilla simple** `'`. Si la app
no la trata con cuidado, al enviar una sola comilla la consulta queda “mal cerrada”
y suele aparecer un **mensaje de error de la base de datos**. Un error así = señal
fuerte de inyección.
</details>

<details><summary>✅ Si te atascaste</summary>

En el buscador, escribe exactamente:

```
'
```

Aparece un error tipo `unterminated quoted string…`. En los filtros desplegables
de Flota/Conductores/Rutas **no** pasa nada → esos usan consultas parametrizadas.
</details>

**Para tu informe:** el payload de prueba, qué entrada falló y la evidencia (captura
del error). Anota también cuáles **no** fallaron.

---

# Fase 3 — `UNION`: ver el resto de las tablas

**Objetivo:** usar `UNION SELECT` para listar las tablas de la base y detectar
cuáles **contienen datos sensibles** y no se muestran en la app.

**Manos a la obra**
1. Averigua **cuántas columnas** devuelve la consulta original (un `UNION` exige
   el mismo número de columnas).
2. Arma un `UNION SELECT` de prueba con ese número de columnas.
3. Reemplaza esos valores de prueba por una consulta al **catálogo del sistema**
   (`information_schema.tables`) para listar las tablas.
4. Identifica las tablas cuyo nombre huela a información sensible.

<details><summary>💡 Pistas</summary>

- Para contar columnas: prueba `' ORDER BY 1-- `, `' ORDER BY 2-- `… hasta que falle.
  El último número que **no** falla es la cantidad de columnas.
- En PostgreSQL el comentario es `--` (sirve para “tapar” lo que quede a la derecha
  de tu inyección).
- Las columnas de tu `UNION` deben “calzar” en tipo. Si alguna es numérica,
  conviértela con `::text`. Aquí todas las columnas mostradas son texto.
- El catálogo `information_schema.tables` tiene `table_schema` y `table_name`.
  Filtra por el esquema de negocio (`lod`).
</details>

<details><summary>✅ Si te atascaste (payloads)</summary>

```
' ORDER BY 5-- 
' UNION SELECT 'a','b','c','d','e'-- 
' UNION SELECT table_schema, table_name, NULL, NULL, NULL FROM information_schema.tables WHERE table_schema='lod'-- 
```

Fíjate en tablas como `driver_credentials`, `admin_accounts` y
`classified_operations`: **ninguna** aparece en la interfaz.
</details>

**Para tu informe:** cuántas columnas tiene la consulta, la lista de tablas y
cuáles marcas como “sensibles” (justifica).

---

# Fase 4 — Robar las credenciales

**Objetivo:** extraer usuarios y contraseñas (en hash) de las tablas sensibles.

**Manos a la obra**
1. Antes de leer una tabla, descubre **sus columnas** (usa `information_schema.columns`).
2. Arma un `UNION` que traiga el usuario y el hash de contraseña.
3. Hazlo para las credenciales de **conductores** y de **administradores**.

<details><summary>💡 Pista</summary>

`information_schema.columns` tiene `table_name`, `column_name` y `data_type`.
Filtra por la tabla que te interese para ver qué columnas pedir en tu `UNION`
(busca algo como `username` y `password_hash`).
</details>

<details><summary>✅ Si te atascaste (payloads)</summary>

```
' UNION SELECT column_name, data_type, NULL, NULL, NULL FROM information_schema.columns WHERE table_name='driver_credentials'-- 
' UNION SELECT username, password_hash, role, COALESCE(mfa_secret,''), driver_id FROM lod.driver_credentials-- 
' UNION SELECT username, password_hash, role, email, full_name FROM lod.admin_accounts-- 
```
</details>

**Para tu informe:** una tabla con los usuarios y hashes obtenidos (puedes truncar
los hashes en la evidencia, pero deja claro qué tablas eran accesibles).

---

# Fase 5 — Crackear los hashes MD5

**Objetivo:** demostrar que esos hashes no protegen nada porque son débiles.

**Manos a la obra**
1. Identifica el **algoritmo**: ¿qué te dice un hash de 32 caracteres hexadecimales?
2. Intenta recuperar las contraseñas en claro con una herramienta de tu elección.
3. Anota cuántas lograste recuperar y en cuánto tiempo.

<details><summary>💡 Pista</summary>

32 caracteres hex ⇒ **MD5**. MD5 es rapidísimo de romper y estas claves son muy
comunes, así que un simple *lookup* en una rainbow table (p. ej. CrackStation) o
`hashcat -m 0 hashes.txt rockyou.txt` las revienta en segundos. **No** te damos las
contraseñas: descúbrelas.
</details>

**Para tu informe:** las contraseñas recuperadas, la herramienta usada y el tiempo.
Comenta por qué MD5 sin *salt* es inaceptable para guardar contraseñas.

---

# Fase 6 — Modificar datos (demostrar el impacto)

**Objetivo:** probar que un atacante no solo **lee**, sino que puede **alterar** la
base — el argumento definitivo para frenar el despliegue.

> ⚠️ Esto modifica la base del laboratorio. Está permitido **solo aquí**. El/la
> docente puede resetear el entorno después.

**Manos a la obra**
1. La conexión permite **encadenar** sentencias separadas por `;` (*stacked queries*).
2. Usando una tabla sensible que descubriste, ejecuta un `UPDATE` que cambie algo
   verificable (por ejemplo, el rol o el hash de un administrador).
3. **Comprueba** el cambio leyendo de nuevo el dato con un `UNION`.

<details><summary>💡 Pista</summary>

Cierra el string como siempre, agrega `; ` y tu sentencia de escritura, y cierra
con `-- ` para anular lo que quede. Luego vuelve a leer la fila para confirmar.
</details>

<details><summary>✅ Si te atascaste (payloads)</summary>

```
'; UPDATE lod.admin_accounts SET role='AUDITADO' WHERE username='admin'; -- 
' UNION SELECT username, password_hash, role, NULL, NULL FROM lod.admin_accounts WHERE username='admin'-- 
```

La primera no muestra resultados (es un `UPDATE`); la segunda confirma que el rol
cambió.
</details>

**Para tu informe:** la sentencia de modificación, la evidencia **antes/después** y
un párrafo de **impacto al negocio**: ¿qué significa que un atacante pueda leer PII
de conductores, credenciales de administradores, contratos reservados **y** además
manipular registros? ¿Por qué la app **no** puede salir a producción así?

---

## 📝 Plantilla de informe de hallazgo

Completa una ficha por cada hallazgo relevante (mínimo el de inyección SQL):

| Campo | Contenido |
|---|---|
| **Título** | p. ej. *Inyección SQL en el buscador de flota* |
| **Severidad** | Crítica / Alta / Media / Baja (justifica) |
| **Ubicación** | endpoint / parámetro afectado |
| **Descripción** | qué es y por qué ocurre |
| **Pasos para reproducir** | numerados, con los payloads usados |
| **Evidencia** | capturas de pantalla |
| **Impacto** | confidencialidad (datos leídos) e integridad (datos alterados) |
| **Recomendación** | cómo se corrige (ver preguntas de cierre) |

## 🧠 Preguntas de cierre (remediación)

1. ¿Cuál es la causa **raíz** del problema y cómo se corrige en el código? (pista:
   compara el buscador con los filtros que **no** eran vulnerables).
2. La app usaba **vistas** que escondían columnas sensibles. ¿Por qué no sirvieron
   de protección?
3. El rol de base de datos de la app podía leer y **escribir** tablas que no le
   correspondían. ¿Qué principio de seguridad se violó y cómo se aplica?
4. ¿Qué otras defensas en profundidad agregarías (manejo de errores, hashing de
   contraseñas, etc.)?

## ✅ Tu veredicto

En una frase: **¿recomiendas o no** poner *TransAndes Analytics* en producción?
Fundaméntalo con tus hallazgos.

---

### Rúbrica sugerida (referencial)

| Criterio | Pts |
|---|---|
| Fase 1–2: identifica y confirma el punto de inyección con evidencia | 20 |
| Fase 3: enumera tablas y detecta las sensibles | 20 |
| Fase 4: exfiltra credenciales de ambas tablas | 15 |
| Fase 5: crackea los hashes y explica por qué MD5 es inadecuado | 15 |
| Fase 6: demuestra modificación de datos con evidencia antes/después | 15 |
| Informe y remediación (causa raíz, mínimo privilegio, defensa en profundidad) | 15 |
