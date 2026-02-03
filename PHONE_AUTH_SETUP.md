# GABAY - Phone Number Authentication Setup

## Prerequisites

1. **Supabase Project** – Create one at [supabase.com](https://supabase.com)
2. **Twilio Account** – For SMS delivery (Supabase uses Twilio for phone OTP)

## Step 1: Enable Phone Auth in Supabase

1. Go to your Supabase project → **Authentication** → **Providers**
2. Enable **Phone**
3. Configure **Twilio**:
   - Sign up at [twilio.com](https://twilio.com)
   - Get your **Account SID**, **Auth Token**, and **Twilio Phone Number**
   - Add these in Supabase: **Authentication** → **Providers** → **Phone** → **Twilio**

## Step 2: Run the Database Schema

1. In Supabase SQL Editor, run the contents of `supabase_schema.sql`
2. If you already have the `users` table, run the migration to add profile columns:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS number_of_children INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_infant BOOLEAN;
```

## Step 3: Configure the App

### Option A: Dart define (recommended)

```powershell
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### Option B: Create `lib/core/supabase_config.dart` with your keys

Replace the `defaultValue` in `supabase_config.dart`:

```dart
static const String url = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT.supabase.co',
);

static const String anonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your_anon_key_here',
);
```

**Note:** Do not commit real keys to git. Use `.env` or environment variables in production.

## Step 4: Phone Number Format

- Use Philippine format: `09171234567` or `+639171234567`
- The app auto-adds `+63` if you enter numbers starting with `0`

## Phone + Password Login (no synthetic email)

Auth uses **phone + password** only. Passwords are stored in `public.users.password_hash`; login is validated by the Edge Function.

### Database

Ensure these exist (add to your schema if not already present):

- `users.password_hash` (TEXT)
- RPC `login_by_phone(p_phone text, p_password text)` – returns user row if phone and password match (uses `pgcrypto` `crypt`).
- RPC `set_user_password_by_phone(p_phone text, p_password text)` – sets `password_hash` for the user.

### Edge Function `login-phone-password`

1. Deploy the function: `supabase functions deploy login-phone-password` (from the project root; requires Supabase CLI).
2. In **Supabase Dashboard** → **Edge Functions** → **Secrets**, add:
   - `SUPABASE_JWT_SECRET` = your project’s JWT Secret (**Settings** → **API** → **JWT Secret**).
3. The function accepts POST `{ "phone": "...", "password": "..." }`, calls `login_by_phone`, and returns `access_token` and `refresh_token` (custom JWT). The app uses these to set the session.

If login fails with “invalid refresh token”, the Dart client may be exchanging the token with GoTrue; ensure the Edge Function is deployed and `SUPABASE_JWT_SECRET` is set correctly.

## Flow

- **Sign In**: Enter phone + password → Edge Function validates → Session set → Signed in
- **Sign Up**: Enter phone → Complete profile → Send OTP → Verify → Password stored in `public.users` via `set_user_password_by_phone` → Create account
- **Demo Login**: Tap "Demo Login" to skip phone auth (uses local storage)

## When Supabase Is Not Configured

If `SUPABASE_URL` and `SUPABASE_ANON_KEY` are empty, the app falls back to:
- Demo login (local data)
- SQLite/Memory storage
- No phone OTP – use "Demo Login" to test
