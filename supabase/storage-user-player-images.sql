-- ==================== STORAGE: IMÁGENES SUBIDAS POR USUARIO ====================
-- Ejecutar este script en el SQL Editor de Supabase (después de create-storage-bucket.sql)
-- Requiere que el upload use la ruta: `${auth.uid()}/<archivo>`
-- (el frontend ya sube como: `${userId}/${fileName}`)
-- ============================================================================

-- Permitir que usuarios autenticados suban su propia imagen (solo dentro de su carpeta UID)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Usuarios pueden subir su imagen'
  ) THEN
    CREATE POLICY "Usuarios pueden subir su imagen"
      ON storage.objects FOR INSERT
      TO authenticated
      WITH CHECK (
        bucket_id = 'player-images'
        AND (name LIKE auth.uid()::text || '/%')
      );
  END IF;
END $$;

-- Permitir que usuarios autenticados eliminen su propia imagen
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Usuarios pueden eliminar su imagen'
  ) THEN
    CREATE POLICY "Usuarios pueden eliminar su imagen"
      ON storage.objects FOR DELETE
      TO authenticated
      USING (
        bucket_id = 'player-images'
        AND (name LIKE auth.uid()::text || '/%')
      );
  END IF;
END $$;
