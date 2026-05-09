# Kanzi App - MVP Design Specification

## 1. Overview

A challenge-based social mobile app where users join rooms via codes, complete daily challenges, vote on submissions, and compete on leaderboards.

**Tech Stack:**
- Frontend: Flutter (Android & iOS)
- Backend: Supabase (Auth, PostgreSQL, Storage, Realtime)
- State Management: Riverpod (recommended for Supabase integration)

---

## 2. App Flow & Screen List

### 2.1 Authentication Flow
```
┌─────────────────┐
│  Splash Screen  │
└────────┬────────┘
         │
    ┌────▼────┐
    │ Auth?   │
    └─┬────┬──┘
  No  │    │ Yes
      │    │
┌─────▼─┐  │
│ Login │  │
│Screen │  │
└───┬───┘  │
    │      │
    └──┬───┘
       │
┌──────▼──────┐
│  Home Flow  │
└─────────────┘
```

### 2.2 Main Application Flow
```
Home Screen (Room List)
    │
    ├─> Create Room → Room Details
    │
    ├─> Join Room (via code) → Room Details
    │
    └─> Select Existing Room → Room Details
            │
            ├─> Today's Challenge
            │       │
            │       ├─> Submit Entry
            │       │       └─> Camera/Gallery/Text Input → Preview → Confirm
            │       │
            │       └─> View Submissions
            │               └─> Vote on Entry
            │
            ├─> Leaderboard (Daily)
            │
            └─> Room Settings (admin only)
                    └─> Manage Members, Edit Room
```

### 2.3 Screen List (Flutter Pages)

#### **Unauthenticated Screens**
1. **SplashScreen** (`/`)
   - App logo, checks auth state
   
2. **LoginScreen** (`/login`)
   - Email/Password input
   - Sign In / Sign Up toggle
   - "Forgot Password" link (optional)

#### **Authenticated Screens**
3. **HomeScreen** (`/home`)
   - List of joined rooms (card view)
   - Floating action button: "Create Room" / "Join Room"
   - Each room card shows:
     - Room name
     - Today's challenge preview
     - Unread submissions badge
     - Daily winner badge (if yesterday's winner is from this room)

4. **CreateRoomScreen** (`/create-room`)
   - Room name input
   - Room description (optional)
   - Auto-generate unique room code
   - "Create" button

5. **JoinRoomScreen** (`/join-room`)
   - Room code input (6-digit alphanumeric)
   - "Join" button
   - Display room info before confirming join

6. **RoomDetailsScreen** (`/room/:roomId`)
   - Tab-based layout:
     - **Challenge Tab** (default)
     - **Leaderboard Tab**
     - **Members Tab** (optional for MVP)
   - App bar actions: Room settings (if admin), Leave room

7. **ChallengeFeedScreen** (within RoomDetailsScreen - Challenge Tab)
   - Today's challenge text at top
   - Countdown timer (time left for submissions/voting)
   - User's own submission card (if submitted)
   - List of other submissions (cards with image/text + vote button)
   - Floating action button: "Submit Entry" (if not yet submitted)

8. **SubmitChallengeScreen** (`/room/:roomId/submit`)
   - Challenge prompt display
   - Input options based on challenge type:
     - Photo: Camera + Gallery button
     - Text: Text field
     - Photo + Text: Both
   - Image preview
   - "Submit" button

9. **SubmissionDetailScreen** (`/room/:roomId/submission/:submissionId`)
   - Full-screen image (if photo)
   - Text content
   - Author name
   - Vote button (disabled if own submission or already voted)
   - Current vote count

10. **LeaderboardScreen** (within RoomDetailsScreen - Leaderboard Tab)
    - Daily leaderboard for current room
    - Ranked list:
      - Position number
      - User avatar + name
      - Total votes for today
      - Crown icon for #1
    - Filter: Today / Yesterday

11. **RoomSettingsScreen** (`/room/:roomId/settings`) - Admin only
    - Edit room name/description
    - View room code
    - Delete room (confirmation dialog)
    - Manage members (optional: remove users)

12. **ProfileScreen** (`/profile`) - Optional for MVP
    - User info
    - Stats: Total rooms, wins, submissions
    - Logout button

---

## 3. Database Schema

### 3.1 Tables

#### **users** (managed by Supabase Auth, extended via table)
```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### **rooms**
```sql
CREATE TABLE public.rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  code TEXT UNIQUE NOT NULL, -- 6-char alphanumeric
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_rooms_code ON public.rooms(code);
CREATE INDEX idx_rooms_created_by ON public.rooms(created_by);
```

#### **room_members**
```sql
CREATE TABLE public.room_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member', -- 'admin' or 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);

CREATE INDEX idx_room_members_room_id ON public.room_members(room_id);
CREATE INDEX idx_room_members_user_id ON public.room_members(user_id);
```

#### **challenges**
```sql
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  challenge_text TEXT NOT NULL,
  challenge_type TEXT NOT NULL, -- 'photo', 'text', 'photo_text'
  challenge_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(room_id, challenge_date)
);

CREATE INDEX idx_challenges_room_date ON public.challenges(room_id, challenge_date);
```

#### **submissions**
```sql
CREATE TABLE public.submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  image_url TEXT, -- Supabase Storage URL
  text_content TEXT,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

CREATE INDEX idx_submissions_challenge_id ON public.submissions(challenge_id);
CREATE INDEX idx_submissions_user_id ON public.submissions(user_id);
CREATE INDEX idx_submissions_room_id ON public.submissions(room_id);
```

#### **votes**
```sql
CREATE TABLE public.votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID NOT NULL REFERENCES public.submissions(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  vote_value INTEGER NOT NULL DEFAULT 1, -- 1 for upvote (or 1-5 for rating)
  voted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(submission_id, voter_id)
);

CREATE INDEX idx_votes_submission_id ON public.votes(submission_id);
CREATE INDEX idx_votes_voter_id ON public.votes(voter_id);
```

### 3.2 Database Views (for efficiency)

#### **leaderboard_view**
```sql
CREATE VIEW public.leaderboard_view AS
SELECT 
  s.room_id,
  s.user_id,
  c.challenge_date,
  COUNT(v.id) AS total_votes,
  RANK() OVER (
    PARTITION BY s.room_id, c.challenge_date 
    ORDER BY COUNT(v.id) DESC
  ) AS rank
FROM public.submissions s
JOIN public.challenges c ON s.challenge_id = c.id
LEFT JOIN public.votes v ON s.id = v.submission_id
GROUP BY s.room_id, s.user_id, c.challenge_date, s.id;
```

### 3.3 Database Functions

#### **Generate unique room code**
```sql
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude confusing chars
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;
```

#### **Auto-create daily challenges (via cron or Edge Function)**
```sql
CREATE OR REPLACE FUNCTION create_daily_challenges()
RETURNS void AS $$
DECLARE
  room RECORD;
  challenge_pool TEXT[] := ARRAY[
    'Take the most cringe photo today.',
    'Take a photo with the youngest person you saw today.',
    'Share the most meaningful proverb you know.',
    'Capture the most beautiful sunset.',
    'Show us your weirdest possession.'
  ];
  random_challenge TEXT;
BEGIN
  FOR room IN SELECT id FROM public.rooms LOOP
    random_challenge := challenge_pool[floor(random() * array_length(challenge_pool, 1) + 1)];
    
    INSERT INTO public.challenges (room_id, challenge_text, challenge_type, challenge_date)
    VALUES (room.id, random_challenge, 'photo_text', CURRENT_DATE)
    ON CONFLICT (room_id, challenge_date) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

---

## 4. Row Level Security (RLS) Policies

### 4.1 Enable RLS on All Tables
```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;
```

### 4.2 Profiles Policies
```sql
-- Users can view all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);
```

### 4.3 Rooms Policies
```sql
-- Users can view rooms they are members of
CREATE POLICY "Users can view their rooms"
  ON public.rooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = rooms.id
        AND room_members.user_id = auth.uid()
    )
  );

-- Any authenticated user can create a room
CREATE POLICY "Authenticated users can create rooms"
  ON public.rooms FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Only room admin can update room
CREATE POLICY "Room admins can update their rooms"
  ON public.rooms FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = rooms.id
        AND room_members.user_id = auth.uid()
        AND room_members.role = 'admin'
    )
  );

-- Only room admin can delete room
CREATE POLICY "Room admins can delete their rooms"
  ON public.rooms FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = rooms.id
        AND room_members.user_id = auth.uid()
        AND room_members.role = 'admin'
    )
  );
```

### 4.4 Room Members Policies
```sql
-- Users can view members of rooms they belong to
CREATE POLICY "Users can view members of their rooms"
  ON public.room_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id
        AND rm.user_id = auth.uid()
    )
  );

-- Users can join a room (via code verification in app logic)
CREATE POLICY "Users can join rooms"
  ON public.room_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Only admins can update member roles
CREATE POLICY "Admins can update member roles"
  ON public.room_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id
        AND rm.user_id = auth.uid()
        AND rm.role = 'admin'
    )
  );

-- Users can leave rooms OR admins can remove members
CREATE POLICY "Users can leave or admins can remove members"
  ON public.room_members FOR DELETE
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.room_members rm
      WHERE rm.room_id = room_members.room_id
        AND rm.user_id = auth.uid()
        AND rm.role = 'admin'
    )
  );
```

### 4.5 Challenges Policies
```sql
-- Users can view challenges for rooms they are members of
CREATE POLICY "Users can view challenges in their rooms"
  ON public.challenges FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = challenges.room_id
        AND room_members.user_id = auth.uid()
    )
  );

-- Only system/admins can create challenges (handled via service_role key)
-- No INSERT policy for regular users
```

### 4.6 Submissions Policies
```sql
-- Users can view submissions in rooms they are members of
CREATE POLICY "Users can view submissions in their rooms"
  ON public.submissions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.room_members
      WHERE room_members.room_id = submissions.room_id
        AND room_members.user_id = auth.uid()
    )
  );

-- Users can create their own submissions
CREATE POLICY "Users can create their own submissions"
  ON public.submissions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own submissions (optional: before voting starts)
CREATE POLICY "Users can update their own submissions"
  ON public.submissions FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own submissions
CREATE POLICY "Users can delete their own submissions"
  ON public.submissions FOR DELETE
  USING (auth.uid() = user_id);
```

### 4.7 Votes Policies
```sql
-- Users can view votes on submissions in their rooms
CREATE POLICY "Users can view votes in their rooms"
  ON public.votes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.submissions s
      JOIN public.room_members rm ON s.room_id = rm.room_id
      WHERE s.id = votes.submission_id
        AND rm.user_id = auth.uid()
    )
  );

-- Users can vote on submissions (cannot vote on own submissions - enforced in app)
CREATE POLICY "Users can vote on submissions"
  ON public.votes FOR INSERT
  WITH CHECK (
    auth.uid() = voter_id AND
    NOT EXISTS (
      SELECT 1 FROM public.submissions
      WHERE submissions.id = votes.submission_id
        AND submissions.user_id = auth.uid()
    )
  );

-- Users can update their own votes (change vote value)
CREATE POLICY "Users can update their own votes"
  ON public.votes FOR UPDATE
  USING (auth.uid() = voter_id);

-- Users can delete their own votes (unvote)
CREATE POLICY "Users can delete their own votes"
  ON public.votes FOR DELETE
  USING (auth.uid() = voter_id);
```

---

## 5. Flutter Architecture

### 5.1 State Management: Riverpod

**Why Riverpod?**
- Native async support (perfect for Supabase)
- Built-in dependency injection
- Type-safe
- Great for realtime streams
- Testable

### 5.2 Folder Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── supabase_constants.dart
│   ├── router/
│   │   └── app_router.dart (go_router)
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── utils/
│       ├── extensions.dart
│       └── validators.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   └── login_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_form.dart
│   │   └── domain/
│   │       └── entities/
│   │           └── user.dart
│   │
│   ├── rooms/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── room_repository.dart
│   │   │   └── models/
│   │   │       ├── room_model.dart
│   │   │       └── room_member_model.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── room_list_provider.dart
│   │   │   │   └── room_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart
│   │   │   │   ├── create_room_screen.dart
│   │   │   │   ├── join_room_screen.dart
│   │   │   │   ├── room_details_screen.dart
│   │   │   │   └── room_settings_screen.dart
│   │   │   └── widgets/
│   │   │       ├── room_card.dart
│   │   │       └── room_code_input.dart
│   │   └── domain/
│   │       └── entities/
│   │           └── room.dart
│   │
│   ├── challenges/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── challenge_repository.dart
│   │   │   └── models/
│   │   │       ├── challenge_model.dart
│   │   │       └── submission_model.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── challenge_provider.dart
│   │   │   │   └── submission_provider.dart
│   │   │   ├── screens/
│   │   │   │   ├── challenge_feed_screen.dart
│   │   │   │   ├── submit_challenge_screen.dart
│   │   │   │   └── submission_detail_screen.dart
│   │   │   └── widgets/
│   │   │       ├── challenge_card.dart
│   │   │       ├── submission_card.dart
│   │   │       └── countdown_timer.dart
│   │   └── domain/
│   │       └── entities/
│   │           ├── challenge.dart
│   │           └── submission.dart
│   │
│   ├── voting/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── vote_repository.dart
│   │   │   └── models/
│   │   │       └── vote_model.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── vote_provider.dart
│   │   │   └── widgets/
│   │   │       └── vote_button.dart
│   │   └── domain/
│   │       └── entities/
│   │           └── vote.dart
│   │
│   └── leaderboard/
│       ├── data/
│       │   ├── repositories/
│       │   │   └── leaderboard_repository.dart
│       │   └── models/
│       │       └── leaderboard_entry_model.dart
│       ├── presentation/
│       │   ├── providers/
│       │   │   └── leaderboard_provider.dart
│       │   ├── screens/
│       │   │   └── leaderboard_screen.dart
│       │   └── widgets/
│       │       └── leaderboard_item.dart
│       └── domain/
│           └── entities/
│               └── leaderboard_entry.dart
│
└── shared/
    ├── providers/
    │   └── supabase_provider.dart
    └── widgets/
        ├── loading_indicator.dart
        ├── error_widget.dart
        └── image_picker_widget.dart
```

### 5.3 Key Architectural Patterns

#### **Repository Pattern**
Each feature has a repository that handles data operations:
```dart
abstract class RoomRepository {
  Future<List<Room>> getUserRooms(String userId);
  Future<Room> createRoom(String name, String description, String userId);
  Future<Room> joinRoom(String roomCode, String userId);
  Future<void> leaveRoom(String roomId, String userId);
  Stream<List<Room>> watchUserRooms(String userId);
}
```

#### **Provider Structure**
```dart
// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repository provider
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RoomRepositoryImpl(supabase);
});

// State provider
final roomListProvider = StreamProvider.autoDispose<List<Room>>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repository.watchUserRooms(user.id);
});
```

#### **Navigation: GoRouter**
```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isAuthRoute = state.location == '/login';
      
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
      GoRoute(path: '/create-room', builder: (context, state) => CreateRoomScreen()),
      GoRoute(path: '/join-room', builder: (context, state) => JoinRoomScreen()),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailsScreen(roomId: roomId);
        },
      ),
      // ... more routes
    ],
  );
});
```

---

## 6. Supabase Integration Flow

### 6.1 Authentication

#### **Setup (main.dart)**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(ProviderScope(child: MyApp()));
}
```

#### **Auth Repository**
```dart
class AuthRepository {
  final SupabaseClient _client;
  
  AuthRepository(this._client);
  
  Future<User?> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }
  
  Future<User?> signUpWithEmail(String email, String password, String username) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    
    // Create profile
    if (response.user != null) {
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'display_name': username,
      });
    }
    
    return response.user;
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
```

### 6.2 Database Operations

#### **Example: Room Repository**
```dart
class RoomRepositoryImpl implements RoomRepository {
  final SupabaseClient _client;
  
  RoomRepositoryImpl(this._client);
  
  @override
  Future<List<Room>> getUserRooms(String userId) async {
    final response = await _client
      .from('room_members')
      .select('*, rooms(*)')
      .eq('user_id', userId);
    
    return (response as List)
      .map((json) => Room.fromJson(json['rooms']))
      .toList();
  }
  
  @override
  Future<Room> createRoom(String name, String description, String userId) async {
    // Generate room code
    final code = _generateRoomCode();
    
    // Create room
    final roomData = await _client.from('rooms').insert({
      'name': name,
      'description': description,
      'code': code,
      'created_by': userId,
    }).select().single();
    
    // Add creator as admin
    await _client.from('room_members').insert({
      'room_id': roomData['id'],
      'user_id': userId,
      'role': 'admin',
    });
    
    return Room.fromJson(roomData);
  }
  
  @override
  Future<Room> joinRoom(String roomCode, String userId) async {
    // Find room by code
    final roomData = await _client
      .from('rooms')
      .select()
      .eq('code', roomCode)
      .single();
    
    // Add user as member
    await _client.from('room_members').insert({
      'room_id': roomData['id'],
      'user_id': userId,
      'role': 'member',
    });
    
    return Room.fromJson(roomData);
  }
  
  @override
  Stream<List<Room>> watchUserRooms(String userId) {
    return _client
      .from('room_members')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((json) => Room.fromJson(json['rooms'])).toList());
  }
  
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
```

### 6.3 Storage (Image Uploads)

#### **Image Upload Flow**
```dart
class StorageService {
  final SupabaseClient _client;
  
  StorageService(this._client);
  
  Future<String> uploadSubmissionImage(
    String userId,
    String submissionId,
    File imageFile,
  ) async {
    final fileName = '$submissionId-${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'submissions/$userId/$fileName';
    
    await _client.storage.from('challenge-images').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: false,
      ),
    );
    
    final publicUrl = _client.storage.from('challenge-images').getPublicUrl(path);
    return publicUrl;
  }
  
  Future<void> deleteSubmissionImage(String imageUrl) async {
    // Extract path from URL
    final uri = Uri.parse(imageUrl);
    final path = uri.pathSegments.sublist(5).join('/'); // Skip /storage/v1/object/public/bucket-name/
    
    await _client.storage.from('challenge-images').remove([path]);
  }
}
```

**Storage Bucket Setup:**
- Create bucket: `challenge-images`
- Public: Yes (for easy image viewing)
- File size limit: 5MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

### 6.4 Realtime Subscriptions

#### **Listen to New Submissions**
```dart
class SubmissionProvider extends StateNotifier<AsyncValue<List<Submission>>> {
  final SupabaseClient _client;
  final String roomId;
  StreamSubscription? _subscription;
  
  SubmissionProvider(this._client, this.roomId) : super(AsyncValue.loading()) {
    _init();
  }
  
  void _init() async {
    // Initial fetch
    await _fetchSubmissions();
    
    // Subscribe to realtime changes
    _subscription = _client
      .from('submissions:room_id=eq.$roomId')
      .on(SupabaseEventTypes.insert, (payload) {
        _handleNewSubmission(payload.newRecord);
      })
      .subscribe();
  }
  
  Future<void> _fetchSubmissions() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final data = await _client
        .from('submissions')
        .select('*, profiles(*), challenges!inner(*)')
        .eq('room_id', roomId)
        .eq('challenges.challenge_date', today)
        .order('submitted_at', ascending: false);
      
      final submissions = (data as List)
        .map((json) => Submission.fromJson(json))
        .toList();
      
      state = AsyncValue.data(submissions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void _handleNewSubmission(Map<String, dynamic> newRecord) {
    state.whenData((submissions) {
      final newSubmission = Submission.fromJson(newRecord);
      state = AsyncValue.data([newSubmission, ...submissions]);
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## 7. Implementation Notes

### 7.1 Daily Challenge Generation

**Option 1: Supabase Edge Function + Cron**
```typescript
// supabase/functions/generate-daily-challenges/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const challengePool = [
  { text: 'Take the most cringe photo today.', type: 'photo' },
  { text: 'Take a photo with the youngest person you saw today.', type: 'photo' },
  { text: 'Share the most meaningful proverb you know.', type: 'text' },
  { text: 'Capture your lunch and describe why you chose it.', type: 'photo_text' },
];

serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  // Get all rooms
  const { data: rooms } = await supabaseClient.from('rooms').select('id');

  const today = new Date().toISOString().split('T')[0];

  // Create challenge for each room
  for (const room of rooms) {
    const randomChallenge = challengePool[Math.floor(Math.random() * challengePool.length)];
    
    await supabaseClient.from('challenges').insert({
      room_id: room.id,
      challenge_text: randomChallenge.text,
      challenge_type: randomChallenge.type,
      challenge_date: today,
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

**Cron Schedule:** Daily at 00:00 UTC
```bash
# In Supabase Dashboard > Edge Functions > Cron Jobs
0 0 * * * generate-daily-challenges
```

**Option 2: Flutter App (Lazy Loading)**
- When user opens a room, check if today's challenge exists
- If not, generate one (requires service_role key, less secure)

**Recommendation:** Use Edge Function + Cron for production.

### 7.2 Voting System Decision

**Option A: Simple Upvote (1 point per vote)**
- **Pros:** Simple, fast, clear winner
- **Cons:** No nuance, ties are common

**Option B: 1-5 Rating System**
- **Pros:** More nuanced feedback, fewer ties
- **Cons:** Users may hesitate to give low ratings, slower voting

**MVP Recommendation: Simple Upvote (Option A)**
- Easier to implement and test
- Faster user interaction
- Can upgrade to rating system later based on feedback

### 7.3 Winner Calculation

**Daily Winner Logic:**
```dart
Future<LeaderboardEntry?> getDailyWinner(String roomId, DateTime date) async {
  final dateStr = date.toIso8601String().split('T')[0];
  
  final data = await _client
    .rpc('get_daily_leaderboard', params: {
      'p_room_id': roomId,
      'p_date': dateStr,
    })
    .limit(1)
    .single();
  
  return LeaderboardEntry.fromJson(data);
}
```

**Database Function:**
```sql
CREATE OR REPLACE FUNCTION get_daily_leaderboard(p_room_id UUID, p_date DATE)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  total_votes BIGINT,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS user_id,
    p.username,
    p.avatar_url,
    COUNT(v.id) AS total_votes,
    RANK() OVER (ORDER BY COUNT(v.id) DESC) AS rank
  FROM submissions s
  JOIN challenges c ON s.challenge_id = c.id
  JOIN profiles p ON s.user_id = p.id
  LEFT JOIN votes v ON s.id = v.submission_id
  WHERE s.room_id = p_room_id
    AND c.challenge_date = p_date
  GROUP BY p.id, p.username, p.avatar_url
  ORDER BY total_votes DESC;
END;
$$ LANGUAGE plpgsql;
```

### 7.4 Image Optimization

**Client-Side (Flutter):**
```dart
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

Future<File> compressImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) throw Exception('Failed to decode image');
  
  // Resize to max 1080px width while maintaining aspect ratio
  final resized = img.copyResize(image, width: 1080);
  
  // Compress to JPEG with 85% quality
  final compressed = img.encodeJpg(resized, quality: 85);
  
  // Write to temp file
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await tempFile.writeAsBytes(compressed);
  
  return tempFile;
}
```

### 7.5 Error Handling

**Global Error Handler:**
```dart
class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    } else if (error is StorageException) {
      return 'Failed to upload image. Please try again.';
    }
    return 'An unexpected error occurred.';
  }
}

// Usage in provider
try {
  await repository.createRoom(name, description, userId);
} catch (e) {
  final message = ErrorHandler.getErrorMessage(e);
  // Show snackbar or dialog
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

### 7.6 Testing Strategy

**Unit Tests:**
- Repository methods
- Model serialization/deserialization
- Business logic (e.g., vote validation)

**Widget Tests:**
- Individual screens
- Form validation
- Navigation

**Integration Tests:**
- Auth flow
- Room creation and joining
- Submission and voting flow

**Example Test:**
```dart
void main() {
  group('RoomRepository', () {
    late MockSupabaseClient mockClient;
    late RoomRepository repository;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      repository = RoomRepositoryImpl(mockClient);
    });
    
    test('createRoom should return Room with generated code', () async {
      when(mockClient.from('rooms').insert(any))
        .thenAnswer((_) async => {'id': 'uuid', 'code': 'ABC123', ...});
      
      final room = await repository.createRoom('Test Room', '', 'user-id');
      
      expect(room.code, hasLength(6));
      expect(room.name, 'Test Room');
    });
  });
}
```

---

## 8. MVP Launch Checklist

### 8.1 Supabase Setup
- [ ] Create Supabase project
- [ ] Set up authentication (email/password)
- [ ] Create all database tables
- [ ] Enable RLS on all tables
- [ ] Create RLS policies
- [ ] Create database functions (room code generator, leaderboard)
- [ ] Create storage bucket (`challenge-images`)
- [ ] Set up Edge Function for daily challenges
- [ ] Configure cron job

### 8.2 Flutter Setup
- [ ] Initialize Flutter project
- [ ] Install dependencies:
  - `supabase_flutter`
  - `flutter_riverpod`
  - `go_router`
  - `image_picker`
  - `cached_network_image`
- [ ] Set up folder structure
- [ ] Implement Supabase providers
- [ ] Create theme and constants

### 8.3 Feature Implementation
- [ ] Auth: Login/Signup screens
- [ ] Rooms: Create, Join, List
- [ ] Challenges: View today's challenge
- [ ] Submissions: Submit photo/text
- [ ] Voting: Upvote submissions
- [ ] Leaderboard: View daily rankings
- [ ] Room settings: Edit room, leave room

### 8.4 Testing
- [ ] Unit tests for repositories
- [ ] Widget tests for screens
- [ ] Integration tests for critical flows
- [ ] Manual testing on Android
- [ ] Manual testing on iOS

### 8.5 Deployment
- [ ] Generate app icons
- [ ] Configure app name and bundle ID
- [ ] Build APK/AAB for Android
- [ ] Build IPA for iOS
- [ ] Deploy to Play Store (beta)
- [ ] Deploy to TestFlight (beta)

---

## 9. Key Dependencies

```yaml
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

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.6
```

---

## 10. Future Enhancements (Post-MVP)

*Not part of MVP, but documented for future reference:*

- Push notifications for new challenges
- User profiles with statistics
- Room themes/customization
- Private rooms (invite-only)
- Challenge history
- Weekly/monthly leaderboards
- User badges and achievements
- Social sharing of submissions
- Admin dashboard for challenge management
- Multi-language support

---

## Conclusion

This MVP design provides a complete, working specification for a gamified social challenge app. The architecture is simple, scalable, and follows Flutter best practices. Supabase handles all backend complexity with RLS ensuring data security.

**Estimated Development Time:** 4-6 weeks for a single developer

**Core Features Delivered:**
✅ Room creation and joining via codes  
✅ Daily challenges per room  
✅ Photo/text submissions  
✅ Simple voting system  
✅ Daily leaderboards  
✅ Winner highlighting  

**Next Steps:**
1. Set up Supabase project
2. Initialize Flutter app
3. Implement features in order: Auth → Rooms → Challenges → Submissions → Voting → Leaderboard
4. Test thoroughly
5. Deploy to beta testers
