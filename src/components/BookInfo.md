# Componente BookInfo

Componente interactivo estilo 8 bits que simula un libro con pestañas de información personal.

## Características

- **Diseño Pixel Art**: Libro con estilo retro 8 bits
- **Libro Cerrado**: Al inicio el libro está cerrado y flotan con una animación suave
- **Abrir Libro**: Click en el libro abre un modal con el libro expandido
- **4 Pestañas**: Sobre mi, Lo que hago, Proyectos, Contacto
- **Pestaña Activa**: Al abrir el libro, "Sobre mi" aparece como activa por defecto
- **Responsive**: Se adapta a dispositivos móviles ocultando la página izquierda
- **Modal Overlay**: El libro se muestra centrado y grande en un modal

## Uso

### Importación

```vue
import BookInfo from "@/components/BookInfo.vue";
```

### Ejemplo Básico

```vue
<BookInfo>
  <template #content-0>
    <p>Mi información personal aquí...</p>
  </template>
  <template #content-1>
    <p>Lo que hago...</p>
  </template>
  <template #content-2>
    <p>Mis proyectos...</p>
  </template>
  <template #content-3>
    <p>Contacto: email@example.com</p>
  </template>
</BookInfo>
```

## Props

El componente no utiliza props actualmente. Toda la interacción se hace mediante slots.

## Slots

El componente expone 4 slots para el contenido de cada pestaña:

- `#content-0`: Contenido para la pestaña "Sobre mi"
- `#content-1`: Contenido para la pestaña "Lo que hago"
- `#content-2`: Contenido para la pestaña "Proyectos"
- `#content-3`: Contenido para la pestaña "Contacto"

## Personalización

### Cambiar los nombres de las pestañas

Editar el array `tabs` en el script del componente:

```javascript
const tabs = ["Sobre mi", "Lo que hago", "Proyectos", "Contacto"];
```

### Cambiar colores

Los colores están definidos en las variables CSS del componente. Editar las clases `.book-front`, `.book-page-left`, `.book-page-right` para cambiar los colores del libro.

### Cambiar tamaño del libro cerrado

Ajustar las dimensiones en `.book-cover`:

```css
.book-cover {
  width: 100px;  /* Cambiar aquí */
  height: 140px; /* Cambiar aquí */
}
```

## Comportamiento

1. El libro comienza **cerrado** con una animación de rebote
2. **Click** en el libro lo abre en un modal centrado
3. La primera pestaña (**Sobre mi**) está activa por defecto
4. Pasar el ratón sobre una pestaña muestra efecto visual
5. **Click** en una pestaña cambia el contenido mostrado
6. **Click** en la X o fuera del libro lo cierra

## Notas

- El contenido es responsive y se adapta a pantallas pequeñas
- El modal desactiva el scroll del body mientras está abierto
- Usa transiciones suaves para mejores animaciones
- Compatible con Vue 3 Composition API
