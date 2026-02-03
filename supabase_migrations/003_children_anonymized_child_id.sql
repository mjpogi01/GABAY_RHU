-- Migration: Add anonymized_child_id to children table
-- Fixes PostgrestException PGRST204 (column not in schema cache)
-- Run this if your children table was created without this column.

ALTER TABLE children ADD COLUMN IF NOT EXISTS anonymized_child_id TEXT;
