<template>
  <div class="profile-view">
    <header class="profile-header">
      <button class="back-btn" type="button" @click="goBack">
        <ArrowLeft :size="16" />
        Volver
      </button>
      <h1 class="profile-title">PERFIL DE JUGADOR</h1>
    </header>
    <main class="profile-content">
      <div class="profile-panel">
        <div v-if="loading" class="profile-empty">
          <p class="profile-empty-title">Cargando…</p>
        </div>
        <div v-else-if="!player" class="profile-empty">
          <p class="profile-empty-title">No encontrado</p>
          <p class="profile-empty-sub">No se encontró el jugador solicitado.</p>
        </div>
        <div v-else class="profile-sections">
          <div class="profile-card">
            <div class="profile-hero">
              <div class="avatar-frame">
                <img
                  v-if="player.image_url"
                  :src="player.image_url"
                  :alt="fullName"
                  class="avatar-img"
                />
                <div v-else class="avatar-fallback">
                  <User :size="44" />
                </div>
              </div>
              <div class="identity">
                <div class="identity-tag">JUGADOR</div>
                <div class="identity-name">{{ fullName }}</div>
                <div class="identity-sub">{{ player.nickname }}</div>
                <ProfileStatus :userId="player.user_id" />
              </div>
            </div>
          </div>
          <div class="profile-hud-section">
            <HUD :readonly="true" :playerId="player.id" />
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ArrowLeft, User } from "lucide-vue-next";
import ProfileStatus from "@/components/ProfileStatus.vue";
import HUD from "@/components/HUD.vue";
import { getPlayerById } from "@/services/supabase";

const route = useRoute();
const router = useRouter();
const player = ref(null);
const loading = ref(true);

const fullName = computed(() => {
  const first = player.value?.first_name?.trim?.() || "";
  const last = player.value?.last_name?.trim?.() || "";
  return `${first} ${last}`.trim() || player.value?.nickname || "Jugador";
});

async function fetchPlayer() {
  loading.value = true;
  player.value = null;
  const id = route.params.id;
  if (!id) {
    loading.value = false;
    return;
  }
  try {
    player.value = await getPlayerById(id);
  } catch {
    player.value = null;
  } finally {
    loading.value = false;
  }
}

function goBack() {
  router.back();
}

onMounted(fetchPlayer);
</script>

<style scoped>
.profile-view {
  min-height: 100vh;
  padding: clamp(16px, 2.2vw, 26px) clamp(12px, 3vw, 30px);
  background: radial-gradient(
      circle at 20% 50%,
      rgba(247, 65, 143, 0.15) 0%,
      transparent 50%
    ),
    radial-gradient(
      circle at 80% 80%,
      rgba(0, 255, 194, 0.1) 0%,
      transparent 50%
    ),
    linear-gradient(180deg, #000000 0%, #0a0020 50%, #000000 100%);
  position: relative;
}

.profile-header {
  max-width: 1100px;
  margin: 0 auto 18px;
  position: relative;
  z-index: 5;
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.profile-menu {
  position: relative;
  display: inline-block;
  max-width: min(320px, calc(100% - 24px));
  z-index: 1006;
}

.profile-button {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  max-width: min(320px, calc(100vw - 24px));
  padding: 10px 12px;
  border: 2px solid rgba(0, 255, 194, 0.7);
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.65);
  box-shadow: 0 10px 28px rgba(0, 0, 0, 0.35),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06);
  cursor: pointer;
  color: rgba(255, 255, 255, 0.92);
}

.profile-button:hover {
  filter: brightness(1.08);
}

.profile-button:active {
  transform: translateY(2px);
}

.profile-avatar {
  width: 40px;
  height: 40px;
  border-radius: 10px;
  border: 2px solid rgba(0, 255, 194, 0.6);
  overflow: hidden;
  background: rgba(0, 0, 0, 0.6);
  display: grid;
  place-items: center;
  flex: 0 0 auto;
}

.profile-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.profile-avatar-fallback {
  color: #00ffc2;
  filter: drop-shadow(0 0 8px rgba(0, 255, 194, 0.45));
}

.profile-meta {
  display: grid;
  gap: 4px;
  min-width: 0;
  text-align: left;
}

.profile-name {
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.55);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 210px;
}

.profile-sub {
  font-family: "Press Start 2P", monospace;
  font-size: 0.52rem;
  color: #ffda79;
}

.profile-caret {
  margin-left: auto;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: rgba(0, 255, 194, 0.95);
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.55);
  transition: transform 140ms ease;
}

.profile-button[aria-expanded="true"] .profile-caret {
  transform: rotate(180deg);
}

.profile-dropdown {
  position: absolute;
  top: calc(100% + 10px);
  right: 0;
  min-width: 100%;
  border: 2px solid rgba(0, 255, 194, 0.55);
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.82);
  box-shadow: 0 14px 32px rgba(0, 0, 0, 0.45),
    inset 0 0 0 2px rgba(255, 255, 255, 0.05);
  padding: 10px;
  z-index: 1007;
}

.profile-dropdown::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: 12px;
  pointer-events: none;
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.12),
    rgba(0, 0, 0, 0.12) 2px,
    transparent 2px,
    transparent 4px
  );
  opacity: 0.45;
}

.profile-dropdown > * {
  position: relative;
  z-index: 1;
}

.profile-dropdown-item {
  width: 100%;
  text-align: left;
  border: 2px solid rgba(0, 255, 194, 0.45);
  border-radius: 10px;
  background: rgba(0, 0, 0, 0.55);
  color: rgba(255, 255, 255, 0.92);
  padding: 10px 12px;
  cursor: pointer;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  text-transform: uppercase;
  letter-spacing: 0.02em;
}

.profile-dropdown-item + .profile-dropdown-item {
  margin-top: 10px;
}

.profile-dropdown-item:hover {
  filter: brightness(1.1);
}

.profile-dropdown-item:active {
  transform: translateY(2px);
}

.profile-dropdown-item.danger {
  border-color: rgba(247, 65, 143, 0.65);
  color: #ffd1e6;
  box-shadow: inset 0 0 0 2px rgba(247, 65, 143, 0.12);
}

.pixel-pop-enter-active {
  animation: pixelPopIn 180ms cubic-bezier(0.2, 0.9, 0.2, 1) both;
  transform-origin: top right;
}

.pixel-pop-leave-active {
  animation: pixelPopOut 120ms ease-in both;
  transform-origin: top right;
}

@keyframes pixelPopIn {
  0% {
    opacity: 0;
    transform: translateY(-6px) scale(0.98);
    filter: brightness(0.9);
  }
  70% {
    opacity: 1;
    transform: translateY(0) scale(1.02);
    filter: brightness(1.1);
  }
  100% {
    opacity: 1;
    transform: translateY(0) scale(1);
    filter: brightness(1);
  }
}

@keyframes pixelPopOut {
  0% {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  100% {
    opacity: 0;
    transform: translateY(-4px) scale(0.98);
  }
}

.profile-title {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(1.1rem, 2.6vw, 1.8rem);
  margin: 0;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.8);
}

.back-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: 2px solid rgba(0, 0, 0, 0.95);
  border-radius: 6px;
  padding: 10px 12px;
  font-weight: 900;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  cursor: pointer;
  background: rgba(64, 64, 64, 0.95);
  color: #fff;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7), 0 10px 28px rgba(0, 0, 0, 0.35);
}

.profile-content {
  max-width: 1100px;
  margin: 0 auto;
  position: relative;
  z-index: 2;
}

.profile-panel {
  background: rgba(0, 0, 0, 0.72);
  border: 3px solid rgba(0, 255, 194, 0.6);
  border-radius: 12px;
  padding: clamp(14px, 2.2vw, 22px);
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45),
    inset 0 0 0 2px rgba(255, 255, 255, 0.05);
}

.profile-card {
  display: grid;
  gap: 16px;
}

.profile-sections {
  display: grid;
  gap: 18px;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.22s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.profile-hero {
  display: grid;
  grid-template-columns: minmax(180px, 240px) 1fr;
  gap: clamp(14px, 2.4vw, 26px);
  align-items: center;
}

.avatar-frame {
  position: relative;
  width: 100%;
  aspect-ratio: 1 / 1;
  border-radius: 14px;
  border: 3px solid rgba(0, 255, 194, 0.65);
  background: linear-gradient(180deg, rgba(0, 0, 0, 0.7), rgba(0, 0, 0, 0.9));
  overflow: hidden;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -10px 0 rgba(0, 0, 0, 0.55), 0 18px 40px rgba(0, 0, 0, 0.45);
}

.avatar-frame::before {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(
      135deg,
      rgba(0, 255, 194, 0.08) 0%,
      transparent 40%
    ),
    repeating-linear-gradient(
      0deg,
      rgba(0, 0, 0, 0.15),
      rgba(0, 0, 0, 0.15) 2px,
      transparent 2px,
      transparent 4px
    );
  pointer-events: none;
  opacity: 0.8;
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
  transform: scale(1.01);
}

.avatar-fallback {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  color: rgba(0, 255, 194, 0.95);
  filter: drop-shadow(0 0 10px rgba(0, 255, 194, 0.55));
}

.avatar-edit {
  position: absolute;
  bottom: 10px;
  right: 10px;
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 2px solid rgba(255, 218, 121, 0.9);
  background: rgba(0, 0, 0, 0.72);
  color: #ffda79;
  cursor: pointer;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.05),
    inset 0 -6px 0 rgba(0, 0, 0, 0.7), 0 10px 26px rgba(0, 0, 0, 0.35);
  display: grid;
  place-items: center;
  transition: transform 120ms ease, filter 120ms ease;
  z-index: 2;
}

.avatar-edit:hover {
  filter: brightness(1.12);
}

.avatar-edit:active {
  transform: translateY(2px);
}

.avatar-edit:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.avatar-busy {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  display: grid;
  place-items: center;
  z-index: 1;
}

.avatar-busy-text {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.65);
  animation: blink 1s steps(2, jump-none) infinite;
}

@keyframes blink {
  0%,
  48% {
    opacity: 1;
  }
  52%,
  100% {
    opacity: 0.4;
  }
}

.identity {
  display: grid;
  gap: 10px;
}

.identity-tag {
  display: inline-flex;
  width: fit-content;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: rgba(255, 255, 255, 0.92);
  background: rgba(247, 65, 143, 0.25);
  border: 2px solid rgba(247, 65, 143, 0.55);
  border-radius: 10px;
  padding: 8px 10px;
  box-shadow: inset 0 -6px 0 rgba(0, 0, 0, 0.55);
}

.identity-name {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(1.05rem, 2.4vw, 1.55rem);
  color: #00ffc2;
  text-shadow: 0 0 12px rgba(0, 255, 194, 0.65);
  line-height: 1.25;
}

.identity-sub {
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: rgba(255, 255, 255, 0.75);
}

.identity-hint {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.7);
  line-height: 1.45;
}

.identity-warn {
  margin-top: 6px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  color: #ffda79;
  line-height: 1.5;
  background: rgba(0, 0, 0, 0.55);
  border: 2px solid rgba(255, 218, 121, 0.55);
  border-radius: 12px;
  padding: 12px;
  box-shadow: inset 0 -8px 0 rgba(0, 0, 0, 0.6);
}

.identity-error {
  margin-top: 6px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  color: #ffd1e6;
  line-height: 1.5;
  background: rgba(0, 0, 0, 0.55);
  border: 2px solid rgba(247, 65, 143, 0.55);
  border-radius: 12px;
  padding: 12px;
  box-shadow: inset 0 -8px 0 rgba(0, 0, 0, 0.6);
}

.profile-empty {
  display: grid;
  gap: 12px;
  justify-items: center;
  padding: 18px;
  text-align: center;
}

.profile-empty-title {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.65);
}

.profile-empty-sub {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: rgba(255, 255, 255, 0.75);
  line-height: 1.5;
}

.file-input {
  display: none;
}

.user-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  border: 2px solid rgba(0, 0, 0, 0.95);
  border-radius: 6px;
  padding: 10px 14px;
  font-weight: 900;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  cursor: pointer;
  background: rgba(0, 255, 194, 0.18);
  color: rgba(255, 255, 255, 0.92);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7), 0 10px 28px rgba(0, 0, 0, 0.35);
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
}

.user-btn.secondary {
  background: rgba(255, 218, 121, 0.12);
  color: #ffda79;
}

.profile-book-section {
  margin-top: 3rem;
  padding-top: 2rem;
  border-top: 2px solid rgba(0, 255, 194, 0.3);
  display: flex;
  justify-content: center;
}

.profile-hud-section {
  margin-top: 3rem;
  padding-top: 2rem;
  border-top: 2px solid rgba(0, 255, 194, 0.3);
  display: flex;
  justify-content: center;
  width: 100%;
  position: relative;
  z-index: 20;
  overflow: visible;
}

@media (max-width: 520px) {
  .profile-header {
    flex-direction: column;
    align-items: stretch;
  }

  .profile-title {
    text-align: center;
  }

  .profile-menu {
    align-self: center;
  }

  .profile-hero {
    grid-template-columns: 1fr;
  }
}
</style>
