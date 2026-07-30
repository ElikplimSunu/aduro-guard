import 'prefs.dart';

/// UI strings. English is the base; Twi, Ewe, Dagbani and Hausa sit beside
/// each English source below. The style is conservative, code-switched
/// everyday speech: tech nouns (camera, photo, batch, register, FDA) stay
/// English the way Ghanaian apps actually read.
///
/// Review note for native speakers: corrections welcome, keep them short.
/// A missing translation falls back to English on purpose rather than guess.
abstract final class S {
  static String _l(String en,
          {String? tw, String? ee, String? dag, String? ha}) =>
      switch (Prefs.instance.language) {
        'tw' => tw ?? en,
        'ee' => ee ?? en,
        'dag' => dag ?? en,
        'ha' => ha ?? en,
        _ => en,
      };

  // ── Home ──────────────────────────────────────────────────────────────
  static String get scanAMedicine => _l('Scan a medicine',
      tw: 'Hwɛ aduro bi',
      ee: 'Kpɔ atike aɖe',
      dag: 'Vihimi tim',
      ha: 'Duba magani');
  static String get scanBlurb => _l(
      'Point at the pack. Get a verdict in seconds.',
      tw: 'Fa camera no kyerɛ adaka no so. Wubehu mmuae ntɛm.',
      ee: 'Trɔ camera ɖe aɖaka la ŋu. Àkpɔ ŋuɖoɖo kaba.',
      ha: 'Nuna kyamara ga akwatin. Za ka sami amsa nan take.');
  static String worksOffline(int count, String date) => _l(
      'Works offline · register snapshot of $count products · $date',
      tw: 'Internet ho nhia · FDA nhoma mu nneɛma $count · $date',
      ee: 'Internet mehiã o · FDA agbalẽ me nu $count · $date',
      ha: 'Ba ya bukatar internet · rijistar FDA $count kaya · $date');
  static String get recentChecks => _l('Recent checks',
      tw: 'Nea woahwɛ',
      ee: 'Nu siwo nèkpɔ',
      dag: 'A ni vihimi shɛli',
      ha: 'Abin da ka duba');
  static String get seeAll =>
      _l('See all', tw: 'Hwɛ ne nyinaa', ee: 'Kpɔ wo katã', ha: 'Duba duka');
  static String get nothingChecked => _l(
      'Nothing checked yet. Scan your first medicine and the verdict lands here.',
      tw: 'Wonhwɛɛ hwee ɛ. Hwɛ w’aduro a edi kan na mmuae no bɛba ha.',
      ee: 'Mèkpɔ naneke haɖe o. Kpɔ wò atike gbãtɔ eye ŋuɖoɖo la ava afi sia.',
      ha: 'Ba ka duba komai ba tukuna. Duba maganin farko, amsar za ta zo nan.');
  static String get unnamedPack =>
      _l('Unnamed pack', tw: 'Adaka a enni din', ha: 'Akwati mara suna');
  static String get justNow =>
      _l('Just now', tw: 'Seesei ara', ee: 'Fifi laa', ha: 'Yanzu yanzu');
  static String minAgo(int m) =>
      _l('$m min ago', tw: 'Simma $m atwam', ha: 'Minti $m da suka wuce');
  static String hAgo(int h) =>
      _l('$h h ago', tw: 'Nnɔnhwerew $h atwam', ha: 'Awa $h da suka wuce');
  static String get yesterday =>
      _l('Yesterday', tw: 'Nnɛra', ee: 'Etsɔ si va yi', ha: 'Jiya');

  // ── Scan & result ─────────────────────────────────────────────────────
  static String get resultTitle =>
      _l('Result', tw: 'Mmuae', ee: 'Ŋuɖoɖo', dag: 'Labari', ha: 'Amsa');
  static String get useThisPhoto => _l('Use this photo?',
      tw: 'Fa mfonini yi?', ee: 'Zã foto sia?', ha: 'A yi amfani da wannan hoto?');
  static String get retake =>
      _l('Retake', tw: 'Twa bio', ee: 'Ɖae ake', ha: 'Sake ɗauka');
  static String get checkIt =>
      _l('Check it', tw: 'Hwɛ', ee: 'Kpɔe', dag: 'Vihimi', ha: 'Duba shi');
  static String get tryAgain =>
      _l('Try again', tw: 'Sɔ hwɛ bio', ee: 'Te ekpɔ ake', ha: 'Sake gwadawa');
  static String get scanAgain =>
      _l('Scan again', tw: 'Hwɛ bio', ee: 'Kpɔe ake', ha: 'Duba kuma');
  static String get scanAnother => _l('Scan another medicine',
      tw: 'Hwɛ aduro foforo',
      ee: 'Kpɔ atike bubu',
      dag: 'Vihimi tim din',
      ha: 'Duba wani magani');
  static String get readingPack => _l('Reading the pack…',
      tw: 'Yɛrekenkan adaka no so…',
      ee: 'Míele aɖaka la xlẽm…',
      ha: 'Ana karanta akwatin…');
  static String get checkingRegister => _l('Checking the register…',
      tw: 'Yɛrehwɛ FDA nhoma no mu…',
      ee: 'Míele FDA agbalẽ la me kpɔm…',
      ha: 'Ana duba rijistar…');
  static String get allOnPhone => _l(
      'Everything runs on this phone. No internet needed.',
      tw: 'Biribiara yɛ adwuma wɔ phone yi so. Internet ho nhia.',
      ee: 'Nusianu wɔa dɔ le phone sia dzi. Internet mehiã o.',
      ha: 'Komai yana aiki a wannan wayar. Ba a bukatar internet.');
  static String get cameraOff => _l(
      'Camera permission is off. Allow it in Settings, or pick a photo instead.',
      tw: 'Camera kwan no nna hɔ. Kɔ Nhyehyɛe mu na bue no, anaa fa mfonini bi.',
      ha: 'Ba a ba da izinin kyamara ba. Bude shi a Saituna, ko ka zaɓi hoto.');
  static String get noCamera => _l(
      'No camera on this device. Pick a photo of the pack instead.',
      tw: 'Camera nni phone yi so. Fa adaka no mfonini bi.',
      ha: 'Babu kyamara a wannan na’urar. Zaɓi hoton akwatin.');
  static String get photoFailed => _l('The photo failed. Try again.',
      tw: 'Mfonini no anyɛ yiye. Sɔ hwɛ bio.',
      ha: 'Hoton bai yi ba. Sake gwadawa.');
  static String get pickFromPhotos => _l('Pick from photos',
      tw: 'Fa fi mfonini mu', ee: 'Tia tso foto siwo li me', ha: 'Zaɓi daga hotuna');
  static String get takePhoto => _l('Take photo',
      tw: 'Twa mfonini', ee: 'Ɖa foto', dag: 'Ŋmali foto', ha: 'Ɗauki hoto');
  static String get tipsTitle => _l('Tips for a clear read',
      tw: 'Nea ɛbɛma yɛahu no yiye',
      ee: 'Nu siwo akpe ɖe eŋu be woaxlẽe nyuie',
      ha: 'Shawarwari don karatu mai kyau');
  static String get tips => _l(
      '• Move to brighter light. Daylight works best.\n'
      '• Fill the frame with the front of the pack.\n'
      '• Hold still until the photo is sharp.',
      tw: '• Kɔ baabi a hann wɔ. Awia hann yɛ pa ara.\n'
          '• Ma adaka no anim nyinaa nna mfonini no mu.\n'
          '• Gyina hɔ dinn na mfonini no anyɛ basaa.',
      ha: '• Je wurin da haske yake. Hasken rana ya fi kyau.\n'
          '• Sa gaban akwatin ya cika hoton.\n'
          '• Tsaya cak har hoton ya fito sarai.');
  static String get modelNotSetUp => _l(
      'The offline model is not set up yet. Download it in Settings, then scan again.',
      tw: 'Wonnya nhyehyɛɛ offline model no ɛ. Twe no wɔ Nhyehyɛe mu ansa.',
      ha: 'Ba a shirya model ɗin ba tukuna. Sauke shi a Saituna, sannan ka sake dubawa.');
  static String get somethingWrong => _l(
      'Something went wrong while checking. Try again.',
      tw: 'Biribi ansi yiye wɔ nhwehwɛ no mu. Sɔ hwɛ bio.',
      ha: 'Wani abu ya ɓaci yayin dubawa. Sake gwadawa.');

  // ── Verdict headlines ─────────────────────────────────────────────────
  static String get vRegistered => _l('In the register',
      tw: 'Ɛwɔ FDA nhoma no mu',
      ee: 'Ele FDA agbalẽ la me',
      dag: 'Di be FDA gbaŋ ni',
      ha: 'Yana cikin rijista');
  static String get vExpired => _l('Expired',
      tw: 'Ne bere atwam', ee: 'Eƒe ɣeyiɣi va yi', dag: 'Di saha gari', ha: 'Ya kare');
  static String get vRecalled => _l('Do not take this',
      tw: 'Nnom aduro yi',
      ee: 'Mègano atike sia o',
      dag: 'Di nyu tim ŋɔ',
      ha: 'Kada ka sha wannan');
  static String get vCaution => _l('Check this carefully',
      tw: 'Hwɛ yei yiye',
      ee: 'Lé ŋku ɖe esia ŋu nyuie',
      dag: 'Vihimi ŋɔ viɛnyla',
      ha: 'Duba wannan da kyau');
  static String get vNotFound => _l('Not in the register snapshot',
      tw: 'Enni FDA nhoma yi mu',
      ee: 'Mele FDA agbalẽ sia me o',
      ha: 'Ba ya cikin wannan rijistar');
  static String get vUnreadable => _l('Couldn’t read the pack',
      tw: 'Yantumi ankenkan adaka no so',
      ee: 'Míete ŋu xlẽ aɖaka la o',
      ha: 'Ba a iya karanta akwatin ba');
  static String get vChecked =>
      _l('Checked', tw: 'Yɛahwɛ', ee: 'Wokpɔe', ha: 'An duba');

  // ── Verdict reasons (localized; the engine's English list stays the
  //    canonical record) ────────────────────────────────────────────────
  static String get rUnreadable => _l(
      'The photo could not be read. Try more light and hold steady.',
      tw: 'Yantumi ankenkan mfonini no. Kɔ hann mu na gyina dinn.',
      ee: 'Womete ŋu xlẽ foto la o. Di kekeli wu eye nàlé asi ɖe eŋu goŋgoŋ.',
      ha: 'Ba a iya karanta hoton ba. Nemi karin haske ka kuma tsaya cak.');
  static String rRecalled(String name) => _l(
      'This product matches an FDA Ghana recall or safety alert: $name.',
      tw: 'Aduro yi ne nea FDA Ghana afrɛ no asan anaa abɔ ho kɔkɔ no hyia: $name.',
      ee: 'Atike sia sɔ kple esi FDA Ghana he ɖe megbe alo ƒo nu tso eŋu: $name.',
      ha: 'Wannan kayan ya yi daidai da wanda FDA Ghana ta janye ko ta yi gargaɗi a kai: $name.');
  static String get rRecalledAction => _l(
      'Do not take it. Report to the FDA on 0551112224 (WhatsApp) or return it to the pharmacy.',
      tw: 'Nnom. Bɔ FDA amanneɛ wɔ 0551112224 (WhatsApp) so, anaa san fa kɔ pharmacy no.',
      ee: 'Mèganoe o. Ka nya na FDA le 0551112224 (WhatsApp) dzi alo trɔe yi pharmacy la.',
      ha: 'Kada ka sha. Kai rahoto ga FDA a 0551112224 (WhatsApp) ko ka mayar da shi kantin magani.');
  static String rExpired(String monthYear) => _l(
      'The pack shows an expiry of $monthYear. That date has passed.',
      tw: 'Adaka no kyerɛ sɛ ne bere yɛ $monthYear. Saa bere no atwam.',
      ee: 'Aɖaka la fia be eƒe ɣeyiɣi enye $monthYear. Ŋkeke ma va yi xoxo.',
      ha: 'Akwatin ya nuna ranar karewa $monthYear. Wannan ranar ta wuce.');
  static String rExpiredButListed(String name) => _l(
      'The product itself ($name) is in the register snapshot, but this pack is expired.',
      tw: 'Aduro no ankasa ($name) wɔ FDA nhoma no mu, nanso adaka yi de, ne bere atwam.',
      ee: 'Atike la ŋutɔ ($name) le FDA agbalẽ la me, gake aɖaka sia ƒe ɣeyiɣi va yi.',
      ha: 'Kayan da kansa ($name) yana cikin rijistar, amma wannan akwatin ya kare.');
  static String get rExpiredAction => _l(
      'Expired medicine can be weak or unsafe. Do not take it.',
      tw: 'Aduro a ne bere atwam betumi ayɛ mmerɛw anaa ɛho nni banbɔ. Nnom.',
      ee: 'Atike si ƒe ɣeyiɣi va yi ate ŋu agbɔdzɔ alo mavɔ̃ɖi o. Mèganoe o.',
      ha: 'Maganin da ya kare zai iya raunana ko ya zama mara aminci. Kada ka sha.');
  static String rFoundAs(String name, String maker) => _l(
      maker.isEmpty
          ? 'Found in the register snapshot as “$name”.'
          : 'Found in the register snapshot as “$name” by $maker.',
      tw: maker.isEmpty
          ? 'Yehuu no wɔ FDA nhoma no mu sɛ “$name”.'
          : 'Yehuu no wɔ FDA nhoma no mu sɛ “$name” a $maker na ɔyɛe.',
      ee: maker.isEmpty
          ? 'Wokpɔe le FDA agbalẽ la me be enye “$name”.'
          : 'Wokpɔe le FDA agbalẽ la me be enye “$name” si $maker wɔ.',
      ha: maker.isEmpty
          ? 'An same shi a rijistar da suna “$name”.'
          : 'An same shi a rijistar da suna “$name” wanda $maker ya kera.');
  static String rStillInDate(String monthYear) => _l(
      'Expiry $monthYear, still in date.',
      tw: 'Ne bere yɛ $monthYear; ennya ntwamee.',
      ee: 'Eƒe ɣeyiɣi enye $monthYear; meva yi haɖe o.',
      ha: 'Ranar karewa $monthYear, bai kare ba tukuna.');
  static String get rNoExpiryRead => _l(
      'No expiry date was read from the pack. Check it yourself before use.',
      tw: 'Yanhu ne bere wɔ adaka no so. Hwɛ no wo ara ansa na woanom.',
      ee: 'Womexlẽ ɣeyiɣi si wòava yi le aɖaka la dzi o. Kpɔe ɖokuiwò hafi nàzãe.',
      ha: 'Ba a ga ranar karewa a akwatin ba. Ka duba da kanka kafin amfani.');
  static String rCloseName(String read, String listed) => _l(
      'The name read as “$read”, which is close to “$listed” in the register, but not an exact match.',
      tw: 'Din a yehui ne “$read”. Ɛbɛn “$listed” a ɛwɔ FDA nhoma no mu, nanso ɛnyɛ no pɛpɛɛpɛ.',
      ee: 'Ŋkɔ si woxlẽ enye “$read”. Ete ɖe “$listed” si le FDA agbalẽ la me ŋu, gake mesɔ pɛpɛpɛ o.',
      ha: 'Sunan da aka karanta shi ne “$read”. Yana kusa da “$listed” a rijistar, amma ba daidai suke ba sosai.');
  static String get rSpellingTrick => _l(
      'Check the spelling on the pack carefully. Small name changes are a known counterfeit trick.',
      tw: 'Hwɛ nkyerɛwee a ɛwɔ adaka no so yiye. Din mu nsakrae nketenkete yɛ aduro a wɔabɔ ho dawuru no nsusuwii.',
      ee: 'Lé ŋku ɖe ŋɔŋlɔ si le aɖaka la dzi ŋu nyuie. Ŋkɔ ƒe tɔtrɔ suesuewo nye aʋatsotike ƒe dzesi.',
      ha: 'Duba rubutun da ke akwatin da kyau. Sauya sunan kadan dabara ce ta magungunan jabu.');
  static String rRegMismatch(String name, String packReg, String listedReg) =>
      _l(
          'The name matches “$name” in the register, but the pack prints registration number $packReg while the register lists $listedReg for that product.',
          tw: 'Din no ne “$name” a ɛwɔ FDA nhoma no mu hyia, nanso adaka no so registration number yɛ $packReg; nea ɛwɔ nhoma no mu ne $listedReg.',
          ee: 'Ŋkɔ la sɔ kple “$name” si le FDA agbalẽ la me, gake registration number si le aɖaka la dzi enye $packReg; esi le agbalẽ la me enye $listedReg.',
          ha: 'Sunan ya yi daidai da “$name” a rijistar, amma akwatin yana ɗauke da lambar rijista $packReg yayin da rijistar ke da $listedReg.');
  static String get rRegDriftHint => _l(
      'The two numbers differ only slightly, so the camera may simply have misread the small print. Rescan the number up close to be sure.',
      tw: 'Nsonoe a ɛda nɔma abien no ntam sua koraa; ebia camera no ankenkan nkyerɛwee nketewa no yiye. Twa nɔma no mfonini bio wɔ bɛn mu na woahu yiye.',
      ha: 'Bambancin lambobin biyu kadan ne, watakila kyamarar ce ba ta karanta karamin rubutu daidai ba. Sake dauka kusa-kusa don tabbatarwa.');
  static String get rRegCounterfeitHint => _l(
      'A registration number that does not match the register is a known counterfeit sign. It can also mean this particular variant is no longer registered.',
      tw: 'Registration number a ɛne nhoma no mu de nhyia yɛ aduro a wɔabɔ ho dawuru ho nsɛnkyerɛnne. Ebetumi nso akyerɛ sɛ saa aduro yi ankasa registration no atwam.',
      ha: 'Lambar rijista da ba ta dace da rijistar ba alama ce ta jabu. Kuma yana iya nufin cewa wannan nau’in ba a sake rijistarsa ba.');
  static String get rVerifyFda => _l(
      'Verify with your pharmacist or the FDA (0551112224 on WhatsApp) before use.',
      tw: 'Bisa wo pharmacist anaa FDA (0551112224 wɔ WhatsApp so) ansa na woanom.',
      ee: 'Bia wò pharmacist alo FDA (0551112224 le WhatsApp dzi) hafi nàzãe.',
      ha: 'Tabbatar daga likitan magani ko FDA (0551112224 a WhatsApp) kafin amfani.');
  static String rNotFound(String read) => _l(
      '“$read” was not found in this offline register snapshot.',
      tw: 'Yanhu “$read” wɔ FDA nhoma a ɛwɔ phone yi so no mu.',
      ee: 'Womekpɔ “$read” le FDA agbalẽ si le phone sia dzi me o.',
      ha: 'Ba a sami “$read” a cikin rijistar da ke wannan wayar ba.');
  static String get rNotProofFake => _l(
      'That does not prove it is fake, but treat it with caution.',
      tw: 'Ɛno nkyerɛ sɛ ɛyɛ atoro aduro, nanso fa ahwɛyiye di ho dwuma.',
      ee: 'Ema mefia be aʋatsotike wònye o, gake lé ŋku ɖe eŋu nyuie.',
      ha: 'Wannan bai tabbatar da cewa jabu ne ba, amma ka yi taka tsantsan.');

  // ── Facts & sections ──────────────────────────────────────────────────
  static String get whatPackSays => _l('What the pack says',
      tw: 'Nea ɛwɔ adaka no so',
      ee: 'Nu si le aɖaka la dzi',
      dag: 'Din be adaka ŋɔ ni',
      ha: 'Abin da ke akwatin');
  static String get whatPackSaid => _l('What the pack said',
      tw: 'Nea na ɛwɔ adaka no so',
      ee: 'Nu si nɔ aɖaka la dzi',
      ha: 'Abin da ke akwatin');
  static String get product => _l('Product',
      tw: 'Aduro', ee: 'Atike', dag: 'Tim', ha: 'Magani');
  static String get madeBy => _l('Made by',
      tw: 'Nea ɔyɛe', ee: 'Ame si wɔe', ha: 'Wanda ya kera');
  static String get batch =>
      _l('Batch', tw: 'Batch', ee: 'Batch', ha: 'Batch');
  static String get expiry => _l('Expiry',
      tw: 'Ne bere', ee: 'Eƒe ɣeyiɣi', dag: 'Saha', ha: 'Ranar karewa');
  static String get fdaNumber => _l('FDA number',
      tw: 'FDA nɔma', ee: 'FDA xexlẽdzesi', ha: 'Lambar FDA');
  static String get whatThisMeans => _l('What this means',
      tw: 'Nea ɛkyerɛ',
      ee: 'Nu si wòfia',
      dag: 'Din ŋɔ wuhi',
      ha: 'Abin da wannan ke nufi');
  static String get puttingPlainWords => _l('Putting it in plain words…',
      tw: 'Yɛrekyerɛ mu…', ee: 'Míele eme ɖem…', ha: 'Ana bayyana shi a sauƙaƙe…');
  static String get readAloud => _l('Read aloud',
      tw: 'Kenkan ma me', ee: 'Xlẽe nam', dag: 'Karimi ma', ha: 'Karanta da murya');
  static String get stopReading =>
      _l('Stop', tw: 'Gyae', ee: 'Tɔ', dag: 'Chɛli', ha: 'Tsaya');
  static String get preparingVoice => _l('Getting the voice ready…',
      tw: 'Yɛresiesie nne no…',
      ee: 'Míele gbe la dzram ɖo…',
      ha: 'Ana shirya muryar…');
  static String get guidanceUnavailable => _l(
      'Guidance is unavailable right now. The verdict above still stands.',
      tw: 'Akwankyerɛ no nni hɔ seesei. Mmuae a ɛwɔ soro no da so yɛ nokware.',
      ha: 'Jagora ba ta samuwa yanzu. Amsar da ke sama tana nan daram.');
  static String downloadVoiceHint(String language) => _l(
      'Download the $language voice in Settings to hear this aloud.',
      tw: 'Twe $language nne no wɔ Nhyehyɛe mu na woate.',
      ee: 'He $language gbe la le Ɖoɖowo me be nàsee.',
      ha: 'Sauke muryar $language a Saituna don jin wannan.');
  static String voiceRoadmap(String language) => _l(
      'A $language voice is on the roadmap.',
      tw: '$language nne no bɛba akyiri yi.',
      ha: 'Muryar $language na zuwa nan gaba.');

  // ── Follow-up ─────────────────────────────────────────────────────────
  static String get askAboutPack => _l('Ask about this pack',
      tw: 'Bisa biribi fa aduro yi ho',
      ee: 'Bia nya tso aɖaka sia ŋu',
      dag: 'Bɔhi tim ŋɔ yɛla',
      ha: 'Tambaya game da wannan akwatin');
  static String get answersFromPack => _l(
      'Answers come only from what the pack itself says.',
      tw: 'Mmuae no fi nea ɛwɔ adaka no so nko ara.',
      ee: 'Ŋuɖoɖoawo tso nu si le aɖaka la ŋutɔ dzi ko me.',
      ha: 'Amsoshi na zuwa daga abin da ke akwatin kawai.');
  static String get typeQuestion => _l('Type a question…',
      tw: 'Kyerɛw asɛmmisa…', ee: 'Ŋlɔ biabia…', ha: 'Rubuta tambaya…');
  static String get send =>
      _l('Send', tw: 'Soma', ee: 'Ɖoe ɖa', ha: 'Aika');
  static String get holdAndSpeak => _l(
      'Hold the gold button and speak your question.',
      tw: 'Mia button no so na kasa.',
      ee: 'Lé button la ɖe te eye nàƒo nu.',
      ha: 'Rike maballin zinariya ka yi magana.');
  static String get listeningLetGo => _l('Listening… let go to send.',
      tw: 'Yɛretie… gyae na ɛnkɔ.',
      ee: 'Míele to ɖom… ɖe asi le eŋu be wòaɖo ɖa.',
      ha: 'Ana saurara… saki don aikawa.');
  static String get listeningToPack => _l('Listening to the pack…',
      tw: 'Yɛrehwɛ adaka no so…', ha: 'Ana duban akwatin…');
  static String get spokenQuestion => _l('Spoken question',
      tw: 'Asɛmmisa a wokae', ee: 'Biabia si nègblɔ', ha: 'Tambayar da ka faɗa');
  static String get askFailed => _l('That didn’t work. Ask again.',
      tw: 'Ɛno anyɛ yiye. Bisa bio.',
      ee: 'Mewɔ dɔ o. Bia ake.',
      ha: 'Wannan bai yi ba. Sake tambaya.');
  static String get holdToRecordHint => _l(
      'Hold to record a spoken question',
      tw: 'Mia so na woaka asɛmmisa',
      ha: 'Rike don yin rikodin tambaya');

  // ── Settings ──────────────────────────────────────────────────────────
  static String get settings => _l('Settings',
      tw: 'Nhyehyɛe', ee: 'Ɖoɖowo', dag: 'Shiriya', ha: 'Saituna');
  static String get language =>
      _l('Language', tw: 'Kasa', ee: 'Gbe', dag: 'Yɛltɔɣa', ha: 'Harshe');
  static String get earlySupport => _l('Early support',
      tw: 'Mfiase kwan so', ee: 'Gɔmedzedze', ha: 'Tallafi na farko');
  static String get appearance => _l('Appearance',
      tw: 'Ɔyɛbea', ee: 'Dzedzeme', ha: 'Kamanni');
  static String get matchPhone => _l('Match the phone',
      tw: 'Di phone no akyi', ee: 'Sɔ kple phone la', ha: 'Bi wayar');
  static String get light =>
      _l('Light', tw: 'Hann', ee: 'Kekeli', ha: 'Haske');
  static String get dark =>
      _l('Dark', tw: 'Sum', ee: 'Viviti', ha: 'Duhu');
  static String get offlineBrain => _l('Offline brain',
      tw: 'Adwene a internet ho nhia',
      ee: 'Susu si mehiã internet o',
      ha: 'Kwakwalwa mara internet');
  static String get offlineBrainBlurb => _l(
      'Gemma 4 runs entirely on this phone. Download once on Wi-Fi; scanning then needs no internet at all.',
      tw: 'Gemma 4 yɛ adwuma wɔ phone yi so. Twe no pɛnkoro wɔ Wi-Fi so; ɛno akyi internet ho nhia koraa.',
      ha: 'Gemma 4 yana aiki a wannan wayar kacokan. Sauke sau ɗaya a Wi-Fi; bayan haka ba a bukatar internet ko kadan.');
  static String get e2bBlurb => _l(
      'Recommended. Runs on phones with 4–6 GB memory.',
      tw: 'Yɛkamfo yei. Ɛyɛ adwuma wɔ phone a ne memory yɛ 4–6 GB so.',
      ha: 'Wanda aka ba da shawara. Yana aiki a wayoyi masu memory 4–6 GB.');
  static String get e4bBlurb => _l(
      'Stronger reading on hard packs. Needs 8 GB memory.',
      tw: 'Ɛkenkan adaka a emu yɛ den no yiye. Ɛhia memory 8 GB.',
      ha: 'Karatu mafi ƙarfi a akwatuna masu wuya. Yana bukatar memory 8 GB.');
  static String get voices => _l('Voices',
      tw: 'Nne ahorow', ee: 'Gbeawo', ha: 'Muryoyi');
  static String get voicesBlurb => _l(
      'Optional offline voices so guidance can be read aloud in local languages. Each is a one-time download.',
      tw: 'Twe nne no na yɛakenkan akwankyerɛ no wɔ wo kasa mu. Wutwe no pɛnkoro pɛ.',
      ha: 'Muryoyin da za ka iya saukewa don a karanta jagora a harsunan gida. Kowanne saukewa sau ɗaya ne.');
  static String voiceName(String language) => _l('$language voice',
      tw: '$language nne', ee: '$language gbe', ha: 'Muryar $language');
  static String voiceBlurb(String language) => _l(
      'Reads $language guidance aloud, offline.',
      tw: 'Ɛkenkan $language akwankyerɛ, internet ho nhia.',
      ha: 'Yana karanta jagorar $language, ba tare da internet ba.');
  static String get download =>
      _l('Download', tw: 'Twe', ee: 'Hee', dag: 'Deemi', ha: 'Sauke');
  static String get remove =>
      _l('Remove', tw: 'Yi fi hɔ', ee: 'Ɖee ɖa', ha: 'Cire');
  static String get installed =>
      _l('Installed', tw: 'Ɛwɔ hɔ', ee: 'Ele afi ma', ha: 'An sauke');
  static String get importFile => _l('Import file',
      tw: 'Fa fael no bra', ee: 'Tsɔ fael la vɛ', ha: 'Shigo da fayil');
  static String downloading(int p) => _l('Downloading… $p%',
      tw: 'Ɛretwe… $p%', ee: 'Ele hehem… $p%', ha: 'Ana saukewa… $p%');
  static String downloadingModel(String name, int p) => _l(
      'Downloading $name · $p%',
      tw: 'Ɛretwe $name · $p%',
      ha: 'Ana sauke $name · $p%');
  static String get downloadStopped => _l(
      'The download stopped. Check your connection and retry.',
      tw: 'Twe no agyae. Hwɛ wo network na sɔ hwɛ bio.',
      ha: 'Saukewar ta tsaya. Duba haɗin ka ka sake gwadawa.');
  static String get importFailed => _l('That file could not be imported.',
      tw: 'Yantumi amfa fael no amma.',
      ha: 'Ba a iya shigo da wannan fayil ɗin ba.');
  static String get notSeenOnPack => _l('The camera did not see:',
      tw: 'Camera no anhu:',
      ee: 'Camera la mekpɔ esiawo o:',
      ha: 'Kyamarar ba ta ga:');
  static String get fromRegisterTag => _l('register',
      tw: 'nhoma mu', ee: 'agbalẽ me', ha: 'rijista');
  static String get managePhotos => _l('Change selected photos',
      tw: 'Sesa mfonini a woayi no',
      ha: 'Canza hotunan da ka zaɓa');
  static String get allowPhotosHint => _l(
      'Allow photo access to pick a pack photo. Choosing "Select photos" keeps it to just your medicine photos.',
      tw: 'Ma kwan ma mfonini na woayi adaka no mfonini. "Select photos" ma wohu w\'aduro mfonini nko ara.',
      ha: 'Ba da izinin hotuna don zaɓar hoton akwatin. "Select photos" na nuna hotunan maganinka kawai.');
  static String get noPhotosYet => _l(
      'No photos selected yet. Use the manage button above to choose your medicine photos.',
      tw: 'Wonyii mfonini biara ɛ. Fa button a ɛwɔ soro no yi w\'aduro mfonini.',
      ha: 'Ba a zaɓi hotuna ba tukuna. Yi amfani da maballin da ke sama don zaɓar hotunan maganinka.');
  static String get packPhoto => _l('Pack photo',
      tw: 'Aduro no mfonini', ee: 'Aɖaka la ƒe foto', ha: 'Hoton akwatin');
  static String get addAnotherSide => _l('Add a photo of another side',
      tw: 'Fa ɔfa foforo mfonini ka ho',
      ee: 'Tsɔ akpa bubu ƒe foto kpe ɖe eŋu',
      ha: 'Kara hoton wani gefen');
  static String get sideFailed => _l(
      'That side could not be read. The first result is unchanged.',
      tw: 'Yantumi ankenkan saa ɔfa no. Nea edi kan no da hɔ.',
      ha: 'Ba a iya karanta wannan gefen ba. Sakamakon farko bai canza ba.');
  static String get preparingFile => _l(
      'Getting the file ready. This can take a minute.',
      tw: 'Yɛresiesie fael no. Ebetumi agye bere kakra.',
      ha: 'Ana shirya fayil ɗin. Zai iya ɗaukar minti guda.');
  static String get about =>
      _l('About', tw: 'Ɛfa ho', ee: 'Tso eŋu', ha: 'Game da shi');
  static String snapshotLine(int count, String date) => _l(
      'Register snapshot: $count products · $date',
      tw: 'FDA nhoma mu nneɛma: $count · $date',
      ha: 'Rijistar FDA: kaya $count · $date');
  static String get disclaimer => _l(
      'Aduro Guard is a verification aid, not medical advice. For any health decision, talk to a pharmacist, a clinic, or the FDA on 0551112224 (WhatsApp).',
      tw: 'Aduro Guard boa wo ma wohwɛ aduro; ɛnyɛ ayaresa afotu. Apɔmuden asɛm biara ho no, kɔhwɛ pharmacist, clinic, anaa FDA wɔ 0551112224 (WhatsApp) so.',
      ha: 'Aduro Guard mataimaki ne na tantancewa, ba shawarar likita ba. Don kowane shawarar lafiya, tuntuɓi likitan magani, asibiti, ko FDA a 0551112224 (WhatsApp).');

  // ── Onboarding ────────────────────────────────────────────────────────
  static String get welcomeBlurb => _l(
      'Point your camera at any medicine pack. It gets checked against the Ghana FDA register, right here on your phone, no internet needed.',
      tw: 'Fa wo camera kyerɛ aduro adaka biara so. Yɛde bɛtoto Ghana FDA nhoma no ho wɔ wo phone yi ara so; internet ho nhia.',
      ee: 'Trɔ wò camera ɖe atike ƒe aɖaka ɖesiaɖe ŋu. Wotsɔnɛ sɔna kple Ghana FDA ƒe agbalẽ le wò phone sia dzi; internet mehiã o.',
      ha: 'Nuna kyamararka ga kowane akwatin magani. Ana duba shi da rijistar FDA ta Ghana, a nan wayarka, ba tare da internet ba.');
  static String get chooseLanguage => _l('Choose your language',
      tw: 'Yi wo kasa',
      ee: 'Tia wò gbe',
      dag: 'Piimi a yɛltɔɣa',
      ha: 'Zaɓi harshenka');
  static String get continueLabel => _l('Continue',
      tw: 'Kɔ so', ee: 'Yi edzi', dag: 'Chaŋmi', ha: 'Ci gaba');
  static String get setupBrainTitle => _l('Set up the offline brain',
      tw: 'Siesie adwene a internet ho nhia no',
      ha: 'Shirya kwakwalwar mara internet');
  static String setupBrainBlurb(String size) => _l(
      'Aduro Guard reads packs with Gemma 4, a model that lives on your phone. One download of $size, best on Wi-Fi, and every scan after that works with no signal at all.',
      tw: 'Aduro Guard de Gemma 4 na ɛkenkan aduro adaka; ɛte wo phone yi so. Twe $size pɛnkoro (Wi-Fi so ye), na ɛno akyi biribiara yɛ adwuma a signal nnim.',
      ha: 'Aduro Guard yana karanta akwatuna da Gemma 4, model da ke zaune a wayarka. Saukewa ɗaya na $size, mafi kyau a Wi-Fi, sannan kowace dubawa tana aiki ba tare da siginar komai ba.');
  static String downloadSize(String size) => _l('Download · $size',
      tw: 'Twe · $size', ee: 'Hee · $size', ha: 'Sauke · $size');
  static String get alreadyHaveFile => _l('I already have the file',
      tw: 'Mewɔ fael no dedaw',
      ee: 'Fael la le asinye xoxo',
      ha: 'Ina da fayil ɗin tuni');
  static String get setUpLater => _l('Set up later',
      tw: 'Yɛ no akyiri yi', ee: 'Wɔe emegbe', ha: 'Shirya daga baya');
  static String e4bNote(String size) => _l(
      'This is the version sized for everyday phones. A stronger $size version for 8 GB phones lives in Settings whenever you want it.',
      tw: 'Yei ne nea ɛfata phone a yɛde di dwuma daa. Nea ɛyɛ den a ɛyɛ $size ma phone a ne memory yɛ 8 GB no wɔ Nhyehyɛe mu bere biara.',
      ha: 'Wannan shi ne wanda ya dace da wayoyin yau da kullum. Mafi ƙarfi na $size don wayoyi masu 8 GB yana a Saituna duk lokacin da kake so.');
  static String get downloadStoppedRetryImport => _l(
      'The download stopped. Check your connection and try again, or import the file if you already have it.',
      tw: 'Twe no agyae. Hwɛ wo network na sɔ hwɛ bio, anaa fa fael no bra sɛ wowɔ bi dedaw a.',
      ha: 'Saukewar ta tsaya. Duba haɗin ka ka sake gwadawa, ko ka shigo da fayil ɗin idan kana da shi tuni.');

  // ── History ───────────────────────────────────────────────────────────
  static String get allChecks => _l('All checks',
      tw: 'Nea woahwɛ nyinaa', ee: 'Nu siwo nèkpɔ katã', ha: 'Duk abin da ka duba');
  static String get noChecksYet => _l('No checks yet.',
      tw: 'Wonhwɛɛ hwee ɛ.', ee: 'Mèkpɔ naneke haɖe o.', ha: 'Ba a duba komai ba tukuna.');
  static String get savedCheck => _l('Saved check',
      tw: 'Nea woahwɛ', ee: 'Nu si nèkpɔ', ha: 'Abin da aka ajiye');
  static String get guidanceGiven => _l('Guidance given',
      tw: 'Akwankyerɛ a wonyae', ee: 'Mɔfiafia si wona', ha: 'Jagorar da aka bayar');
  static String get deleteCheckQ => _l('Delete this check?',
      tw: 'Yi eyi mfi hɔ?', ee: 'Àtutu esia?', ha: 'A goge wannan?');
  static String get deleteBody => _l('This only removes the saved record.',
      tw: 'Eyi yi nea wɔakora so no nko ara.',
      ha: 'Wannan yana cire bayanan da aka ajiye kawai.');
  static String get keepIt => _l('Keep it',
      tw: 'Gyae ma ɛnna hɔ', ee: 'Gblẽe ɖi', ha: 'Bar shi');
  static String get delete =>
      _l('Delete', tw: 'Yi fi hɔ', ee: 'Tutui', ha: 'Goge');
  static String checkedOn(String date) => _l('Checked $date',
      tw: 'Yɛhwɛe $date', ee: 'Wokpɔe $date', ha: 'An duba $date');
}
