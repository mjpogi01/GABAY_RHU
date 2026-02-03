-- ============================================================================
-- GABAY - Database Reset Script
-- WARNING: This will delete ALL data and schema!
-- Run this only if you want to completely reset your database
-- ============================================================================

-- Disable RLS temporarily to allow dropping policies
ALTER TABLE IF EXISTS users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS modules DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS module_assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS module_progress DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS questions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assessment_results DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- DROP POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;

DROP POLICY IF EXISTS "Modules are viewable by all" ON modules;

DROP POLICY IF EXISTS "Users can view own module assignments" ON module_assignments;
DROP POLICY IF EXISTS "Users can insert own module assignments" ON module_assignments;
DROP POLICY IF EXISTS "Users can update own module assignments" ON module_assignments;

DROP POLICY IF EXISTS "Users can view own module progress" ON module_progress;
DROP POLICY IF EXISTS "Users can insert own module progress" ON module_progress;
DROP POLICY IF EXISTS "Users can update own module progress" ON module_progress;

DROP POLICY IF EXISTS "Questions are viewable by authenticated" ON questions;

DROP POLICY IF EXISTS "Users can view own assessment results" ON assessment_results;
DROP POLICY IF EXISTS "Users can insert own assessment results" ON assessment_results;

-- ============================================================================
-- DROP FUNCTIONS
-- ============================================================================

DROP FUNCTION IF EXISTS normalize_phone_ph(text);

-- ============================================================================
-- DROP TABLES (in reverse order of dependencies)
-- ============================================================================

DROP TABLE IF EXISTS assessment_results CASCADE;
DROP TABLE IF EXISTS module_progress CASCADE;
DROP TABLE IF EXISTS module_assignments CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- DROP EXTENSIONS (optional - uncomment if you want to remove pgcrypto too)
-- ============================================================================

-- DROP EXTENSION IF EXISTS pgcrypto CASCADE;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Uncomment to verify tables are dropped:
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
--   AND table_type = 'BASE TABLE'
-- ORDER BY table_name;
