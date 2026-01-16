<template>
  <div class="app-container">
    <router-view v-if="!authInitializing" />
    <GlobalLoader />
  </div>
</template>

<script setup>
import GlobalLoader from "@/components/GlobalLoader.vue";
import { authInitializing } from "@/services/authInit";
// App principal - renderiza router y loader global
</script>

<style>
/* Estilos globales en style.css */
</style>
