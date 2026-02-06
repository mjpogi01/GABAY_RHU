-- Add domain and reference-module columns to questions (required by app)
-- Run this in Supabase SQL Editor if your questions table was created without these columns.

ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS domain TEXT DEFAULT 'general';

ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS "pairedId" TEXT;

ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS explanation TEXT;

ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS "referenceModuleId" TEXT;

-- Backfill domain for existing rows
UPDATE questions SET domain = 'general' WHERE domain IS NULL;
