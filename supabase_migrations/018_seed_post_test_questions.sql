-- Seed one post-test question per existing pre-test question.
-- Post-test question pairedId = pre-test question id so the app can show the matching set.
-- Run once; ON CONFLICT skips if post-test id already exists.

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
  'post_' || substring(p.id from 5),
  'post_test',
  'After the course, how would you rate your knowledge about: ' || COALESCE(m.title, 'this topic') || '?',
  p.options,
  p.correct_answer,
  COALESCE(p.domain, 'general'),
  p.id,
  'Post-assessment for your learning progress.',
  p."referenceModuleId",
  p.order_index
FROM questions p
LEFT JOIN modules m ON m.id = p."referenceModuleId"
WHERE p.type = 'pre_test'
ON CONFLICT (id) DO NOTHING;
