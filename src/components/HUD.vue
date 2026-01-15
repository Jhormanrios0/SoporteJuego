<template>
  <div class="hud-container">
    <!-- HUD Slots Grid -->
    <div class="hud-grid">
      <!-- Slot 1: Libro de Información -->
      <button 
        class="hud-slot hud-slot-active" 
        @click="openBookModal"
        title="Información"
        aria-label="Abrir información"
      >
        <div class="hud-slot-inner">
          <img src="/icons/book.png" alt="Información" class="hud-slot-icon" />
        </div>
      </button>

      <!-- Slot 2: Vacío -->
      <div class="hud-slot">
        <div class="hud-slot-inner empty">
        </div>
      </div>

      <!-- Slot 3: Vacío -->
      <div class="hud-slot">
        <div class="hud-slot-inner empty">
        </div>
      </div>

      <!-- Slot 4: Vacío -->
      <div class="hud-slot">
        <div class="hud-slot-inner empty">
        </div>
      </div>

      <!-- Slot 5: Vacío -->
      <div class="hud-slot">
        <div class="hud-slot-inner empty">
        </div>
      </div>

      <!-- Slots 6-13: Vacíos adicionales -->
      <div v-for="i in 8" :key="`slot-${i + 5}`" class="hud-slot">
        <div class="hud-slot-inner empty">
        </div>
      </div>
    </div>

    <!-- Modal del Libro de Información -->
    <Transition name="modal-fade">
      <div v-if="isBookOpen" class="modal-overlay" @click="closeBookModal">
        <div class="modal-content" @click.stop>
          <BookInfo :standaloneMode="false" @close="closeBookModal" />
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref } from "vue";
import BookInfo from "./BookInfo.vue";

const isBookOpen = ref(false);

const openBookModal = () => {
  isBookOpen.value = true;
};

const closeBookModal = () => {
  isBookOpen.value = false;
};
</script>

<style scoped>
/* Contenedor HUD */
.hud-container {
  position: relative;
  width: 100%;
}

/* Grid de slots HUD */
.hud-grid {
  display: grid;
  grid-template-columns: repeat(13, 1fr);
  gap: 0.5rem;
  width: 100%;
  max-width: 100%;
  padding: 1rem;
}

/* Slot HUD individual */
.hud-slot {
  aspect-ratio: 1;
  background: transparent;
  border: none;
  cursor: default;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hud-slot.hud-slot-active {
  cursor: pointer;
  transition: all 0.2s ease;
}

.hud-slot-active:hover {
  transform: scale(1.05);
}

.hud-slot-active:active {
  transform: scale(0.98);
}

/* Interior del slot */
.hud-slot-inner {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #5a7c7a 0%, #4a6c6a 50%, #3a5c5a 100%);
  border: 4px solid #2a4c4a;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 
    inset -3px -3px 0 rgba(0, 0, 0, 0.4),
    inset 3px 3px 0 rgba(255, 255, 255, 0.1),
    0 4px 0 rgba(0, 0, 0, 0.3);
  position: relative;
  overflow: hidden;
}

/* Textura de slot */
.hud-slot-inner::before {
  content: "";
  position: absolute;
  inset: 0;
  background: 
    repeating-linear-gradient(
      0deg,
      transparent,
      transparent 2px,
      rgba(0, 0, 0, 0.1) 2px,
      rgba(0, 0, 0, 0.1) 4px
    );
  pointer-events: none;
}

.hud-slot-inner.empty {
  background: linear-gradient(135deg, #4a6c6a 0%, #3a5c5a 50%, #2a4c4a 100%);
  opacity: 0.6;
}

/* Icono del slot */
.hud-slot-icon {
  width: 60%;
  height: 60%;
  object-fit: contain;
  image-rendering: pixelated;
  z-index: 1;
  filter: drop-shadow(2px 2px 0 rgba(0, 0, 0, 0.3));
}

/* MODAL */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 2rem;
  backdrop-filter: blur(2px);
}

.modal-content {
  position: relative;
  max-width: 1124px;
  width: 100%;
  max-height: 94vh;
  overflow-y: auto;
  background: rgba(0, 0, 0, 0.95);
  border: 4px solid rgba(0, 255, 194, 0.6);
  border-radius: 8px;
  padding: 0;
  box-shadow: 
    0 0 30px rgba(0, 255, 194, 0.3),
    inset 0 0 20px rgba(0, 0, 0, 0.5);
}

/* Botón cerrar modal */
.modal-close {
  position: absolute;
  top: 1rem;
  left: 1rem;
  background: transparent;
  border: none;
  color: var(--neon-pink);
  cursor: pointer;
  padding: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1001;
  transition: all 0.2s ease;
}

.modal-close:hover {
  transform: scale(1.2);
  filter: drop-shadow(0 0 10px var(--neon-pink));
}

.modal-close:active {
  transform: scale(1.05);
}

/* Transiciones */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

/* Responsive */
@media (max-width: 768px) {
  .hud-grid {
    max-width: 300px;
    gap: 0.4rem;
  }

  .hud-slot-inner {
    border: 3px solid #2a4c4a;
  }

  .hud-slot-icon {
    width: 55%;
    height: 55%;
  }

  .modal-content {
    max-height: 85vh;
  }
}

@media (max-width: 480px) {
  .hud-grid {
    max-width: 250px;
    gap: 0.3rem;
  }

  .hud-slot-inner {
    border: 2px solid #2a4c4a;
  }

  .hud-slot-icon {
    width: 50%;
    height: 50%;
  }
}
</style>
