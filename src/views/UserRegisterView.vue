<template>
  <div class="register-view">
    <div class="panel">
      <div class="panel-header">
        <h1 class="title">Registro de usuario</h1>
        <p class="subtitle">
          Ya validamos tu Google. Completa tu perfil para entrar al juego.
        </p>
      </div>

      <div class="form">
        <label class="label">Correo</label>
        <input class="input" type="email" :value="email" disabled />

        <div class="row">
          <div class="col">
            <label class="label">Nombre</label>
            <input
              class="input"
              v-model.trim="firstName"
              type="text"
              placeholder="Ej: Juan"
              maxlength="40"
            />
          </div>
          <div class="col">
            <label class="label">Apellido</label>
            <input
              class="input"
              v-model.trim="lastName"
              type="text"
              placeholder="Ej: Pérez"
              maxlength="40"
            />
          </div>
        </div>

        <label class="label">Foto (la que se verá en el juego)</label>
        <div class="file-row">
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            class="file-native"
            @change="onPick"
          />

          <button class="mc-btn" type="button" @click="pickFile">
            Seleccionar foto
          </button>

          <div class="file-meta">
            {{ fileLabel }}
          </div>
        </div>

        <div v-if="preview" class="preview">
          <div class="preview-frame">
            <img :src="preview" alt="preview" class="preview-img" />
          </div>
          <button class="mc-btn danger" type="button" @click="clearImage">
            Quitar foto
          </button>
        </div>

        <button
          class="mc-btn primary"
          :disabled="saving || !firstName || !lastName"
          @click="save"
        >
          {{ saving ? "GUARDANDO…" : "GUARDAR Y ENTRAR" }}
        </button>

        <p v-if="error" class="error">{{ error }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import {
  getSession,
  getMyPlayer,
  upsertMyPlayer,
  updateMyProfile,
} from "@/services/supabase";

const route = useRoute();
const router = useRouter();

const firstName = ref("");
const lastName = ref("");
const imageFile = ref(null);
const preview = ref("");
const saving = ref(false);
const error = ref("");
const fileInput = ref(null);

const fileLabel = computed(() => {
  if (!imageFile.value) return "Sin archivo";
  return imageFile.value.name || "Archivo seleccionado";
});

const email = computed(() => String(route.query.email || ""));

onMounted(async () => {
  try {
    const session = await getSession();
    if (!session?.user) {
      await router.replace({ name: "public" });
      return;
    }

    const me = await getMyPlayer();
    if (me?.id) {
      await router.replace({ name: "public" });
      return;
    }

    if (!email.value) {
      // fallback: usar el email del user si no viene por query
      if (session.user.email) {
        await router.replace({
          name: "register",
          query: { email: session.user.email },
        });
      }
    }
  } catch (e) {
    error.value = e?.message || "Error cargando el registro";
  }
});

function onPick(event) {
  const file = event.target.files?.[0];
  if (!file) return;

  if (!file.type.startsWith("image/")) {
    error.value = "Selecciona una imagen válida";
    return;
  }
  if (file.size > 5 * 1024 * 1024) {
    error.value = "La imagen no debe superar 5MB";
    return;
  }

  imageFile.value = file;
  error.value = "";
  const reader = new FileReader();
  reader.onload = (e) => {
    preview.value = e.target?.result || "";
  };
  reader.readAsDataURL(file);
}

function pickFile() {
  fileInput.value?.click();
}

function clearImage() {
  imageFile.value = null;
  preview.value = "";

  if (fileInput.value) {
    fileInput.value.value = "";
  }
}

async function save() {
  error.value = "";
  saving.value = true;
  try {
    const first = firstName.value.trim();
    const last = lastName.value.trim();
    if (!first || !last) return;

    // Crear/actualizar jugador (players)
    await upsertMyPlayer({
      first_name: first,
      last_name: last,
      imageFile: imageFile.value,
    });

    // Mantener display_name en profiles (para etiqueta de sesión)
    await updateMyProfile({
      display_name: `${first} ${last}`.trim(),
    });

    await router.replace({ name: "public" });
  } catch (e) {
    error.value = e?.message || "No se pudo guardar el perfil";
  } finally {
    saving.value = false;
  }
}
</script>

<style scoped>
.register-view {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;

  /* Fondo estilo Minecraft (dirt/grass vibes, sin assets) */
  background: linear-gradient(0deg, rgba(0, 0, 0, 0.65), rgba(0, 0, 0, 0.65)),
    repeating-linear-gradient(
      90deg,
      rgba(69, 55, 39, 0.35) 0px,
      rgba(69, 55, 39, 0.35) 8px,
      rgba(60, 48, 34, 0.35) 8px,
      rgba(60, 48, 34, 0.35) 16px
    ),
    repeating-linear-gradient(
      0deg,
      rgba(92, 66, 41, 0.22) 0px,
      rgba(92, 66, 41, 0.22) 10px,
      rgba(44, 111, 54, 0.18) 10px,
      rgba(44, 111, 54, 0.18) 20px
    );
}

.register-view,
.register-view * {
  box-sizing: border-box;
}

.panel {
  width: min(620px, 100%);

  /* Marco pixelado tipo UI Minecraft */
  background: rgba(22, 22, 22, 0.9);
  border: 4px solid rgba(0, 0, 0, 0.85);
  border-radius: 8px;
  padding: 18px;
  box-shadow: 0 18px 55px rgba(0, 0, 0, 0.55),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 0 0 6px rgba(0, 0, 0, 0.55);

  position: relative;

  box-sizing: border-box;
  overflow: hidden;
}

.panel::before {
  content: "";
  position: absolute;
  inset: 10px;
  border: 2px solid rgba(255, 255, 255, 0.06);
  border-radius: 6px;
  pointer-events: none;
}

.panel-header {
  margin-bottom: 14px;
  padding-bottom: 12px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.08);
}

.title {
  margin: 0 0 6px;
  color: #ffffff;
  font-weight: 900;
  letter-spacing: 1px;
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.8);

  font-size: clamp(1.4rem, 4vw, 2.15rem);
  line-height: 1.12;
  overflow-wrap: anywhere;
}

.subtitle {
  margin: 0 0 18px;
  color: rgba(255, 255, 255, 0.78);
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.6);
}

.form {
  display: grid;
  gap: 10px;
  min-width: 0;
}

.row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  min-width: 0;
}

.col {
  display: grid;
  gap: 10px;
  min-width: 0;
}

.label {
  color: rgba(255, 255, 255, 0.9);
  font-weight: 900;
  font-size: 0.92rem;
}

.input {
  border-radius: 6px;
  border: 2px solid rgba(0, 0, 0, 0.9);
  background: rgba(45, 45, 45, 0.9);
  color: #fff;
  padding: 12px 12px;
  outline: none;
  width: 100%;
  min-width: 0;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.05),
    inset 0 -2px 0 rgba(0, 0, 0, 0.65);
}

.input:focus {
  border-color: rgba(94, 223, 110, 0.85);
  box-shadow: 0 0 0 3px rgba(94, 223, 110, 0.18),
    inset 0 0 0 2px rgba(255, 255, 255, 0.05),
    inset 0 -2px 0 rgba(0, 0, 0, 0.65);
}

.input:disabled {
  opacity: 0.7;
}

.file-row {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: 10px;
  align-items: center;
  min-width: 0;
}

.file-native {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
  pointer-events: none;
}

.file-meta {
  border-radius: 6px;
  border: 2px solid rgba(0, 0, 0, 0.9);
  background: rgba(35, 35, 35, 0.9);
  color: rgba(255, 255, 255, 0.72);
  padding: 10px 12px;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.04),
    inset 0 -2px 0 rgba(0, 0, 0, 0.65);
  min-width: 0;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.mc-btn {
  border: 2px solid rgba(0, 0, 0, 0.95);
  border-radius: 6px;
  padding: 12px 14px;
  font-weight: 900;
  letter-spacing: 0.8px;
  text-transform: uppercase;
  background: rgba(64, 64, 64, 0.95);
  color: #fff;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7), 0 10px 28px rgba(0, 0, 0, 0.35);
  transition: transform 0.08s ease, filter 0.12s ease;

  max-width: 100%;
  text-align: center;
}

.mc-btn:hover:not(:disabled) {
  filter: brightness(1.08);
}

.mc-btn:active:not(:disabled) {
  transform: translateY(2px);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 -2px 0 rgba(0, 0, 0, 0.8), 0 6px 18px rgba(0, 0, 0, 0.35);
}

.mc-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  filter: grayscale(0.2);
}

.mc-btn.primary {
  background: linear-gradient(
    180deg,
    rgba(84, 215, 104, 0.95),
    rgba(35, 140, 55, 0.95)
  );
}

.mc-btn.danger {
  background: linear-gradient(
    180deg,
    rgba(255, 110, 110, 0.85),
    rgba(170, 45, 45, 0.9)
  );
}

.preview {
  display: grid;
  gap: 10px;
  justify-items: start;
}

.preview-frame {
  width: 160px;
  height: 160px;
  border-radius: 10px;
  border: 3px solid rgba(0, 0, 0, 0.9);
  background: rgba(20, 20, 20, 0.95);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.05),
    inset 0 -4px 0 rgba(0, 0, 0, 0.7);
  overflow: hidden;
}

.preview-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

@media (max-width: 640px) {
  .row {
    grid-template-columns: 1fr;
  }

  .register-view {
    padding: 16px;
  }
}

@media (max-width: 520px) {
  .file-row {
    grid-template-columns: 1fr;
    align-items: stretch;
  }

  .file-meta,
  .mc-btn {
    width: 100%;
  }
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  margin-top: 8px;
  color: #ff6b6b;
  font-weight: 900;
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.7);
}
</style>
