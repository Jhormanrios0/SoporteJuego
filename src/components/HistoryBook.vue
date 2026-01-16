<template>
  <div class="history-book-overlay" @click="$emit('close')">
    <div class="history-book-container" @click.stop>
      <!-- Libro abierto estilo Minecraft -->
      <div class="book-open-wrapper">
        <!-- Página del libro -->
        <div class="book-page">
          <!-- Margen rojo izquierdo -->
          <div class="red-margin"></div>

          <!-- Agujeros del lado izquierdo (efecto cuaderno) -->
          <div class="holes-container">
            <div class="hole" v-for="n in 8" :key="n"></div>
          </div>

          <!-- Contenido de la página -->
          <div v-if="!props.locked" class="page-content">
            <!-- Botón cerrar dentro de la página -->
            <button
              class="close-book-btn"
              @click="$emit('close')"
              aria-label="Cerrar libro"
              title="Cerrar libro"
            >
              <ArrowLeft :size="20" />
            </button>

            <h2 class="tab-title">
              <span class="chapter-label">Historial:</span>
              {{
                selectedMonth === null ? "Vidas Perdidas" : selectedMonthLabel
              }}
            </h2>

            <!-- Botón actualizar -->
            <button
              class="refresh-btn"
              :disabled="loading"
              @click="$emit('refresh')"
            >
              {{ loading ? "CARGANDO…" : "ACTUALIZAR" }}
            </button>

            <!-- Contenido del historial -->
            <div class="tab-content">
              <!-- Sin registro -->
              <div v-if="!hasPlayer" class="empty-content">
                <Scroll :size="32" class="empty-icon" />
                <p>SIN REGISTRO</p>
                <p class="empty-sub">
                  Completa el registro para ver tu historial.
                </p>
              </div>

              <!-- Error -->
              <div v-else-if="error" class="error-content">
                <AlertTriangle :size="32" class="error-icon" />
                <p>{{ error }}</p>
              </div>

              <!-- Sin eventos -->
              <div
                v-else-if="allFilteredEvents.length === 0"
                class="empty-content"
              >
                <Sparkles :size="32" class="empty-icon" />
                <p>SIN EVENTOS</p>
                <p class="empty-sub">
                  {{
                    selectedMonth !== null
                      ? "No hay eventos en este mes."
                      : "Aún no tienes vidas quitadas registradas."
                  }}
                </p>
              </div>

              <!-- Lista de eventos paginados -->
              <div v-else class="history-events-page">
                <!-- Header con total si hay mes seleccionado -->
                <div
                  v-if="selectedMonth !== null && currentMonthGroup"
                  class="month-header"
                >
                  <span class="month-name">{{ currentMonthGroup.label }}</span>
                  <span class="month-total"
                    >-{{ currentMonthGroup.total }} vidas</span
                  >
                </div>

                <div class="events-list">
                  <div
                    v-for="ev in paginatedEvents"
                    :key="ev.id"
                    class="event-entry"
                  >
                    <div class="event-row">
                      <span class="event-date">{{
                        formatEventDate(ev.created_at)
                      }}</span>
                      <span class="event-amount"
                        >-{{ Math.abs(ev.delta) }}</span
                      >
                      <span class="event-reason">{{
                        normalizeReason(ev.reason) || "Sin motivo"
                      }}</span>
                    </div>
                    <div v-if="hasAdminNote(ev)" class="event-note">
                      <FileText :size="12" class="note-icon" />
                      {{ ev.admin_message }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-else class="page-content locked-page">
            <div class="locked-visual">
              <div class="locked-pixels" />
              <div class="locked-title">HISTORIAL BLOQUEADO</div>
              <div class="locked-sub">Solo disponible en tu propio perfil</div>
              <div class="locked-padlock">🔒</div>
            </div>
          </div>

          <!-- Controles de navegación inferior -->
          <div class="page-controls">
            <!-- Botones de navegación de páginas -->
            <div class="nav-buttons">
              <button
                class="nav-btn prev-btn"
                @click="prevPage"
                :disabled="currentPage === 0"
                title="Página anterior"
              >
                ◄
              </button>
              <button
                class="nav-btn next-btn"
                @click="nextPage"
                :disabled="currentPage >= totalPages - 1"
                title="Página siguiente"
              >
                ►
              </button>
            </div>

            <!-- Número de página -->
            <div class="page-number">
              {{ currentPage + 1 }} of {{ totalPages }}
            </div>
          </div>
        </div>

        <!-- Tabs laterales con meses -->
        <div class="tabs-sidebar">
          <!-- Tab "Todos" -->
          <button
            class="tab-btn-side"
            :class="{ active: selectedMonth === null }"
            @click="selectMonth(null)"
            title="Ver todos los meses"
          >
            <template v-if="selectedMonth === null">
              <div class="tab-active-content">
                <span class="tab-chapter">Filtro:</span>
                <span class="tab-name">Todos</span>
                <span class="tab-arrow">➤</span>
              </div>
            </template>
            <Calendar v-else :size="18" class="tab-icon" />
          </button>

          <!-- Tabs de meses -->
          <button
            v-for="(month, index) in monthsWithEvents"
            :key="month.value"
            class="tab-btn-side"
            :class="{ active: selectedMonth === month.value }"
            :style="{
              backgroundColor:
                selectedMonth === month.value ? '#f5ede0' : getTabColor(index),
            }"
            @click="selectMonth(month.value)"
            :title="month.label"
          >
            <template v-if="selectedMonth === month.value">
              <div class="tab-active-content">
                <span class="tab-chapter">Mes:</span>
                <span class="tab-name">{{ month.shortLabel }}</span>
                <span class="tab-arrow">➤</span>
              </div>
            </template>
            <span v-else class="tab-plus-side">+</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from "vue";
import {
  ArrowLeft,
  Scroll,
  AlertTriangle,
  Sparkles,
  FileText,
  Calendar,
} from "lucide-vue-next";

const props = defineProps({
  events: {
    type: Array,
    default: () => [],
  },
  loading: {
    type: Boolean,
    default: false,
  },
  error: {
    type: String,
    default: "",
  },
  hasPlayer: {
    type: Boolean,
    default: false,
  },
  playerNickname: {
    type: String,
    default: "",
  },
  locked: {
    type: Boolean,
    default: false,
  },
});

defineEmits(["close", "refresh"]);

// Paginación
const ITEMS_PER_PAGE = 5;
const currentPage = ref(0);
const selectedMonth = ref(null);
const currentYear = new Date().getFullYear();

// Colores para las pestañas de meses
const tabColors = [
  "#e8b68c",
  "#d4a373",
  "#c99562",
  "#b88654",
  "#a87744",
  "#986834",
  "#885924",
  "#784a14",
];

const getTabColor = (index) => {
  return tabColors[index % tabColors.length] || "#d4a373";
};

// Meses del año
const months = [
  { value: 0, label: "Enero", shortLabel: "Ene" },
  { value: 1, label: "Febrero", shortLabel: "Feb" },
  { value: 2, label: "Marzo", shortLabel: "Mar" },
  { value: 3, label: "Abril", shortLabel: "Abr" },
  { value: 4, label: "Mayo", shortLabel: "May" },
  { value: 5, label: "Junio", shortLabel: "Jun" },
  { value: 6, label: "Julio", shortLabel: "Jul" },
  { value: 7, label: "Agosto", shortLabel: "Ago" },
  { value: 8, label: "Septiembre", shortLabel: "Sep" },
  { value: 9, label: "Octubre", shortLabel: "Oct" },
  { value: 10, label: "Noviembre", shortLabel: "Nov" },
  { value: 11, label: "Diciembre", shortLabel: "Dic" },
];

// Eventos de pérdida de vida del año actual (delta negativo)
const lifeLossEvents = computed(() => {
  return (props.events || [])
    .filter((ev) => {
      const date = ev?.created_at ? new Date(ev.created_at) : null;
      if (!date || Number.isNaN(date.getTime())) return false;
      return date.getFullYear() === currentYear && Number(ev?.delta ?? 0) < 0;
    })
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
});

// Meses que tienen eventos (para tabs laterales)
const monthsWithEvents = computed(() => {
  const monthsSet = new Set();
  lifeLossEvents.value.forEach((ev) => {
    const d = new Date(ev.created_at);
    monthsSet.add(d.getMonth());
  });
  return months
    .filter((m) => monthsSet.has(m.value))
    .sort((a, b) => b.value - a.value);
});

// Agrupar eventos por mes
const lifeLossGroups = computed(() => {
  const byKey = new Map();
  for (const ev of lifeLossEvents.value) {
    const date = new Date(ev.created_at);
    const monthIndex = date.getMonth();
    const key = `${date.getFullYear()}-${monthIndex}`;

    if (!byKey.has(key)) {
      byKey.set(key, {
        key,
        label: months[monthIndex].label.toUpperCase(),
        total: 0,
        events: [],
        monthIndex,
      });
    }
    const group = byKey.get(key);
    group.total += Math.abs(Number(ev?.delta ?? 0));
    group.events.push(ev);
  }

  return Array.from(byKey.values()).sort((a, b) => b.monthIndex - a.monthIndex);
});

// Eventos filtrados según el mes seleccionado
const allFilteredEvents = computed(() => {
  if (selectedMonth.value === null) {
    return lifeLossEvents.value;
  }
  return lifeLossEvents.value.filter((ev) => {
    const d = new Date(ev.created_at);
    return d.getMonth() === selectedMonth.value;
  });
});

// Grupo del mes actual (para mostrar header)
const currentMonthGroup = computed(() => {
  if (selectedMonth.value === null) return null;
  return lifeLossGroups.value.find((g) => g.monthIndex === selectedMonth.value);
});

// Label del mes seleccionado
const selectedMonthLabel = computed(() => {
  const m = months.find((m) => m.value === selectedMonth.value);
  return m ? m.label : "Vidas Perdidas";
});

// Paginación: total de páginas
const totalPages = computed(() => {
  const total = allFilteredEvents.value.length;
  if (total === 0) return 1;
  return Math.ceil(total / ITEMS_PER_PAGE);
});

// Eventos de la página actual
const paginatedEvents = computed(() => {
  const start = currentPage.value * ITEMS_PER_PAGE;
  const end = start + ITEMS_PER_PAGE;
  return allFilteredEvents.value.slice(start, end);
});

// Resetear página al cambiar filtro
watch(selectedMonth, () => {
  currentPage.value = 0;
});

// Navegación de páginas
function prevPage() {
  if (currentPage.value > 0) {
    currentPage.value--;
  }
}

function nextPage() {
  if (currentPage.value < totalPages.value - 1) {
    currentPage.value++;
  }
}

// Seleccionar mes
function selectMonth(monthValue) {
  selectedMonth.value = monthValue;
}

function normalizeReason(reason) {
  const raw = String(reason || "").trim();
  if (!raw) return "";
  const nickname = String(props.playerNickname || "").trim();
  if (!nickname) return raw;
  const lower = raw.toLowerCase();
  const prefix = `${nickname.toLowerCase()} `;
  if (lower.startsWith(prefix)) {
    return raw.slice(nickname.length + 1).trim();
  }
  return raw;
}

function formatEventDate(value) {
  try {
    const date = value ? new Date(value) : null;
    if (!date || Number.isNaN(date.getTime())) return "";
    return new Intl.DateTimeFormat("es-ES", {
      day: "2-digit",
      month: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    }).format(date);
  } catch {
    return "";
  }
}

function hasAdminNote(ev) {
  return String(ev?.admin_message || "").trim().length > 0;
}
</script>

<style scoped>
/* Overlay del modal */
.history-book-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: grid;
  place-items: center;
  padding: 18px;
  background: rgba(0, 0, 0, 0.88);
  backdrop-filter: blur(4px);
}

.history-book-container {
  width: min(780px, 100%);
  max-height: 92vh;
  overflow: visible;
}

/* ============================================
   LIBRO ABIERTO - ESTILO MINECRAFT
   ============================================ */
.book-open-wrapper {
  position: relative;
  display: flex;
  background: #f5ede0;
  border: 8px solid #5a3825;
  box-shadow: 0 0 60px rgba(90, 56, 37, 0.5), 0 0 40px rgba(0, 0, 0, 0.7),
    inset 0 0 20px rgba(0, 0, 0, 0.1);
  min-height: 550px;
  max-height: calc(92vh - 36px);
  width: 100%;
}

.book-page {
  flex: 1;
  padding: 2.5rem 2.5rem 3.5rem 2rem;
  position: relative;
  background: linear-gradient(135deg, #f5ede0 0%, #f0e6d6 100%);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* Textura de papel con líneas */
.book-page::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image: repeating-linear-gradient(
    0deg,
    transparent,
    transparent 24px,
    rgba(90, 56, 37, 0.08) 24px,
    rgba(90, 56, 37, 0.08) 25px
  );
  pointer-events: none;
  opacity: 0.6;
}

/* Margen rojo izquierdo */
.red-margin {
  position: absolute;
  left: 1.8rem;
  top: 2rem;
  bottom: 2rem;
  width: 3px;
  background: rgba(220, 80, 80, 0.4);
  pointer-events: none;
  z-index: 1;
}

/* Agujeros del lado izquierdo (efecto cuaderno) */
.holes-container {
  position: absolute;
  left: 0.9rem;
  top: 3rem;
  bottom: 3rem;
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  z-index: 1;
}

.hole {
  width: 12px;
  height: 12px;
  background: radial-gradient(circle at 40% 40%, #e8dcc8, #d4c4b0);
  border: 2px solid #5a3825;
  border-radius: 50%;
  box-shadow: inset 2px 2px 3px rgba(0, 0, 0, 0.3), 0 1px 2px rgba(0, 0, 0, 0.2);
}

.page-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  z-index: 2;
  margin-left: 1.2rem;
  overflow: hidden;
}

/* Botón cerrar */
.close-book-btn {
  position: absolute;
  top: 0;
  left: 0;
  background: transparent;
  border: none;
  cursor: pointer;
  color: #3d2310;
  padding: 0.4rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
  border-radius: 4px;
  z-index: 10;
}

.close-book-btn:hover {
  background: rgba(61, 35, 16, 0.1);
  transform: scale(1.1);
}

.close-book-btn:active {
  transform: scale(0.95);
}

/* Título */
.tab-title {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.85rem;
  color: #5a3825;
  margin-bottom: 1rem;
  text-transform: capitalize;
  border-bottom: 3px solid #5a3825;
  padding-bottom: 0.6rem;
  letter-spacing: 0.05em;
  font-weight: bold;
  position: relative;
  padding-top: 0.5rem;
  padding-left: 2rem;
}

.chapter-label {
  display: block;
  font-size: 0.5rem;
  opacity: 0.6;
  margin-bottom: 0.4rem;
  text-transform: capitalize;
}

/* Botón actualizar */
.refresh-btn {
  align-self: flex-start;
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.5rem;
  padding: 0.6rem 1.2rem;
  background: #d4a373;
  border: 3px solid #5a3825;
  color: #5a3825;
  cursor: pointer;
  margin-bottom: 1rem;
  transition: all 0.2s;
  box-shadow: inset -2px -2px 0 rgba(0, 0, 0, 0.2),
    inset 2px 2px 0 rgba(255, 255, 255, 0.2), 3px 3px 0 rgba(0, 0, 0, 0.3);
}

.refresh-btn:hover:not(:disabled) {
  background: #e8c88c;
  transform: translateY(-1px);
}

.refresh-btn:active:not(:disabled) {
  transform: translateY(1px);
  box-shadow: inset 2px 2px 0 rgba(0, 0, 0, 0.2), 1px 1px 0 rgba(0, 0, 0, 0.2);
}

.refresh-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Contenido del historial */
.tab-content {
  flex: 1;
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.55rem;
  color: #5a3825;
  line-height: 1.8;
  overflow-y: auto;
  padding-right: 0.8rem;
}

/* Locked page styles */
.locked-page {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2.4rem;
}
.locked-visual {
  text-align: center;
  color: #f5e4c8;
  font-family: "Press Start 2P", monospace;
  display: flex;
  flex-direction: column;
  gap: 12px;
  align-items: center;
  justify-content: center;
}
.locked-padlock {
  font-size: 32px;
  filter: drop-shadow(3px 3px 0 #000);
}
.locked-title {
  font-size: 0.7rem;
  color: #e8b68c;
}
.locked-sub {
  font-size: 0.45rem;
  color: #d4a373;
}
.locked-pixels {
  width: 120px;
  height: 24px;
  background-image: linear-gradient(
    90deg,
    #000 0 12.5%,
    transparent 12.5% 25%,
    #000 25% 37.5%,
    transparent 37.5% 50%
  );
  image-rendering: pixelated;
  opacity: 0.25;
  transform: scaleY(2);
}

.tab-content::-webkit-scrollbar {
  width: 10px;
}

.tab-content::-webkit-scrollbar-track {
  background: rgba(90, 56, 37, 0.1);
  border: 2px solid #5a3825;
}

.tab-content::-webkit-scrollbar-thumb {
  background: #d4a373;
  border: 2px solid #5a3825;
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.2);
}

.tab-content::-webkit-scrollbar-thumb:hover {
  background: #e8c88c;
}

/* Contenido vacío */
.empty-content {
  text-align: center;
  color: rgba(90, 56, 37, 0.5);
  padding: 2rem 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.8rem;
}

.empty-icon {
  color: rgba(90, 56, 37, 0.4);
  opacity: 0.8;
}

.empty-content p {
  margin: 0;
  font-size: 0.6rem;
}

.empty-sub {
  font-size: 0.5rem !important;
  opacity: 0.7;
}

/* Error */
.error-content {
  text-align: center;
  color: #8b4513;
  padding: 2rem 1rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.8rem;
}

.error-icon {
  color: #8b4513;
  opacity: 0.8;
}

/* Eventos paginados */
.history-events-page {
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
}

.month-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.6rem 0.8rem;
  background: rgba(90, 56, 37, 0.1);
  border: 2px solid rgba(90, 56, 37, 0.2);
  border-radius: 4px;
}

.month-name {
  font-size: 0.55rem;
  color: #5a3825;
  font-weight: bold;
}

.month-total {
  font-size: 0.55rem;
  color: #8b4513;
  background: rgba(139, 69, 19, 0.1);
  padding: 0.2rem 0.5rem;
  border-radius: 2px;
}

.events-list {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.event-entry {
  padding: 0.5rem;
  border: 1px solid rgba(90, 56, 37, 0.15);
  border-radius: 3px;
  background: rgba(255, 255, 255, 0.3);
}

.event-row {
  display: grid;
  grid-template-columns: 80px 40px 1fr;
  gap: 0.5rem;
  align-items: center;
}

.event-date {
  font-size: 0.48rem;
  color: rgba(90, 56, 37, 0.7);
}

.event-amount {
  font-size: 0.6rem;
  color: #8b4513;
  font-weight: bold;
  text-align: center;
}

.event-reason {
  font-size: 0.5rem;
  color: #5a3825;
  line-height: 1.4;
}

.event-note {
  margin-top: 0.4rem;
  padding-top: 0.4rem;
  border-top: 1px dashed rgba(90, 56, 37, 0.25);
  font-size: 0.48rem;
  color: #6b4423;
  font-style: italic;
  display: flex;
  align-items: center;
  gap: 0.3rem;
}

.note-icon {
  opacity: 0.7;
  flex-shrink: 0;
}

/* Controles de navegación */
.page-controls {
  position: absolute;
  bottom: 1rem;
  left: 2rem;
  right: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  z-index: 2;
}

.nav-buttons {
  display: flex;
  gap: 0.5rem;
}

.nav-btn {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.7rem;
  padding: 0.4rem 0.6rem;
  background: #d4a373;
  border: 3px solid #5a3825;
  color: #5a3825;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: inset -2px -2px 0 rgba(0, 0, 0, 0.2),
    inset 2px 2px 0 rgba(255, 255, 255, 0.2), 2px 2px 0 rgba(0, 0, 0, 0.3);
}

.nav-btn:hover:not(:disabled) {
  background: #e8c88c;
  transform: translateY(-1px);
}

.nav-btn:active:not(:disabled) {
  transform: translateY(1px);
  box-shadow: inset 2px 2px 0 rgba(0, 0, 0, 0.2), 1px 1px 0 rgba(0, 0, 0, 0.2);
}

.nav-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  background: #b8a898;
}

.page-number {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.5rem;
  color: rgba(90, 56, 37, 0.6);
  background: rgba(90, 56, 37, 0.08);
  padding: 0.3rem 0.6rem;
  border-radius: 2px;
}

/* ============================================
   TABS LATERALES - MESES
   ============================================ */
.tabs-sidebar {
  position: absolute;
  right: -145px;
  top: -8px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  z-index: 100;
}

.tab-btn-side {
  border: 4px solid #5a3825;
  font-family: "Press Start 2P", "Courier New", monospace;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: inset -3px -3px 0 rgba(0, 0, 0, 0.3),
    inset 3px 3px 0 rgba(255, 255, 255, 0.2), 4px 3px 0 rgba(0, 0, 0, 0.4);
  color: #5a3825;
  font-weight: bold;
  width: 45px;
  height: 45px;
  padding: 0.5rem;
  transition: filter 0.2s ease;
  background: #d4a373;
}

.tab-btn-side.active {
  color: #3d2515;
  box-shadow: inset 3px 3px 0 rgba(255, 255, 255, 0.5),
    inset -3px -3px 0 rgba(0, 0, 0, 0.2), 4px 2px 0 rgba(0, 0, 0, 0.2);
  width: 135px;
  height: 50px;
  padding: 0.6rem 0.8rem;
  background: #f5ede0;
}

.tab-btn-side:hover {
  filter: brightness(1.1);
}

.tab-active-content {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.15rem;
  width: 100%;
  position: relative;
}

.tab-chapter {
  font-size: 0.3rem;
  opacity: 0.7;
  text-transform: capitalize;
  display: block;
  line-height: 1.2;
}

.tab-name {
  font-size: 0.4rem;
  text-transform: capitalize;
  display: block;
  line-height: 1.3;
}

.tab-arrow {
  position: absolute;
  right: -3px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 0.7rem;
  opacity: 0.8;
}

.tab-plus-side {
  font-size: 1rem;
  font-weight: bold;
  text-shadow: 1px 1px 0 rgba(255, 255, 255, 0.3);
}

.tab-icon {
  color: #5a3825;
  opacity: 0.8;
}

/* ============================================
   RESPONSIVE
   ============================================ */
@media (max-width: 900px) {
  .tabs-sidebar {
    position: static;
    flex-direction: row;
    width: 100%;
    padding: 0.8rem;
    gap: 0.4rem;
    flex-wrap: wrap;
    justify-content: center;
    border-top: 5px solid #5a3825;
    background: #e8dcc8;
  }

  .tab-btn-side {
    width: 42px;
    height: 42px;
    padding: 0.4rem;
  }

  .tab-btn-side.active {
    width: auto;
    min-width: 110px;
    height: auto;
    padding: 0.5rem 0.8rem;
  }

  .book-open-wrapper {
    flex-direction: column;
    min-height: auto;
    max-height: calc(92vh - 36px);
  }

  .book-page {
    min-height: 400px;
  }
}

@media (max-width: 600px) {
  .history-book-container {
    width: 100%;
  }

  .book-page {
    padding: 1.5rem 1.5rem 3rem 1.2rem;
  }

  .tab-title {
    font-size: 0.55rem;
    padding-left: 1.5rem;
  }

  .chapter-label {
    font-size: 0.35rem;
  }

  .tab-content {
    font-size: 0.4rem;
  }

  .event-row {
    grid-template-columns: 1fr;
    gap: 0.3rem;
  }

  .event-date,
  .event-amount,
  .event-reason {
    font-size: 0.38rem;
  }

  .red-margin {
    left: 1.2rem;
  }

  .holes-container {
    left: 0.5rem;
  }

  .hole {
    width: 10px;
    height: 10px;
  }

  .page-content {
    margin-left: 0.8rem;
  }

  .page-controls {
    left: 1.2rem;
    right: 1rem;
  }

  .nav-btn {
    font-size: 0.5rem;
    padding: 0.3rem 0.5rem;
  }

  .page-number {
    font-size: 0.4rem;
  }

  .refresh-btn {
    font-size: 0.35rem;
    padding: 0.4rem 0.8rem;
  }
}

@media (max-width: 480px) {
  .book-page {
    padding: 1.2rem 1rem 2.5rem 1rem;
    min-height: 350px;
  }

  .tab-title {
    font-size: 0.5rem;
    padding-left: 1.2rem;
  }

  .holes-container {
    display: none;
  }

  .red-margin {
    left: 0.5rem;
  }

  .page-content {
    margin-left: 0.5rem;
  }

  .tab-btn-side {
    width: 38px;
    height: 38px;
  }

  .tab-btn-side.active {
    min-width: 90px;
  }

  .tab-chapter {
    font-size: 0.25rem;
  }

  .tab-name {
    font-size: 0.35rem;
  }

  .nav-btn {
    font-size: 0.45rem;
    padding: 0.25rem 0.4rem;
  }

  .page-number {
    font-size: 0.35rem;
  }
}
</style>
