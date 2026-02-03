-- Migration: Make children.date_of_birth nullable
-- Date of birth is not used by the app; making it optional.

ALTER TABLE children ALTER COLUMN date_of_birth DROP NOT NULL;
