-- ==================== AGREGAR MENSAJES DE MUERTE DE MINECRAFT ====================
-- Ejecutar este script en el SQL Editor de Supabase
-- Esto modifica la función admin_remove_lives para generar mensajes aleatorios de Minecraft
-- ====================================================================================

-- FUNCIÓN: Quitar vidas a un jugador CON MENSAJE DE MUERTE ALEATORIO
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
    player_nickname TEXT;
    death_message TEXT;
    death_messages TEXT[] := ARRAY[
        'fue explotado por un Creeper',
        'fue asesinado por un Esqueleto',
        'fue devorado por un Zombie',
        'cayó al vacío',
        'se quemó en lava',
        'fue asesinado por una Araña',
        'murió ahogado',
        'fue alcanzado por un rayo',
        'fue eliminado por un Enderman',
        'fue asesinado por un Blaze',
        'cayó de un lugar alto',
        'fue envenenado por una Araña de Cueva',
        'fue asesinado por un Piglin',
        'explotó por TNT',
        'fue golpeado por un Ghast',
        'fue asesinado por un Vindicator',
        'cayó en cactus',
        'murió por inanición',
        'fue congelado hasta morir',
        'fue atravesado por un Tridente',
        'fue eliminado por el Wither',
        'fue asesinado por un Evoker',
        'fue picado por una abeja',
        'cayó en polvo de nieve',
        'fue empalado por una Stalagmite',
        'fue asesinado por un Hoglin',
        'intentó nadar en lava',
        'descubrió que el piso era lava',
        'fue fulminado por magia',
        'fue golpeado hasta morir'
    ];
BEGIN
    -- Verificar que el usuario es admin
    IF NOT EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND is_admin = true
    ) THEN
        RAISE EXCEPTION 'No autorizado: solo admin puede ejecutar esta función';
    END IF;

    -- Obtener vidas actuales y nickname
    SELECT lives, nickname INTO current_lives, player_nickname
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

    -- Generar mensaje de muerte aleatorio (solo si se quitan vidas)
    IF p_amount > 0 THEN
        death_message := player_nickname || ' ' || death_messages[1 + floor(random() * array_length(death_messages, 1))::int];
    ELSE
        death_message := p_reason;
    END IF;

    -- Registrar evento con mensaje de muerte
    INSERT INTO life_events (player_id, admin_id, delta, reason)
    VALUES (p_player_id, auth.uid(), -p_amount, death_message);
END;
$$;
