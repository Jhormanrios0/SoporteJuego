<template>
  <div class="auth-callback">
    <div class="panel">
      <div class="panel-header">
        <h1 class="title">Iniciando sesión…</h1>
        <p class="subtitle">Validando tu cuenta de Google</p>
      </div>

      <div class="loading">
        <div class="bar" />
        <div class="hint">Cargando mundo…</div>
      </div>

      <p v-if="error" class="error">{{ error }}</p>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import { getSession, getMyPlayer } from "@/services/supabase";

const router = useRouter();
const error = ref("");

onMounted(async () => {
  try {
    const session = await getSession();

    if (!session?.user) {
      error.value = "No se encontró sesión. Intenta entrar de nuevo.";
      setTimeout(() => router.replace({ name: "public" }), 1200);
      return;
    }

    // Establecer expiración personalizada de sesión: 10 horas desde ahora
    try {
      const TEN_HOURS_MS = 10 * 60 * 60 * 1000;
      localStorage.setItem(
        "session_expires_at",
        String(Date.now() + TEN_HOURS_MS)
      );
    } catch (e) {
      // noop
    }

    const player = await getMyPlayer();

    // Si el usuario no tiene jugador asociado, lo tratamos como “registro pendiente”
    if (!player?.id) {
      await router.replace({
        name: "register",
        query: { email: session.user.email || "" },
      });
      return;
    }

    await router.replace({ name: "public" });
  } catch (e) {
    error.value = e?.message || "Error iniciando sesión";
    setTimeout(() => router.replace({ name: "public" }), 1500);
  }
});
</script>

<style scoped>
.auth-callback {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 24px;

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

.panel {
  width: min(560px, 100%);

  background: rgba(22, 22, 22, 0.9);
  border: 4px solid rgba(0, 0, 0, 0.85);
  border-radius: 8px;
  padding: 18px;
  box-shadow: 0 18px 55px rgba(0, 0, 0, 0.55),
    inset 0 0 0 2px rgba(255, 255, 255, 0.06),
    inset 0 0 0 6px rgba(0, 0, 0, 0.55);

  position: relative;
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
  color: #fff;
  font-weight: 900;
  letter-spacing: 1px;
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.8);
}

.subtitle {
  margin: 0;
  color: rgba(255, 255, 255, 0.78);
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.6);
}

.loading {
  display: grid;
  gap: 10px;
}

.bar {
  height: 14px;
  border-radius: 6px;
  border: 2px solid rgba(0, 0, 0, 0.95);
  background: linear-gradient(
    180deg,
    rgba(35, 35, 35, 0.95),
    rgba(25, 25, 25, 0.95)
  );
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.05),
    inset 0 -2px 0 rgba(0, 0, 0, 0.7);
  overflow: hidden;
  position: relative;
}

.bar::after {
  content: "";
  position: absolute;
  inset: 0;
  width: 45%;
  background: linear-gradient(
    180deg,
    rgba(84, 215, 104, 0.95),
    rgba(35, 140, 55, 0.95)
  );
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.08);
  animation: load 1.2s ease-in-out infinite;
}

@keyframes load {
  0% {
    transform: translateX(-40%);
  }
  50% {
    transform: translateX(80%);
  }
  100% {
    transform: translateX(-40%);
  }
}

.hint {
  color: rgba(255, 255, 255, 0.72);
}

.error {
  margin-top: 14px;
  color: #ff6b6b;
  font-weight: 900;
  text-shadow: 0 2px 0 rgba(0, 0, 0, 0.7);
}
</style>
