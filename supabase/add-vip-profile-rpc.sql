-- Expose a public VIP profile (display_name + avatar_url) without leaking admin email.
-- This function intentionally returns only public fields.

CREATE OR REPLACE FUNCTION public.get_vip_profile()
RETURNS TABLE (
  display_name TEXT,
  avatar_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    COALESCE(NULLIF(p.display_name, ''), 'VIP') AS display_name,
    NULLIF(p.avatar_url, '') AS avatar_url
  FROM public.profiles p
  WHERE p.is_admin = true
  ORDER BY p.updated_at DESC NULLS LAST, p.created_at DESC
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_vip_profile() TO anon;
GRANT EXECUTE ON FUNCTION public.get_vip_profile() TO authenticated;
