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

## Flow

- **Sign In**: Enter phone → Send OTP → Enter 6-digit code → Verify → Signed in
- **Sign Up**: Enter phone → Send OTP → Verify → Enter profile (children, status, name, address) → Create account
- **Demo Login**: Tap "Demo Login" to skip phone auth (uses local storage)

## When Supabase Is Not Configured

If `SUPABASE_URL` and `SUPABASE_ANON_KEY` are empty, the app falls back to:
- Demo login (local data)
- SQLite/Memory storage
- No phone OTP – use "Demo Login" to test
