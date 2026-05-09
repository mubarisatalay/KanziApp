# Kanzi App - Quick Start Guide

## Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Supabase account (free tier is sufficient)
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio with Flutter extensions

---

## Step 1: Supabase Setup

### 1.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in project details:
   - Project name: `kanzi-app`
   - Database password: (save this securely)
   - Region: Choose closest to your target users
4. Wait for project to be provisioned (~2 minutes)

### 1.2 Execute Database Schema

1. In Supabase Dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy entire contents of `database_schema.sql`
4. Paste and click "Run"
5. Verify all tables created: Go to **Table Editor** and see:
   - profiles
   - rooms
   - room_members
   - challenges
   - submissions
   - votes

### 1.3 Set Up Storage

1. Go to **Storage** in Supabase Dashboard
2. Bucket `challenge-images` should already be created by the SQL script
3. If not, create it manually:
   - Name: `challenge-images`
   - Public: ✅ Yes
   - File size limit: 5MB
   - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

### 1.4 Set Up Edge Function (Daily Challenges)

1. Install Supabase CLI:
```bash
brew install supabase/tap/supabase  # macOS
# or
npm install -g supabase             # Cross-platform
```

2. Login to Supabase:
```bash
supabase login
```

3. Link your project:
```bash
supabase link --project-ref YOUR_PROJECT_REF
```
*(Find PROJECT_REF in Settings > General > Reference ID)*

4. Create Edge Function:
```bash
supabase functions new generate-daily-challenges
```

5. Replace contents of `supabase/functions/generate-daily-challenges/index.ts` with:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const challengePool = [
  { text: 'Take the most cringe photo today.', type: 'photo' },
  { text: 'Take a photo with the youngest person you saw today.', type: 'photo' },
  { text: 'Share the most meaningful proverb you know.', type: 'text' },
  { text: 'Capture the most beautiful sunset you see.', type: 'photo' },
  { text: 'Show us your weirdest possession.', type: 'photo' },
  { text: 'Take a photo of something that made you smile today.', type: 'photo' },
  { text: 'Share a childhood memory in one sentence.', type: 'text' },
  { text: 'Take a photo of your view right now.', type: 'photo' },
  { text: 'What is your biggest fear? Explain in one sentence.', type: 'text' },
  { text: 'Take a selfie with a stranger (with permission!).', type: 'photo' },
];

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get all rooms
    const { data: rooms, error: roomsError } = await supabaseClient
      .from('rooms')
      .select('id');

    if (roomsError) throw roomsError;

    const today = new Date().toISOString().split('T')[0];
    let created = 0;

    // Create challenge for each room
    for (const room of rooms || []) {
      const randomChallenge = challengePool[Math.floor(Math.random() * challengePool.length)];
      
      const { error } = await supabaseClient
        .from('challenges')
        .insert({
          room_id: room.id,
          challenge_text: randomChallenge.text,
          challenge_type: randomChallenge.type,
          challenge_date: today,
        });

      if (!error) created++;
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        created,
        total_rooms: rooms?.length || 0,
        date: today 
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
```

6. Deploy the function:
```bash
supabase functions deploy generate-daily-challenges
```

7. Set up cron job (in Supabase Dashboard):
   - Go to **Database** > **Cron**
   - Click "Create a new cron job"
   - Name: `Daily Challenge Generation`
   - Schedule: `0 0 * * *` (daily at midnight UTC)
   - Command: Call the Edge Function via HTTP trigger

### 1.5 Get API Keys

1. Go to **Settings** > **API**
2. Copy these values (you'll need them in Flutter):
   - Project URL (e.g., `https://xxxxx.supabase.co`)
   - `anon` `public` key

---

## Step 2: Flutter Project Setup

### 2.1 Initialize Flutter Project

```bash
cd /Users/barisatalay/Desktop/Flutter_Projects/kanziapp
flutter create .
```

### 2.2 Add Dependencies

Edit `pubspec.yaml`:

```yaml
name: kanziapp
description: A gamified social challenge app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Supabase
  supabase_flutter: ^2.0.0
  
  # Navigation
  go_router: ^12.0.0
  
  # Image Handling
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  image: ^4.1.3
  
  # UI
  flutter_svg: ^2.0.9
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.0.0
  path_provider: ^2.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.6
```

Run:
```bash
flutter pub get
```

### 2.3 Configure Supabase

Create `lib/core/constants/supabase_constants.dart`:

```dart
class SupabaseConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

⚠️ **Important:** Replace with your actual Supabase credentials from Step 1.5

### 2.4 Initialize Supabase in main.dart

Edit `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanzi App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Kanzi App - Ready to Build!'),
        ),
      ),
    );
  }
}
```

### 2.5 Test Supabase Connection

Run the app:
```bash
flutter run
```

If it builds successfully without errors, Supabase is configured correctly!

---

## Step 3: Implement Features (Recommended Order)

### Phase 1: Authentication (Week 1)
1. Create `features/auth/` folder structure
2. Implement `auth_repository.dart`
3. Create `auth_provider.dart` with Riverpod
4. Build `login_screen.dart` with email/password
5. Implement sign up flow
6. Add splash screen with auth state check

**Test:** Sign up, log out, log in

### Phase 2: Rooms (Week 2)
1. Create `features/rooms/` folder structure
2. Implement `room_repository.dart`
3. Build `home_screen.dart` (room list)
4. Build `create_room_screen.dart`
5. Build `join_room_screen.dart` (with room code input)
6. Implement `room_details_screen.dart` with tabs

**Test:** Create room, join room via code, view room list

### Phase 3: Challenges & Submissions (Week 3)
1. Create `features/challenges/` folder structure
2. Implement `challenge_repository.dart`
3. Build `challenge_feed_screen.dart`
4. Build `submit_challenge_screen.dart`
5. Integrate `image_picker` for photo uploads
6. Implement image upload to Supabase Storage
7. Display submissions in feed

**Test:** View today's challenge, submit photo/text, see submissions

### Phase 4: Voting & Leaderboard (Week 4)
1. Create `features/voting/` folder structure
2. Implement `vote_repository.dart`
3. Add vote button to submission cards
4. Prevent voting on own submissions
5. Create `features/leaderboard/` folder structure
6. Implement `leaderboard_repository.dart`
7. Build `leaderboard_screen.dart`
8. Highlight daily winner

**Test:** Vote on submissions, view leaderboard, verify winner calculation

### Phase 5: Polish & Testing (Week 5-6)
1. Add error handling
2. Add loading states
3. Implement realtime subscriptions for new submissions
4. Add room settings screen (admin only)
5. Write unit tests for repositories
6. Write widget tests for key screens
7. Manual testing on Android/iOS
8. Fix bugs

---

## Step 4: Run the App

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Web (for testing)
```bash
flutter run -d chrome
```

---

## Step 5: Build for Production

### Android (APK)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
flutter build ios --release
```
Then open Xcode and archive for App Store distribution.

---

## Troubleshooting

### Issue: "Supabase not initialized"
**Solution:** Make sure `Supabase.initialize()` is called before `runApp()` in `main.dart`

### Issue: "RLS policy violation"
**Solution:** Check that all RLS policies are correctly set up in Supabase. Re-run `database_schema.sql`

### Issue: "Image upload fails"
**Solution:** 
- Verify `challenge-images` bucket exists and is public
- Check storage policies in Supabase Dashboard
- Ensure image is compressed to < 5MB

### Issue: "No challenges appear"
**Solution:**
- Manually run Edge Function: `supabase functions invoke generate-daily-challenges`
- Check if rooms exist in database
- Verify cron job is set up correctly

### Issue: "Can't vote on submissions"
**Solution:** Check votes table RLS policy - ensure user is a member of the room

---

## Next Steps After MVP

Once your MVP is working:

1. **Gather Feedback:** Deploy to beta testers (TestFlight/Play Store Beta)
2. **Analytics:** Add Firebase Analytics or Posthog
3. **Push Notifications:** Implement for new challenges/winners
4. **Performance:** Optimize image loading with caching
5. **Features:** Add user profiles, challenge history, badges

---

## Support & Resources

- **Supabase Docs:** https://supabase.com/docs
- **Flutter Docs:** https://docs.flutter.dev
- **Riverpod Docs:** https://riverpod.dev

---

**Estimated Time:** 4-6 weeks for a solo developer  
**Difficulty:** Intermediate

Good luck building Kanzi App! 🚀
