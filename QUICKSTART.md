# 🎮 Guía Rápida - Primeros Pasos

Sigue estos pasos para tener el proyecto funcionando en 10 minutos.

---

## ⚡ Setup Rápido (Local)

### 1. Instalar dependencias

```bash
npm install
```

### 2. Configurar variables de entorno

```bash
# Copiar el archivo de ejemplo
copy .env.example .env   # Windows
# cp .env.example .env   # Mac/Linux
```

Edita `.env` y completa con tus credenciales de Supabase.

### 3. Iniciar desarrollo

```bash
npm run dev
```

Abre http://localhost:5173

---

## 🗄️ Setup de Supabase (5 minutos)

### 1. Crear proyecto

- Ve a https://supabase.com
- "New Project"
- Espera ~2 minutos

### 2. Ejecutar SQL

- SQL Editor → New query
- Copia todo de `supabase/schema.sql`
- Run ▶️

### 3. Crear admin

```sql
-- Authentication → Users → Add user
-- Luego ejecuta:
UPDATE profiles
SET is_admin = true
WHERE email = 'tu-email@ejemplo.com';
```

### 4. Obtener credenciales

- Settings → API
- Copia URL y anon key
- Pégalos en `.env`

---

## ✅ Verificar que funciona

1. Panel público: http://localhost:5173

   - ✅ No hay errores en consola
   - ✅ Mensaje "No hay jugadores"

2. Panel admin: http://localhost:5173/admin
   - ✅ Aparece formulario de login
   - ✅ Puedes hacer login
   - ✅ Puedes crear jugadores

---

## 🚀 Deploy en Vercel (3 minutos)

### 1. Subir a GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/tu-usuario/arcade-game.git
git push -u origin main
```

### 2. Importar en Vercel

- https://vercel.com/new
- Importar repositorio
- Configurar variables de entorno (mismas del `.env`)
- Deploy

### 3. Probar

- Abre tu URL de Vercel
- Verifica que funciona igual que en local

---

## 🆘 Problemas Comunes

### "Supabase URL not found"

**Solución:** Verifica que `.env` existe y tiene las variables correctas.

### "No autorizado" al quitar vidas

**Solución:** El usuario no es admin. Ejecuta:

```sql
UPDATE profiles SET is_admin = true WHERE email = 'tu-email';
```

### Realtime no funciona

**Solución:** Database → Replication → Activar tabla `players`

---

## 📚 Más información

- 📖 Documentación completa: `README.md`
- 🚀 Guía de deploy: `DEPLOY.md`
- 📊 Resumen del proyecto: `PROJECT_SUMMARY.md`

---

¡Listo! 🎉 Ahora tienes el proyecto funcionando.
