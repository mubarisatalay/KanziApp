// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline =>
      'Daily challenges with your friends.\nSubmit, vote, win.';

  @override
  String get taglineShort => 'Submit, vote, win.';

  @override
  String get labelUsernameUpper => 'USERNAME';

  @override
  String get labelEmailUpper => 'E-MAIL';

  @override
  String get labelPasswordUpper => 'PASSWORD';

  @override
  String get labelRoomNameUpper => 'ROOM NAME';

  @override
  String get labelDescriptionOptionalUpper => 'DESCRIPTION (OPTIONAL)';

  @override
  String get labelDescriptionUpper => 'DESCRIPTION';

  @override
  String get labelInviteCodeUpper => 'INVITE CODE';

  @override
  String get labelDisplayNameUpper => 'DISPLAY NAME';

  @override
  String get labelYourAnswerUpper => 'YOUR ANSWER';

  @override
  String get labelCaptionOptionalUpper => 'CAPTION (OPTIONAL)';

  @override
  String get labelPhotoUpper => 'PHOTO';

  @override
  String get labelPhotoRequiredUpper => 'PHOTO (REQUIRED)';

  @override
  String get show => 'show';

  @override
  String get hide => 'hide';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get noAccountPrompt => 'No account yet? ';

  @override
  String get haveAccountPrompt => 'Already have an account? ';

  @override
  String get forgotPassword => 'Forgot my password';

  @override
  String get accountCreatedVerify =>
      'Account created! Verify your e-mail before signing in.';

  @override
  String get resendEmail => 'Resend';

  @override
  String get resendEmailSent => 'Sent again — check your inbox.';

  @override
  String greeting(String name) {
    return 'Hi $name';
  }

  @override
  String roomsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Challenges await you in $count rooms',
      one: 'A challenge awaits you in 1 room',
    );
    return '$_temp0';
  }

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverSubtitle => 'Rooms you haven\'t joined yet';

  @override
  String get discoverEmpty => 'You\'re in all available rooms!';

  @override
  String get discoverEmptySubtitle =>
      'Create a new room or wait for an invite.';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get challengeToday => 'Challenge today';

  @override
  String get joinWithCode => 'Join with Code';

  @override
  String get noRoomsTitle => 'No rooms yet';

  @override
  String get noRoomsSubtitle =>
      'Create a room or join your friends\' room with an invite code.';

  @override
  String get createRoomAction => 'Create room';

  @override
  String get createRoomSubtitle => 'Start a new challenge room';

  @override
  String get joinRoomAction => 'Join room';

  @override
  String get joinRoomSubtitle => 'Enter an invite code';

  @override
  String get roomFabLabel => 'Room';

  @override
  String members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get adminSuffix => ' · admin';

  @override
  String activeChallengeProgress(int submitted, int total) {
    return 'Active challenge · $submitted/$total submitted';
  }

  @override
  String get challengeAwaitsYou => 'A challenge awaits you';

  @override
  String get noChallengeToday => 'No challenge today';

  @override
  String get newRoomTitle => 'New room';

  @override
  String get create => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get roomNameRequired => 'Room name is required';

  @override
  String get roomNameTooShort => 'At least 2 characters';

  @override
  String get roomNameTooLong => 'At most 50 characters';

  @override
  String roomCreated(String name, String code) {
    return '\"$name\" created · code: $code';
  }

  @override
  String get joinRoomTitle => 'Join a room';

  @override
  String get join => 'Join';

  @override
  String get inviteCodeRequired => 'Invite code is required';

  @override
  String get inviteCodeLength => 'Code must be 6 characters';

  @override
  String get inviteCodeHint => 'Ask the room admin for the 6-character code.';

  @override
  String joinedRoom(String name) {
    return 'Joined \"$name\"!';
  }

  @override
  String get youAreAdminSuffix => ' · you\'re the admin';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get shareAction => 'Share';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get sectionTodaysChallengeUpper => 'TODAY\'S CHALLENGE';

  @override
  String get historyLink => 'History ›';

  @override
  String get sectionMembersUpper => 'MEMBERS';

  @override
  String get leaderboardLink => 'Scoreboard ›';

  @override
  String get mvpLink => 'Weekly MVP ›';

  @override
  String get mvpTitle => 'Weekly MVP';

  @override
  String get mvpWeekLabel => 'This week · normalized score';

  @override
  String get mvpTabRoom => 'This Room';

  @override
  String get mvpTabGlobal => 'All Rooms';

  @override
  String get mvpNoData => 'No data this week yet';

  @override
  String get mvpNoDataSub =>
      'Complete challenges and earn votes to appear here!';

  @override
  String get mvpYouLabel => 'YOU';

  @override
  String mvpSubmissionsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subs',
      one: '1 sub',
    );
    return '$_temp0';
  }

  @override
  String get adminBadge => 'Admin';

  @override
  String get unknownUser => 'Unknown';

  @override
  String membersLoadFailed(String error) {
    return 'Couldn\'t load members: $error';
  }

  @override
  String get menuCreateChallenge => 'Create challenge';

  @override
  String get menuEditRoom => 'Edit room';

  @override
  String get menuDeleteRoom => 'Delete room';

  @override
  String get menuLeaveRoom => 'Leave room';

  @override
  String get editRoomTitle => 'Edit room';

  @override
  String get save => 'Save';

  @override
  String get roomUpdated => 'Room updated!';

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get deleteRoomTitle => 'Delete room';

  @override
  String deleteRoomConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone — all room data will be permanently deleted.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get roomDeleted => 'Room deleted';

  @override
  String get leaveRoomTitle => 'Leave room';

  @override
  String leaveRoomConfirm(String name) {
    return 'Do you want to leave \"$name\"?';
  }

  @override
  String get leave => 'Leave';

  @override
  String get leftRoom => 'You left the room';

  @override
  String actionFailed(String error) {
    return 'Action failed: $error';
  }

  @override
  String get noChallengeAdminHint => 'You can create a new challenge.';

  @override
  String get noChallengeMemberHint => 'The daily challenge will appear here.';

  @override
  String get challengeLoadFailed => 'Couldn\'t load the challenge';

  @override
  String get retry => 'Try again';

  @override
  String submissionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count submissions',
      one: '1 submission',
    );
    return '$_temp0';
  }

  @override
  String get submitted => 'Submitted ✓';

  @override
  String get submitAction => 'Submit';

  @override
  String get nextChallengeLabel => 'Next Challenge';

  @override
  String get statusActiveUpper => 'ACTIVE';

  @override
  String get statusFinishedUpper => 'FINISHED';

  @override
  String get statusUpcomingUpper => 'UPCOMING';

  @override
  String get timeLeftSuffix => ' left';

  @override
  String get todaysChallengeTitle => 'Today\'s challenge';

  @override
  String get challengeTitle => 'Challenge';

  @override
  String get sectionSubmissionsUpper => 'SUBMISSIONS';

  @override
  String get anonymousNote => 'Nobody knows who\'s who';

  @override
  String get revealCountdownLabelUpper => 'UNTIL THE REVEAL';

  @override
  String revealNote(String time) {
    return 'Results open at $time · votes are anonymous';
  }

  @override
  String get noSubmissionsYet => 'No submissions yet — be the first!';

  @override
  String get submitYourPhoto => 'Submit your photo';

  @override
  String get submitYourAnswer => 'Submit your answer';

  @override
  String get youSubmitted => 'You submitted ✓';

  @override
  String get youHaventSubmitted => 'You haven\'t submitted';

  @override
  String get typePhoto => 'Photo';

  @override
  String get typeText => 'Text';

  @override
  String get typePhotoText => 'Photo + text';

  @override
  String anonymousEntry(int number) {
    return 'ENTRY #$number';
  }

  @override
  String get yourVote => 'Your vote';

  @override
  String get vote => 'Vote';

  @override
  String get noVotesYet => 'No votes';

  @override
  String ratingLabel(String score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
    );
    return '$score ($_temp0)';
  }

  @override
  String get ownSubmissionNotice =>
      'You submitted this — you can\'t vote on your own entry';

  @override
  String get submitSheetTitle => 'Submit your answer';

  @override
  String get pickImageFailed => 'Couldn\'t pick the image. Try again.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get photoRequiredError => 'Add a photo for this challenge.';

  @override
  String get textRequiredError => 'Add some text for this challenge.';

  @override
  String get submittedToast => 'Submitted!';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get answerHint => 'Write your answer…';

  @override
  String get captionHint => 'Add something…';

  @override
  String get send => 'Send';

  @override
  String get scoreboardTitle => 'Scoreboard';

  @override
  String get tabToday => 'Today';

  @override
  String get tabAllTime => 'All-time';

  @override
  String get noSubmissionsToday => 'No submissions today yet';

  @override
  String get noVotesYetBoard => 'No votes yet';

  @override
  String get boardEmptyHint => 'Submit and vote — rankings show up here.';

  @override
  String votesShort(int count) {
    return '$count votes';
  }

  @override
  String get youPillUpper => 'YOU';

  @override
  String get profileTitle => 'Profile';

  @override
  String get edit => 'Edit';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String memberSince(String date) {
    return 'since $date';
  }

  @override
  String get statRoomsUpper => 'ROOMS';

  @override
  String get statWinsUpper => 'CHALLENGE WINS';

  @override
  String get statStreakUpper => 'DAY STREAK';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String get signOut => 'Sign out';

  @override
  String profileLoadFailed(String error) {
    return 'Couldn\'t load profile: $error';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String ceremonyRevealLabel(String time) {
    return '$time · REVEAL';
  }

  @override
  String get ceremonyTitle => 'Today\'s winner';

  @override
  String get ceremonyNobodySubmitted => 'Nobody submitted today.';

  @override
  String get ceremonyShare => 'Share the result';

  @override
  String get ceremonyShareHeader => 'kanzi. — today\'s winner';

  @override
  String get seeResults => 'The results are in — see the winner ›';

  @override
  String get anonymousName => 'Hidden';
}
