-- Align assessment_results with app (AssessmentResultModel) so results save and load correctly.
-- App uses: id (e.g. pre_<uuid>), userId, type, domainScores, domainTotals, totalCorrect, totalQuestions, completedAt, responses.

-- Allow TEXT id (app uses 'pre_<user_id>' and 'post_<user_id>')
ALTER TABLE assessment_results
  ALTER COLUMN id DROP DEFAULT;
ALTER TABLE assessment_results
  ALTER COLUMN id TYPE TEXT USING id::text;

-- Add columns the app expects (snake_case for Postgres)
ALTER TABLE assessment_results
  ADD COLUMN IF NOT EXISTS domain_scores JSONB DEFAULT '{}';

ALTER TABLE assessment_results
  ADD COLUMN IF NOT EXISTS domain_totals JSONB DEFAULT '{}';

ALTER TABLE assessment_results
  ADD COLUMN IF NOT EXISTS total_correct INTEGER;

ALTER TABLE assessment_results
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE assessment_results
  ADD COLUMN IF NOT EXISTS responses JSONB DEFAULT '[]';

-- Backfill from existing columns so old rows still work
UPDATE assessment_results
SET total_correct = score,
    completed_at = created_at,
    responses  = COALESCE(answers, '[]'::jsonb)
WHERE total_correct IS NULL;

-- Allow users to update own assessment results (needed for upsert)
CREATE POLICY "Users can update own assessment results" ON assessment_results
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);
