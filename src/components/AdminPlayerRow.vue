<template>
  <div class="admin-player-row">
    <div class="player-info">
      <div class="player-ident">
        <div class="avatar-frame" aria-hidden="true">
          <img
            v-if="avatarUrl && !avatarFailed"
            :src="avatarUrl"
            class="avatar-img"
            alt=""
            @error="avatarFailed = true"
          />
          <div v-else class="avatar-placeholder">
            <CreeperIcon :size="54" class="avatar-creeper" />
            <span class="avatar-initials">{{ initials }}</span>
          </div>
        </div>

        <span class="player-name">{{ displayName }}</span>
      </div>
      <HeartsBar :lives="player.lives" :max-lives="player.max_lives || 12" />
    </div>

    <div class="admin-actions">
      <!-- Botones rápidos -->
      <button
        @click="removeLives(1)"
        class="btn-action btn-minus"
        :disabled="player.lives === 0"
      >
        -1
      </button>
      <button
        @click="removeLives(3)"
        class="btn-action btn-minus"
        :disabled="player.lives === 0"
      >
        -3
      </button>

      <!-- Input manual -->
      <input
        v-model.number="customAmount"
        type="number"
        min="1"
        :max="player.lives"
        placeholder="Otro"
        class="custom-input"
        :disabled="player.lives === 0"
      />
      <button
        @click="removeCustom"
        class="btn-action btn-custom"
        :disabled="player.lives === 0 || !customAmount"
      >
        OK
      </button>

      <!-- Reset individual -->
      <button
        @click="resetLives"
        class="btn-action btn-reset"
        :disabled="player.lives === 12"
      >
        Reset
      </button>

      <!-- Eliminar jugador -->
      <button @click="$emit('delete', player.id)" class="btn-action btn-delete">
        <Trash2 :size="16" />
      </button>
    </div>

    <!-- Campo de razón -->
    <div class="reason-input">
      <input
        v-model="reason"
        type="text"
        placeholder="Razón (opcional)"
        class="reason-field"
        maxlength="100"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";
import { Trash2 } from "lucide-vue-next";
import HeartsBar from "./HeartsBar.vue";
import CreeperIcon from "./CreeperIcon.vue";

const props = defineProps({
  player: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(["remove-lives", "reset", "delete"]);

const displayName = computed(() => {
  const first = props.player?.first_name?.trim?.() || "";
  const last = props.player?.last_name?.trim?.() || "";
  const full = `${first} ${last}`.trim();
  return full || props.player?.nickname || "Jugador";
});

const avatarUrl = computed(() => String(props.player?.image_url || "").trim());
const avatarFailed = ref(false);

const initials = computed(() => {
  const name = displayName.value || "";
  const parts = name
    .split(" ")
    .map((p) => p.trim())
    .filter(Boolean);
  const first = parts[0]?.[0] || "?";
  const second = parts.length > 1 ? parts[1]?.[0] : "";
  return (first + second).toUpperCase();
});

const avatarSize = computed(() => 84);

const customAmount = ref(null);
const reason = ref("");

function removeLives(amount) {
  emit("remove-lives", props.player.id, amount, reason.value);
  reason.value = ""; // Limpiar después de usar
}

function removeCustom() {
  if (customAmount.value && customAmount.value > 0) {
    emit("remove-lives", props.player.id, customAmount.value, reason.value);
    customAmount.value = null;
    reason.value = "";
  }
}

function resetLives() {
  emit("reset", props.player.id);
  reason.value = "";
}
</script>

<style scoped>
.admin-player-row {
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid #00ff88;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 12px;
  box-shadow: 0 0 15px rgba(0, 255, 136, 0.2);
}

.player-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid rgba(0, 255, 136, 0.3);
}

.player-ident {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.avatar-frame {
  width: 84px;
  height: 84px;
  border-radius: 10px;
  border: 3px solid rgba(0, 0, 0, 0.9);
  background: rgba(20, 20, 20, 0.95);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.05),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7);
  overflow: hidden;
  flex: 0 0 auto;
  transform: translateZ(0);
  transition: transform 120ms ease, filter 140ms ease;
}

.admin-player-row:hover .avatar-frame {
  transform: translateY(-1px);
  filter: brightness(1.05);
}

.avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
  transform: translateZ(0);
}

.avatar-placeholder {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  background: linear-gradient(
    180deg,
    rgba(52, 52, 52, 0.9),
    rgba(24, 24, 24, 0.95)
  );
  position: relative;
}

.avatar-creeper {
  animation: creeperBob 1.4s ease-in-out infinite;
}

.avatar-initials {
  position: absolute;
  right: 6px;
  bottom: 6px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: rgba(255, 255, 255, 0.9);
  background: rgba(0, 0, 0, 0.55);
  border: 2px solid rgba(0, 0, 0, 0.85);
  border-radius: 6px;
  padding: 4px 6px;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06);
}

@keyframes creeperBob {
  0%,
  100% {
    transform: translateY(0);
    filter: brightness(1);
  }
  50% {
    transform: translateY(-2px);
    filter: brightness(1.08);
  }
}

.player-name {
  font-family: "Press Start 2P", monospace;
  font-size: 1rem;
  color: #00ff88;
  text-shadow: 0 0 8px rgba(0, 255, 136, 0.6);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
}

.admin-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
}

.btn-action {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  padding: 8px 16px;
  border: 2px solid;
  border-radius: 4px;
  background: rgba(0, 0, 0, 0.5);
  cursor: pointer;
  transition: all 0.2s;
  text-transform: uppercase;
}

.btn-action:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 255, 255, 0.4);
}

.btn-action:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.btn-minus {
  border-color: #ff0055;
  color: #ff0055;
}

.btn-minus:hover:not(:disabled) {
  background: rgba(255, 0, 85, 0.2);
  box-shadow: 0 4px 12px rgba(255, 0, 85, 0.5);
}

.btn-custom {
  border-color: #ffaa00;
  color: #ffaa00;
}

.btn-custom:hover:not(:disabled) {
  background: rgba(255, 170, 0, 0.2);
}

.btn-reset {
  border-color: #00ffff;
  color: #00ffff;
}

.btn-reset:hover:not(:disabled) {
  background: rgba(0, 255, 255, 0.2);
}

.btn-delete {
  border-color: #ff3366;
  color: #ff3366;
  font-size: 1rem;
  padding: 8px 12px;
}

.btn-delete:hover:not(:disabled) {
  background: rgba(255, 51, 102, 0.2);
}

.custom-input {
  width: 80px;
  padding: 8px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  background: rgba(0, 0, 0, 0.7);
  border: 2px solid #ffaa00;
  border-radius: 4px;
  color: #ffaa00;
  text-align: center;
}

.custom-input:focus {
  outline: none;
  box-shadow: 0 0 12px rgba(255, 170, 0, 0.5);
}

.custom-input:disabled {
  opacity: 0.3;
}

.reason-input {
  margin-top: 8px;
}

.reason-field {
  width: 100%;
  padding: 10px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  background: rgba(0, 0, 0, 0.7);
  border: 2px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
}

.reason-field:focus {
  outline: none;
  box-shadow: 0 0 12px rgba(0, 255, 136, 0.5);
}

.reason-field::placeholder {
  color: rgba(0, 255, 136, 0.4);
}

@media (max-width: 768px) {
  .player-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .admin-actions {
    justify-content: center;
  }

  .btn-action {
    font-size: 0.65rem;
    padding: 6px 12px;
  }
}
</style>
