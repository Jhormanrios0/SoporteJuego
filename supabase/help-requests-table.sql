-- Tabla para solicitudes de ayuda y mensajes entre jugadores
CREATE TABLE IF NOT EXISTS public.help_requests (
  id BIGSERIAL PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_player_id BIGINT REFERENCES public.players(id) ON DELETE SET NULL,
  target_player_id BIGINT REFERENCES public.players(id) ON DELETE SET NULL,
  message TEXT NOT NULL,
  type VARCHAR(20) NOT NULL DEFAULT 'general' CHECK (type IN ('specific', 'general', 'mention')),
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para consultas rápidas
CREATE INDEX IF NOT EXISTS idx_help_requests_sender ON public.help_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_help_requests_target ON public.help_requests(target_player_id);
CREATE INDEX IF NOT EXISTS idx_help_requests_type ON public.help_requests(type);
CREATE INDEX IF NOT EXISTS idx_help_requests_read ON public.help_requests(read);
CREATE INDEX IF NOT EXISTS idx_help_requests_created ON public.help_requests(created_at DESC);

-- Habilitar RLS
ALTER TABLE public.help_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Los usuarios pueden leer mensajes donde son el remitente o destinatario, o mensajes generales
CREATE POLICY "Users can read their own and general messages"
  ON public.help_requests
  FOR SELECT
  USING (
    auth.uid() = sender_id 
    OR target_player_id IN (SELECT id FROM public.players WHERE user_id = auth.uid())
    OR type = 'general'
  );

-- Policy: Los usuarios autenticados pueden enviar mensajes
CREATE POLICY "Authenticated users can send messages"
  ON public.help_requests
  FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Policy: Los usuarios pueden marcar como leídos los mensajes que reciben
CREATE POLICY "Users can update read status of received messages"
  ON public.help_requests
  FOR UPDATE
  USING (
    target_player_id IN (SELECT id FROM public.players WHERE user_id = auth.uid())
    OR (type = 'general' AND auth.uid() IS NOT NULL)
  )
  WITH CHECK (
    target_player_id IN (SELECT id FROM public.players WHERE user_id = auth.uid())
    OR (type = 'general' AND auth.uid() IS NOT NULL)
  );

-- Policy: Los usuarios pueden eliminar sus propios mensajes enviados
CREATE POLICY "Users can delete their own sent messages"
  ON public.help_requests
  FOR DELETE
  USING (auth.uid() = sender_id);

-- Habilitar realtime para la tabla
ALTER PUBLICATION supabase_realtime ADD TABLE public.help_requests;

-- Comentarios
COMMENT ON TABLE public.help_requests IS 'Tabla para solicitudes de ayuda y mensajes entre jugadores';
COMMENT ON COLUMN public.help_requests.type IS 'Tipo de mensaje: specific (a un jugador), general (a todos), mention (mención directa)';
