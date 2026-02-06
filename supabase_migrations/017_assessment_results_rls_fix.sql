-- Fix RLS on assessment_results so users can read their own pre-test result.
-- Policies must use auth.uid() = user_id and TO authenticated so the JWT is used.

-- Drop existing policies (from 001 and 014)
DROP POLICY IF EXISTS "Users can view own assessment results" ON assessment_results;
DROP POLICY IF EXISTS "Users can insert own assessment results" ON assessment_results;
DROP POLICY IF EXISTS "Users can update own assessment results" ON assessment_results;

-- Recreate: only authenticated users, explicit auth.uid() = user_id
CREATE POLICY "Users can view own assessment results"
  ON assessment_results FOR SELECT TO authenticated
  USING (auth.uid() IS NOT NULL AND user_id = auth.uid());

CREATE POLICY "Users can insert own assessment results"
  ON assessment_results FOR INSERT TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());

CREATE POLICY "Users can update own assessment results"
  ON assessment_results FOR UPDATE TO authenticated
  USING (auth.uid() IS NOT NULL AND user_id = auth.uid())
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());
