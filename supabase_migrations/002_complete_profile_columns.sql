-- Migration: Add Complete Your Profile columns to users table
-- Run this if your users table already exists (e.g. from an earlier schema)
-- Registration flow: Create Account -> Complete Your Profile -> OTP

ALTER TABLE users ADD COLUMN IF NOT EXISTS consent_given INTEGER DEFAULT 1;
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS number_of_children INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS id_number TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_infant BOOLEAN;
