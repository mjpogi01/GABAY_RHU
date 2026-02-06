-- Add one pre-test question per module (up to 8 modules).
-- Each question references its module so wrong answers assign that module.
-- Run once; ON CONFLICT skips if question id already exists.

INSERT INTO questions (
  id,
  type,
  question,
  options,
  correct_answer,
  domain,
  "pairedId",
  explanation,
  "referenceModuleId",
  order_index
)
SELECT
  'pre_seed_' || m.id,
  'pre_test',
  'How would you rate your current knowledge about: ' || m.title || '?',
  '["I am confident", "I know a little", "I am not sure", "I need to learn this"]'::jsonb,
  'I am confident',
  COALESCE(m.domain, 'general'),
  'pre_seed_' || m.id,
  'This question helps tailor your learning path.',
  m.id,
  m.order_index
FROM (
  SELECT id, title, domain, order_index
  FROM modules
  ORDER BY order_index
  LIMIT 8
) m
ON CONFLICT (id) DO NOTHING;
