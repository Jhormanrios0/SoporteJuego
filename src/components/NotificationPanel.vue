<template>
  <Transition name="panel-slide">
    <aside v-if="isOpen" class="notification-panel" @click.self="close">
      <div class="panel-container">
        <!-- Header -->
        <header class="panel-header">
          <h2 class="panel-title">
            <Bell :size="20" />
            NOTIFICACIONES
          </h2>
          <button
            class="close-btn"
            type="button"
            @click="close"
            aria-label="Cerrar panel"
          >
            <X :size="20" />
          </button>
        </header>

        <!-- Contenido según el rol -->
        <div class="panel-content">
          <!-- Vista Admin: Enviar notificaciones -->
          <div v-if="isVipOrAdmin" class="admin-section">
            <div class="section-header">
              <Send :size="18" />
              <h3 class="section-title">ENVIAR NOTIFICACIÓN</h3>
            </div>

            <form class="notification-form" @submit.prevent="sendNotification">
              <label class="form-label">Mensaje</label>
              <textarea
                v-model="messageText"
                class="form-textarea"
                placeholder="Escribe tu mensaje aquí..."
                maxlength="500"
                rows="4"
                :disabled="isSending"
              ></textarea>
              <div class="char-count">
                {{ messageText.length }}/500
              </div>

              <label class="form-label">Destinatarios</label>
              <div class="form-radio-group">
                <label class="radio-option">
                  <input
                    v-model="notificationType"
                    type="radio"
                    value="all"
                    :disabled="isSending"
                  />
                  <span class="radio-label">
                    <Users :size="16" />
                    Todos los jugadores
                  </span>
                </label>
                <label class="radio-option">
                  <input
                    v-model="notificationType"
                    type="radio"
                    value="specific"
                    :disabled="isSending"
                  />
                  <span class="radio-label">
                    <User :size="16" />
                    Jugador específico
                  </span>
                </label>
              </div>

              <!-- Selector de jugador específico -->
              <div v-if="notificationType === 'specific'" class="player-select">
                <label class="form-label">Seleccionar jugador</label>
                <select
                  v-model="selectedPlayerId"
                  class="form-select"
                  :disabled="isSending"
                >
                  <option :value="null">-- Selecciona un jugador --</option>
                  <option
                    v-for="player in allPlayers"
                    :key="player.id"
                    :value="player.id"
                  >
                    {{
                      player.nickname ||
                      `${player.first_name || ""} ${player.last_name || ""}`.trim() ||
                      "Jugador"
                    }}
                    ({{ player.lives }} ❤️)
                  </option>
                </select>
              </div>

              <button
                class="send-btn"
                type="submit"
                :disabled="!canSend || isSending"
              >
                <Send :size="16" />
                {{ isSending ? "ENVIANDO..." : "ENVIAR NOTIFICACIÓN" }}
              </button>

              <div v-if="sendError" class="error-message">
                {{ sendError }}
              </div>
              <div v-if="sendSuccess" class="success-message">
                ¡Notificación enviada correctamente!
              </div>
            </form>
          </div>

          <!-- Divisor entre secciones -->
          <div v-if="isVipOrAdmin" class="section-divider"></div>

          <!-- Vista de notificaciones recibidas (para todos) -->
          <div class="notifications-section">
            <div class="section-header">
              <Inbox :size="18" />
              <h3 class="section-title">
                {{ isVipOrAdmin ? "NOTIFICACIONES ENVIADAS" : "NOTIFICACIONES" }}
              </h3>
            </div>

            <div v-if="loading" class="loading-state">
              <div class="spinner"></div>
              <p>Cargando notificaciones...</p>
            </div>

            <div
              v-else-if="displayNotifications.length === 0"
              class="empty-state"
            >
              <Inbox :size="48" />
              <p>No hay notificaciones</p>
            </div>

            <div v-else class="notifications-list">
              <div
                v-for="notification in displayNotifications"
                :key="notification.id"
                class="notification-item"
                :class="{ unread: !notification.read }"
              >
                <div class="notification-header">
                  <span class="notification-time">
                    {{ formatDate(notification.created_at) }}
                  </span>
                  <span
                    v-if="notification.type === 'specific'"
                    class="notification-badge specific"
                  >
                    Personal
                  </span>
                  <span v-else class="notification-badge global">Global</span>
                </div>

                <p class="notification-message">{{ notification.message }}</p>

                <div v-if="!isVipOrAdmin" class="notification-actions">
                  <button
                    v-if="!notification.read"
                    class="action-btn mark-read"
                    type="button"
                    @click="markAsRead(notification.id)"
                  >
                    <Check :size="14" />
                    Marcar leída
                  </button>
                  <button
                    class="action-btn delete"
                    type="button"
                    @click="deleteNotification(notification.id)"
                  >
                    <Trash2 :size="14" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </aside>
  </Transition>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import {
  Bell,
  X,
  Send,
  Users,
  User,
  Inbox,
  Check,
  Trash2,
} from "lucide-vue-next";

const props = defineProps({
  isOpen: {
    type: Boolean,
    required: true,
  },
  isVipOrAdmin: {
    type: Boolean,
    default: false,
  },
  notifications: {
    type: Array,
    default: () => [],
  },
  allPlayers: {
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
  "send-notification",
  "mark-read",
  "delete-notification",
]);

// Estados del formulario de envío
const messageText = ref("");
const notificationType = ref("all");
const selectedPlayerId = ref(null);
const isSending = ref(false);
const sendError = ref("");
const sendSuccess = ref("");

// Computed
const canSend = computed(() => {
  if (!messageText.value.trim()) return false;
  if (notificationType.value === "specific" && !selectedPlayerId.value)
    return false;
  return true;
});

const displayNotifications = computed(() => {
  return props.notifications.slice().sort((a, b) => {
    return new Date(b.created_at) - new Date(a.created_at);
  });
});

// Métodos
function close() {
  emit("close");
}

async function sendNotification() {
  if (!canSend.value || isSending.value) return;

  sendError.value = "";
  sendSuccess.value = "";
  isSending.value = true;

  try {
    const payload = {
      message: messageText.value.trim(),
      type: notificationType.value === "all" ? "general" : "specific",
      targetPlayerId:
        notificationType.value === "specific" ? selectedPlayerId.value : null,
    };

    emit("send-notification", payload);

    // Mostrar mensaje de éxito
    sendSuccess.value = "¡Notificación enviada!";

    // Limpiar formulario
    messageText.value = "";
    notificationType.value = "all";
    selectedPlayerId.value = null;

    // Limpiar mensaje de éxito después de 3 segundos
    setTimeout(() => {
      sendSuccess.value = "";
    }, 3000);
  } catch (error) {
    sendError.value = error.message || "Error al enviar notificación";
  } finally {
    isSending.value = false;
  }
}

function markAsRead(notificationId) {
  emit("mark-read", notificationId);
}

function deleteNotification(notificationId) {
  emit("delete-notification", notificationId);
}

function formatDate(dateString) {
  if (!dateString) return "";
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return "Ahora";
  if (diffMins < 60) return `Hace ${diffMins}m`;
  if (diffHours < 24) return `Hace ${diffHours}h`;
  if (diffDays < 7) return `Hace ${diffDays}d`;

  return date.toLocaleDateString("es-ES", {
    day: "2-digit",
    month: "short",
  });
}

// Limpiar errores al cerrar
watch(
  () => props.isOpen,
  (isOpen) => {
    if (!isOpen) {
      sendError.value = "";
      sendSuccess.value = "";
    }
  }
);
</script>

<style scoped>
.notification-panel {
  position: fixed;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(4px);
  z-index: 2000;
  display: flex;
  justify-content: flex-end;
  align-items: stretch;
}

.panel-container {
  width: min(480px, 90vw);
  background: linear-gradient(
    180deg,
    rgba(10, 0, 32, 0.98) 0%,
    rgba(0, 0, 0, 0.98) 100%
  );
  border-left: 3px solid rgba(0, 255, 194, 0.6);
  box-shadow: -8px 0 40px rgba(0, 0, 0, 0.6),
    inset 0 0 0 1px rgba(255, 255, 255, 0.05);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 20px 24px;
  border-bottom: 2px solid rgba(0, 255, 194, 0.3);
  background: rgba(0, 0, 0, 0.4);
}

.panel-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.9rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.6);
  margin: 0;
}

.close-btn {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  border: 2px solid rgba(247, 65, 143, 0.6);
  background: rgba(0, 0, 0, 0.6);
  color: #f7418f;
  cursor: pointer;
  display: grid;
  place-items: center;
  transition: all 0.15s ease;
}

.close-btn:hover {
  filter: brightness(1.2);
  transform: scale(1.05);
}

.close-btn:active {
  transform: scale(0.95);
}

.panel-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* Sección Admin */
.admin-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #00ffc2;
}

.section-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #00ffc2;
  text-shadow: 0 0 8px rgba(0, 255, 194, 0.5);
  margin: 0;
}

.notification-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: rgba(0, 0, 0, 0.4);
  border: 2px solid rgba(0, 255, 194, 0.3);
  border-radius: 12px;
  padding: 20px;
}

.form-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: rgba(255, 255, 255, 0.9);
  margin-bottom: 8px;
}

.form-textarea {
  width: 100%;
  min-height: 100px;
  padding: 12px;
  border: 2px solid rgba(0, 255, 194, 0.4);
  border-radius: 8px;
  background: rgba(0, 0, 0, 0.6);
  color: rgba(255, 255, 255, 0.95);
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  line-height: 1.6;
  resize: vertical;
  transition: all 0.2s ease;
}

.form-textarea:focus {
  outline: none;
  border-color: #00ffc2;
  box-shadow: 0 0 0 3px rgba(0, 255, 194, 0.15);
}

.form-textarea:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.char-count {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.5);
  text-align: right;
  margin-top: -8px;
}

.form-radio-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.radio-option {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  border: 2px solid rgba(0, 255, 194, 0.3);
  border-radius: 8px;
  background: rgba(0, 0, 0, 0.4);
  cursor: pointer;
  transition: all 0.15s ease;
}

.radio-option:hover {
  border-color: rgba(0, 255, 194, 0.5);
  background: rgba(0, 255, 194, 0.05);
}

.radio-option input[type="radio"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: #00ffc2;
}

.radio-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: rgba(255, 255, 255, 0.9);
}

.player-select {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-select {
  width: 100%;
  padding: 12px;
  border: 2px solid rgba(0, 255, 194, 0.4);
  border-radius: 8px;
  background: rgba(0, 0, 0, 0.6);
  color: rgba(255, 255, 255, 0.95);
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.form-select:focus {
  outline: none;
  border-color: #00ffc2;
  box-shadow: 0 0 0 3px rgba(0, 255, 194, 0.15);
}

.form-select:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.send-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 20px;
  border: 2px solid rgba(0, 255, 194, 0.7);
  border-radius: 8px;
  background: rgba(0, 255, 194, 0.15);
  color: #00ffc2;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: 0 4px 12px rgba(0, 255, 194, 0.2);
}

.send-btn:hover:not(:disabled) {
  filter: brightness(1.2);
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 255, 194, 0.3);
}

.send-btn:active:not(:disabled) {
  transform: translateY(0);
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.error-message {
  padding: 12px;
  border: 2px solid rgba(247, 65, 143, 0.6);
  border-radius: 8px;
  background: rgba(247, 65, 143, 0.1);
  color: #ffd1e6;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  line-height: 1.5;
}

.success-message {
  padding: 12px;
  border: 2px solid rgba(0, 255, 194, 0.6);
  border-radius: 8px;
  background: rgba(0, 255, 194, 0.1);
  color: #00ffc2;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  line-height: 1.5;
}

/* Divisor */
.section-divider {
  height: 2px;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(0, 255, 194, 0.3) 50%,
    transparent 100%
  );
  margin: 8px 0;
}

/* Sección de notificaciones */
.notifications-section {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 16px;
  padding: 40px 20px;
  color: rgba(255, 255, 255, 0.5);
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  text-align: center;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(0, 255, 194, 0.2);
  border-top-color: #00ffc2;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.notifications-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.notification-item {
  padding: 16px;
  border: 2px solid rgba(0, 255, 194, 0.3);
  border-radius: 10px;
  background: rgba(0, 0, 0, 0.4);
  transition: all 0.15s ease;
}

.notification-item.unread {
  border-color: rgba(0, 255, 194, 0.6);
  background: rgba(0, 255, 194, 0.05);
  box-shadow: 0 0 12px rgba(0, 255, 194, 0.2);
}

.notification-item:hover {
  transform: translateX(-4px);
  border-color: rgba(0, 255, 194, 0.5);
}

.notification-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 10px;
}

.notification-time {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: rgba(255, 255, 255, 0.5);
}

.notification-badge {
  padding: 4px 8px;
  border-radius: 6px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.45rem;
  text-transform: uppercase;
  margin-left: auto;
}

.notification-badge.global {
  background: rgba(0, 255, 194, 0.2);
  color: #00ffc2;
  border: 1px solid rgba(0, 255, 194, 0.4);
}

.notification-badge.specific {
  background: rgba(255, 218, 121, 0.2);
  color: #ffda79;
  border: 1px solid rgba(255, 218, 121, 0.4);
}

.notification-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.6;
  margin: 0 0 12px 0;
  word-wrap: break-word;
}

.notification-actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 10px;
  border: 2px solid rgba(0, 255, 194, 0.4);
  border-radius: 6px;
  background: rgba(0, 0, 0, 0.5);
  color: rgba(255, 255, 255, 0.9);
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  cursor: pointer;
  transition: all 0.15s ease;
}

.action-btn:hover {
  filter: brightness(1.2);
}

.action-btn.mark-read {
  border-color: rgba(0, 255, 194, 0.5);
  color: #00ffc2;
}

.action-btn.delete {
  border-color: rgba(247, 65, 143, 0.5);
  color: #f7418f;
  margin-left: auto;
}

/* Animaciones */
.panel-slide-enter-active,
.panel-slide-leave-active {
  transition: all 0.3s ease;
}

.panel-slide-enter-active .panel-container,
.panel-slide-leave-active .panel-container {
  transition: transform 0.3s ease;
}

.panel-slide-enter-from,
.panel-slide-leave-to {
  opacity: 0;
}

.panel-slide-enter-from .panel-container,
.panel-slide-leave-to .panel-container {
  transform: translateX(100%);
}

/* Scrollbar personalizado */
.panel-content::-webkit-scrollbar {
  width: 8px;
}

.panel-content::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.3);
  border-radius: 4px;
}

.panel-content::-webkit-scrollbar-thumb {
  background: rgba(0, 255, 194, 0.4);
  border-radius: 4px;
}

.panel-content::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 255, 194, 0.6);
}

/* Responsive */
@media (max-width: 640px) {
  .panel-container {
    width: 100vw;
  }

  .panel-header {
    padding: 16px 20px;
  }

  .panel-content {
    padding: 20px;
  }

  .notification-form {
    padding: 16px;
  }
}
</style>
