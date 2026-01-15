<template>
  <div class="book-container">
    <!-- Libro cerrado dentro de un cofre - clickable (SOLO EN MODO STANDALONE) -->
    <div v-if="!isOpen && standaloneMode" class="book-closed" @click="openBook">
      <div class="chest-container">
        <!-- Cofre (Minecraft style) -->
        <div class="chest">
          <!-- Tapa del cofre -->
          <div class="chest-lid">
            <div class="chest-lid-front"></div>
          </div>
          
          <!-- Cuerpo del cofre -->
          <div class="chest-body">
            <div class="chest-panel chest-panel-left"></div>
            <div class="chest-panel chest-panel-center"></div>
            <div class="chest-panel chest-panel-right"></div>
          </div>
        </div>
        
        <!-- Libro saliendo del cofre -->
        <div class="book-from-chest">
          <div class="book-spine-chest"></div>
          <div class="book-front-chest">
            <span class="book-text-chest">INFO</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Libro abierto -->
    <Transition name="book-fade">
      <div v-if="isOpen" class="book-open-container">
        <!-- Contenedor del libro abierto (UNA SOLA PÁGINA) -->
        <div class="book-open-wrapper">
          
          <!-- SOLO UNA PÁGINA del libro -->
          <div class="book-page">
            <!-- Margen rojo izquierdo -->
            <div class="red-margin"></div>
            
            <!-- Agujeros del lado izquierdo (efecto cuaderno) -->
            <div class="holes-container">
              <div class="hole" v-for="n in 8" :key="n"></div>
            </div>
            
            <!-- Contenido de la pestaña activa -->
            <div class="page-content">
              <!-- Botón cerrar dentro de la página -->
              <button class="close-book-btn" @click="closeBook" aria-label="Cerrar libro" title="Cerrar libro">
                <ArrowLeft :size="20" />
              </button>
              
              <h2 class="tab-title">
                <span class="chapter-label">Capítulo {{ activeTab + 1 }}:</span>
                {{ tabs[activeTab] }}
              </h2>
              <div class="tab-content">
                <p v-if="!hasContent" class="empty-content">
                  Sin información aún...
                </p>
                <div v-else class="content-text">
                  <slot :name="`content-${activeTab}`"></slot>
                </div>
              </div>
            </div>
            
            <!-- Controles de navegación inferior -->
            <div class="page-controls">
              <!-- Botones de navegación -->
              <div class="nav-buttons">
                <button 
                  class="nav-btn prev-btn" 
                  @click="prevTab"
                  :disabled="activeTab === 0"
                  title="Página anterior"
                >
                  ◄
                </button>
                <button 
                  class="nav-btn next-btn" 
                  @click="nextTab"
                  :disabled="activeTab === tabs.length - 1"
                  title="Página siguiente"
                >
                  ►
                </button>
              </div>
              
              <!-- Número de página -->
              <div class="page-number">{{ activeTab + 1 }} of {{ tabs.length }}</div>
            </div>
          </div>

          <!-- Tabs laterales (saliendo del libro) - ESTILO HORIZONTAL CON FLECHA -->
          <div class="tabs-sidebar">
            <button
              v-for="(tab, index) in tabs"
              :key="index"
              class="tab-btn-side"
              :class="{ active: activeTab === index }"
              :style="{ backgroundColor: activeTab === index ? '#f5ede0' : getTabColor(index) }"
              @click="selectTab(index)"
              :title="tab"
            >
              <!-- Pestaña activa: muestra Chapter + nombre + flecha -->
              <template v-if="activeTab === index">
                <div class="tab-active-content">
                  <span class="tab-chapter">Chapter {{ index + 1 }}:</span>
                  <span class="tab-name">{{ tab }}</span>
                  <span class="tab-arrow">➤</span>
                </div>
              </template>
              <!-- Pestaña inactiva: solo muestra + -->
              <span v-else class="tab-plus-side">+</span>
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { ArrowLeft } from "lucide-vue-next";

// Props para controlar el modo
const props = defineProps({
  standaloneMode: {
    type: Boolean,
    default: true // Por defecto, muestra el cofre cerrado
  }
});

// Emits para comunicación con modal
const emit = defineEmits(["close"]);

const isOpen = ref(false);
const activeTab = ref(0); // Primera pestaña activa por defecto
const hasContent = ref(false);

const tabs = ["Sobre mi", "Lo que hago", "Proyectos", "Contacto"];

// Colores para las pestañas
const tabColors = [
  '#e8b68c', // Sobre mi - naranja claro
  '#d4a373', // Lo que hago - marrón medio
  '#c99562', // Proyectos - marrón
  '#b88654'  // Contacto - marrón oscuro
];

const getTabColor = (index) => {
  return tabColors[index] || '#d4a373';
};

const openBook = () => {
  isOpen.value = true;
  activeTab.value = 0; // Siempre abre con la primera pestaña activa
};

const closeBook = () => {
  if (props.standaloneMode) {
    isOpen.value = false;
  } else {
    emit("close");
  }
};

const selectTab = (index) => {
  activeTab.value = index;
};

const nextTab = () => {
  if (activeTab.value < tabs.length - 1) {
    activeTab.value++;
  }
};

const prevTab = () => {
  if (activeTab.value > 0) {
    activeTab.value--;
  }
};

// Iniciar el libro abierto si no está en modo standalone
if (!props.standaloneMode) {
  isOpen.value = true;
}
</script>

<style scoped>
/* Contenedor principal */
.book-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  min-height: 500px;
  position: relative;
  padding: 2rem;
}

/* ============================================
   LIBRO CERRADO EN COFRE - ESTILO MINECRAFT
   ============================================ */
.book-closed {
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0;
  animation: chestBounce 3s ease-in-out infinite;
  position: absolute;
  top: 2rem;
  left: 2rem;
  width: auto;
}

@keyframes chestBounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-8px);
  }
}

/* Contenedor del cofre y libro */
.chest-container {
  position: relative;
  width: 120px;
  height: 100px;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

/* COFRE (Minecraft chest con lava) */
.chest {
  width: 100%;
  height: 70px;
  position: relative;
  filter: drop-shadow(4px 4px 0 rgba(0, 0, 0, 0.6));
  image-rendering: pixelated;
}

/* Tapa del cofre (ROJA/NARANJA - LAVA) */
.chest-lid {
  position: absolute;
  width: 100%;
  height: 28px;
  top: 0;
  background: linear-gradient(180deg, #ff6b1a 0%, #ff5500 30%, #cc4400 70%, #aa3300 100%);
  border: 3px solid #333333;
  border-bottom: 4px solid #1a1a1a;
}

.chest-lid-front {
  width: 100%;
  height: 100%;
  background: linear-gradient(
    180deg,
    #ff8833 0%,
    #ff6b1a 20%,
    #ff5500 40%,
    #ee4400 60%,
    #cc3300 80%,
    #bb2200 100%
  );
  border-bottom: 2px solid #1a1a1a;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

/* Textura de lava animada en la tapa */
.chest-lid-front::before {
  content: "";
  position: absolute;
  width: 100%;
  height: 100%;
  background: 
    radial-gradient(circle at 20% 30%, rgba(255, 200, 0, 0.3) 0%, transparent 20%),
    radial-gradient(circle at 70% 60%, rgba(255, 150, 0, 0.2) 0%, transparent 15%),
    radial-gradient(circle at 40% 80%, rgba(255, 100, 0, 0.25) 0%, transparent 18%);
  animation: lavaFlow 4s ease-in-out infinite;
  z-index: 1;
}

@keyframes lavaFlow {
  0%, 100% {
    opacity: 0.5;
  }
  50% {
    opacity: 0.8;
  }
}

/* Bisagra izquierda */
.chest-lid-front::after {
  content: "";
  position: absolute;
  width: 14px;
  height: 10px;
  background: linear-gradient(180deg, #666666 0%, #444444 100%);
  left: 12%;
  top: 50%;
  transform: translateY(-50%);
  border: 2px solid #222222;
  border-radius: 2px;
  box-shadow: inset 1px 1px 0 rgba(255, 255, 255, 0.2);
  z-index: 2;
}

/* Cuerpo del cofre (GRIS) */
.chest-body {
  position: absolute;
  width: 100%;
  height: 46px;
  top: 28px;
  background: linear-gradient(180deg, #888888 0%, #666666 30%, #555555 70%, #444444 100%);
  border: 3px solid #333333;
  border-top: 2px solid #777777;
  display: flex;
}

/* Paneles del cofre */
.chest-panel {
  flex: 1;
  background: linear-gradient(90deg, #777777 0%, #666666 40%, #555555 60%, #444444 100%);
  border-right: 3px solid #222222;
  position: relative;
  overflow: hidden;
}

.chest-panel:last-child {
  border-right: none;
}

/* Textura metálica en paneles */
.chest-panel::before {
  content: "";
  position: absolute;
  width: 100%;
  height: 100%;
  background: 
    repeating-linear-gradient(
      0deg,
      transparent,
      transparent 4px,
      rgba(0, 0, 0, 0.15) 4px,
      rgba(0, 0, 0, 0.15) 6px
    ),
    repeating-linear-gradient(
      90deg,
      transparent,
      transparent 8px,
      rgba(255, 255, 255, 0.05) 8px,
      rgba(255, 255, 255, 0.05) 10px
    );
  pointer-events: none;
}

/* Cerradura en panel central */
.chest-panel-center::after {
  content: "";
  position: absolute;
  width: 10px;
  height: 14px;
  background: linear-gradient(180deg, #555555 0%, #333333 100%);
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  border: 2px solid #1a1a1a;
  border-radius: 1px;
  box-shadow: 
    inset 1px 1px 0 rgba(0, 0, 0, 0.8),
    inset -1px -1px 0 rgba(255, 255, 255, 0.1);
  z-index: 2;
}

/* Punto de la cerradura */
.chest-panel-center::before {
  content: "";
  position: absolute;
  width: 3px;
  height: 3px;
  background: #222222;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  border-radius: 50%;
  box-shadow: 0 0 2px rgba(0, 0, 0, 0.8);
  z-index: 3;
}

/* LIBRO saliendo del cofre */
.book-from-chest {
  position: absolute;
  right: 10px;
  top: 30px;
  width: 45px;
  height: 50px;
  display: flex;
  z-index: 5;
  filter: drop-shadow(2px 2px 0 rgba(0, 0, 0, 0.3));
}

.book-spine-chest {
  width: 8px;
  height: 100%;
  background: linear-gradient(90deg, #8b5a3c 0%, #6b4a2c 100%);
  border: 2px solid #3d2310;
  border-radius: 2px;
}

.book-front-chest {
  flex: 1;
  background: linear-gradient(135deg, #d2691e 0%, #a0522d 100%);
  border: 2px solid #3d2310;
  border-left: none;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 
    inset -2px -2px 0 rgba(0, 0, 0, 0.3),
    inset 2px 2px 0 rgba(255, 255, 255, 0.1);
  position: relative;
}

.book-text-chest {
  font-family: 'Press Start 2P', monospace;
  font-size: 0.6rem;
  color: #ffb800;
  font-weight: bold;
  writing-mode: vertical-rl;
  text-orientation: mixed;
  letter-spacing: 2px;
  text-shadow: 1px 1px 0 #3d2310;
}

/* ============================================
   LIBRO ABIERTO - EN EL MISMO LUGAR (SIN MODAL)
   ============================================ */
.book-open-container {
  position: relative;
  width: 100%;
  max-width: 700px;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.close-btn {
  position: absolute;
  top: -40px;
  right: 10px;
  background: transparent;
  border: none;
  color: #ff00ff;
  font-size: 2rem;
  cursor: pointer;
  font-family: 'Press Start 2P', 'Courier New', monospace;
  text-shadow: 0 0 15px #ff00ff;
  transition: all 0.2s;
  z-index: 1001;
  font-weight: bold;
  display: none;
}

.close-book-btn {
  position: absolute;
  top: 1rem;
  left: 1rem;
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

/* ============================================
   LIBRO ABIERTO - UNA SOLA PÁGINA
   ============================================ */
.book-open-wrapper {
  position: relative;
  display: flex;
  background: #f5ede0;
  border: 8px solid #5a3825;
  box-shadow: 
    0 0 40px rgba(0, 0, 0, 0.7),
    inset 0 0 20px rgba(0, 0, 0, 0.1);
  min-height: 600px;
  width: 100%;
}

.book-page {
  flex: 1;
  padding: 3rem 3rem 4rem 2.5rem;
  position: relative;
  background: linear-gradient(135deg, #f5ede0 0%, #f0e6d6 100%);
  overflow: hidden;
}

/* Textura de papel con líneas */
.book-page::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-image: 
    repeating-linear-gradient(
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
  left: 2.2rem;
  top: 2.5rem;
  bottom: 2.5rem;
  width: 3px;
  background: rgba(220, 80, 80, 0.4);
  pointer-events: none;
  z-index: 1;
}

/* Agujeros del lado izquierdo (efecto cuaderno) */
.holes-container {
  position: absolute;
  left: 1.2rem;
  top: 3.5rem;
  bottom: 3.5rem;
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
  box-shadow: 
    inset 2px 2px 3px rgba(0, 0, 0, 0.3),
    0 1px 2px rgba(0, 0, 0, 0.2);
}

.page-content {
  min-height: calc(100% - 60px);
  display: flex;
  flex-direction: column;
  position: relative;
  z-index: 2;
  margin-left: 1.5rem;
}

/* Controles de navegación en la parte inferior */
.page-controls {
  position: absolute;
  bottom: 1.5rem;
  left: 2.5rem;
  right: 2rem;
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
  width: 35px;
  height: 35px;
  background: #d4a373;
  border: 4px solid #5a3825;
  cursor: pointer;
  font-family: 'Press Start 2P', 'Courier New', monospace;
  font-size: 0.7rem;
  color: #5a3825;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 
    inset -2px -2px 0 rgba(0, 0, 0, 0.3),
    inset 2px 2px 0 rgba(255, 255, 255, 0.2),
    3px 3px 0 rgba(0, 0, 0, 0.3);
  transition: all 0.2s;
}

.nav-btn:hover:not(:disabled) {
  background: #e8c88c;
  transform: translateY(-2px);
  box-shadow: 
    inset -2px -2px 0 rgba(0, 0, 0, 0.3),
    inset 2px 2px 0 rgba(255, 255, 255, 0.3),
    4px 4px 0 rgba(0, 0, 0, 0.4);
}

.nav-btn:active:not(:disabled) {
  transform: translateY(0);
  box-shadow: 
    inset 2px 2px 0 rgba(0, 0, 0, 0.3),
    2px 2px 0 rgba(0, 0, 0, 0.3);
}

.nav-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

/* Número de página */
.page-number {
  font-family: 'Press Start 2P', 'Courier New', monospace;
  font-size: 0.5rem;
  color: rgba(90, 56, 37, 0.6);
}

/* ============================================
   TABS LATERALES - HORIZONTAL CON FLECHA
   ============================================ */
.tabs-sidebar {
  position: absolute;
  right: -160px;
  top: -8px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  z-index: 100;
}

.tab-btn-side {
  border: 5px solid #5a3825;
  font-family: 'Press Start 2P', 'Courier New', monospace;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: 
    inset -3px -3px 0 rgba(0, 0, 0, 0.3),
    inset 3px 3px 0 rgba(255, 255, 255, 0.2),
    5px 3px 0 rgba(0, 0, 0, 0.4);
  color: #5a3825;
  font-weight: bold;
  /* Tamaño por defecto (solo +) */
  width: 50px;
  height: 50px;
  padding: 0.6rem;
  transition: filter 0.2s ease;
}

/* Pestaña activa - HORIZONTAL con Chapter + nombre + flecha */
.tab-btn-side.active {
  color: #3d2515;
  box-shadow: 
    inset 3px 3px 0 rgba(255, 255, 255, 0.5),
    inset -3px -3px 0 rgba(0, 0, 0, 0.2),
    4px 2px 0 rgba(0, 0, 0, 0.2);
  /* Más ancha cuando está activa */
  width: 150px;
  height: 60px;
  padding: 0.8rem 1rem;
}

.tab-btn-side:hover {
  filter: brightness(1.1);
}

/* Contenido de la pestaña activa (horizontal) */
.tab-active-content {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.2rem;
  width: 100%;
  position: relative;
}

.tab-chapter {
  font-size: 0.35rem;
  opacity: 0.7;
  text-transform: capitalize;
  display: block;
  line-height: 1.2;
}

.tab-name {
  font-size: 0.45rem;
  text-transform: capitalize;
  display: block;
  line-height: 1.3;
}

.tab-arrow {
  position: absolute;
  right: -5px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 0.8rem;
  opacity: 0.8;
}

.tab-plus-side {
  font-size: 1.2rem;
  font-weight: bold;
  text-shadow: 1px 1px 0 rgba(255, 255, 255, 0.3);
}

/* ============================================
   CONTENIDO DE LA PÁGINA
   ============================================ */
.tab-title {
  font-family: 'Press Start 2P', 'Courier New', monospace;
  font-size: 0.75rem;
  color: #5a3825;
  margin-bottom: 1.5rem;
  text-transform: capitalize;
  border-bottom: 3px solid #5a3825;
  padding-bottom: 0.8rem;
  letter-spacing: 0.05em;
  font-weight: bold;
  position: relative;
  padding-top: 1rem;
}

.chapter-label {
  display: block;
  font-size: 0.45rem;
  opacity: 0.6;
  margin-bottom: 0.5rem;
  text-transform: capitalize;
}

.tab-content {
  flex: 1;
  font-family: 'Press Start 2P', 'Courier New', monospace;
  font-size: 0.5rem;
  color: #5a3825;
  line-height: 2;
  overflow-y: auto;
  padding-right: 1rem;
  max-height: 400px;
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

.empty-content {
  text-align: center;
  color: rgba(90, 56, 37, 0.4);
  padding: 3rem 2rem;
  font-style: italic;
  line-height: 2;
  font-size: 0.55rem;
}

.content-text {
  line-height: 2;
}

/* ============================================
   TRANSICIONES
   ============================================ */
.book-fade-enter-active,
.book-fade-leave-active {
  transition: opacity 0.3s ease;
}

.book-fade-enter-from,
.book-fade-leave-to {
  opacity: 0;
}

/* ============================================
   RESPONSIVE
   ============================================ */
@media (max-width: 968px) {
  .book-open-wrapper {
    flex-direction: column;
    min-height: auto;
  }

  .tabs-sidebar {
    position: static;
    flex-direction: row;
    height: auto;
    width: 100%;
    padding: 1rem;
    gap: 0.5rem;
    flex-wrap: wrap;
    justify-content: center;
    border-top: 5px solid #5a3825;
    background: #e8dcc8;
  }

  .tab-btn-side {
    width: 50px;
    height: 50px;
    padding: 0.5rem;
  }

  .tab-btn-side.active {
    width: auto;
    min-width: 140px;
    height: auto;
    padding: 0.6rem 1rem;
  }

  .tab-chapter {
    font-size: 0.3rem;
  }

  .tab-name {
    font-size: 0.4rem;
  }

  .tab-arrow {
    font-size: 0.7rem;
  }

  .tab-plus-side {
    font-size: 1rem;
  }

  .book-page {
    padding: 2rem 1.5rem 3.5rem 1.5rem;
  }

  .red-margin {
    left: 1.5rem;
  }

  .holes-container {
    left: 0.8rem;
  }

  .hole {
    width: 10px;
    height: 10px;
  }

  .page-content {
    margin-left: 1rem;
  }

  .tab-title {
    font-size: 0.65rem;
  }

  .chapter-label {
    font-size: 0.4rem;
  }

  .tab-content {
    font-size: 0.45rem;
    max-height: 300px;
  }

  .page-controls {
    bottom: 1rem;
    left: 1.5rem;
    right: 1.5rem;
  }

  .nav-btn {
    width: 32px;
    height: 32px;
    font-size: 0.6rem;
  }

  .page-number {
    font-size: 0.45rem;
  }
}

@media (max-width: 768px) {
  .book-closed-wrapper {
    width: 220px;
    height: 160px;
  }

  .book-title {
    font-size: 0.8rem;
  }

  .book-subtitle {
    font-size: 0.4rem;
  }
}

@media (max-width: 480px) {
  .book-closed-wrapper {
    width: 180px;
    height: 130px;
  }

  .book-title {
    font-size: 0.65rem;
    padding: 0.5rem;
  }

  .book-subtitle {
    font-size: 0.35rem;
  }

  .book-page {
    padding: 1.5rem 1rem 3rem 1rem;
  }

  .holes-container {
    left: 0.5rem;
  }

  .hole {
    width: 8px;
    height: 8px;
  }

  .page-content {
    margin-left: 0.5rem;
  }

  .tab-title {
    font-size: 0.55rem;
  }

  .chapter-label {
    font-size: 0.35rem;
  }

  .tab-content {
    font-size: 0.4rem;
    max-height: 250px;
  }

  .tab-btn-side {
    width: 45px;
    height: 45px;
  }

  .tab-btn-side.active {
    min-width: 120px;
    padding: 0.5rem 0.8rem;
  }

  .tab-chapter {
    font-size: 0.28rem;
  }

  .tab-name {
    font-size: 0.35rem;
  }

  .page-controls {
    bottom: 0.8rem;
    left: 1rem;
    right: 1rem;
  }

  .nav-btn {
    width: 28px;
    height: 28px;
    font-size: 0.55rem;
  }

  .page-number {
    font-size: 0.4rem;
  }
}
</style>