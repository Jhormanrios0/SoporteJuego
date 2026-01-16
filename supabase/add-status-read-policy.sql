-- Permitir lectura pública del campo status en profiles
-- Esto permite que cualquier usuario (autenticado o no) pueda ver el estado de otros jugadores

DROP POLICY IF EXISTS "Lectura pública del status en profiles" ON profiles;

CREATE POLICY "Lectura pública del status en profiles"
ON profiles
FOR SELECT
USING (true);

-- Nota: Esta política permite ver TODOS los campos de profiles públicamente
-- Si solo quieres exponer el campo status, considera crear una vista (view) en su lugar
