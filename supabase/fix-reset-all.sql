-- ==================== FIX: admin_reset_lives_all ====================
-- Ejecutar este script en el SQL Editor de Supabase
-- para corregir el error "UPDATE requires a WHERE clause"
-- ====================================================================

-- FUNCIÓN: Resetear vidas de TODOS los jugadores (CORREGIDA)
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

    -- Resetear todos los jugadores (con WHERE clause)
    UPDATE players
    SET lives = max_lives
    WHERE id IS NOT NULL;  -- Esta línea resuelve el error

    -- Registrar eventos para cada jugador
    INSERT INTO life_events (player_id, admin_id, delta, reason)
    SELECT id, auth.uid(), max_lives, 'Reset global'
    FROM players;
END;
$$;
