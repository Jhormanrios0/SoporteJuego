<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div v-if="isOpen" class="help-modal-overlay" @click="closeModal">
        <div class="help-modal" @click.stop>
          <template v-if="!props.locked">
            <!-- Header -->
            <div class="help-header">
              <h2 class="help-title">
                <img src="/icons/abcde.gif" alt="" class="help-title-icon" />
                ¡Pedir Ayuda!
              </h2>
              <button
                class="help-close"
                @click="closeModal"
                aria-label="Cerrar"
              >
                <X :size="20" />
              </button>
            </div>

            <!-- Selector de tipo -->
            <div class="help-type-selector">
              <button
                class="type-btn"
                :class="{ active: helpType === 'specific' }"
                @click="helpType = 'specific'"
              >
                <UserCircle :size="18" />
                Jugador específico
              </button>
              <button
                class="type-btn"
                :class="{ active: helpType === 'general' }"
                @click="
                  helpType = 'general';
                  selectedPlayer = null;
                "
              >
                <Users :size="18" />
                Grupo general
              </button>
            </div>

            <!-- Área de mensaje -->
            <div class="help-message-area">
              <div class="textarea-wrapper">
                <textarea
                  ref="textareaRef"
                  v-model="messageText"
                  class="help-textarea"
                  placeholder="Escribe tu mensaje de ayuda..."
                  rows="4"
                  @input="handleInput"
                  @keydown="handleKeydown"
                ></textarea>

                <!-- Dropdown de menciones -->
                <Transition name="mention-slide">
                  <div
                    v-if="showMentionDropdown && filteredPlayers.length > 0"
                    class="mention-dropdown"
                    :style="mentionDropdownStyle"
                  >
                    <div class="mention-header">
                      <AtSign :size="14" />
                      <span>Mencionar jugador</span>
                    </div>
                    <div class="mention-list">
                      <button
                        v-for="(player, index) in filteredPlayers"
                        :key="player.id"
                        class="mention-item"
                        :class="{ highlighted: index === highlightedIndex }"
                        @click="selectMention(player)"
                        @mouseenter="highlightedIndex = index"
                      >
                        <span class="mention-avatar">
                          <img
                            v-if="player.image_url"
                            :src="player.image_url"
                            :alt="player.nickname"
                          />
                          <span v-else class="mention-avatar-fallback">
                            {{ getInitials(player) }}
                          </span>
                        </span>
                        <span class="mention-info">
                          <span class="mention-name">{{
                            getPlayerName(player)
                          }}</span>
                          <span class="mention-nickname"
                            >@{{ player.nickname }}</span
                          >
                        </span>
                        <span
                          class="mention-status"
                          :class="getStatusClass(player)"
                          :style="getStatusStyle(player)"
                        >
                          {{ getPlayerStatus(player) }}
                        </span>
                      </button>
                    </div>
                  </div>
                </Transition>
              </div>

              <!-- Jugador seleccionado (si es específico) -->
              <div
                v-if="helpType === 'specific' && selectedPlayer"
                class="selected-player"
              >
                <span class="selected-label">Enviando a:</span>
                <div class="selected-tag">
                  <span class="selected-avatar">
                    <img
                      v-if="selectedPlayer.image_url"
                      :src="selectedPlayer.image_url"
                      :alt="selectedPlayer.nickname"
                    />
                    <span v-else>{{ getInitials(selectedPlayer) }}</span>
                  </span>
                  <span>{{ getPlayerName(selectedPlayer) }}</span>
                  <button
                    class="remove-selected"
                    @click="selectedPlayer = null"
                  >
                    <X :size="14" />
                  </button>
                </div>
              </div>

              <div v-if="helpType === 'general'" class="general-info">
                <Info :size="16" />
                <span>Este mensaje será visible para todos los jugadores</span>
              </div>
            </div>

            <!-- Footer con botón enviar -->
            <div class="help-footer">
              <span
                class="char-count"
                :class="{ warning: messageText.length > 450 }"
              >
                {{ messageText.length }}/500
              </span>
              <button
                class="send-btn"
                :disabled="!canSend || isSending"
                @click="sendHelpRequest"
              >
                <Send :size="16" />
                {{ isSending ? "Enviando..." : "Enviar solicitud" }}
              </button>
            </div>

            <!-- Mensaje de éxito/error -->
            <Transition name="fade">
              <div
                v-if="feedbackMessage"
                class="feedback-message"
                :class="feedbackType"
              >
                <CheckCircle v-if="feedbackType === 'success'" :size="16" />
                <AlertCircle v-else :size="16" />
                {{ feedbackMessage }}
              </div>
            </Transition>
          </template>

          <template v-else>
            <div class="help-locked">
              <div class="help-locked-pad">🔒</div>
              <div class="help-locked-title">PEDIR AYUDA BLOQUEADO</div>
              <div class="help-locked-sub">
                Solo disponible en tu propio perfil
              </div>
              <div class="help-locked-note">
                Intenta desde tu perfil para enviar solicitudes.
              </div>
            </div>
          </template>
          <!-- Header, body and footer handled above (or locked visual) -->
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch, nextTick } from "vue";
import {
  X,
  UserCircle,
  Users,
  AtSign,
  Send,
  Info,
  CheckCircle,
  AlertCircle,
} from "lucide-vue-next";

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  players: {
    type: Array,
    default: () => [],
  },
  currentUserId: {
    type: String,
    default: null,
  },
  locked: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(["close", "send"]);

const textareaRef = ref(null);
const helpType = ref("specific");
const messageText = ref("");
const selectedPlayer = ref(null);
const showMentionDropdown = ref(false);
const mentionQuery = ref("");
const mentionStartIndex = ref(-1);
const highlightedIndex = ref(0);
const isSending = ref(false);
const feedbackMessage = ref("");
const feedbackType = ref("success");

const mentionDropdownStyle = ref({
  top: "0px",
  left: "0px",
});

// Filtrar jugadores para menciones (excluir al usuario actual)
const filteredPlayers = computed(() => {
  const query = mentionQuery.value.toLowerCase();
  return props.players
    .filter((p) => {
      if (p.user_id === props.currentUserId) return false;
      const nickname = (p.nickname || "").toLowerCase();
      const firstName = (p.first_name || "").toLowerCase();
      const lastName = (p.last_name || "").toLowerCase();
      return (
        nickname.includes(query) ||
        firstName.includes(query) ||
        lastName.includes(query)
      );
    })
    .slice(0, 8);
});

const canSend = computed(() => {
  const hasMessage = messageText.value.trim().length > 0;
  const withinLimit = messageText.value.length <= 500;
  const hasTarget = helpType.value === "general" || selectedPlayer.value;
  return hasMessage && withinLimit && hasTarget;
});

function closeModal() {
  emit("close");
  resetForm();
}

function resetForm() {
  messageText.value = "";
  selectedPlayer.value = null;
  helpType.value = "specific";
  showMentionDropdown.value = false;
  feedbackMessage.value = "";
}

function getPlayerName(player) {
  const first = player?.first_name?.trim() || "";
  const last = player?.last_name?.trim() || "";
  const full = `${first} ${last}`.trim();
  return full || player?.nickname || "Jugador";
}

function getInitials(player) {
  const first = player?.first_name?.[0] || "";
  const last = player?.last_name?.[0] || "";
  if (first || last) return `${first}${last}`.toUpperCase();
  return player?.nickname?.[0]?.toUpperCase() || "?";
}

function getPlayerStatus(player) {
  // Primero verificar si tiene status personalizado
  if (player?.status?.status) {
    return player.status.status;
  }
  // Fallback a activo/eliminado basado en vidas
  return player?.lives > 0 ? "Activo" : "Eliminado";
}

function getStatusClass(player) {
  // Si no tiene status personalizado, usar clase basada en vidas
  if (!player?.status?.status) {
    return { online: player?.lives > 0 };
  }
  return { "custom-status": true };
}

function getStatusStyle(player) {
  // Si tiene color personalizado en el status, usarlo
  if (player?.status?.color) {
    return {
      background: `${player.status.color}33`,
      borderColor: player.status.color,
      color: player.status.color,
    };
  }
  return {};
}

function handleInput(e) {
  const text = e.target.value;
  const cursorPos = e.target.selectionStart;

  // Buscar si estamos escribiendo una mención
  const textBeforeCursor = text.slice(0, cursorPos);
  const lastAtIndex = textBeforeCursor.lastIndexOf("@");

  if (lastAtIndex !== -1) {
    const textAfterAt = textBeforeCursor.slice(lastAtIndex + 1);
    // Verificar que no hay espacio después del @
    if (!textAfterAt.includes(" ")) {
      mentionQuery.value = textAfterAt;
      mentionStartIndex.value = lastAtIndex;
      showMentionDropdown.value = true;
      highlightedIndex.value = 0;
      updateMentionDropdownPosition();
      return;
    }
  }

  showMentionDropdown.value = false;
}

function handleKeydown(e) {
  if (!showMentionDropdown.value) return;

  if (e.key === "ArrowDown") {
    e.preventDefault();
    highlightedIndex.value = Math.min(
      highlightedIndex.value + 1,
      filteredPlayers.value.length - 1
    );
  } else if (e.key === "ArrowUp") {
    e.preventDefault();
    highlightedIndex.value = Math.max(highlightedIndex.value - 1, 0);
  } else if (e.key === "Enter" && filteredPlayers.value.length > 0) {
    e.preventDefault();
    selectMention(filteredPlayers.value[highlightedIndex.value]);
  } else if (e.key === "Escape") {
    showMentionDropdown.value = false;
  }
}

function selectMention(player) {
  const before = messageText.value.slice(0, mentionStartIndex.value);
  const after = messageText.value.slice(textareaRef.value.selectionStart);

  messageText.value = `${before}@${player.nickname} ${after}`;
  showMentionDropdown.value = false;

  // Si es tipo específico, seleccionar al jugador
  if (helpType.value === "specific" && !selectedPlayer.value) {
    selectedPlayer.value = player;
  }

  nextTick(() => {
    const newPos = before.length + player.nickname.length + 2;
    textareaRef.value?.setSelectionRange(newPos, newPos);
    textareaRef.value?.focus();
  });
}

function updateMentionDropdownPosition() {
  if (!textareaRef.value) return;

  // Obtener posición del textarea para posicionar el dropdown debajo
  const textarea = textareaRef.value;
  const rect = textarea.getBoundingClientRect();

  mentionDropdownStyle.value = {
    top: `${rect.bottom + 8}px`,
    left: `${rect.left}px`,
    width: `${rect.width}px`,
  };
}

async function sendHelpRequest() {
  if (!canSend.value || isSending.value) return;

  isSending.value = true;
  feedbackMessage.value = "";

  try {
    const payload = {
      message: messageText.value.trim(),
      type: helpType.value,
      targetPlayerId:
        helpType.value === "specific" ? selectedPlayer.value?.id : null,
      targetPlayerNickname:
        helpType.value === "specific" ? selectedPlayer.value?.nickname : null,
    };

    emit("send", payload);

    feedbackType.value = "success";
    feedbackMessage.value = "¡Solicitud enviada correctamente!";

    setTimeout(() => {
      closeModal();
    }, 1500);
  } catch (error) {
    console.error("Error enviando solicitud:", error);
    feedbackType.value = "error";
    feedbackMessage.value = "Error al enviar. Intenta de nuevo.";
  } finally {
    isSending.value = false;
  }
}

// Reset al cerrar
watch(
  () => props.isOpen,
  (newVal) => {
    if (!newVal) {
      resetForm();
    }
  }
);
</script>

<style scoped>
.help-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(0, 0, 0, 0.92);
  backdrop-filter: blur(4px);
  image-rendering: pixelated;
}

.help-modal {
  width: min(520px, 95%);
  max-height: 90vh;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border: 4px solid #8b5a2b;
  border-radius: 0;
  box-shadow: inset 0 0 0 2px #5c3d1e, inset 0 0 0 4px #3d2610,
    6px 6px 0 #1a1208, 0 0 60px rgba(139, 90, 43, 0.5),
    0 20px 60px rgba(0, 0, 0, 0.8);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  image-rendering: pixelated;
}

.help-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: linear-gradient(180deg, #3d2610 0%, #2d1f0f 100%);
  border-bottom: 4px solid #5c3d1e;
}

.help-title {
  display: flex;
  align-items: center;
  gap: 12px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  color: #ffaa00;
  margin: 0;
  text-shadow: 2px 2px 0 #000, 0 0 10px rgba(255, 170, 0, 0.5);
}

.help-title-icon {
  width: 36px;
  height: 36px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(2px 2px 0 #000);
}

.help-close {
  background: linear-gradient(180deg, #553333 0%, #331111 100%);
  border: 3px solid #882222;
  border-radius: 0;
  padding: 8px;
  color: #ff5555;
  cursor: pointer;
  transition: all 0.1s;
  box-shadow: inset 1px 1px 0 #884444, inset -1px -1px 0 #331111;
}

.help-close:hover {
  background: linear-gradient(180deg, #774444 0%, #552222 100%);
  transform: scale(1.05);
}

.help-type-selector {
  display: flex;
  gap: 12px;
  padding: 16px 20px;
  background: #1a1208;
  border-bottom: 3px solid #3d2610;
}

.type-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 16px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  background: linear-gradient(180deg, #3d2610 0%, #2d1f0f 100%);
  border: 3px solid #5c3d1e;
  border-radius: 0;
  color: #8b7355;
  cursor: pointer;
  transition: all 0.1s;
  text-shadow: 1px 1px 0 #000;
  box-shadow: inset 1px 1px 0 #5c3d1e, inset -1px -1px 0 #1a1208;
}

.type-btn:hover {
  background: linear-gradient(180deg, #4d3620 0%, #3d2610 100%);
  border-color: #8b5a2b;
}

.type-btn.active {
  background: linear-gradient(180deg, #553300 0%, #442200 100%);
  border-color: #ffaa00;
  color: #ffaa00;
  box-shadow: inset 1px 1px 0 #886600, inset -1px -1px 0 #331100,
    0 0 15px rgba(255, 170, 0, 0.3);
}

.help-message-area {
  padding: 16px 20px;
  flex: 1;
  overflow-y: auto;
  background: #1a1208;
}

.textarea-wrapper {
  position: relative;
}

.help-textarea {
  width: 100%;
  min-height: 120px;
  padding: 14px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  line-height: 1.8;
  background: rgba(0, 0, 0, 0.4);
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  color: rgba(255, 255, 255, 0.95);
  resize: vertical;
  transition: all 0.2s;
}

.help-textarea::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.help-textarea:focus {
  outline: none;
  border-color: rgba(255, 193, 7, 0.6);
  box-shadow: 0 0 20px rgba(255, 193, 7, 0.2);
}

/* Locked visual for help modal when blocked */
.help-locked {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 36px 20px;
  gap: 12px;
  color: #ffd28a;
  font-family: "Press Start 2P", monospace;
}
.help-locked-pad {
  font-size: 40px;
  filter: drop-shadow(3px 3px 0 #000);
}
.help-locked-title {
  font-size: 0.85rem;
  color: #ffdd99;
}
.help-locked-sub {
  font-size: 0.5rem;
  color: #d4a373;
}
.help-locked-note {
  font-size: 0.45rem;
  color: #b88a5a;
  opacity: 0.9;
}

/* Mention Dropdown - Sobrepuesto sobre todo */
.mention-dropdown {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: min(460px, 90vw);
  max-height: 360px;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border: 4px solid #8b5a2b;
  border-radius: 0;
  box-shadow: inset 0 0 0 2px #5c3d1e, inset 0 0 0 4px #3d2610,
    0 8px 32px rgba(0, 0, 0, 0.95), 0 0 100px rgba(139, 90, 43, 0.6);
  overflow: hidden;
  z-index: 99999;
  image-rendering: pixelated;
}

.mention-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: #7cfc00;
  background: linear-gradient(180deg, #3d2610 0%, #2d1f0f 100%);
  border-bottom: 4px solid #5c3d1e;
  text-shadow: 2px 2px 0 #000;
  letter-spacing: 1px;
}

.mention-list {
  max-height: 260px;
  overflow-y: auto;
  background: #1a1208;
}

.mention-list::-webkit-scrollbar {
  width: 12px;
}

.mention-list::-webkit-scrollbar-track {
  background: #2d1f0f;
  border-left: 2px solid #5c3d1e;
}

.mention-list::-webkit-scrollbar-thumb {
  background: linear-gradient(180deg, #8b5a2b 0%, #5c3d1e 100%);
  border: 2px solid #3d2610;
}

.mention-item {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  background: transparent;
  border: none;
  border-bottom: 3px solid #3d2610;
  color: #e8d5b0;
  cursor: pointer;
  transition: all 0.1s;
  text-align: left;
}

.mention-item:hover,
.mention-item.highlighted {
  background: linear-gradient(
    90deg,
    rgba(124, 252, 0, 0.2) 0%,
    transparent 100%
  );
  border-left: 4px solid #7cfc00;
  padding-left: 12px;
}

.mention-avatar {
  width: 40px;
  height: 40px;
  border-radius: 0;
  overflow: hidden;
  background: #3d2610;
  border: 3px solid #5c3d1e;
  flex-shrink: 0;
  image-rendering: pixelated;
}

.mention-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.mention-avatar-fallback {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: #7cfc00;
  background: linear-gradient(135deg, #2d1f0f 0%, #1a1208 100%);
  text-shadow: 1px 1px 0 #000;
}

.mention-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.mention-name {
  font-family: "Press Start 2P", monospace;
  font-size: 0.6rem;
  color: #fff;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  text-shadow: 2px 2px 0 #000;
}

.mention-nickname {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #55ff55;
  text-shadow: 1px 1px 0 #000;
}

.mention-status {
  font-family: "Press Start 2P", monospace;
  font-size: 0.45rem;
  padding: 5px 10px;
  border-radius: 0;
  background: #550000;
  border: 2px solid #880000;
  color: #ff5555;
  text-shadow: 1px 1px 0 #000;
  white-space: nowrap;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
}

.mention-status.online {
  background: #005500;
  border-color: #008800;
  color: #55ff55;
}

.mention-status.custom-status {
  background: rgba(0, 0, 0, 0.4);
  text-shadow: 1px 1px 0 rgba(0, 0, 0, 0.8);
}

/* Selected player */
.selected-player {
  margin-top: 14px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.selected-label {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
}

.selected-tag {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  background: linear-gradient(180deg, #003300 0%, #002200 100%);
  border: 3px solid #005500;
  border-radius: 0;
  box-shadow: inset 1px 1px 0 #004400, inset -1px -1px 0 #001100;
}

.selected-avatar {
  width: 28px;
  height: 28px;
  border-radius: 0;
  overflow: hidden;
  background: #002200;
  border: 2px solid #004400;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: "Press Start 2P", monospace;
  font-size: 0.4rem;
  color: #55ff55;
  image-rendering: pixelated;
}

.selected-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  image-rendering: pixelated;
}

.selected-tag > span:not(.selected-avatar) {
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  color: #55ff55;
  text-shadow: 1px 1px 0 #000;
}

.remove-selected {
  background: linear-gradient(180deg, #550000 0%, #330000 100%);
  border: 2px solid #880000;
  border-radius: 0;
  padding: 4px;
  color: #ff5555;
  cursor: pointer;
  transition: all 0.1s;
}

.remove-selected:hover {
  background: linear-gradient(180deg, #770000 0%, #550000 100%);
  transform: scale(1.1);
}

.general-info {
  margin-top: 14px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  background: linear-gradient(180deg, #332200 0%, #221100 100%);
  border: 3px solid #554400;
  border-radius: 0;
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #ffaa00;
  text-shadow: 1px 1px 0 #000;
  box-shadow: inset 1px 1px 0 #443300, inset -1px -1px 0 #110800;
}

.help-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  background: linear-gradient(180deg, #2d1f0f 0%, #1a1208 100%);
  border-top: 4px solid #5c3d1e;
}

.char-count {
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  color: #8b7355;
  text-shadow: 1px 1px 0 #000;
}

.char-count.warning {
  color: #ff5555;
}

.send-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 24px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  background: linear-gradient(180deg, #55aa55 0%, #337733 100%);
  border: 3px solid #225522;
  border-radius: 0;
  color: #fff;
  cursor: pointer;
  transition: all 0.1s;
  text-shadow: 1px 1px 0 #113311;
  box-shadow: inset 2px 2px 0 #77cc77, inset -2px -2px 0 #225522,
    3px 3px 0 #1a1208;
}

.send-btn:hover:not(:disabled) {
  background: linear-gradient(180deg, #66bb66 0%, #448844 100%);
  transform: translateY(-2px);
  box-shadow: inset 2px 2px 0 #88dd88, inset -2px -2px 0 #336633,
    3px 5px 0 #1a1208;
}

.send-btn:active:not(:disabled) {
  transform: translateY(0);
  box-shadow: inset -2px -2px 0 #77cc77, inset 2px 2px 0 #225522,
    1px 1px 0 #1a1208;
}

.send-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  filter: grayscale(0.7);
  background: linear-gradient(180deg, #555555 0%, #333333 100%);
  border-color: #222222;
}

.feedback-message {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  text-shadow: 1px 1px 0 #000;
}

.feedback-message.success {
  background: linear-gradient(180deg, #003300 0%, #002200 100%);
  border-top: 3px solid #005500;
  color: #55ff55;
}

.feedback-message.error {
  background: linear-gradient(180deg, #330000 0%, #220000 100%);
  border-top: 3px solid #550000;
  color: #ff5555;
}

/* Transitions */
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.3s ease;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.mention-slide-enter-active,
.mention-slide-leave-active {
  transition: all 0.15s ease;
}

.mention-slide-enter-from,
.mention-slide-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@media (max-width: 520px) {
  .help-modal {
    max-height: 95vh;
    width: 100%;
  }

  .help-title {
    font-size: 0.65rem;
  }

  .type-btn {
    font-size: 0.4rem;
    padding: 10px 8px;
    gap: 6px;
  }

  .help-textarea {
    font-size: 0.5rem;
    min-height: 100px;
  }

  .send-btn {
    font-size: 0.45rem;
    padding: 12px 16px;
  }

  .mention-dropdown {
    left: 10px !important;
    right: 10px !important;
    width: auto !important;
  }
}
</style>
