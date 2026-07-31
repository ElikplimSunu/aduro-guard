# Aduro Guard

**Title:** Aduro Guard: check any medicine, offline, in your own language

**Subtitle:** Gemma 4 reads the pack, an offline copy of the Ghana FDA register decides the verdict, and Gemma explains it in Twi, out loud. No internet.

**Track:** Main

---

*(Everything below goes in the Project Description field, following the host's template headings.)*

### Inspiration

One in ten medical products in low and middle income countries is substandard or falsified (WHO). In sub-Saharan Africa the modelled cost is up to half a million deaths a year, roughly 267,000 of them linked to fake antimalarials. Ghana knows this fight well. Post-market surveillance found substandard or falsified antimalarials at 75% prevalence in 2014, still 35% after enforcement in 2016, and more than 94% of sampled oxytocin and ergometrine, the injections that stop mothers bleeding after birth, failing quality testing.

The defense a Ghanaian buyer has today is mPedigree: scratch a code, SMS it, wait. It only covers products whose manufacturers opted in, and assumes the buyer reads English. The FDA's own register of 16,000+ products is public, but its server is intermittently down, the search answers online only, and nobody at a market stall queries a website while a peddler waits.

**[ONE SENTENCE ABOUT WHO YOU BUILT THIS FOR. Yours to write, not ours.]**

Aduro Guard turns any phone camera into that missing check. Point it at any medicine box and in seconds you get a verdict from an offline copy of the FDA register, explained out loud in your own language. No barcode, no opt-in, no literacy requirement, no signal.

### How we built it

**Gemma 4 E2B, on device, via flutter_gemma and LiteRT-LM with GPU acceleration.** No cloud, no fine-tuning, no RAG: prompt engineering plus a database, in a deliberate three-stage split:

**1. Gemma reads.** The pack photo goes to Gemma 4's vision with a strict-JSON prompt and comes back as `{product_name, manufacturer, batch_number, expiry_date, registration_number, pack_text, legible}`. Extraction streams, so an unreadable photo is detected in the first few tokens and generation stops early instead of burning the whole budget.

**2. The database decides.** This is the safety-critical choice: **the model never invents a verdict.**

We built the register ourselves. Ghana's FDA publishes it at **https://verifypermit.fdaghana.gov.gh/publicsearch**, a server-side DataTables endpoint that answers online only, over HTTPS only (plain HTTP returns 404), with a TLS certificate expired since 2025. A resumable exporter (`tool/scrape_register.py`) pages through it politely; `tool/build_db.dart` compiles the result into the SQLite snapshot inside the APK: **16,454 rows, 15,171 unique products** with registration numbers, generics and manufacturers, exported 2026-07-19. Two commands produce a fresh one.

Pure Dart then checks each extraction against that snapshot, a recall and alert table from real FDA Ghana and WHO notices, and a lookalike-name table. Registration numbers match exactly, including the pre-2013 FDB prefix still printed on real packs. Expiry parsing, fuzzy matching and recall precedence are deterministic and unit tested. A one-letter near-miss like "Pamadol" can never pass as "Panadol". A genuine registration number on a wrong-named pack never upgrades a verdict, and a name match whose printed number disagrees with the register drops to caution, a known counterfeit sign.

**3. Gemma explains.** The verdict is phrased as three to five simple sentences in English, Twi, Ewe, Ga, Dagbani or Hausa. Speech is offline too: English uses the phone's own voice, while Twi, Ewe and Hausa are synthesized on device from Meta's open MMS voices (VITS, community ONNX exports, ~115 MB each, CC BY-NC 4.0) by sherpa-onnx in a warm isolate, each an optional one-time download. There is no speech-to-text stack anywhere: spoken questions go straight into Gemma 4's native audio.

**4. Voice follow-up.** Hold a button and ask out loud. Gemma 4's native audio understanding ingests the 16kHz WAV directly, with no separate speech-to-text stack, and answers only from the pack's own text. Ask "can a pregnant woman take this?" and, unless the pack says so, it refuses and points to a pharmacist. That refusal is a feature we demo, not a failure.

Four Gemma 4 capabilities carry one loop: vision OCR, native audio, multilingual generation and edge inference. Remove Gemma and there is no product; remove the database and there is no safety. A verdict about medicine is a factual claim, and a 2.4GB model that hallucinates one is worse than no app at all, so the decision lives in code anyone can audit while Gemma does what it is genuinely better at.

### The Prototype

**Demo video:** [INSERT YOUTUBE LINK]
**Code:** https://github.com/ElikplimSunu/aduro-guard
**Installable APK:** https://github.com/ElikplimSunu/aduro-guard/releases/tag/v1.0.0

Measured on a Samsung Galaxy S24 in airplane mode, release build:

- **About 11 seconds** from confirming a photo to a verdict on screen.
- Vin-C Plus, a real vitamin C pack: green, "In the register", expiry 12/2027, still in date.
- Lufart antimalarial: amber. The pack reads "LUFART Tablets / Comprimes"; the register lists "LUFART 20MG+120MG TABLETS". Close, not exact, so it says check the spelling rather than guessing.
- Gasto Mixture, a herbal product: honest amber, "not in this register snapshot", with the FDA WhatsApp line to report it.
- A deliberately blurry shot: "Couldn't read the pack. Try more light."

One photo rarely shows everything: the name is on the front while batch and expiry hide on a side panel. Rather than instruct anyone up front, the app waits until it has a verdict, names exactly what it could not see, and offers one button for another angle. The reads merge field by field and the verdict re-runs. On Vin-C that turned three blank fields into batch A5522, expiry 12/2027 and a green verdict.

The app also ships light and dark themes from one token system, a language picker where every option is labelled in its own language and the whole interface flips on selection, saved question threads so an answer survives closing the app, and screen reader support with labelled controls, an announced verdict and 44dp touch targets.

### Challenges we ran into

**The model would not speak Ghana's languages, and lied about it convincingly.** Gemma 4 E2B writes good English. Asked for Ewe, Ga or Dagbani it returned fluent English under a local-language heading, and it collapsed Twi into a five-word phrase repeating until the token budget ran out. A user cannot tell a wrong translation from a right one, so shipping that would have been worse than shipping English.

So we stopped trusting the output and started verifying it. Every generation is checked for two failures: a repetition collapse, and English prose under a local-language heading. Text failing either is discarded and replaced with human-reviewed wording in the repository, six verdicts in each of six languages, with slots that fill in the scan's own facts so it still names the expiry read off the pack.

That guard needed a second pass. It ran per streamed chunk, and chunks land mid-word, so the tail it inspected was misaligned almost every time and a real collapse still reached a tester's screen. It now also checks the finished text and rejects any short phrase repeating four times anywhere. Chat answers get the same guard, and since they have no reviewed fallback a collapsing answer is dropped and the user asked to try again.

The deeper problem is reviewability: generated low-resource text differs every run, so no native speaker can proofread it. Thirty-six fixed paragraphs can be read once and corrected for good. Ewe, Ga and Dagbani skip generation, and their chat answers come in English with the interface saying so. English, Twi and Hausa generate and fall back only on failure.

**Voices were a harder no than expected.** MMS covers Twi, Ewe and Hausa, shipped as optional 115 MB downloads, and has nothing for Ga or Dagbani. None of GhanaNLP's hundred models is Ga speech, so Ga has no offline voice anywhere. Dagbani does have one, a VITS checkpoint shaped like the MMS voices, so we wrote an exporter. It converts; sherpa-onnx then rejects it twice on metadata and token format, both fixed, and finally segfaults during generation because our graph carries the HuggingFace forward signature while sherpa-onnx feeds VITS its inputs and sampling scales as separate tensors. The script and the full trail are committed. Dagbani stays text-only rather than ship something untested into a medicine app.

That failure earned its keep. Voice models load through native code, so a bad one aborts the process rather than throwing, and the app warmed the current voice at launch. One broken model therefore made the app impossible to start. Voices now warm on the result screen, where the worst case costs one screen.

**A third bug nearly shipped:** the model loader kept its in-flight future after a failure, so one lost 2.4GB load poisoned the process and every later scan reported guidance unavailable until restart.

### Honest limits

The register is a dated snapshot, so "not found" always reads as verify, never fake. All the local-language wording is written but not yet reviewed by native speakers; it sits in one file for exactly that purpose, and Ga is newest and least reviewed. Follow-up questions answer in English for Ewe, Ga and Dagbani, and neither Ga nor Dagbani has an offline voice. The MMS voices are intelligible rather than natural.

Licensing: this repository and the runtime stack are Apache 2.0; Gemma 4 ships under the free Gemma license, and the optional MMS voices under CC BY-NC 4.0. All free and publicly available, as the rules require.
