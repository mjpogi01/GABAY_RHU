-- ============================================================================
-- GABAY - Initial Database Schema
-- Complete setup from scratch: tables, extensions, functions, RLS, seed data
-- Pure OTP-based authentication (no passwords, no edge functions)
-- ============================================================================

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  anonymized_id TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'parent',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  consent_given INTEGER DEFAULT 1,
  first_name TEXT,
  last_name TEXT,
  phone_number TEXT,
  status TEXT,
  address TEXT,
  number_of_children INTEGER,
  id_number TEXT,
  has_infant BOOLEAN
);

-- Modules table
CREATE TABLE modules (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  content TEXT,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Module assignments (user only, no child)
CREATE TABLE module_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  module_id TEXT REFERENCES modules(id) NOT NULL,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, module_id)
);

-- Module progress (user only, no child)
CREATE TABLE module_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  module_id TEXT REFERENCES modules(id) NOT NULL,
  progress_percentage REAL DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, module_id)
);

-- Questions table
CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  question TEXT NOT NULL,
  options JSONB,
  correct_answer TEXT,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assessment results (user only, no child)
CREATE TABLE assessment_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  type TEXT NOT NULL,
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  answers JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Normalize phone to E.164 format (Philippines: 09171234567 -> +639171234567)
-- Helper function for consistent phone number formatting
CREATE OR REPLACE FUNCTION normalize_phone_ph(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN trim(p) = '' THEN ''
    WHEN trim(p) ~ '^0' THEN '+63' || substring(trim(p) from 2)
    WHEN trim(p) !~ '^\+' THEN '+63' || trim(p)
    ELSE trim(p)
  END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own data" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

-- Modules policies
CREATE POLICY "Modules are viewable by all" ON modules FOR SELECT TO authenticated USING (true);

-- Module assignments policies
CREATE POLICY "Users can view own module assignments" ON module_assignments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module assignments" ON module_assignments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module assignments" ON module_assignments FOR UPDATE USING (auth.uid() = user_id);

-- Module progress policies
CREATE POLICY "Users can view own module progress" ON module_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module progress" ON module_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module progress" ON module_progress FOR UPDATE USING (auth.uid() = user_id);

-- Questions policies
CREATE POLICY "Questions are viewable by authenticated" ON questions FOR SELECT TO authenticated USING (true);

-- Assessment results policies
CREATE POLICY "Users can view own assessment results" ON assessment_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own assessment results" ON assessment_results FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION normalize_phone_ph(text) TO authenticated;

-- No seed data: modules and questions are added by admins or via app.
