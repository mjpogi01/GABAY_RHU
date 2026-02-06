-- Ensure order_index has a default so inserts/upserts without it don't violate NOT NULL
ALTER TABLE questions
  ALTER COLUMN order_index SET DEFAULT 0;
