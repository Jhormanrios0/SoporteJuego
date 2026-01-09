# 🎮 Proyecto Arcade Game - Resumen Ejecutivo

## 📊 Estructura Completa del Proyecto

```
c:\Coding\SoporteJuego/
│
├── 📂 public/                      # Assets estáticos
│   ├── hearts/
│   │   ├── full.svg               ❤️ Corazón lleno
│   │   ├── empty.svg              🖤 Corazón vacío
│   │   └── README.md              📖 Guía de sprites
│   └── arcade.svg                 🎯 Icono del sitio
│
├── 📂 src/
│   ├── 📂 components/             # Componentes Vue
│   │   ├── HeartsBar.vue          ❤️ Barra de corazones visual
│   │   ├── PlayerCard.vue         🃏 Tarjeta de jugador
│   │   ├── AdminPlayerRow.vue     ⚙️ Fila editable admin
│   │   └── ConfirmModal.vue       ⚠️ Modal de confirmación
│   │
│   ├── 📂 views/                  # Vistas principales
│   │   ├── PublicView.vue         👀 Panel público (/)
│   │   └── AdminView.vue          🔐 Panel admin (/admin)
│   │
│   ├── 📂 services/               # Servicios
│   │   └── supabase.js            🔌 Cliente Supabase + API
│   │
│   ├── App.vue                    🏠 Componente raíz
│   ├── main.js                    🚀 Entry point + Router
│   └── style.css                  🎨 Estilos globales retro
│
├── 📂 supabase/
│   └── schema.sql                 🗄️ Schema completo de BD
│
├── 📂 .vscode/
│   └── extensions.json            🔧 Extensiones recomendadas
│
├── 📄 .env.example                🔑 Template variables
├── 📄 .gitignore                  🚫 Archivos ignorados
├── 📄 index.html                  🌐 HTML principal
├── 📄 package.json                📦 Dependencias
├── 📄 vite.config.js              ⚡ Configuración Vite
├── 📄 jsconfig.json               🔧 Configuración JS
├── 📄 vercel.json                 ☁️ Deploy Vercel
├── 📄 README.md                   📖 Documentación principal
└── 📄 DEPLOY.md                   🚀 Guía de deploy
```

---

## 🎯 Funcionalidades Implementadas

### ✅ Panel Público (/)

- [x] Vista de todos los jugadores sin autenticación
- [x] Corazones visuales (12 por jugador)
- [x] Contador numérico "X/12"
- [x] Ordenamiento por menos vidas
- [x] Actualización en tiempo real (Supabase Realtime)
- [x] Diseño responsive mobile-first
- [x] Efectos CRT retro con scanlines

### ✅ Panel Admin (/admin)

- [x] Login seguro con Supabase Auth
- [x] Crear jugadores (nickname único)
- [x] Quitar vidas: -1, -3, -5, o custom
- [x] Campo de razón opcional
- [x] Reset individual de vidas
- [x] Reset global con confirmación
- [x] Historial de eventos completo
- [x] Eliminar jugadores
- [x] Logout seguro

### ✅ Base de Datos (Supabase)

- [x] Tabla `players` con RLS
- [x] Tabla `life_events` para historial
- [x] Tabla `profiles` para rol admin
- [x] Triggers automáticos (updated_at, crear perfil)
- [x] RPC Functions seguras:
  - [x] `admin_remove_lives()`
  - [x] `admin_reset_lives()`
  - [x] `admin_reset_lives_all()`
- [x] Row Level Security habilitado
- [x] Policies configuradas

### ✅ Diseño 8-bit Retro

- [x] Tipografía Press Start 2P
- [x] Paleta neón (#00ff88, #00ffff, #ff0055)
- [x] Efectos CRT con scanlines animadas
- [x] Bordes con glow neón
- [x] Animaciones de hover y pulse
- [x] Sprites de corazones pixel art
- [x] Scrollbar personalizado
- [x] Modales con estilo arcade

---

## 🛠️ Stack Tecnológico

| Tecnología  | Versión | Propósito                |
| ----------- | ------- | ------------------------ |
| Vue         | 3.4+    | Framework frontend       |
| Vue Router  | 4.2+    | Navegación SPA           |
| Vite        | 5.0+    | Build tool               |
| Supabase JS | 2.39+   | Cliente Supabase         |
| PostgreSQL  | -       | Base de datos (Supabase) |
| Vercel      | -       | Hosting + CDN            |

---

## 📋 Checklist de Deploy

### Supabase

- [ ] Crear proyecto en Supabase
- [ ] Ejecutar `supabase/schema.sql`
- [ ] Crear usuario admin
- [ ] Asignar rol admin (`UPDATE profiles SET is_admin = true`)
- [ ] Habilitar Realtime para tabla `players`
- [ ] Copiar URL y anon key

### GitHub

- [ ] Inicializar git: `git init`
- [ ] Crear repositorio en GitHub
- [ ] Push inicial: `git push -u origin main`

### Vercel

- [ ] Importar repositorio desde GitHub
- [ ] Configurar variables de entorno:
  - [ ] `VITE_SUPABASE_URL`
  - [ ] `VITE_SUPABASE_ANON_KEY`
- [ ] Deploy automático
- [ ] Verificar funcionamiento

---

## 🔐 Seguridad

### ✅ Implementado

- Row Level Security (RLS) en todas las tablas
- Solo admin puede modificar datos
- Lectura pública sin exponer datos sensibles
- RPC functions con verificación de rol
- Variables de entorno para secretos
- HTTPS automático por Vercel
- Anon key segura (diseñada para frontend)

### ⚠️ Nunca exponer

- `service_role` key de Supabase
- Database password directo
- JWT secret

---

## 📊 Esquema de Base de Datos

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│   players   │         │ life_events  │         │  profiles   │
├─────────────┤         ├──────────────┤         ├─────────────┤
│ id (PK)     │←────────│ player_id(FK)│         │ id (PK/FK)  │
│ nickname    │         │ admin_id (FK)│←────────│ email       │
│ lives       │         │ delta        │         │ is_admin    │
│ max_lives   │         │ reason       │         │ created_at  │
│ created_at  │         │ created_at   │         └─────────────┘
│ updated_at  │         └──────────────┘
└─────────────┘
```

**Relaciones:**

- `life_events.player_id` → `players.id` (CASCADE DELETE)
- `life_events.admin_id` → `auth.users.id` (SET NULL)
- `profiles.id` → `auth.users.id` (CASCADE DELETE)

---

## 🎨 Paleta de Colores

```css
/* Neón Principal */
#00ff88  /* Verde neón - primario */
#00ffff  /* Cyan neón - secundario */
#ff0055  /* Rosa neón - alertas */
#ffaa00  /* Naranja - warnings */

/* Fondos */
#0a0015  /* Oscuro principal */
#1a0030  /* Oscuro gradiente */
#000000  /* Negro puro */

/* Acentos */
#888888  /* Gris neutral */
#333333  /* Gris oscuro */
```

---

## 📱 Responsive Breakpoints

```css
/* Desktop first */
@media (max-width: 768px) {
  /* Tablets */
}
@media (max-width: 480px) {
  /* Móviles */
}
```

---

## 🚀 Comandos de Desarrollo

```bash
# Instalar dependencias
npm install

# Desarrollo local (http://localhost:5173)
npm run dev

# Build para producción
npm run build

# Preview del build
npm run preview

# Deploy en Vercel (opcional, con Vercel CLI)
vercel --prod
```

---

## 🔄 Flujo de Trabajo Típico

1. **Usuario público** entra a `/`
2. Ve todos los jugadores y sus vidas
3. No necesita login
4. **Admin** entra a `/admin`
5. Hace login con email/password
6. Crea jugadores o modifica vidas
7. Cambios se reflejan en tiempo real en panel público
8. Historial queda registrado en `life_events`

---

## 📚 Archivos de Documentación

| Archivo                   | Contenido                          |
| ------------------------- | ---------------------------------- |
| `README.md`               | Documentación general del proyecto |
| `DEPLOY.md`               | Guía paso a paso de deploy         |
| `supabase/schema.sql`     | Schema completo con comentarios    |
| `public/hearts/README.md` | Guía para sprites de corazones     |

---

## 🐛 Troubleshooting Rápido

### Error: "No autorizado"

```sql
-- Solución: Asignar rol admin
UPDATE profiles SET is_admin = true WHERE email = 'tu-email';
```

### Error: Variables de entorno no encontradas

```bash
# Solución: Verificar .env local
cat .env

# Solución: Verificar en Vercel
# Settings → Environment Variables
```

### Realtime no funciona

```
Solución: Database → Replication → Activar para tabla "players"
```

---

## ✨ Mejoras Futuras (Backlog)

- [ ] Sonidos 8-bit al quitar vidas
- [ ] Exportar historial a CSV
- [ ] Sistema de logros/badges
- [ ] Ranking de "supervivientes"
- [ ] Modo oscuro/claro
- [ ] Notificaciones push
- [ ] Tests unitarios (Vitest)
- [ ] Tests E2E (Playwright)
- [ ] CI/CD con GitHub Actions
- [ ] Múltiples idiomas (i18n)

---

## 📞 Contacto y Soporte

- 📧 Email: support@ejemplo.com
- 🐛 Issues: GitHub Issues
- 💬 Discussions: GitHub Discussions
- 📖 Docs: README.md + DEPLOY.md

---

**Estado del proyecto:** ✅ Completo y listo para deploy

**Última actualización:** 2026-01-09

---

Creado con ❤️ y estilo retro 8-bit 🎮
