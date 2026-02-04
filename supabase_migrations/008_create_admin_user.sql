-- Create an admin user in public.users (role = 'admin').
-- Run from Supabase SQL Editor after creating the auth user in Dashboard.
-- Requires: auth user already exists (Authentication → Add user).

CREATE OR REPLACE FUNCTION create_admin_user(
  p_user_id UUID,
  p_anonymized_id TEXT DEFAULT 'admin-001'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    id,
    anonymized_id,
    role,
    created_at,
    consent_given
  ) VALUES (
    p_user_id,
    p_anonymized_id,
    'admin',
    NOW(),
    1
  )
  ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    anonymized_id = EXCLUDED.anonymized_id;
END;
$$;

-- Only allow execution by service role / postgres (e.g. from SQL Editor or Edge Function).
-- Do not grant to authenticated or anon.
COMMENT ON FUNCTION create_admin_user(UUID, TEXT) IS
  'Inserts or updates public.users with role=admin. Call from SQL Editor after creating auth user in Dashboard.';
