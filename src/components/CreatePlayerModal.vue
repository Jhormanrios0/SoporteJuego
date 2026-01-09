<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="show" class="modal-overlay" @click="handleOverlayClick">
        <div class="modal-container" @click.stop>
          <div class="modal-header">
            <h2 class="modal-title">CREAR NUEVO JUGADOR</h2>
            <button @click="$emit('cancel')" class="modal-close">
              &times;
            </button>
          </div>

          <div class="modal-body">
            <div class="form-group">
              <label class="form-label">Nickname</label>
              <input
                v-model="formData.nickname"
                type="text"
                placeholder="Nombre del jugador"
                class="form-input"
                maxlength="30"
                @keyup.enter="handleCreate"
              />
            </div>

            <div class="form-group">
              <label class="form-label">Imagen (opcional)</label>
              <div class="image-upload">
                <div v-if="previewImage" class="image-preview">
                  <img :src="previewImage" :alt="formData.nickname" />
                  <button @click="removeImage" class="remove-image-btn">
                    ✕
                  </button>
                </div>
                <div
                  v-else
                  class="upload-placeholder"
                  @click="triggerFileInput"
                >
                  <input
                    ref="fileInput"
                    type="file"
                    accept="image/*"
                    class="file-input"
                    @change="handleImageSelect"
                  />
                  <div class="upload-hint">
                    <span class="upload-icon">📸</span>
                    <p>Haz clic o arrastra una imagen</p>
                  </div>
                </div>
              </div>
            </div>

            <p v-if="error" class="error-message">{{ error }}</p>
          </div>

          <div class="modal-actions">
            <button @click="$emit('cancel')" class="modal-btn btn-cancel">
              Cancelar
            </button>
            <button
              @click="handleCreate"
              class="modal-btn btn-confirm"
              :disabled="!formData.nickname.trim() || loading"
            >
              {{ loading ? "CARGANDO..." : "CREAR" }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch } from "vue";

const props = defineProps({
  show: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(["cancel", "create"]);

const formData = ref({
  nickname: "",
  imageFile: null,
});

const previewImage = ref("");
const fileInput = ref(null);
const loading = ref(false);
const error = ref("");

watch(
  () => props.show,
  (newVal) => {
    if (!newVal) {
      resetForm();
    }
  }
);

function handleImageSelect(event) {
  const file = event.target.files?.[0];
  if (!file) return;

  // Validar que sea imagen
  if (!file.type.startsWith("image/")) {
    error.value = "Por favor selecciona una imagen válida";
    return;
  }

  // Validar tamaño (máximo 5MB)
  if (file.size > 5 * 1024 * 1024) {
    error.value = "La imagen no debe superar 5MB";
    return;
  }

  formData.value.imageFile = file;
  error.value = "";

  // Mostrar preview
  const reader = new FileReader();
  reader.onload = (e) => {
    previewImage.value = e.target?.result || "";
  };
  reader.readAsDataURL(file);
}

function triggerFileInput() {
  fileInput.value?.click();
}

function removeImage() {
  formData.value.imageFile = null;
  previewImage.value = "";
  if (fileInput.value) {
    fileInput.value.value = "";
  }
}

async function handleCreate() {
  error.value = "";

  if (!formData.value.nickname.trim()) {
    error.value = "El nickname es requerido";
    return;
  }

  loading.value = true;

  try {
    await emit("create", {
      nickname: formData.value.nickname.trim(),
      imageFile: formData.value.imageFile,
    });
    resetForm();
  } catch (err) {
    error.value = "Error al crear jugador";
    console.error(err);
  } finally {
    loading.value = false;
  }
}

function handleOverlayClick() {
  emit("cancel");
}

function resetForm() {
  formData.value.nickname = "";
  formData.value.imageFile = null;
  previewImage.value = "";
  error.value = "";
  if (fileInput.value) {
    fileInput.value.value = "";
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  backdrop-filter: blur(4px);
}

.modal-container {
  background: #0a0a0a;
  border: 4px solid #00ff88;
  border-radius: 8px;
  padding: 32px;
  max-width: 600px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 0 40px rgba(0, 255, 136, 0.5),
    inset 0 0 30px rgba(0, 255, 136, 0.1);
  animation: modalPulse 0.3s ease-out;
}

@keyframes modalPulse {
  0% {
    transform: scale(0.9);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 2px solid rgba(0, 255, 136, 0.3);
}

.modal-title {
  font-family: "Press Start 2P", monospace;
  font-size: 1.2rem;
  color: #00ff88;
  text-shadow: 0 0 10px rgba(0, 255, 136, 0.8);
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 2rem;
  color: #00ff88;
  cursor: pointer;
  padding: 0;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.modal-close:hover {
  color: #f7418f;
  text-shadow: 0 0 10px rgba(247, 65, 143, 0.8);
}

.modal-body {
  margin-bottom: 24px;
}

.form-group {
  margin-bottom: 24px;
}

.form-label {
  display: block;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  color: #00ffff;
  margin-bottom: 12px;
  text-shadow: 0 0 5px rgba(0, 255, 255, 0.6);
}

.form-input {
  width: 100%;
  padding: 12px 16px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  background: rgba(0, 0, 0, 0.8);
  border: 2px solid #00ff88;
  border-radius: 4px;
  color: #00ff88;
  box-sizing: border-box;
}

.form-input:focus {
  outline: none;
  box-shadow: 0 0 15px rgba(0, 255, 136, 0.6);
  border-color: #00ffff;
}

/* IMAGE UPLOAD */
.image-upload {
  margin-top: 12px;
}

.image-preview {
  position: relative;
  width: 100%;
  height: 200px;
  border: 2px solid #00ff88;
  border-radius: 8px;
  overflow: hidden;
  background: rgba(0, 0, 0, 0.6);
}

.image-preview img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.remove-image-btn {
  position: absolute;
  top: 8px;
  right: 8px;
  background: rgba(255, 0, 85, 0.8);
  border: none;
  color: white;
  width: 32px;
  height: 32px;
  border-radius: 4px;
  font-size: 1.2rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.remove-image-btn:hover {
  background: rgba(255, 0, 85, 1);
  box-shadow: 0 0 15px rgba(255, 0, 85, 0.6);
}

.upload-placeholder {
  border: 2px dashed #00ff88;
  border-radius: 8px;
  padding: 32px;
  text-align: center;
  background: rgba(0, 255, 136, 0.05);
  cursor: pointer;
  transition: all 0.2s;
}

.upload-placeholder:hover {
  border-color: #00ffff;
  background: rgba(0, 255, 194, 0.1);
}

.file-input {
  display: none;
}

.upload-hint {
  color: #00ff88;
  pointer-events: none;
}

.upload-icon {
  font-size: 2rem;
  display: block;
  margin-bottom: 8px;
}

.upload-hint p {
  font-family: "Press Start 2P", monospace;
  font-size: 0.75rem;
  margin: 0;
  text-shadow: 0 0 5px rgba(0, 255, 136, 0.6);
}

.error-message {
  font-family: "Press Start 2P", monospace;
  font-size: 0.7rem;
  color: #ff0055;
  text-shadow: 0 0 5px rgba(255, 0, 85, 0.6);
  margin: 0;
  padding: 8px;
  background: rgba(255, 0, 85, 0.1);
  border-left: 3px solid #ff0055;
  border-radius: 2px;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.modal-btn {
  padding: 12px 24px;
  font-family: "Press Start 2P", monospace;
  font-size: 0.8rem;
  border: 2px solid;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  text-transform: uppercase;
}

.btn-cancel {
  background: transparent;
  border-color: #888;
  color: #888;
}

.btn-cancel:hover {
  border-color: #00ffff;
  color: #00ffff;
  box-shadow: 0 0 15px rgba(0, 255, 255, 0.4);
}

.btn-confirm {
  background: rgba(0, 255, 136, 0.2);
  border-color: #00ff88;
  color: #00ff88;
}

.btn-confirm:hover:not(:disabled) {
  background: rgba(0, 255, 136, 0.3);
  box-shadow: 0 0 20px rgba(0, 255, 136, 0.6);
  transform: translateY(-2px);
}

.btn-confirm:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Transiciones */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>
