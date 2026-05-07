# FitTrack Flutter App with Supabase Backend

This ZIP contains a complete Flutter app using Supabase as the backend.

## What the app includes

- Real signup
- Real signin
- Logout
- Profile page showing the signed-in user's name
- Feed activities stored in Supabase
- Routes stored in Supabase
- Challenges stored in Supabase
- Join challenge feature
- Record activity timer
- Save recorded timer activity to Supabase

## What you need to change

### 1. Replace Supabase URL and anon key

Open this file:

```text
lib/services/supabase_config.dart
```

Replace:

```dart
static const String supabaseUrl = 'PASTE_YOUR_SUPABASE_PROJECT_URL_HERE';
static const String supabaseAnonKey = 'PASTE_YOUR_SUPABASE_ANON_KEY_HERE';
```

With your own Supabase project values.

Find them in Supabase:

```text
Project Settings > API > Project URL
Project Settings > API > anon public key
```

## Supabase setup

### 2. Enable email authentication

In Supabase dashboard:

```text
Authentication > Providers > Email
```

Enable Email provider.

Important for easy testing:

```text
Authentication > Providers > Email > Confirm email
```

Turn **Confirm email OFF** while testing, otherwise new users may need to confirm email before logging in.

### 3. Create database tables

Open:

```text
supabase_setup.sql
```

Copy everything and run it in:

```text
Supabase Dashboard > SQL Editor > New query > Run
```

This creates:

```text
profiles
activities
routes
challenges
challenge_members
```

It also adds Row Level Security policies.

## Flutter setup

### 4. Create a new Flutter project

```bash
flutter create fittrack_app
cd fittrack_app
```

### 5. Copy files

Copy the ZIP contents into your project.

You can replace:

```text
lib/
pubspec.yaml
```

with the files from this ZIP.

### 6. Install packages

```bash
flutter pub get
```

### 7. Run

```bash
flutter run
```

## Notes

The app uses online Unsplash image URLs, so your emulator or phone needs internet access.

This is a real backend app, but it does not yet include:

- Real GPS location tracking
- Real map route drawing
- Image upload
- Likes/comments database
- Password reset

Those can be added later.