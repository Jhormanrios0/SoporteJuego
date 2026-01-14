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
    SET lives = max_lives
    WHERE id IS NOT NULL;

    INSERT INTO life_events (player_id, admin_id, delta, reason)
    SELECT id, auth.uid(), max_lives, 'Reset global'
    FROM players;
END;
$$;
