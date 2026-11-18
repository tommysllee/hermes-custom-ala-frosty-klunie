Acabas de instalar Hermes y ya puedes chatear conmigo desde el gateway. Pero antes de que hagamos cualquier otra cosa, necesito darte cuatro recordatorios y que los ejecutes EN ESTE ORDEN. No los saltes.

Escribe en español, porque así me lo pidió mi jefe. Si en algún momento te pido cambiar de idioma, lo cambio, pero el idioma por defecto ahora es español.

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

Cada vez que guardes algo, dime en una línea dónde lo pusiste y por qué ahí.

# 2. CONECTAR WHATSAPP

Necesito que puedas leer y enviar mensajes de WhatsApp por mí. Esto requiere que yo escanee un código QR o ingrese un código de 8 dígitos, así que guíame paso a paso:

- Primero prepárate: deja el servicio listo y muéstrame el QR en una página que se actualice sola cada 20 segundos, o dame el código de 8 dígitos.
- Explícame claramente qué debo hacer en mi teléfono.
- Cuando esté conectado, verifica que realmente funciona: NO te conformes con que diga "conectado". Pídeme que te mande un mensaje de prueba y confirma que lo leíste en la base de datos.
- Si falla, dime exactamente qué falló. No adivines dos veces lo mismo: si un método ya falló, prueba otro.

# 3. INICIAR SESIÓN EN GOOGLE DESDE REMOTE VIEW

Necesito que tengas acceso a mi Google (Drive, Sheets, Docs) para poder trabajar con mis archivos.

- Prepárame el Remote View y ábrelo tú mismo en el navegador, para que yo solo tenga que entrar y escribir mi contraseña.
- Avisa con claridad cuándo está listo y qué URL debo abrir.
- Después de que yo inicie sesión, verifica que de verdad tienes acceso: intenta listar mis archivos de Drive. Si no puedes, dímelo.
- Recuerda: yo escribo la contraseña, no tú. Nunca me pidas que te la dicte.

# 4. CREAR GITHUB Y SU TOKEN (PAT)

Necesito respaldo automático de todo mi sistema en GitHub. Guíame para:

- Crear un repositorio PRIVADO para el respaldo.
- Crear un token de acceso personal (fine-grained PAT) con estos permisos exactos:
  - **Contents**: Read and write
  - **Issues**: Read and write
  - **Pull requests**: Read and write
- Instalarlo con: `hermes config set GITHUB_TOKEN <token>`

Cuando el token esté puesto, verifica que funciona de verdad: intenta leer el repositorio con ese token. Si devuelve error de permisos, dime cuál permiso falta.

# 5. CONFIGURAR AUTOBACKUP

Cuando los puntos 1 a 4 estén listos, configura el respaldo automático de TODO el estado de Hermes:

- Skills, cron, templates, knowledge, scripts
- Perfiles, configuraciones, accesos, sesiones, state.db

Requisitos:
- Que sea **restaurable al 100%** después de reinstalar (pasos a y b): un comando y todo vuelve — sin volver a poner API keys, sin volver a iniciar sesión en nada, sin errores.
- Que corra con un cron propio, y que el respaldo anterior se conserve (no que se sobrescriba y se pierda el historial).
- Que verifiques que el respaldo se puede RESTAURAR, no solo que se creó. Un respaldo que nunca se probó no es un respaldo.

# AL TERMINAR

Dame un resumen corto con:
- Qué quedó funcionando (con la prueba que lo demuestra, no con "ya está")
- Qué quedó pendiente y qué necesitas de mí
- Qué métodos fallaron y cuáles no, para no repetir el error mañana
