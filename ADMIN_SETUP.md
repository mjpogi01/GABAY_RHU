# Creating an admin account (GABAY)

Admin accounts use the same login as other users but have `role = 'admin'` in the database so the app can show admin-only features (e.g. via `user.isAdmin`).

## Steps

### 1. Create the auth user in Supabase

1. Open your project in [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **Authentication** → **Users** → **Add user** → **Create new user**.
3. Enter:
   - **Email**: e.g. `admin@gabay.local` or your chosen admin email.
   - **Password**: a strong password (and optionally **Auto Confirm User**).
4. Click **Create user**.

### 2. Get the user’s UUID

- In **Authentication** → **Users**, find the user you just created.
- Copy its **UUID** (e.g. `a1b2c3d4-e5f6-7890-abcd-ef1234567890`).

### 3. Add the admin row in the database

1. In Supabase, go to **SQL Editor**.
2. Run this (replace `YOUR_AUTH_USER_UUID` with the UUID from step 2):

```sql
SELECT create_admin_user('fbed3873-4a5f-48b5-a84b-83e86e000dd7'::uuid, 'admin-001');
```

Example:

```sql
SELECT create_admin_user('a1b2c3d4-e5f6-7890-abcd-ef1234567890'::uuid, 'admin-001');
```

This uses the migration function `create_admin_user` to insert (or update) a row in `public.users` with `role = 'admin'`.

### 4. Log in as admin

- In the app, sign in with the **email** and **password** you set in step 1.
- The app will load the user from `public.users` and `user.isAdmin` will be `true`.

---

## Remote editing of modules

When the app uses **Supabase** (configured in `lib/core/supabase_config.dart`), admins can edit modules remotely. Changes are stored in Supabase and all users see the updated content when they open the app.

1. **Run the modules migration**  
   In Supabase **SQL Editor**, run the script `supabase_migrations/009_modules_admin_and_storage.sql`. It adds `domain`, `cards_json`, and `cover_image_url` to the `modules` table and enables RLS so only admins can insert, update, or delete modules.

2. **Module images: Cloudinary (free tier)**  
   Cover images are uploaded to **Cloudinary** instead of Supabase Storage (which is paid). Set your Cloudinary credentials so the app can upload:
   - In [Cloudinary Dashboard](https://cloudinary.com/console): create an **unsigned upload preset** (Settings → Upload → Upload presets → Add preset → Signing Mode: **Unsigned**).
   - Run the app with:
     ```bash
     flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset_name
     ```
   - Or edit `lib/core/cloudinary_config.dart` and set `defaultValue` for `cloudName` and `uploadPreset` (do not commit API secrets; use env/dart-define in production).

3. **Admin flow**  
   Log in as admin → open **Modules (LMs)** → add or edit a module (title, rich text content, optional cover image). Saving uploads the cover image to Cloudinary and stores the module (with image URL) in Supabase. All clients load these modules from Supabase.

4. **Bundled vs remote**  
   - **SQLite / no Supabase:** Modules come from bundled assets (`assets/data/modules.json`) seeded on first run; admin edits in the app only affect the local device.  
   - **Supabase:** Modules are loaded from Supabase; admin edits affect everyone using that project.

---

**Note:** The app currently uses **phone + password** or **email + password** depending on your auth setup. If you use phone login, create the auth user with the desired phone number in Dashboard and use that account’s UUID in step 3.   
