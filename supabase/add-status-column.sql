-- Agregar columna status a la tabla profiles
-- Esta columna almacenará un JSON con el estado del usuario y su color

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS status JSONB DEFAULT '{"status": "Sin estado", "color": "#00ffc2"}'::jsonb;

-- Agregar comentario descriptivo
COMMENT ON COLUMN public.profiles.status IS 'Estado personalizable del usuario con formato: {"status": "texto", "color": "#hexadecimal"}';
