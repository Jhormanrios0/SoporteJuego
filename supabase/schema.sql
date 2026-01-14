CREATE TABLE IF NOT EXISTS players (
    id BIGSERIAL PRIMARY KEY,
    nickname VARCHAR(30) UNIQUE NOT NULL,
    lives INTEGER NOT NULL DEFAULT 12 CHECK (lives >= 0 AND lives <= 12),
    max_lives INTEGER NOT NULL DEFAULT 12,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_players_nickname ON players(nickname);

CREATE INDEX IF NOT EXISTS idx_players_lives ON players(lives);


CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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


CREATE TABLE IF NOT EXISTS life_events (
    id BIGSERIAL PRIMARY KEY,
    player_id BIGINT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    delta INTEGER NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_life_events_player ON life_events(player_id);

CREATE INDEX IF NOT EXISTS idx_life_events_created ON life_events(created_at DESC);


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


ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE life_events ENABLE ROW LEVEL SECURITY;


CREATE POLICY "Lectura pública de players"
    ON players FOR SELECT
    USING (true);

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


CREATE POLICY "Usuarios pueden ver su perfil"
    ON profiles FOR SELECT
    USING (auth.uid() = id);


DROP POLICY IF EXISTS "Solo admin puede ver eventos" ON public.life_events;
DROP POLICY IF EXISTS "Lectura pública de eventos" ON public.life_events;

CREATE POLICY "Lectura pública de eventos"
    ON public.life_events FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Solo admin puede crear eventos"
    ON life_events FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.is_admin = true
        )
    );


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
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    SELECT lives INTO current_lives
    FROM players
    WHERE id = p_player_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jugador no encontrado';
    END IF;

    new_lives := GREATEST(current_lives - p_amount, 0);

    UPDATE players
    SET lives = new_lives
    WHERE id = p_player_id;

    INSERT INTO life_events (player_id, admin_id, delta, reason)
    VALUES (p_player_id, auth.uid(), -p_amount, p_reason);
END;
$$;

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
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    SELECT max_lives INTO max_lives_value
    FROM players
    WHERE id = p_player_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jugador no encontrado';
    END IF;

    UPDATE players
    SET lives = max_lives_value
    WHERE id = p_player_id;

    INSERT INTO life_events (player_id, admin_id, delta, reason)
    VALUES (p_player_id, auth.uid(), max_lives_value, 'Reset individual');
END;
$$;

CREATE OR REPLACE FUNCTION admin_reset_lives_all()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    UPDATE players
    SET lives = max_lives;

    INSERT INTO life_events (player_id, admin_id, delta, reason)
    SELECT id, auth.uid(), max_lives, 'Reset global'
    FROM players;
END;
$$;
