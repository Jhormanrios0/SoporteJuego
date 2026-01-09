-- ==================== FIX: POLÍTICAS RLS PARA LIFE_EVENTS ====================
-- Ejecutar este script en el SQL Editor de Supabase
-- Esto permite que TODOS puedan leer los eventos (necesario para notificaciones)
-- ==============================================================================

-- Eliminar la política restrictiva anterior
DROP POLICY IF EXISTS "Solo admin puede ver eventos" ON life_events;

-- Crear nueva política: Lectura pública de eventos
CREATE POLICY "Lectura pública de eventos"
    ON life_events FOR SELECT
    USING (true);  -- Cualquiera puede leer los eventos

-- La política de INSERT sigue igual (solo admin puede crear)
-- No necesitamos modificarla
