# Aduro Guard

**Title:** Aduro Guard: check any medicine, offline, in your own language

**Subtitle:** Gemma 4 reads the pack, an offline copy of the Ghana FDA register decides the verdict, and Gemma explains it in Twi, out loud. No internet.

**Track:** Main

---

*(Everything below goes in the Project Description field, following the host's template headings.)*

### Inspiration

One in ten medical products in low and middle income countries is substandard or falsified (WHO). In sub-Saharan Africa the modelled cost is up to half a million deaths a year, roughly 267,000 of them linked to fake antimalarials. Ghana knows this fight well. Post-market surveillance found substandard or falsified antimalarials at 75% prevalence in 2014, still 35% after enforcement in 2016, and more than 94% of sampled oxytocin and ergometrine, the injections that stop mothers bleeding after birth, failing quality testing.

The defense a Ghanaian buyer has today is mPedigree: scratch a code, SMS it, wait. It only works for products whose manufacturers opted in, and it assumes the buyer reads English comfortably. The FDA's own register of more than 16,000 products is public, but its server is intermittently down, the search only answers online, and nobody at a market stall queries a website while a drug peddler waits.

**[ONE SENTENCE ABOUT WHO YOU BUILT THIS FOR. Yours to write, not ours.]**

Aduro Guard turns any phone camera into that missing check. Point it at any medicine box, whether a registered brand, an obscure import or expired stock, and in seconds you get a verdict from an offline copy of the FDA register, explained in plain English or Twi, out loud. No barcode, no opt-in, no literacy requirement, no signal. Aduro means medicine in Twi.

### How we built it

**Gemma 4 E2B, on device, via flutter_gemma and LiteRT-LM with GPU acceleration.** No cloud, no fine-tuning, no RAG. Prompt engineering plus a database, in a deliberate three-stage split:

**1. Gemma reads.** The pack photo goes to Gemma 4's vision with a strict-JSON prompt and comes back as `{product_name, manufacturer, batch_number, expiry_date, registration_number, pack_text, legible}`. Extraction streams, so an unreadable photo is detected in the first few tokens and generation stops early instead of burning the whole budget.

**2. The database decides.** This is the safety-critical choice: **the model never invents a verdict.**

We built the register ourselves. Ghana's FDA publishes its product register at **https://verifypermit.fdaghana.gov.gh/publicsearch**, a server-side DataTables endpoint that only answers online, over HTTPS only (plain HTTP returns 404), and whose TLS certificate has been expired since 2025, so browsers warn before letting you in. A resumable Python exporter in the repo (`tool/scrape_register.py`) pages through it politely and writes every row to TSV; `tool/build_db.dart` compiles that into the SQLite snapshot shipped inside the APK. The result is **16,454 rows, 15,171 unique products**, each with its registration number, generic name and manufacturer, exported 2026-07-19. Re-running two commands produces a fresh snapshot, so the app is never more stale than the day it was built.

Pure Dart code then checks each extraction against that snapshot, a recall and alert table built from real FDA Ghana and WHO notices, and a lookalike-name table. Registration numbers match exactly, including the pre-2013 FDB prefix still printed on real packs. Expiry parsing, fuzzy matching and recall precedence are deterministic and unit tested. A one-letter near-miss like "Pamadol" can never pass as "Panadol", because single-word spellings short of exact are capped below the match threshold. A genuine registration number on a wrong-named pack never upgrades a verdict, and a name match whose printed number disagrees with the register is downgraded to caution, since that mismatch is a known counterfeit sign.

**3. Gemma explains.** The settled verdict is phrased as three to five simple sentences in English, Twi, Ewe, Ga, Dagbani or Hausa. Speech is offline too: the device voice covers English, while Twi, Ewe and Hausa are synthesized on device with Meta's open MMS voices (VITS, community ONNX exports, about 115 MB per language) through sherpa-onnx in a persistent warm isolate, each an optional one-time download. There is no separate speech-to-text stack anywhere in the app.

**4. Voice follow-up.** Hold a button and ask out loud. Gemma 4's native audio understanding ingests the 16kHz WAV directly, with no separate speech-to-text stack, and answers only from the pack's own text. Ask "can a pregnant woman take this?" and, unless the pack says so, it refuses and points to a pharmacist. That refusal is a feature we demo, not a failure.

Four Gemma 4 capabilities carry one loop: vision OCR, native audio, multilingual generation and edge inference. Remove Gemma and there is no product. Remove the database and there is no safety.

Why these choices were right: a verdict about medicine is a factual claim, and a 2.4GB model that hallucinates one is worse than no app at all. Putting the decision in testable code means the safety logic can be reviewed, unit tested and audited by anyone, while Gemma does the two things it is genuinely better at than code, reading a photograph and explaining a result in Twi.

### The Prototype

**Demo video:** [INSERT YOUTUBE LINK]
**Code:** https://github.com/ElikplimSunu/aduro-guard
**Installable APK:** https://github.com/ElikplimSunu/aduro-guard/releases/tag/v1.0.0

Measured on a Samsung Galaxy S24 in airplane mode, release build:

- **About 11 seconds** from confirming a photo to a verdict on screen.
- Vin-C Plus, a real vitamin C pack: green, "In the register", expiry 12/2027, still in date.
- Lufart antimalarial: amber. The pack reads "LUFART Tablets / Comprimes"; the register lists "LUFART 20MG+120MG TABLETS". Close, not exact, so the app says check the spelling rather than guessing.
- Gasto Mixture, a Naturemedics herbal product: honest amber, "not in this register snapshot", with the FDA WhatsApp line to report it.
- A deliberately blurry shot: "Couldn't read the pack. Try more light."

One photo rarely shows everything, because the name is on the front while batch and expiry hide on a side panel. Rather than instruct people up front, the app waits until it has a verdict, then names exactly what it could not see and offers one button to photograph another side. The second read merges field by field, the verdict re-runs and the saved record updates. On Vin-C that turned three blank fields into batch A5522, expiry 12/2027 and a green verdict.

The app also ships light and dark themes from one token system, a language picker where every option is labelled in its own language and the whole interface flips on selection, saved question threads so an answer survives closing the app, and screen reader support with labelled controls, an announced verdict and 44dp touch targets.

### Challenges we ran into

**The model would not speak Ghana's languages, and lied about it convincingly.** Gemma 4 E2B writes good English. Asked for Ewe or Dagbani it returned fluent English under an Ewe heading, and it collapsed Twi into a five-word phrase repeating until the token budget ran out. Our first repetition guard counted unique words in the tail, so a cycling *phrase* went straight through it.

Shipping that would have been worse than shipping English, because a user cannot tell a wrong translation from a right one. So we stopped trusting the output and started verifying it. Generation is now checked twice: a cycle detector that looks for any block of up to six words repeating three times, and a function-word heuristic that catches English prose sitting under a local-language heading. Text failing either check is discarded and replaced with human-reviewed wording held in the repository, six verdicts in each of the six languages.

The deeper problem is reviewability. Generated low-resource text differs on every run, so no native speaker can ever proofread it. A finite set of thirty-six short paragraphs can be read once and corrected for good. Ewe and Dagbani now skip generation entirely, which also saves a 15 second call that never returned their language, while English, Twi and Hausa still generate and fall back only on failure. Both real failures are now regression tests.

**A second bug nearly shipped:** our model loader cached its in-flight future but kept it after a failure, so one lost 2.4GB load poisoned the whole process and every later scan showed "guidance unavailable" until restart. Found by reading the code after seeing it on device.

### Honest limits

The register is a dated snapshot, so "not found" always reads as *verify*, never *fake*. The Twi, Ewe, Ga, Dagbani and Hausa wording is written but not yet reviewed by native speakers; it sits in one file for exactly that purpose. The MMS voices are intelligible rather than natural, and Dagbani has no published voice yet, so it ships as text only.

Licensing: this repository and the runtime stack are Apache 2.0; Gemma 4 ships under the free Gemma license, and the optional MMS voices under CC BY-NC 4.0. All free and publicly available, as the rules require.
