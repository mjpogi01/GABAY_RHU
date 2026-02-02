-- GABAY Database Schema for Supabase
-- Run this SQL in your Supabase SQL editor to set up the database

-- Enable Row Level Security

-- Users table (extends Supabase auth.users)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  anonymized_id TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL DEFAULT 'parent',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Profile fields (add if table already exists: use ALTER TABLE)
  first_name TEXT,
  last_name TEXT,
  phone_number TEXT,
  address TEXT,
  status TEXT,
  number_of_children INTEGER,
  has_infant BOOLEAN
);

-- If users table already exists, run this migration:
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number TEXT;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS number_of_children INTEGER;
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS has_infant BOOLEAN;

-- Children table
CREATE TABLE children (
  id TEXT PRIMARY KEY,
  caregiver_id UUID REFERENCES users(id) NOT NULL,
  date_of_birth DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences table
CREATE TABLE user_preferences (
  user_id UUID REFERENCES users(id) PRIMARY KEY,
  current_child_id TEXT REFERENCES children(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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

-- Module assignments table
CREATE TABLE module_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  child_id TEXT REFERENCES children(id) NOT NULL,
  module_id TEXT REFERENCES modules(id) NOT NULL,
  assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, child_id, module_id)
);

-- Module progress table
CREATE TABLE module_progress (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  child_id TEXT REFERENCES children(id) NOT NULL,
  module_id TEXT REFERENCES modules(id) NOT NULL,
  progress_percentage REAL DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  last_accessed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, child_id, module_id)
);

-- Questions table
CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL, -- 'pre_test' or 'post_test'
  question TEXT NOT NULL,
  options JSONB, -- For multiple choice questions
  correct_answer TEXT,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assessment results table
CREATE TABLE assessment_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) NOT NULL,
  child_id TEXT REFERENCES children(id) NOT NULL,
  type TEXT NOT NULL, -- 'pre_test' or 'post_test'
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  answers JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can only see their own data
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own data" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own children" ON children FOR SELECT USING (auth.uid() = caregiver_id);
CREATE POLICY "Users can insert own children" ON children FOR INSERT WITH CHECK (auth.uid() = caregiver_id);
CREATE POLICY "Users can update own children" ON children FOR UPDATE USING (auth.uid() = caregiver_id);

CREATE POLICY "Users can view own preferences" ON user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own preferences" ON user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON user_preferences FOR UPDATE USING (auth.uid() = user_id);

-- Modules are public
CREATE POLICY "Modules are viewable by all authenticated users" ON modules FOR SELECT TO authenticated USING (true);

-- Module assignments are user-specific
CREATE POLICY "Users can view own module assignments" ON module_assignments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module assignments" ON module_assignments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module assignments" ON module_assignments FOR UPDATE USING (auth.uid() = user_id);

-- Module progress is user-specific
CREATE POLICY "Users can view own module progress" ON module_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module progress" ON module_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module progress" ON module_progress FOR UPDATE USING (auth.uid() = user_id);

-- Questions are public for authenticated users
CREATE POLICY "Questions are viewable by authenticated users" ON questions FOR SELECT TO authenticated USING (true);

-- Assessment results are user-specific
CREATE POLICY "Users can view own assessment results" ON assessment_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own assessment results" ON assessment_results FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Insert sample data
INSERT INTO modules (id, title, description, content, order_index) VALUES
('module_1', 'Introduction to Infant Care', 'Basic care for newborns', 'Content for module 1', 1),
('module_2', 'Nutrition and Feeding', 'Proper feeding practices', 'Content for module 2', 2),
('module_3', 'Health and Safety', 'Keeping your baby safe', 'Content for module 3', 3);

INSERT INTO questions (id, type, question, options, correct_answer, order_index) VALUES
('pre_q1', 'pre_test', 'What is the recommended age for starting solid foods?', '["4 months", "6 months", "12 months"]', '6 months', 1),
('pre_q2', 'pre_test', 'How often should you bathe a newborn?', '["Daily", "Every other day", "Weekly"]', 'Every other day', 2),
('post_q1', 'post_test', 'What is the main benefit of breastfeeding?', '["Convenience", "Bonding and nutrition", "Cost savings"]', 'Bonding and nutrition', 1),
('post_q2', 'post_test', 'When should you call a doctor for a fever in infants?', '["Above 100°F", "Above 101°F", "Above 102°F"]', 'Above 101°F', 2);
