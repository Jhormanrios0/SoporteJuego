-- ============================================
-- MIGRATION: CREATE TEAM MESSAGES TABLE
-- ============================================
-- Descripción: Tabla para almacenar mensajes generales del admin al equipo
-- Autor: Sistema
-- Fecha: 2026-01-14
-- ============================================

-- Crear la tabla de mensajes del equipo
CREATE TABLE IF NOT EXISTS public.team_messages (
  id BIGSERIAL PRIMARY KEY,
  message TEXT NOT NULL,
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('normal', 'important', 'urgent')),
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_team_messages_created_at ON public.team_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_team_messages_priority ON public.team_messages(priority);
CREATE INDEX IF NOT EXISTS idx_team_messages_created_by ON public.team_messages(created_by);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.team_messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES
-- ============================================

-- Policy: Los administradores pueden leer TODOS los mensajes
CREATE POLICY "Admins can read all team messages"
ON public.team_messages
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.is_admin = true
  )
);

-- Policy: Los administradores pueden insertar mensajes
CREATE POLICY "Admins can create team messages"
ON public.team_messages
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.is_admin = true
  )
);

-- Policy: Los administradores pueden actualizar mensajes
CREATE POLICY "Admins can update team messages"
ON public.team_messages
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.is_admin = true
  )
);

-- Policy: Los administradores pueden eliminar mensajes
CREATE POLICY "Admins can delete team messages"
ON public.team_messages
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.is_admin = true
  )
);

-- Policy (OPCIONAL): Usuarios autenticados pueden leer mensajes
-- Descomenta esto si quieres que todos los usuarios puedan ver los mensajes
/*
CREATE POLICY "Authenticated users can read team messages"
ON public.team_messages
FOR SELECT
USING (auth.role() = 'authenticated');
*/

-- ============================================
-- TRIGGER: Actualizar updated_at automáticamente
-- ============================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger que actualiza updated_at en cada UPDATE
CREATE TRIGGER update_team_messages_updated_at
BEFORE UPDATE ON public.team_messages
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE public.team_messages IS 'Mensajes generales del equipo administrativo';
COMMENT ON COLUMN public.team_messages.message IS 'Contenido del mensaje';
COMMENT ON COLUMN public.team_messages.priority IS 'Prioridad del mensaje: normal, important, urgent';
COMMENT ON COLUMN public.team_messages.created_by IS 'UUID del usuario que creó el mensaje';
COMMENT ON COLUMN public.team_messages.created_at IS 'Fecha y hora de creación del mensaje';
COMMENT ON COLUMN public.team_messages.updated_at IS 'Fecha y hora de última actualización';
