# Supabase Setup Guide

This guide explains how to configure Supabase for the MyTransit application, including authentication settings.

## Disabling Email Confirmation

By default, Supabase requires users to confirm their email address before they can sign in. To allow users to sign in immediately after registration (without email confirmation), you need to disable this setting in your Supabase dashboard.

### Steps to Disable Email Confirmation:

1. **Access Supabase Dashboard**
   - Log in to your Supabase account at [https://app.supabase.com](https://app.supabase.com)
   - Select your project

2. **Navigate to Authentication Settings**
   - In the left-hand menu, click on **Authentication**
   - Then, select **Providers**

3. **Disable Email Confirmation**
   - Under the **Email** section, find the **Confirm email** option
   - Toggle this option **OFF** to disable email confirmations

4. **Save Changes**
   - The changes are saved automatically

### What Happens After Disabling Email Confirmation:

- Users can sign in immediately after registration
- No confirmation email is sent
- Users are automatically signed in after successful signup
- The app will handle the session automatically through the session manager

### Important Notes:

- **Security Consideration**: Disabling email confirmation means you won't verify that users own the email addresses they register with. This may be acceptable for development or certain use cases, but consider the security implications for production applications.

- **Code Behavior**: The app code is designed to handle both scenarios:
  - If email confirmation is **disabled**: Users are automatically signed in after signup
  - If email confirmation is **enabled**: Users receive a message to check their email for confirmation

## Environment Variables

Make sure you have the following environment variables set when running the app:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous/public key

These can be set via `--dart-define` flags when running Flutter:

```bash
flutter run --dart-define SUPABASE_URL=your_url --dart-define SUPABASE_ANON_KEY=your_key
```

## Troubleshooting

### Users Can't Sign In After Registration

If users are created in the database but can't sign in:

1. Check if email confirmation is enabled in Supabase dashboard
2. If enabled, either:
   - Disable it following the steps above, OR
   - Have users check their email and click the confirmation link
3. Verify that the session manager is properly initialized (check app logs)

### Session Not Persisting

If users need to log in again after app restarts:

1. Ensure the session manager is properly initialized in `main.dart`
2. Check that Supabase is properly configured with environment variables
3. Verify that secure storage is working on your platform

