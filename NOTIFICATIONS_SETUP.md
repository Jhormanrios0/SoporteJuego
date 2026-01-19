# Sistema de Notificaciones - Configuración

## Descripción
Este documento describe la configuración necesaria para el sistema de notificaciones globales que permite a los VIP/Admin enviar mensajes a los jugadores.

## Requisitos de Base de Datos

El sistema reutiliza la tabla `help_requests` existente para las notificaciones globales. Esta tabla ya está configurada y no requiere cambios adicionales.

### Estructura de la tabla `help_requests`

```sql
-- La tabla ya existe con la siguiente estructura
CREATE TABLE help_requests (
  id BIGSERIAL PRIMARY KEY,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_player_id BIGINT REFERENCES players(id) ON DELETE SET NULL,
  target_player_id BIGINT REFERENCES players(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('general', 'specific')),
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

### Campo `is_admin` en tabla `profiles`

Asegúrate de que la tabla `profiles` tenga el campo `is_admin` para identificar a los administradores:

```sql
-- Si no existe, agregar columna is_admin
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;

-- Marcar al usuario admin (reemplaza con el UUID correcto)
UPDATE profiles 
SET is_admin = true 
WHERE email = 'admin@tudominio.com';
```

## Row Level Security (RLS)

### Políticas para `help_requests`

Las políticas RLS ya deben estar configuradas. Verifica que existan:

```sql
-- Política de lectura: los usuarios pueden leer sus notificaciones
CREATE POLICY "Users can read their own notifications"
ON help_requests FOR SELECT
USING (
  target_player_id IN (
    SELECT id FROM players WHERE user_id = auth.uid()
  )
  OR type = 'general'
  OR sender_id = auth.uid()
);

-- Política de inserción: cualquier usuario autenticado puede crear notificaciones
CREATE POLICY "Authenticated users can send help requests"
ON help_requests FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL AND sender_id = auth.uid());

-- Política de actualización: los usuarios pueden actualizar sus notificaciones
CREATE POLICY "Users can update their notifications"
ON help_requests FOR UPDATE
USING (
  target_player_id IN (
    SELECT id FROM players WHERE user_id = auth.uid()
  )
  OR type = 'general'
);

-- Política de eliminación: los usuarios pueden eliminar sus notificaciones recibidas
CREATE POLICY "Users can delete their notifications"
ON help_requests FOR DELETE
USING (
  target_player_id IN (
    SELECT id FROM players WHERE user_id = auth.uid()
  )
  OR type = 'general'
);
```

## Funcionalidades del Sistema

### Para VIP/Admin
- **Enviar notificaciones globales**: Mensajes visibles para todos los jugadores
- **Enviar notificaciones específicas**: Mensajes dirigidos a un jugador en particular
- **Ver historial de notificaciones enviadas**: Lista de todos los mensajes enviados
- **Seleccionar destinatarios**: Dropdown con todos los jugadores disponibles

### Para Jugadores/Users
- **Ver notificaciones recibidas**: Lista de mensajes globales y personales
- **Marcar como leídas**: Cambiar el estado de las notificaciones
- **Eliminar notificaciones**: Borrar mensajes individualmente
- **Indicadores visuales**: Badges que distinguen mensajes globales vs personales
- **Notificaciones del navegador**: Alertas nativas del sistema operativo
- **Sonido de notificación**: Audio cuando llega una nueva notificación

## Notificaciones del Navegador

El sistema integra las notificaciones nativas del navegador (Web Notifications API) para alertar a los jugadores incluso cuando la pestaña está en segundo plano.

### Características:
- ✅ **Banner de permisos**: Se muestra automáticamente para solicitar permisos
- ✅ **Notificaciones toast**: Alertas nativas del sistema operativo (Windows, macOS, Linux)
- ✅ **Sonido integrado**: Audio de notificación cuando llega un mensaje
- ✅ **Íconos personalizados**: Muestra la imagen del remitente
- ✅ **Títulos descriptivos**: "📢 Notificación Global" o "📩 Mensaje Personal"
- ✅ **Auto-cierre**: Se cierran automáticamente después de unos segundos
- ✅ **Persistencia de preferencias**: Recuerda si el usuario descartó el banner

### Componente `NotificationPermissionBanner.vue`
Banner flotante que solicita permisos de notificaciones:
- Se muestra en la esquina inferior derecha
- Solo aparece si los permisos no han sido otorgados/rechazados
- Se puede descartar haciendo clic en "X"
- Botón "Activar" solicita permisos al navegador
- Guarda preferencia en localStorage

### Flujo de Notificaciones:
1. Usuario recibe una nueva notificación (mensaje global o personal)
2. Se reproduce un sonido de alerta (enderman teleport)
3. Si tiene permisos, se muestra notificación nativa del navegador
4. La notificación aparece en el panel lateral
5. Se marca con badge "Global" o "Personal"

## Componentes Creados

### 1. `NotificationPanel.vue`
Componente principal del menú aside con dos vistas:
- **Vista Admin**: Formulario para enviar notificaciones + historial de enviadas
- **Vista User**: Lista de notificaciones recibidas con acciones

### 2. `NotificationPermissionBanner.vue`
Banner para solicitar permisos de notificaciones del navegador:
- Aparece automáticamente si no hay permisos
- Diseño retro/arcade coherente con la app
- Animaciones suaves de entrada/salida
- Responsive para móviles

### 3. Funciones en `supabase.js`
- `sendGlobalNotification(payload)`: Enviar notificación (solo admin)
- `getAdminSentNotifications(opts)`: Obtener notificaciones enviadas
- `isCurrentUserAdmin()`: Verificar si el usuario es admin

### 4. Servicio `desktopNotifications.js`
Ya existente, utilizado para:
- `showDesktopNotification()`: Mostrar notificación nativa
- `requestDesktopNotificationsPermission()`: Solicitar permisos
- `getDesktopNotificationPermission()`: Verificar estado de permisos

## Integración en las Vistas

### ProfileView.vue (Jugadores)
```vue
<NotificationPanel
  :isOpen="isNotificationPanelOpen"
  :isVipOrAdmin="false"
  :notifications="helpNotifications"
  :allPlayers="allPlayers"
  :loading="false"
  @close="closeNotificationPanel"
  @mark-read="handleMarkNotificationRead"
  @delete-notification="handleDeleteNotification"
/>
```

### VipProfileView.vue (Admin)
```vue
<NotificationPanel
  :isOpen="isNotificationPanelOpen"
  :isVipOrAdmin="true"
  :notifications="sentNotifications"
  :allPlayers="allPlayers"
  :loading="notificationsLoading"
  @close="closeNotificationPanel"
  @send-notification="handleSendNotification"
/>
```

## Cómo Usar

### Como Admin/VIP:
1. Haz clic en el botón "📢 NOTIFICACIONES" en tu perfil
2. Escribe tu mensaje en el área de texto
3. Selecciona destinatarios:
   - **Todos los jugadores**: Mensaje global visible para todos
   - **Jugador específico**: Selecciona un jugador del dropdown
4. Haz clic en "ENVIAR NOTIFICACIÓN"
5. Puedes ver el historial de notificaciones enviadas en la parte inferior

### Como Jugador:
1. **Activar notificaciones** (primera vez):
   - Aparecerá un banner en la esquina inferior derecha
   - Haz clic en "Activar" para permitir notificaciones del navegador
   - El navegador pedirá confirmación - selecciona "Permitir"
   
2. **Acceder al panel**:
   - Haz clic en el ícono de manzana en el HUD (Slot 3)
   - O haz clic en la campanita de notificaciones (si hay nuevas)

3. **Ver y gestionar notificaciones**:
   - Verás todas tus notificaciones (globales y personales)
   - Las notificaciones no leídas tienen un brillo especial
   - Los badges indican si el mensaje es "Global" o "Personal"
   
4. **Acciones disponibles**:
   - **Marcar como leída**: Click en el botón "Marcar leída"
   - **Eliminar**: Click en el botón de la papelera
   - **Ver detalles**: Lee el mensaje completo con timestamp

5. **Notificaciones del navegador**:
   - Cuando llegue un nuevo mensaje, verás una notificación toast
   - Se reproduce un sonido de alerta
   - Puedes hacer clic en la notificación para abrir la aplicación

## Permisos y Seguridad

- Solo usuarios con `is_admin = true` pueden enviar notificaciones
- Las notificaciones se validan en el servidor usando RLS
- Los jugadores solo pueden ver sus propias notificaciones o las globales
- Los jugadores no pueden eliminar notificaciones de otros

## Estilo y Diseño

El panel de notificaciones mantiene el estilo retro/arcade del resto de la aplicación:
- Colores neón (#00ffc2, #f7418f, #ffda79)
- Fuente Press Start 2P
- Animaciones suaves de slide
- Efectos de brillo y sombras
- Diseño responsivo

## Notas Adicionales

- El sistema reutiliza la infraestructura de `help_requests` existente
- No requiere crear nuevas tablas en la base de datos
- Las notificaciones se actualizan en tiempo real con Supabase Realtime
- El panel se puede cerrar haciendo clic fuera de él o en el botón X
- Las notificaciones del navegador funcionan en Chrome, Edge, Firefox y Safari (con limitaciones)
- Los permisos de notificaciones se solicitan por dominio y se guardan en el navegador
- El sonido de notificación utiliza el mismo audio del enderman (enderman_teleport.mp3)
- Las preferencias del banner se guardan en localStorage

## Archivos Modificados/Creados

### Nuevos Archivos:
- `src/components/NotificationPanel.vue` - Panel lateral de notificaciones
- `src/components/NotificationPermissionBanner.vue` - Banner para solicitar permisos
- `NOTIFICATIONS_SETUP.md` - Esta documentación

### Archivos Modificados:
- `src/services/supabase.js` - Agregadas funciones de notificaciones globales
- `src/views/ProfileView.vue` - Integrado panel y banner de permisos
- `src/views/VipProfileView.vue` - Integrado panel para admin
- `src/components/HUD.vue` - Agregado slot 3 para notificaciones

## Troubleshooting

### Las notificaciones del navegador no aparecen:
1. Verifica que los permisos estén otorgados (ícono del candado en la barra de direcciones)
2. Comprueba que el navegador soporte Web Notifications API
3. Revisa la consola del navegador por errores
4. Algunos navegadores bloquean notificaciones en sitios HTTP (solo HTTPS)

### El banner de permisos no aparece:
1. Los permisos ya fueron otorgados o rechazados anteriormente
2. El usuario descartó el banner (localStorage tiene el flag)
3. El navegador no soporta notificaciones

### No se reproduce el sonido:
1. El volumen del navegador está silenciado
2. El navegador bloquea reproducción automática de audio
3. Interactúa con la página primero (política de autoplay)

### Limpiar preferencias:
```javascript
// En consola del navegador:
localStorage.removeItem('notification_permission_dismissed');
```
