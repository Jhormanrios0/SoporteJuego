<template>
  <div class="notification-bell-wrapper">
    <button
      class="notification-bell-btn"
      :class="{ 'has-notifications': unreadCount > 0 }"
      @click="toggleNotifications"
      :aria-label="`Notificaciones${
        unreadCount > 0 ? ` (${unreadCount} nuevas)` : ''
      }`"
    >
      <img
        src="/icons/abcde.gif"
        alt="Notificaciones"
        class="bell-icon"
        :class="{ ringing: unreadCount > 0 }"
      />
      <Transition name="badge-pop">
        <span v-if="unreadCount > 0" class="notification-badge">
          {{ unreadCount > 99 ? "99+" : unreadCount }}
        </span>
      </Transition>
    </button>

    <!-- Panel de notificaciones -->
    <Transition name="panel-slide">
      <div v-if="isOpen" class="notification-panel" @click.stop>
        <div class="panel-header">
          <h3 class="panel-title">
            <Bell :size="18" />
            Notificaciones
          </h3>
          <button
            v-if="notifications.length > 0"
            class="mark-all-read"
            @click="markAllAsRead"
          >
            Marcar todo leído
          </button>
        </div>

        <div class="panel-content">
          <div v-if="notifications.length === 0" class="empty-notifications">
            <BellOff :size="32" />
            <p>Sin notificaciones</p>
            <span>Las menciones y solicitudes de ayuda aparecerán aquí</span>
          </div>

          <TransitionGroup
            v-else
            name="notification-list"
            tag="div"
            class="notifications-list"
          >
            <div
              v-for="notification in sortedNotifications"
              :key="notification.id"
              class="notification-item"
              :class="{ unread: !notification.read, [notification.type]: true }"
              @click="handleNotificationClick(notification)"
            >
              <div class="notification-icon">
                <AtSign v-if="notification.type === 'mention'" :size="18" />
                <HelpCircle
                  v-else-if="notification.type === 'help'"
                  :size="18"
                />
                <MessageCircle v-else :size="18" />
              </div>

              <div class="notification-content">
                <div class="notification-header">
                  <span class="notification-sender">
                    {{ notification.senderName }}
                  </span>
                  <span class="notification-time">
                    {{ formatTime(notification.createdAt) }}
                  </span>
                </div>
                <p class="notification-message">
                  {{ notification.message }}
                </p>
                <span class="notification-type-label">
                  {{ getTypeLabel(notification.type) }}
                </span>
              </div>

              <button
                class="notification-dismiss"
                @click.stop="dismissNotification(notification.id)"
                aria-label="Descartar"
              >
                <X :size="14" />
              </button>
            </div>
          </TransitionGroup>
        </div>

        <div v-if="notifications.length > 0" class="panel-footer">
          <button class="clear-all-btn" @click="clearAllNotifications">
            <Trash2 :size="14" />
            Limpiar todo
          </button>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from "vue";
import {
  Bell,
  BellOff,
  AtSign,
  HelpCircle,
  MessageCircle,
  X,
  Trash2,
} from "lucide-vue-next";

const props = defineProps({
  notifications: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits([
  "toggle",
  "mark-read",
  "mark-all-read",
  "dismiss",
  "clear-all",
  "notification-click",
]);

const isOpen = ref(false);

const unreadCount = computed(() => {
  return props.notifications.filter((n) => !n.read).length;
});

const sortedNotifications = computed(() => {
  return [...props.notifications].sort((a, b) => {
    // Primero no leídas, luego por fecha
    if (a.read !== b.read) return a.read ? 1 : -1;
    return new Date(b.createdAt) - new Date(a.createdAt);
  });
});

function toggleNotifications() {
  isOpen.value = !isOpen.value;
  emit("toggle", isOpen.value);
}

function closePanel() {
  isOpen.value = false;
}

function markAllAsRead() {
  emit("mark-all-read");
}

function dismissNotification(id) {
  emit("dismiss", id);
}

function clearAllNotifications() {
  emit("clear-all");
  closePanel();
}

function handleNotificationClick(notification) {
  if (!notification.read) {
    emit("mark-read", notification.id);
  }
  emit("notification-click", notification);
}

function formatTime(dateStr) {
  if (!dateStr) return "";
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return "Ahora";
  if (diffMins < 60) return `${diffMins}m`;
  if (diffHours < 24) return `${diffHours}h`;
  if (diffDays < 7) return `${diffDays}d`;

  return date.toLocaleDateString("es-ES", {
    day: "2-digit",
    month: "short",
  });
}

function getTypeLabel(type) {
  const labels = {
    mention: "Mención directa",
    help: "Solicitud de ayuda",
    general: "Mensaje general",
  };
  return labels[type] || "Notificación";
}

// Cerrar al hacer clic fuera
function handleClickOutside(e) {
  if (isOpen.value) {
    const wrapper = e.target.closest(".notification-bell-wrapper");
    if (!wrapper) {
      closePanel();
    }
  }
}

onMounted(() => {
  document.addEventListener("click", handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener("click", handleClickOutside);
});
</script>

<style scoped>
.notification-bell-wrapper {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 9000;
}

.notification-bell-btn {
  position: relative;
  width: 60px;
  height: 60px;
  background: linear-gradient(180deg, #8b5a2b 0%, #5c3d1e 50%, #3d2610 100%);
  border: 4px solid #2d1f0f;
  border-radius: 0;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s;
  box-shadow: inset 2px 2px 0 #a67c52, inset -2px -2px 0 #3d2610,
    4px 4px 0 #1a1208, 0 8px 20px rgba(0, 0, 0, 0.6);
  image-rendering: pixelated;
}

.notification-bell-btn::before {
  content: "";
  position: absolute;
  inset: 4px;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.1) 0%,
    transparent 50%
  );
  pointer-events: none;
}

.notification-bell-btn:hover {
  transform: translateY(-3px);
  box-shadow: inset 2px 2px 0 #a67c52, inset -2px -2px 0 #3d2610,
    4px 7px 0 #1a1208, 0 12px 30px rgba(0, 0, 0, 0.7);
}

.notification-bell-btn:active {
  transform: translateY(0);
  box-shadow: inset -2px -2px 0 #a67c52, inset 2px 2px 0 #3d2610,
    2px 2px 0 #1a1208;
}

.notification-bell-btn.has-notifications {
  background: linear-gradient(180deg, #ffaa00 0%, #ff8800 50%, #cc5500 100%);
  border-color: #552200;
  animation: minecraftGlow 1.5s ease-in-out infinite;
}

@keyframes minecraftGlow {
  0%,
  100% {
    box-shadow: inset 2px 2px 0 #ffcc55, inset -2px -2px 0 #aa5500,
      4px 4px 0 #1a1208, 0 0 20px rgba(255, 170, 0, 0.5);
  }
  50% {
    box-shadow: inset 2px 2px 0 #ffcc55, inset -2px -2px 0 #aa5500,
      4px 4px 0 #1a1208, 0 0 40px rgba(255, 170, 0, 0.8),
      0 0 60px rgba(255, 136, 0, 0.4);
  }
}

.bell-icon {
  width: 40px;
  height: 40px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(2px 2px 0 rgba(0, 0, 0, 0.8));
}

.bell-icon.ringing {
  animation: pixelBellRing 0.4s ease-in-out infinite;
}

@keyframes pixelBellRing {
  0%,
  100% {
    transform: rotate(0deg) scale(1);
  }
  25% {
    transform: rotate(15deg) scale(1.05);
  }
  75% {
    transform: rotate(-15deg) scale(1.05);
  }
}

.notification-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  min-width: 26px;
  height: 26px;
  padding: 0 6px;
  background: linear-gradient(180deg, #ff5555 0%, #aa0000 100%);
  border: 3px solid #550000;
  border-radius: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: inset 1px 1px 0 #ff8888, inset -1px -1px 0 #880000,
    2px 2px 0 #1a1208;
  text-shadow: 1px 1px 0 #550000;
}

/* Panel de notificaciones - FIXED para no desplazar */
.notification-panel {
  position: fixed;
  bottom: 90px;
  right: 20px;
  width: min(400px, calc(100vw - 40px));
  max-height: min(500px, 60vh);
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border: 4px solid #8b5a2b;
  border-radius: 0;
  box-shadow: inset 0 0 0 2px #5c3d1e, inset 0 0 0 4px #3d2610,
    6px 6px 0 #1a1208, 0 10px 40px rgba(0, 0, 0, 0.8);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  z-index: 9999;
  image-rendering: pixelated;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  background: linear-gradient(180deg, #3d2610 0%, #2d1f0f 100%);
  border-bottom: 4px solid #5c3d1e;
}

.panel-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  color: #ffaa00;
  margin: 0;
  text-shadow: 2px 2px 0 #000;
}

.mark-all-read {
  font-family: "Press Start 2P", monospace;
  font-size: 0.45rem;
  padding: 8px 12px;
  background: linear-gradient(180deg, #55aa55 0%, #337733 100%);
  border: 3px solid #225522;
  border-radius: 0;
  color: #fff;
  cursor: pointer;
  transition: all 0.1s;
  text-shadow: 1px 1px 0 #113311;
  box-shadow: inset 1px 1px 0 #77cc77, inset -1px -1px 0 #225522;
}

.mark-all-read:hover {
  background: linear-gradient(180deg, #66bb66 0%, #448844 100%);
  transform: translateY(-1px);
}

.panel-content {
  flex: 1;
  overflow-y: auto;
  padding: 8px;
  background: #1a1208;
}

.panel-content::-webkit-scrollbar {
  width: 14px;
}

.panel-content::-webkit-scrollbar-track {
  background: #2d1f0f;
  border-left: 3px solid #5c3d1e;
}

.panel-content::-webkit-scrollbar-thumb {
  background: linear-gradient(180deg, #8b5a2b 0%, #5c3d1e 100%);
  border: 2px solid #3d2610;
}

.empty-notifications {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 50px 20px;
  text-align: center;
  color: #8b7355;
}

.empty-notifications svg {
  margin-bottom: 16px;
  opacity: 0.6;
  filter: drop-shadow(2px 2px 0 #000);
}

.empty-notifications p {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  margin: 0 0 10px;
  color: #a67c52;
  text-shadow: 2px 2px 0 #000;
}

.empty-notifications span {
  font-family: "Press Start 2P", monospace;
  font-size: 0.45rem;
  color: #5c3d1e;
  text-shadow: 1px 1px 0 #000;
}

.notifications-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.notification-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 12px;
  background: linear-gradient(180deg, #3d2610 0%, #2d1f0f 100%);
  border: 3px solid #5c3d1e;
  border-radius: 0;
  cursor: pointer;
  transition: all 0.1s;
}

.notification-item:hover {
  background: linear-gradient(180deg, #4d3620 0%, #3d2610 100%);
  border-color: #8b5a2b;
  transform: translateX(2px);
}

.notification-item.unread {
  background: linear-gradient(180deg, #4a3a15 0%, #3a2a10 100%);
  border-color: #ffaa00;
}

.notification-item.unread::before {
  content: "";
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 6px;
  background: linear-gradient(180deg, #ffcc00 0%, #ff8800 100%);
}

.notification-icon {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border: 2px solid #5c3d1e;
  border-radius: 0;
  flex-shrink: 0;
}

.notification-item.mention .notification-icon {
  background: linear-gradient(180deg, #115511 0%, #003300 100%);
  border-color: #228822;
  color: #55ff55;
}

.notification-item.specific .notification-icon {
  background: linear-gradient(180deg, #115511 0%, #003300 100%);
  border-color: #228822;
  color: #55ff55;
}

.notification-item.help .notification-icon {
  background: linear-gradient(180deg, #553300 0%, #331100 100%);
  border-color: #885500;
  color: #ffaa00;
}

.notification-item.general .notification-icon {
  background: linear-gradient(180deg, #330055 0%, #220033 100%);
  border-color: #550088;
  color: #aa55ff;
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 6px;
}

.notification-sender {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: #fff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-shadow: 2px 2px 0 #000;
}

.notification-time {
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  color: #8b7355;
  flex-shrink: 0;
  text-shadow: 1px 1px 0 #000;
}

.notification-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #a67c52;
  margin: 0 0 8px;
  line-height: 1.6;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-shadow: 1px 1px 0 #000;
}

.notification-type-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  padding: 4px 8px;
  border-radius: 0;
  background: #2d1f0f;
  border: 2px solid #5c3d1e;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
}

.notification-item.mention .notification-type-label,
.notification-item.specific .notification-type-label {
  background: #003300;
  border-color: #115511;
  color: #55ff55;
}

.notification-item.help .notification-type-label {
  background: #331100;
  border-color: #553300;
  color: #ffaa00;
}

.notification-dismiss {
  padding: 6px;
  background: linear-gradient(180deg, #553333 0%, #331111 100%);
  border: 2px solid #882222;
  border-radius: 0;
  color: #ff5555;
  cursor: pointer;
  transition: all 0.1s;
}

.notification-dismiss:hover {
  background: linear-gradient(180deg, #884444 0%, #552222 100%);
  transform: scale(1.1);
}

.panel-footer {
  padding: 12px 16px;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border-top: 4px solid #5c3d1e;
}

.clear-all-btn {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  background: linear-gradient(180deg, #aa3333 0%, #772222 100%);
  border: 3px solid #551111;
  border-radius: 0;
  color: #fff;
  cursor: pointer;
  transition: all 0.1s;
  text-shadow: 1px 1px 0 #330000;
  box-shadow: inset 1px 1px 0 #cc5555, inset -1px -1px 0 #551111;
}

.clear-all-btn:hover {
  background: linear-gradient(180deg, #cc4444 0%, #883333 100%);
  transform: translateY(-1px);
}

/* Transitions */
.badge-pop-enter-active {
  animation: badgePop 0.3s ease-out;
}

.badge-pop-leave-active {
  animation: badgePop 0.2s ease-in reverse;
}

@keyframes badgePop {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  50% {
    transform: scale(1.2);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.panel-slide-enter-active,
.panel-slide-leave-active {
  transition: all 0.3s ease;
}

.panel-slide-enter-from,
.panel-slide-leave-to {
  opacity: 0;
  transform: translateY(-10px) scale(0.95);
}

.notification-list-enter-active,
.notification-list-leave-active {
  transition: all 0.3s ease;
}

.notification-list-enter-from,
.notification-list-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

.notification-list-move {
  transition: transform 0.3s ease;
}

@media (max-width: 520px) {
  .notification-bell-wrapper {
    bottom: 15px;
    right: 15px;
  }

  .notification-bell-btn {
    width: 52px;
    height: 52px;
  }

  .bell-icon {
    width: 32px;
    height: 32px;
  }

  .notification-panel {
    bottom: 75px;
    right: 10px;
    left: 10px;
    width: auto;
    max-height: 55vh;
  }

  .notification-badge {
    min-width: 22px;
    height: 22px;
    font-size: 0.4rem;
    top: -6px;
    right: -6px;
  }
}
</style>
