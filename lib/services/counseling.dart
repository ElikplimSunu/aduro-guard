import '../models/verdict.dart';

/// Human-written counseling for every verdict, in every language.
///
/// Why this exists: Gemma 4 E2B writes good English but drifts out of the
/// low-resource Ghanaian languages, either answering in English under a Twi
/// heading or collapsing into a repeated phrase. Generated text in a language
/// nobody on the team can proofread is also, by construction, unreviewable —
/// it is different on every run. These templates are the opposite: a fixed,
/// finite set a native speaker can read once and correct for good.
///
/// [Gemma.counsel] still generates where the model is reliable and verifies
/// what it produced; this is what the user sees when that check fails, and
/// what is shown directly for languages the model cannot hold.
///
/// Review note for native speakers: 6 verdicts per language, below. The FDA
/// number 0551112224 (WhatsApp) and product names stay as they are.
String counselingTemplate(VerdictStatus status, String lang) =>
    _fill((_byLang[lang] ?? _en)[status]!, lang, null);

/// The template with this scan's own facts filled into its slots, so the
/// reviewed wording carries the same crucial specifics the generated English
/// does: a registered verdict names the actual expiry date read off the pack.
String counselingText(Verdict v, String lang) =>
    _fill((_byLang[lang] ?? _en)[v.status]!, lang, v.expiryDate);

String _fill(String t, String lang, DateTime? expiry) {
  if (!t.contains('{expiry}')) return t;
  final line = expiry == null
      ? (_checkExpiry[lang] ?? _checkExpiry['en']!)
      : (_stillInDate[lang] ?? _stillInDate['en']!)
          .replaceAll('{date}', '${expiry.month}/${expiry.year}');
  return t.replaceAll('{expiry}', line);
}

/// Expiry slot, when the camera read a date that has not passed. (An expired
/// date never reaches these templates; that is its own verdict.)
const _stillInDate = {
  'en': 'The expiry date on the pack is {date}; it has not passed.',
  'tw': 'Ne bere a ɛwɔ adaka no so no yɛ {date}; ennya ntwamee.',
  'ee': 'Ɣeyiɣi si le aɖaka la dzi enye {date}; meva yi haɖe o.',
  'dag': 'Saha din be adaka maa zuɣu nyɛla {date}; di na bi gari.',
  'ha': 'Ranar karewa da ke akwatin ita ce {date}; ba ta wuce ba tukuna.',
};

/// Expiry slot, when no date was read.
const _checkExpiry = {
  'en': 'Check the expiry date on the pack yourself before you use it.',
  'tw': 'Hwɛ ne bere a ɛwɔ adaka no so no wo ara ansa na woanom.',
  'ee': 'Kpɔ ɣeyiɣi si dzi wòava yi le aɖaka la dzi ɖokuiwò hafi nàzãe.',
  'dag': 'Vihimi di saha din be adaka maa zuɣu a maŋa poi ka a nyu li.',
  'ha': 'Duba ranar karewa da ke akwatin da kanka kafin ka sha.',
};

const _en = {
  VerdictStatus.registered:
      'This medicine is in the Ghana FDA register. That means the FDA has approved a product with this name. Take it exactly as the pack instructs. {expiry} If you are unsure about anything, ask a pharmacist.',
  VerdictStatus.expired:
      'The expiry date printed on this pack has passed. Do not take it. Medicine past its date can be weak, or it can harm you. Take it back to the pharmacy and get a fresh pack.',
  VerdictStatus.recalled:
      'The FDA has issued a recall or a safety alert for this product. Do not take it. Return it to the pharmacy, or report it to the FDA on 0551112224 (WhatsApp). Ask a pharmacist for a safe replacement.',
  VerdictStatus.caution:
      'Check this pack carefully. The name or the registration number on it does not match the FDA register exactly, and small changes like that are a known counterfeit sign. Do not take it until you are sure. Show it to a pharmacist, or call the FDA on 0551112224 (WhatsApp).',
  VerdictStatus.notFound:
      'This product was not found in the FDA register copy on this phone. That does not prove it is fake. It may be new, or it may not be registered. Ask a pharmacist, or check with the FDA on 0551112224 (WhatsApp), before you take it.',
  VerdictStatus.unreadable:
      'The photo could not be read. Move to brighter light, hold the phone steady, and fill the frame with the front of the pack. Then take the photo again.',
};

const _tw = {
  VerdictStatus.registered:
      'Aduro yi wɔ Ghana FDA nhoma no mu. Ɛkyerɛ sɛ FDA apene aduro a ɛwɔ din yi so. Fa no sɛnea adaka no so kyerɛ pɛpɛɛpɛ. {expiry} Sɛ biribiara haw wo a, kɔbisa pharmacist.',
  VerdictStatus.expired:
      'Bere a ɛwɔ adaka yi so no atwam. Nnom. Aduro a ne bere atwam betumi ayɛ mmerɛw, anaa ɛbɛpira wo. San fa kɔ pharmacy hɔ na kɔgye foforo.',
  VerdictStatus.recalled:
      'FDA abɔ aduro yi ho kɔkɔ. Nnom koraa. San fa kɔ pharmacy hɔ, anaa bɔ FDA amanneɛ wɔ 0551112224 (WhatsApp) so. Bisa pharmacist na ɔmma wo foforo a ɛho tew.',
  VerdictStatus.caution:
      'Hwɛ adaka yi yiye. Din anaa registration nɔma a ɛwɔ so no ne nea ɛwɔ FDA nhoma no mu nhyia pɛpɛɛpɛ, na nsakrae nketewa sɛɛ yɛ aduro a wɔabɔ ho dawuru ho sɛnkyerɛnne. Nnom kosi sɛ wubehu yiye. Fa kyerɛ pharmacist, anaa frɛ FDA wɔ 0551112224 (WhatsApp) so.',
  VerdictStatus.notFound:
      'Yanhu aduro yi wɔ FDA nhoma a ɛwɔ phone yi so no mu. Ɛno nkyerɛ sɛ ɛyɛ atoro aduro. Ebia ɛyɛ foforo, anaa wɔnkyerɛw ne din ntoo hɔ. Bisa pharmacist, anaa FDA wɔ 0551112224 (WhatsApp) so, ansa na woanom.',
  VerdictStatus.unreadable:
      'Yantumi ankenkan mfonini no. Kɔ baabi a hann wɔ, gyina dinn, na ma adaka no anim nyinaa nna mfonini no mu. Afei twa no bio.',
};

const _ee = {
  VerdictStatus.registered:
      'Atike sia le Ghana FDA ƒe agbalẽ me. Efia be FDA da asi atike si ŋkɔ nye esia dzi. Zãe abe ale si woŋlɔ ɖe aɖaka la dzi ene tututu. {expiry} Ne nane meko ɖe dziwò o la, bia pharmacist.',
  VerdictStatus.expired:
      'Ɣeyiɣi si woŋlɔ ɖe aɖaka sia dzi la va yi xoxo. Mèganoe o. Atike si ƒe ɣeyiɣi va yi ate ŋu agbɔdzɔ, alo wòagblẽ nu le ŋuwò. Trɔ yi pharmacy la be woatsɔ yeye na wò.',
  VerdictStatus.recalled:
      'FDA ƒo nu tso atike sia ŋu be mele dedie o. Mèganoe kura o. Trɔe yi pharmacy la, alo ka nya na FDA le 0551112224 (WhatsApp) dzi. Bia pharmacist be wòatsɔ bubu si le dedie na wò.',
  VerdictStatus.caution:
      'Lé ŋku ɖe aɖaka sia ŋu nyuie. Ŋkɔ alo registration xexlẽdzesi si le edzi la mesɔ pɛpɛpɛ kple esi le FDA ƒe agbalẽ me o, eye tɔtrɔ sue mawo nye aʋatsotike ƒe dzesi. Mèganoe va se ɖe esime nàka ɖe edzi o. Fiae pharmacist, alo ƒo ka na FDA le 0551112224 (WhatsApp) dzi.',
  VerdictStatus.notFound:
      'Míekpɔ atike sia le FDA ƒe agbalẽ si le phone sia dzi me o. Mefia be aʋatsotike wònye o. Ate ŋu anye yeye, alo womeŋlɔ eŋkɔ ɖi o. Bia pharmacist, alo FDA le 0551112224 (WhatsApp) dzi, hafi nàzãe.',
  VerdictStatus.unreadable:
      'Míete ŋu xlẽ foto la o. Yi teƒe si kekeli le, lé phone la ɖe asi goŋgoŋ, eye nàna aɖaka la ŋkume nayɔ foto la me. Emegbe nàɖe foto la ake.',
};

const _dag = {
  VerdictStatus.registered:
      'Tim ŋɔ be Ghana FDA gbaŋ ni. Di wuhirimi ni FDA saɣi tim din mali yuli ŋɔ. Nyum li kaman adaka maa ni yɛli shɛm. {expiry} A yi ka baŋsim shɛli zuɣu, bɔhimi pharmacist.',
  VerdictStatus.expired:
      'Saha din be adaka ŋɔ zuɣu maa gari. Miri ka a nyu li. Tim din saha gari ku tooi tuma viɛnyɛla, bee di ni tooi niŋ a chuuta. Labimi pharmacy ka a deei din palli.',
  VerdictStatus.recalled:
      'FDA yɛli ka tim ŋɔ ka viɛnyɛla. Miri ka a nyu li. Labisi li pharmacy, bee a bɔhi FDA 0551112224 (WhatsApp) zuɣu. Bɔhimi pharmacist ka o ti a din viɛla.',
  VerdictStatus.caution:
      'Vihimi adaka ŋɔ viɛnyla. Di yuli bee di registration namba bi niŋ yim ni din be FDA gbaŋ ni, ka taɣibu bihi ŋɔ nyɛla ʒiri tim dalirili. Miri ka a nyu li hali ka a naan baŋ. Wuhimi pharmacist, bee a bɔhi FDA 0551112224 (WhatsApp) zuɣu.',
  VerdictStatus.notFound:
      'Ti bi nya tim ŋɔ FDA gbaŋ din be phone ŋɔ ni maa ni. Di pa ni di nyɛla ʒiri tim. Di ni tooi nyɛ din palli, bee bi sabi di yuli. Bɔhimi pharmacist, bee FDA 0551112224 (WhatsApp) zuɣu, poi ka a nyu li.',
  VerdictStatus.unreadable:
      'Ti bi tooi karim foto maa. Chaŋmi luɣushɛli neesim ni be, zanimi yim, ka adaka maa nini pali foto maa ni. Din nyaaŋa, lan ŋmali foto maa.',
};

const _ha = {
  VerdictStatus.registered:
      'Wannan maganin yana cikin rijistar FDA ta Ghana. Wannan yana nufin FDA ta amince da magani mai wannan sunan. Yi amfani da shi daidai yadda akwatin ya faɗa. {expiry} Idan wani abu bai fito maka sarai ba, tambayi likitan magani.',
  VerdictStatus.expired:
      'Ranar karewa da aka rubuta a wannan akwatin ta wuce. Kada ka sha shi. Maganin da ranarsa ta wuce zai iya raunana, ko kuma ya cutar da kai. Mayar da shi kantin magani ka sami sabo.',
  VerdictStatus.recalled:
      'FDA ta yi gargaɗi ko ta janye wannan kayan. Kada ka sha shi ko kaɗan. Mayar da shi kantin magani, ko ka kai rahoto ga FDA a 0551112224 (WhatsApp). Tambayi likitan magani ya ba ka wanda ya fi aminci.',
  VerdictStatus.caution:
      'Duba wannan akwatin da kyau. Sunan ko lambar rijistar da ke kansa bai yi daidai da rijistar FDA ba sosai, kuma irin waɗannan ƙananan canje-canje alama ce ta magungunan jabu. Kada ka sha shi sai ka tabbatar. Nuna wa likitan magani, ko ka kira FDA a 0551112224 (WhatsApp).',
  VerdictStatus.notFound:
      'Ba a sami wannan kayan a cikin rijistar FDA da ke wannan wayar ba. Wannan bai tabbatar da cewa jabu ne ba. Yana iya zama sabo, ko kuma ba a yi masa rijista ba. Tambayi likitan magani, ko FDA a 0551112224 (WhatsApp), kafin ka sha.',
  VerdictStatus.unreadable:
      'Ba a iya karanta hoton ba. Je wurin da haske yake, ka riƙe wayar cak, kuma ka sa gaban akwatin ya cika hoton. Sannan ka sake ɗaukar hoto.',
};

const _byLang = {
  'en': _en,
  'tw': _tw,
  'ee': _ee,
  'dag': _dag,
  'ha': _ha,
};
