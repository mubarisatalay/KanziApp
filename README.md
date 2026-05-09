# 🎮 Kanzi App

A gamified social challenge mobile application where users join rooms, complete daily challenges, vote on submissions, and compete on leaderboards.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Documentation](#-documentation)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

Kanzi is a social, challenge-based mobile app that brings friends together through daily creative challenges. Users can:
- **Join Rooms** via unique codes
- **Complete Daily Challenges** (photo/text/both)
- **Vote on Submissions** from other users
- **Compete on Leaderboards** to become the daily winner

Perfect for groups of friends, families, or communities looking to engage in fun, creative activities together!

---

## ✨ Features

### MVP Features (Phase 1)
- ✅ **User Authentication** - Email/password signup and login
- ✅ **Room Management** - Create rooms with unique codes, join existing rooms
- ✅ **Daily Challenges** - System-generated challenges for each room
- ✅ **Photo/Text Submissions** - Users can submit creative responses
- ✅ **Simple Voting** - Upvote submissions you like (1 vote = 1 point)
- ✅ **Daily Leaderboard** - See who's winning in your room
- ✅ **Winner Highlighting** - Daily winner displayed prominently
- ✅ **Real-time Updates** - Live submission feeds with Supabase Realtime

### Challenge Types
1. **Photo Challenge** - Submit a photo (e.g., "Take the most cringe photo today")
2. **Text Challenge** - Submit text (e.g., "Share the most meaningful proverb you know")
3. **Photo + Text** - Submit both (e.g., "Capture your lunch and describe why you chose it")

### User Roles
- **Admin** - Can create rooms, manage settings, moderate submissions
- **Member** - Can join rooms, submit challenges, vote on submissions

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** (3.0+) - Cross-platform mobile framework
- **Riverpod** (2.4+) - State management
- **GoRouter** (12.0+) - Navigation
- **Image Picker** - Camera/gallery access
- **Cached Network Image** - Efficient image loading

### Backend (Supabase)
- **Authentication** - Email/password (social auth optional)
- **PostgreSQL** - Relational database with RLS
- **Storage** - Image hosting (challenge submissions)
- **Edge Functions** - Daily challenge generation
- **Realtime** - Live updates for submissions

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Supabase account ([Sign up free](https://supabase.com))
- Android Studio / Xcode (for mobile development)

### Quick Setup (5 minutes)

#### 1. Clone & Install Dependencies
```bash
cd /Users/barisatalay/Desktop/Flutter_Projects/kanziapp
flutter pub get
```

#### 2. Set Up Supabase
1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run `database_schema.sql`
3. Copy your project URL and anon key from **Settings > API**

#### 3. Configure Flutter App
Create `lib/core/constants/supabase_constants.dart`:
```dart
class SupabaseConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

#### 4. Run the App
```bash
flutter run
```

For detailed setup instructions, see **[QUICKSTART.md](QUICKSTART.md)**

---

## 📚 Documentation

This project includes comprehensive documentation:

| Document | Description |
|----------|-------------|
| **[MVP_DESIGN.md](MVP_DESIGN.md)** | Complete product design specification |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Technical architecture & code examples |
| **[QUICKSTART.md](QUICKSTART.md)** | Step-by-step setup guide |
| **[database_schema.sql](database_schema.sql)** | Supabase database schema |

### Key Design Decisions

#### Why Riverpod?
- Native async support (perfect for Supabase streams)
- Type-safe and compile-time error checking
- Built-in dependency injection
- Easy testing with overrides

#### Why Simple Upvote vs Rating System?
For MVP, we chose **1 vote = 1 point** because:
- Faster user interaction (one tap)
- Clearer winner determination
- Less decision fatigue for users
- Can upgrade to 1-5 rating later based on feedback

#### Why Row Level Security (RLS)?
- Users can only see data from rooms they've joined
- Prevents data leaks between rooms
- No middleware needed - security at database level
- Supabase enforces policies automatically

---

## 📁 Project Structure

```
kanziapp/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Root widget with router
│   │
│   ├── core/                        # Core utilities
│   │   ├── constants/               # App constants, Supabase config
│   │   ├── router/                  # GoRouter configuration
│   │   ├── theme/                   # App theme & colors
│   │   └── utils/                   # Helper functions
│   │
│   ├── features/                    # Feature modules
│   │   ├── auth/                    # Authentication
│   │   │   ├── data/                # Repositories, models
│   │   │   ├── domain/              # Entities
│   │   │   └── presentation/        # Screens, widgets, providers
│   │   │
│   │   ├── rooms/                   # Room management
│   │   ├── challenges/              # Challenge & submissions
│   │   ├── voting/                  # Voting system
│   │   └── leaderboard/             # Leaderboards
│   │
│   └── shared/                      # Shared components
│       ├── providers/               # Global providers
│       └── widgets/                 # Reusable widgets
│
├── test/                            # Unit & widget tests
├── integration_test/                # Integration tests
│
├── database_schema.sql              # Supabase schema
├── MVP_DESIGN.md                    # Design specification
├── ARCHITECTURE.md                  # Architecture guide
├── QUICKSTART.md                    # Setup guide
└── README.md                        # This file
```

---

## 🎨 App Flow

```
┌─────────────┐
│   Splash    │
└──────┬──────┘
       │
   ┌───▼───┐
   │ Login │
   └───┬───┘
       │
┌──────▼──────┐
│  Home       │  ← List of joined rooms
│  (Rooms)    │
└──┬────┬────┘
   │    │
   │    └──────────┐
   │               │
┌──▼──────┐   ┌───▼────────┐
│ Create  │   │ Join Room  │
│ Room    │   │ (via code) │
└─────────┘   └────────────┘
                    │
              ┌─────▼──────┐
              │   Room     │
              │  Details   │
              └─┬─────┬────┘
                │     │
     ┌──────────┘     └─────────┐
     │                          │
┌────▼─────┐           ┌────────▼────┐
│ Today's  │           │ Leaderboard │
│Challenge │           └─────────────┘
└────┬─────┘
     │
┌────▼─────────┐
│   Submit     │
│ (Photo/Text) │
└──────────────┘
     │
┌────▼─────────┐
│ View & Vote  │
│ Submissions  │
└──────────────┘
```

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🔒 Security

- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Users can only access rooms they're members of
- ✅ Cannot vote on own submissions (enforced by RLS)
- ✅ Images stored in public bucket (read-only via URL)
- ✅ Client uses `anon` key (service role never exposed)

---

## 🚢 Deployment

### Android
```bash
# Build APK for testing
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
# Build for App Store
flutter build ios --release
```

Then open in Xcode and archive for distribution.

---

## 📈 Roadmap

### Phase 1 - MVP (Current)
- [x] Design specification
- [x] Database schema
- [x] Architecture documentation
- [ ] Implement authentication
- [ ] Implement rooms
- [ ] Implement challenges & submissions
- [ ] Implement voting & leaderboard
- [ ] Testing & bug fixes

### Phase 2 - Enhancements (Future)
- [ ] Push notifications for new challenges
- [ ] User profiles with stats
- [ ] Challenge history
- [ ] Weekly/monthly leaderboards
- [ ] User badges & achievements
- [ ] Private rooms (invite-only)
- [ ] Social sharing

### Phase 3 - Scaling (Future)
- [ ] Admin dashboard
- [ ] Custom challenge creation
- [ ] In-app messaging
- [ ] Multi-language support
- [ ] Analytics & insights

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Run `flutter analyze` before committing
- Write tests for new features
- Update documentation as needed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing cross-platform framework
- **Supabase Team** - For the open-source Firebase alternative
- **Riverpod** - For state management made simple
- **Community** - For all the open-source packages used in this project

---

## 📞 Support

- **Documentation:** See docs in this repository
- **Issues:** [GitHub Issues](https://github.com/yourusername/kanziapp/issues)
- **Supabase Docs:** [supabase.com/docs](https://supabase.com/docs)
- **Flutter Docs:** [docs.flutter.dev](https://docs.flutter.dev)

---

## 📊 Project Stats

- **Estimated Development Time:** 4-6 weeks (solo developer)
- **Target Platforms:** Android, iOS
- **Minimum SDK:** Android 21+, iOS 12+
- **Backend Cost:** Free (Supabase free tier sufficient for MVP)

---

## 🎉 Get Started Now!

Ready to build? Follow the **[Quick Start Guide](QUICKSTART.md)** to set up your development environment and start coding in under 10 minutes!

```bash
cd /Users/barisatalay/Desktop/Flutter_Projects/kanziapp
flutter pub get
flutter run
```

Happy coding! 🚀

---

**Made with ❤️ using Flutter & Supabase**
