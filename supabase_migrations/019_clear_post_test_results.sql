-- Delete only post-test results (keeps pre-test results).
-- Run in Supabase SQL Editor when you need to let users retake the post-test.

DELETE FROM assessment_results
WHERE type = 'post_test';
