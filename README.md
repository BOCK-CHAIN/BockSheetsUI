# BockSheets - Flutter Spreadsheet Application

A modern, collaborative spreadsheet application built with Flutter and Supabase.

## Features

- ✅ User authentication (Email/Password & Google OAuth)
- ✅ Real-time collaboration
- ✅ Formula support (SUM, AVERAGE, MIN, MAX, COUNT, IF)
- ✅ Array formulas (ARRAYSUM, ARRAYMULTIPLY, etc.)
- ✅ Cell formatting (bold, italic, underline, colors, alignment)
- ✅ Import/Export (CSV, XLSX)
- ✅ Undo/Redo functionality
- ✅ Auto-save
- ✅ Trash/Restore spreadsheets
- ✅ Multi-cell selection

## Tech Stack

- **Frontend**: Flutter 3.9.2+
- **Backend**: Supabase (PostgreSQL + Realtime)
- **State Management**: Provider
- **Authentication**: Supabase Auth

## Setup Instructions

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- Supabase account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/owner-username/frontend-repo.git
cd frontend-repo
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create `.env` file in the root:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

4. Run the app:
```bash
flutter run
```

## Project Structure
```
lib/
├── config/          # App configuration (theme, Supabase)
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic & API calls
└── widgets/         # Reusable widgets
```

## Environment Variables

Create a `.env` file with:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anonymous key

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## License

[Add license information]