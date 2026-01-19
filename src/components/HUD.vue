<template>
  <div class="hud-container">
    <!-- HUD Slots Grid -->
    <div class="hud-grid">
      <!-- Slot 1: Libro de Información -->
      <button
        class="hud-slot hud-slot-active"
        @click="openBookModal"
        data-tooltip="Información"
        aria-label="Abrir información"
      >
        <div class="hud-slot-inner">
          <img src="/icons/book.png" alt="Información" class="hud-slot-icon" />
        </div>
      </button>

      <!-- Slot 2: Historial -->
      <button
        class="hud-slot hud-slot-active"
        @click="openHistory"
        data-tooltip="Historial"
        aria-label="Abrir historial"
      >
        <div class="hud-slot-inner">
          <img
            src="/icons/Hanging_Sign.webp"
            alt="Historial"
            class="hud-slot-icon"
          />
        </div>
      </button>

      <!-- Slot 3: Panel de Notificaciones -->
      <button
        class="hud-slot hud-slot-active"
        @click="openNotifications"
        data-tooltip="Notificaciones"
        aria-label="Abrir notificaciones"
      >
        <div class="hud-slot-inner">
          <img
            src=""
            alt="Notificaciones"
            class="hud-slot-icon"
          />
        </div>
      </button>

      <!-- Slot 4: Vacío -->
      <div class="hud-slot">
        <div class="hud-slot-inner empty"></div>
      </div>

      <!-- Slot 5: Vacío -->
      <div class="hud-slot">
        <div class="hud-slot-inner empty"></div>
      </div>

      <!-- Slots 6-12: Vacíos adicionales -->
      <div v-for="i in 7" :key="`slot-${i + 5}`" class="hud-slot">
        <div class="hud-slot-inner empty"></div>
      </div>

      <!-- Slot 13 (último): Botón de Ayuda -->
      <button
        class="hud-slot hud-slot-active hud-slot-help"
        @click="openHelpModal"
        data-tooltip="¡Pedir ayuda!"
        aria-label="Pedir ayuda"
      >
        <div class="hud-slot-inner help-slot">
          <img
            src="/icons/abcde.gif"
            alt="Pedir ayuda"
            class="hud-slot-icon help-icon"
          />
        </div>
      </button>
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

const emit = defineEmits(["open-history", "open-help", "open-notifications"]);

const isBookOpen = ref(false);

const openBookModal = () => {
  isBookOpen.value = true;
};

const closeBookModal = () => {
  isBookOpen.value = false;
};

const openHistory = () => {
  emit("open-history");
};

const openHelpModal = () => {
  emit("open-help");
};

const openNotifications = () => {
  emit("open-notifications");
};
</script>

<style scoped>
/* Contenedor HUD */
.hud-container {
  position: relative;
  width: 100%;
  display: grid;
  justify-items: center;
  overflow: visible;
}

/* Grid de slots HUD */
.hud-grid {
  --hud-gap: clamp(8px, 1.2vw, 14px);
  --hud-slot: clamp(70px, 7.5vw, 140px);
  display: flex;
  flex-wrap: wrap;
  gap: var(--hud-gap);
  width: 100%;
  max-width: 100%;
  padding: clamp(12px, 1.6vw, 18px);
  justify-content: center;
  align-content: center;
  overflow: visible;
  background: linear-gradient(
    180deg,
    rgba(24, 30, 24, 0.6) 0%,
    rgba(0, 0, 0, 0.15) 100%
  );
  border: 2px solid rgba(0, 255, 194, 0.18);
  border-radius: 12px;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.35),
    inset 0 0 0 2px rgba(255, 255, 255, 0.04);
  position: relative;
}

.hud-grid::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    /* scanlines */ repeating-linear-gradient(
      0deg,
      rgba(0, 0, 0, 0.12),
      rgba(0, 0, 0, 0.12) 2px,
      transparent 2px,
      transparent 4px
    ),
    /* subtle block grid */
      repeating-linear-gradient(
        90deg,
        rgba(255, 255, 255, 0.03) 0px,
        rgba(255, 255, 255, 0.03) 2px,
        transparent 2px,
        transparent 20px
      );
  pointer-events: none;
  opacity: 0.55;
  border-radius: 12px;
  z-index: 0;
}

.hud-grid > * {
  position: relative;
  z-index: 1;
}

/* Slot HUD individual */
.hud-slot {
  width: var(--hud-slot);
  height: var(--hud-slot);
  background: transparent;
  border: none;
  cursor: default;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  min-width: 0;
  overflow: visible;
}

.hud-slot.hud-slot-active {
  cursor: pointer;
  transition: all 0.2s ease;
}

.hud-slot-active:hover {
  transform: translateY(-2px) scale(1.06);
}

.hud-slot-active:active {
  transform: scale(0.98);
}

.hud-slot-active:focus-visible {
  outline: none;
}

.hud-slot-active:focus-visible .hud-slot-inner {
  box-shadow: 0 0 0 3px rgba(0, 255, 194, 0.5), 0 18px 0 rgba(0, 0, 0, 0.35),
    inset -4px -4px 0 rgba(0, 0, 0, 0.4),
    inset 4px 4px 0 rgba(255, 255, 255, 0.1);
}

/* Tooltip retro (hover/focus) */
.hud-slot-active::after {
  content: attr(data-tooltip);
  position: absolute;
  left: 50%;
  bottom: calc(100% + 10px);
  transform: translateX(-50%) translateY(6px);
  opacity: 0;
  pointer-events: none;
  white-space: nowrap;
  padding: 8px 10px;
  border-radius: 10px;
  border: 2px solid rgba(0, 255, 194, 0.55);
  background: rgba(0, 0, 0, 0.82);
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.55),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06);
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  letter-spacing: 1px;
  color: rgba(255, 255, 255, 0.92);
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.25);
  z-index: 10050;
}

.hud-slot-active::before {
  content: "";
  position: absolute;
  left: 50%;
  bottom: calc(100% + 4px);
  transform: translateX(-50%) translateY(6px);
  opacity: 0;
  pointer-events: none;
  width: 0;
  height: 0;
  border-left: 7px solid transparent;
  border-right: 7px solid transparent;
  border-top: 7px solid rgba(0, 0, 0, 0.82);
  filter: drop-shadow(0 -1px 0 rgba(0, 255, 194, 0.35));
  z-index: 10049;
}

.hud-slot-active:hover::after,
.hud-slot-active:hover::before,
.hud-slot-active:focus-visible::after,
.hud-slot-active:focus-visible::before {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
}

/* Interior del slot */
.hud-slot-inner {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #557a46 0%, #3f6a3c 45%, #2b4c2f 100%);
  border: clamp(4px, 0.45vw, 7px) solid rgba(12, 18, 12, 0.95);
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: inset -4px -4px 0 rgba(0, 0, 0, 0.42),
    inset 4px 4px 0 rgba(255, 255, 255, 0.1), 0 10px 0 rgba(0, 0, 0, 0.35),
    0 0 24px rgba(0, 255, 194, 0.1);
  position: relative;
  overflow: hidden;
}

/* Textura de slot */
.hud-slot-inner::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    /* pixel noise */ repeating-linear-gradient(
      0deg,
      transparent,
      transparent 2px,
      rgba(0, 0, 0, 0.12) 2px,
      rgba(0, 0, 0, 0.12) 4px
    ),
    /* subtle "block" grid */
      repeating-linear-gradient(
        90deg,
        rgba(255, 255, 255, 0.05) 0px,
        rgba(255, 255, 255, 0.05) 2px,
        transparent 2px,
        transparent 18px
      ),
    repeating-linear-gradient(
      0deg,
      rgba(0, 0, 0, 0.12) 0px,
      rgba(0, 0, 0, 0.12) 2px,
      transparent 2px,
      transparent 18px
    );
  pointer-events: none;
}

.hud-slot-inner.empty {
  background: linear-gradient(135deg, #2b3b2c 0%, #233424 50%, #182718 100%);
  opacity: 0.65;
}

/* Slot de ayuda especial */
.hud-slot-help .hud-slot-inner {
  background: linear-gradient(135deg, #5a4a1a 0%, #4a3a10 45%, #3a2a08 100%);
  border-color: rgba(255, 193, 7, 0.6);
  box-shadow: inset -4px -4px 0 rgba(0, 0, 0, 0.42),
    inset 4px 4px 0 rgba(255, 255, 255, 0.15), 0 10px 0 rgba(0, 0, 0, 0.35),
    0 0 24px rgba(255, 193, 7, 0.25);
}

.hud-slot-help:hover .hud-slot-inner {
  box-shadow: inset -4px -4px 0 rgba(0, 0, 0, 0.42),
    inset 4px 4px 0 rgba(255, 255, 255, 0.15), 0 10px 0 rgba(0, 0, 0, 0.35),
    0 0 35px rgba(255, 193, 7, 0.45);
}

.help-icon {
  animation: helpPulse 2s ease-in-out infinite;
}

@keyframes helpPulse {
  0%,
  100% {
    filter: drop-shadow(3px 3px 0 rgba(0, 0, 0, 0.35)) brightness(1);
  }
  50% {
    filter: drop-shadow(3px 3px 0 rgba(0, 0, 0, 0.35)) brightness(1.2);
  }
}

/* Icono del slot */
.hud-slot-icon {
  width: 80%;
  height: 80%;
  object-fit: contain;
  image-rendering: pixelated;
  z-index: 1;
  filter: drop-shadow(3px 3px 0 rgba(0, 0, 0, 0.35));
}

@media (max-width: 520px) {
  .hud-grid {
    --hud-gap: 8px;
    --hud-slot: clamp(64px, 14vw, 112px);
    padding: 12px;
  }

  .hud-slot-active::after {
    font-size: 0.5rem;
  }
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
  box-shadow: 0 0 30px rgba(0, 255, 194, 0.3), inset 0 0 20px rgba(0, 0, 0, 0.5);
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
    --hud-slot-size: clamp(44px, 10vw, 64px);
    --hud-gap: 10px;
    max-width: 100%;
  }

  .hud-slot-inner {
    border-width: 4px;
  }

  .hud-slot-icon {
    width: 70%;
    height: 70%;
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
