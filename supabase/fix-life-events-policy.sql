DROP POLICY IF EXISTS "Solo admin puede ver eventos" ON public.life_events;
DROP POLICY IF EXISTS "Lectura pública de eventos" ON public.life_events;

CREATE POLICY "Lectura pública de eventos"
    ON public.life_events FOR SELECT
    TO anon, authenticated
    USING (true);
