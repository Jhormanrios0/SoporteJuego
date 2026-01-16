<template>
  <div class="admin-view">
    <!-- Login Screen -->
    <div v-if="!isAuthenticated" class="login-screen">
      <div class="login-container">
        <h1 class="login-title">ADMIN LOGIN</h1>
        <p class="login-subtitle">Panel de administración</p>

        <form @submit.prevent="handleLogin" class="login-form">
          <input
            v-model="loginEmail"
            type="email"
            placeholder="Email"
            required
            class="login-input"
          />
          <input
            v-model="loginPassword"
            type="password"
            placeholder="Password"
            required
            class="login-input"
          />
          <button type="submit" class="login-btn" :disabled="loading">
            {{ loading ? "CARGANDO..." : "ENTRAR" }}
          </button>
        </form>

        <p v-if="loginError" class="login-error">{{ loginError }}</p>

        <button @click="goToPublic" class="back-btn">
          <ArrowLeft :size="16" />
          Volver al panel público
        </button>
      </div>
    </div>

    <!-- Admin Panel -->
    <div v-else class="admin-panel">
      <!-- Header -->
      <header class="admin-header">
        <h1 class="admin-title">
          <Settings class="admin-icon" :size="28" />
          PANEL DE CONTROL
        </h1>
        <div class="admin-header-actions">
          <div
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
        </div>
      </header>

      <!-- Jugadores -->
      <section class="admin-section">
        <!-- Lista de jugadores -->
        <div class="players-section">
          <div class="section-header">
            <h2 class="section-title">Jugadores ({{ players.length }})</h2>
            <button
              @click="confirmResetAll"
              class="btn-reset-all"
              :disabled="players.length === 0"
            >
              Reset Global
            </button>
          </div>

          <div v-if="players.length > 0" class="players-list">
            <AdminPlayerRow
              v-for="player in players"
              :key="player.id"
              :player="player"
              @remove-lives="handleRemoveLives"
              @reset="handleResetPlayer"
              @delete="confirmDeletePlayer"
            />
          </div>

          <div v-else class="empty-players">
            <p>No hay jugadores creados</p>
          </div>
        </div>
      </section>
    </div>

    <!-- Modals -->
    <ConfirmModal
      :show="showResetAllModal"
      title="RESET GLOBAL"
      message="¿Resetear las vidas de TODOS los jugadores a 12? Esta acción no se puede deshacer."
      @confirm="handleResetAll"
      @cancel="showResetAllModal = false"
    />

    <ConfirmModal
      :show="showDeleteModal"
      title="ELIMINAR JUGADOR"
      :message="`¿Eliminar al jugador ${playerToDelete?.nickname}? Esta acción no se puede deshacer.`"
      @confirm="handleDeletePlayer"
      @cancel="showDeleteModal = false"
    />

    <ConfirmModal
      :show="showRemoveLivesModal"
      title="QUITAR VIDAS"
      :message="removeLivesModalMessage"
      @confirm="handleConfirmRemoveLives"
      @cancel="showRemoveLivesModal = false"
    />

    <ConfirmModal
      :show="showResetPlayerModal"
      title="RESET JUGADOR"
      :message="`¿Resetear las vidas de ${playerToReset?.nickname} a 12?`"
      @confirm="handleConfirmResetPlayer"
      @cancel="showResetPlayerModal = false"
    />

    <GameOverBanner
      :show="gameOverVisible"
      :playerName="gameOverPlayerName"
      :cause="gameOverCause"
      @close="hideGameOver"
    />
    
    <!-- Notificaciones de cambio de estado -->
    <StatusChangeNotification :notifications="statusNotifications" />
  </div>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from "vue";
import { useRouter } from "vue-router";
import { Settings, ArrowLeft } from "lucide-vue-next";
import {
  adminLogin,
  adminLogout,
  getSession,
  getMyProfile,
  getPlayers,
  getPlayerById,
  removePlayerLives,
  resetPlayerLives,
  resetAllLives,
  deletePlayer,
  subscribeToLifeEvents,
  subscribeToStatusChanges,
  supabase,
} from "@/services/supabase";
import AdminPlayerRow from "@/components/AdminPlayerRow.vue";
import ConfirmModal from "@/components/ConfirmModal.vue";
import GameOverBanner from "@/components/GameOverBanner.vue";
import StatusChangeNotification from "@/components/StatusChangeNotification.vue";

const router = useRouter();

// Auth
const isAuthenticated = ref(false);
const loginEmail = ref("");
const loginPassword = ref("");
const loginError = ref("");
const loading = ref(false);

const adminProfile = ref(null);
// Menú de perfil (dropdown) como jugadores
const profileMenuOpen = ref(false);
const profileMenuEl = ref(null);

const adminLabel = computed(() => {
  const name = adminProfile.value?.display_name?.trim?.() || "";
  return name || adminProfile.value?.email || "VIP";
});

// Players
const players = ref([]);

// Game Over banner (global)
const gameOverVisible = ref(false);
const gameOverPlayerName = ref("");
const gameOverCause = ref("");
const gameOverQueue = [];

// Notificaciones de estado
const statusNotifications = ref([]);
let statusNotificationId = 0;
let statusSubscription = null;
let gameOverTimer = null;
let liveEventsSubscription = null;

// Modals
const showResetAllModal = ref(false);
const showDeleteModal = ref(false);
const playerToDelete = ref(null);
const showRemoveLivesModal = ref(false);
const removeLivesModalMessage = ref("");
const pendingRemoveLives = ref(null);
const showResetPlayerModal = ref(false);
const playerToReset = ref(null);

onMounted(async () => {
  document.addEventListener("click", onDocumentClick);
  await checkAuth();
});

onUnmounted(() => {
  document.removeEventListener("click", onDocumentClick);
  stopSubscriptions();
});

async function checkAuth() {
  const session = await getSession();
  if (!session?.user) {
    isAuthenticated.value = false;
    return;
  }

  try {
    const profile = await getMyProfile();
    adminProfile.value = profile;
    isAuthenticated.value = !!profile?.is_admin;
  } catch {
    isAuthenticated.value = false;
  }

  if (isAuthenticated.value) {
    await loadData();
    startSubscriptions();
  }
}

async function loadData() {
  players.value = await getPlayers();
}

async function handleLogin() {
  loginError.value = "";
  loading.value = true;

  try {
    await adminLogin(loginEmail.value, loginPassword.value);
    const profile = await getMyProfile();

    adminProfile.value = profile;

    if (!profile?.is_admin) {
      loginError.value = "No autorizado";
      await adminLogout();
      isAuthenticated.value = false;
      return;
    }

    isAuthenticated.value = true;
    await loadData();
    startSubscriptions();
  } catch (error) {
    loginError.value = "Credenciales incorrectas";
    console.error("Error login:", error);
  } finally {
    loading.value = false;
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
  router.push({ name: "vip-profile" });
}

async function handleProfileMenuLogout() {
  closeProfileMenu();
  await handleLogout();
}

async function handleLogout() {
  try {
    stopSubscriptions();
    await adminLogout();
    isAuthenticated.value = false;
    adminProfile.value = null;
    loginEmail.value = "";
    loginPassword.value = "";
  } catch (error) {
    console.error("Error logout:", error);
  }
}

async function handleStatusChange(payload) {
  console.log("[Status] Cambio de estado recibido:", payload);

  // Verificar que hay cambios en la columna status
  if (payload?.new && payload.new.status) {
    const oldStatus = payload.old?.status;
    const newStatus = payload.new.status;

    // Solo notificar si realmente cambió el status
    if (JSON.stringify(oldStatus) === JSON.stringify(newStatus)) return;

    try {
      // Obtener datos del jugador/perfil
      const { data: profile, error } = await supabase
        .from("profiles")
        .select("first_name, last_name, email")
        .eq("id", payload.new.id)
        .single();

      if (error) throw error;

      const playerName =
        profile.first_name && profile.last_name
          ? `${profile.first_name} ${profile.last_name}`
          : profile.email?.split("@")[0] || "Usuario";

      const id = ++statusNotificationId;

      const notification = {
        id,
        playerName,
        status: newStatus.status || "Sin estado",
        color: newStatus.color || "#00ffc2",
        index: statusNotifications.value.length,
      };

      statusNotifications.value.push(notification);

      // Actualizar índices
      statusNotifications.value.forEach((notif, idx) => {
        notif.index = idx;
      });

      // Remover después de 5 segundos
      setTimeout(() => {
        const index = statusNotifications.value.findIndex((n) => n.id === id);
        if (index !== -1) {
          statusNotifications.value.splice(index, 1);
          // Actualizar índices después de remover
          statusNotifications.value.forEach((notif, idx) => {
            notif.index = idx;
          });
        }
      }, 5000);
    } catch (error) {
      console.error("Error al procesar cambio de estado:", error);
    }
  }
}

function startSubscriptions() {
  if (liveEventsSubscription) return;
  liveEventsSubscription = subscribeToLifeEvents(async (payload) => {
    if (payload?.new && payload.new.delta < 0) {
      const event = payload.new;

      let player = players.value.find((p) => p.id === event.player_id) || null;
      let lives = player ? player.lives : null;

      try {
        const fresh = await getPlayerById(event.player_id);
        if (fresh) {
          player = fresh;
          lives = typeof fresh.lives === "number" ? fresh.lives : lives;
        }
      } catch {
        // noop
      }

      if (lives === 0) {
        enqueueGameOver(
          getPlayerDisplayName(player),
          String(event.reason || "")
        );
      }
    }
  });

  // Suscribirse a cambios de estado
  statusSubscription = subscribeToStatusChanges((payload) => {
    handleStatusChange(payload);
  });
}

function stopSubscriptions() {
  if (liveEventsSubscription) {
    liveEventsSubscription.unsubscribe();
    liveEventsSubscription = null;
  }
  if (statusSubscription) {
    statusSubscription.unsubscribe();
    statusSubscription = null;
  }
}

function getPlayerDisplayName(player) {
  if (!player) return "Jugador";
  const first = player?.first_name?.trim?.() || "";
  const last = player?.last_name?.trim?.() || "";
  const full = `${first} ${last}`.trim();
  return full || player?.nickname || "Jugador";
}

function enqueueGameOver(playerName, cause) {
  gameOverQueue.push({
    playerName: String(playerName || "Jugador"),
    cause: String(cause || ""),
  });
  if (!gameOverVisible.value) {
    showNextGameOver();
  }
}

function showNextGameOver() {
  const next = gameOverQueue.shift();
  if (!next) return;

  gameOverPlayerName.value = next.playerName;
  gameOverCause.value = next.cause;
  gameOverVisible.value = true;

  if (gameOverTimer) clearTimeout(gameOverTimer);
  gameOverTimer = setTimeout(() => {
    hideGameOver();
  }, 5200);
}

function hideGameOver() {
  if (gameOverTimer) {
    clearTimeout(gameOverTimer);
    gameOverTimer = null;
  }

  if (!gameOverVisible.value) return;
  gameOverVisible.value = false;

  setTimeout(() => {
    if (!gameOverVisible.value) {
      showNextGameOver();
    }
  }, 360);
}

function handleRemoveLives(playerId, amount, reason) {
  const player = players.value.find((p) => p.id === playerId);
  if (!player) return;

  const vidasTexto = amount === 1 ? "vida" : "vidas";
  removeLivesModalMessage.value = `¿Quitar ${amount} ${vidasTexto} a ${
    player.nickname
  }?${reason ? `\n\nRazón: ${reason}` : ""}`;
  pendingRemoveLives.value = { playerId, amount, reason };
  showRemoveLivesModal.value = true;
}

async function handleConfirmRemoveLives() {
  if (!pendingRemoveLives.value) return;

  const { playerId, amount, reason } = pendingRemoveLives.value;

  try {
    await removePlayerLives(playerId, amount, reason);
    showRemoveLivesModal.value = false;
    pendingRemoveLives.value = null;
    await loadData();
  } catch (error) {
    console.error("Error quitar vidas:", error);
    alert("Error al quitar vidas");
  }
}

function handleResetPlayer(playerId) {
  playerToReset.value = players.value.find((p) => p.id === playerId);
  showResetPlayerModal.value = true;
}

async function handleConfirmResetPlayer() {
  if (!playerToReset.value) return;

  try {
    await resetPlayerLives(playerToReset.value.id);
    showResetPlayerModal.value = false;
    playerToReset.value = null;
    await loadData();
  } catch (error) {
    console.error("Error reset:", error);
    alert("Error al resetear vidas");
  }
}

function confirmResetAll() {
  showResetAllModal.value = true;
}

async function handleResetAll() {
  try {
    await resetAllLives();
    showResetAllModal.value = false;
    await loadData();
  } catch (error) {
    console.error("Error reset global:", error);
    alert("Error al resetear todas las vidas");
  }
}

function confirmDeletePlayer(playerId) {
  playerToDelete.value = players.value.find((p) => p.id === playerId);
  showDeleteModal.value = true;
}

async function handleDeletePlayer() {
  if (!playerToDelete.value) return;

  try {
    await deletePlayer(playerToDelete.value.id);
    showDeleteModal.value = false;
    playerToDelete.value = null;
    await loadData();
  } catch (error) {
    console.error("Error eliminar:", error);
    alert("Error al eliminar jugador");
  }
}

function goToPublic() {
  router.push("/");
}
</script>

<style scoped>
.admin-view {
  min-height: 100vh;
  background: linear-gradient(180deg, #0a0015 0%, #1a0030 100%);
}

/* LOGIN SCREEN */
.login-screen {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 20px;
}

.login-container {
  background: rgba(0, 0, 0, 0.8);
  border: 4px solid #00ff88;
  border-radius: 8px;
  padding: 48px 40px;
  max-width: 450px;
  width: 100%;
  box-shadow: 0 0 40px rgba(0, 255, 136, 0.5),
    inset 0 0 30px rgba(0, 255, 136, 0.1);
}

.login-title {
  font-family: "Press Start 2P", monospace;
  font-size: 1.8rem;
  color: #00ff88;
  text-shadow: 0 0 20px rgba(0, 255, 136, 0.8);
  text-align: center;
  margin: 0 0 12px 0;
}

.login-subtitle {
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  color: #00ffff;
  text-align: center;
  margin: 0 0 32px 0;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 16px;
}

.login-input {
  padding: 16px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  background: rgba(0, 0, 0, 0.6);
  border: 3px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
}

.login-input:focus {
  outline: none;
  box-shadow: 0 0 15px rgba(0, 255, 136, 0.6);
}

.login-btn {
  padding: 16px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.9rem;
  background: rgba(0, 255, 136, 0.2);
  border: 3px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
  cursor: pointer;
  transition: all 0.3s;
}

.login-btn:hover:not(:disabled) {
  background: rgba(0, 255, 136, 0.3);
  box-shadow: 0 0 20px rgba(0, 255, 136, 0.6);
  transform: translateY(-2px);
}

.login-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.login-error {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  color: #ff0055;
  text-align: center;
  margin: 16px 0 0 0;
}

.back-btn {
  width: 100%;
  padding: 12px;
  margin-top: 24px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  background: transparent;
  border: 2px solid #888;
  border-radius: 4px;
  color: #888;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.back-btn:hover {
  border-color: #00ffff;
  color: #00ffff;
}

/* ADMIN PANEL */
.admin-panel {
  padding: 40px 20px;
}

.admin-header {
  max-width: 1400px;
  margin: 0 auto 40px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 20px;
  position: relative;
  z-index: 5;
}

.admin-title {
  font-family: "Press Start 2P", monospace;
  font-size: 2rem;
  color: #00ff88;
  text-shadow: 0 0 20px rgba(0, 255, 136, 0.8);
  margin: 0;
  display: flex;
  align-items: center;
  gap: 12px;
}

.admin-icon {
  filter: drop-shadow(0 0 10px rgba(0, 255, 136, 0.8));
}

.admin-header-actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

/* Perfil dropdown (igual que jugadores) */
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

.btn-header {
  padding: 12px 20px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid #00ffff;
  border-radius: 4px;
  color: #00ffff;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-header:hover {
  background: rgba(0, 255, 255, 0.2);
  box-shadow: 0 0 15px rgba(0, 255, 255, 0.5);
}

.btn-create-header {
  border-color: #00ff88;
  color: #00ff88;
  background: rgba(0, 255, 136, 0.15);
}

.btn-create-header:hover {
  border-color: #00ff88;
  background: rgba(0, 255, 136, 0.25);
  box-shadow: 0 0 15px rgba(0, 255, 136, 0.6);
}

.btn-logout {
  border-color: #ff0055;
  color: #ff0055;
}

.btn-logout:hover {
  background: rgba(255, 0, 85, 0.2);
  box-shadow: 0 0 15px rgba(255, 0, 85, 0.5);
}

.btn-save {
  border-color: #00ff88;
  color: #00ff88;
}

.btn-save:hover {
  background: rgba(0, 255, 136, 0.2);
  box-shadow: 0 0 15px rgba(0, 255, 136, 0.5);
}

/* VIP editor */
.vip-editor {
  max-width: 1400px;
  margin: 0 auto 26px;
}

.vip-editor-head {
  display: grid;
  gap: 6px;
  margin-bottom: 12px;
}

.vip-editor-sub {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: rgba(255, 255, 255, 0.65);
  line-height: 1.5;
}

.vip-editor-card {
  background: rgba(0, 0, 0, 0.75);
  border: 3px solid rgba(0, 255, 255, 0.55);
  border-radius: 10px;
  padding: 16px;
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 16px;
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45),
    inset 0 0 0 2px rgba(255, 255, 255, 0.05);
}

.vip-editor-avatar {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 12px;
  border: 3px solid rgba(0, 255, 194, 0.6);
  overflow: hidden;
  background: rgba(0, 0, 0, 0.7);
  box-shadow: inset 0 -10px 0 rgba(0, 0, 0, 0.6);
}

.vip-editor-avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.vip-editor-avatar-fallback {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
  color: #00ffff;
  text-shadow: 0 0 12px rgba(0, 255, 255, 0.55);
}

.vip-editor-edit {
  position: absolute;
  right: 8px;
  bottom: 8px;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  border: 2px solid rgba(255, 218, 121, 0.9);
  background: rgba(0, 0, 0, 0.7);
  color: #ffda79;
  cursor: pointer;
  display: grid;
  place-items: center;
  box-shadow: inset 0 -6px 0 rgba(0, 0, 0, 0.65),
    0 12px 24px rgba(0, 0, 0, 0.35);
}

.vip-editor-edit:hover {
  filter: brightness(1.12);
}

.vip-editor-edit:active {
  transform: translateY(2px);
}

.vip-editor-busy {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: #00ff88;
  background: rgba(0, 0, 0, 0.55);
  text-shadow: 0 0 14px rgba(0, 255, 136, 0.55);
}

.vip-editor-fields {
  display: grid;
  gap: 10px;
  align-content: start;
}

.vip-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: rgba(255, 255, 255, 0.75);
}

.vip-input {
  padding: 14px 14px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  background: rgba(0, 0, 0, 0.55);
  border: 3px solid rgba(0, 255, 255, 0.55);
  border-radius: 6px;
  color: #00ffff;
}

.vip-input:focus {
  outline: none;
  box-shadow: 0 0 18px rgba(0, 255, 255, 0.45);
}

.vip-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.vip-error {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: #ff0055;
  line-height: 1.45;
}

.vip-file-input {
  display: none;
}

@media (max-width: 520px) {
  .vip-editor-card {
    grid-template-columns: 1fr;
    justify-items: center;
  }

  .vip-editor-fields {
    width: 100%;
  }
}

.admin-section {
  max-width: 1400px;
  margin: 0 auto;
}

.create-player {
  background: rgba(0, 0, 0, 0.7);
  border: 3px solid #00ff88;
  border-radius: 8px;
  padding: 24px;
  margin-bottom: 32px;
}

.section-title {
  font-family: "Press Start 2P", monospace;
  font-size: 1.2rem;
  color: #00ffff;
  text-shadow: 0 0 10px rgba(0, 255, 255, 0.6);
  margin: 0 0 20px 0;
}

.create-form {
  display: flex;
  gap: 12px;
}

.create-input {
  flex: 1;
  padding: 12px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
}

.create-input:focus {
  outline: none;
  box-shadow: 0 0 12px rgba(0, 255, 136, 0.5);
}

.btn-create {
  padding: 12px 24px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  background: rgba(0, 255, 136, 0.2);
  border: 2px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-create:hover:not(:disabled) {
  background: rgba(0, 255, 136, 0.3);
  box-shadow: 0 0 15px rgba(0, 255, 136, 0.5);
}

.btn-create:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.error-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #ff0055;
  margin: 12px 0 0 0;
}

.players-section {
  background: rgba(0, 0, 0, 0.7);
  border: 3px solid #00ffff;
  border-radius: 8px;
  padding: 24px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.btn-reset-all {
  padding: 12px 20px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  background: rgba(255, 0, 85, 0.2);
  border: 2px solid #ff0055;
  border-radius: 4px;
  color: #ff0055;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-reset-all:hover:not(:disabled) {
  background: rgba(255, 0, 85, 0.3);
  box-shadow: 0 0 15px rgba(255, 0, 85, 0.5);
}

.btn-reset-all:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.players-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(450px, 1fr));
  gap: 16px;
}

.empty-players {
  text-align: center;
  padding: 40px;
  font-family: "Press Start 2P", monospace;
  color: #888;
  font-size: 0.9rem;
}

/* HISTORY */

@media (max-width: 768px) {
  .admin-header {
    flex-direction: column;
    align-items: stretch;
  }

  .admin-title {
    font-size: 1.5rem;
    text-align: center;
  }

  .admin-header-actions {
    flex-direction: column;
  }

  .create-form {
    flex-direction: column;
  }

  .section-header {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }
}
</style>
