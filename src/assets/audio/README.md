# Archivos de Audio para Sonidos de Daño

## Instrucciones:

Debes colocar dos archivos de audio en esta carpeta:

1. **hahaDamage.mp3** - Sonido divertido de daño (ej: "¡Ha ha!")
2. **MinecraftDamage.mp3** - Sonido de daño de Minecraft

### ¿Dónde obtener estos archivos?

Puedes:

- Descargar de repositorios de sonidos libres (Freesound, Zapsplat, etc.)
- Grabar tus propios sonidos
- Usar sonidos de Minecraft (assets de Minecraft)

### Requisitos de los archivos:

- Formato: MP3
- Duración: 0.5 - 1.5 segundos (máximo)
- Tamaño: < 500KB cada uno
- Nombre exacto:
  - `hahaDamage.mp3`
  - `MinecraftDamage.mp3`

### Ejemplo de uso:

```
src/assets/audio/
├── hahaDamage.mp3
└── MinecraftDamage.mp3
```

Cuando alguien reciba daño, se reproducirá uno de estos dos sonidos de forma aleatoria para TODOS los usuarios conectados.

### Sonidos recomendados:

**hahaDamage.mp3**: Un sonido cómico/divertido como una risa
**MinecraftDamage.mp3**: El sonido clásico de daño de Minecraft

Una vez que coloques los archivos aquí, el sistema funcionará automáticamente.
