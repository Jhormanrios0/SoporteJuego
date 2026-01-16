<template>
  <Teleport to="body">
    <TransitionGroup name="toast">
      <div
        v-for="notification in notifications"
        :key="notification.id"
        class="status-notification"
        :style="{ 
          top: `${20 + notification.index * 90}px`,
          borderColor: notification.color,
          boxShadow: `0 0 20px ${notification.color}40, inset 0 0 15px ${notification.color}20`
        }"
      >
        <div 
          class="status-icon"
        >
          <img src="/icons/ender_eye.png" alt="Ender Eye" width="40" height="40" />
        </div>
        <div class="status-content">
          <div class="status-title">CAMBIO DE ESTADO</div>
          <div class="status-player">{{ notification.playerName }}</div>
          <div 
            class="status-message"
            :style="{ 
              color: notification.color,
              textShadow: `0 0 8px ${notification.color}80`
            }"
          >
            {{ notification.status }}
          </div>
        </div>
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
</script>

<style scoped>
.status-notification {
  position: fixed;
  right: 20px;
  background: linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 100%);
  border: 3px solid;
  border-radius: 12px;
  padding: 16px 20px;
  min-width: 350px;
  max-width: 450px;
  z-index: 10000;
  display: flex;
  align-items: center;
  gap: 16px;
  animation: slideIn 0.4s ease-out;
  backdrop-filter: blur(10px);
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

.status-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  animation: sparkle 1.5s ease-in-out infinite;
}

.status-icon img {
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
}

@keyframes sparkle {
  0%, 100% {
    transform: scale(1) rotate(0deg);
  }
  25% {
    transform: scale(1.1) rotate(-10deg);
  }
  50% {
    transform: scale(1.2) rotate(10deg);
  }
  75% {
    transform: scale(1.1) rotate(-10deg);
  }
}

.status-content {
  flex: 1;
}

.status-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  color: #ffffff;
  text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
  margin-bottom: 8px;
  letter-spacing: 1px;
}

.status-player {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: #cccccc;
  margin-bottom: 6px;
}

.status-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  font-weight: bold;
  line-height: 1.4;
  word-wrap: break-word;
  display: flex;
  align-items: center;
  gap: 6px;
}

.status-message::before {
  content: "●";
  font-size: 0.6rem;
  animation: pulse 1s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.6;
    transform: scale(1.3);
  }
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
  transform: translateX(500px);
  opacity: 0;
}

.toast-move {
  transition: all 0.3s ease;
}
</style>
