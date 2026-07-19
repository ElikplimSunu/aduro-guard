# Aduro Guard — Kaggle Writeup Draft

> Target: 1,500 words or fewer. Sections mapped to the rubric (Gemma Integration 30 /
> Innovation & Impact 30 / Functionality 20 / Presentation 20). Fill the [BRACKETS] on
> event day. Word count at last edit: about 1,180, which leaves room for day-of additions.

---

**Title:** Aduro Guard, the medicine scanner that works on any box, in Twi, offline

**Subtitle:** Gemma 4 reads the pack, the Ghana FDA register decides, Gemma explains. All
of it on a low-end Android phone with no internet.

**Track:** [Main / GenAI for Good / Edge / Multimodal, select in the form]

---

## The problem (250w, Innovation & Impact)

One in ten medical products in low- and middle-income countries is substandard or
falsified (WHO). In sub-Saharan Africa the modelled cost is up to half a million deaths
every year, roughly 267,000 of them linked to fake antimalarials. Ghana knows this fight
well. Post-market surveillance found substandard or falsified antimalarials at 75%
prevalence in 2014, still 35% after enforcement in 2016, and more than 94% of sampled
oxytocin and ergometrine, the injections that stop mothers bleeding after birth, failing
quality testing.

The defense a Ghanaian buyer actually has today is mPedigree: scratch a code, SMS it,
wait. It only works for products whose manufacturers opted in, and it assumes the buyer
reads English comfortably. The FDA's own register of 30,000+ products is public, but
nobody at a market stall queries a website while a drug peddler waits.

[ONE HUMAN SENTENCE. For example: "My aunt buys her hypertension medicine from a roadside
stall in Kumasi; this is for her."]

Aduro Guard turns any phone camera into that missing check. Point it at any medicine box,
whether a registered brand, an obscure import, or expired stock, and in seconds you get a
verdict from an offline copy of the FDA register, explained in plain English or Twi, out
loud. No barcode, no opt-in, no literacy requirement, no signal.

## Why nothing else does this (150w, Innovation & Impact)

mPedigree checks codes manufacturers chose to print; Aduro Guard reads any box ever
printed. Prior Gemma hackathon winners clustered around accessibility assistants,
chatbots, and crop diagnosis; medicine authenticity is untouched territory. Cloud OCR
products exist, but uploading purchases over paid data, or having no data at all in a
rural district, is exactly what Ghana's connectivity reality rules out. The register is
public. What was missing is the offline, camera-first, local-language bridge to it.

## Architecture: Gemma reads, the database decides, Gemma explains (300w, Gemma Integration)

The safety-critical design decision: **the model never invents a verdict.**

1. **Vision.** Gemma 4 E2B (on-device, LiteRT-LM, GPU) receives the pack photo with a
   strict-JSON prompt and returns `{product_name, manufacturer, batch_number,
   expiry_date, registration_number, pack_text, legible}`.
2. **Decision.** Pure Dart code checks the extraction against an offline SQLite snapshot
   of the Ghana FDA product register, a recall and alert table built from real FDA Ghana
   and WHO notices, and a lookalike-name table. Expiry parsing, fuzzy matching, and recall
   precedence are deterministic and unit-tested. A one-letter near-miss like "Pamadol" can
   never pass as "Panadol"; single-word spellings short of exact are capped below the
   match threshold.
3. **Explanation.** Gemma phrases the settled verdict as 3 to 5 simple sentences in
   English or Asante Twi (few-shot exemplars; medicine names stay in English), spoken via
   device TTS.
4. **Voice follow-up.** The user holds a button and asks in speech. Gemma 4's native audio
   understanding ingests the 16kHz WAV directly, with no separate ASR stack, and answers
   only from the pack's own text. Ask "can a pregnant woman take this?" and, unless the
   pack says, it refuses and points to a pharmacist. That refusal is a feature we demo,
   not a failure.

Four Gemma 4 capabilities (vision OCR, native audio, multilingual generation, edge
inference) carry one loop. Remove Gemma and there is no product; remove the database and
there is no safety.

## What works today (250w, Functionality)

Live demo flow, phone in airplane mode from the first second:

- Scan a registered antimalarial: green verdict, register match shown, Twi counseling
  read aloud.
- Scan an expired pack: the expiry date is parsed from the pack print and the verdict
  goes red, even though the product itself is in the register.
- Scan [OBSCURE IMPORT PRODUCT]: honest amber "not in this register snapshot", with the
  FDA WhatsApp line to report.
- A deliberately blurry shot: "Couldn't read the pack. Try more light." Engineered
  honesty.
- Voice: "Where should I store it?" answered from the pack text. "Can my sister take it
  with her blood-pressure medicine?" referred to a pharmacist, because the pack does not
  say.

Everything runs on a [PHONE MODEL] with 4 to 6 GB of memory on Gemma 4 E2B (2.4GB). The
stronger E4B build is a settings toggle for 8 GB phones. Model download happens once on
Wi-Fi; the demo needs zero connectivity. [ADD: measured seconds per scan on the demo
phone.] The app ships light and dark themes from one token system.

Honest limits: the committed register snapshot is a curated subset of real products (the
FDA's public register backend was unreachable during build week; the repo ships a
resumable exporter that folds in the full register the moment the server answers). "Not
found" therefore always reads as *verify*, never *fake*. Twi is code-switched everyday
Twi; spoken Twi waits on an online Khaya TTS tier.

## Impact & roadmap (150w, Innovation & Impact)

The register snapshot updates by re-running one script; a build with the full
30,000-product export is the same APK with a bigger asset. The natural partner is the FDA
itself: their recalls become push updates, and every "not found" scan is a crowd-sourced
surveillance signal. The reporting channel (the FDA's 0551112224 WhatsApp line) is
already in the app copy. Next languages are Ewe, Dagbani, and Hausa; Gemma 4's
multilingual base plus GhanaNLP's corpora make each one prompt-and-exemplar work, not a
new model. Apache 2.0 all the way down: weights (Gemma), runtime (flutter_gemma), and
this repo.

## Links & acknowledgments (100w)

- **Code:** [PUBLIC GITHUB URL] with architecture, verdict-engine tests, and the data
  pipeline.
- **Demo:** [APK release link / demo video URL]
- Built with Gemma 4 E2B (Google DeepMind) via flutter_gemma + LiteRT-LM; register data
  from FDA Ghana public notices and WHO medical product alerts; design constraints per
  the repo's DESIGN.md.
- Statistics: WHO (substandard and falsified medical products), Ghana post-market
  surveillance studies (PMC), CHAG quality monitoring.

---

### Day-of checklist (not part of the writeup)

- [ ] Fill every [BRACKET]; re-count words (1,500 max).
- [ ] Buy 4 to 6 real boxes including one expired; add their rows to products.tsv;
      rebuild the db.
- [ ] Retry `tool/scrape_register.py`; if it lands, rebuild the db with the full register.
- [ ] Record a backup demo video before the final hour.
- [ ] Airplane mode ON from the start of the pitch.
- [ ] Repo public, APK attached, writeup submitted before the deadline.
