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

  const result = await Notification.requestPermission();
  return result === "granted";
}

/**
 * Shows an OS-level notification (Windows toast on Chrome/Edge) if permission is granted.
 * Note: Only works while the site is open; for notifications when closed you need Push.
 */
export function showDesktopNotification({
  title,
  body,
  tag,
  icon = DEFAULT_ICON,
  requireInteraction = false,
} = {}) {
  if (!canUseDesktopNotifications()) return null;
  if (Notification.permission !== "granted") return null;

  try {
    const n = new Notification(String(title || "Notificación"), {
      body: String(body || ""),
      icon,
      tag,
      renotify: Boolean(tag),
      silent: false,
      requireInteraction,
    });

    // auto-close to avoid piling up
    setTimeout(
      () => {
        try {
          n.close();
        } catch {
          // noop
        }
      },
      requireInteraction ? 12000 : 6000
    );

    return n;
  } catch {
    return null;
  }
}
