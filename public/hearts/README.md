# Sprites de Corazones Pixel Art

Esta carpeta debe contener los sprites de corazones en estilo 8-bit.

## Archivos necesarios

- `full.png` - Corazón lleno (vida disponible)
- `empty.png` - Corazón vacío (vida perdida)

## Especificaciones

**Tamaño recomendado:** 16x16 píxeles o 32x32 píxeles

**Formato:** PNG con transparencia

**Estilo:** Pixel art 8-bit, inspirado en Minecraft o juegos retro

## Cómo crear los sprites

### Opción 1: Herramientas online

- **Piskel** (https://www.piskelapp.com/) - Editor pixel art online gratis
- **Pixilart** (https://www.pixilart.com/)

### Opción 2: Software

- **Aseprite** (de pago, muy popular)
- **GIMP** con pixel pencil
- **Photoshop** con grid de píxeles

### Opción 3: Usar assets existentes (libre de derechos)

- **OpenGameArt.org**
- **Itch.io** (free game assets)
- **Kenney.nl** (assets gratuitos)

## Ejemplo de diseño

### Corazón lleno (full.png)

```
   ████  ████
 ██████████████
████████████████
████████████████
 ██████████████
  ████████████
   ████████
     ████
      ██
```

Color: Rojo (#ff0055) con sombras y bordes negros

### Corazón vacío (empty.png)

```
   ████  ████
 ██    ██    ██
██              ██
██              ██
 ██            ██
  ████      ████
   ████  ████
     ████
      ██
```

Color: Gris oscuro (#333333) con transparencia

## Alternativa temporal

Si no tienes los sprites, puedes usar emojis o caracteres Unicode:

- Lleno: ❤️ o ♥
- Vacío: ♡ o 🖤

Modifica HeartsBar.vue para usar texto en lugar de imágenes:

```vue
<span v-for="i in maxLives" :key="i" class="heart-text">
  {{ i <= lives ? '♥' : '♡' }}
</span>
```

## Ubicación

Coloca los archivos en:

```
public/
  hearts/
    full.png
    empty.png
```

Los archivos en `/public` son accesibles directamente como `/hearts/full.png` en el navegador.
