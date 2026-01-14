# 🎮 Arcade Game - Sistema de Vidas

Sistema web retro 8-bit para gestionar vidas de jugadores, con panel público y administración privada.

![Vue 3](https://img.shields.io/badge/Vue-3-4FC08D?logo=vue.js)
![Supabase](https://img.shields.io/badge/Supabase-Database-3ECF8E?logo=supabase)
![Vercel](https://img.shields.io/badge/Deploy-Vercel-000000?logo=vercel)

---

## ✨ Características

- 🎨 **Diseño retro 8-bit** con efectos CRT y tipografía arcade
- 💚 **Sistema de vidas** representado con corazones pixel art (12 vidas por jugador)
- 👀 **Panel público** sin login para ver el estado de todos los jugadores
- 👤 **Login de usuario con Google** (opcional) para “entrar al juego”
- 🔐 **Panel admin** con autenticación para gestionar jugadores
- ⚡ **Actualización en tiempo real** con Supabase Realtime
- 📊 **Historial completo** de acciones del admin
- 🚀 **Deploy fácil** en Vercel con CI/CD automático

---

## 🏗️ Arquitectura

### Frontend

- **Vue 3** + Composition API
- **Vite** para bundling ultra-rápido
- **Vue Router** para navegación
- CSS vanilla con variables y efectos retro

### Backend

- **Supabase** (PostgreSQL + Auth + Realtime)
- **Row Level Security (RLS)** para protección de datos
- **RPC Functions** para lógica de negocio segura

### Deploy

- **Vercel** para hosting y CDN global
- **GitHub** para control de versiones

---

## 📁 Estructura del proyecto

```
SoporteJuego/
├── public/
│   ├── hearts/              # Sprites de corazones pixel art
│   │   ├── full.png         # Corazón lleno
│   │   ├── empty.png        # Corazón vacío
│   │   └── README.md        # Guía para crear sprites
│   └── arcade.svg           # Icono del sitio
├── src/
│   ├── components/
│   │   ├── HeartsBar.vue           # Barra de corazones visual
│   │   ├── PlayerCard.vue          # Card de jugador (panel público)
│   │   ├── AdminPlayerRow.vue      # Fila editable (panel admin)
│   │   └── ConfirmModal.vue        # Modal de confirmación
│   ├── views/
│   │   ├── PublicView.vue          # Panel público (/)
│   │   ├── AuthCallbackView.vue     # Callback OAuth (/auth/callback)
│   │   ├── UserRegisterView.vue     # Registro usuario (/register)
│   │   └── AdminView.vue            # Panel admin (/admin)
│   ├── services/
│   │   └── supabase.js             # Cliente y servicios de Supabase
│   ├── App.vue                     # Componente raíz
│   ├── main.js                     # Entry point + router
│   └── style.css                   # Estilos globales retro
├── supabase/
│   ├── schema.sql                  # Schema completo de BD
│   └── add-user-profile-fields.sql # Campos + policy para usuarios Google
├── .env.example                    # Template de variables de entorno
├── DEPLOY.md                       # Guía completa de deploy
├── package.json
├── vite.config.js
└── README.md
```

---

## 🚀 Inicio rápido

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/arcade-game-vidas.git
cd arcade-game-vidas
```

### 2. Instalar dependencias

```bash
npm install
```

### 3. Configurar variables de entorno

```bash
# Copia el ejemplo y edita con tus credenciales
cp .env.example .env
```

Edita `.env` con tus credenciales de Supabase:

```env
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu-clave-anon
```

### 4. Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Ve al SQL Editor y ejecuta `supabase/schema.sql`
3. (Usuarios Google) Ejecuta `supabase/add-user-profile-fields.sql`
4. Habilita Google OAuth en **Authentication → Providers → Google**
5. Agrega Redirect URLs (Authentication → URL Configuration):
   - `http://localhost:5173/auth/callback`
   - Tu URL de producción: `https://TU-DOMINIO/auth/callback`
6. Crea un usuario admin y asigna el rol (ver [DEPLOY.md](DEPLOY.md))

### 5. Iniciar desarrollo

```bash
npm run dev
```

Abre http://localhost:5173

---

## 🎮 Uso

### Panel Público (`/`)

- Ver todos los jugadores y sus vidas
- Corazones visuales + contador "X/12"
- Ordenado por menos vidas primero
- Actualización en tiempo real
- Sin necesidad de login

### Panel Admin (`/admin`)

**Requiere autenticación con email/password**

- Crear nuevos jugadores (nickname único)
- Quitar vidas: -1, -3, -5, o cantidad personalizada
- Agregar razón opcional para cada acción
- Resetear vidas de un jugador a 12
- Resetear TODAS las vidas con confirmación
- Ver historial completo de eventos
- Eliminar jugadores

---

## 🗄️ Base de datos

### Tablas principales

#### `players`

```sql
- id (BIGSERIAL PRIMARY KEY)
- nickname (VARCHAR(30) UNIQUE)
- lives (INTEGER 0-12)
- max_lives (INTEGER, default 12)
- created_at, updated_at
```

#### `life_events`

```sql
- id (BIGSERIAL PRIMARY KEY)
- player_id (FK → players)
- admin_id (FK → auth.users)
- delta (INTEGER) -- negativo si quita, positivo si resetea
- reason (TEXT)
- created_at
```

#### `profiles`

```sql
- id (UUID FK → auth.users)
- email (TEXT)
- is_admin (BOOLEAN)
- created_at

Opcional para usuarios Google (ver `supabase/add-user-profile-fields.sql`):

- display_name (TEXT)
- avatar_url (TEXT)
- updated_at
```

### RPC Functions

- `admin_remove_lives(player_id, amount, reason)` - Quita vidas (nunca < 0)
- `admin_reset_lives(player_id)` - Resetea un jugador
- `admin_reset_lives_all()` - Resetea todos los jugadores

### Row Level Security (RLS)

- ✅ Lectura pública de `players`
- 🔒 Solo admin puede escribir en `players`
- 🔒 Solo admin puede ver/crear `life_events`

---

## 🎨 Diseño y Estilo

### Paleta de colores

```css
--neon-green:  #00ff88  /* Primario */
--neon-cyan:   #00ffff  /* Secundario */
--neon-pink:   #ff0055  /* Alertas/acciones */
--neon-orange: #ffaa00  /* Warnings */
--bg-dark:     #0a0015  /* Fondo principal */
```

### Tipografía

- **Font principal:** Press Start 2P (Google Fonts)
- Tamaños: 0.7rem - 2.5rem
- Efectos: text-shadow con glow neón

### Efectos visuales

- Scanlines CRT animadas
- Bordes con glow neón
- Animaciones de hover y pulse
- Pixel art rendering para sprites

---

## 📦 Deploy en producción

Ver guía completa en [DEPLOY.md](DEPLOY.md)

**Resumen:**

1. Configurar Supabase (SQL + Auth + Admin user)
2. Subir código a GitHub
3. Importar en Vercel
4. Configurar variables de entorno
5. Deploy automático ✅

---

## 🛠️ Tecnologías utilizadas

| Categoría  | Tecnología                        |
| ---------- | --------------------------------- |
| Frontend   | Vue 3, Vue Router                 |
| Build tool | Vite                              |
| Backend    | Supabase (PostgreSQL)             |
| Auth       | Supabase Auth                     |
| Realtime   | Supabase Realtime                 |
| Hosting    | Vercel                            |
| Styles     | CSS3 (variables + grid + flexbox) |

---

## 📸 Screenshots

### Panel Público

- Grid responsive de jugadores
- Corazones visuales por jugador
- Efecto CRT y escanlines
- Diseño 8-bit retro

### Panel Admin

- Login seguro
- Gestión completa de jugadores
- Historial de eventos
- Confirmaciones para acciones críticas

---

## 🤝 Contribuir

¿Quieres mejorar el proyecto?

1. Fork el repositorio
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'Añadir nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

---

## 📝 Licencia

Este proyecto es de código abierto bajo licencia MIT.

---

## 🐛 Reporte de bugs

Si encuentras un bug, por favor abre un [Issue](https://github.com/tu-usuario/arcade-game-vidas/issues) con:

- Descripción del problema
- Pasos para reproducir
- Capturas de pantalla (si aplica)
- Navegador y versión

---

## 💡 Ideas de mejora

- [ ] Modo oscuro / modo claro
- [ ] Sonidos 8-bit al quitar vidas
- [ ] Exportar historial a CSV
- [ ] Sistema de logros/badges
- [ ] Ranking de supervivientes
- [ ] Modo "batalla" entre jugadores
- [ ] Notificaciones push

---

## 👨‍💻 Autor

Creado con ❤️ y mucho café ☕

---

## 🙏 Agradecimientos

- Google Fonts (Press Start 2P)
- Supabase team
- Vue.js community
- Vercel por el hosting gratuito

---

**¿Listo para jugar?** 🎮

Visita la demo: [https://tu-proyecto.vercel.app](https://tu-proyecto.vercel.app)
