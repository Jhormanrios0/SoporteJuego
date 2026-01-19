-- ============================================
-- ENABLE READ ACCESS FOR AUTHENTICATED USERS
-- ============================================

-- Permitir que cualquier usuario logueado (authenticated) pueda LEER los mensajes
-- Esto es necesario para que los jugadores vean el historial en el panel lateral

CREATE POLICY "Authenticated users can read team messages"
ON public.team_messages
FOR SELECT
USING (auth.role() = 'authenticated');

-- Nota: Las políticas de INSERT, UPDATE y DELETE siguen siendo solo para Admins
