<template>
  <div class="public-view">
    <!-- Header retro -->
    <header class="arcade-header">
      <div class="title-container">
        <div class="title-decoration top"></div>
        <h1 class="arcade-title">
          <Gamepad2 class="title-icon" :size="40" />
          <span class="title-text">SOPORTE</span>
          <span class="title-highlight">SQUID GAMES</span>
          <Gamepad2 class="title-icon" :size="40" />
        </h1>
        <div class="title-decoration bottom"></div>
      </div>
      <p class="arcade-subtitle">SISTEMA DE VIDAS • JUGADORES ACTIVOS</p>
      <div class="stats-bar">
        <div class="stat-item">
          <span class="stat-label">Jugadores:</span>
          <span class="stat-value">{{ players.length }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">En riesgo:</span>
          <span class="stat-value danger">{{
            players.filter((p) => p.lives <= 3).length
          }}</span>
        </div>
      </div>
    </header>

    <!-- Grid de jugadores -->
    <main class="players-grid">
      <PlayerCard v-for="player in players" :key="player.id" :player="player" />

      <!-- Estado vacío -->
      <div v-if="players.length === 0" class="empty-state">
        <p class="empty-message">No hay jugadores registrados</p>
        <p class="empty-hint">Inicia sesión y regístrate para aparecer</p>
      </div>
    </main>

    <!-- Footer -->
    <footer class="arcade-footer">
      <div class="user-auth">
        <button
          v-if="!authUser"
          class="user-btn"
          :disabled="authLoading"
          @click="openLoginModal"
        >
          <LogIn class="btn-icon" :size="18" />
          <span>{{ authLoading ? "CARGANDO…" : "ENTRAR" }}</span>
        </button>

        <div v-else class="user-session">
          <div class="user-session-text">
            Sesión: <span class="user-session-strong">{{ userLabel }}</span>
            <span v-if="profileNeedsRegister" class="user-session-warn">
              • Registro pendiente
            </span>
          </div>

          <div class="user-session-actions">
            <button
              v-if="profileNeedsRegister"
              class="user-btn secondary"
              @click="goToRegister"
            >
              Completar registro
            </button>
            <button class="user-btn danger" @click="logout">
              Cerrar sesión
            </button>
          </div>
        </div>

        <p v-if="authError" class="auth-error">{{ authError }}</p>
      </div>
    </footer>

    <!-- Modal de login (VIP / Jugador) -->
    <div
      v-if="showLoginModal"
      class="login-modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-label="Opciones de inicio de sesión"
      @click.self="closeLoginModal"
    >
      <div class="login-modal">
        <div class="login-modal-header">
          <div class="login-modal-title">ELIGE TU ACCESO</div>
          <button
            class="login-modal-close"
            type="button"
            aria-label="Cerrar"
            @click="closeLoginModal"
          >
            ✕
          </button>
        </div>

        <div class="login-modal-body">
          <p class="login-modal-subtitle">
            VIP es para administración. Jugador entra con Google.
          </p>

          <div class="login-modal-actions">
            <button class="user-btn secondary" type="button" @click="enterVip">
              <Crown class="btn-icon" :size="18" />
              <span>VIP</span>
            </button>
            <button
              class="user-btn"
              type="button"
              :disabled="authLoading"
              @click="enterJugador"
            >
              <User class="btn-icon" :size="18" />
              <span>{{ authLoading ? "CARGANDO…" : "JUGADOR" }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <GameOverBanner
      :show="gameOverVisible"
      :playerName="gameOverPlayerName"
      :cause="gameOverCause"
      @close="hideGameOver"
    />

    <!-- Notificaciones de muerte -->
    <DeathNotification :notifications="deathNotifications" />
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from "vue";
import { useRouter } from "vue-router";
import { Crown, Gamepad2, LogIn, User } from "lucide-vue-next";
import {
  getPlayers,
  getPlayerById,
  subscribeToPlayers,
  subscribeToLifeEvents,
  getSession,
  getMyPlayer,
  userLoginWithGoogle,
  userLogout,
  supabase,
} from "@/services/supabase";
import PlayerCard from "@/components/PlayerCard.vue";
import DeathNotification from "@/components/DeathNotification.vue";
import GameOverBanner from "@/components/GameOverBanner.vue";
import hahaDamageSound from "@/assets/audio/hahaDamage.mp3";
import minecraftDamageSound from "@/assets/audio/MinecraftDamage.mp3";
import {
  requestDesktopNotificationsPermission,
  showDesktopNotification,
  canUseDesktopNotifications,
} from "@/services/desktopNotifications";

const router = useRouter();
const players = ref([]);
const deathNotifications = ref([]);
let notificationId = 0;
let playersSubscription = null;
let eventsSubscription = null;
let audioContext = null;

// Auth usuario
const authUser = ref(null);
const myPlayer = ref(null);
const authLoading = ref(false);
const authError = ref("");
let authSubscription = null;

// Modal login
const showLoginModal = ref(false);

// Game Over banner (global)
const gameOverVisible = ref(false);
const gameOverPlayerName = ref("");
const gameOverCause = ref("");
const gameOverQueue = [];
let gameOverTimer = null;

// Desktop notifications
let requestedDesktopNotifications = false;

function requestDesktopNotificationsOnce() {
  if (!canUseDesktopNotifications()) return;
  if (requestedDesktopNotifications) return;
  requestedDesktopNotifications = true;
  requestDesktopNotificationsPermission().catch(() => {
    // noop
  });
}

function maybeNotifyDesktopDeath(message) {
  // En desktop, normalmente se desea cuando está en segundo plano
  if (!document.hidden) return;
  showDesktopNotification({
    title: "MUERTE",
    body: message,
    tag: "life-event",
  });
}

function notifyDesktopGameOver(playerName, cause) {
  showDesktopNotification({
    title: "GAME OVER",
    body: `${playerName}: ${cause}`,
    tag: `game-over-${playerName}`,
    requireInteraction: true,
  });
}

const userLabel = computed(() => {
  const first = myPlayer.value?.first_name?.trim?.() || "";
  const last = myPlayer.value?.last_name?.trim?.() || "";
  const full = `${first} ${last}`.trim();
  return full || authUser.value?.email || "Usuario";
});

const profileNeedsRegister = computed(() => {
  // Registro pendiente si está autenticado pero aún no creó su jugador
  if (!authUser.value) return false;
  return !myPlayer.value?.id;
});

async function loadAuth() {
  authError.value = "";
  authLoading.value = true;
  try {
    const session = await getSession();
    authUser.value = session?.user || null;
    myPlayer.value = authUser.value ? await getMyPlayer() : null;
  } catch (e) {
    authUser.value = null;
    myPlayer.value = null;
    authError.value = e?.message || "Error cargando sesión";
  } finally {
    authLoading.value = false;
  }
}

function openLoginModal() {
  authError.value = "";
  showLoginModal.value = true;
}

function closeLoginModal() {
  showLoginModal.value = false;
}

async function loginWithGoogle() {
  authError.value = "";
  authLoading.value = true;
  try {
    await userLoginWithGoogle();
    // Redirige a Google
  } catch (e) {
    authError.value = e?.message || "No se pudo iniciar sesión con Google";
    authLoading.value = false;
  }
}

function enterVip() {
  closeLoginModal();
  goToAdmin();
}

async function enterJugador() {
  closeLoginModal();
  await loginWithGoogle();
}

async function logout() {
  authError.value = "";
  authLoading.value = true;
  try {
    await userLogout();
    authUser.value = null;
    myPlayer.value = null;
  } catch (e) {
    authError.value = e?.message || "No se pudo cerrar sesión";
  } finally {
    authLoading.value = false;
  }
}

function goToRegister() {
  router.push({
    name: "register",
    query: { email: authUser.value?.email || "" },
  });
}

// Inicializar AudioContext cuando el usuario interactúa
function initializeAudioContext() {
  if (!audioContext) {
    try {
      audioContext = new (window.AudioContext || window.webkitAudioContext)();
      console.log("[Audio] AudioContext inicializado");

      // Si está suspendido, reanudarlo
      if (audioContext.state === "suspended") {
        audioContext
          .resume()
          .then(() => {
            console.log("[Audio] AudioContext reanudado");
          })
          .catch((err) => {
            console.warn(
              "[Audio] No se pudo reanudar (requiere interacción):",
              err
            );
          });
      }
    } catch (error) {
      console.error("[Audio] Error al inicializar AudioContext:", error);
    }
  } else if (audioContext.state === "suspended") {
    // Si ya existe pero está suspendido, intentar reanudarlo
    audioContext.resume().catch((err) => {
      console.warn("[Audio] No se pudo reanudar (requiere interacción):", err);
    });
  }
}

onMounted(async () => {
  window.addEventListener("keydown", onKeydown);

  // Intentar inicializar AudioContext inmediatamente
  initializeAudioContext();

  // También agregarlo como listener de respaldo
  document.addEventListener("click", initializeAudioContext, { once: true });

  // Pedir permiso de notificaciones con gesto de usuario (click)
  document.addEventListener("click", requestDesktopNotificationsOnce, {
    once: true,
  });

  // Cargar jugadores iniciales
  await loadPlayers();

  // Cargar sesión usuario (si existe)
  await loadAuth();

  // Escuchar cambios de auth (login/logout)
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

  // Pedir permiso al primer click (igual que el audio)
  document.addEventListener(
    "click",
    () => {
      requestDesktopPermission();
    },
    { once: true }
  );

  // Suscribirse a cambios en jugadores
  playersSubscription = subscribeToPlayers(() => {
    loadPlayers();
  });

  // Suscribirse a eventos de muerte
  eventsSubscription = subscribeToLifeEvents((payload) => {
    handleDeathEvent(payload);
  });
});

onUnmounted(() => {
  window.removeEventListener("keydown", onKeydown);

  // Limpiar suscripciones
  if (playersSubscription) {
    playersSubscription.unsubscribe();
  }
  if (eventsSubscription) {
    eventsSubscription.unsubscribe();
  }

  if (authSubscription) {
    authSubscription.unsubscribe();
  }
});

function canNotify() {
  return "Notification" in window;
}

// Solicitar permiso de notificaciones de escritorio
async function requestDesktopPermission() {
  if (!canNotify()) return false;

  if (Notification.permission === "granted") return true;

  const permission = await Notification.requestPermission();
  return permission === "granted";
}

async function loadPlayers() {
  players.value = await getPlayers();
}

function handleDeathEvent(payload) {
  console.log("[Events] Evento recibido:", payload);

  // Solo mostrar notificaciones cuando se quitan vidas (delta negativo)
  if (payload?.new && payload.new.delta < 0) {
    console.log("[Audio] Reproduciendo sonido de daño...");

    const event = payload.new;

    const localPlayer =
      players.value.find((p) => p.id === event.player_id) || null;
    const localLives = localPlayer ? localPlayer.lives : 0;

    // Reproducir sonido de daño (sin esperar red)
    playDamageSound(localLives);

    // Función para enviar notificación de escritorio
    sendDesktopNotification("💀 ¡Vida perdida!", payload.new.reason);

    const id = ++notificationId;

    const amount = Math.abs(Number(event.delta || 0)) || 1;
    const playerName = getPlayerDisplayName(localPlayer);
    const message =
      String(event.reason || "").trim() ||
      `${playerName} perdió ${amount} vida${amount === 1 ? "" : "s"}`;

    const notification = {
      id,
      message,
      index: deathNotifications.value.length,
    };

    deathNotifications.value.push(notification);

    // Notificación del sistema (Windows) en segundo plano
    maybeNotifyDesktopDeath(message);

    // Actualizar índices
    deathNotifications.value.forEach((notif, idx) => {
      notif.index = idx;
    });

    // Remover después de 5 segundos
    setTimeout(() => {
      const index = deathNotifications.value.findIndex((n) => n.id === id);
      if (index !== -1) {
        deathNotifications.value.splice(index, 1);
        // Actualizar índices después de remover
        deathNotifications.value.forEach((notif, idx) => {
          notif.index = idx;
        });
      }
    }, 5000);

    // Banner global SOLO si el jugador llegó a 0 vidas (sin bloquear alerts/sonidos)
    getPlayerById(event.player_id)
      .then((fresh) => {
        const livesAfter =
          typeof fresh?.lives === "number" ? fresh.lives : null;
        if (livesAfter === 0) {
          const name = getPlayerDisplayName(fresh || localPlayer);
          enqueueGameOver(name, message);
          notifyDesktopGameOver(name, message);
        }
      })
      .catch(() => {
        // noop
      });
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

  // esperar la animación de salida
  setTimeout(() => {
    if (!gameOverVisible.value) {
      showNextGameOver();
    }
  }, 360);
}

function playDamageSound(currentLives = 0) {
  try {
    console.log("[Audio] Intentando reproducir sonido...");

    // Intentar inicializar AudioContext si no está
    if (!audioContext || audioContext.state === "suspended") {
      initializeAudioContext();
    }

    // Seleccionar sonido según las vidas
    // >= 6 vidas = Minecraft, < 6 vidas = Haha
    const selectedSound =
      currentLives >= 6 ? minecraftDamageSound : hahaDamageSound;

    console.log(
      "[Audio] Sonido seleccionado:",
      currentLives >= 6 ? "Minecraft" : "Haha",
      "(Vidas:",
      currentLives,
      ")"
    );

    const audio = new Audio(selectedSound);
    audio.volume = 0.7;

    const playPromise = audio.play();

    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          console.log("[Audio] Sonido reproduciéndose correctamente");
        })
        .catch((error) => {
          console.warn(
            "[Audio] No se pudo reproducir (requiere interacción):",
            error.message
          );
        });
    }
  } catch (error) {
    console.error("[Audio] Error en playDamageSound:", error);
    playSyntheticSound();
  }
}

function sendDesktopNotification(title, body) {
  if (!("Notification" in window)) return;

  if (document.visibilityState === "visible") return;

  if (Notification.permission !== "granted") return;

  new Notification(title, {
    body,
  });
}
function playSyntheticSound() {
  try {
    // Verificar que AudioContext esté inicializado (requiere clic del usuario)
    if (!audioContext) {
      console.warn("[Audio] Haz clic en la página para habilitar los sonidos");
      return;
    }

    // Verificar estado del AudioContext
    if (audioContext.state === "suspended") {
      console.warn("[Audio] AudioContext suspendido. Haz clic en la página.");
      return;
    }

    console.log("[Audio] Creando sonido sintetizado...");
    reproducirSonido();

    function reproducirSonido() {
      // Crear nodos
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      const filter = audioContext.createBiquadFilter();

      // Conectar nodos
      oscillator.connect(filter);
      filter.connect(gainNode);
      gainNode.connect(audioContext.destination);

      // Configurar filtro
      filter.type = "highpass";
      filter.frequency.setValueAtTime(100, audioContext.currentTime);

      // Sonido corto y punzante (tipo daño Minecraft)
      const now = audioContext.currentTime;

      oscillator.type = "square";
      oscillator.frequency.setValueAtTime(150, now);
      oscillator.frequency.exponentialRampToValueAtTime(75, now + 0.15);

      // Envelope ADSR
      gainNode.gain.setValueAtTime(0.5, now);
      gainNode.gain.exponentialRampToValueAtTime(0.01, now + 0.15);

      // Reproducir
      oscillator.start(now);
      oscillator.stop(now + 0.15);

      console.log("[Audio] Sonido sintetizado reproducido correctamente");
    }
  } catch (error) {
    console.error("[Audio] Error al crear sonido sintetizado:", error);
  }
}

function goToAdmin() {
  router.push("/admin");
}

function onKeydown(e) {
  if (e.key === "Escape" && showLoginModal.value) {
    closeLoginModal();
  }
}
</script>

<style scoped>
.public-view {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
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

/* Efecto CRT scanlines */
.public-view::before {
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

.arcade-header {
  text-align: center;
  margin: 0 auto clamp(22px, 4vw, 60px);
  max-width: 1400px;
  position: relative;
  z-index: 2;
  background: linear-gradient(
    180deg,
    rgba(247, 65, 143, 0.1) 0%,
    transparent 100%
  );
  padding: clamp(20px, 4.2vw, 42px) clamp(12px, 2.8vw, 22px);
  border-bottom: 3px solid rgba(247, 65, 143, 0.3);
}

.title-container {
  position: relative;
  display: inline-block;
  padding: clamp(14px, 3.2vw, 20px) clamp(16px, 4.2vw, 40px);
}

.title-decoration {
  position: absolute;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(
    90deg,
    transparent,
    #f7418f 20%,
    #00ffc2 50%,
    #f7418f 80%,
    transparent
  );
  animation: lineGlow 2s ease-in-out infinite;
}

.title-decoration.top {
  top: 0;
}

.title-decoration.bottom {
  bottom: 0;
}

.arcade-title {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(1.1rem, 2.6vw, 2rem);
  margin: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: clamp(10px, 2vw, 20px);
  flex-wrap: wrap;
}

.title-text {
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 1), 0 0 20px rgba(0, 255, 194, 0.8),
    0 0 30px rgba(0, 255, 194, 0.6);
  animation: titlePulse 2s ease-in-out infinite;
}

.title-highlight {
  color: #f7418f;
  text-shadow: 0 0 10px rgba(247, 65, 143, 1), 0 0 20px rgba(247, 65, 143, 0.8),
    0 0 30px rgba(247, 65, 143, 0.6), 0 0 40px rgba(247, 65, 143, 0.4);
  animation: titlePulse 2s ease-in-out infinite 0.5s;
}

@keyframes titlePulse {
  0%,
  100% {
    transform: scale(1);
    filter: brightness(1);
  }
  50% {
    transform: scale(1.05);
    filter: brightness(1.2);
  }
}

@keyframes lineGlow {
  0%,
  100% {
    text-shadow: 0 0 20px rgba(0, 255, 136, 1), 0 0 40px rgba(0, 255, 136, 0.6);
  }
  50% {
    text-shadow: 0 0 30px rgba(0, 255, 255, 1), 0 0 60px rgba(0, 255, 255, 0.8);
  }
}

.title-icon {
  display: inline-block;
  animation: float 2s ease-in-out infinite;
  filter: drop-shadow(0 0 10px rgba(0, 255, 136, 0.8));
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-10px);
  }
}

.arcade-subtitle {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(0.65rem, 1.35vw, 0.85rem);
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.8);
  margin: 20px 0;
  letter-spacing: clamp(1px, 0.6vw, 3px);
}

.stats-bar {
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: clamp(14px, 3vw, 40px);
  margin-top: 30px;
  padding: 20px;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid rgba(247, 65, 143, 0.3);
  border-radius: 8px;
  width: min(520px, 100%);
  margin-left: auto;
  margin-right: auto;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: center;
}

.stat-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.65rem;
  color: #888;
  text-transform: uppercase;
}

.stat-value {
  font-family: "Press Start 2P", monospace;
  font-size: 1.8rem;
  color: #00ffc2;
  text-shadow: 0 0 15px rgba(0, 255, 194, 0.8);
  font-weight: bold;
}

.stat-value.danger {
  color: #f7418f;
  text-shadow: 0 0 15px rgba(247, 65, 143, 0.8);
  animation: dangerPulse 1s ease-in-out infinite;
}

@keyframes dangerPulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
}

.players-grid {
  width: 100%;
  flex: 1 1 auto;
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(340px, 100%), 1fr));
  gap: clamp(14px, 2.2vw, 30px);
  align-content: start;
  position: relative;
  z-index: 2;
  padding: 0 clamp(0px, 2vw, 20px);
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 80px 20px;
  background: rgba(0, 0, 0, 0.5);
  border: 3px dashed rgba(0, 255, 136, 0.3);
  border-radius: 8px;
}

.empty-message {
  font-family: "Press Start 2P", monospace;
  font-size: 1.2rem;
  color: #00ff88;
  margin: 0 0 16px 0;
}

.empty-hint {
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  color: #888;
  margin: 0;
}

.arcade-footer {
  text-align: center;
  margin-top: clamp(18px, 4vw, 60px);
  padding-bottom: max(12px, env(safe-area-inset-bottom));
  position: relative;
  z-index: 2;
}

.user-auth {
  margin-top: 14px;
  display: grid;
  gap: 10px;
  justify-items: center;
}

.user-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  border: 2px solid rgba(0, 0, 0, 0.95);
  border-radius: 6px;
  padding: 12px 14px;
  font-weight: 900;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  cursor: pointer;
  background: rgba(64, 64, 64, 0.95);
  color: #fff;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7), 0 10px 28px rgba(0, 0, 0, 0.35);
  transition: transform 0.08s ease, filter 0.12s ease;
}

.btn-icon {
  flex: 0 0 auto;
}

.user-btn:hover:not(:disabled) {
  filter: brightness(1.08);
}

.user-btn:active:not(:disabled) {
  transform: translateY(2px);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -2px 0 rgba(0, 0, 0, 0.8), 0 6px 18px rgba(0, 0, 0, 0.35);
}

.user-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.user-btn.secondary {
  background: rgba(45, 45, 45, 0.95);
}

.user-btn.danger {
  background: linear-gradient(
    180deg,
    rgba(255, 110, 110, 0.85),
    rgba(170, 45, 45, 0.9)
  );
}

.user-session {
  width: min(680px, 100%);
  display: grid;
  gap: 10px;
  align-items: center;
  justify-items: center;
}

.user-session-text {
  color: rgba(255, 255, 255, 0.86);
  font-weight: 700;
  text-align: center;
}

.user-session-strong {
  color: #00ffc2;
  font-weight: 900;
}

.user-session-warn {
  color: #ffda79;
  font-weight: 900;
}

.user-session-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: center;
}

.auth-error {
  margin: 0;
  color: #ff6b6b;
  font-weight: 800;
  text-align: center;
}

.footer-text {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  color: #888;
  margin: 0;
}

.footer-link {
  color: #00ffff;
  cursor: pointer;
  text-decoration: underline;
  transition: color 0.2s;
}

.footer-link:hover {
  color: #00ff88;
  text-shadow: 0 0 8px rgba(0, 255, 136, 0.8);
}

.login-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: grid;
  place-items: center;
  padding: 18px;
  background: rgba(0, 0, 0, 0.66);
  backdrop-filter: blur(2px);
}

.login-modal {
  width: min(540px, 100%);
  background: rgba(22, 22, 22, 0.92);
  border: 4px solid rgba(0, 0, 0, 0.85);
  border-radius: 10px;
  box-shadow: 0 18px 55px rgba(0, 0, 0, 0.55),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 0 0 6px rgba(0, 0, 0, 0.55);
  overflow: hidden;
}

.login-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 14px 14px 10px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.08);
}

.login-modal-title {
  font-family: "Press Start 2P", monospace;
  color: #ffffff;
  font-size: 0.95rem;
  letter-spacing: 1px;
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.8);
}

.login-modal-close {
  border: 2px solid rgba(0, 0, 0, 0.95);
  border-radius: 8px;
  width: 42px;
  height: 38px;
  background: rgba(64, 64, 64, 0.95);
  color: #fff;
  font-weight: 900;
  cursor: pointer;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7);
}

.login-modal-close:active {
  transform: translateY(2px);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -2px 0 rgba(0, 0, 0, 0.8);
}

.login-modal-body {
  padding: 14px;
  display: grid;
  gap: 12px;
}

.login-modal-subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.78);
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.6);
}

.login-modal-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

@media (max-width: 520px) {
  .login-modal-actions {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 768px) {
  .public-view {
    padding: 18px 14px;
  }

  .arcade-title {
    font-size: 1.5rem;
  }

  .arcade-subtitle {
    font-size: 0.7rem;
  }

  .players-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }
}

@media (max-width: 420px) {
  .title-icon {
    display: none;
  }

  .stats-bar {
    padding: 14px;
  }

  .stat-value {
    font-size: 1.5rem;
  }
}
</style>
