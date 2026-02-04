-- ============================================================================
-- GABAY - Remote admin editing of modules
-- Adds domain, cards_json, cover_image_url; RLS for admin CRUD; Storage bucket
-- ============================================================================

-- Add columns to modules for app model (id, title, domain, order_index, cards_json, cover_image_url)
ALTER TABLE modules ADD COLUMN IF NOT EXISTS domain TEXT NOT NULL DEFAULT 'general';
ALTER TABLE modules ADD COLUMN IF NOT EXISTS cards_json TEXT;
ALTER TABLE modules ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

-- Migrate existing rows: put content into a single card in cards_json
UPDATE modules
SET cards_json = json_build_array(
  json_build_object('id', 'card_1', 'content', COALESCE(content, ''), 'imagePath', NULL, 'order', 0)
)::text
WHERE cards_json IS NULL AND (content IS NOT NULL OR content = '');

-- Allow admins to insert, update, delete modules (all authenticated users can SELECT)
CREATE POLICY "Admins can insert modules" ON modules
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can update modules" ON modules
  FOR UPDATE TO authenticated
  USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can delete modules" ON modules
  FOR DELETE TO authenticated
  USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'admin');
