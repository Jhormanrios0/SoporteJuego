<template>
  <div class="profile-view">
    <header class="profile-header">
      <button class="back-btn" type="button" @click="goHome">
        <ArrowLeft :size="16" />
        Home
      </button>

      <h1 class="profile-title">PERFIL</h1>

      <div
        v-if="authUser"
        ref="profileMenuEl"
        class="profile-menu"
        @keydown.esc.stop.prevent="closeProfileMenu"
      >
        <button
          class="profile-button"
          type="button"
          aria-label="Menú de perfil"
          aria-haspopup="menu"
          :aria-expanded="profileMenuOpen ? 'true' : 'false'"
          @click.stop="toggleProfileMenu"
          @keydown.enter.stop.prevent="toggleProfileMenu"
          @keydown.space.stop.prevent="toggleProfileMenu"
        >
          <span class="profile-avatar">
            <img
              v-if="myPlayer?.image_url"
              :src="myPlayer.image_url"
              :alt="userLabel"
              class="profile-avatar-img"
            />
            <span v-else class="profile-avatar-fallback">
              <User :size="18" />
            </span>
          </span>

          <span class="profile-meta">
            <span class="profile-name">{{ userLabel }}</span>
            <span v-if="profileNeedsRegister" class="profile-sub">
              Registro pendiente
            </span>
          </span>

          <span class="profile-caret" aria-hidden="true">▾</span>
        </button>

        <Transition name="pixel-pop">
          <div
            v-show="profileMenuOpen"
            class="profile-dropdown"
            role="menu"
            aria-label="Opciones de perfil"
          >
            <button
              class="profile-dropdown-item"
              type="button"
              role="menuitem"
              @click="handleProfileMenuProfile"
            >
              Perfil
            </button>
            <button
              class="profile-dropdown-item danger"
              type="button"
              role="menuitem"
              @click="handleProfileMenuLogout"
            >
              Cerrar sesión
            </button>
          </div>
        </Transition>
      </div>
    </header>

    <main class="profile-content">
      <div class="profile-panel">
        <p class="profile-placeholder">PERFIL</p>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useRouter } from "vue-router";
import { ArrowLeft, User } from "lucide-vue-next";
import {
  getMyPlayer,
  getSession,
  supabase,
  userLogout,
} from "@/services/supabase";

const router = useRouter();

// Auth usuario
const authUser = ref(null);
const myPlayer = ref(null);
const authLoading = ref(false);
const authError = ref("");
let authSubscription = null;

// Menú de perfil (dropdown)
const profileMenuOpen = ref(false);
const profileMenuEl = ref(null);

const profileNeedsRegister = computed(
  () => !!authUser.value && !myPlayer.value
);

const userLabel = computed(() => {
  const first = myPlayer.value?.first_name?.trim?.() || "";
  const last = myPlayer.value?.last_name?.trim?.() || "";
  const full = `${first} ${last}`.trim();
  if (full) return full;
  return authUser.value?.email || "Jugador";
});

async function loadAuth() {
  authError.value = "";
  authLoading.value = true;
  try {
    const session = await getSession();
    authUser.value = session?.user || null;
    if (authUser.value) {
      try {
        myPlayer.value = await getMyPlayer();
      } catch {
        myPlayer.value = null;
      }
    } else {
      myPlayer.value = null;
    }
  } catch (e) {
    authError.value = e?.message || "No se pudo cargar la sesión";
  } finally {
    authLoading.value = false;
  }
}

function toggleProfileMenu() {
  profileMenuOpen.value = !profileMenuOpen.value;
}

function closeProfileMenu() {
  profileMenuOpen.value = false;
}

function onDocumentClick(e) {
  if (!profileMenuOpen.value) return;
  const container = profileMenuEl.value;
  if (!container) return;
  if (container.contains(e.target)) return;
  closeProfileMenu();
}

function handleProfileMenuProfile() {
  closeProfileMenu();
  router.push({ name: "profile" });
}

async function handleProfileMenuLogout() {
  closeProfileMenu();
  authError.value = "";
  authLoading.value = true;
  try {
    await userLogout();
    authUser.value = null;
    myPlayer.value = null;
    router.push({ name: "public" });
  } catch (e) {
    authError.value = e?.message || "No se pudo cerrar sesión";
  } finally {
    authLoading.value = false;
  }
}

function onKeydown(e) {
  if (e.key === "Escape" && profileMenuOpen.value) {
    closeProfileMenu();
  }
}

function goHome() {
  router.push({ name: "public" });
}

onMounted(async () => {
  window.addEventListener("keydown", onKeydown);
  document.addEventListener("click", onDocumentClick);

  await loadAuth();

  authSubscription = supabase.auth.onAuthStateChange(
    async (_event, session) => {
      authUser.value = session?.user || null;
      if (authUser.value) {
        try {
          myPlayer.value = await getMyPlayer();
        } catch {
          myPlayer.value = null;
        }
      } else {
        myPlayer.value = null;
      }
    }
  ).data.subscription;
});

onUnmounted(() => {
  window.removeEventListener("keydown", onKeydown);
  document.removeEventListener("click", onDocumentClick);
  if (authSubscription) authSubscription.unsubscribe();
});
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

.profile-view::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.15),
    rgba(0, 0, 0, 0.15) 1px,
    transparent 1px,
    transparent 2px
  );
  pointer-events: none;
  z-index: 1;
}

.profile-header {
  max-width: 1100px;
  margin: 0 auto 18px;
  position: relative;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.profile-menu {
  position: relative;
  display: inline-block;
  max-width: min(320px, calc(100% - 24px));
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
  background: rgba(0, 0, 0, 0.7);
  border: 3px solid rgba(0, 255, 194, 0.6);
  border-radius: 12px;
  padding: 18px;
}

.profile-placeholder {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  color: rgba(255, 255, 255, 0.85);
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
}
</style>
