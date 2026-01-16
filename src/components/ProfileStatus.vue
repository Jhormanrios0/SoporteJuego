<script setup>
import { ref, computed, onMounted, onUnmounted } from "vue";
import { supabase } from "@/services/supabase";
import { Pencil, X, Check } from "lucide-vue-next";

const props = defineProps({
  userId: {
    type: String,
    required: false,
  },
});

const isEditing = ref(false);
const statusText = ref("Sin estado");
const statusColor = ref("#00ffc2");
const tempStatusText = ref("");
const tempStatusColor = ref("#00ffc2");
const isLoading = ref(false);
const errorMsg = ref("");

const maxChars = 20;

const displayColor = computed(() => {
  return isEditing.value ? tempStatusColor.value : statusColor.value;
});

const displayText = computed(() => {
  return isEditing.value ? tempStatusText.value : statusText.value;
});

const remainingChars = computed(() => {
  return maxChars - tempStatusText.value.length;
});

let statusSubscription = null;

async function loadStatus() {
  try {
    let userId = props.userId;

    if (!userId) {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) return;
      userId = user.id;
    }

    const { data, error } = await supabase
      .from("profiles")
      .select("status")
      .eq("id", userId)
      .maybeSingle();

    // Si no hay error y hay datos con status
    if (!error && data?.status) {
      statusText.value = data.status.status || "Sin estado";
      statusColor.value = data.status.color || "#00ffc2";
    }

    // Suscribirse a cambios en tiempo real
    setupRealtimeSubscription(userId);
  } catch (error) {
    // Silenciar errores para mantener limpia la consola
  }
}

function setupRealtimeSubscription(userId) {
  // Limpiar suscripción anterior si existe
  if (statusSubscription) {
    statusSubscription.unsubscribe();
  }

  console.log('[ProfileStatus] Setting up realtime for userId:', userId);

  // Suscribirse a cambios en el perfil específico
  statusSubscription = supabase
    .channel(`profile-status-${userId}`)
    .on(
      "postgres_changes",
      {
        event: "UPDATE",
        schema: "public",
        table: "profiles",
        filter: `id=eq.${userId}`,
      },
      (payload) => {
        console.log('[ProfileStatus] Realtime update received:', payload);
        if (payload.new?.status) {
          statusText.value = payload.new.status.status || "Sin estado";
          statusColor.value = payload.new.status.color || "#00ffc2";
          console.log('[ProfileStatus] Status updated in realtime:', statusText.value, statusColor.value);
        }
      }
    )
    .subscribe((status) => {
      console.log('[ProfileStatus] Subscription status:', status);
    });
}

function startEdit() {
  tempStatusText.value = statusText.value;
  tempStatusColor.value = statusColor.value;
  isEditing.value = true;
  errorMsg.value = "";
}

function cancelEdit() {
  isEditing.value = false;
  tempStatusText.value = "";
  errorMsg.value = "";
}

async function saveStatus() {
  if (tempStatusText.value.length > maxChars) {
    errorMsg.value = `Máximo ${maxChars} caracteres`;
    return;
  }

  if (tempStatusText.value.trim() === "") {
    errorMsg.value = "El estado no puede estar vacío";
    return;
  }

  isLoading.value = true;
  errorMsg.value = "";

  try {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) throw new Error("No hay usuario autenticado");

    const statusData = {
      status: tempStatusText.value.trim(),
      color: tempStatusColor.value,
    };

    const { error } = await supabase
      .from("profiles")
      .update({ status: statusData })
      .eq("id", user.id);

    if (error) throw error;

    statusText.value = statusData.status;
    statusColor.value = statusData.color;
    isEditing.value = false;
  } catch (error) {
    console.error("Error saving status:", error);
    errorMsg.value = "Error al guardar el estado";
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  loadStatus();
});

onUnmounted(() => {
  if (statusSubscription) {
    statusSubscription.unsubscribe();
  }
});
</script>

<template>
  <div class="status-wrapper">
    <div
      v-if="!isEditing"
      class="indentity-status"
      :style="{
        color: statusColor,
        background: `${statusColor}1F`,
        borderColor: `${statusColor}73`,
        textShadow: `0 0 8px ${statusColor}80`,
      }"
    >
      <span class="status-text">{{ statusText }}</span>
      <button
        v-if="!props.userId"
        class="status-edit-btn"
        @click="startEdit"
        aria-label="Editar estado"
      >
        <Pencil :size="12" />
      </button>
    </div>

    <div v-else class="status-editor">
      <div class="editor-row">
        <input
          v-model="tempStatusText"
          type="text"
          :maxlength="maxChars"
          placeholder="Escribe tu estado..."
          class="status-input"
          :style="{
            color: tempStatusColor,
            borderColor: `${tempStatusColor}73`,
          }"
        />
        <input
          v-model="tempStatusColor"
          type="color"
          class="color-picker"
          aria-label="Seleccionar color"
        />
      </div>

      <div class="char-counter" :class="{ warning: remainingChars < 5 }">
        {{ remainingChars }} caracteres restantes
      </div>

      <div v-if="errorMsg" class="error-msg">{{ errorMsg }}</div>

      <div class="editor-actions">
        <button
          class="action-btn save"
          @click="saveStatus"
          :disabled="isLoading"
          aria-label="Guardar estado"
        >
          <Check :size="14" />
          {{ isLoading ? "Guardando..." : "Guardar" }}
        </button>
        <button
          class="action-btn cancel"
          @click="cancelEdit"
          :disabled="isLoading"
          aria-label="Cancelar"
        >
          <X :size="14" />
          Cancelar
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.status-wrapper {
  margin-top: 12px;
}

.indentity-status {
  display: inline-flex;
  width: fit-content;
  align-items: center;
  gap: 8px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  border: 2px solid;
  border-radius: 8px;
  padding: 8px 12px;
  box-shadow: inset 0 -4px 0 rgba(0, 0, 0, 0.5), 0 0 15px currentColor;
  animation: statusPulse 2s ease-in-out infinite;
  position: relative;
}

.indentity-status::before {
  content: "●";
  font-size: 0.7rem;
  animation: statusBlink 1.5s ease-in-out infinite;
  filter: drop-shadow(0 0 6px currentColor);
}

.status-text {
  flex: 1;
}

.status-edit-btn {
  background: none;
  border: none;
  color: currentColor;
  cursor: pointer;
  padding: 2px;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.6;
  transition: opacity 0.2s;
}

.status-edit-btn:hover {
  opacity: 1;
}

.status-editor {
  background: rgba(0, 0, 0, 0.4);
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  padding: 12px;
  font-family: "Press Start 2P", monospace;
}

.editor-row {
  display: flex;
  gap: 8px;
  margin-bottom: 8px;
}

.status-input {
  flex: 1;
  background: rgba(0, 0, 0, 0.6);
  border: 2px solid;
  border-radius: 6px;
  padding: 8px 10px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.55rem;
  outline: none;
  transition: all 0.2s;
}

.status-input:focus {
  box-shadow: 0 0 10px currentColor;
}

.color-picker {
  width: 40px;
  height: 36px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 6px;
  cursor: pointer;
  background: none;
  padding: 2px;
}

.char-counter {
  font-size: 0.45rem;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 8px;
}

.char-counter.warning {
  color: #ff6b6b;
}

.error-msg {
  font-size: 0.45rem;
  color: #ff6b6b;
  margin-bottom: 8px;
  padding: 4px 8px;
  background: rgba(255, 107, 107, 0.1);
  border-radius: 4px;
  border: 1px solid rgba(255, 107, 107, 0.3);
}

.editor-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.5rem;
  padding: 8px 12px;
  border: 2px solid;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  background: rgba(0, 0, 0, 0.4);
}

.action-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.action-btn.save {
  color: #00ff88;
  border-color: #00ff88;
}

.action-btn.save:hover:not(:disabled) {
  background: rgba(0, 255, 136, 0.1);
  box-shadow: 0 0 10px rgba(0, 255, 136, 0.3);
}

.action-btn.cancel {
  color: #ff6b6b;
  border-color: #ff6b6b;
}

.action-btn.cancel:hover:not(:disabled) {
  background: rgba(255, 107, 107, 0.1);
  box-shadow: 0 0 10px rgba(255, 107, 107, 0.3);
}

@keyframes statusPulse {
  0%,
  100% {
    box-shadow: inset 0 -4px 0 rgba(0, 0, 0, 0.5), 0 0 15px currentColor;
  }

  50% {
    box-shadow: inset 0 -4px 0 rgba(0, 0, 0, 0.5), 0 0 25px currentColor;
  }
}

@keyframes statusBlink {
  0%,
  100% {
    opacity: 1;
  }

  50% {
    opacity: 0.5;
  }
}
</style>