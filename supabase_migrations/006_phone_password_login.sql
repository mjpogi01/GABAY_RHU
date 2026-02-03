-- Migration 006: Phone + password login (no OTP for login).
-- Adds users.password_hash and RPCs login_by_phone, set_user_password_by_phone.
-- Requires extension pgcrypto for password hashing.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Add password_hash to users if missing
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Normalize phone to E.164 (Philippines: 09171234567 -> +639171234567)
CREATE OR REPLACE FUNCTION normalize_phone_ph(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN trim(p) = '' THEN ''
    WHEN trim(p) ~ '^0' THEN '+63' || substring(trim(p) from 2)
    WHEN trim(p) !~ '^\+' THEN '+63' || trim(p)
    ELSE trim(p)
  END;
$$;

-- Returns user row if phone and password match; used by login-phone-password Edge Function.
CREATE OR REPLACE FUNCTION login_by_phone(p_phone text, p_password text)
RETURNS SETOF users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  norm_phone text;
BEGIN
  IF p_phone IS NULL OR p_password IS NULL OR trim(p_phone) = '' OR trim(p_password) = '' THEN
    RETURN;
  END IF;
  norm_phone := normalize_phone_ph(p_phone);
  RETURN QUERY
  SELECT u.*
  FROM users u
  WHERE normalize_phone_ph(u.phone_number) = norm_phone
    AND u.password_hash IS NOT NULL
    AND u.password_hash = crypt(p_password, u.password_hash)
  LIMIT 1;
END;
$$;

-- Sets password_hash for the user with the given phone (after registration / OTP).
CREATE OR REPLACE FUNCTION set_user_password_by_phone(p_phone text, p_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  norm_phone text;
BEGIN
  IF p_phone IS NULL OR p_password IS NULL OR trim(p_phone) = '' OR trim(p_password) = '' THEN
    RETURN;
  END IF;
  norm_phone := normalize_phone_ph(p_phone);
  UPDATE users
  SET password_hash = crypt(p_password, gen_salt('bf'))
  WHERE normalize_phone_ph(phone_number) = norm_phone;
END;
$$;
