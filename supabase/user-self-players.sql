-- ==================== JUGADORES AUTO-REGISTRADOS (USERS) ====================
-- Ejecutar este script en el SQL Editor de Supabase (después de schema.sql + add-image-field.sql)
-- Objetivo:
-- - Vincular players con auth.users (user_id)
-- - Guardar nombre/apellido públicamente
-- - Permitir que cada usuario cree/edite SOLO sus datos públicos (no vidas)
-- ============================================================================

-- 1) Extender tabla players
ALTER TABLE public.players
  ADD COLUMN IF NOT EXISTS user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT;

-- 2) (Opcional recomendado) permitir nombres repetidos
-- Si tu tabla tiene el constraint UNIQUE en nickname (del schema.sql), lo removemos.
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

-- 3) RLS policies: permitir que usuarios creen/actualicen su propio jugador
-- (Nota: las policies se OR-ean; las de admin siguen funcionando)
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

-- 4) Restringir columnas editables por usuarios (evita que cambien vidas)
-- Postgres permite GRANT por columna.
REVOKE UPDATE ON public.players FROM authenticated;
GRANT UPDATE (first_name, last_name, nickname, image_url) ON public.players TO authenticated;

REVOKE INSERT ON public.players FROM authenticated;
GRANT INSERT (user_id, first_name, last_name, nickname, image_url) ON public.players TO authenticated;

-- SELECT ya es público por policy en schema.sql (Lectura pública de players)
