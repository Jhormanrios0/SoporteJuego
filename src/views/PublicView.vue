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
        <p class="empty-hint">El admin debe crear jugadores desde /admin</p>
      </div>
    </main>

    <!-- Footer -->
    <footer class="arcade-footer">
      <p class="footer-text">
        Actualización en tiempo real •
        <span class="footer-link" @click="goToAdmin">Admin Panel</span>
      </p>
    </footer>

    <!-- Notificaciones de muerte -->
    <DeathNotification :notifications="deathNotifications" />
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";
import { useRouter } from "vue-router";
import { Gamepad2 } from "lucide-vue-next";
import {
  getPlayers,
  subscribeToPlayers,
  subscribeToLifeEvents,
} from "@/services/supabase";
import PlayerCard from "@/components/PlayerCard.vue";
import DeathNotification from "@/components/DeathNotification.vue";
import hahaDamageSound from "@/assets/audio/hahaDamage.mp3";
import minecraftDamageSound from "@/assets/audio/MinecraftDamage.mp3";

const router = useRouter();
const players = ref([]);
const deathNotifications = ref([]);
let notificationId = 0;
let playersSubscription = null;
let eventsSubscription = null;
let audioContext = null;

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
  // Intentar inicializar AudioContext inmediatamente
  initializeAudioContext();

  // También agregarlo como listener de respaldo
  document.addEventListener("click", initializeAudioContext, { once: true });

  // Cargar jugadores iniciales
  await loadPlayers();

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
  // Limpiar suscripciones
  if (playersSubscription) {
    playersSubscription.unsubscribe();
  }
  if (eventsSubscription) {
    eventsSubscription.unsubscribe();
  }
});

async function loadPlayers() {
  players.value = await getPlayers();
}

function handleDeathEvent(payload) {
  console.log("[Events] Evento recibido:", payload);

  // Solo mostrar notificaciones cuando se quitan vidas (delta negativo)
  if (payload.new && payload.new.delta < 0 && payload.new.reason) {
    console.log("[Audio] Reproduciendo sonido de daño...");

    // Buscar las vidas actuales del jugador
    const player = players.value.find((p) => p.id === payload.new.player_id);
    const currentLives = player ? player.lives : 0;

    // Reproducir sonido de daño
    playDamageSound(currentLives);

    const id = ++notificationId;
    const notification = {
      id,
      message: payload.new.reason,
      index: deathNotifications.value.length,
    };

    deathNotifications.value.push(notification);

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
  }
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
  margin-bottom: 60px;
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

.title-container {
  position: relative;
  display: inline-block;
  padding: 20px 40px;
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
  font-size: 2rem;
  margin: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px;
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
  font-size: 0.85rem;
  color: #00ffc2;
  text-shadow: 0 0 10px rgba(0, 255, 194, 0.8);
  margin: 20px 0;
  letter-spacing: 3px;
}

.stats-bar {
  display: flex;
  justify-content: center;
  gap: 40px;
  margin-top: 30px;
  padding: 20px;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid rgba(247, 65, 143, 0.3);
  border-radius: 8px;
  max-width: 500px;
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
  max-width: 1400px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 30px;
  position: relative;
  z-index: 2;
  padding: 0 20px;
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
  margin-top: 60px;
  position: relative;
  z-index: 2;
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

@media (max-width: 768px) {
  .public-view {
    padding: 20px 16px;
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
</style>
