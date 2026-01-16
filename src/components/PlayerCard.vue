<template>
  <div
    :class="[
      'player-card',
      { 'low-lives': player.lives <= 6, 'zero-lives': player.lives === 0 },
    ]"
  >
    <!-- Imagen del jugador a la izquierda -->
    <div
      v-if="player.image_url"
      :class="[
        'player-image-container',
        { 'game-over-image': player.lives === 0 },
      ]"
    >
      <img :src="player.image_url" :alt="displayName" class="player-image" />
      <span v-if="player.lives === 0" class="death-mark">✗</span>
    </div>
    <div
      v-else
      :class="[
        'player-image-placeholder',
        { 'game-over-image': player.lives === 0 },
      ]"
    >
      <span v-if="player.lives === 0" class="death-mark">✗</span>
      <span v-else class="placeholder-icon">
        <CreeperIcon :size="60" />
      </span>
    </div>

    <!-- Contenido a la derecha -->
    <div class="player-content">
      <div class="player-header">
        <h3 class="player-nickname">{{ displayName }}</h3>
        <span v-if="player.lives === 0" class="game-over-badge">GAME OVER</span>
      </div>

      <HeartsBar :lives="player.lives" :max-lives="player.max_lives || 12" />

      <ProfileStatus v-if="player.user_id" :userId="player.user_id" />

      <div v-if="showUpdatedTime" class="updated-time">
        Actualizado: {{ formatDate(player.updated_at) }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";
import HeartsBar from "./HeartsBar.vue";
import CreeperIcon from "./CreeperIcon.vue";
import ProfileStatus from "./ProfileStatus.vue";

const props = defineProps({
  player: {
    type: Object,
    required: true,
  },
  showUpdatedTime: {
    type: Boolean,
    default: false,
  },
});

const displayName = computed(() => {
  const first = props.player?.first_name?.trim?.() || "";
  const last = props.player?.last_name?.trim?.() || "";
  const full = `${first} ${last}`.trim();
  return full || props.player?.nickname || "Jugador";
});

function formatDate(dateString) {
  if (!dateString) return "";
  const date = new Date(dateString);
  return date.toLocaleString("es-ES", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}
</script>

<style scoped>
.player-card {
  background: linear-gradient(
    135deg,
    rgba(0, 0, 0, 0.9) 0%,
    rgba(10, 10, 30, 0.9) 100%
  );
  border: 3px solid #00ffc2;
  border-radius: 12px;
  padding: 16px;
  box-shadow: 0 8px 32px rgba(0, 255, 194, 0.2),
    inset 0 1px 0 rgba(0, 255, 194, 0.1), 0 0 0 1px rgba(0, 0, 0, 0.5);
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  gap: 16px;
}

.player-card::before {
  content: "";
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: radial-gradient(
    circle,
    rgba(0, 255, 194, 0.1) 0%,
    transparent 70%
  );
  opacity: 0;
  transition: opacity 0.4s;
}

.player-card:hover::before {
  opacity: 1;
}

.player-card:hover {
  border-color: #f7418f;
  box-shadow: 0 12px 48px rgba(247, 65, 143, 0.4),
    inset 0 1px 0 rgba(247, 65, 143, 0.2), 0 0 0 1px rgba(0, 0, 0, 0.5);
  transform: translateY(-8px) scale(1.02);
}

@media (hover: none) {
  .player-card:hover {
    transform: none;
  }
}

.player-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.player-card.low-lives {
  border-color: #ffb800;
  box-shadow: 0 8px 32px rgba(255, 184, 0, 0.3),
    inset 0 1px 0 rgba(255, 184, 0, 0.1);
  background: linear-gradient(
    135deg,
    rgba(20, 15, 0, 0.9) 0%,
    rgba(30, 20, 0, 0.9) 100%
  );
}

.player-card.zero-lives {
  border-color: #f7418f;
  box-shadow: 0 8px 32px rgba(247, 65, 143, 0.5),
    inset 0 1px 0 rgba(247, 65, 143, 0.2);
  background: linear-gradient(
    135deg,
    rgba(30, 0, 15, 0.95) 0%,
    rgba(20, 0, 10, 0.95) 100%
  );
  opacity: 0.9;
  filter: grayscale(0.3);
  animation: deathShake 0.6s ease-in-out;
}

@keyframes deathShake {
  0% {
    transform: translateX(0) scale(1);
  }
  10% {
    transform: translateX(-10px) scale(1);
  }
  20% {
    transform: translateX(10px) scale(1);
  }
  30% {
    transform: translateX(-8px) scale(1);
  }
  40% {
    transform: translateX(8px) scale(1);
  }
  50% {
    transform: translateX(-5px) scale(1);
  }
  60% {
    transform: translateX(5px) scale(1);
  }
  70%,
  100% {
    transform: translateX(0) scale(1);
  }
}

.game-over-image {
  position: relative;
  border-color: #f7418f !important;
}

.game-over-image .player-image {
  filter: grayscale(100%) brightness(0.5);
  opacity: 0.6;
}

.game-over-image .placeholder-icon {
  filter: grayscale(100%) brightness(0.5);
  opacity: 0.3;
}

.death-mark {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 4rem;
  color: #f7418f;
  text-shadow: 0 0 20px rgba(247, 65, 143, 1), 0 0 30px rgba(247, 65, 143, 0.8);
  font-weight: bold;
  animation: deathPulse 0.8s ease-in-out infinite;
  z-index: 10;
}

@keyframes deathPulse {
  0%,
  100% {
    transform: translate(-50%, -50%) scale(1);
    opacity: 1;
  }
  50% {
    transform: translate(-50%, -50%) scale(1.15);
    opacity: 0.9;
  }
}

/* IMAGEN DEL JUGADOR */
.player-image-container {
  width: 160px;
  height: 160px;
  min-width: 160px;
  border: 2px solid #00ffc2;
  border-radius: 8px;
  overflow: hidden;
  background: rgba(0, 0, 0, 0.6);
  position: relative;
}

.player-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
  transition: transform 0.4s;
}

.player-card:hover .player-image {
  transform: scale(1.05);
}

.player-image-placeholder {
  width: 160px;
  height: 160px;
  min-width: 160px;
  border: 2px dashed #00ffc2;
  border-radius: 8px;
  background: rgba(0, 255, 194, 0.05);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.placeholder-icon {
  opacity: 0.9;
  transform: translateZ(0);
  animation: creeperCardBob 1.6s ease-in-out infinite;
}

@keyframes creeperCardBob {
  0%,
  100% {
    transform: translateY(0);
    filter: brightness(1);
  }
  50% {
    transform: translateY(-3px);
    filter: brightness(1.08);
  }
}

.player-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  margin-bottom: 0;
}

.player-nickname {
  font-family: "Press Start 2P", monospace;
  font-size: 1rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.8), 0 2px 4px rgba(0, 0, 0, 0.5);
  margin: 0;
  letter-spacing: 1px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 100%;
}

.game-over-badge {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #fff;
  background: linear-gradient(135deg, #f7418f 0%, #d6006e 100%);
  padding: 6px 12px;
  border: 2px solid #fff;
  border-radius: 4px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.8);
  box-shadow: 0 0 20px rgba(247, 65, 143, 0.8),
    inset 0 1px 0 rgba(255, 255, 255, 0.3);
  animation: gameOverBlink 0.8s infinite;
}

@keyframes gameOverBlink {
  0%,
  40%,
  100% {
    opacity: 1;
    transform: scale(1);
  }
  20%,
  60% {
    opacity: 0.7;
    transform: scale(0.95);
  }
}

.player-status {
  display: inline-flex;
  width: fit-content;
  align-items: center;
  gap: 6px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  border: 2px solid;
  border-radius: 6px;
  padding: 6px 10px;
  margin-top: 4px;
  box-shadow: inset 0 -3px 0 rgba(0, 0, 0, 0.4), 0 0 12px currentColor;
  animation: statusPulse 2s ease-in-out infinite;
}

.status-indicator {
  font-size: 0.5rem;
  animation: statusBlink 1.5s ease-in-out infinite;
  filter: drop-shadow(0 0 4px currentColor);
}

@keyframes statusPulse {
  0%, 100% {
    box-shadow: inset 0 -3px 0 rgba(0, 0, 0, 0.4), 0 0 12px currentColor;
  }
  50% {
    box-shadow: inset 0 -3px 0 rgba(0, 0, 0, 0.4), 0 0 20px currentColor;
  }
}

@keyframes statusBlink {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.updated-time {
  margin-top: 12px;
  font-size: 0.75rem;
  color: #888;
  font-family: "Press Start 2P", monospace;
}

@media (max-width: 768px) {
  .player-card {
    padding: 12px;
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }

  .player-image-container,
  .player-image-placeholder {
    width: min(240px, 100%);
    height: auto;
    aspect-ratio: 1 / 1;
    min-width: unset;
    margin: 0 auto;
  }

  .player-header {
    flex-direction: column;
    align-items: center;
    text-align: center;
  }

  .player-nickname {
    font-size: 0.85rem;
    white-space: normal;
    overflow: visible;
    text-overflow: unset;
  }

  .game-over-badge {
    font-size: 0.6rem;
  }
}

@media (max-width: 420px) {
  .player-card {
    padding: 10px;
  }

  .player-nickname {
    font-size: 0.78rem;
  }

  .game-over-badge {
    font-size: 0.55rem;
    padding: 6px 10px;
  }
}
</style>
