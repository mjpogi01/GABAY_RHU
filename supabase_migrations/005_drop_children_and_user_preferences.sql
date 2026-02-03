-- Migration 005: Remove children and user_preferences; drop child_id from other tables.
-- Run after 004. Preserves data in module_assignments, module_progress, assessment_results.
-- Order: drop policies → drop FKs / columns → drop children and user_preferences.

-- =============================================================================
-- 1. Drop RLS policies on tables we will alter (so we can change them)
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own module assignments" ON module_assignments;
DROP POLICY IF EXISTS "Users can insert own module assignments" ON module_assignments;
DROP POLICY IF EXISTS "Users can update own module assignments" ON module_assignments;
DROP POLICY IF EXISTS "Users can view own module progress" ON module_progress;
DROP POLICY IF EXISTS "Users can insert own module progress" ON module_progress;
DROP POLICY IF EXISTS "Users can update own module progress" ON module_progress;
DROP POLICY IF EXISTS "Users can view own assessment results" ON assessment_results;
DROP POLICY IF EXISTS "Users can insert own assessment results" ON assessment_results;

-- =============================================================================
-- 2. Drop foreign key constraints that reference children (so we can drop children)
-- =============================================================================
ALTER TABLE module_assignments DROP CONSTRAINT IF EXISTS module_assignments_child_id_fkey;
ALTER TABLE module_progress   DROP CONSTRAINT IF EXISTS module_progress_child_id_fkey;
ALTER TABLE assessment_results DROP CONSTRAINT IF EXISTS assessment_results_child_id_fkey;

-- =============================================================================
-- 3. Drop children and user_preferences (and their policies first)
-- =============================================================================
DROP POLICY IF EXISTS "Users can view own children" ON children;
DROP POLICY IF EXISTS "Users can insert own children" ON children;
DROP POLICY IF EXISTS "Users can update own children" ON children;
DROP POLICY IF EXISTS "Users can view own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can insert own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can update own preferences" ON user_preferences;
DROP TABLE IF EXISTS user_preferences;
DROP TABLE IF EXISTS children;

-- =============================================================================
-- 4. Drop child_id column and fix unique constraints (keeps existing data)
-- =============================================================================
-- module_assignments: drop old unique, drop column, add new unique
ALTER TABLE module_assignments DROP CONSTRAINT IF EXISTS module_assignments_user_id_child_id_module_id_key;
ALTER TABLE module_assignments DROP COLUMN IF EXISTS child_id;
ALTER TABLE module_assignments ADD CONSTRAINT module_assignments_user_id_module_id_key UNIQUE (user_id, module_id);

-- module_progress: drop old unique, drop column, add new unique
ALTER TABLE module_progress DROP CONSTRAINT IF EXISTS module_progress_user_id_child_id_module_id_key;
ALTER TABLE module_progress DROP COLUMN IF EXISTS child_id;
ALTER TABLE module_progress ADD CONSTRAINT module_progress_user_id_module_id_key UNIQUE (user_id, module_id);

-- assessment_results: drop column only (no unique on child_id)
ALTER TABLE assessment_results DROP COLUMN IF EXISTS child_id;

-- =============================================================================
-- 5. Re-enable RLS and recreate policies
-- =============================================================================
ALTER TABLE module_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own module assignments" ON module_assignments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module assignments" ON module_assignments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module assignments" ON module_assignments FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own module progress" ON module_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module progress" ON module_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module progress" ON module_progress FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own assessment results" ON assessment_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own assessment results" ON assessment_results FOR INSERT WITH CHECK (auth.uid() = user_id);
