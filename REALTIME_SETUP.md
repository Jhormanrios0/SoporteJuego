# Habilitar Realtime para notificaciones de muerte

Para que funcionen las notificaciones de muerte en tiempo real, necesitas habilitar Realtime en Supabase:

## Pasos:

1. Ve a tu proyecto en Supabase Dashboard
2. Ve a **Database** → **Replication**
3. En la lista de tablas, busca `life_events`
4. Haz clic en el switch para **habilitar** Realtime en esa tabla
5. Guarda los cambios

## ¿Qué hace esto?

Cuando el admin quite vidas a un jugador, el sistema:

- Genera automáticamente un mensaje de muerte aleatorio de Minecraft (ej: "PLAYER_01 fue explotado por un Creeper")
- Este mensaje se guarda en la tabla `life_events`
- Gracias a Realtime, todos los usuarios en la vista pública recibirán una notificación instantánea
- La notificación aparecerá en la esquina derecha con estilo retro y se eliminará después de 5 segundos

## Script SQL

También debes ejecutar el script `supabase/add-death-messages.sql` en el SQL Editor para actualizar la función que genera los mensajes aleatorios.
