ALTER TABLE public.players
  ADD COLUMN IF NOT EXISTS user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'players_nickname_key'
      AND conrelid = 'public.players'::regclass
  ) THEN
    ALTER TABLE public.players DROP CONSTRAINT players_nickname_key;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'players'
      AND policyname = 'Usuarios pueden insertar su jugador'
  ) THEN
    CREATE POLICY "Usuarios pueden insertar su jugador"
      ON public.players
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'players'
      AND policyname = 'Usuarios pueden actualizar su jugador'
  ) THEN
    CREATE POLICY "Usuarios pueden actualizar su jugador"
      ON public.players
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

REVOKE UPDATE ON public.players FROM authenticated;
GRANT UPDATE (first_name, last_name, nickname, image_url) ON public.players TO authenticated;

REVOKE INSERT ON public.players FROM authenticated;
GRANT INSERT (user_id, first_name, last_name, nickname, image_url) ON public.players TO authenticated;
