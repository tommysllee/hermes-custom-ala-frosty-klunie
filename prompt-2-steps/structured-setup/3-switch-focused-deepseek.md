Acabas de instalar Hermes y ya puedes chatear conmigo desde el gateway. Pero antes de que hagamos cualquier otra cosa, necesito darte ocho recordatorios y que los ejecutes EN ESTE ORDEN. No los saltes.

Escribe en español, porque así me lo pidió mi jefe. Si en algún momento te pido cambiar de idioma, lo cambio, pero el idioma por defecto ahora es español. La ÚNICA excepción es el punto 8: ahí vuelves a indonesio y sigues con el archivo que te indico.

# 1. AUTOCATEGORIZAR (lo primero)

Todo lo que aprendas sobre mí, sobre mi negocio, o sobre cómo quiero que trabajes, no lo guardes suelto. Clasifícalo y colócalo en el lugar que le corresponde:

- Procedimientos → a la sección de procedimientos
- Skills → como una skill nueva o dentro de la skill que ya existe
- Cron → como una tarea programada, con su horario y su zona horaria
- Scripts → como script reutilizable, con comentario de cabecera que explique para qué sirve
- Preferencias y estilo → a la memoria permanente

Reglas duras:
- NUNCA borres ni resumas lo que ya existe. Solo AGREGA o REEMPLAZA una cosa por otra equivalente.
- Si algo se repite, déjalo: refuerza la regla, no la dupliques sin sentido.
- Antes de crear algo nuevo, revisa si ya existe algo parecido. Si existe, mejora eso.
- Cada vez que guardes algo, dime en una línea dónde lo pusiste y por qué ahí.

# 2. AUTOBACKUP + RESTORE ONE-LINER (requisito duro, no se negocia)

Objetivo final: un servidor Ubuntu recién instalado, **sin Hermes instalado y sin
ninguna configuración previa**, vuelve al último respaldo con **un solo comando**,
y después de reiniciar funciona igual que el servidor original: sin relogin, sin
volver a ingresar API/token, sin ningún error.

## 2.1 FLUJO EXACTO QUE YO QUIERO (cuatro pasos)

Este es el flujo, en este orden. Si tu implementación no permite hacerlo así,
dímelo antes de construir otra cosa.

```
PASO 1  Instalo Ubuntu Server y configuro el módem hasta tener internet.
        NO instalo Hermes. NO configuro nada más.

PASO 2  Escribo UNA sola línea en la terminal de Ubuntu (la que está en el README
        del repositorio). Esa línea ya lleva el PAT del repositorio dentro, así que
        al dar Enter NO se me pregunta nada.
        Variante aceptable: una línea que, al dar Enter, me pida el PAT una vez.

PASO 3  Esa misma línea: instala Hermes por su cuenta, clona el snapshot más
        reciente, y restaura TODO el estado (ver 2.4).

PASO 4  Reinicio (sudo reboot) para que la restauración quede aplicada.
        Después del reinicio, todo debe estar como lo dejé la última vez.
```

El comando del PASO 2 debe ser literalmente una línea, copiable tal cual, sin
editar rutas ni completar variables a mano.

## 2.2 REPOSITORIO Y CREDENCIALES

- Un repositorio **PRIVADO** en GitHub para el snapshot (los scripts usan el nombre
  "Pull Issue Content"; si lo cambias, actualiza también el script y el README).
- Se usa un **PAT clásico o fine-grained** con permiso de **Contents: Read and write**
  sobre ese repositorio. Ese PAT va **dentro del one-liner del README**, para que el
  PASO 2 no pida autenticación.
- Instálalo también en el servidor: `hermes config set GITHUB_TOKEN <token>`.
- Verifica de verdad que el token lee y escribe ese repositorio. Si falla, dime qué
  permiso falta, no lo dejes en "debería funcionar".

**Decisión mía, explícita:** acepto que el respaldo contenga credenciales
(`.env`, tokens, API keys, cookies de sesión, sesiones de WhatsApp, claves SSH,
credenciales de git). El repositorio es privado y solo el técnico tiene acceso.
No intentes "limpiar" ni censurar credenciales para quedar bien: si falta una,
el restore deja de ser total y me obliga a rehacer logins.

## 2.3 JADWAL

- Backup automático con cron **2 veces al día** (por ejemplo 02:00 y 14:00 hora del
  servidor). No más seguido: llena el historial sin aportar nada.
- El respaldo anterior NO se sobrescribe: se conserva el historial (commits).
- Cada ejecución debe terminar con push verificado. Si el push falla, **reintenta**
  (mínimo 3 intentos) y guarda el registro del error; nunca dejes un push fallido
  reportado como "éxito", y nunca confundas "ok" con "ya subió".

## 2.4 COBERTURA TOTAL (qué debe volver)

Se respalda **TODO**, incluidas carpetas que aparezcan después. **No uses
allowlist/whitelist.** La blacklist solo se permite para lo que se regenera solo
(caché, logs, temporales) y cada exclusión debe estar anotada en el README con su
motivo, comprobando que su ausencia no rompe el arranque.

Lo que tiene que volver, sin excepción:

- **Hermes**: `config.yaml` (modelos, gateway, MCP, herramientas, STT, delegación),
  `skills/`, `cron/` con todos los jobs, `memories/`, base de memoria persistente,
  `sessions/`, `knowledge/`, `scripts/`, `vault/`, `remote-view/` (con su perfil de
  navegador), plantillas y documentos.
- **Cada perfil por separado**, completo: `config.yaml`, `skills/`, `cron/`,
  `memories/`, `knowledge/`, `scripts/`, `sessions/`, `state.db` (historial de
  conversación), `.env`, `vault/`, auths, y cualquier carpeta nueva del perfil.
- **Credenciales y sesiones**: `.env` de todos los perfiles, tokens de bot,
  `google_token.json`, `auth.json`, cookies/sesiones de navegador (para no volver a
  iniciar sesión), sesión de WhatsApp, `~/.ssh/`, `.git-credentials`, `rclone.conf`,
  vault (clave + contenido).
- **Sistema**: `docker-compose`, dumps de base de datos, unidades systemd, crontab.

Meta medible: **state vuelve 100% sin relogin, sin retoken, sin re-API, sin error.**
Si para lograrlo hay que subir todo, sube todo.

Reglas técnicas obligatorias:

- **Conserva permisos, owner y symlinks** (`tar -p` o `rsync -a`); no los normalices.
- **Los symlinks de skills NO pueden guardarse como enlace**: si una skill es un
  symlink a otra ruta, guárdala con su **contenido real** (dereference). Un symlink
  guardado como enlace deja un enlace roto después del restore y esa skill
  desaparece. Además, nunca guardes symlinks con ruta absoluta del servidor
  original: en un servidor con otro usuario no resuelven.
- `state.db` puede ir comprimido (`.zst`) para no chocar con el límite de GitHub,
  pero debe restaurarse y quedar íntegro (`PRAGMA integrity_check` = `ok`).

## 2.5 README DEL REPOSITORIO PRIVADO (parte de la entrega)

El README del repositorio de respaldo debe contener, escrito y no supuesto:

1. El **flujo de cuatro pasos** de 2.1 tal cual (instalar Ubuntu → una línea →
   restore → reiniciar).
2. El **one-liner listo para copiar y pegar, con el PAT incluido**, y la variante
   que pide el PAT una vez.
3. La **lista de lo que se restaura** (Hermes, cada perfil, credenciales, sistema)
   y la lista de exclusiones con su motivo, si hay alguna.
4. La nota de seguridad: por qué las credenciales están dentro (repositorio
   privado, solo el técnico tiene acceso) y qué implica.
5. El **resultado real de la prueba** de 2.7 con números.
6. Los pasos posteriores al restore: `sudo reboot`, y las comprobaciones
   (`hermes --version`, estado del gateway, prueba de remote view).
7. Solución de problemas: PAT rechazado (401), push fallido (dónde está el log),
   y qué hacer si una skill no aparece.

## 2.6 RESTORE (requisito duro)

- En un Ubuntu Server vacío, yo **NO** instalo Hermes ni configuro nada: el
  one-liner instala Hermes por su cuenta si no está.
- Basta ejecutar ese comando → todo vuelve al último backup y funciona de inmediato.
- Condiciones: **SIN relogin, SIN volver a ingresar API/token, SIN ningún error.**
- No me pidas nada más que el acceso a ese GitHub.
- Si algo requiere intervención manual, debe ser **después** del restore y estar
  escrito en el README (por ejemplo levantar un contenedor de Docker). Todo lo que
  sea credencial o configuración debe volver solo.

## 2.7 PRUEBA OBLIGATORIA EN HOME FALSO (antes de darlo por bueno)

Nunca pruebes sobre el HOME real ni sobre la base de datos en uso. Crea un entorno
aislado de verdad:

- HOME, HERMES_HOME y TMPDIR falsos, y `sudo`, `systemctl`, `crontab`, `docker`,
  `apt`, `curl` desviados a un `PATH` falso, para que el sistema real no se toque.
- El restore se prueba **clonando desde GitHub**, no desde el directorio local: así
  se comprueba lo que de verdad hay subido.
- Compara original contra restaurado con **checksum sha256 y tamaño** de cada
  archivo, y compara el **contenido** de cada base (`integrity_check` y número de
  mensajes), no solo que el archivo exista.
- Comprueba explícitamente: todos los perfiles, todos los `.env` (mismas claves),
  cron (mismo número de jobs), skills (misma cantidad, sin enlaces rotos),
  credenciales, cookies y vault.
- Exige **100%**: si algo no coincide o falta, corrige y repite hasta que pase.
  No me entregues "casi listo" ni me reportes éxito sin números.
- Al terminar, dime: cuántas comprobaciones hiciste, cuántas pasaron, cuántas
  fallaron, y cuánto tardó el restore.

## 2.8 ENTREGA (una línea)

Dame en una línea: la hora del cron, el comando de restore, y el resultado de la
prueba (comprobaciones / pasadas / fallidas / duración). Debajo, si algo quedó
pendiente, dilo sin adornos.

# 3. REMOTE VIEW (con resolución alta y vertical)

Prepárame el Remote View y ábrelo tú mismo en el navegador, para que yo solo tenga que entrar y escribir mi contraseña.

Regla de pantalla, importante:
- Usa una resolución **alta y en formato vertical (más alto que ancho)**, del tipo 1080×1920 o similar.
- Motivo: en pantallas anchas y bajas, las páginas quedan cortadas y hay que hacer scroll para ver los botones importantes. Con formato vertical largo se ve todo de arriba a abajo sin que nada quede tapado.
- Comprueba que la ventana del navegador esté maximizada dentro de esa resolución, no flotando en una esquina.

Además, en esta misma sesión remota, deja listas dos capacidades nuevas y verifícalas de verdad (no me digas "debería funcionar"):

**3.a Generar imágenes con Gemini (web, sesión ya iniciada)**
- Abre Gemini en el navegador remoto y genera una imagen de prueba.
- Descárgala a una carpeta del servidor y dime la ruta exacta.
- Guarda el método como skill reutilizable: qué botón se pulsa, dónde se escribe el prompt, cómo se descarga el resultado.
- Si el botón cambió de sitio, NO inventes: busca el botón correcto, y si no lo encuentras, dime exactamente qué ves en pantalla.

**3.b Generar video con NotebookLM (web, sesión ya iniciada)**
- Abre NotebookLM, crea un cuaderno nuevo y genera un Video Overview de prueba.
- Espera a que termine y descarga el archivo al servidor. Dime la ruta, la duración y el tamaño.
- Guarda el método como skill aparte, con sus propios pasos: no copies el formato de la skill de imágenes, porque los botones y los tiempos son distintos.
- Regla fija: el video NO puede llevar el crédito de "Gemini Notebook" visible. Cuando lo entregues, córtalo justo en el fotograma donde empieza ese crédito, y verifica que no quede ni un fotograma negro ni una palabra cortada.

# 4. STT CON GROQ (pregúntame primero)

Ofréceme cambiar el reconocimiento de voz a Groq:

"¿Quieres activar el STT con Groq, modelo Whisper large-v3? (Y/n)"

Si digo que sí:
- Pídeme la API key de Groq. Yo la pego, tú no la inventes ni la busques en otro sitio.
- Configura Whisper **large-v3**.
- Pon el idioma en **"id"** (indonesio) para todos los audios, no en automático.
- Verifica con un audio de prueba real: envíame la transcripción y comprueba que las palabras en indonesio salen correctas.

Si digo que no, déjalo como está y no vuelvas a preguntar en esta sesión.

# 5. SESIÓN DE GOOGLE CON LA CUENTA NUEVA (pregúntame primero)

"¿Quieres que iniciemos sesión en Google con la cuenta nueva, a través del Remote View? (Y/n)"

Si digo que sí:
- Abre el Remote View y deja la página de inicio de sesión de Google lista en el navegador.
- Dame la URL exacta y dime cuándo está lista.
- Yo escribo el correo y la contraseña; tú NUNCA me pidas que te los dicte ni los escribas por mí.
- Después de que yo entre, verifica el acceso de verdad: lista mis archivos de Drive y dime cuántos ves. Si no puedes, dime qué error aparece.
- Si hay verificación en dos pasos, avísame antes de que se agote el tiempo.

# 6. GATEWAY DE TELEGRAM (pregúntame primero)

"¿Quieres conectar el gateway de Telegram (o X) para que me puedas dar órdenes al robot desde el móvil? (Y/n)"

Si digo que sí:
- Guíame paso a paso: crear el bot con BotFather, copiar el token, pegarlo donde corresponda.
- Configura el gateway, arráncalo y comprueba que el servicio queda activo (no solo "iniciado").
- Pídeme que te mande un mensaje de prueba y confirma que lo recibiste y respondiste.
- Si hay dos gateways corriendo a la vez, detén uno: dos procesos peleando por el mismo token rompen la base de datos.

Si digo que no, sáltalo y sigue.

# 7. GATEWAY DE WHATSAPP (pregúntame primero)

"¿Quieres conectar el gateway de WhatsApp para que el robot te represente ahí? (Y/n)"

Si digo que sí:
- Prepara el servicio y muéstrame el QR en una página que se actualice sola cada 20 segundos, o dame el código de 8 dígitos.
- Explícame claramente qué debo hacer en mi teléfono.
- Cuando esté conectado, verifica que funciona de verdad: pídeme un mensaje de prueba y confirma que lo leíste en la base de datos. No te conformes con que diga "conectado".
- Si falla, dime exactamente qué falló. Si un método ya falló, prueba otro; no adivines dos veces lo mismo.

# 8. CERRAR EN INDONESIO Y LANJUTKAN

Sampai di sini, kembali ke bahasa Indonesia untuk percakapan kita.

Setelah poin 1 sampai 7 selesai (yang tidak saya setujui, lewati saja dan catat sebagai "ditolak"), lakukan ini sekarang juga tanpa menunggu perintah saya:

1. Ambil dan jalankan isi berkas `prompt-2-steps/structured-setup/4-mandatory-offer.md` dari repo yang sama.
2. Ikuti isinya persis, jangan diringkas dan jangan ditambah sendiri.
3. Setelah selesai, beri saya ringkasan singkat dalam bahasa Indonesia:

```
- Apa yang sudah jalan (dengan bukti ujinya, bukan "sudah beres")
- Apa yang belum jalan dan apa yang Anda butuhkan dari saya
- Metode mana yang gagal dan mana yang berhasil, supaya besok tidak diulang
```
