<template>
  <div v-if="visible" class="global-loader" aria-hidden="false">
    <div class="loader-card">
      <div class="spinner" />
      <div class="loader-text">Cargando…</div>
    </div>
  </div>
</template>

<script setup>
import { computed } from "vue";
import { authInitializing } from "@/services/authInit";

const visible = computed(() => authInitializing.value === true);
</script>

<style scoped>
.global-loader {
  position: fixed;
  inset: 0;
  display: grid;
  place-items: center;
  background: rgba(0, 0, 0, 0.98);
  z-index: 2147483647;
}
.loader-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px 26px;
  border-radius: 12px;
  background: linear-gradient(
    180deg,
    rgba(0, 0, 0, 0.9),
    rgba(10, 10, 30, 0.95)
  );
  border: 2px solid rgba(0, 255, 194, 0.5);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.6);
}
.spinner {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  border: 4px solid rgba(0, 255, 194, 0.2);
  border-top-color: #00ffc2;
  animation: spin 1s linear infinite;
}
.loader-text {
  font-family: "Press Start 2P", monospace;
  color: #00ffc2;
  font-size: 0.7rem;
}
@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
