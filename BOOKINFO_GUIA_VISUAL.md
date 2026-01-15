# 🎮 BookInfo - Minecraft Edition

## Resumen Visual

### LIBRO CERRADO
```
┌─────────────────────────┐
│                         │
│   ╔════════════════╗    │
│   ║ MINECRAFT BOOK ║ <-- PLUMA
│   ║  (Rebotando)   ║
│   ║                ║
│   ║   [PORTADA]    ║
│   ║                ║
│   ║   BROWN TONES  ║
│   ║                ║
│   ╚════════════════╝
│                         │
│   "Haz clic para abrir" │
│    (Pulsing animation)  │
└─────────────────────────┘
```

### LIBRO ABIERTO
```
┌────────────────────────────────────────────────┐
│                   [X CERRAR]                   │
│                                                │
│  ╔─────────────────┬──────────────────────╗   │
│  │                 │ [Sobre mi] [+] [+] [+] │   │
│  │  PÁGINA         ├──────────────────────│   │
│  │  IZQUIERDA      │ SOBRE MI             │   │
│  │  (Decorativa)   │                      │   │
│  │  • • •          │ Sin información      │   │
│  │                 │ aún...               │   │
│  │  • • •          │                      │   │
│  │                 │                      │   │
│  │  • • •          │                      │   │
│  ╚─────────────────┴──────────────────────╝   │
│                                                │
└────────────────────────────────────────────────┘
```

## Especificaciones Técnicas

### Colores Minecraft Auténticos
| Elemento | Color | Hex |
|----------|-------|-----|
| Portada | Marrón Oscuro | #8b5a3c |
| Gradiente | Marrón Claro | #a0613f |
| Papel | Beige Antiguo | #f5e6d3 |
| Texto | Marrón Oscuro | #3d2310 |
| Pluma | Tan | #d4a574 |
| Punta Pluma | Negro | #2a2a2a |

### Dimensiones
- **Libro Cerrado**: 200px × 240px
- **Libro Abierto**: max 1000px × min 600px
- **Pluma**: 30px × 120px
- **Padding Páginas**: 3rem

### Pestañas
1. **Sobre mi** (Activa por defecto)
2. **Lo que hago**
3. **Proyectos**
4. **Contacto**

## Funcionalidades

✅ Libro rebota infinitamente cuando está cerrado
✅ Click abre en modal centrado y ampliado
✅ Primera pestaña activa al abrir
✅ Página izquierda decorativa con puntos
✅ Cambio de contenido con click en pestañas
✅ Símbol "+" visible en pestañas inactivas
✅ Efectos hover mejorados en botones
✅ Scroll integrado si contenido es largo
✅ Cierre con X o click fuera
✅ Transición suave fade in/out
✅ Responsive (oculta página izquierda en mobile)
✅ Textura pixel art simulada
✅ Sombras 3D realistas

## Ubicación en ProfileView

```vue
<profile-hero />
<!-- NUEVO: Libro de Información -->
<div class="profile-book-section">
  <BookInfo>
    <template #content-0>
      <!-- Contenido "Sobre mi" -->
    </template>
    <template #content-1>
      <!-- Contenido "Lo que hago" -->
    </template>
    <template #content-2>
      <!-- Contenido "Proyectos" -->
    </template>
    <template #content-3>
      <!-- Contenido "Contacto" -->
    </template>
  </BookInfo>
</div>
```

## Animaciones

### Libro Cerrado
- **Bounce**: 2.5s infinite ease-in-out
- Y: 0 → -15px → 0
- Rotación: 0° → -2° → 0°

### Pestaña Hover
- **Elevación**: translateY(-2px)
- **Shadow**: Aumenta profundidad

### Pestaña Activa
- **Estado**: Presionada (translateY(1px))
- **Color**: Destacado

### Modal
- **Fade**: 0.3s ease
- **Backdrop**: blur(1px)

## Uso del Componente

### Importación
```javascript
import BookInfo from "@/components/BookInfo.vue";
```

### En Template
```vue
<BookInfo>
  <template #content-0>
    <p>Mi información personal aquí...</p>
  </template>
  <!-- Más slots... -->
</BookInfo>
```

---

**Componente: BookInfo.vue**
**Estado: ✅ Completado**
**Estilo: 🎮 Minecraft Auténtico**
**Tamaño: 200x240px cerrado, Expandible abierto**
