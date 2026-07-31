/// The languages Aduro Guard speaks, in one place: pickers, Gemma prompts,
/// and offline voices all read from this catalog.
class Lang {
  final String code; // stored in prefs
  final String name; // English label
  final String endonym; // the language's own name for itself (picker label)
  final String? nativeLine; // subtitle written in the language itself
  final String promptLine; // instruction for Gemma
  final String? exemplar; // few-shot tone example for counseling
  final bool early; // output quality still maturing; labelled in the UI
  final String? mmsCode; // MMS voice id for offline TTS; null = no voice yet

  /// Whether Gemma 4 E2B can actually hold this language for counseling.
  /// Measured on device (Galaxy S24, 2026-07-30): English, Twi and Hausa
  /// come back in-language; Ewe and Dagbani come back in English every time,
  /// so asking costs 15 seconds and returns text under the wrong heading.
  /// Those two read from lib/services/counseling.dart instead. Flip this on
  /// again when a stronger model (E4B) or better exemplars change the result.
  final bool counselFromModel;

  const Lang({
    required this.code,
    required this.name,
    required this.endonym,
    this.nativeLine,
    required this.promptLine,
    this.exemplar,
    this.early = false,
    this.mmsCode,
    this.counselFromModel = true,
  });
}

const langs = [
  Lang(
    code: 'en',
    name: 'English',
    endonym: 'English',
    nativeLine: 'Use the app in English',
    promptLine: 'Write in plain everyday English.',
    exemplar:
        'Example of the tone (this one is for a registered, in-date pack):\n"This pack is in the FDA register and its expiry date has not passed. Take it exactly as the pack instructs. Store it below 30°C, away from children. If you do not feel better, talk to a pharmacist or clinic."',
  ),
  Lang(
    code: 'tw',
    name: 'Twi',
    endonym: 'Twi',
    nativeLine: 'Fa Twi kasa di dwuma',
    promptLine:
        'Write in everyday Asante Twi as spoken in Ghana. Keep medicine names, numbers and "FDA" in English.',
    exemplar:
        'Example of the tone for Twi (this one is for a registered, in-date pack):\n"Saa Coartem yi wɔ FDA nhoma no mu, na ne bere nntwaam ɛ. Fa no sɛnea wɔakyerɛ wɔ adaka no so pɛpɛɛpɛ. Fa sie baabi a ɛnyɛ hyew, na mma mmofra nsa nnka. Sɛ wonte nka yiye wɔ akyi a, kɔhwɛ pharmacist anaa clinic."',
    mmsCode: 'aka',
  ),
  Lang(
    code: 'ee',
    name: 'Ewe',
    endonym: 'Eʋegbe',
    promptLine:
        "Write in everyday Ewe as spoken in Ghana's Volta Region. Keep medicine names, numbers and \"FDA\" in English. Use short simple sentences.",
    early: true,
    mmsCode: 'ewe',
    counselFromModel: false,
  ),
  Lang(
    code: 'ga',
    name: 'Ga',
    endonym: 'Gã',
    nativeLine: 'Kɛ Gã tsu nii',
    promptLine:
        'Write in everyday Ga as spoken in Accra. Keep medicine names, numbers and "FDA" in English. Use short simple sentences.',
    early: true,
    // No published MMS voice for Ga (gaa 404s on the ONNX repo), and the
    // model cannot hold Ga; counseling reads lib/services/counseling.dart.
    counselFromModel: false,
  ),
  Lang(
    code: 'dag',
    name: 'Dagbani',
    endonym: 'Dagbanli',
    promptLine:
        'Write in everyday Dagbani as spoken in northern Ghana. Keep medicine names, numbers and "FDA" in English. Use short simple sentences.',
    early: true,
    counselFromModel: false,
  ),
  Lang(
    code: 'ha',
    name: 'Hausa',
    endonym: 'Hausa',
    nativeLine: 'A yi amfani da Hausa',
    promptLine:
        'Write in everyday Hausa as understood in Ghana. Keep medicine names, numbers and "FDA" in English. Use short simple sentences.',
    exemplar:
        'Example of the tone for Hausa (this one is for a registered, in-date pack):\n"Wannan maganin yana cikin rijistar FDA ta Ghana, kuma ranar karewarsa bai wuce ba. Yi amfani da shi daidai yadda akwatin ya faɗa. Ka ajiye shi a wuri mai sanyi, nesa da yara. Idan ba ka ji sauƙi ba, tambayi likitan magani."',
    early: true,
    mmsCode: 'hau',
  ),
];

Lang langBy(String code) => langs.firstWhere(
      (l) => l.code == code,
      orElse: () => langs.first,
    );
