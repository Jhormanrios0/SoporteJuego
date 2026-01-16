<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="isOpen"
        class="notification-history-overlay"
        @click.self="close"
      >
        <div class="notification-history-modal">
          <!-- Header del libro -->
          <div class="book-header">
            <div class="book-title-decoration">⚔️</div>
            <h2 class="book-title">Historial de Ayuda</h2>
            <div class="book-title-decoration">⚔️</div>
          </div>

          <button class="close-btn" @click="close" aria-label="Cerrar">
            <X :size="20" />
          </button>

          <!-- Contenido del libro -->
          <div class="book-content">
            <div v-if="loading" class="loading-state">
              <div class="loading-icon">⏳</div>
              <p>Cargando historial...</p>
            </div>

            <div v-else-if="notifications.length === 0" class="empty-state">
              <div class="empty-icon">📜</div>
              <p class="empty-title">Sin registros</p>
              <p class="empty-text">
                Las solicitudes de ayuda y menciones aparecerán aquí
              </p>
            </div>

            <div v-else class="notifications-scroll">
              <TransitionGroup name="list" tag="div" class="notifications-list">
                <div
                  v-for="notification in sortedNotifications"
                  :key="notification.id"
                  class="history-item"
                  :class="{
                    unread: !notification.read,
                    [notification.type]: true,
                  }"
                >
                  <div class="item-icon">
                    <AtSign
                      v-if="notification.type === 'specific'"
                      :size="18"
                    />
                    <Users
                      v-else-if="notification.type === 'general'"
                      :size="18"
                    />
                    <HelpCircle v-else :size="18" />
                  </div>

                  <div class="item-content">
                    <div class="item-header">
                      <span class="item-sender">{{
                        notification.senderName
                      }}</span>
                      <span class="item-type">{{
                        getTypeLabel(notification.type)
                      }}</span>
                    </div>

                    <!-- Status del jugador que envió -->
                    <div
                      v-if="notification.senderStatus"
                      class="item-status"
                      :style="{
                        '--status-color':
                          notification.senderStatus.color || '#8b7355',
                        borderColor:
                          notification.senderStatus.color || '#8b7355',
                      }"
                    >
                      {{ notification.senderStatus.status || "Sin estado" }}
                    </div>

                    <p class="item-message">{{ notification.message }}</p>
                    <span class="item-time">{{
                      formatDate(notification.createdAt)
                    }}</span>
                  </div>

                  <div class="item-actions">
                    <button
                      v-if="!notification.read"
                      class="action-btn mark-read"
                      @click="markRead(notification.id)"
                      title="Marcar como leída"
                    >
                      <Check :size="14" />
                    </button>
                    <button
                      class="action-btn delete"
                      @click="deleteNotif(notification.id)"
                      title="Eliminar"
                    >
                      <Trash2 :size="14" />
                    </button>
                  </div>
                </div>
              </TransitionGroup>
            </div>
          </div>

          <!-- Footer -->
          <div class="book-footer">
            <div class="footer-stats">
              <span class="stat">
                <span class="stat-value">{{ notifications.length }}</span>
                <span class="stat-label">Total</span>
              </span>
              <span class="stat">
                <span class="stat-value">{{ unreadCount }}</span>
                <span class="stat-label">Sin leer</span>
              </span>
            </div>
            <div class="footer-actions">
              <button
                v-if="unreadCount > 0"
                class="footer-btn secondary"
                @click="markAllRead"
              >
                <CheckCheck :size="14" />
                Marcar todo leído
              </button>
              <button
                v-if="notifications.length > 0"
                class="footer-btn danger"
                @click="clearAll"
              >
                <Trash2 :size="14" />
                Limpiar todo
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { computed } from "vue";
import {
  X,
  AtSign,
  Users,
  HelpCircle,
  Check,
  CheckCheck,
  Trash2,
} from "lucide-vue-next";

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  notifications: {
    type: Array,
    default: () => [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  "close",
  "mark-read",
  "mark-all-read",
  "delete",
  "clear-all",
]);

const unreadCount = computed(() => {
  return props.notifications.filter((n) => !n.read).length;
});

const sortedNotifications = computed(() => {
  return [...props.notifications].sort((a, b) => {
    // Primero no leídas, luego por fecha más reciente
    if (a.read !== b.read) return a.read ? 1 : -1;
    return new Date(b.createdAt) - new Date(a.createdAt);
  });
});

function close() {
  emit("close");
}

function markRead(id) {
  emit("mark-read", id);
}

function markAllRead() {
  emit("mark-all-read");
}

function deleteNotif(id) {
  emit("delete", id);
}

function clearAll() {
  if (confirm("¿Eliminar todas las notificaciones?")) {
    emit("clear-all");
  }
}

function getTypeLabel(type) {
  const labels = {
    specific: "Mención directa",
    general: "Mensaje general",
    help: "Solicitud de ayuda",
  };
  return labels[type] || "Notificación";
}

function formatDate(dateStr) {
  if (!dateStr) return "";
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return "Hace un momento";
  if (diffMins < 60) return `Hace ${diffMins} minuto${diffMins > 1 ? "s" : ""}`;
  if (diffHours < 24)
    return `Hace ${diffHours} hora${diffHours > 1 ? "s" : ""}`;
  if (diffDays < 7) return `Hace ${diffDays} día${diffDays > 1 ? "s" : ""}`;

  return date.toLocaleDateString("es-ES", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
</script>

<style scoped>
.notification-history-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 99999;
  padding: 20px;
}

.notification-history-modal {
  position: relative;
  width: 100%;
  max-width: 600px;
  max-height: 85vh;
  background: linear-gradient(180deg, #8b5a2b 0%, #5c3d1e 50%, #3d2610 100%);
  border: 6px solid #2d1f0f;
  border-radius: 0;
  display: flex;
  flex-direction: column;
  box-shadow: inset 4px 4px 0 #a67c52, inset -4px -4px 0 #3d2610,
    8px 8px 0 #1a1208, 0 20px 60px rgba(0, 0, 0, 0.8);
  image-rendering: pixelated;
}

.book-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 20px;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border-bottom: 4px solid #5c3d1e;
}

.book-title-decoration {
  font-size: 1.2rem;
  filter: drop-shadow(2px 2px 0 #000);
}

.book-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  color: #ffcc00;
  text-shadow: 2px 2px 0 #000, 0 0 10px rgba(255, 204, 0, 0.5);
  margin: 0;
  text-align: center;
}

.close-btn {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(180deg, #aa3333 0%, #772222 100%);
  border: 3px solid #551111;
  border-radius: 0;
  color: #fff;
  cursor: pointer;
  transition: all 0.1s;
  box-shadow: inset 1px 1px 0 #cc5555, inset -1px -1px 0 #551111;
  z-index: 10;
}

.close-btn:hover {
  background: linear-gradient(180deg, #cc4444 0%, #993333 100%);
  transform: scale(1.05);
}

.book-content {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.loading-state,
.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  text-align: center;
}

.loading-icon,
.empty-icon {
  font-size: 3rem;
  margin-bottom: 16px;
  filter: drop-shadow(2px 2px 0 #000);
}

.loading-state p,
.empty-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  color: #a67c52;
  text-shadow: 1px 1px 0 #000;
  margin: 0;
}

.empty-text {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
  margin: 12px 0 0;
  line-height: 1.8;
}

.notifications-scroll {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
}

.notifications-scroll::-webkit-scrollbar {
  width: 12px;
}

.notifications-scroll::-webkit-scrollbar-track {
  background: #2d1f0f;
  border: 2px solid #5c3d1e;
}

.notifications-scroll::-webkit-scrollbar-thumb {
  background: linear-gradient(180deg, #8b5a2b 0%, #5c3d1e 100%);
  border: 2px solid #3d2610;
}

.notifications-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.history-item {
  position: relative;
  display: flex;
  gap: 12px;
  padding: 14px;
  background: linear-gradient(180deg, #3d2610 0%, #2d1f0f 100%);
  border: 3px solid #5c3d1e;
  border-radius: 0;
  transition: all 0.15s;
}

.history-item:hover {
  background: linear-gradient(180deg, #4d3620 0%, #3d2610 100%);
  border-color: #8b5a2b;
}

.history-item.unread {
  background: linear-gradient(180deg, #4a3a15 0%, #3a2a10 100%);
  border-color: #ffaa00;
}

.history-item.unread::before {
  content: "";
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 6px;
  background: linear-gradient(180deg, #ffcc00 0%, #ff8800 100%);
}

.item-icon {
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border: 2px solid #5c3d1e;
  border-radius: 0;
  flex-shrink: 0;
  color: #8b7355;
}

.history-item.specific .item-icon {
  background: linear-gradient(180deg, #115511 0%, #003300 100%);
  border-color: #228822;
  color: #55ff55;
}

.history-item.general .item-icon {
  background: linear-gradient(180deg, #330055 0%, #220033 100%);
  border-color: #550088;
  color: #aa55ff;
}

.item-content {
  flex: 1;
  min-width: 0;
}

.item-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}

.item-sender {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: #fff;
  text-shadow: 2px 2px 0 #000;
}

.item-type {
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  padding: 4px 8px;
  background: #2d1f0f;
  border: 2px solid #5c3d1e;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
}

.history-item.specific .item-type {
  background: #003300;
  border-color: #115511;
  color: #55ff55;
}

.history-item.general .item-type {
  background: #220033;
  border-color: #440066;
  color: #aa55ff;
}

.item-status {
  display: inline-block;
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  padding: 3px 8px;
  margin-bottom: 8px;
  background: linear-gradient(
    180deg,
    rgba(0, 0, 0, 0.4) 0%,
    rgba(0, 0, 0, 0.6) 100%
  );
  border: 2px solid var(--status-color, #8b7355);
  border-radius: 0;
  color: var(--status-color, #8b7355);
  text-shadow: 1px 1px 0 #000;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}

.item-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #a67c52;
  margin: 0 0 10px;
  line-height: 1.8;
  text-shadow: 1px 1px 0 #000;
  word-break: break-word;
}

.item-time {
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
}

.item-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex-shrink: 0;
}

.action-btn {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0;
  cursor: pointer;
  transition: all 0.1s;
}

.action-btn.mark-read {
  background: linear-gradient(180deg, #335533 0%, #113311 100%);
  border: 2px solid #228822;
  color: #55ff55;
}

.action-btn.mark-read:hover {
  background: linear-gradient(180deg, #448844 0%, #225522 100%);
  transform: scale(1.1);
}

.action-btn.delete {
  background: linear-gradient(180deg, #553333 0%, #331111 100%);
  border: 2px solid #882222;
  color: #ff5555;
}

.action-btn.delete:hover {
  background: linear-gradient(180deg, #884444 0%, #552222 100%);
  transform: scale(1.1);
}

.book-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 20px;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border-top: 4px solid #5c3d1e;
  flex-wrap: wrap;
}

.footer-stats {
  display: flex;
  gap: 20px;
}

.stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-value {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #ffcc00;
  text-shadow: 2px 2px 0 #000;
}

.stat-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
}

.footer-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.footer-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.45rem;
  border-radius: 0;
  cursor: pointer;
  transition: all 0.1s;
  text-shadow: 1px 1px 0 #000;
}

.footer-btn.secondary {
  background: linear-gradient(180deg, #335533 0%, #224422 100%);
  border: 3px solid #113311;
  color: #55ff55;
  box-shadow: inset 1px 1px 0 #558855, inset -1px -1px 0 #113311;
}

.footer-btn.secondary:hover {
  background: linear-gradient(180deg, #448844 0%, #336633 100%);
}

.footer-btn.danger {
  background: linear-gradient(180deg, #aa3333 0%, #772222 100%);
  border: 3px solid #551111;
  color: #fff;
  box-shadow: inset 1px 1px 0 #cc5555, inset -1px -1px 0 #551111;
}

.footer-btn.danger:hover {
  background: linear-gradient(180deg, #cc4444 0%, #883333 100%);
}

/* Transitions */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: all 0.25s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-fade-enter-from .notification-history-modal,
.modal-fade-leave-to .notification-history-modal {
  transform: scale(0.9) translateY(20px);
}

.list-enter-active,
.list-leave-active {
  transition: all 0.2s ease;
}

.list-enter-from {
  opacity: 0;
  transform: translateX(-20px);
}

.list-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

/* Responsive */
@media (max-width: 600px) {
  .notification-history-modal {
    max-height: 90vh;
  }

  .book-header {
    padding: 16px;
  }

  .book-title {
    font-size: 0.65rem;
  }

  .book-footer {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }

  .footer-stats {
    justify-content: center;
  }

  .footer-actions {
    justify-content: center;
  }
}
</style>
