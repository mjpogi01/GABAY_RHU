-- Migration 007: Set password_hash by user id (for set-auth-email-password Edge Function and Settings).
-- Ensures public.users.password_hash is set when Auth password is set, so login_by_phone works.
-- When called from client (authenticated user), only allows setting own password (auth.uid() = p_user_id).
-- When called from Edge Function (service role, auth.uid() null), allows setting any user's password.

CREATE OR REPLACE FUNCTION set_user_password_by_id(p_user_id uuid, p_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_user_id IS NULL OR p_password IS NULL OR trim(p_password) = '' THEN
    RETURN;
  END IF;
  -- Service role (auth.uid() null) can set any user; otherwise only own id
  IF auth.uid() IS NOT NULL AND auth.uid() != p_user_id THEN
    RETURN;
  END IF;
  UPDATE users
  SET password_hash = crypt(p_password, gen_salt('bf'))
  WHERE id = p_user_id;
END;
$$;
