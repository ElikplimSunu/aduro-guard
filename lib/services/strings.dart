import 'prefs.dart';

/// UI strings. English is the base; Twi ships as conservative, code-switched
/// everyday Twi (tech nouns stay English, the way Ghanaian apps actually
/// read). Ewe, Dagbani and Hausa chrome falls back to English until native
/// speakers review translations; their CONTENT (counseling, answers, voices)
/// is already in-language via Gemma.
///
/// Review note for Twi speakers: every string sits next to its English
/// source below. Corrections welcome; keep them short.
abstract final class S {
  static String _l(String en, {String? tw}) =>
      Prefs.instance.language == 'tw' ? (tw ?? en) : en;

  // ── Home ──────────────────────────────────────────────────────────────
  static String get scanAMedicine => _l('Scan a medicine', tw: 'Hwɛ aduro bi');
  static String get scanBlurb => _l('Point at the pack. Get a verdict in seconds.',
      tw: 'Fa camera no kyerɛ adaka no so. Wubehu mmuae ntɛm.');
  static String worksOffline(int count, String date) => _l(
      'Works offline · register snapshot of $count products · $date',
      tw: 'Internet ho nhia · FDA nhoma mu nneɛma $count · $date');
  static String get recentChecks => _l('Recent checks', tw: 'Nea woahwɛ');
  static String get seeAll => _l('See all', tw: 'Hwɛ ne nyinaa');
  static String get nothingChecked => _l(
      'Nothing checked yet. Scan your first medicine and the verdict lands here.',
      tw: 'Wonhwɛɛ hwee ɛ. Hwɛ w’aduro a edi kan na mmuae no bɛba ha.');
  static String get unnamedPack => _l('Unnamed pack');
  static String get justNow => _l('Just now', tw: 'Seesei ara');
  static String minAgo(int m) => _l('$m min ago', tw: 'Simma $m atwam');
  static String hAgo(int h) => _l('$h h ago', tw: 'Nnɔnhwerew $h atwam');
  static String get yesterday => _l('Yesterday', tw: 'Nnɛra');

  // ── Scan & result ─────────────────────────────────────────────────────
  static String get resultTitle => _l('Result', tw: 'Mmuae');
  static String get useThisPhoto => _l('Use this photo?', tw: 'Fa mfonini yi?');
  static String get retake => _l('Retake', tw: 'Twa bio');
  static String get checkIt => _l('Check it', tw: 'Hwɛ');
  static String get tryAgain => _l('Try again', tw: 'Sɔ hwɛ bio');
  static String get scanAgain => _l('Scan again', tw: 'Hwɛ bio');
  static String get scanAnother =>
      _l('Scan another medicine', tw: 'Hwɛ aduro foforo');
  static String get readingPack =>
      _l('Reading the pack…', tw: 'Yɛrekenkan adaka no so…');
  static String get checkingRegister =>
      _l('Checking the register…', tw: 'Yɛrehwɛ FDA nhoma no mu…');
  static String get allOnPhone => _l(
      'Everything runs on this phone. No internet needed.',
      tw: 'Biribiara yɛ adwuma wɔ phone yi so. Internet ho nhia.');
  static String get cameraOff => _l(
      'Camera permission is off. Allow it in Settings, or pick a photo instead.');
  static String get noCamera =>
      _l('No camera on this device. Pick a photo of the pack instead.');
  static String get photoFailed => _l('The photo failed. Try again.');
  static String get pickFromPhotos => _l('Pick from photos');
  static String get takePhoto => _l('Take photo', tw: 'Twa mfonini');
  static String get tipsTitle =>
      _l('Tips for a clear read', tw: 'Nea ɛbɛma yɛahu no yiye');
  static String get tips => _l(
      '• Move to brighter light. Daylight works best.\n'
      '• Fill the frame with the front of the pack.\n'
      '• Hold still until the photo is sharp.',
      tw: '• Kɔ baabi a hann wɔ. Awia hann yɛ pa ara.\n'
          '• Ma adaka no anim nyinaa nna mfonini no mu.\n'
          '• Gyina hɔ dinn na mfonini no anyɛ basaa.');
  static String get modelNotSetUp => _l(
      'The offline model is not set up yet. Download it in Settings, then scan again.');
  static String get somethingWrong =>
      _l('Something went wrong while checking. Try again.');

  // ── Verdict headlines ─────────────────────────────────────────────────
  static String get vRegistered =>
      _l('In the register', tw: 'Ɛwɔ FDA nhoma no mu');
  static String get vExpired => _l('Expired', tw: 'Ne bere atwam');
  static String get vRecalled => _l('Do not take this', tw: 'Nnom aduro yi');
  static String get vCaution => _l('Check this carefully', tw: 'Hwɛ yei yiye');
  static String get vNotFound =>
      _l('Not in the register snapshot', tw: 'Enni FDA nhoma yi mu');
  static String get vUnreadable =>
      _l('Couldn’t read the pack', tw: 'Yantumi ankenkan adaka no so');
  static String get vChecked => _l('Checked', tw: 'Yɛahwɛ');

  // ── Facts & sections ──────────────────────────────────────────────────
  static String get whatPackSays =>
      _l('What the pack says', tw: 'Nea ɛwɔ adaka no so');
  static String get whatPackSaid =>
      _l('What the pack said', tw: 'Nea na ɛwɔ adaka no so');
  static String get product => _l('Product', tw: 'Aduro');
  static String get madeBy => _l('Made by', tw: 'Nea ɔyɛe');
  static String get batch => _l('Batch');
  static String get expiry => _l('Expiry', tw: 'Ne bere');
  static String get fdaNumber => _l('FDA number');
  static String get whatThisMeans =>
      _l('What this means', tw: 'Nea ɛkyerɛ');
  static String get puttingPlainWords =>
      _l('Putting it in plain words…', tw: 'Yɛrekyerɛ mu…');
  static String get readAloud => _l('Read aloud', tw: 'Kenkan ma me');
  static String get stopReading => _l('Stop', tw: 'Gyae');
  static String get guidanceUnavailable => _l(
      'Guidance is unavailable right now. The verdict above still stands.');
  static String downloadVoiceHint(String language) => _l(
      'Download the $language voice in Settings to hear this aloud.',
      tw: 'Twe $language nne no wɔ Nhyehyɛe mu na woate.');
  static String voiceRoadmap(String language) =>
      _l('A $language voice is on the roadmap.');

  // ── Follow-up ─────────────────────────────────────────────────────────
  static String get askAboutPack =>
      _l('Ask about this pack', tw: 'Bisa biribi fa aduro yi ho');
  static String get answersFromPack => _l(
      'Answers come only from what the pack itself says.',
      tw: 'Mmuae no fi nea ɛwɔ adaka no so nko ara.');
  static String get typeQuestion =>
      _l('Type a question…', tw: 'Kyerɛw asɛmmisa…');
  static String get send => _l('Send');
  static String get holdAndSpeak => _l(
      'Hold the gold button and speak your question.',
      tw: 'Mia button no so na kasa.');
  static String get listeningLetGo =>
      _l('Listening… let go to send.', tw: 'Yɛretie… gyae na ɛnkɔ.');
  static String get listeningToPack =>
      _l('Listening to the pack…', tw: 'Yɛrehwɛ adaka no so…');
  static String get spokenQuestion =>
      _l('Spoken question', tw: 'Asɛmmisa a wokae');
  static String get askFailed => _l('That didn’t work. Ask again.');
  static String get holdToRecordHint =>
      _l('Hold to record a spoken question');

  // ── Settings ──────────────────────────────────────────────────────────
  static String get settings => _l('Settings', tw: 'Nhyehyɛe');
  static String get language => _l('Language', tw: 'Kasa');
  static String get earlySupport => _l('Early support');
  static String get appearance => _l('Appearance');
  static String get matchPhone => _l('Match the phone', tw: 'Di phone no akyi');
  static String get light => _l('Light', tw: 'Hann');
  static String get dark => _l('Dark', tw: 'Sum');
  static String get offlineBrain => _l('Offline brain');
  static String get offlineBrainBlurb => _l(
      'Gemma 4 runs entirely on this phone. Download once on Wi-Fi; scanning then needs no internet at all.',
      tw: 'Gemma 4 yɛ adwuma wɔ phone yi so. Twe no pɛnkoro wɔ Wi-Fi so; ɛno akyi internet ho nhia koraa.');
  static String get voices => _l('Voices', tw: 'Nne ahorow');
  static String get voicesBlurb => _l(
      'Optional offline voices so guidance can be read aloud in local languages. Each is a one-time download.',
      tw: 'Twe nne no na yɛakenkan akwankyerɛ no wɔ wo kasa mu. Wutwe no pɛnkoro pɛ.');
  static String voiceName(String language) =>
      _l('$language voice', tw: '$language nne');
  static String voiceBlurb(String language) => _l(
      'Reads $language guidance aloud, offline.',
      tw: 'Ɛkenkan $language akwankyerɛ, internet ho nhia.');
  static String get download => _l('Download', tw: 'Twe');
  static String get remove => _l('Remove', tw: 'Yi fi hɔ');
  static String get installed => _l('Installed', tw: 'Ɛwɔ hɔ');
  static String get importFile => _l('Import file');
  static String downloading(int p) => _l('Downloading… $p%', tw: 'Ɛretwe… $p%');
  static String downloadingModel(String name, int p) =>
      _l('Downloading $name · $p%', tw: 'Ɛretwe $name · $p%');
  static String get downloadStopped => _l(
      'The download stopped. Check your connection and retry.');
  static String get importFailed => _l('That file could not be imported.');
  static String get notSeenOnPack =>
      _l('The camera did not see:', tw: 'Kamera no anhu:');
  static String get addAnotherSide =>
      _l('Add a photo of another side', tw: 'Fa ɔfa foforo mfonini ka ho');
  static String get sideFailed => _l(
      'That side could not be read. The first result is unchanged.',
      tw: 'Yantumi ankenkan saa ɔfa no. Nea edi kan no da hɔ.');
  static String get preparingFile => _l('Getting the file ready. This can take a minute.',
      tw: 'Yɛresiesie fael no. Ebetumi agye bere kakra.');
  static String get about => _l('About', tw: 'Ɛfa ho');
  static String snapshotLine(int count, String date) => _l(
      'Register snapshot: $count products · $date',
      tw: 'FDA nhoma mu nneɛma: $count · $date');
  static String get disclaimer => _l(
      'Aduro Guard is a verification aid, not medical advice. For any health decision, talk to a pharmacist, a clinic, or the FDA on 0551112224 (WhatsApp).',
      tw: 'Aduro Guard boa wo ma wohwɛ aduro; ɛnyɛ ayaresa afotu. Apɔmuden asɛm biara ho no, kɔhwɛ pharmacist, clinic, anaa FDA wɔ 0551112224 (WhatsApp) so.');

  // ── Onboarding ────────────────────────────────────────────────────────
  static String get welcomeBlurb => _l(
      'Point your camera at any medicine pack. It gets checked against the Ghana FDA register, right here on your phone, no internet needed.',
      tw: 'Fa wo camera kyerɛ aduro adaka biara so. Yɛde bɛtoto Ghana FDA nhoma no ho wɔ wo phone yi ara so; internet ho nhia.');
  static String get chooseLanguage =>
      _l('Choose your language', tw: 'Yi wo kasa');
  static String get continueLabel => _l('Continue', tw: 'Kɔ so');
  static String get setupBrainTitle =>
      _l('Set up the offline brain');
  static String setupBrainBlurb(String size) => _l(
      'Aduro Guard reads packs with Gemma 4, a model that lives on your phone. One download of $size, best on Wi-Fi, and every scan after that works with no signal at all.',
      tw: 'Aduro Guard de Gemma 4 na ɛkenkan aduro adaka; ɛte wo phone yi so. Twe $size pɛnkoro (Wi-Fi so ye), na ɛno akyi biribiara yɛ adwuma a signal nnim.');
  static String downloadSize(String size) =>
      _l('Download · $size', tw: 'Twe · $size');
  static String get alreadyHaveFile => _l('I already have the file');
  static String get setUpLater => _l('Set up later', tw: 'Yɛ no akyiri yi');
  static String e4bNote(String size) => _l(
      'This is the version sized for everyday phones. A stronger $size version for 8 GB phones lives in Settings whenever you want it.');
  static String get downloadStoppedRetryImport => _l(
      'The download stopped. Check your connection and try again, or import the file if you already have it.');

  // ── History ───────────────────────────────────────────────────────────
  static String get allChecks => _l('All checks', tw: 'Nea woahwɛ nyinaa');
  static String get noChecksYet => _l('No checks yet.', tw: 'Wonhwɛɛ hwee ɛ.');
  static String get savedCheck => _l('Saved check', tw: 'Nea woahwɛ');
  static String get guidanceGiven =>
      _l('Guidance given', tw: 'Akwankyerɛ a wonyae');
  static String get deleteCheckQ =>
      _l('Delete this check?', tw: 'Yi eyi mfi hɔ?');
  static String get deleteBody =>
      _l('This only removes the saved record.');
  static String get keepIt => _l('Keep it', tw: 'Gyae ma ɛnna hɔ');
  static String get delete => _l('Delete', tw: 'Yi fi hɔ');
  static String checkedOn(String date) =>
      _l('Checked $date', tw: 'Yɛhwɛe $date');
}
