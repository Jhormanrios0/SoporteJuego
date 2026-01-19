<template>
  <Teleport to="body">
    <TransitionGroup name="toast">
      <div
        v-for="notification in notifications"
        :key="notification.id"
        class="message-notification"
        :class="{
          'notification-global': notification.type === 'general',
          'notification-personal': notification.type === 'specific',
        }"
        :style="{ 
          top: `${120 + notification.index * 100}px`,
        }"
        @click="handleClick(notification.id)"
      >
        <div class="notification-icon">
          <img 
            v-if="notification.type === 'general'"
            src="/icons/ender_eye.png" 
            alt="Global" 
            width="48" 
            height="48" 
          />
          <img 
            v-else
            src="/icons/icon_bell.webp" 
            alt="Personal" 
            width="48" 
            height="48" 
          />
        </div>
        
        <div class="notification-content">
          <div class="notification-title">
            {{ notification.type === 'general' ? '📢 MENSAJE GLOBAL' : '📩 MENSAJE PERSONAL' }}
          </div>
          <div class="notification-sender">{{ notification.senderName }}</div>
          <div class="notification-message">{{ truncateMessage(notification.message, 60) }}</div>
        </div>

        <button 
          class="notification-close" 
          @click.stop="handleClose(notification.id)" 
          aria-label="Cerrar"
        >
          ×
        </button>
      </div>
    </TransitionGroup>
  </Teleport>
</template>

<script setup>
const props = defineProps({
  notifications: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['click', 'close']);

function truncateMessage(message, maxLength = 60) {
  if (!message) return '';
  if (message.length <= maxLength) return message;
  return message.substring(0, maxLength) + '...';
}

function handleClick(notificationId) {
  emit('click', notificationId);
}

function handleClose(notificationId) {
  emit('close', notificationId);
}
</script>

<style scoped>
.message-notification {
  position: fixed;
  right: 20px;
  background: linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 100%);
  border: 3px solid;
  border-radius: 12px;
  padding: 16px 20px;
  min-width: 380px;
  max-width: 450px;
  z-index: 10000;
  display: flex;
  align-items: center;
  gap: 16px;
  animation: slideIn 0.4s ease-out;
  backdrop-filter: blur(10px);
  cursor: pointer;
  transition: transform 0.2s ease;
}

.message-notification:hover {
  transform: translateX(-4px);
}

.notification-global {
  border-color: #00ffc2;
  box-shadow: 
    0 0 25px rgba(0, 255, 194, 0.5),
    inset 0 0 15px rgba(0, 255, 194, 0.2);
}

.notification-personal {
  border-color: #ffda79;
  box-shadow: 
    0 0 25px rgba(255, 218, 121, 0.5),
    inset 0 0 15px rgba(255, 218, 121, 0.2);
}

@keyframes slideIn {
  from {
    transform: translateX(500px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.notification-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  animation: iconFloat 2s ease-in-out infinite;
}

.notification-icon img {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
  filter: drop-shadow(0 0 8px currentColor);
}

.notification-global .notification-icon img {
  color: rgba(0, 255, 194, 0.8);
}

.notification-personal .notification-icon img {
  color: rgba(255, 218, 121, 0.8);
}

@keyframes iconFloat {
  0%, 100% {
    transform: translateY(0) rotate(0deg);
  }
  25% {
    transform: translateY(-3px) rotate(-5deg);
  }
  50% {
    transform: translateY(0) rotate(5deg);
  }
  75% {
    transform: translateY(-3px) rotate(-5deg);
  }
}

.notification-content {
  flex: 1;
  min-width: 0;
}

.notification-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  margin-bottom: 8px;
  letter-spacing: 1px;
}

.notification-global .notification-title {
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.8);
}

.notification-personal .notification-title {
  color: #ffda79;
  text-shadow: 0 0 10px rgba(255, 218, 121, 0.8);
}

.notification-sender {
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  color: #ffffff;
  margin-bottom: 6px;
  text-shadow: 0 0 8px rgba(255, 255, 255, 0.5);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.notification-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.85);
  line-height: 1.5;
  word-wrap: break-word;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.notification-close {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  border: 2px solid rgba(247, 65, 143, 0.5);
  background: rgba(0, 0, 0, 0.7);
  color: #f7418f;
  font-size: 1.4rem;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.15s ease;
  font-family: monospace;
  padding: 0;
  opacity: 0.8;
}

.notification-close:hover {
  opacity: 1;
  background: rgba(247, 65, 143, 0.2);
  border-color: rgba(247, 65, 143, 0.8);
  transform: scale(1.1);
}

.notification-close:active {
  transform: scale(0.95);
}

/* Transiciones del grupo */
.toast-enter-active {
  transition: all 0.4s ease-out;
}

.toast-leave-active {
  transition: all 0.3s ease-in;
}

.toast-enter-from {
  transform: translateX(500px);
  opacity: 0;
}

.toast-leave-to {
  transform: translateX(500px) scale(0.95);
  opacity: 0;
}

.toast-move {
  transition: all 0.3s ease;
}

/* Responsive */
@media (max-width: 640px) {
  .message-notification {
    right: 10px;
    left: 10px;
    min-width: auto;
    max-width: none;
    padding: 14px 16px;
  }

  .notification-icon img {
    width: 40px;
    height: 40px;
  }

  .notification-title {
    font-size: 0.55rem;
  }

  .notification-sender {
    font-size: 0.52rem;
  }

  .notification-message {
    font-size: 0.5rem;
  }
}
</style>
