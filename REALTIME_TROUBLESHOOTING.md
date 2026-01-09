# PASOS PARA ACTIVAR REALTIME Y NOTIFICACIONES

Sigue estos pasos en orden:

## 1. Ejecutar scripts SQL

### Script 1: Corregir política de life_events

Ve a Supabase → SQL Editor y ejecuta el contenido de `supabase/fix-life-events-policy.sql`

### Script 2: Corregir función de reset global (si no lo has hecho)

Ejecuta el contenido de `supabase/fix-reset-all.sql`

### Script 3: Actualizar función con mensajes de muerte

Ejecuta el contenido de `supabase/add-death-messages.sql`

## 2. Habilitar Realtime en Supabase

Ve a tu proyecto en Supabase Dashboard:

1. **Database** → **Replication**
2. Busca la tabla `players` y activa el switch de **Realtime**
3. Busca la tabla `life_events` y activa el switch de **Realtime**
4. Guarda los cambios

## 3. Verificar en la consola del navegador

Abre la consola de desarrollador (F12) en ambas ventanas (admin y usuario) y busca mensajes como:

- `Realtime subscription connected`
- Errores de conexión o suscripción

## 4. Prueba

1. En la ventana de admin: quita 1 vida a un jugador
2. En la ventana de usuario (panel público):
   - Deberías ver las vidas actualizarse automáticamente
   - Debería aparecer una notificación en la esquina superior derecha con el mensaje de muerte

## Troubleshooting

Si no funciona:

1. Recarga ambas páginas (F5)
2. Revisa la consola del navegador en busca de errores
3. Verifica que las tablas `players` y `life_events` tengan Realtime activo
4. Asegúrate de que el script de políticas se ejecutó correctamente
