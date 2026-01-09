-- ==================== CREAR BUCKET DE STORAGE PARA IMÁGENES ====================
-- Ejecutar este script en el SQL Editor de Supabase
-- Esto crea un bucket público para almacenar imágenes de jugadores
-- ============================================================================

-- Crear el bucket (si no existe)
INSERT INTO storage.buckets (id, name, public)
VALUES ('player-images', 'player-images', true)
ON CONFLICT (id) DO NOTHING;

-- Crear política: Lectura pública
CREATE POLICY "Lectura pública"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'player-images');

-- Crear política: Solo admin puede subir
CREATE POLICY "Solo admin puede subir imágenes"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'player-images' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );

-- Crear política: Solo admin puede eliminar
CREATE POLICY "Solo admin puede eliminar imágenes"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'player-images' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.is_admin = true
    )
  );
