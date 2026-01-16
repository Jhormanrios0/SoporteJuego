<template>
  <div class="vip-profile-view">
    <header class="profile-header">
      <button class="back-btn" type="button" @click="goAdmin">
        <ArrowLeft :size="16" />
        Panel
      </button>

      <h1 class="profile-title">PERFIL VIP</h1>

      <div
        v-if="authUser && isAdmin"
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
              v-if="adminProfile?.avatar_url"
              :src="adminProfile.avatar_url"
              :alt="adminLabel"
              class="profile-avatar-img"
            />
            <span v-else class="profile-avatar-fallback">VIP</span>
          </span>

          <span class="profile-meta">
            <span class="profile-name">{{ adminLabel }}</span>
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
        <div v-if="authLoading" class="profile-empty">
          <p class="profile-empty-title">CARGANDO…</p>
        </div>

        <div v-else-if="!authUser" class="profile-empty">
          <p class="profile-empty-title">SIN SESIÓN</p>
          <p class="profile-empty-sub">
            Inicia sesión como VIP para editar tu perfil.
          </p>
          <button class="user-btn" type="button" @click="goAdmin">
            Ir a Admin
          </button>
        </div>

        <div v-else-if="!isAdmin" class="profile-empty">
          <p class="profile-empty-title">NO AUTORIZADO</p>
          <p class="profile-empty-sub">
            Esta página es solo para el VIP/Admin.
          </p>
          <button class="user-btn" type="button" @click="goHome">
            Ir a Home
          </button>
        </div>

        <div v-else class="profile-card">
          <div class="profile-hero">
            <div
              class="avatar-frame"
              :data-busy="isUploading ? 'true' : 'false'"
            >
              <img
                v-if="activeAvatarUrl"
                :src="activeAvatarUrl"
                :alt="adminLabel"
                class="avatar-img"
              />
              <div v-else class="avatar-fallback">VIP</div>

              <button
                class="avatar-edit"
                type="button"
                :disabled="isUploading"
                @click="pickNewAvatar"
                @keydown.enter.prevent="pickNewAvatar"
                @keydown.space.prevent="pickNewAvatar"
                aria-label="Cambiar imagen VIP"
                title="Cambiar imagen"
              >
                <Pencil :size="18" />
              </button>

              <div v-if="isUploading" class="avatar-busy" aria-hidden="true">
                <span class="avatar-busy-text">Cargando…</span>
              </div>
            </div>

            <div class="identity">
              <div class="identity-tag">VIP / ADMIN</div>
              <div class="identity-name">{{ adminLabel }}</div>
              <div class="identity-sub">{{ authUser?.email }}</div>

              <div v-if="saveError" class="identity-error">
                {{ saveError }}
              </div>
            </div>
          </div>

          <div class="vip-form">
            <label class="vip-label">Nombre VIP</label>
            <input
              v-model="vipName"
              class="vip-input"
              type="text"
              maxlength="40"
              placeholder="Nombre para mostrar"
            />

            <div class="vip-actions">
              <button
                class="user-btn"
                type="button"
                :disabled="isSaving || isUploading"
                @click="saveName"
              >
                {{ isSaving ? "GUARDANDO…" : "GUARDAR" }}
              </button>
            </div>
          </div>

          <input
            ref="fileInputEl"
            class="file-input"
            type="file"
            accept="image/*"
            @change="onFileSelected"
          />
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useRouter } from "vue-router";
import { ArrowLeft, Pencil } from "lucide-vue-next";
import {
  getMyProfile,
  getSession,
  replaceMyProfileAvatar,
  updateMyProfile,
  userLogout,
  supabase,
} from "@/services/supabase";

const router = useRouter();

const authUser = ref(null);
const adminProfile = ref(null);
const isAdmin = ref(false);
const authLoading = ref(false);
let authSubscription = null;

const fileInputEl = ref(null);
const previewUrl = ref("");
const isUploading = ref(false);

const vipName = ref("");
const isSaving = ref(false);
const saveError = ref("");

// Menú de perfil (dropdown)
const profileMenuOpen = ref(false);
const profileMenuEl = ref(null);

const adminLabel = computed(() => {
  const name = (adminProfile.value?.display_name || vipName.value || "").trim();
  return name || authUser.value?.email || "VIP";
});

const activeAvatarUrl = computed(
  () => previewUrl.value || adminProfile.value?.avatar_url || ""
);

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
  // ya estamos en perfil VIP
}

async function handleProfileMenuLogout() {
  closeProfileMenu();
  await logout();
}

function goHome() {
  router.push({ name: "public" });
}

function goAdmin() {
  router.push({ name: "admin" });
}

function pickNewAvatar() {
  saveError.value = "";
  fileInputEl.value?.click?.();
}

function clearPreview() {
  if (!previewUrl.value) return;
  try {
    URL.revokeObjectURL(previewUrl.value);
  } catch {
    // noop
  }
  previewUrl.value = "";
}

async function onFileSelected(e) {
  const file = e?.target?.files?.[0] || null;
  if (!file) return;
  e.target.value = "";

  saveError.value = "";

  if (!file.type?.startsWith("image/")) {
    saveError.value = "El archivo debe ser una imagen";
    return;
  }
  const maxBytes = 5 * 1024 * 1024;
  if (file.size > maxBytes) {
    saveError.value = "La imagen es muy pesada (máx 5MB)";
    return;
  }

  clearPreview();
  previewUrl.value = URL.createObjectURL(file);

  isUploading.value = true;
  try {
    const label = (
      vipName.value ||
      adminProfile.value?.display_name ||
      authUser.value?.email ||
      "vip"
    ).trim();
    const updated = await replaceMyProfileAvatar(file, label);
    adminProfile.value = updated;
    setTimeout(() => {
      clearPreview();
    }, 300);
  } catch (err) {
    console.error("[VIP] Error subiendo avatar:", err);
    saveError.value = err?.message || "No se pudo actualizar la imagen";
    clearPreview();
  } finally {
    isUploading.value = false;
  }
}

async function saveName() {
  saveError.value = "";
  isSaving.value = true;
  try {
    const next = (vipName.value || "").trim();
    const updated = await updateMyProfile({ display_name: next });
    adminProfile.value = updated;
    vipName.value = updated?.display_name || next;
  } catch (err) {
    console.error("[VIP] Error guardando nombre:", err);
    saveError.value = err?.message || "No se pudo guardar el nombre";
  } finally {
    isSaving.value = false;
  }
}

async function loadAuth() {
  authLoading.value = true;
  try {
    const session = await getSession();
    authUser.value = session?.user || null;

    if (!authUser.value) {
      adminProfile.value = null;
      isAdmin.value = false;
      return;
    }

    const profile = await getMyProfile();
    adminProfile.value = profile;
    vipName.value = profile?.display_name || "";
    isAdmin.value = !!profile?.is_admin;

    if (!isAdmin.value) {
      adminProfile.value = profile;
    }
  } catch {
    authUser.value = null;
    adminProfile.value = null;
    isAdmin.value = false;
  } finally {
    authLoading.value = false;
  }
}

async function logout() {
  try {
    await userLogout();
  } finally {
    authUser.value = null;
    adminProfile.value = null;
    isAdmin.value = false;
    closeProfileMenu();
    goHome();
  }
}

onMounted(async () => {
  document.addEventListener("click", onDocumentClick);
  await loadAuth();

  authSubscription = supabase.auth.onAuthStateChange(
    async (_event, session) => {
      authUser.value = session?.user || null;
      await loadAuth();
    }
  ).data.subscription;
});

onUnmounted(() => {
  document.removeEventListener("click", onDocumentClick);
  if (authSubscription) authSubscription.unsubscribe();
  clearPreview();
});
</script>

<style scoped>
.vip-profile-view {
  min-height: 100vh;
  padding: 20px;
  background: radial-gradient(
      circle at 20% 50%,
      rgba(0, 255, 255, 0.12) 0%,
      transparent 55%
    ),
    radial-gradient(
      circle at 80% 80%,
      rgba(0, 255, 136, 0.08) 0%,
      transparent 55%
    ),
    linear-gradient(180deg, #000000 0%, #061326 50%, #000000 100%);
  position: relative;
}

.profile-header {
  max-width: 1400px;
  margin: 0 auto 26px;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: start;
  gap: 14px;
  position: relative;
  z-index: 5;
}

.profile-title {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(1rem, 2.2vw, 1.6rem);
  text-align: center;
  color: #00ffff;
  text-shadow: 0 0 18px rgba(0, 255, 255, 0.75);
  margin: 0;
}

.back-btn {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border: 2px solid rgba(0, 255, 255, 0.6);
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.65);
  color: rgba(255, 255, 255, 0.92);
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  cursor: pointer;
}

.back-btn:hover {
  filter: brightness(1.1);
}

.profile-content {
  position: relative;
  z-index: 2;
  max-width: 1100px;
  margin: 0 auto;
}

.profile-panel {
  border: 2px solid rgba(0, 255, 255, 0.25);
  border-radius: 14px;
  background: rgba(0, 0, 0, 0.55);
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45);
  padding: 18px;
}

.profile-empty {
  display: grid;
  gap: 10px;
  justify-items: center;
  padding: 24px 10px;
}

.profile-empty-title {
  font-family: "Press Start 2P", monospace;
  color: #00ffff;
  margin: 0;
}

.profile-empty-sub {
  margin: 0;
  color: rgba(255, 255, 255, 0.75);
  text-align: center;
}

.user-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px 16px;
  border: 2px solid rgba(0, 255, 255, 0.7);
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.7);
  color: rgba(255, 255, 255, 0.92);
  font-family: "Press Start 2P", monospace;
  font-size: 0.68rem;
  cursor: pointer;
}

.user-btn:hover {
  filter: brightness(1.12);
}

.profile-card {
  display: grid;
  gap: 18px;
}

.profile-hero {
  display: grid;
  grid-template-columns: 160px 1fr;
  gap: 18px;
  align-items: center;
}

.avatar-frame {
  width: 160px;
  height: 160px;
  border-radius: 18px;
  border: 2px solid rgba(0, 255, 255, 0.65);
  background: rgba(0, 0, 0, 0.6);
  overflow: hidden;
  position: relative;
  box-shadow: inset 0 -10px 0 rgba(0, 0, 0, 0.6);
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.avatar-fallback {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  font-family: "Press Start 2P", monospace;
  color: #00ffff;
  text-shadow: 0 0 12px rgba(0, 255, 255, 0.6);
}

.avatar-edit {
  position: absolute;
  right: 10px;
  bottom: 10px;
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 2px solid rgba(0, 255, 255, 0.7);
  background: rgba(0, 0, 0, 0.75);
  color: #00ffff;
  display: grid;
  place-items: center;
  cursor: pointer;
}

.avatar-edit:hover {
  filter: brightness(1.12);
}

.avatar-edit:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}

.avatar-busy {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  background: rgba(0, 0, 0, 0.55);
}

.avatar-busy-text {
  font-family: "Press Start 2P", monospace;
  color: #00ffff;
}

.identity-tag {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.75);
}

.identity-name {
  font-family: "Press Start 2P", monospace;
  font-size: 0.95rem;
  color: #00ffff;
  text-shadow: 0 0 14px rgba(0, 255, 255, 0.55);
}

.identity-sub {
  margin-top: 6px;
  color: rgba(255, 255, 255, 0.78);
}

.identity-error {
  margin-top: 10px;
  color: #ffda79;
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
}

.vip-form {
  display: grid;
  gap: 10px;
  padding-top: 6px;
  border-top: 2px solid rgba(0, 255, 255, 0.18);
}

.vip-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  color: rgba(255, 255, 255, 0.75);
}

.vip-input {
  padding: 12px 12px;
  border: 2px solid rgba(0, 255, 255, 0.35);
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.6);
  color: rgba(255, 255, 255, 0.92);
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
}

.vip-actions {
  display: flex;
  justify-content: flex-start;
}

.file-input {
  display: none;
}

/* Dropdown perfil (mismo que jugadores) */
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
  padding: 10px 12px;
  border: 2px solid rgba(0, 255, 255, 0.7);
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.65);
  box-shadow: 0 10px 28px rgba(0, 0, 0, 0.35),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06);
  cursor: pointer;
  color: rgba(255, 255, 255, 0.92);
  width: auto;
  max-width: min(320px, calc(100vw - 24px));
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
  border: 2px solid rgba(0, 255, 255, 0.6);
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
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: #00ffff;
  text-shadow: 0 0 10px rgba(0, 255, 255, 0.6);
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
  color: #00ffff;
  text-shadow: 0 0 10px rgba(0, 255, 255, 0.55);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 230px;
}

.profile-caret {
  margin-left: auto;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: rgba(0, 255, 255, 0.95);
  text-shadow: 0 0 10px rgba(0, 255, 255, 0.55);
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
  border: 2px solid rgba(0, 255, 255, 0.55);
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

.profile-dropdown-item {
  width: 100%;
  text-align: left;
  border: 2px solid rgba(0, 255, 255, 0.45);
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

@media (max-width: 860px) {
  .profile-hero {
    grid-template-columns: 1fr;
    justify-items: center;
    text-align: center;
  }
}
</style>
