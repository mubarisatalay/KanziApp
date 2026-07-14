// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get tagline => 'Arkadaşlarınla günlük görevler.\nGönder, oyla, kazan.';

  @override
  String get taglineShort => 'Gönder, oyla, kazan.';

  @override
  String get labelUsernameUpper => 'KULLANICI ADI';

  @override
  String get labelEmailUpper => 'E-POSTA';

  @override
  String get labelPasswordUpper => 'ŞİFRE';

  @override
  String get labelRoomNameUpper => 'ODA ADI';

  @override
  String get labelDescriptionOptionalUpper => 'AÇIKLAMA (İSTEĞE BAĞLI)';

  @override
  String get labelDescriptionUpper => 'AÇIKLAMA';

  @override
  String get labelInviteCodeUpper => 'DAVET KODU';

  @override
  String get labelDisplayNameUpper => 'GÖRÜNEN AD';

  @override
  String get labelYourAnswerUpper => 'CEVABIN';

  @override
  String get labelCaptionOptionalUpper => 'AÇIKLAMA (İSTEĞE BAĞLI)';

  @override
  String get labelPhotoUpper => 'FOTOĞRAF';

  @override
  String get labelPhotoRequiredUpper => 'FOTOĞRAF (GEREKLİ)';

  @override
  String get show => 'göster';

  @override
  String get hide => 'gizle';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signUp => 'Kayıt ol';

  @override
  String get noAccountPrompt => 'Hesabın yok mu? ';

  @override
  String get haveAccountPrompt => 'Zaten hesabın var mı? ';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get accountCreatedVerify =>
      'Hesap oluşturuldu! Giriş yapmadan önce e-postanı doğrula.';

  @override
  String get resendEmail => 'Tekrar gönder';

  @override
  String get resendEmailSent => 'Tekrar gönderildi — gelen kutunu kontrol et.';

  @override
  String greeting(String name) {
    return 'Selam $name';
  }

  @override
  String roomsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count odada seni bekleyen görev var',
      one: '1 odada seni bekleyen görev var',
    );
    return '$_temp0';
  }

  @override
  String get noRoomsTitle => 'Henüz bir odan yok';

  @override
  String get noRoomsSubtitle =>
      'Yeni bir oda kur ya da davet koduyla arkadaşlarının odasına katıl.';

  @override
  String get createRoomAction => 'Oda oluştur';

  @override
  String get createRoomSubtitle => 'Yeni bir görev odası kur';

  @override
  String get joinRoomAction => 'Odaya katıl';

  @override
  String get joinRoomSubtitle => 'Davet kodunu gir';

  @override
  String get roomFabLabel => 'Oda';

  @override
  String members(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count üye',
      one: '1 üye',
    );
    return '$_temp0';
  }

  @override
  String get adminSuffix => ' · admin';

  @override
  String activeChallengeProgress(int submitted, int total) {
    return 'Aktif görev · $submitted/$total gönderdi';
  }

  @override
  String get challengeAwaitsYou => 'Görev seni bekliyor';

  @override
  String get noChallengeToday => 'Bugün görev yok';

  @override
  String get newRoomTitle => 'Yeni oda';

  @override
  String get create => 'Oluştur';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get roomNameRequired => 'Oda adı gerekli';

  @override
  String get roomNameTooShort => 'En az 2 karakter';

  @override
  String get roomNameTooLong => 'En fazla 50 karakter';

  @override
  String roomCreated(String name, String code) {
    return '\"$name\" kuruldu · kod: $code';
  }

  @override
  String get joinRoomTitle => 'Odaya katıl';

  @override
  String get join => 'Katıl';

  @override
  String get inviteCodeRequired => 'Davet kodu gerekli';

  @override
  String get inviteCodeLength => 'Kod 6 karakter olmalı';

  @override
  String get inviteCodeHint => '6 karakterlik kodu oda admininden iste.';

  @override
  String joinedRoom(String name) {
    return '\"$name\" odasına katıldın!';
  }

  @override
  String get youAreAdminSuffix => ' · sen adminsin';

  @override
  String get inviteCodeLabel => 'Davet kodu';

  @override
  String get shareAction => 'Paylaş';

  @override
  String get codeCopied => 'Kod kopyalandı!';

  @override
  String get sectionTodaysChallengeUpper => 'BUGÜNÜN GÖREVİ';

  @override
  String get historyLink => 'Geçmiş ›';

  @override
  String get sectionMembersUpper => 'ÜYELER';

  @override
  String get leaderboardLink => 'Skor tablosu ›';

  @override
  String get adminBadge => 'Admin';

  @override
  String get unknownUser => 'Bilinmiyor';

  @override
  String membersLoadFailed(String error) {
    return 'Üyeler yüklenemedi: $error';
  }

  @override
  String get menuCreateChallenge => 'Görev oluştur';

  @override
  String get menuEditRoom => 'Odayı düzenle';

  @override
  String get menuDeleteRoom => 'Odayı sil';

  @override
  String get menuLeaveRoom => 'Odadan ayrıl';

  @override
  String get editRoomTitle => 'Odayı düzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get roomUpdated => 'Oda güncellendi!';

  @override
  String updateFailed(String error) {
    return 'Güncellenemedi: $error';
  }

  @override
  String get deleteRoomTitle => 'Odayı sil';

  @override
  String deleteRoomConfirm(String name) {
    return '\"$name\" silinsin mi? Bu geri alınamaz — tüm oda verisi kalıcı olarak silinir.';
  }

  @override
  String get delete => 'Sil';

  @override
  String get roomDeleted => 'Oda silindi';

  @override
  String get leaveRoomTitle => 'Odadan ayrıl';

  @override
  String leaveRoomConfirm(String name) {
    return '\"$name\" odasından ayrılmak istiyor musun?';
  }

  @override
  String get leave => 'Ayrıl';

  @override
  String get leftRoom => 'Odadan ayrıldın';

  @override
  String actionFailed(String error) {
    return 'İşlem başarısız: $error';
  }

  @override
  String get noChallengeAdminHint => 'Yeni bir görev oluşturabilirsin.';

  @override
  String get noChallengeMemberHint => 'Günlük görev burada görünecek.';

  @override
  String get challengeLoadFailed => 'Görev yüklenemedi';

  @override
  String get retry => 'Tekrar dene';

  @override
  String submissionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gönderi',
      one: '1 gönderi',
    );
    return '$_temp0';
  }

  @override
  String get submitted => 'Gönderildi ✓';

  @override
  String get submitAction => 'Gönder';

  @override
  String get statusActiveUpper => 'AKTİF';

  @override
  String get statusFinishedUpper => 'BİTTİ';

  @override
  String get statusUpcomingUpper => 'YAKINDA';

  @override
  String get timeLeftSuffix => ' kaldı';

  @override
  String get todaysChallengeTitle => 'Bugünün görevi';

  @override
  String get challengeTitle => 'Görev';

  @override
  String get sectionSubmissionsUpper => 'GÖNDERİLER';

  @override
  String get anonymousNote => 'Kim kimin bilinmiyor';

  @override
  String get revealCountdownLabelUpper => 'AÇILIŞA KALAN';

  @override
  String revealNote(String time) {
    return 'Sonuçlar $time\'de açılır · oylar anonim';
  }

  @override
  String get noSubmissionsYet => 'Henüz gönderi yok — ilk sen ol!';

  @override
  String get submitYourPhoto => 'Fotoğrafını gönder';

  @override
  String get submitYourAnswer => 'Cevabını gönder';

  @override
  String get youSubmitted => 'Sen gönderdin ✓';

  @override
  String get youHaventSubmitted => 'Sen göndermedin';

  @override
  String get typePhoto => 'Fotoğraf';

  @override
  String get typeText => 'Yazı';

  @override
  String get typePhotoText => 'Fotoğraf + yazı';

  @override
  String anonymousEntry(int number) {
    return 'GÖNDERİ #$number';
  }

  @override
  String get yourVote => 'Senin oyun';

  @override
  String get vote => 'Oyla';

  @override
  String get noVotesYet => 'Oy yok';

  @override
  String ratingLabel(String score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oy',
      one: '1 oy',
    );
    return '$score ($_temp0)';
  }

  @override
  String get ownSubmissionNotice =>
      'Sen gönderdin — kendi gönderine oy veremezsin';

  @override
  String get submitSheetTitle => 'Cevabını gönder';

  @override
  String get pickImageFailed => 'Fotoğraf seçilemedi. Tekrar dene.';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get photoRequiredError => 'Bu görev için bir fotoğraf ekle.';

  @override
  String get textRequiredError => 'Bu görev için bir yazı ekle.';

  @override
  String get submittedToast => 'Gönderildi!';

  @override
  String get choosePhoto => 'Fotoğraf seç';

  @override
  String get answerHint => 'Cevabını yaz…';

  @override
  String get captionHint => 'Bir şeyler ekle…';

  @override
  String get send => 'Gönder';

  @override
  String get scoreboardTitle => 'Skor tablosu';

  @override
  String get tabToday => 'Bugün';

  @override
  String get tabAllTime => 'Tüm zamanlar';

  @override
  String get noSubmissionsToday => 'Bugün henüz gönderi yok';

  @override
  String get noVotesYetBoard => 'Henüz oy yok';

  @override
  String get boardEmptyHint => 'Gönder ve oyla — sıralama burada.';

  @override
  String votesShort(int count) {
    return '$count oy';
  }

  @override
  String get youPillUpper => 'SEN';

  @override
  String get profileTitle => 'Profil';

  @override
  String get edit => 'Düzenle';

  @override
  String get profileNotFound => 'Profil bulunamadı';

  @override
  String memberSince(String date) {
    return '$date\'ten beri';
  }

  @override
  String get statRoomsUpper => 'ODA';

  @override
  String get statWinsUpper => 'GÖREV GALİBİYETİ';

  @override
  String get statStreakUpper => 'GÜN SERİ';

  @override
  String get profileUpdated => 'Profil güncellendi!';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String profileLoadFailed(String error) {
    return 'Profil yüklenemedi: $error';
  }

  @override
  String get somethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String ceremonyRevealLabel(String time) {
    return '$time · AÇILIŞ';
  }

  @override
  String get ceremonyTitle => 'Bugünün kazananı';

  @override
  String get ceremonyNobodySubmitted => 'Bugün kimse göndermedi.';

  @override
  String get ceremonyShare => 'Sonucu paylaş';

  @override
  String get ceremonyShareHeader => 'kanzi. — bugünün kazananı';

  @override
  String get seeResults => 'Sonuçlar açıldı — kazananı gör ›';

  @override
  String get anonymousName => 'Gizli';
}
