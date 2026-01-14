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
          <button @click="showHistory = !showHistory" class="btn-header">
            {{ showHistory ? "Ver jugadores" : "Ver historial" }}
          </button>
          <button @click="handleLogout" class="btn-header btn-logout">
            Cerrar sesión
          </button>
        </div>
      </header>

      <!-- Jugadores -->
      <section v-if="!showHistory" class="admin-section">
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

      <!-- Historial -->
      <section v-else class="history-section">
        <h2 class="section-title">Historial de eventos</h2>

        <!-- Filtros -->
        <div class="history-filters">
          <div class="filter-group">
            <label class="filter-label">Filtrar por persona:</label>
            <select v-model="filterPlayer" class="filter-select">
              <option value="">Todos los jugadores</option>
              <option
                v-for="player in players"
                :key="player.id"
                :value="player.id"
              >
                {{ player.nickname }}
              </option>
            </select>
          </div>

          <div class="filter-group">
            <label class="filter-label">Desde:</label>
            <input v-model="filterStartDate" type="date" class="filter-input" />
          </div>

          <div class="filter-group">
            <label class="filter-label">Hasta:</label>
            <input v-model="filterEndDate" type="date" class="filter-input" />
          </div>

          <button @click="resetFilters" class="filter-reset-btn">
            Limpiar filtros
          </button>
        </div>

        <div v-if="filteredEvents.length > 0" class="history-list">
          <div
            v-for="event in filteredEvents"
            :key="event.id"
            class="history-item"
          >
            <div class="history-main">
              <span class="history-player">{{
                event.player?.nickname || "Desconocido"
              }}</span>
              <span
                class="history-delta"
                :class="event.delta < 0 ? 'negative' : 'positive'"
              >
                {{ event.delta > 0 ? "+" : "" }}{{ event.delta }} vidas
              </span>
            </div>
            <div class="history-meta">
              <span class="history-date">{{
                formatDate(event.created_at)
              }}</span>
              <span
                v-if="event.reason && !isMinecraftDeathMessage(event.reason)"
                class="history-reason"
              >
                • {{ event.reason }}
              </span>
            </div>
          </div>
        </div>

        <div v-else class="empty-history">
          <p>No hay eventos que coincidan con los filtros</p>
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
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from "vue";
import { useRouter } from "vue-router";
import { Settings, ArrowLeft, History, Users } from "lucide-vue-next";
import {
  adminLogin,
  adminLogout,
  getSession,
  getMyProfile,
  getPlayers,
  removePlayerLives,
  resetPlayerLives,
  resetAllLives,
  getLifeEvents,
  deletePlayer,
} from "@/services/supabase";
import AdminPlayerRow from "@/components/AdminPlayerRow.vue";
import ConfirmModal from "@/components/ConfirmModal.vue";

const router = useRouter();

// Auth
const isAuthenticated = ref(false);
const loginEmail = ref("");
const loginPassword = ref("");
const loginError = ref("");
const loading = ref(false);

// Players
const players = ref([]);

// History
const showHistory = ref(false);
const lifeEvents = ref([]);
const filterPlayer = ref("");
const filterStartDate = ref("");
const filterEndDate = ref("");

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
  await checkAuth();
});

async function checkAuth() {
  const session = await getSession();
  if (!session?.user) {
    isAuthenticated.value = false;
    return;
  }

  try {
    const profile = await getMyProfile();
    isAuthenticated.value = !!profile?.is_admin;
  } catch {
    isAuthenticated.value = false;
  }

  if (isAuthenticated.value) await loadData();
}

async function loadData() {
  players.value = await getPlayers();
  lifeEvents.value = await getLifeEvents();
}

const filteredEvents = computed(() => {
  return lifeEvents.value.filter((event) => {
    // Filtrar por jugador
    if (
      filterPlayer.value &&
      event.player_id !== parseInt(filterPlayer.value)
    ) {
      return false;
    }

    // Filtrar por fecha de inicio
    if (filterStartDate.value) {
      const eventDate = new Date(event.created_at).toISOString().split("T")[0];
      if (eventDate < filterStartDate.value) {
        return false;
      }
    }

    // Filtrar por fecha de fin
    if (filterEndDate.value) {
      const eventDate = new Date(event.created_at).toISOString().split("T")[0];
      if (eventDate > filterEndDate.value) {
        return false;
      }
    }

    return true;
  });
});

function resetFilters() {
  filterPlayer.value = "";
  filterStartDate.value = "";
  filterEndDate.value = "";
}

async function handleLogin() {
  loginError.value = "";
  loading.value = true;

  try {
    await adminLogin(loginEmail.value, loginPassword.value);
    const profile = await getMyProfile();

    if (!profile?.is_admin) {
      loginError.value = "No autorizado";
      await adminLogout();
      isAuthenticated.value = false;
      return;
    }

    isAuthenticated.value = true;
    await loadData();
  } catch (error) {
    loginError.value = "Credenciales incorrectas";
    console.error("Error login:", error);
  } finally {
    loading.value = false;
  }
}

async function handleLogout() {
  try {
    await adminLogout();
    isAuthenticated.value = false;
    loginEmail.value = "";
    loginPassword.value = "";
  } catch (error) {
    console.error("Error logout:", error);
  }
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

function isMinecraftDeathMessage(reason) {
  // Lista de patrones de mensajes de muerte automáticos
  const deathPatterns = [
    "fue explotado por un Creeper",
    "fue asesinado por un Esqueleto",
    "fue devorado por un Zombie",
    "cayó al vacío",
    "se quemó en lava",
    "fue asesinado por una Araña",
    "murió ahogado",
    "fue alcanzado por un rayo",
    "fue eliminado por un Enderman",
    "fue asesinado por un Blaze",
    "cayó de un lugar alto",
    "fue envenenado por una Araña de Cueva",
    "fue asesinado por un Piglin",
    "explotó por TNT",
    "fue golpeado por un Ghast",
    "fue asesinado por un Vindicator",
    "cayó en cactus",
    "murió por inanición",
    "fue congelado hasta morir",
    "fue atravesado por un Tridente",
    "fue eliminado por el Wither",
    "fue asesinado por un Evoker",
    "fue picado por una abeja",
    "cayó en polvo de nieve",
    "fue empalado por una Stalagmite",
    "fue asesinado por un Hoglin",
    "intentó nadar en lava",
    "descubrió que el piso era lava",
    "fue fulminado por magia",
    "fue golpeado hasta morir",
  ];

  return deathPatterns.some((pattern) => reason?.includes(pattern));
}

function formatDate(dateString) {
  const date = new Date(dateString);
  return date.toLocaleString("es-ES", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
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
  align-items: center;
  flex-wrap: wrap;
  gap: 20px;
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
.history-section {
  max-width: 1400px;
  margin: 0 auto;
  background: rgba(0, 0, 0, 0.7);
  border: 3px solid #ffaa00;
  border-radius: 8px;
  padding: 24px;
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.history-item {
  background: rgba(0, 0, 0, 0.5);
  border: 2px solid rgba(255, 170, 0, 0.5);
  border-radius: 4px;
  padding: 16px;
}

.history-main {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.history-player {
  font-family: "Press Start 2P", monospace;
  font-size: 0.9rem;
  color: #00ff88;
}

.history-delta {
  font-family: "Press Start 2P", monospace;
  font-size: 0.85rem;
  font-weight: bold;
}

.history-delta.negative {
  color: #ff0055;
}

.history-delta.positive {
  color: #00ffff;
}

.history-meta {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  color: #888;
}

.history-date {
  margin-right: 8px;
}

.history-reason {
  color: #ffaa00;
}

/* FILTROS */
.history-filters {
  display: flex;
  gap: 16px;
  margin-bottom: 24px;
  padding: 20px;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid #00ffff;
  border-radius: 8px;
  flex-wrap: wrap;
  align-items: flex-end;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.filter-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  color: #00ffff;
}

.filter-select,
.filter-input {
  padding: 10px 12px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  background: rgba(0, 0, 0, 0.8);
  border: 2px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
  min-width: 200px;
}

.filter-select:focus,
.filter-input:focus {
  outline: none;
  box-shadow: 0 0 12px rgba(0, 255, 136, 0.5);
}

.filter-reset-btn {
  padding: 10px 16px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  background: rgba(255, 0, 85, 0.2);
  border: 2px solid #ff0055;
  border-radius: 4px;
  color: #ff0055;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-reset-btn:hover {
  background: rgba(255, 0, 85, 0.3);
  box-shadow: 0 0 12px rgba(255, 0, 85, 0.5);
}

.empty-history {
  text-align: center;
  padding: 40px;
  font-family: "Press Start 2P", monospace;
  color: #888;
  font-size: 0.9rem;
}

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
