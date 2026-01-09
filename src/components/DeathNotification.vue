<template>
  <Teleport to="body">
    <TransitionGroup name="toast">
      <div
        v-for="notification in notifications"
        :key="notification.id"
        class="death-notification"
        :style="{ top: `${20 + notification.index * 80}px` }"
      >
        <div class="death-icon">💀</div>
        <div class="death-content">
          <div class="death-title">MUERTE</div>
          <div class="death-message">{{ notification.message }}</div>
        </div>
      </div>
    </TransitionGroup>
  </Teleport>
</template>

<script setup>
import { ref, watch } from "vue";

const props = defineProps({
  notifications: {
    type: Array,
    required: true,
  },
});
</script>

<style scoped>
.death-notification {
  position: fixed;
  right: 20px;
  background: linear-gradient(135deg, #1a0000 0%, #3d0000 100%);
  border: 3px solid #ff0000;
  border-radius: 8px;
  padding: 16px 20px;
  min-width: 350px;
  max-width: 450px;
  box-shadow: 0 0 30px rgba(255, 0, 0, 0.6), inset 0 0 20px rgba(255, 0, 0, 0.1);
  z-index: 10000;
  display: flex;
  align-items: center;
  gap: 16px;
  animation: shake 0.5s ease-in-out;
}

@keyframes shake {
  0%,
  100% {
    transform: translateX(0);
  }
  10%,
  30%,
  50%,
  70%,
  90% {
    transform: translateX(-5px);
  }
  20%,
  40%,
  60%,
  80% {
    transform: translateX(5px);
  }
}

.death-icon {
  font-size: 2.5rem;
  animation: pulse 1s ease-in-out infinite;
}

@keyframes pulse {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.2);
  }
}

.death-content {
  flex: 1;
}

.death-title {
  font-family: "Press Start 2P", monospace;
  font-size: 0.9rem;
  color: #ff0000;
  text-shadow: 0 0 10px rgba(255, 0, 0, 0.8);
  margin-bottom: 8px;
  letter-spacing: 2px;
}

.death-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #ffffff;
  line-height: 1.4;
  text-shadow: 0 0 5px rgba(255, 255, 255, 0.5);
}

/* Transiciones */
.toast-enter-active {
  animation: slideIn 0.4s ease-out;
}

.toast-leave-active {
  animation: slideOut 0.4s ease-out;
}

@keyframes slideIn {
  from {
    transform: translateX(400px);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes slideOut {
  from {
    transform: translateX(0);
    opacity: 1;
  }
  to {
    transform: translateX(400px);
    opacity: 0;
  }
}

/* Responsive */
@media (max-width: 768px) {
  .death-notification {
    right: 10px;
    left: 10px;
    min-width: unset;
    max-width: unset;
  }

  .death-title {
    font-size: 0.7rem;
  }

  .death-message {
    font-size: 0.6rem;
  }
}
</style>
