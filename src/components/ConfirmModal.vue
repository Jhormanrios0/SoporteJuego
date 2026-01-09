<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="modal-overlay" @click="handleOverlayClick">
        <div class="modal-container" @click.stop>
          <div class="modal-header">
            <h2 class="modal-title">{{ title }}</h2>
          </div>

          <div class="modal-body">
            <p class="modal-message">{{ message }}</p>
          </div>

          <div class="modal-actions">
            <button @click="$emit('cancel')" class="modal-btn btn-cancel">
              Cancelar
            </button>
            <button @click="$emit('confirm')" class="modal-btn btn-confirm">
              Confirmar
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
defineProps({
  show: {
    type: Boolean,
    required: true,
  },
  title: {
    type: String,
    default: "Confirmar acción",
  },
  message: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(["confirm", "cancel"]);

function handleOverlayClick() {
  emit("cancel");
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  backdrop-filter: blur(4px);
}

.modal-container {
  background: #0a0a0a;
  border: 4px solid #00ff88;
  border-radius: 8px;
  padding: 32px;
  max-width: 500px;
  width: 90%;
  box-shadow: 0 0 40px rgba(0, 255, 136, 0.5),
    inset 0 0 30px rgba(0, 255, 136, 0.1);
  animation: modalPulse 0.3s ease-out;
}

@keyframes modalPulse {
  0% {
    transform: scale(0.9);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.modal-header {
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 2px solid rgba(0, 255, 136, 0.3);
}

.modal-title {
  font-family: "Press Start 2P", monospace;
  font-size: 1.2rem;
  color: #00ff88;
  text-shadow: 0 0 10px rgba(0, 255, 136, 0.8);
  margin: 0;
  text-align: center;
}

.modal-body {
  margin-bottom: 24px;
}

.modal-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
  color: #00ffff;
  line-height: 1.8;
  text-align: center;
  margin: 0;
}

.modal-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
}

.modal-btn {
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
  padding: 12px 24px;
  border: 3px solid;
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.5);
  cursor: pointer;
  transition: all 0.2s;
  text-transform: uppercase;
}

.modal-btn:hover {
  transform: translateY(-2px);
}

.btn-cancel {
  border-color: #888;
  color: #888;
}

.btn-cancel:hover {
  background: rgba(136, 136, 136, 0.2);
  box-shadow: 0 4px 15px rgba(136, 136, 136, 0.4);
}

.btn-confirm {
  border-color: #ff0055;
  color: #ff0055;
}

.btn-confirm:hover {
  background: rgba(255, 0, 85, 0.2);
  box-shadow: 0 4px 15px rgba(255, 0, 85, 0.5);
}

/* Transiciones */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

@media (max-width: 768px) {
  .modal-container {
    padding: 24px;
  }

  .modal-title {
    font-size: 1rem;
  }

  .modal-message {
    font-size: 0.75rem;
  }

  .modal-btn {
    font-size: 0.75rem;
    padding: 10px 20px;
  }
}
</style>
