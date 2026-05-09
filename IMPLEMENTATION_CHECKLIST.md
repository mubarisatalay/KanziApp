# Implementation Checklist

Use this checklist to track your progress building the Kanzi App MVP.

---

## Phase 0: Setup & Configuration

### Supabase Setup
- [x] Create Supabase project ✅
- [x] Run `database_schema.sql` in SQL Editor ⚠️ (User needs to run this manually)
- [x] Verify all tables created (profiles, rooms, room_members, challenges, submissions, votes)
- [ ] Create storage bucket `challenge-images` (public)
- [ ] Configure storage policies
- [ ] Test RLS policies by creating test data
- [ ] Set up Edge Function for daily challenges
- [ ] Configure cron job (daily at 00:00 UTC)
- [x] Copy Project URL and anon key ✅

### Flutter Project Setup
- [x] Initialize Flutter project ✅
- [x] Add dependencies to `pubspec.yaml` ✅
- [x] Run `flutter pub get` ✅
- [x] Create `lib/core/constants/supabase_constants.dart` ✅
- [x] Add Supabase credentials ✅
- [x] Initialize Supabase in `main.dart` ✅
- [ ] Test app builds successfully on Android (Ready to test)
- [ ] Test app builds successfully on iOS (Ready to test)

### Project Structure
- [x] Create folder structure (core/, features/, shared/) ✅
- [x] Set up core constants ✅
- [x] Set up app theme ✅
- [x] Configure GoRouter ✅
- [x] Create shared providers (Supabase client) ✅

---

## Phase 1: Authentication (Week 1)

### Data Layer
- [x] Create `features/auth/data/models/user_model.dart` ✅
- [x] Create `features/auth/data/repositories/auth_repository.dart` ✅
- [x] Implement `signInWithEmail()` ✅
- [x] Implement `signUpWithEmail()` ✅
- [x] Implement `signOut()` ✅
- [x] Implement `authStateChanges` stream ✅
- [ ] Write unit tests for auth repository

### Presentation Layer
- [x] Create `features/auth/presentation/providers/auth_provider.dart` ✅
- [x] Create `authStateProvider` (StreamProvider) ✅
- [x] Create `currentUserProvider` ✅
- [x] Create `features/auth/presentation/screens/splash_screen.dart` ✅
- [x] Create `features/auth/presentation/screens/login_screen.dart` ✅
- [x] Create login form with email/password inputs ✅
- [x] Add form validation ✅
- [x] Implement "Sign Up" toggle ✅
- [x] Add loading states ✅
- [x] Add error handling ✅
- [ ] Write widget tests for login screen

### Testing & Validation
- [ ] Test signup flow (create new account) ⚠️ (Ready to test - needs database setup)
- [ ] Test login flow (existing account) ⚠️ (Ready to test - needs database setup)
- [ ] Test logout flow ⚠️ (Ready to test)
- [ ] Test auth state persistence (app restart)
- [ ] Test error cases (wrong password, invalid email)
- [ ] Verify profile created in Supabase after signup

---

## Phase 2: Room Management (Week 2)

### Data Layer
- [ ] Create `features/rooms/data/models/room_model.dart`
- [ ] Create `features/rooms/data/models/room_member_model.dart`
- [ ] Create `features/rooms/data/repositories/room_repository.dart`
- [ ] Implement `getUserRooms()`
- [ ] Implement `createRoom()`
- [ ] Implement `joinRoom()` with room code lookup
- [ ] Implement `leaveRoom()`
- [ ] Implement `getRoomById()`
- [ ] Implement `watchUserRooms()` stream
- [ ] Add room code generation logic
- [ ] Write unit tests for room repository

### Presentation Layer
- [ ] Create `features/rooms/presentation/providers/room_provider.dart`
- [ ] Create `userRoomsProvider` (StreamProvider)
- [ ] Create `roomProvider` (FutureProvider.family)
- [ ] Create `features/rooms/presentation/screens/home_screen.dart`
- [ ] Display list of joined rooms
- [ ] Create empty state (no rooms)
- [ ] Add floating action button (Create/Join)
- [ ] Create `features/rooms/presentation/screens/create_room_screen.dart`
- [ ] Add room name input
- [ ] Add room description input (optional)
- [ ] Auto-generate and display room code
- [ ] Implement create room action
- [ ] Create `features/rooms/presentation/screens/join_room_screen.dart`
- [ ] Add room code input (6 characters, uppercase)
- [ ] Add validation for room code format
- [ ] Display room details before joining
- [ ] Implement join room action
- [ ] Create `features/rooms/presentation/widgets/room_card.dart`
- [ ] Display room name, code, member count
- [ ] Add tap action to navigate to room details
- [ ] Write widget tests for room screens

### Room Details
- [ ] Create `features/rooms/presentation/screens/room_details_screen.dart`
- [ ] Implement tab layout (Challenge, Leaderboard, Members)
- [ ] Add app bar with room name
- [ ] Add room settings button (admin only)
- [ ] Add leave room button
- [ ] Create `features/rooms/presentation/screens/room_settings_screen.dart`
- [ ] Allow editing room name/description (admin only)
- [ ] Display room code (copy to clipboard)
- [ ] Add delete room button (admin only)
- [ ] Add confirmation dialog for delete
- [ ] Write widget tests for room details

### Testing & Validation
- [ ] Test creating a room
- [ ] Verify room code is unique and 6 characters
- [ ] Verify creator is added as admin
- [ ] Test joining room with valid code
- [ ] Test joining room with invalid code (error handling)
- [ ] Test leaving a room
- [ ] Test deleting a room (admin only)
- [ ] Verify room members can see the room
- [ ] Verify non-members cannot see the room (RLS)

---

## Phase 3: Challenges & Submissions (Week 3)

### Data Layer
- [ ] Create `features/challenges/data/models/challenge_model.dart`
- [ ] Create `features/challenges/data/models/submission_model.dart`
- [ ] Create `features/challenges/data/repositories/challenge_repository.dart`
- [ ] Implement `getTodayChallenge(roomId)`
- [ ] Implement `getSubmissionsForChallenge(challengeId)`
- [ ] Implement `createSubmission()`
- [ ] Implement `getUserSubmission(challengeId, userId)`
- [ ] Implement `watchSubmissions()` stream
- [ ] Create `shared/services/storage_service.dart`
- [ ] Implement `uploadSubmissionImage()`
- [ ] Implement `deleteSubmissionImage()`
- [ ] Add image compression logic
- [ ] Write unit tests for challenge repository

### Presentation Layer
- [ ] Create `features/challenges/presentation/providers/challenge_provider.dart`
- [ ] Create `todayChallengeProvider` (FutureProvider.family)
- [ ] Create `submissionsProvider` (StreamProvider.family)
- [ ] Create `userSubmissionProvider` (FutureProvider.family)
- [ ] Create `features/challenges/presentation/screens/challenge_feed_screen.dart`
- [ ] Display today's challenge text at top
- [ ] Add countdown timer (time left for submissions)
- [ ] Display user's own submission (if exists)
- [ ] Display list of other users' submissions
- [ ] Add floating action button "Submit Entry"
- [ ] Hide submit button if already submitted
- [ ] Create `features/challenges/presentation/screens/submit_challenge_screen.dart`
- [ ] Display challenge prompt
- [ ] Add photo input (camera + gallery buttons)
- [ ] Add text input field
- [ ] Show/hide inputs based on challenge type
- [ ] Add image preview
- [ ] Add submit button with loading state
- [ ] Implement image compression before upload
- [ ] Implement submission creation
- [ ] Create `features/challenges/presentation/widgets/challenge_card.dart`
- [ ] Create `features/challenges/presentation/widgets/submission_card.dart`
- [ ] Display submission image (if photo challenge)
- [ ] Display submission text (if text challenge)
- [ ] Display author name and avatar
- [ ] Add vote button (covered in Phase 4)
- [ ] Create `features/challenges/presentation/screens/submission_detail_screen.dart`
- [ ] Full-screen image view
- [ ] Display text content
- [ ] Display author info
- [ ] Add vote button
- [ ] Write widget tests for challenge screens

### Image Handling
- [ ] Create `shared/widgets/image_picker_widget.dart`
- [ ] Implement camera capture
- [ ] Implement gallery selection
- [ ] Add image preview
- [ ] Add remove image action
- [ ] Test image compression (< 1MB after compression)
- [ ] Test image upload to Supabase Storage
- [ ] Verify public URL generation

### Testing & Validation
- [ ] Verify daily challenge is created for each room
- [ ] Test viewing today's challenge
- [ ] Test submitting photo-only challenge
- [ ] Test submitting text-only challenge
- [ ] Test submitting photo+text challenge
- [ ] Verify user can only submit once per challenge
- [ ] Test image compression (output size < 1MB)
- [ ] Test image upload success
- [ ] Verify submission appears in feed
- [ ] Test real-time submission updates (use 2 devices)
- [ ] Verify non-members cannot see submissions (RLS)

---

## Phase 4: Voting System (Week 4)

### Data Layer
- [ ] Create `features/voting/data/models/vote_model.dart`
- [ ] Create `features/voting/data/repositories/vote_repository.dart`
- [ ] Implement `voteOnSubmission(submissionId, userId)`
- [ ] Implement `unvoteSubmission(submissionId, userId)`
- [ ] Implement `getUserVote(submissionId, userId)`
- [ ] Implement `getVoteCount(submissionId)`
- [ ] Add validation to prevent voting on own submission
- [ ] Write unit tests for vote repository

### Presentation Layer
- [ ] Create `features/voting/presentation/providers/vote_provider.dart`
- [ ] Create `voteCountProvider` (StreamProvider.family)
- [ ] Create `userVoteProvider` (FutureProvider.family)
- [ ] Create `features/voting/presentation/widgets/vote_button.dart`
- [ ] Display vote count
- [ ] Show voted state (highlighted if user voted)
- [ ] Disable button if own submission
- [ ] Add loading state during vote action
- [ ] Implement vote toggle (vote/unvote)
- [ ] Integrate vote button into submission cards
- [ ] Add vote button to submission detail screen
- [ ] Write widget tests for vote button

### Testing & Validation
- [ ] Test voting on another user's submission
- [ ] Verify vote count increases immediately
- [ ] Test unvoting (vote count decreases)
- [ ] Verify user cannot vote on own submission
- [ ] Verify user can only vote once per submission
- [ ] Test changing vote (unvote then vote again)
- [ ] Test real-time vote updates (use 2 devices)
- [ ] Verify vote persists after app restart

---

## Phase 5: Leaderboard (Week 4 continued)

### Data Layer
- [ ] Create `features/leaderboard/data/models/leaderboard_entry_model.dart`
- [ ] Create `features/leaderboard/data/repositories/leaderboard_repository.dart`
- [ ] Implement `getDailyLeaderboard(roomId, date)`
- [ ] Implement `getDailyWinner(roomId, date)`
- [ ] Test leaderboard calculation with sample data
- [ ] Write unit tests for leaderboard repository

### Presentation Layer
- [ ] Create `features/leaderboard/presentation/providers/leaderboard_provider.dart`
- [ ] Create `dailyLeaderboardProvider` (FutureProvider.family)
- [ ] Create `dailyWinnerProvider` (FutureProvider.family)
- [ ] Create `features/leaderboard/presentation/screens/leaderboard_screen.dart`
- [ ] Display ranked list of users
- [ ] Show position number (1, 2, 3, ...)
- [ ] Display user avatar and name
- [ ] Display total votes for today
- [ ] Highlight #1 with crown icon
- [ ] Add date filter (Today / Yesterday)
- [ ] Create `features/leaderboard/presentation/widgets/leaderboard_item.dart`
- [ ] Add winner badge to room cards on home screen
- [ ] Write widget tests for leaderboard

### Testing & Validation
- [ ] Verify leaderboard calculates correctly
- [ ] Test with tie scores (multiple users with same votes)
- [ ] Verify winner is highlighted
- [ ] Test leaderboard refreshes daily
- [ ] Test viewing yesterday's leaderboard
- [ ] Verify winner badge appears on home screen

---

## Phase 6: Polish & Optimization (Week 5)

### Error Handling
- [ ] Add global error handler
- [ ] Display user-friendly error messages
- [ ] Add retry logic for failed network requests
- [ ] Handle offline mode gracefully
- [ ] Add error boundaries for widgets

### Loading States
- [ ] Add shimmer loading for room list
- [ ] Add shimmer loading for submission feed
- [ ] Add shimmer loading for leaderboard
- [ ] Add progress indicators for form submissions
- [ ] Add skeleton screens for initial load

### Real-time Features
- [ ] Implement real-time submission updates
- [ ] Implement real-time vote count updates
- [ ] Add optimistic UI updates
- [ ] Handle connection loss gracefully

### UI/UX Improvements
- [ ] Add pull-to-refresh on lists
- [ ] Add smooth animations and transitions
- [ ] Improve empty states with illustrations
- [ ] Add haptic feedback for actions
- [ ] Improve form validation feedback
- [ ] Add toast notifications for success/error

### Performance
- [ ] Optimize image loading with caching
- [ ] Add pagination for long lists (if needed)
- [ ] Lazy load images in submission feed
- [ ] Profile app performance with DevTools
- [ ] Fix any memory leaks

### Accessibility
- [ ] Add semantic labels for screen readers
- [ ] Ensure proper contrast ratios
- [ ] Test with TalkBack (Android) and VoiceOver (iOS)
- [ ] Add keyboard navigation support

---

## Phase 7: Testing (Week 5-6)

### Unit Tests
- [ ] Test all repositories (auth, rooms, challenges, voting, leaderboard)
- [ ] Test all models (serialization/deserialization)
- [ ] Test utility functions
- [ ] Test validators
- [ ] Achieve >80% code coverage for business logic

### Widget Tests
- [ ] Test login screen
- [ ] Test home screen
- [ ] Test create/join room screens
- [ ] Test room details screen
- [ ] Test challenge feed screen
- [ ] Test submit challenge screen
- [ ] Test leaderboard screen
- [ ] Test all custom widgets

### Integration Tests
- [ ] Test complete auth flow (signup → login → logout)
- [ ] Test complete room flow (create → join → leave)
- [ ] Test complete challenge flow (view → submit → vote)
- [ ] Test leaderboard updates after voting

### Manual Testing
- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Test on different screen sizes
- [ ] Test in airplane mode (offline handling)
- [ ] Test with slow network connection
- [ ] Test with multiple users simultaneously
- [ ] Test edge cases (empty states, long text, etc.)

---

## Phase 8: Deployment Preparation (Week 6)

### App Assets
- [ ] Design app icon (1024x1024)
- [ ] Generate app icons for all platforms
- [ ] Design splash screen
- [ ] Generate splash screens for all platforms
- [ ] Add app screenshots for stores

### Android
- [ ] Update app name in `AndroidManifest.xml`
- [ ] Update package name in `build.gradle`
- [ ] Set up code signing (keystore)
- [ ] Test release build locally
- [ ] Build release APK
- [ ] Build release App Bundle

### iOS
- [ ] Update bundle identifier in Xcode
- [ ] Update app name in `Info.plist`
- [ ] Set up code signing in Xcode
- [ ] Test release build locally
- [ ] Build release IPA

### App Store Setup
- [ ] Create Google Play Console account
- [ ] Create Apple Developer account
- [ ] Write app description (short & long)
- [ ] Create promotional graphics
- [ ] Set up age rating
- [ ] Set up privacy policy URL
- [ ] Submit to Google Play (beta)
- [ ] Submit to TestFlight (beta)

---

## Phase 9: Beta Testing & Feedback (Week 7+)

### Beta Release
- [ ] Invite 10-20 beta testers
- [ ] Distribute via TestFlight (iOS)
- [ ] Distribute via Play Store Beta (Android)
- [ ] Create feedback form (Google Forms / Typeform)
- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Monitor user feedback

### Bug Fixes & Iterations
- [ ] Fix critical bugs reported by beta testers
- [ ] Address usability feedback
- [ ] Optimize performance based on feedback
- [ ] Iterate on UI/UX
- [ ] Release beta updates

### Production Release
- [ ] Verify all critical bugs fixed
- [ ] Get approval from beta testers
- [ ] Write release notes
- [ ] Submit to Google Play (production)
- [ ] Submit to App Store (production)
- [ ] Announce launch!

---

## Optional Enhancements (Post-MVP)

### Features
- [ ] Push notifications for new challenges
- [ ] User profile screen with stats
- [ ] Challenge history view
- [ ] Weekly/monthly leaderboards
- [ ] User badges and achievements
- [ ] Private rooms (invite-only)
- [ ] In-app messaging
- [ ] Social sharing of submissions

### Technical
- [ ] Set up CI/CD pipeline (GitHub Actions / Codemagic)
- [ ] Add analytics (Firebase Analytics / Mixpanel)
- [ ] Add crash reporting (Firebase Crashlytics / Sentry)
- [ ] Set up remote config for feature flags
- [ ] Add A/B testing framework
- [ ] Implement deep linking
- [ ] Add multi-language support (i18n)

### Business
- [ ] Create landing page
- [ ] Set up social media accounts
- [ ] Plan marketing strategy
- [ ] Set up user support system
- [ ] Monitor app metrics and KPIs

---

## Progress Tracking

- **Start Date:** _______________
- **Target Launch Date:** _______________
- **Current Phase:** _______________
- **Completed Tasks:** _____ / _____
- **Blockers:** _______________

---

## Notes

Use this section to track decisions, blockers, or important notes:

```
[Date] - Note
```

---

**Good luck with your implementation! 🚀**

Refer to the other documentation files for detailed guidance:
- [MVP_DESIGN.md](MVP_DESIGN.md) - Product specification
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture
- [QUICKSTART.md](QUICKSTART.md) - Setup guide
- [DATABASE_DIAGRAM.md](DATABASE_DIAGRAM.md) - Database schema
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration guide
