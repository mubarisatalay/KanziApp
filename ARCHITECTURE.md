# Kanzi App - Architecture & Implementation Guide

## Architecture Overview

This document provides detailed implementation guidance for the Kanzi App MVP, including code examples, architectural patterns, and best practices.

---

## 1. Clean Architecture Layers

The app follows a feature-based Clean Architecture pattern:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (UI, Providers, Screens, Widgets)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Domain Layer                    │
│  (Entities, Use Cases - Optional MVP)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer                      │
│  (Repositories, Models, Data Sources)   │
└─────────────────────────────────────────┘
```

**Key Principles:**
- **Separation of Concerns:** Each layer has a single responsibility
- **Dependency Rule:** Dependencies point inward (Presentation → Domain → Data)
- **Testability:** Each layer can be tested independently
- **Scalability:** Easy to add new features without affecting existing code

---

## 2. State Management: Riverpod Deep Dive

### 2.1 Why Riverpod?

- ✅ Built-in async support (perfect for Supabase)
- ✅ Compile-time safety (no runtime errors)
- ✅ Automatic disposal (no memory leaks)
- ✅ Easy testing with overrides
- ✅ Native support for streams

### 2.2 Provider Types Used

| Provider Type | Use Case | Example |
|--------------|----------|---------|
| `Provider` | Immutable/singleton values | Supabase client, repositories |
| `StateProvider` | Simple mutable state | Selected tab, filters |
| `FutureProvider` | One-time async data fetch | Get user profile |
| `StreamProvider` | Real-time data streams | Room list updates |
| `StateNotifierProvider` | Complex mutable state | Auth state, form state |
| `ChangeNotifierProvider` | Legacy support (avoid) | N/A |

### 2.3 Provider Structure Example

```dart
// 1. Dependency Providers (Singletons)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

// 2. Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
});

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RoomRepositoryImpl(client);
});

// 3. State Providers (Authenticated User)
final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((event) => event.session?.user);
});

final currentUserProvider = Provider<User>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user ?? (throw Exception('Not authenticated')),
    loading: () => throw Exception('Loading'),
    error: (_, __) => throw Exception('Auth error'),
  );
});

// 4. Data Providers (Rooms)
final userRoomsProvider = StreamProvider.autoDispose<List<Room>>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repository.watchUserRooms(user.id);
});

// 5. Family Providers (Parameterized)
final roomProvider = FutureProvider.family<Room, String>((ref, roomId) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRoomById(roomId);
});

final todayChallengeProvider = FutureProvider.family.autoDispose<Challenge, String>(
  (ref, roomId) async {
    final repository = ref.watch(challengeRepositoryProvider);
    final today = DateTime.now();
    return repository.getTodayChallenge(roomId, today);
  },
);

// 6. Complex State with StateNotifier
class SubmissionState {
  final bool isSubmitting;
  final String? errorMessage;
  final Submission? submission;

  SubmissionState({
    this.isSubmitting = false,
    this.errorMessage,
    this.submission,
  });

  SubmissionState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    Submission? submission,
  }) {
    return SubmissionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      submission: submission ?? this.submission,
    );
  }
}

class SubmissionNotifier extends StateNotifier<SubmissionState> {
  final SubmissionRepository _repository;
  final StorageService _storage;

  SubmissionNotifier(this._repository, this._storage)
      : super(SubmissionState());

  Future<void> submitChallenge({
    required String challengeId,
    required String roomId,
    required String userId,
    File? imageFile,
    String? textContent,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storage.uploadSubmissionImage(
          userId,
          const Uuid().v4(),
          imageFile,
        );
      }

      final submission = await _repository.createSubmission(
        challengeId: challengeId,
        roomId: roomId,
        userId: userId,
        imageUrl: imageUrl,
        textContent: textContent,
      );

      state = state.copyWith(
        isSubmitting: false,
        submission: submission,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final submissionNotifierProvider = StateNotifierProvider.family<
    SubmissionNotifier, SubmissionState, String>(
  (ref, roomId) {
    final repository = ref.watch(submissionRepositoryProvider);
    final storage = ref.watch(storageServiceProvider);
    return SubmissionNotifier(repository, storage);
  },
);
```

### 2.4 Using Providers in Widgets

```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final roomsAsync = ref.watch(userRoomsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Rooms'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: roomsAsync.when(
        data: (rooms) => _buildRoomList(rooms),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrJoinDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomList(List<Room> rooms) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No rooms yet'),
            SizedBox(height: 8),
            Text('Create or join a room to get started'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: rooms.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return RoomCard(room: rooms[index]);
      },
    );
  }
}

// Using StateNotifier with Form
class SubmitChallengeScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Challenge challenge;

  const SubmitChallengeScreen({
    Key? key,
    required this.roomId,
    required this.challenge,
  }) : super(key: key);

  @override
  ConsumerState<SubmitChallengeScreen> createState() =>
      _SubmitChallengeScreenState();
}

class _SubmitChallengeScreenState
    extends ConsumerState<SubmitChallengeScreen> {
  File? _selectedImage;
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(
      submissionNotifierProvider(widget.roomId),
    );
    final currentUser = ref.watch(currentUserProvider);

    // Listen to state changes
    ref.listen<SubmissionState>(
      submissionNotifierProvider(widget.roomId),
      (previous, next) {
        if (next.submission != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission created!')),
          );
          Navigator.pop(context);
        } else if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text('Submit Challenge')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.challenge.challengeText,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            if (widget.challenge.type != ChallengeType.text)
              _buildImagePicker(),
            if (widget.challenge.type != ChallengeType.photo)
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Your response',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: submissionState.isSubmitting ? null : _submit,
              child: submissionState.isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final notifier = ref.read(
      submissionNotifierProvider(widget.roomId).notifier,
    );
    final currentUser = ref.read(currentUserProvider);

    await notifier.submitChallenge(
      challengeId: widget.challenge.id,
      roomId: widget.roomId,
      userId: currentUser.id,
      imageFile: _selectedImage,
      textContent: _textController.text.trim().isNotEmpty
          ? _textController.text.trim()
          : null,
    );
  }
}
```

---

## 3. Repository Pattern Implementation

### 3.1 Repository Interface

```dart
// domain/repositories/room_repository.dart
abstract class RoomRepository {
  Future<List<Room>> getUserRooms(String userId);
  Future<Room> createRoom({
    required String name,
    String? description,
    required String userId,
  });
  Future<Room> joinRoom({
    required String roomCode,
    required String userId,
  });
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  });
  Future<Room> getRoomById(String roomId);
  Stream<List<Room>> watchUserRooms(String userId);
}
```

### 3.2 Repository Implementation

```dart
// data/repositories/room_repository_impl.dart
class RoomRepositoryImpl implements RoomRepository {
  final SupabaseClient _client;

  RoomRepositoryImpl(this._client);

  @override
  Future<List<Room>> getUserRooms(String userId) async {
    try {
      final response = await _client
          .from('room_members')
          .select('*, rooms(*)')
          .eq('user_id', userId)
          .order('joined_at', ascending: false);

      return (response as List)
          .map((json) => Room.fromJson(json['rooms']))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Room> createRoom({
    required String name,
    String? description,
    required String userId,
  }) async {
    try {
      // Generate unique room code
      final code = _generateRoomCode();

      // Create room
      final roomData = await _client.from('rooms').insert({
        'name': name,
        'description': description,
        'code': code,
        'created_by': userId,
      }).select().single();

      // Add creator as admin member
      await _client.from('room_members').insert({
        'room_id': roomData['id'],
        'user_id': userId,
        'role': 'admin',
      });

      return Room.fromJson(roomData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Room> joinRoom({
    required String roomCode,
    required String userId,
  }) async {
    try {
      // Find room by code
      final roomData = await _client
          .from('rooms')
          .select()
          .eq('code', roomCode.toUpperCase())
          .maybeSingle();

      if (roomData == null) {
        throw RoomNotFoundException('Room not found with code: $roomCode');
      }

      // Check if already a member
      final existingMember = await _client
          .from('room_members')
          .select()
          .eq('room_id', roomData['id'])
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw AlreadyMemberException('You are already a member of this room');
      }

      // Add user as member
      await _client.from('room_members').insert({
        'room_id': roomData['id'],
        'user_id': userId,
        'role': 'member',
      });

      return Room.fromJson(roomData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _client
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Room> getRoomById(String roomId) async {
    try {
      final roomData = await _client
          .from('rooms')
          .select()
          .eq('id', roomId)
          .single();

      return Room.fromJson(roomData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<List<Room>> watchUserRooms(String userId) {
    return _client
        .from('room_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((memberData) async {
          // Fetch room details for each membership
          final roomIds = memberData.map((m) => m['room_id']).toList();
          
          if (roomIds.isEmpty) return <Room>[];
          
          final roomsData = await _client
              .from('rooms')
              .select()
              .in_('id', roomIds);
          
          return (roomsData as List)
              .map((json) => Room.fromJson(json))
              .toList();
        });
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Exception _handleError(Object error) {
    if (error is PostgrestException) {
      return RepositoryException(error.message);
    } else if (error is RepositoryException) {
      return error;
    }
    return RepositoryException('An unexpected error occurred');
  }
}

// Custom exceptions
class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);

  @override
  String toString() => message;
}

class RoomNotFoundException extends RepositoryException {
  RoomNotFoundException(String message) : super(message);
}

class AlreadyMemberException extends RepositoryException {
  AlreadyMemberException(String message) : super(message);
}
```

---

## 4. Navigation with GoRouter

### 4.1 Route Configuration

```dart
// core/router/app_router.dart
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login';
      final isRootRoute = state.matchedLocation == '/';

      // Redirect to login if not authenticated
      if (!isAuthenticated && !isAuthRoute && !isRootRoute) {
        return '/login';
      }

      // Redirect to home if authenticated and on auth route
      if (isAuthenticated && (isAuthRoute || isRootRoute)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-room',
        builder: (context, state) => const CreateRoomScreen(),
      ),
      GoRoute(
        path: '/join-room',
        builder: (context, state) => const JoinRoomScreen(),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomDetailsScreen(roomId: roomId);
        },
        routes: [
          GoRoute(
            path: 'submit',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              final challenge = state.extra as Challenge;
              return SubmitChallengeScreen(
                roomId: roomId,
                challenge: challenge,
              );
            },
          ),
          GoRoute(
            path: 'submission/:submissionId',
            builder: (context, state) {
              final submissionId = state.pathParameters['submissionId']!;
              return SubmissionDetailScreen(submissionId: submissionId);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return RoomSettingsScreen(roomId: roomId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

// Use in app.dart
class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Kanzi App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
```

---

## 5. Image Upload Flow

### 5.1 Storage Service

```dart
// shared/services/storage_service.dart
class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  Future<String> uploadSubmissionImage(
    String userId,
    String submissionId,
    File imageFile,
  ) async {
    try {
      // Compress image first
      final compressedImage = await _compressImage(imageFile);

      // Generate unique filename
      final fileName = '$submissionId-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'submissions/$userId/$fileName';

      // Upload to Supabase Storage
      await _client.storage.from('challenge-images').upload(
            path,
            compressedImage,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _client.storage.from('challenge-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw StorageException('Failed to upload image: $e');
    }
  }

  Future<void> deleteSubmissionImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find 'challenge-images' bucket index and get path after it
      final bucketIndex = pathSegments.indexOf('challenge-images');
      if (bucketIndex == -1) throw Exception('Invalid image URL');
      
      final path = pathSegments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from('challenge-images').remove([path]);
    } catch (e) {
      throw StorageException('Failed to delete image: $e');
    }
  }

  Future<File> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Resize to max 1080px width while maintaining aspect ratio
    final resized = image.width > 1080
        ? img.copyResize(image, width: 1080)
        : image;

    // Compress to JPEG with 85% quality
    final compressed = img.encodeJpg(resized, quality: 85);

    // Write to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(compressed);

    return tempFile;
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => message;
}
```

### 5.2 Image Picker Widget

```dart
// shared/widgets/image_picker_widget.dart
class ImagePickerWidget extends StatefulWidget {
  final Function(File) onImageSelected;
  final File? initialImage;

  const ImagePickerWidget({
    Key? key,
    required this.onImageSelected,
    this.initialImage,
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _selectedImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() => _selectedImage = file);
        widget.onImageSelected(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedImage != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() => _selectedImage = null);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 64, color: Colors.grey[600]),
                  SizedBox(height: 8),
                  Text('No image selected', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library),
                label: Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 6. Testing Strategy

### 6.1 Unit Tests (Repositories)

```dart
// test/data/repositories/room_repository_test.dart
void main() {
  late MockSupabaseClient mockClient;
  late RoomRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = RoomRepositoryImpl(mockClient);
  });

  group('RoomRepository', () {
    test('createRoom should return Room with generated code', () async {
      // Arrange
      when(mockClient.from('rooms').insert(any))
          .thenAnswer((_) async => {
                'id': 'room-uuid',
                'code': 'ABC123',
                'name': 'Test Room',
                'description': null,
                'created_by': 'user-uuid',
              });

      when(mockClient.from('room_members').insert(any))
          .thenAnswer((_) async => {});

      // Act
      final room = await repository.createRoom(
        name: 'Test Room',
        userId: 'user-uuid',
      );

      // Assert
      expect(room.code, hasLength(6));
      expect(room.name, 'Test Room');
      verify(mockClient.from('rooms').insert(any)).called(1);
    });

    test('joinRoom should throw RoomNotFoundException for invalid code',
        () async {
      // Arrange
      when(mockClient.from('rooms').select().eq('code', any).maybeSingle())
          .thenAnswer((_) async => null);

      // Act & Assert
      expect(
        () => repository.joinRoom(roomCode: 'INVALID', userId: 'user-uuid'),
        throwsA(isA<RoomNotFoundException>()),
      );
    });
  });
}
```

### 6.2 Widget Tests

```dart
// test/features/rooms/presentation/screens/home_screen_test.dart
void main() {
  testWidgets('HomeScreen shows room list when data is available',
      (tester) async {
    // Arrange
    final mockRooms = [
      Room(id: '1', name: 'Room 1', code: 'CODE1'),
      Room(id: '2', name: 'Room 2', code: 'CODE2'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRoomsProvider.overrideWith(
            (ref) => Stream.value(mockRooms),
          ),
        ],
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    // Act
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Room 1'), findsOneWidget);
    expect(find.text('Room 2'), findsOneWidget);
  });
}
```

---

## 7. Performance Optimizations

### 7.1 Image Caching

```dart
// Use CachedNetworkImage for submission images
CachedNetworkImage(
  imageUrl: submission.imageUrl,
  placeholder: (context, url) => Center(
    child: CircularProgressIndicator(),
  ),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fit: BoxFit.cover,
  memCacheWidth: 600, // Reduce memory usage
  maxHeightDiskCache: 1200,
  maxWidthDiskCache: 1200,
)
```

### 7.2 Pagination (Future Enhancement)

```dart
// For large lists of submissions
final submissionsProvider = StreamProvider.family.autoDispose<
    List<Submission>, SubmissionQuery>((ref, query) {
  final repository = ref.watch(submissionRepositoryProvider);
  return repository.watchSubmissions(
    roomId: query.roomId,
    limit: query.limit,
    offset: query.offset,
  );
});
```

---

## 8. Security Best Practices

### 8.1 Never Expose Service Role Key in Flutter

```dart
// ❌ WRONG - Never do this!
const serviceRoleKey = 'your-service-role-key';

// ✅ CORRECT - Only use anon key
const anonKey = 'your-anon-key';
```

### 8.2 Validate Data Client-Side

```dart
class Validators {
  static String? validateRoomCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Room code is required';
    }
    if (value.length != 6) {
      return 'Room code must be 6 characters';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'Room code must be alphanumeric';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }
}
```

---

## Summary

This architecture provides:
- ✅ **Scalability:** Easy to add new features
- ✅ **Testability:** Each layer is independently testable
- ✅ **Maintainability:** Clear separation of concerns
- ✅ **Type Safety:** Compile-time error catching with Riverpod
- ✅ **Real-time Updates:** Stream-based state management

Follow this guide to build a robust, production-ready MVP! 🚀
