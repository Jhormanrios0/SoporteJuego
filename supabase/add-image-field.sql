-- ==================== AGREGAR CAMPO DE IMAGEN A JUGADORES ====================
-- Ejecutar este script en el SQL Editor de Supabase
-- Esto agrega un campo para guardar la URL de la imagen de perfil
-- ============================================================================

-- Agregar columna image_url a la tabla players
ALTER TABLE players
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Comentario para documentar la columna
COMMENT ON COLUMN players.image_url IS 'URL de la imagen de perfil del jugador';
