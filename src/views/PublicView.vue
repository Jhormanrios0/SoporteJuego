<template>
  <div class="public-view" :class="{ 'guest-locked': guestLocked }">
    <div class="public-shell">
      <!-- VIP overlay (tipo stream/live) -->
      <div class="vip-overlay" aria-label="VIP en vivo">
        <div class="vip-card">
          <div class="vip-avatar">
            <img
              v-if="vipProfile?.avatar_url"
              :src="vipProfile.avatar_url"
              alt="VIP"
              class="vip-avatar-img"
            />
            <div v-else class="vip-avatar-fallback">VIP</div>
          </div>
        </div>
      </div>

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

        <p class="arcade-subtitle">SISTEMA DE VIDAS • JUGADORES ACTIVOS</p>
        <div class="stats-bar">
          <div class="stat-item">
            <span class="stat-label">Jugadores:</span>
            <span class="stat-value">{{ activePlayersCount }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">En riesgo:</span>
            <span class="stat-value danger">{{ atRiskPlayersCount }}</span>
          </div>
          <div class="stat-item">
            <span class="stat-label">Eliminados:</span>
            <span class="stat-value eliminated">{{
              eliminatedPlayersCount
            }}</span>
          </div>
        </div>
      </header>

      <!-- Grid de jugadores -->
      <main class="players-grid">
        <PlayerCard
          v-for="player in players"
          :key="player.id"
          :player="player"
        />

        <!-- Estado vacío -->
        <div v-if="players.length === 0" class="empty-state">
          <p class="empty-message">No hay jugadores registrados</p>
          <p class="empty-hint">Inicia sesión y regístrate para aparecer</p>
        </div>
      </main>

      <!-- Footer (solo si hay error estando autenticado) -->
      <footer class="arcade-footer" v-if="!guestLocked && authError">
        <div class="user-auth">
          <p class="auth-error">{{ authError }}</p>
        </div>
      </footer>
    </div>

    <!-- Gate de invitado: blur + solo botón de entrada -->
    <div
      v-if="guestLocked && !showLoginModal"
      class="guest-gate"
      role="dialog"
      aria-modal="true"
      aria-label="Bloqueo de contenido"
    >
      <div class="guest-gate-card">
        <div class="guest-title">
          <div class="guest-title-row">
            <span class="guest-title-main">SOPORTE</span>
            <span class="guest-title-accent">SQUID GAMES</span>
          </div>
        </div>

        <button
          class="user-btn guest-enter"
          type="button"
          :disabled="authLoading"
          @click="openLoginModal"
        >
          <LogIn class="btn-icon" :size="18" />
          <span>{{ authLoading ? "CARGANDO…" : "ENTRAR AL JUEGO" }}</span>
        </button>

        <p class="guest-hint">Inicia sesión para ver el tablero.</p>

        <p v-if="authError" class="guest-error">{{ authError }}</p>
      </div>
    </div>

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

    <!-- Notificaciones de cambio de estado -->
    <StatusChangeNotification :notifications="statusNotifications" />

    <!-- Reglas -->
    <button class="book-button" @click="rulesVisible = !rulesVisible">
      <img :src="bookIconUrl" alt="Reglas" />
    </button>
    <Rules v-if="rulesVisible" @close="rulesVisible = false" />

    <!-- Campana de notificaciones -->
    <NotificationBell
      v-if="authUser"
      :notifications="helpNotifications"
      @mark-read="handleMarkNotificationRead"
      @mark-all-read="handleMarkAllRead"
      @dismiss="handleDismissNotification"
      @clear-all="handleClearAll"
    />
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
  subscribeToStatusChanges,
  subscribeToHelpRequests,
  getMyNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
  deleteNotification,
  getVipProfile,
  getSession,
  getMyPlayer,
  userLoginWithGoogle,
  userLogout,
  supabase,
} from "@/services/supabase";
import PlayerCard from "@/components/PlayerCard.vue";
import DeathNotification from "@/components/DeathNotification.vue";
import StatusChangeNotification from "@/components/StatusChangeNotification.vue";
import GameOverBanner from "@/components/GameOverBanner.vue";
import NotificationBell from "@/components/NotificationBell.vue";
import Rules from "@/components/Rules.vue";
import hahaDamageSound from "@/assets/audio/hahaDamage.mp3";
import minecraftDamageSound from "@/assets/audio/MinecraftDamage.mp3";
import {
  requestDesktopNotificationsPermission,
  showDesktopNotification,
  canUseDesktopNotifications,
} from "@/services/desktopNotifications";

const router = useRouter();
const bookIconUrl = "/icons/book.png";
const players = ref([]);
const deathNotifications = ref([]);
const statusNotifications = ref([]);
const helpNotifications = ref([]);
const vipProfile = ref(null);
let vipPollTimer = null;
let notificationId = 0;
let statusNotificationId = 0;
let playersSubscription = null;
let eventsSubscription = null;
let statusSubscription = null;
let helpSubscription = null;
let audioContext = null;
let rulesVisible = ref(false);

// Auth usuario
const authUser = ref(null);
const myPlayer = ref(null);
const authLoading = ref(false);
const authError = ref("");
let authSubscription = null;

// Menú de perfil (dropdown)
const profileMenuOpen = ref(false);
const profileMenuEl = ref(null);

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

const activePlayersCount = computed(() => {
  return players.value.filter((p) => Number(p?.lives ?? 0) > 0).length;
});

const eliminatedPlayersCount = computed(() => {
  return players.value.filter((p) => Number(p?.lives ?? 0) === 0).length;
});

const atRiskPlayersCount = computed(() => {
  // En riesgo: menos de 6 vidas, pero no eliminado
  return players.value.filter((p) => {
    const lives = Number(p?.lives ?? 0);
    return lives > 0 && lives < 6;
  }).length;
});

const profileNeedsRegister = computed(() => {
  // Registro pendiente si está autenticado pero aún no creó su jugador
  if (!authUser.value) return false;
  return !myPlayer.value?.id;
});

const guestLocked = computed(() => !authUser.value);

async function loadAuth() {
  authError.value = "";
  authLoading.value = true;
  try {
    const session = await getSession();
    authUser.value = session?.user || null;
    if (authUser.value) {
      myPlayer.value = await getMyPlayer();
    } else {
      myPlayer.value = null;
    }
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

async function refreshVipProfile() {
  try {
    vipProfile.value = await getVipProfile();
  } catch {
    vipProfile.value = vipProfile.value || null;
  }
}

function startVipPolling() {
  if (vipPollTimer) return;
  refreshVipProfile();
  vipPollTimer = window.setInterval(() => {
    refreshVipProfile();
  }, 15000);
}

function stopVipPolling() {
  if (vipPollTimer) {
    window.clearInterval(vipPollTimer);
    vipPollTimer = null;
  }
  vipProfile.value = null;
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
  goToProfile();
}

async function handleProfileMenuLogout() {
  closeProfileMenu();
  await logout();
}

function goToRegister() {
  router.push({
    name: "register",
    query: { email: authUser.value?.email || "" },
  });
}

function goToProfile() {
  router.push({ name: "profile" });
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
  document.addEventListener("click", onDocumentClick);

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

  // VIP en vista pública (para usuarios y visitantes)
  startVipPolling();

  // Cargar sesión usuario (si existe)
  await loadAuth();

  // Escuchar cambios de auth (login/logout)
  authSubscription = supabase.auth.onAuthStateChange(
    async (_event, session) => {
      const wasLoggedIn = !!authUser.value;
      authUser.value = session?.user || null;

      if (authUser.value) {
        try {
          myPlayer.value = await getMyPlayer();
        } catch {
          myPlayer.value = null;
        }

        // Cargar notificaciones y suscribirse si acaba de loguearse
        if (!wasLoggedIn) {
          await loadHelpNotifications();
          if (!helpSubscription) {
            helpSubscription = subscribeToHelpRequests((payload) => {
              handleNewHelpRequest(payload);
            });
          }
        }
      } else {
        myPlayer.value = null;
        helpNotifications.value = [];
        // Desuscribirse al hacer logout
        if (helpSubscription) {
          helpSubscription.unsubscribe();
          helpSubscription = null;
        }
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

  // Suscribirse a cambios de estado
  statusSubscription = subscribeToStatusChanges((payload) => {
    handleStatusChange(payload);
  });

  // Cargar notificaciones de ayuda y suscribirse
  if (authUser.value) {
    await loadHelpNotifications();
    helpSubscription = subscribeToHelpRequests((payload) => {
      handleNewHelpRequest(payload);
    });
  }
});

onUnmounted(() => {
  window.removeEventListener("keydown", onKeydown);
  document.removeEventListener("click", onDocumentClick);

  // Limpiar suscripciones
  if (playersSubscription) {
    playersSubscription.unsubscribe();
  }
  if (eventsSubscription) {
    eventsSubscription.unsubscribe();
  }
  if (statusSubscription) {
    statusSubscription.unsubscribe();
  }

  if (helpSubscription) {
    helpSubscription.unsubscribe();
  }

  if (authSubscription) {
    authSubscription.unsubscribe();
  }

  stopVipPolling();
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

// ==================== NOTIFICACIONES DE AYUDA ====================

async function loadHelpNotifications() {
  try {
    const data = await getMyNotifications({ limit: 50 });
    helpNotifications.value = data.map((n) => ({
      id: n.id,
      type: n.type,
      message: n.message,
      senderName:
        n.sender?.nickname ||
        `${n.sender?.first_name || ""} ${n.sender?.last_name || ""}`.trim() ||
        "Anónimo",
      senderImage: n.sender?.image_url || "",
      read: n.read,
      createdAt: n.created_at,
    }));
  } catch (e) {
    console.error("[Help] Error cargando notificaciones:", e);
    helpNotifications.value = [];
  }
}

async function handleNewHelpRequest(payload) {
  // Solo procesar si el nuevo registro nos corresponde
  const newRecord = payload?.new;
  if (!newRecord) return;

  // No mostrar mis propias solicitudes
  if (authUser.value && newRecord.sender_id === authUser.value.id) return;

  // Verificar si el mensaje es para mí
  const isForMe =
    newRecord.type === "general" ||
    (newRecord.type === "specific" &&
      myPlayer.value &&
      newRecord.target_player_id === myPlayer.value.id);

  if (!isForMe) return;

  // Obtener datos del sender
  let senderName = "Alguien";
  let senderImage = "";

  if (newRecord.sender_player_id) {
    try {
      const player = await getPlayerById(newRecord.sender_player_id);
      if (player) {
        senderName =
          player.nickname ||
          `${player.first_name || ""} ${player.last_name || ""}`.trim() ||
          "Jugador";
        senderImage = player.image_url || "";
      }
    } catch (e) {
      console.error("[Help] Error obteniendo datos del sender:", e);
    }
  }

  const notification = {
    id: newRecord.id,
    type: newRecord.type,
    message: newRecord.message,
    senderName,
    senderImage,
    read: false,
    createdAt: newRecord.created_at,
  };

  // Agregar al inicio de la lista
  helpNotifications.value.unshift(notification);

  // Desktop notification si está en segundo plano
  if (document.hidden) {
    showDesktopNotification({
      title: newRecord.type === "general" ? "Ayuda General" : "Te mencionaron",
      body: `${senderName}: ${newRecord.message}`,
      tag: `help-${newRecord.id}`,
    });
  }
}

async function handleMarkNotificationRead(notificationId) {
  try {
    await markNotificationAsRead(notificationId);
    const idx = helpNotifications.value.findIndex(
      (n) => n.id === notificationId
    );
    if (idx !== -1) {
      helpNotifications.value[idx].read = true;
    }
  } catch (e) {
    console.error("[Help] Error marcando notificación como leída:", e);
  }
}

async function handleMarkAllRead() {
  try {
    await markAllNotificationsAsRead();
    helpNotifications.value.forEach((n) => (n.read = true));
  } catch (e) {
    console.error("[Help] Error marcando todas como leídas:", e);
  }
}

async function handleDismissNotification(notificationId) {
  try {
    await deleteNotification(notificationId);
    helpNotifications.value = helpNotifications.value.filter(
      (n) => n.id !== notificationId
    );
  } catch (e) {
    console.error("[Help] Error eliminando notificación:", e);
  }
}

function handleClearAll() {
  // Eliminar todas las notificaciones una por una
  const ids = helpNotifications.value.map((n) => n.id);
  Promise.all(ids.map((id) => deleteNotification(id))).then(() => {
    helpNotifications.value = [];
  });
}

async function handleStatusChange(payload) {
  console.log("[Status] Cambio de estado recibido:", payload);

  // Verificar que hay cambios en la columna status
  if (payload?.new && payload.new.status) {
    const oldStatus = payload.old?.status;
    const newStatus = payload.new.status;

    // Solo notificar si realmente cambió el status
    if (JSON.stringify(oldStatus) === JSON.stringify(newStatus)) return;

    // No notificar si es el propio usuario quien cambió
    if (authUser.value && payload.new.id === authUser.value.id) return;

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

      // Notificación de escritorio
      if (canUseDesktopNotifications() && document.hidden) {
        showDesktopNotification(
          "✨ Cambio de estado",
          `${playerName}: ${newStatus.status}`
        ).catch(() => {
          // noop
        });
      }

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

  if (e.key === "Escape" && profileMenuOpen.value) {
    closeProfileMenu();
  }
}
</script>

<style scoped>
.public-view {
  min-height: 100vh;
  padding: 20px;
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

.public-shell {
  position: relative;
  z-index: 2;
}

.public-view.guest-locked {
  overflow: hidden;
}

.public-view.guest-locked .public-shell {
  filter: blur(11px) saturate(0.6) brightness(0.72);
  transform: scale(1.02);
  pointer-events: none;
  user-select: none;
}

.guest-gate {
  position: fixed;
  inset: 0;
  z-index: 2500;
  display: grid;
  place-items: center;
  padding: 24px;
  background: radial-gradient(
      circle at 50% 35%,
      rgba(0, 255, 194, 0.08) 0%,
      rgba(0, 0, 0, 0.76) 55%
    ),
    rgba(0, 0, 0, 0.68);
  backdrop-filter: blur(3px);
}

.guest-gate-card {
  width: min(520px, 100%);
  padding: 18px 18px 16px;
  border-radius: 14px;
  border: 2px solid rgba(0, 255, 194, 0.55);
  background: linear-gradient(
    180deg,
    rgba(10, 14, 12, 0.92),
    rgba(0, 0, 0, 0.76)
  );
  box-shadow: 0 18px 60px rgba(0, 0, 0, 0.62), 0 0 0 2px rgba(0, 0, 0, 0.75),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 0 0 8px rgba(0, 0, 0, 0.35), 0 0 32px rgba(0, 255, 194, 0.18);
  display: grid;
  gap: 12px;
  justify-items: center;
  position: relative;
  overflow: hidden;
}

.guest-gate-card::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    /* Bloques estilo Minecraft */ repeating-linear-gradient(
      90deg,
      rgba(0, 255, 194, 0.06) 0px,
      rgba(0, 255, 194, 0.06) 2px,
      transparent 2px,
      transparent 18px
    ),
    repeating-linear-gradient(
      0deg,
      rgba(0, 255, 194, 0.04) 0px,
      rgba(0, 255, 194, 0.04) 2px,
      transparent 2px,
      transparent 18px
    ),
    radial-gradient(circle at 30% 20%, rgba(0, 255, 136, 0.12), transparent 45%),
    radial-gradient(
      circle at 75% 80%,
      rgba(247, 65, 143, 0.12),
      transparent 55%
    );
  opacity: 0.55;
  pointer-events: none;
}

.guest-gate-card::after {
  /* Marco pixelado */
  content: "";
  position: absolute;
  inset: 10px;
  border: 2px solid rgba(255, 255, 255, 0.08);
  border-radius: 10px;
  box-shadow: inset 0 0 0 2px rgba(0, 255, 194, 0.18),
    0 0 0 2px rgba(0, 0, 0, 0.55);
  pointer-events: none;
}

.guest-title {
  position: relative;
  z-index: 1;
  display: grid;
  gap: 8px;
  text-align: center;
}

.guest-title-row {
  display: flex;
  align-items: baseline;
  justify-content: center;
  flex-wrap: wrap;
  gap: 10px;
}

.guest-title-main {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(1rem, 2.6vw, 1.35rem);
  color: #00ffc2;
  text-shadow: 0 0 12px rgba(0, 255, 194, 0.55);
  letter-spacing: 2px;
}

.guest-title-accent {
  font-family: "Press Start 2P", monospace;
  font-size: clamp(1rem, 2.6vw, 1.35rem);
  color: #ff2a6d;
  text-shadow: 0 0 12px rgba(255, 42, 109, 0.5);
  letter-spacing: 2px;
}

.guest-title-sub {
  font-family: "Press Start 2P", monospace;
  font-size: 0.58rem;
  color: rgba(255, 255, 255, 0.72);
  letter-spacing: 1px;
}

.guest-enter {
  width: 100%;
  justify-content: center;
  padding: 14px 16px;
  position: relative;
  z-index: 1;
}

.guest-hint {
  margin: 0;
  position: relative;
  z-index: 1;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.92rem;
  text-align: center;
}

.guest-error {
  margin: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: #ffda79;
  text-align: center;
  line-height: 1.5;
  position: relative;
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
  padding: 40px 20px;
  border-bottom: 3px solid rgba(247, 65, 143, 0.3);
}

/* VIP overlay tipo stream/live */
.vip-overlay {
  position: fixed;
  top: 12px;
  left: 12px;
  z-index: 1006;
  display: grid;
  gap: 8px;
  pointer-events: none;
}

.vip-card {
  justify-self: start;
  position: relative;
  display: grid;
  grid-template-columns: 1fr;
  gap: 0;
  align-items: center;
  padding: 8px;
  border: 2px solid rgba(0, 255, 194, 0.65);
  border-radius: 16px;
  background: rgba(0, 0, 0, 0.75);
  box-shadow: 0 16px 34px rgba(0, 0, 0, 0.45),
    inset 0 0 0 2px rgba(255, 255, 255, 0.05);
  max-width: none;
}

.vip-card::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: 16px;
  background: repeating-linear-gradient(
    0deg,
    rgba(0, 0, 0, 0.14),
    rgba(0, 0, 0, 0.14) 2px,
    transparent 2px,
    transparent 4px
  );
  opacity: 0.35;
  pointer-events: none;
}

.vip-avatar {
  width: clamp(140px, 18vw, 220px);
  height: clamp(140px, 18vw, 220px);
  border-radius: 16px;
  border: 2px solid rgba(0, 255, 194, 0.6);
  overflow: hidden;
  background: rgba(0, 0, 0, 0.6);
  display: grid;
  place-items: center;
  box-shadow: inset 0 -10px 0 rgba(0, 0, 0, 0.6),
    0 18px 40px rgba(0, 0, 0, 0.45);
}

.vip-avatar-img {
  width: clamp(140px, 18vw, 220px);
  height: clamp(140px, 18vw, 220px);
  object-fit: cover;
  image-rendering: pixelated;
}

.vip-avatar-fallback {
  font-family: "Press Start 2P", monospace;
  font-size: 1.05rem;
  color: rgba(0, 255, 194, 0.95);
  text-shadow: 0 0 12px rgba(0, 255, 194, 0.65);
}

@media (max-width: 520px) {
  .vip-avatar {
    width: clamp(120px, 30vw, 180px);
    height: clamp(120px, 30vw, 180px);
  }
}

.profile-menu {
  position: absolute;
  top: 12px;
  right: 12px;
  left: auto;
  z-index: 1005;
  display: inline-block;
  max-width: min(320px, calc(100% - 24px));
}

.profile-button {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border: 2px solid rgba(0, 255, 194, 0.7);
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

/* Animación retro (pixel-pop) */
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

.profile-name {
  font-family: "Press Start 2P", monospace;
  font-size: 0.62rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.55);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 230px;
}

.profile-sub {
  font-family: "Press Start 2P", monospace;
  font-size: 0.52rem;
  color: #ffda79;
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
  gap: clamp(14px, 2.5vw, 34px);
  margin-top: 30px;
  padding: 20px;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid rgba(247, 65, 143, 0.3);
  border-radius: 8px;
  width: min(720px, 100%);
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

.stat-value.eliminated {
  color: #ff2a6d;
  text-shadow: 0 0 15px rgba(255, 42, 109, 0.75);
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
  z-index: 3000;
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

  .profile-menu {
    top: 10px;
    right: 10px;
  }

  .vip-overlay {
    top: 10px;
    left: 10px;
  }

  .profile-name {
    max-width: 220px;
  }
}

.book-button {
  position: fixed;
  bottom: 20px;
  left: 20px;
  width: 50px;
  height: 50px;
  border: none;
  background-color: #fa9393;
  border-radius: 10px;
  padding: 5px;
  cursor: pointer;
  z-index: 1000;
}

.book-button img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.book-button:hover {
  background-color: #ffb3b3;
  transform: scale(1.05);
  transition: transform 0.2s;
}
</style>
