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
