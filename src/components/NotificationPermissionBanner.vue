<template>
  <Transition name="permission-slide">
    <div v-if="shouldShow" class="notification-permission-banner">
      <div class="banner-content">
        <div class="banner-icon">
          <Bell :size="24" />
        </div>
        <div class="banner-text">
          <h3 class="banner-title">🔔 Activa las notificaciones</h3>
          <p class="banner-description">
            Recibe alertas del admin y mensajes importantes en tiempo real
          </p>
        </div>
        <div class="banner-actions">
          <button class="btn-enable" type="button" @click="requestPermission">
            Activar
          </button>
          <button class="btn-dismiss" type="button" @click="dismiss">
            <X :size="18" />
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { Bell, X } from "lucide-vue-next";
import {
  canUseDesktopNotifications,
  getDesktopNotificationPermission,
  requestDesktopNotificationsPermission,
} from "@/services/desktopNotifications";

const shouldShow = ref(false);
const DISMISS_KEY = "notification_permission_dismissed";

function checkIfShouldShow() {
  if (!canUseDesktopNotifications()) {
    console.log('[NotificationBanner] ❌ Browser no soporta notificaciones');
    shouldShow.value = false;
    return;
  }

  const permission = getDesktopNotificationPermission();
  const dismissed = localStorage.getItem(DISMISS_KEY);

  console.log('[NotificationBanner] 📊 Estado:', { permission, dismissed });

  // Mostrar solo si no tiene permisos y no lo ha descartado antes
  shouldShow.value = permission === "default" && !dismissed;
  
  if (shouldShow.value) {
    console.log('[NotificationBanner] ✅ Mostrando banner de solicitud de permisos');
  }
}

async function requestPermission() {
  console.log('[NotificationBanner] 🔔 Solicitando permisos de notificaciones...');
  const granted = await requestDesktopNotificationsPermission();
  
  if (granted) {
    console.log('[NotificationBanner] ✅ Permisos concedidos!');
    shouldShow.value = false;
    // Remover el flag de descartado si otorgan permisos
    localStorage.removeItem(DISMISS_KEY);
    
    // Show a test notification
    try {
      new Notification('✅ Notificaciones activadas', {
        body: 'Ahora recibirás mensajes del admin en tiempo real',
        icon: '/arcade.svg',
      });
    } catch (error) {
      console.error('[NotificationBanner] Error showing test notification:', error);
    }
  } else {
    console.warn('[NotificationBanner] ❌ Permisos denegados o cancelados');
    // Si rechazan, ocultar el banner
    shouldShow.value = false;
  }
}

function dismiss() {
  shouldShow.value = false;
  // Guardar que el usuario descartó el banner (durará hasta que limpie el localStorage)
  localStorage.setItem(DISMISS_KEY, "true");
}

onMounted(() => {
  checkIfShouldShow();
});
</script>

<style scoped>
.notification-permission-banner {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1500;
  max-width: 420px;
  width: calc(100vw - 48px);
}

.banner-content {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 16px;
  align-items: center;
  padding: 16px 20px;
  background: linear-gradient(
    135deg,
    rgba(0, 255, 194, 0.15) 0%,
    rgba(0, 0, 0, 0.95) 100%
  );
  border: 2px solid rgba(0, 255, 194, 0.6);
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6),
    inset 0 0 0 1px rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.banner-icon {
  width: 48px;
  height: 48px;
  display: grid;
  place-items: center;
  background: rgba(0, 255, 194, 0.2);
  border: 2px solid rgba(0, 255, 194, 0.5);
  border-radius: 12px;
  color: #00ffc2;
  animation: pulse-glow 2s ease-in-out infinite;
}

@keyframes pulse-glow {
  0%,
  100% {
    box-shadow: 0 0 10px rgba(0, 255, 194, 0.3);
  }
  50% {
    box-shadow: 0 0 20px rgba(0, 255, 194, 0.6);
  }
}

.banner-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.banner-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.5);
  margin: 0;
  line-height: 1.4;
}

.banner-description {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: rgba(255, 255, 255, 0.75);
  margin: 0;
  line-height: 1.5;
}

.banner-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-end;
}

.btn-enable {
  padding: 10px 16px;
  border: 2px solid rgba(0, 255, 194, 0.7);
  border-radius: 8px;
  background: rgba(0, 255, 194, 0.15);
  color: #00ffc2;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.btn-enable:hover {
  background: rgba(0, 255, 194, 0.25);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 255, 194, 0.3);
}

.btn-enable:active {
  transform: translateY(0);
}

.btn-dismiss {
  width: 32px;
  height: 32px;
  padding: 0;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.4);
  color: rgba(255, 255, 255, 0.6);
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: all 0.2s ease;
}

.btn-dismiss:hover {
  border-color: rgba(247, 65, 143, 0.6);
  color: #f7418f;
  background: rgba(247, 65, 143, 0.1);
}

.btn-dismiss:active {
  transform: scale(0.95);
}

/* Animaciones */
.permission-slide-enter-active,
.permission-slide-leave-active {
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

.permission-slide-enter-from {
  opacity: 0;
  transform: translateX(100%) translateY(20px);
}

.permission-slide-leave-to {
  opacity: 0;
  transform: translateX(100%) translateY(-20px);
}

/* Responsive */
@media (max-width: 640px) {
  .notification-permission-banner {
    bottom: 16px;
    right: 16px;
    width: calc(100vw - 32px);
  }

  .banner-content {
    grid-template-columns: auto 1fr;
    gap: 12px;
    padding: 14px 16px;
  }

  .banner-icon {
    width: 40px;
    height: 40px;
  }

  .banner-title {
    font-size: 0.6rem;
  }

  .banner-description {
    font-size: 0.45rem;
  }

  .banner-actions {
    grid-column: 1 / -1;
    flex-direction: row;
    justify-content: space-between;
    width: 100%;
  }

  .btn-enable {
    flex: 1;
  }
}
</style>
