# Sistema de Sonidos de Daño

## ✅ Implementación Completada

Se ha agregado un sistema de sonidos que se reproduce en **TODOS los usuarios** cuando el administrador quita vidas a un jugador.

### 🔊 Cómo funciona:

1. El admin quita vidas a un jugador desde el panel de control
2. Todos los usuarios conectados en la vista pública reciben la notificación
3. **Se reproduce automáticamente** un sonido aleatorio:
   - 50% de probabilidad: `hahaDamage.mp3`
   - 50% de probabilidad: `MinecraftDamage.mp3`

### 📂 Dónde colocar los archivos de audio:

```
SoporteJuego/
└── src/
    └── assets/
        └── audio/
            ├── hahaDamage.mp3
            └── MinecraftDamage.mp3
```

La carpeta ya existe en: `src/assets/audio/`

### 📝 Pasos:

1. **Descarga o graba los sonidos:**

   - `hahaDamage.mp3` - Sonido cómico/divertido (ej: risa)
   - `MinecraftDamage.mp3` - Sonido de daño de Minecraft

2. **Coloca los archivos en `src/assets/audio/`**

   - Ambos deben ser archivos MP3
   - Máximo 500KB cada uno
   - Duración recomendada: 0.5 - 1.5 segundos

3. **Recarga el navegador** (F5)

4. **Prueba:**
   - Abre el panel público en una pestaña
   - Abre el admin en otra pestaña
   - El admin quita vidas
   - El sonido debe reproducirse en la vista pública

### 🔧 Configuración:

El volumen está configurado al 70% en el código. Si quieres cambiar:

- Ve a `src/views/PublicView.vue`
- Busca `randomSound.volume = 0.7`
- Cambia 0.7 a otro valor (0-1)
  - 0.5 = 50%
  - 0.9 = 90%
  - 1.0 = 100%

### 🎵 Dónde obtener sonidos:

**Opciones gratuitas:**

- Freesound (freesound.org)
- Zapsplat (zapsplat.com)
- Sonidos de Minecraft (Assets del juego)
- YouTube (busca "Minecraft damage sound" o "funny laugh sound")

**Requisitos:**

- Formato MP3
- Libre de derechos de autor (uso comercial permitido)
- Duración corta (no más de 2 segundos)

### ⚙️ Comportamiento:

- Se reproduce **para todos los usuarios** en tiempo real
- Sonido aleatorio entre los 2 disponibles
- Volumen: 70%
- Sin repetición de sonido en menos de 1 segundo
- Compatible con navegadores modernos

### ✅ Validaciones:

- Si un archivo de audio no existe, muestra error en consola pero no rompe la app
- Si el navegador bloquea audio automático, el usuario debe interactuar primero
- Los sonidos se limpian de memoria automáticamente
