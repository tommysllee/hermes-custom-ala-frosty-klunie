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

# 2. AUTOBACKUP

Configura el respaldo automático de TODO el estado de Hermes:

- Skills, cron, templates, knowledge, scripts
- Perfiles, configuraciones, accesos, sesiones, state.db

Antes de eso, si todavía no existe, crea el respaldo en GitHub:

- Un repositorio **PRIVADO** (de preferencia llamado "Pull Issue Content", es el nombre que usan los scripts).
- Un token de acceso personal (fine-grained PAT) con estos permisos exactos:
  - **Contents**: Read and write
  - **Issues**: Read and write
  - **Pull requests**: Read and write
- Instálalo con: `hermes config set GITHUB_TOKEN <token>`
- Verifica de verdad: intenta leer el repositorio con ese token. Si devuelve error de permisos, dime cuál permiso falta.

Requisitos del respaldo:
- Que sea **restaurable al 100%**: un comando y todo vuelve — sin volver a poner API keys, sin volver a iniciar sesión en nada, sin errores.
- Que corra con un cron propio (dos veces al día es razonable), y que el respaldo anterior se conserve: el historial no se sobrescribe.
- Que verifiques que el respaldo se puede RESTAURAR, no solo que se creó. Un respaldo que nunca se probó no es un respaldo.
- Los tokens y contraseñas van fuera del repositorio y con permisos 600; nunca los pegues en un archivo que se sube.

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
