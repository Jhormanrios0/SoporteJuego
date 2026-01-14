<template>
    <section class="rules-section" @click.self="$emit('close')">
        <div class="book-container">
            <!-- Página Izquierda -->
            <div class="book-page left-page">
                <div class="page-border">
                    <div class="page-content">
                        <div class="page-number">Página {{ currentPage }} de {{ totalPages }}</div>
                        <div class="rule-text">{{ rules[currentPage - 1] }}</div>
                    </div>
                </div>
            </div>

            <!-- Página Derecha -->
            <div class="book-page right-page">
                <div class="page-border">
                    <div class="page-content">
                        <div class="page-number">Página {{ currentPage + 1 }} de {{ totalPages }}</div>
                        <div class="rule-text">{{ rules[currentPage] }}</div>
                    </div>
                </div>
            </div>

            <!-- Controles de navegación -->
            <div class="controls">
                <button 
                    @click="previousPage" 
                    :disabled="currentPage === 1"
                    class="nav-button"
                >
                    ← Anterior
                </button>
                <button @click="$emit('close')" class="close-button">
                    Cerrar Libro
                </button>
                <button 
                    @click="nextPage" 
                    :disabled="currentPage >= totalPages - 1"
                    class="nav-button"
                >
                    Siguiente →
                </button>
            </div>
        </div>
    </section>
</template>

<script setup>
import { ref, computed } from 'vue'

const currentPage = ref(1)

// Array de reglas del juego
const rules = [
    `Reglas del Juego

Este es un juego de supervivencia donde cada jugador comienza con 10 corazones de vida.

El objetivo es ser el último jugador con vida restante.`,

    `Cómo Perder Vida

Los jugadores pueden perder corazones por:
- Desafíos fallidos
- Votaciones del grupo
- Eventos especiales
- Penalizaciones por romper reglas`,

    `Sistema de Corazones

Cada jugador tiene:
- Máximo 10 corazones
- Mínimo 0 corazones
- Al llegar a 0, el jugador es eliminado del juego`,

    `Votaciones

Los jugadores pueden votar para:
- Quitar vida a otros jugadores
- Añadir desafíos
- Cambiar reglas temporalmente

Se requiere mayoría simple.`,

    `Desafíos

Tipos de desafíos:
- Individuales
- Por equipos
- Sorpresa
- Timed (con tiempo límite)`,

    `Reglas Especiales

- No se permite el sabotaje físico
- Respeta las decisiones del moderador
- Sé honesto con tus acciones
- Diviértete y sé justo`,

    `Eliminación

Cuando un jugador llega a 0 corazones:
- Queda eliminado
- Puede observar el resto del juego
- No puede influir en decisiones`,

    `Victoria

El ganador es:
- El último jugador con vida
- O el equipo superviviente
- Recibe un premio especial

¡Buena suerte a todos!`
]

const totalPages = computed(() => rules.length)

const nextPage = () => {
    if (currentPage.value < totalPages.value - 1) {
        currentPage.value += 2
    }
}

const previousPage = () => {
    if (currentPage.value > 1) {
        currentPage.value -= 2
    }
}
</script>

<style scoped>
.rules-section {
    position: fixed;
    top: 0;
    right: 0;
    width: 100vw;
    height: 100vh;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: #222222b2;
    backdrop-filter: blur(5px);
    z-index: 1000;
}

.book-container {
    display: flex;
    gap: 20px;
    position: relative;
    filter: drop-shadow(0 10px 30px rgba(0, 0, 0, 0.5));
}

.book-page {
    width: 320px;
    height: 450px;
    background: linear-gradient(to bottom, #f4e8d0 0%, #e8dcc4 100%);
    border-radius: 8px;
    position: relative;
}

.left-page {
    border-top-left-radius: 8px;
    border-bottom-left-radius: 8px;
    box-shadow: inset -3px 0 8px rgba(0, 0, 0, 0.1);
}

.right-page {
    border-top-right-radius: 8px;
    border-bottom-right-radius: 8px;
    box-shadow: inset 3px 0 8px rgba(0, 0, 0, 0.1);
}

.page-border {
    position: absolute;
    top: 15px;
    left: 15px;
    right: 15px;
    bottom: 15px;
    border: 3px solid #8b4513;
    border-radius: 4px;
    padding: 15px;
}

.page-content {
    height: 100%;
    display: flex;
    flex-direction: column;
}

.page-number {
    font-family: 'Courier New', monospace;
    font-size: 12px;
    text-align: center;
    color: #4a4a4a;
    margin-bottom: 15px;
    padding-bottom: 8px;
    border-bottom: 1px solid #8b4513;
}

.rule-text {
    font-family: 'Courier New', monospace;
    font-size: 14px;
    line-height: 1.6;
    color: #2a2a2a;
    white-space: pre-wrap;
    overflow-y: auto;
    flex: 1;
    text-shadow: 0.5px 0.5px 0px rgba(0, 0, 0, 0.1);
}

.rule-text::-webkit-scrollbar {
    width: 6px;
}

.rule-text::-webkit-scrollbar-track {
    background: #e8dcc4;
    border-radius: 3px;
}

.rule-text::-webkit-scrollbar-thumb {
    background: #8b4513;
    border-radius: 3px;
}

.controls {
    position: absolute;
    bottom: -60px;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    gap: 15px;
    align-items: center;
}

.nav-button,
.close-button {
    padding: 10px 20px;
    font-family: 'Courier New', monospace;
    font-size: 14px;
    border: 2px solid #8b4513;
    border-radius: 4px;
    background: #f4e8d0;
    color: #2a2a2a;
    cursor: pointer;
    transition: all 0.2s;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.nav-button:hover:not(:disabled),
.close-button:hover {
    background: #e8dcc4;
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
}

.nav-button:disabled {
    opacity: 0.4;
    cursor: not-allowed;
}

.close-button {
    background: #d4a574;
    font-weight: bold;
}

.close-button:hover {
    background: #c49564;
}

@media (max-width: 768px) {
    .book-container {
        flex-direction: column;
        gap: 10px;
    }

    .book-page {
        width: 90vw;
        max-width: 350px;
        height: 400px;
    }

    .right-page {
        display: none;
    }

    .controls {
        position: relative;
        bottom: auto;
        margin-top: 20px;
        flex-wrap: wrap;
    }
}
</style>