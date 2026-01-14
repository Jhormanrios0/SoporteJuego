<template>
  <svg
    class="creeper"
    :width="size"
    :height="size"
    viewBox="0 0 64 64"
    preserveAspectRatio="xMidYMid meet"
    shape-rendering="crispEdges"
    role="img"
    aria-label="Creeper"
  >
    <!-- Fondo (verde creeper) -->
    <rect x="0" y="0" width="64" height="64" rx="6" fill="#3fbf3f" />

    <!-- Textura simple tipo pixel -->
    <g opacity="0.22">
      <rect x="6" y="6" width="10" height="10" fill="#2aa62a" />
      <rect x="18" y="10" width="8" height="8" fill="#4dd84d" />
      <rect x="44" y="8" width="12" height="12" fill="#2aa62a" />
      <rect x="10" y="44" width="12" height="12" fill="#2aa62a" />
      <rect x="38" y="42" width="10" height="10" fill="#4dd84d" />
    </g>

    <!-- Cara (bloques estilo pixel) -->
    <g fill="#0b0b0b">
      <!-- ojos -->
      <rect x="12" y="14" width="16" height="16" />
      <rect x="36" y="14" width="16" height="16" />

      <!-- nariz -->
      <rect x="28" y="30" width="8" height="8" />

      <!-- boca -->
      <rect x="20" y="38" width="8" height="18" />
      <rect x="36" y="38" width="8" height="18" />
      <rect x="24" y="40" width="16" height="10" />
    </g>

    <!-- Bisel interior -->
    <rect
      x="3"
      y="3"
      width="58"
      height="58"
      rx="5"
      fill="none"
      stroke="rgba(255,255,255,0.14)"
      stroke-width="2"
    />
  </svg>
</template>

<script setup>
defineProps({
  size: { type: Number, default: 44 },
});
</script>

<style scoped>
.creeper {
  image-rendering: pixelated;
  display: block;
}
</style>
