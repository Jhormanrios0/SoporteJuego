# Configurar Subida de Imágenes

## Pasos para habilitar la subida de imágenes de jugadores:

### 1. Crear Storage Bucket (mediante UI de Supabase)

Go to tu proyecto Supabase:

1. Ve a **Storage** en el menú izquierdo
2. Haz clic en **Create a new bucket**
3. Nombre: `player-images`
4. Marca como **Public** (permite lectura pública)
5. Haz clic en **Create bucket**

### 2. Ejecutar políticas de seguridad (SQL)

Ve a **SQL Editor** y ejecuta el contenido de `supabase/create-storage-bucket.sql`

Esto configura:

- ✅ Lectura pública (todos pueden ver las imágenes)
- ✅ Solo admin puede subir imágenes
- ✅ Solo admin puede eliminar imágenes

### 3. Actualizar settings de Storage (opcional pero recomendado)

En Supabase, ve a **Storage** → **Settings** y:

- Asegúrate de que el bucket `player-images` esté configurado correctamente
- Máximo de tamaño de archivo: 5MB (ya configurado en el modal)

## ¿Cómo funciona?

1. El admin hace clic en **"+ Crear Jugador"** en el header
2. Se abre un modal con:
   - Campo de nickname
   - Zona de carga de imagen (drag & drop o click)
   - Preview de la imagen seleccionada
3. Al hacer clic en "CREAR":
   - La imagen se sube a Storage
   - Se obtiene la URL pública
   - El jugador se crea con la URL de imagen
4. En la vista pública, cada jugador muestra su imagen en la tarjeta

## Validaciones

- ✅ Solo imágenes (JPG, PNG, GIF, WebP, etc.)
- ✅ Máximo 5MB
- ✅ Nickname es requerido
- ✅ Imagen es opcional

## Troubleshooting

Si no puedes subir imágenes:

1. Verifica que el bucket `player-images` exista en Storage
2. Confirma que esté marcado como **Public**
3. Ejecuta el script SQL de políticas de seguridad
4. Recarga el navegador (F5)

Si las imágenes no aparecen:

1. Verifica que `image_url` tenga un valor en la base de datos
2. Abre la consola del navegador (F12) y busca errores
3. Asegúrate de que las políticas de lectura pública estén habilitadas
