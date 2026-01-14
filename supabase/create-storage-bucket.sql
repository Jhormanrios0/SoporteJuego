INSERT INTO storage.buckets (id, name, public)
VALUES ('player-images', 'player-images', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Lectura pública'
  ) THEN
    CREATE POLICY "Lectura pública"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'player-images');
  END IF;
END $$;
