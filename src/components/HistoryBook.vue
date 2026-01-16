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
          <div class="page-content">
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
              Vidas Perdidas
            </h2>

            <!-- Filtro de meses -->
            <div class="month-filter">
              <span class="filter-label">Filtrar por mes:</span>
              <div class="month-buttons">
                <button
                  class="month-btn"
                  :class="{ active: selectedMonth === null }"
                  @click="selectedMonth = null"
                >
                  Todos
                </button>
                <button
                  v-for="month in availableMonths"
                  :key="month.value"
                  class="month-btn"
                  :class="{ active: selectedMonth === month.value }"
                  @click="selectedMonth = month.value"
                >
                  {{ month.label }}
                </button>
              </div>
            </div>

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
                v-else-if="filteredGroups.length === 0"
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

              <!-- Lista de eventos agrupados por mes -->
              <div v-else class="history-groups">
                <div
                  v-for="group in filteredGroups"
                  :key="group.key"
                  class="history-month-group"
                >
                  <div class="month-header">
                    <span class="month-name">{{ group.label }}</span>
                    <span class="month-total">-{{ group.total }} vidas</span>
                  </div>

                  <div class="events-list">
                    <div
                      v-for="ev in group.events"
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
          </div>

          <!-- Controles de navegación inferior (info de página) -->
          <div class="page-controls">
            <div class="page-info">
              <span class="year-label">{{ currentYear }}</span>
            </div>
            <div class="page-number">
              {{ filteredGroups.length }}
              {{ filteredGroups.length === 1 ? "mes" : "meses" }}
            </div>
          </div>
        </div>

        <!-- Tabs laterales con meses -->
        <div class="tabs-sidebar">
          <button
            class="tab-btn-side"
            :class="{ active: selectedMonth === null }"
            @click="selectedMonth = null"
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

          <button
            v-for="(month, index) in displayedMonthTabs"
            :key="month.value"
            class="tab-btn-side"
            :class="{ active: selectedMonth === month.value }"
            :style="{
              backgroundColor:
                selectedMonth === month.value ? '#f5ede0' : getTabColor(index),
            }"
            @click="selectedMonth = month.value"
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
import { ref, computed } from "vue";
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
});

defineEmits(["close", "refresh"]);

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

// Eventos de pérdida de vida (delta negativo)
const lifeLossEvents = computed(() => {
  return (props.events || []).filter((ev) => Number(ev?.delta ?? 0) < 0);
});

// Meses disponibles del año actual
const availableMonths = computed(() => {
  const months = [];
  const currentDate = new Date();
  const currentMonth = currentDate.getMonth();

  const monthNames = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  const shortMonthNames = [
    "Ene",
    "Feb",
    "Mar",
    "Abr",
    "May",
    "Jun",
    "Jul",
    "Ago",
    "Sep",
    "Oct",
    "Nov",
    "Dic",
  ];

  // Solo mostrar meses hasta el mes actual del año actual
  for (let i = 0; i <= currentMonth; i++) {
    months.push({
      value: i,
      label: monthNames[i],
      shortLabel: shortMonthNames[i],
    });
  }

  return months.reverse(); // Más reciente primero
});

// Tabs de meses para mostrar en el sidebar (máximo 6)
const displayedMonthTabs = computed(() => {
  return availableMonths.value.slice(0, 6);
});

// Agrupar eventos por mes
const lifeLossGroups = computed(() => {
  const formatter = new Intl.DateTimeFormat("es-ES", {
    month: "long",
    year: "numeric",
  });

  const byKey = new Map();
  for (const ev of lifeLossEvents.value) {
    const createdAt = ev?.created_at;
    const date = createdAt ? new Date(createdAt) : null;
    if (!date || Number.isNaN(date.getTime())) continue;

    // Solo eventos del año actual
    if (date.getFullYear() !== currentYear) continue;

    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(
      2,
      "0"
    )}`;
    const monthIndex = date.getMonth();

    if (!byKey.has(key)) {
      const label = String(
        formatter.format(new Date(date.getFullYear(), date.getMonth(), 1))
      ).toUpperCase();
      byKey.set(key, { key, label, total: 0, events: [], monthIndex });
    }
    const group = byKey.get(key);
    group.total += Math.abs(Number(ev?.delta ?? 0));
    group.events.push(ev);
  }

  return Array.from(byKey.values()).sort((a, b) => b.key.localeCompare(a.key));
});

// Grupos filtrados por mes seleccionado
const filteredGroups = computed(() => {
  if (selectedMonth.value === null) {
    return lifeLossGroups.value;
  }
  return lifeLossGroups.value.filter(
    (group) => group.monthIndex === selectedMonth.value
  );
});

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

/* Filtro de meses */
.month-filter {
  margin-bottom: 0.8rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.filter-label {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.5rem;
  color: rgba(90, 56, 37, 0.7);
}

.month-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.month-btn {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.45rem;
  padding: 0.5rem 0.7rem;
  background: #e8dcc8;
  border: 2px solid #5a3825;
  color: #5a3825;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: inset -1px -1px 0 rgba(0, 0, 0, 0.2),
    inset 1px 1px 0 rgba(255, 255, 255, 0.3), 2px 2px 0 rgba(0, 0, 0, 0.2);
}

.month-btn:hover {
  background: #d4c4b0;
}

.month-btn.active {
  background: #5a3825;
  color: #f5ede0;
  box-shadow: inset 1px 1px 0 rgba(0, 0, 0, 0.3), 1px 1px 0 rgba(0, 0, 0, 0.2);
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

/* Grupos de historial */
.history-groups {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.history-month-group {
  border: 2px solid rgba(90, 56, 37, 0.3);
  border-radius: 4px;
  background: rgba(90, 56, 37, 0.05);
  overflow: hidden;
}

.month-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.6rem 0.8rem;
  background: rgba(90, 56, 37, 0.1);
  border-bottom: 2px solid rgba(90, 56, 37, 0.2);
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
  padding: 0.6rem;
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

.page-info {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.year-label {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.55rem;
  color: rgba(90, 56, 37, 0.6);
  background: rgba(90, 56, 37, 0.1);
  padding: 0.3rem 0.6rem;
  border-radius: 2px;
}

.page-number {
  font-family: "Press Start 2P", "Courier New", monospace;
  font-size: 0.5rem;
  color: rgba(90, 56, 37, 0.5);
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

  .month-buttons {
    gap: 0.3rem;
  }

  .month-btn {
    font-size: 0.3rem;
    padding: 0.3rem 0.5rem;
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

  .filter-label {
    font-size: 0.35rem;
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

  .month-filter {
    margin-bottom: 0.6rem;
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

  .year-label,
  .page-number {
    font-size: 0.35rem;
  }
}
</style>
