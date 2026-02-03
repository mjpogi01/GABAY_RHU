-- GABAY Database Schema for Supabase (users table only for auth/profile)
-- Registration: Create Account -> Complete Your Profile -> OTP -> Pre-test
-- Profile fields: status, address, number_of_children, id_number (optional).

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

-- RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own data" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Modules are viewable by all" ON modules FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can view own module assignments" ON module_assignments FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module assignments" ON module_assignments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module assignments" ON module_assignments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own module progress" ON module_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own module progress" ON module_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own module progress" ON module_progress FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Questions are viewable by authenticated" ON questions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can view own assessment results" ON assessment_results FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own assessment results" ON assessment_results FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Seed data
INSERT INTO modules (id, title, description, content, order_index) VALUES
('module_1', 'Introduction to Infant Care', 'Basic care for newborns', 'Content for module 1', 1),
('module_2', 'Nutrition and Feeding', 'Proper feeding practices', 'Content for module 2', 2),
('module_3', 'Health and Safety', 'Keeping your baby safe', 'Content for module 3', 3);

INSERT INTO questions (id, type, question, options, correct_answer, order_index) VALUES
('pre_q1', 'pre_test', 'What is the recommended age for starting solid foods?', '["4 months", "6 months", "12 months"]', '6 months', 1),
('pre_q2', 'pre_test', 'How often should you bathe a newborn?', '["Daily", "Every other day", "Weekly"]', 'Every other day', 2),
('post_q1', 'post_test', 'What is the main benefit of breastfeeding?', '["Convenience", "Bonding and nutrition", "Cost savings"]', 'Bonding and nutrition', 1),
('post_q2', 'post_test', 'When should you call a doctor for a fever in infants?', '["Above 100°F", "Above 101°F", "Above 102°F"]', 'Above 101°F', 2);
