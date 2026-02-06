-- Clear module progress and post-test results.
-- Run in Supabase SQL Editor when you want to reset progress and post-test for all users.

-- Remove all module completion/progress records
TRUNCATE TABLE module_progress;

-- Remove post-test results only (keeps pre-test results)
DELETE FROM assessment_results
WHERE type = 'post_test';
