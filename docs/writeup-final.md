# Aduro Guard

**Subtitle:** Gemma 4 reads the pack, the Ghana FDA register decides, Gemma explains. All of it on an Android phone with no internet.

**Track:** Main

---

## The problem

One in ten medical products in low and middle income countries is substandard or falsified (WHO). In sub-Saharan Africa the modelled cost is up to half a million deaths every year, roughly 267,000 of them linked to fake antimalarials. Ghana knows this fight well. Post-market surveillance found substandard or falsified antimalarials at 75% prevalence in 2014, still 35% after enforcement in 2016, and more than 94% of sampled oxytocin and ergometrine, the injections that stop mothers bleeding after birth, failing quality testing.

The defense a Ghanaian buyer actually has today is mPedigree: scratch a code, SMS it, wait. It only works for products whose manufacturers opted in, and it assumes the buyer reads English comfortably. The FDA's own register of more than 16,000 products is public, but its server is intermittently down, the search only answers online, and nobody at a market stall queries a website while a drug peddler waits.

**[ONE SENTENCE ABOUT WHO YOU BUILT THIS FOR. Yours to write, not ours.]**

Aduro Guard turns any phone camera into that missing check. Point it at any medicine box, whether a registered brand, an obscure import, or expired stock, and in seconds you get a verdict from an offline copy of the FDA register, explained in plain English or Twi, out loud. No barcode, no opt-in, no literacy requirement, no signal.

## Why nothing else does this

mPedigree checks codes manufacturers chose to print; Aduro Guard reads any box ever printed. Cloud OCR products exist, but uploading purchases over paid data, or having no data at all in a rural district, is exactly what Ghana's connectivity reality rules out. The register is public. What was missing is the offline, camera-first, local-language bridge to it.

## Architecture: Gemma reads, the database decides, Gemma explains

The safety-critical design decision: **the model never invents a verdict.**

1. **Vision.** Gemma 4 E2B (on-device, LiteRT-LM, GPU) receives the pack photo with a strict-JSON prompt and returns `{product_name, manufacturer, batch_number, expiry_date, registration_number, pack_text, legible}`.

2. **Decision.** Pure Dart code checks that extraction against a full offline export of the Ghana FDA product register (16,454 rows, 15,171 unique products with registration numbers), a recall and alert table built from real FDA Ghana and WHO notices, and a lookalike-name table. Registration numbers match exactly, including the pre-2013 FDB prefix still printed on real packs. Expiry parsing, fuzzy matching and recall precedence are deterministic and unit tested. A one-letter near-miss like "Pamadol" can never pass as "Panadol": single-word spellings short of exact are capped below the match threshold. A genuine registration number on a wrong-named pack never upgrades a verdict, and a name match whose printed number disagrees with the register is downgraded to caution, because that mismatch is a known counterfeit sign.

3. **Explanation.** Gemma phrases the settled verdict as three to five simple sentences in English, Twi, Ewe, Dagbani or Hausa. Speech out is offline too: the device voice covers English, and Twi, Ewe and Hausa are synthesized on-device with Meta's open MMS voices via sherpa-onnx, each an optional one-time download.

4. **Voice follow-up.** The user holds a button and asks in speech. Gemma 4's native audio understanding ingests the 16kHz WAV directly, with no separate ASR stack, and answers only from the pack's own text. Ask "can a pregnant woman take this?" and, unless the pack says, it refuses and points to a pharmacist. That refusal is a feature we demo, not a failure.

Four Gemma 4 capabilities (vision OCR, native audio, multilingual generation, edge inference) carry one loop. Remove Gemma and there is no product; remove the database and there is no safety.

## The challenge we did not expect

Gemma 4 E2B writes good English. On Ghana's low-resource languages it does not hold: asked for Ewe or Dagbani it answered in fluent English under an Ewe heading, and it collapsed Twi into a five-word phrase repeating until the token budget ran out. Our first repetition guard counted unique words in the tail, so a cycling *phrase* sailed straight through it.

Shipping that would have been worse than shipping English. So we stopped trusting the output and started checking it. Generation is now verified twice: a cycle detector that looks for any block of up to six words repeating three times, and a function-word heuristic that catches English prose sitting under a local-language heading. Text that fails either check is discarded and replaced with human-reviewed wording held in the repository, six verdicts per language.

The deeper reason is reviewability. Generated low-resource text is different on every run, so no native speaker can ever proofread it. A finite set of thirty short paragraphs can be read once and corrected for good. Ewe and Dagbani now skip generation entirely, which also saves a 15 second call that never returned their language; English, Twi and Hausa still generate and fall back only when the check fails. Both failures from our device logs are now regression tests.

## What works today

Measured on a Samsung Galaxy S24, airplane mode, release build:

- **About 11 seconds** from confirming a photo to a verdict on screen, with the model warmed at app launch.
- Vin-C Plus, a real vitamin C pack: green, "In the register", expiry 12/2027 still in date.
- Lufart antimalarial: amber. The pack reads "LUFART Tablets / Comprimes" and the register lists "LUFART 20MG+120MG TABLETS", close but not exact, so the app says check the spelling rather than guessing.
- Gasto Mixture, a Naturemedics herbal product: honest amber "not in this register snapshot", with the FDA WhatsApp line to report it.
- A deliberately blurry shot: "Couldn't read the pack. Try more light." Engineered honesty.

One photo rarely shows everything, because the name is on the front and the batch and expiry are on a side panel. Rather than instruct people up front, the app waits until it has a verdict and then names exactly what it could not see, with one button to photograph another side. The second read merges field-wise, the verdict re-runs, and the saved record updates. On Vin-C that turned three blank fields into batch A5522, expiry 12/2027, and a green verdict.

Everything runs on Gemma 4 E2B (2.4GB), the build sized for the 4 to 6 GB phones most Ghanaians carry; E4B is a settings toggle for 8 GB phones. Model download happens once on Wi-Fi. The app also ships light and dark themes from one token system, a language picker where every option is labelled in its own language and the whole interface flips on selection, saved question threads so an answer survives closing the app, and screen reader support with labelled controls, an announced verdict and 44dp touch targets.

## Honest limits

The register is a dated snapshot, so "not found" always reads as *verify*, never *fake*. The Twi, Ewe, Dagbani and Hausa wording is written but not yet reviewed by native speakers; it sits in one file for exactly that purpose. The MMS voices are intelligible rather than natural, and Dagbani has no published voice yet, so it ships as text only.

## Impact and roadmap

The snapshot refreshes by re-running one script against the FDA's own endpoint, so a fresher build is the same APK with a newer asset. The natural partner is the FDA itself: their recalls become push updates, and every "not found" scan is a crowd-sourced surveillance signal. The reporting channel, the FDA's 0551112224 WhatsApp line, is already in the app copy. Apache 2.0 all the way down: weights, runtime and this repository.

## Links

- **Code:** https://github.com/ElikplimSunu/aduro-guard
- **Demo:** https://github.com/ElikplimSunu/aduro-guard/releases/tag/v1.0.0
- Built with Gemma 4 E2B (Google DeepMind) via flutter_gemma and LiteRT-LM; offline voices from Meta MMS; register data from the Ghana FDA public register, FDA Ghana notices and WHO medical product alerts.
- Statistics: WHO substandard and falsified medical products; Ghana post-market surveillance studies.
