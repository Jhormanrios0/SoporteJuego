<template>
  <div class="hearts-container">
    <!-- Contador numérico -->
    <span class="hearts-counter">{{ lives }}/{{ maxLives }}</span>

    <!-- Corazones visuales -->
    <div class="hearts-bar">
      <img
        v-for="i in maxLives"
        :key="i"
        :src="i <= lives ? '/hearts/full.svg' : '/hearts/empty.svg'"
        :alt="i <= lives ? 'Vida' : 'Vida perdida'"
        :class="['heart-pixel', { 'heart-lost': i > lives }]"
        :style="i <= lives ? getHeartColor(i) : {}"
      />
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  lives: {
    type: Number,
    required: true,
  },
  maxLives: {
    type: Number,
    default: 12,
  },
});

function getHeartColor(heartIndex) {
  // Si tiene todas las vidas (12), todos los corazones rojos
  if (props.lives === props.maxLives) {
    return { filter: "hue-rotate(0deg) saturate(1.2)" };
  }

  // Si tiene menos vidas, gradiente de colores
  // 12-10 vidas: rojo
  // 9-7 vidas: naranja
  // 6-4 vidas: amarillo
  // 3-1 vidas: verde/cyan

  const percentage = props.lives / props.maxLives;

  if (percentage >= 0.75) {
    // 9-12 vidas: rojo
    return { filter: "hue-rotate(0deg) saturate(1.2)" };
  } else if (percentage >= 0.5) {
    // 6-8 vidas: naranja
    return { filter: "hue-rotate(-15deg) saturate(1.3) brightness(1.1)" };
  } else if (percentage >= 0.25) {
    // 3-5 vidas: amarillo
    return { filter: "hue-rotate(-45deg) saturate(1.4) brightness(1.2)" };
  } else {
    // 1-2 vidas: cyan/verde
    return { filter: "hue-rotate(120deg) saturate(1.5) brightness(1.1)" };
  }
}
</script>

<style scoped>
.hearts-container {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hearts-counter {
  font-family: "Press Start 2P", monospace;
  font-size: 1rem;
  color: #00ff88;
  text-shadow: 0 0 8px rgba(0, 255, 136, 0.8);
  min-width: 80px;
}

.hearts-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  max-width: 164px;
}

.heart-pixel {
  width: 24px;
  height: 24px;
  image-rendering: pixelated;
  image-rendering: crisp-edges;
  transition: all 0.3s ease;
}

.heart-pixel.heart-lost {
  opacity: 0.3;
  filter: grayscale(100%);
}

.heart-pixel:not(.heart-lost) {
  animation: heartbeat 2s ease-in-out infinite;
}

@keyframes heartbeat {
  0%,
  100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

@media (max-width: 768px) {
  .hearts-container {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .hearts-counter {
    font-size: 0.875rem;
  }

  .heart-pixel {
    width: 20px;
    height: 20px;
  }
}
</style>
