const DEFAULT_ICON = "/hearts/full.svg";

export function canUseDesktopNotifications() {
  return typeof window !== "undefined" && "Notification" in window;
}

export function getDesktopNotificationPermission() {
  if (!canUseDesktopNotifications()) return "unsupported";
  return Notification.permission;
}

/**
 * Request permission. Must be called from a user gesture (click/tap).
 * @returns {Promise<boolean>} granted?
 */
export async function requestDesktopNotificationsPermission() {
  if (!canUseDesktopNotifications()) return false;

  if (Notification.permission === "granted") return true;
  if (Notification.permission === "denied") return false;

  try {
    const result = await Notification.requestPermission();
    console.log('[Notifications] Permission result:', result);
    return result === "granted";
  } catch (error) {
    console.error('[Notifications] Error requesting permission:', error);
    return false;
  }
}

/**
 * Check if we should auto-request permissions (only for default state)
 * @returns {boolean}
 */
export function shouldRequestNotificationPermission() {
  if (!canUseDesktopNotifications()) return false;
  return Notification.permission === "default";
}

/**
 * Shows an OS-level notification (Windows toast on Chrome/Edge) if permission is granted.
 * Note: Only works while the site is open; for notifications when closed you need Push.
 * @returns {Notification|null} The notification instance or null
 */
export function showDesktopNotification({
  title,
  body,
  tag,
  icon = DEFAULT_ICON,
  requireInteraction = false,
} = {}) {
  if (!canUseDesktopNotifications()) {
    console.warn('[Notifications] Browser does not support notifications');
    return null;
  }
  
  if (Notification.permission !== "granted") {
    console.warn('[Notifications] Permission not granted. Current permission:', Notification.permission);
    return null;
  }

  try {
    console.log('[Notifications] Creating desktop notification:', { title, body, tag });
    
    const n = new Notification(String(title || "Notificación"), {
      body: String(body || ""),
      icon,
      tag,
      renotify: Boolean(tag),
      silent: false,
      requireInteraction,
    });

    // Log when notification is shown
    n.onshow = () => {
      console.log('[Notifications] Notification shown successfully');
    };

    // Log if notification fails
    n.onerror = (error) => {
      console.error('[Notifications] Notification error:', error);
    };

    // Auto-close to avoid piling up
    const timeout = requireInteraction ? 12000 : 6000;
    setTimeout(
      () => {
        try {
          n.close();
          console.log('[Notifications] Notification auto-closed after', timeout, 'ms');
        } catch (err) {
          console.warn('[Notifications] Error closing notification:', err);
        }
      },
      timeout
    );

    return n;
  } catch (error) {
    console.error('[Notifications] Error creating notification:', error);
    return null;
  }
}

/**
 * Shows a notification from admin message
 * @param {Object} params Message parameters
 * @param {string} params.type Message type ('general' or 'specific')
 * @param {string} params.senderName Name of sender
 * @param {string} params.message Message content
 * @param {string} params.senderImage Optional sender image
 * @returns {Notification|null}
 */
export function showAdminMessageNotification({ type, senderName, message, senderImage }) {
  const notifTitle = type === 'general' 
    ? '📢 Notificación Global' 
    : '📩 Mensaje Personal';
  
  const notifBody = `${senderName}: ${message}`;
  
  return showDesktopNotification({
    title: notifTitle,
    body: notifBody,
    tag: `admin-message-${Date.now()}`,
    icon: senderImage || DEFAULT_ICON,
    requireInteraction: true, // Important messages should require user action
  });
}

