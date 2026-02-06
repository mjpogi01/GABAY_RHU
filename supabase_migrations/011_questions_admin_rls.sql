-- Allow admins to insert, update, delete questions (authenticated users can already SELECT)
CREATE POLICY "Admins can insert questions" ON questions
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can update questions" ON questions
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can delete questions" ON questions
  FOR DELETE TO authenticated
  USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
