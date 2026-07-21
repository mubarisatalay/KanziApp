import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Daily challenges with your friends.\nSubmit, vote, win.'**
  String get tagline;

  /// No description provided for @taglineShort.
  ///
  /// In en, this message translates to:
  /// **'Submit, vote, win.'**
  String get taglineShort;

  /// No description provided for @labelUsernameUpper.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get labelUsernameUpper;

  /// No description provided for @labelEmailUpper.
  ///
  /// In en, this message translates to:
  /// **'E-MAIL'**
  String get labelEmailUpper;

  /// No description provided for @labelPasswordUpper.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get labelPasswordUpper;

  /// No description provided for @labelRoomNameUpper.
  ///
  /// In en, this message translates to:
  /// **'ROOM NAME'**
  String get labelRoomNameUpper;

  /// No description provided for @labelDescriptionOptionalUpper.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION (OPTIONAL)'**
  String get labelDescriptionOptionalUpper;

  /// No description provided for @labelDescriptionUpper.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get labelDescriptionUpper;

  /// No description provided for @labelInviteCodeUpper.
  ///
  /// In en, this message translates to:
  /// **'INVITE CODE'**
  String get labelInviteCodeUpper;

  /// No description provided for @labelDisplayNameUpper.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY NAME'**
  String get labelDisplayNameUpper;

  /// No description provided for @labelYourAnswerUpper.
  ///
  /// In en, this message translates to:
  /// **'YOUR ANSWER'**
  String get labelYourAnswerUpper;

  /// No description provided for @labelCaptionOptionalUpper.
  ///
  /// In en, this message translates to:
  /// **'CAPTION (OPTIONAL)'**
  String get labelCaptionOptionalUpper;

  /// No description provided for @labelPhotoUpper.
  ///
  /// In en, this message translates to:
  /// **'PHOTO'**
  String get labelPhotoUpper;

  /// No description provided for @labelPhotoRequiredUpper.
  ///
  /// In en, this message translates to:
  /// **'PHOTO (REQUIRED)'**
  String get labelPhotoRequiredUpper;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'hide'**
  String get hide;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'No account yet? '**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccountPrompt;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot my password'**
  String get forgotPassword;

  /// No description provided for @accountCreatedVerify.
  ///
  /// In en, this message translates to:
  /// **'Account created! Verify your e-mail before signing in.'**
  String get accountCreatedVerify;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendEmail;

  /// No description provided for @resendEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Sent again — check your inbox.'**
  String get resendEmailSent;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String greeting(String name);

  /// No description provided for @roomsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A challenge awaits you in 1 room} other{Challenges await you in {count} rooms}}'**
  String roomsWaiting(int count);

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms you haven\'t joined yet'**
  String get discoverSubtitle;

  /// No description provided for @discoverEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re in all available rooms!'**
  String get discoverEmpty;

  /// No description provided for @discoverEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new room or wait for an invite.'**
  String get discoverEmptySubtitle;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// No description provided for @challengeToday.
  ///
  /// In en, this message translates to:
  /// **'Challenge today'**
  String get challengeToday;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with Code'**
  String get joinWithCode;

  /// No description provided for @noRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'No rooms yet'**
  String get noRoomsTitle;

  /// No description provided for @noRoomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a room or join your friends\' room with an invite code.'**
  String get noRoomsSubtitle;

  /// No description provided for @createRoomAction.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoomAction;

  /// No description provided for @createRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new challenge room'**
  String get createRoomSubtitle;

  /// No description provided for @joinRoomAction.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get joinRoomAction;

  /// No description provided for @joinRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite code'**
  String get joinRoomSubtitle;

  /// No description provided for @roomFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get roomFabLabel;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String members(int count);

  /// No description provided for @adminSuffix.
  ///
  /// In en, this message translates to:
  /// **' · admin'**
  String get adminSuffix;

  /// No description provided for @activeChallengeProgress.
  ///
  /// In en, this message translates to:
  /// **'Active challenge · {submitted}/{total} submitted'**
  String activeChallengeProgress(int submitted, int total);

  /// No description provided for @challengeAwaitsYou.
  ///
  /// In en, this message translates to:
  /// **'A challenge awaits you'**
  String get challengeAwaitsYou;

  /// No description provided for @noChallengeToday.
  ///
  /// In en, this message translates to:
  /// **'No challenge today'**
  String get noChallengeToday;

  /// No description provided for @newRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'New room'**
  String get newRoomTitle;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @roomNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Room name is required'**
  String get roomNameRequired;

  /// No description provided for @roomNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 2 characters'**
  String get roomNameTooShort;

  /// No description provided for @roomNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'At most 50 characters'**
  String get roomNameTooLong;

  /// No description provided for @roomCreated.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" created · code: {code}'**
  String roomCreated(String name, String code);

  /// No description provided for @joinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a room'**
  String get joinRoomTitle;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @inviteCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Invite code is required'**
  String get inviteCodeRequired;

  /// No description provided for @inviteCodeLength.
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 characters'**
  String get inviteCodeLength;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the room admin for the 6-character code.'**
  String get inviteCodeHint;

  /// No description provided for @joinedRoom.
  ///
  /// In en, this message translates to:
  /// **'Joined \"{name}\"!'**
  String joinedRoom(String name);

  /// No description provided for @youAreAdminSuffix.
  ///
  /// In en, this message translates to:
  /// **' · you\'re the admin'**
  String get youAreAdminSuffix;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @sectionTodaysChallengeUpper.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S CHALLENGE'**
  String get sectionTodaysChallengeUpper;

  /// No description provided for @historyLink.
  ///
  /// In en, this message translates to:
  /// **'History ›'**
  String get historyLink;

  /// No description provided for @sectionMembersUpper.
  ///
  /// In en, this message translates to:
  /// **'MEMBERS'**
  String get sectionMembersUpper;

  /// No description provided for @leaderboardLink.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard ›'**
  String get leaderboardLink;

  /// No description provided for @mvpLink.
  ///
  /// In en, this message translates to:
  /// **'Weekly MVP ›'**
  String get mvpLink;

  /// No description provided for @mvpTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly MVP'**
  String get mvpTitle;

  /// No description provided for @mvpWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'This week · normalized score'**
  String get mvpWeekLabel;

  /// No description provided for @mvpTabRoom.
  ///
  /// In en, this message translates to:
  /// **'This Room'**
  String get mvpTabRoom;

  /// No description provided for @mvpTabGlobal.
  ///
  /// In en, this message translates to:
  /// **'All Rooms'**
  String get mvpTabGlobal;

  /// No description provided for @mvpNoData.
  ///
  /// In en, this message translates to:
  /// **'No data this week yet'**
  String get mvpNoData;

  /// No description provided for @mvpNoDataSub.
  ///
  /// In en, this message translates to:
  /// **'Complete challenges and earn votes to appear here!'**
  String get mvpNoDataSub;

  /// No description provided for @mvpYouLabel.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get mvpYouLabel;

  /// No description provided for @mvpSubmissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sub} other{{count} subs}}'**
  String mvpSubmissionsLabel(int count);

  /// No description provided for @adminBadge.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminBadge;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// No description provided for @membersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members: {error}'**
  String membersLoadFailed(String error);

  /// No description provided for @menuCreateChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create challenge'**
  String get menuCreateChallenge;

  /// No description provided for @menuEditRoom.
  ///
  /// In en, this message translates to:
  /// **'Edit room'**
  String get menuEditRoom;

  /// No description provided for @menuDeleteRoom.
  ///
  /// In en, this message translates to:
  /// **'Delete room'**
  String get menuDeleteRoom;

  /// No description provided for @menuLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get menuLeaveRoom;

  /// No description provided for @editRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit room'**
  String get editRoomTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @roomUpdated.
  ///
  /// In en, this message translates to:
  /// **'Room updated!'**
  String get roomUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String updateFailed(String error);

  /// No description provided for @deleteRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete room'**
  String get deleteRoomTitle;

  /// No description provided for @deleteRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone — all room data will be permanently deleted.'**
  String deleteRoomConfirm(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @roomDeleted.
  ///
  /// In en, this message translates to:
  /// **'Room deleted'**
  String get roomDeleted;

  /// No description provided for @leaveRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get leaveRoomTitle;

  /// No description provided for @leaveRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave \"{name}\"?'**
  String leaveRoomConfirm(String name);

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leftRoom.
  ///
  /// In en, this message translates to:
  /// **'You left the room'**
  String get leftRoom;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed: {error}'**
  String actionFailed(String error);

  /// No description provided for @noChallengeAdminHint.
  ///
  /// In en, this message translates to:
  /// **'You can create a new challenge.'**
  String get noChallengeAdminHint;

  /// No description provided for @noChallengeMemberHint.
  ///
  /// In en, this message translates to:
  /// **'The daily challenge will appear here.'**
  String get noChallengeMemberHint;

  /// No description provided for @challengeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the challenge'**
  String get challengeLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @submissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 submission} other{{count} submissions}}'**
  String submissionsCount(int count);

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted ✓'**
  String get submitted;

  /// No description provided for @submitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitAction;

  /// No description provided for @nextChallengeLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Challenge'**
  String get nextChallengeLabel;

  /// No description provided for @statusActiveUpper.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActiveUpper;

  /// No description provided for @statusFinishedUpper.
  ///
  /// In en, this message translates to:
  /// **'FINISHED'**
  String get statusFinishedUpper;

  /// No description provided for @statusUpcomingUpper.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get statusUpcomingUpper;

  /// No description provided for @timeLeftSuffix.
  ///
  /// In en, this message translates to:
  /// **' left'**
  String get timeLeftSuffix;

  /// No description provided for @todaysChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge'**
  String get todaysChallengeTitle;

  /// No description provided for @challengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challengeTitle;

  /// No description provided for @sectionSubmissionsUpper.
  ///
  /// In en, this message translates to:
  /// **'SUBMISSIONS'**
  String get sectionSubmissionsUpper;

  /// No description provided for @anonymousNote.
  ///
  /// In en, this message translates to:
  /// **'Nobody knows who\'s who'**
  String get anonymousNote;

  /// No description provided for @revealCountdownLabelUpper.
  ///
  /// In en, this message translates to:
  /// **'UNTIL THE REVEAL'**
  String get revealCountdownLabelUpper;

  /// No description provided for @revealNote.
  ///
  /// In en, this message translates to:
  /// **'Results open at {time} · votes are anonymous'**
  String revealNote(String time);

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet — be the first!'**
  String get noSubmissionsYet;

  /// No description provided for @submitYourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Submit your photo'**
  String get submitYourPhoto;

  /// No description provided for @submitYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit your answer'**
  String get submitYourAnswer;

  /// No description provided for @youSubmitted.
  ///
  /// In en, this message translates to:
  /// **'You submitted ✓'**
  String get youSubmitted;

  /// No description provided for @youHaventSubmitted.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t submitted'**
  String get youHaventSubmitted;

  /// No description provided for @typePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get typePhoto;

  /// No description provided for @typeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get typeText;

  /// No description provided for @typePhotoText.
  ///
  /// In en, this message translates to:
  /// **'Photo + text'**
  String get typePhotoText;

  /// No description provided for @anonymousEntry.
  ///
  /// In en, this message translates to:
  /// **'ENTRY #{number}'**
  String anonymousEntry(int number);

  /// No description provided for @yourVote.
  ///
  /// In en, this message translates to:
  /// **'Your vote'**
  String get yourVote;

  /// No description provided for @vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get vote;

  /// No description provided for @noVotesYet.
  ///
  /// In en, this message translates to:
  /// **'No votes'**
  String get noVotesYet;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'{score} ({count, plural, =1{1 vote} other{{count} votes}})'**
  String ratingLabel(String score, int count);

  /// No description provided for @ownSubmissionNotice.
  ///
  /// In en, this message translates to:
  /// **'You submitted this — you can\'t vote on your own entry'**
  String get ownSubmissionNotice;

  /// No description provided for @submitSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your answer'**
  String get submitSheetTitle;

  /// No description provided for @pickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t pick the image. Try again.'**
  String get pickImageFailed;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @photoRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Add a photo for this challenge.'**
  String get photoRequiredError;

  /// No description provided for @textRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Add some text for this challenge.'**
  String get textRequiredError;

  /// No description provided for @submittedToast.
  ///
  /// In en, this message translates to:
  /// **'Submitted!'**
  String get submittedToast;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @answerHint.
  ///
  /// In en, this message translates to:
  /// **'Write your answer…'**
  String get answerHint;

  /// No description provided for @captionHint.
  ///
  /// In en, this message translates to:
  /// **'Add something…'**
  String get captionHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @scoreboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get scoreboardTitle;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabAllTime.
  ///
  /// In en, this message translates to:
  /// **'All-time'**
  String get tabAllTime;

  /// No description provided for @noSubmissionsToday.
  ///
  /// In en, this message translates to:
  /// **'No submissions today yet'**
  String get noSubmissionsToday;

  /// No description provided for @noVotesYetBoard.
  ///
  /// In en, this message translates to:
  /// **'No votes yet'**
  String get noVotesYetBoard;

  /// No description provided for @boardEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Submit and vote — rankings show up here.'**
  String get boardEmptyHint;

  /// No description provided for @votesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String votesShort(int count);

  /// No description provided for @youPillUpper.
  ///
  /// In en, this message translates to:
  /// **'YOU'**
  String get youPillUpper;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String memberSince(String date);

  /// No description provided for @statRoomsUpper.
  ///
  /// In en, this message translates to:
  /// **'ROOMS'**
  String get statRoomsUpper;

  /// No description provided for @statWinsUpper.
  ///
  /// In en, this message translates to:
  /// **'CHALLENGE WINS'**
  String get statWinsUpper;

  /// No description provided for @statStreakUpper.
  ///
  /// In en, this message translates to:
  /// **'DAY STREAK'**
  String get statStreakUpper;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load profile: {error}'**
  String profileLoadFailed(String error);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @ceremonyRevealLabel.
  ///
  /// In en, this message translates to:
  /// **'{time} · REVEAL'**
  String ceremonyRevealLabel(String time);

  /// No description provided for @ceremonyTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s winner'**
  String get ceremonyTitle;

  /// No description provided for @ceremonyNobodySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Nobody submitted today.'**
  String get ceremonyNobodySubmitted;

  /// No description provided for @ceremonyShare.
  ///
  /// In en, this message translates to:
  /// **'Share the result'**
  String get ceremonyShare;

  /// No description provided for @ceremonyShareHeader.
  ///
  /// In en, this message translates to:
  /// **'kanzi. — today\'s winner'**
  String get ceremonyShareHeader;

  /// No description provided for @seeResults.
  ///
  /// In en, this message translates to:
  /// **'The results are in — see the winner ›'**
  String get seeResults;

  /// No description provided for @anonymousName.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get anonymousName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
