-- ============================================
-- FIX: Team Messages - Relación con Profiles
-- ============================================
-- Este script corrige la relación de clave foránea
-- para que Supabase pueda hacer JOIN con profiles
-- ============================================

-- Paso 1: Eliminar la constraint existente si existe
ALTER TABLE public.team_messages 
DROP CONSTRAINT IF EXISTS team_messages_created_by_fkey;

-- Paso 2: Agregar la nueva constraint que apunta a profiles
ALTER TABLE public.team_messages
ADD CONSTRAINT team_messages_created_by_fkey
FOREIGN KEY (created_by) 
REFERENCES public.profiles(id) 
ON DELETE SET NULL;

-- Paso 3: Crear índice para mejorar rendimiento en JOINs
CREATE INDEX IF NOT EXISTS idx_team_messages_created_by_profiles 
ON public.team_messages(created_by);

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Puedes ejecutar esto para verificar que funciona:
/*
SELECT 
  tm.*,
  p.display_name,
  p.email
FROM public.team_messages tm
LEFT JOIN public.profiles p ON tm.created_by = p.id
LIMIT 5;
*/
