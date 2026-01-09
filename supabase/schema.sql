-- ==================== SUPABASE SQL SCHEMA ====================
-- Ejecutar este script en el SQL Editor de Supabase
-- ============================================================

-- 1. CREAR TABLA DE JUGADORES
CREATE TABLE IF NOT EXISTS players (
    id BIGSERIAL PRIMARY KEY,
    nickname VARCHAR(30) UNIQUE NOT NULL,
    lives INTEGER NOT NULL DEFAULT 12 CHECK (lives >= 0 AND lives <= 12),
    max_lives INTEGER NOT NULL DEFAULT 12,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para búsquedas por nickname
CREATE INDEX IF NOT EXISTS idx_players_nickname ON players(nickname);

-- Índice para ordenar por vidas
CREATE INDEX IF NOT EXISTS idx_players_lives ON players(lives);


-- 2. CREAR TABLA DE PERFILES (para identificar admin)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger para crear perfil automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, is_admin)
    VALUES (NEW.id, NEW.email, false);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_profile_for_user();


-- 3. CREAR TABLA DE EVENTOS (historial de vidas)
CREATE TABLE IF NOT EXISTS life_events (
    id BIGSERIAL PRIMARY KEY,
    player_id BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    delta INTEGER NOT NULL, -- negativo si quita, positivo si resetea
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice para búsquedas por jugador
CREATE INDEX IF NOT EXISTS idx_life_events_player ON life_events(player_id);

-- Índice para ordenar por fecha
CREATE INDEX IF NOT EXISTS idx_life_events_created ON life_events(created_at DESC);


-- 4. TRIGGER PARA ACTUALIZAR updated_at EN PLAYERS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_players_updated_at
    BEFORE UPDATE ON players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- ==================== ROW LEVEL SECURITY (RLS) ====================

-- Habilitar RLS en todas las tablas
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE life_events ENABLE ROW LEVEL SECURITY;


-- POLICIES PARA PLAYERS
-- Lectura pública (cualquiera puede ver jugadores)
CREATE POLICY "Lectura pública de players"
    ON players FOR SELECT
    USING (true);

-- Solo admin autenticado puede INSERT/UPDATE/DELETE
CREATE POLICY "Solo admin puede insertar players"
    ON players FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.is_admin = true
        )
    );

CREATE POLICY "Solo admin puede actualizar players"
    ON players FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.is_admin = true
        )
    );

CREATE POLICY "Solo admin puede eliminar players"
    ON players FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.is_admin = true
        )
    );


-- POLICIES PARA PROFILES
-- Los usuarios pueden ver su propio perfil
CREATE POLICY "Usuarios pueden ver su perfil"
    ON profiles FOR SELECT
    USING (auth.uid() = id);


-- POLICIES PARA LIFE_EVENTS
-- Solo admin puede ver y crear eventos
CREATE POLICY "Solo admin puede ver eventos"
    ON life_events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.is_admin = true
        )
    );

CREATE POLICY "Solo admin puede crear eventos"
    ON life_events FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.is_admin = true
        )
    );


-- ==================== RPC FUNCTIONS ====================

-- FUNCIÓN: Quitar vidas a un jugador
CREATE OR REPLACE FUNCTION admin_remove_lives(
    p_player_id BIGINT,
    p_amount INTEGER,
    p_reason TEXT DEFAULT ''
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_lives INTEGER;
    new_lives INTEGER;
BEGIN
    -- Verificar que el usuario es admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    -- Obtener vidas actuales
    SELECT lives INTO current_lives
    FROM players
    WHERE id = p_player_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jugador no encontrado';
    END IF;

    -- Calcular nuevas vidas (nunca menor a 0)
    new_lives := GREATEST(current_lives - p_amount, 0);

    -- Actualizar jugador
    UPDATE players
    SET lives = new_lives
    WHERE id = p_player_id;

    -- Registrar evento
    INSERT INTO life_events (player_id, admin_id, delta, reason)
    VALUES (p_player_id, auth.uid(), -p_amount, p_reason);
END;
$$;


-- FUNCIÓN: Resetear vidas de un jugador a max_lives
CREATE OR REPLACE FUNCTION admin_reset_lives(
    p_player_id BIGINT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    max_lives_value INTEGER;
BEGIN
    -- Verificar que el usuario es admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    -- Obtener max_lives del jugador
    SELECT max_lives INTO max_lives_value
    FROM players
    WHERE id = p_player_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jugador no encontrado';
    END IF;

    -- Resetear vidas
    UPDATE players
    SET lives = max_lives_value
    WHERE id = p_player_id;

    -- Registrar evento
    INSERT INTO life_events (player_id, admin_id, delta, reason)
    VALUES (p_player_id, auth.uid(), max_lives_value, 'Reset individual');
END;
$$;


-- FUNCIÓN: Resetear vidas de TODOS los jugadores
CREATE OR REPLACE FUNCTION admin_reset_lives_all()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar que el usuario es admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    -- Resetear todos los jugadores
    UPDATE players
    SET lives = max_lives;

    -- Registrar eventos para cada jugador
    INSERT INTO life_events (player_id, admin_id, delta, reason)
    SELECT id, auth.uid(), max_lives, 'Reset global'
    FROM players;
END;
$$;


-- ==================== DATOS INICIALES (OPCIONAL) ====================
-- Puedes descomentar esto para crear jugadores de prueba:

-- INSERT INTO players (nickname, lives) VALUES
--     ('PLAYER_01', 12),
--     ('PLAYER_02', 8),
--     ('PLAYER_03', 5),
--     ('PLAYER_04', 12);


-- ==================== NOTAS IMPORTANTES ====================
/*
DESPUÉS DE EJECUTAR ESTE SCRIPT:

1. Crear el primer usuario admin:
   - Ve a Authentication > Users en Supabase
   - Crea un nuevo usuario con email y password
   - Luego ejecuta esto en SQL Editor:
   
   UPDATE profiles 
   SET is_admin = true 
   WHERE email = 'tu-email-admin@example.com';

2. Configurar Realtime (opcional):
   - Ve a Database > Replication
   - Habilita "Realtime" para la tabla "players"
   - Esto permite actualizaciones en tiempo real en el panel público

3. Variables de entorno:
   - VITE_SUPABASE_URL: tu URL de proyecto
   - VITE_SUPABASE_ANON_KEY: tu clave anon pública
*/
