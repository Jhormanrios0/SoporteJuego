# 🎮 Guía de Deploy - Arcade Game Vidas

Guía completa para desplegar tu proyecto Vue 3 + Supabase + Vercel

---

## 📋 Requisitos previos

- Cuenta en [Supabase](https://supabase.com) (gratuita)
- Cuenta en [Vercel](https://vercel.com) (gratuita)
- Git instalado localmente
- Node.js 18+ instalado

---

## 🗄️ PASO 1: Configurar Supabase

### 1.1 Crear proyecto en Supabase

1. Ve a https://app.supabase.com
2. Click en "New Project"
3. Completa:
   - **Name**: `arcade-game` (o el que prefieras)
   - **Database Password**: Genera una contraseña segura (guárdala)
   - **Region**: Selecciona la más cercana a tus usuarios
4. Click "Create new project" (tarda ~2 minutos)

### 1.2 Ejecutar el esquema SQL

1. En el dashboard de Supabase, ve a **SQL Editor** (menú lateral)
2. Click en "New query"
3. Copia y pega TODO el contenido de `supabase/schema.sql`
4. Click en **"Run"** (botón verde abajo a la derecha)
5. Deberías ver: "Success. No rows returned"

### 1.3 Crear usuario admin

1. Ve a **Authentication → Users** en el menú lateral
2. Click en "Add user" → "Create new user"
3. Ingresa:
   - **Email**: tu email de admin (ej: `admin@tudominio.com`)
   - **Password**: contraseña segura
   - **Auto Confirm User**: ✅ Activar
4. Click "Create user"

### 1.4 Asignar rol admin

1. Ve a **SQL Editor** nuevamente
2. Ejecuta este query (reemplaza el email):

```sql
UPDATE profiles
SET is_admin = true
WHERE email = 'admin@tudominio.com';
```

3. Verifica que se actualizó 1 fila

### 1.5 Habilitar Realtime (opcional pero recomendado)

1. Ve a **Database → Replication** en el menú lateral
2. Busca la tabla `players`
3. Activa el toggle de **Realtime**
4. Esto permite que el panel público se actualice en vivo

### 1.6 Obtener las credenciales

1. Ve a **Settings → API** en el menú lateral
2. Copia estos valores (los necesitarás):
   - **Project URL** (ej: `https://abcdefghijk.supabase.co`)
   - **anon public key** (una clave larga que empieza con `eyJ...`)

---

## 💻 PASO 2: Preparar el código localmente

### 2.1 Clonar o inicializar el repositorio

```bash
# Si estás en el proyecto local
cd c:\Coding\SoporteJuego

# Inicializar git (si no lo has hecho)
git init
git add .
git commit -m "Initial commit - Arcade Game"
```

### 2.2 Crear `.env` local para desarrollo

Crea un archivo `.env` en la raíz del proyecto:

```bash
# .env
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu-clave-anon-aqui
```

**⚠️ IMPORTANTE:** Reemplaza con tus credenciales reales de Supabase (Paso 1.6)

### 2.3 Instalar dependencias

```bash
npm install
```

### 2.4 Probar en local

```bash
npm run dev
```

Abre http://localhost:5173 y verifica:

- ✅ Panel público carga sin errores
- ✅ Puedes ir a `/admin` y hacer login
- ✅ Puedes crear jugadores y quitar vidas

---

## 🚀 PASO 3: Desplegar en Vercel

### 3.1 Subir código a GitHub

1. Crea un nuevo repositorio en GitHub (ej: `arcade-game-vidas`)
2. Sube tu código:

```bash
git remote add origin https://github.com/tu-usuario/arcade-game-vidas.git
git branch -M main
git push -u origin main
```

### 3.2 Importar proyecto en Vercel

1. Ve a https://vercel.com/new
2. Click "Import Git Repository"
3. Selecciona tu repositorio `arcade-game-vidas`
4. Vercel detectará automáticamente que es un proyecto Vite

### 3.3 Configurar variables de entorno

Antes de hacer deploy, en la sección **Environment Variables**:

| Name                     | Value                             |
| ------------------------ | --------------------------------- |
| `VITE_SUPABASE_URL`      | `https://tu-proyecto.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | `eyJ...` (tu clave anon)          |

**Aplica a:** All (Production, Preview, Development)

### 3.4 Deploy

1. Click en **"Deploy"**
2. Espera ~2 minutos
3. ✅ Tu app estará en vivo en: `https://tu-proyecto.vercel.app`

---

## 🎨 PASO 4: Agregar sprites de corazones (opcional)

Por defecto, el proyecto espera sprites en `/public/hearts/`. Si no los tienes:

### Opción A: Usar emojis temporalmente

Edita `src/components/HeartsBar.vue`:

```vue
<!-- Reemplaza las <img> por: -->
<span
  v-for="i in maxLives"
  :key="i"
  :class="['heart-emoji', { 'heart-lost': i > lives }]"
>
  {{ i <= lives ? '❤️' : '🖤' }}
</span>
```

Y añade este CSS:

```css
.heart-emoji {
  font-size: 24px;
  filter: drop-shadow(0 0 4px rgba(255, 0, 85, 0.8));
}

.heart-emoji.heart-lost {
  opacity: 0.3;
  filter: grayscale(100%);
}
```

### Opción B: Crear sprites pixel art

1. Ve a https://www.piskelapp.com
2. Crea un sprite de 16x16 o 32x32 píxeles
3. Dibuja un corazón lleno (rojo) → Exporta como `full.png`
4. Dibuja un corazón vacío (gris) → Exporta como `empty.png`
5. Colócalos en `/public/hearts/`

### Opción C: Descargar assets gratuitos

- https://opengameart.org
- https://kenney.nl/assets
- https://itch.io/game-assets/free

Busca "pixel heart" y descarga sprites libres de derechos.

---

## 🔧 PASO 5: Configuraciones adicionales

### 5.1 Dominio personalizado (opcional)

1. En Vercel, ve a tu proyecto → **Settings → Domains**
2. Añade tu dominio personalizado (ej: `juego.tudominio.com`)
3. Configura los DNS según las instrucciones de Vercel

### 5.2 HTTPS automático

✅ Vercel incluye HTTPS automático con Let's Encrypt. No necesitas configurar nada.

### 5.3 Políticas de correo en Supabase

Si quieres que los usuarios admin puedan recuperar contraseña:

1. En Supabase, ve a **Authentication → Email Templates**
2. Personaliza los templates de:
   - Confirm signup
   - Reset password
   - Magic link

---

## 📊 PASO 6: Monitoreo y logs

### Ver logs de Supabase

1. Ve a **Logs → Explorer** en Supabase
2. Puedes ver queries, errores, y actividad de RLS

### Ver logs de Vercel

1. En tu proyecto de Vercel → **Logs**
2. Puedes ver errores de build y runtime

---

## 🐛 Troubleshooting común

### Error: "No autorizado" al quitar vidas

**Causa:** El usuario no tiene rol admin

**Solución:**

```sql
-- Ejecuta en SQL Editor de Supabase
UPDATE profiles
SET is_admin = true
WHERE email = 'tu-email';
```

### Error: "Supabase URL not found"

**Causa:** Variables de entorno no configuradas

**Solución:**

- Verifica que `.env` existe localmente
- Verifica que las variables están en Vercel (Environment Variables)
- Redeploy en Vercel si hiciste cambios

### Los cambios no se ven en tiempo real

**Causa:** Realtime no habilitado

**Solución:**

1. Ve a **Database → Replication** en Supabase
2. Activa Realtime para la tabla `players`

### Error al crear jugador: "violates unique constraint"

**Causa:** Ya existe un jugador con ese nickname

**Solución:** Los nicknames deben ser únicos. Usa otro nombre.

---

## 🔒 Seguridad

### ✅ Buenas prácticas implementadas:

- Row Level Security (RLS) habilitado
- Solo admin puede modificar datos
- Lectura pública sin autenticación
- RPC functions con verificación de rol
- Variables de entorno para secretos

### ⚠️ NUNCA expongas:

- `service_role` key de Supabase (tiene acceso total)
- Database password
- JWT secret

### ✅ Seguro exponer:

- `anon` key de Supabase (está diseñada para el frontend)
- Project URL

---

## 📱 Testing en producción

Después del deploy, prueba:

1. **Panel público (`/`)**

   - ✅ Se ven los jugadores sin login
   - ✅ Los corazones se muestran correctamente
   - ✅ La lista está ordenada por menos vidas

2. **Panel admin (`/admin`)**

   - ✅ Puedes hacer login con el usuario admin
   - ✅ Puedes crear jugadores
   - ✅ Puedes quitar vidas (1, 3, 5, o custom)
   - ✅ Puedes resetear individual y global
   - ✅ Ves el historial de eventos

3. **Realtime (prueba en 2 ventanas)**
   - ✅ Abre `/admin` en una ventana
   - ✅ Abre `/` en otra ventana (modo incógnito)
   - ✅ Quita vidas desde admin
   - ✅ Verifica que el panel público se actualiza solo

---

## 🎉 ¡Listo!

Tu proyecto está desplegado y funcionando. Ahora puedes:

- Compartir la URL pública (`/`) con jugadores
- Acceder al admin (`/admin`) con tus credenciales
- Monitorear la actividad desde Supabase

---

## 📝 Comandos útiles

```bash
# Desarrollo local
npm run dev

# Build de producción
npm run build

# Preview del build
npm run preview

# Desplegar en Vercel (si tienes Vercel CLI)
vercel --prod
```

---

## 🆘 Soporte

Si encuentras problemas:

1. Revisa los logs en Vercel y Supabase
2. Verifica que las variables de entorno están configuradas
3. Asegúrate de que el usuario admin tiene `is_admin = true`
4. Revisa la consola del navegador (F12) para errores JS

---

## 📚 Recursos adicionales

- [Documentación de Supabase](https://supabase.com/docs)
- [Documentación de Vercel](https://vercel.com/docs)
- [Vue 3 Documentation](https://vuejs.org)
- [Vite Documentation](https://vitejs.dev)

---

**Creado con ❤️ en estilo retro 8-bit**
