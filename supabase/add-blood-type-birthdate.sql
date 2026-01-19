ALTER TABLE IF EXISTS profiles
ADD COLUMN IF NOT EXISTS blood_type VARCHAR(3),
ADD COLUMN IF NOT EXISTS birth_date DATE;

-- Crear índice para búsquedas por tipo de sangre (opcional)
CREATE INDEX IF NOT EXISTS idx_profiles_blood_type ON profiles(blood_type);
