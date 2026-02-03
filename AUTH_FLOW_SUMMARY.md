# Simplified Auth Flow - Summary

## Overview
Rebuilt authentication system with a clean, simple approach:
- **Sign-up**: OTP verification → saves password_hash
- **Login**: Phone + Password (no OTP)

## Sign-Up Flow

1. User enters: Full Name, Phone Number, Password, Confirm Password
2. User completes profile (status, address, etc.)
3. **Send OTP** → `PhoneAuthService.sendOtp(phone)`
4. **Verify OTP** → `PhoneAuthService.verifyOtp(phone, otp)` 
   - Creates user in `auth.users`
   - Establishes session
5. **Save user profile** → `provider.setUser(user)`
6. **Save password hash** → `PhoneAuthService.savePasswordHash(phone, password)`
   - Uses RPC: `set_user_password_by_phone`
   - Stores SHA256 hash in `public.users.password_hash`

## Login Flow

1. User enters: Phone Number, Password
2. **Sign in** → `PhoneAuthService.signInWithPhonePassword(phone, password)`
   - Calls Edge Function: `login-phone-password`
   - Edge Function validates password_hash via RPC: `login_by_phone`
   - Returns session tokens
   - Sets session in Supabase client

## Database Functions

### `set_user_password_by_phone(p_phone text, p_password text)`
- Saves password hash using SHA256 (no extension needed)
- Uses PostgreSQL's built-in `digest()` function
- Updates `public.users.password_hash`

### `login_by_phone(p_phone text, p_password text)`
- Validates phone + password
- Returns user row if password_hash matches
- Used by login Edge Function

## Edge Functions

### `login-phone-password`
- Validates credentials via `login_by_phone` RPC
- Sets auth email/password if missing (lazy setup)
- Returns session tokens

## Files Changed

1. **`lib/services/phone_auth_service.dart`** - Simplified, clean API
2. **`lib/screens/auth/auth_screen.dart`** - Updated sign-up flow
3. **`supabase_migrations/007_simple_auth_sha256.sql`** - SHA256-based functions

## Setup Steps

1. Run migration: `007_simple_auth_sha256.sql` in Supabase SQL Editor
2. Deploy Edge Function: `supabase functions deploy login-phone-password`
3. Test sign-up and login flows

## Benefits

✅ No pgcrypto extension needed (uses built-in PostgreSQL functions)
✅ Simple, clean code
✅ No JWT gateway issues (RPC works with valid session)
✅ Password hash saved immediately on sign-up
✅ Login works with phone + password (no OTP needed)
