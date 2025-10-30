# BockSheets Setup Guide

## Initial Setup

### 1. Supabase Setup

1. Create a new Supabase project at https://supabase.com
2. Run the database schema from the backend repository
3. Enable Realtime for the `cells` table
4. Configure OAuth providers (optional)

### 2. Flutter Environment

1. Install Flutter: https://flutter.dev/docs/get-started/install
2. Verify installation: `flutter doctor`
3. Clone this repository
4. Run `flutter pub get`

### 3. Configuration

1. Copy `.env.example` to `.env`
2. Fill in Supabase credentials
3. (Optional) Configure OAuth redirect URLs

### 4. Run Development Server
```bash
flutter run
```

## Deployment

### Android
1. Configure `android/app/build.gradle`
2. Set up signing keys
3. Build: `flutter build apk --release`

### iOS
1. Configure Xcode project
2. Set up provisioning profiles
3. Build: `flutter build ios --release`

### Web
1. Build: `flutter build web --release`
2. Deploy to hosting service (Firebase, Vercel, etc.)