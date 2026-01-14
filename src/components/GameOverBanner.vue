<template>
  <Teleport to="body">
    <Transition name="gameover">
      <div
        v-if="show"
        class="go-overlay"
        role="status"
        aria-live="assertive"
        @click.self="$emit('close')"
      >
        <div class="go-panel">
          <div class="go-watermark" aria-hidden="true">
            <CreeperIcon :size="320" />
          </div>

          <div class="go-header">
            <div class="go-creeper" aria-hidden="true">
              <CreeperIcon :size="110" />
            </div>
            <div class="go-title">GAME OVER</div>
            <div class="go-creeper" aria-hidden="true">
              <CreeperIcon :size="110" />
            </div>
          </div>

          <div class="go-lines">
            <div class="go-player">
              <span class="go-label">JUGADOR:</span>
              <span class="go-value">{{ playerName || "DESCONOCIDO" }}</span>
            </div>
            <div class="go-cause">
              <span class="go-label">CAUSA:</span>
              <span class="go-value">{{ cause || "SIN DATOS" }}</span>
            </div>
          </div>

          <div class="go-hint">(click para cerrar)</div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import CreeperIcon from "@/components/CreeperIcon.vue";

defineProps({
  show: { type: Boolean, required: true },
  playerName: { type: String, default: "" },
  cause: { type: String, default: "" },
});

defineEmits(["close"]);
</script>

<style scoped>
.go-overlay {
  position: fixed;
  inset: 0;
  z-index: 10050;
  display: grid;
  place-items: center;
  padding: 18px;

  background: radial-gradient(
      circle at 50% 30%,
      rgba(255, 0, 0, 0.12) 0%,
      rgba(0, 0, 0, 0.75) 55%
    ),
    rgba(0, 0, 0, 0.72);
  backdrop-filter: blur(2px);
}

.go-panel {
  width: min(980px, 100%);
  background: rgba(18, 18, 18, 0.94);
  border: 4px solid rgba(0, 0, 0, 0.88);
  border-radius: 10px;
  padding: 28px 26px 20px;

  box-shadow: 0 24px 80px rgba(0, 0, 0, 0.7),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 0 0 6px rgba(0, 0, 0, 0.55);

  position: relative;
  overflow: hidden;
}

.go-watermark {
  position: absolute;
  inset: -10px;
  display: grid;
  place-items: center;
  opacity: 0.14;
  transform: rotate(-8deg);
  filter: blur(0.2px) saturate(1.05);
  pointer-events: none;
}

.go-panel::before {
  content: "";
  position: absolute;
  inset: 10px;
  border: 2px solid rgba(255, 255, 255, 0.06);
  border-radius: 8px;
  pointer-events: none;
}

.go-header {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  margin-bottom: 14px;
}

.go-creeper {
  transform: translateZ(0);
  animation: goCreeperBob 1.05s ease-in-out infinite;
  filter: drop-shadow(0 6px 0 rgba(0, 0, 0, 0.75))
    drop-shadow(0 0 16px rgba(63, 191, 63, 0.35));
}

.go-creeper:nth-child(3) {
  animation-delay: 120ms;
}

.go-title {
  font-family: "Press Start 2P", monospace;
  text-align: center;
  font-size: clamp(2.1rem, 5.2vw, 3.8rem);
  letter-spacing: 2px;
  color: #ff3b3b;
  text-shadow: 0 3px 0 rgba(0, 0, 0, 0.85), 0 0 18px rgba(255, 59, 59, 0.55);

  animation: goFlicker 1.2s ease-in-out infinite;
}

.go-lines {
  display: grid;
  gap: 10px;
}

.go-player,
.go-cause {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: 10px;
  align-items: start;
}

.go-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.92rem;
  color: rgba(255, 255, 255, 0.8);
}

.go-value {
  font-family: "Press Start 2P", monospace;
  font-size: 0.92rem;
  color: #ffffff;
  line-height: 1.5;
  overflow-wrap: anywhere;
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.65);
}

.go-hint {
  margin-top: 14px;
  text-align: center;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: rgba(255, 255, 255, 0.55);
}

/* Animación de entrada/salida */
.gameover-enter-active {
  animation: goIn 420ms ease-out;
}

.gameover-leave-active {
  animation: goOut 320ms ease-in;
}

@keyframes goIn {
  from {
    opacity: 0;
    transform: translateY(-14px) scale(0.98);
  }
  60% {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  80% {
    transform: translateY(0) scale(1);
  }
  100% {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes goOut {
  from {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateY(10px) scale(0.98);
  }
}

@keyframes goFlicker {
  0%,
  100% {
    filter: brightness(1);
  }
  50% {
    filter: brightness(1.12);
  }
}

@keyframes goCreeperBob {
  0%,
  100% {
    transform: translateY(0) scale(1);
  }
  50% {
    transform: translateY(-4px) scale(1.02);
  }
}

@media (max-width: 520px) {
  .go-header {
    grid-template-columns: 1fr;
    justify-items: center;
  }

  .go-creeper {
    display: none;
  }

  .go-label,
  .go-value {
    font-size: 0.7rem;
  }

  .go-player,
  .go-cause {
    grid-template-columns: 1fr;
  }
}
</style>
