# Aduro Guard

**Check any medicine before you take it — offline, in seconds, in English or Twi.**

Aduro ("medicine" in Twi) Guard is a camera-first medicine safety scanner built for the
[Build with Gemma: Ghana](https://www.kaggle.com/competitions/build-with-gemma-ghana) hackathon.
Point a low-end Android phone at any medicine package: Gemma 4 reads the pack with its eyes,
an offline copy of the Ghana FDA product register decides the verdict, and Gemma explains it
in plain English or Twi — spoken aloud. Then ask follow-up questions by voice; answers come
only from what the pack itself says.

Falsified and substandard medicines are linked to an estimated **half a million deaths a year
in sub-Saharan Africa** (WHO). Ghana's existing defense, scratch-code SMS checks, only covers
manufacturers who opt in. Aduro Guard reads **any box ever printed** — no barcode, no code,
no literacy requirement, no internet.

## Architecture: Gemma reads → the database decides → Gemma explains

```
┌──────────┐   photo    ┌─────────────────┐  strict JSON   ┌──────────────────┐
│  Camera  ├───────────►│  Gemma 4 E2B    ├───────────────►│  Verdict engine  │
└──────────┘            │  vision (OCR)   │ {name, mfr,    │  (pure Dart)     │
                        │  on-device      │  batch, expiry}│  · FDA register  │
┌──────────┐   16kHz    │  LiteRT-LM      │                │    snapshot      │
│   Mic    ├───────────►│  native audio   │◄───────────────┤  · recall list   │
└──────────┘  wav       │  understanding  │  verdict facts │  · lookalikes    │
                        └────────┬────────┘                └──────────────────┘
                                 │ counseling / grounded answers
                                 ▼
                        English / Twi text + device TTS
```

The model **never invents a safety verdict**. It extracts what is printed and phrases what the
database decided. Registered / expired / recalled / caution / not-found are computed by
deterministic Dart code ([lib/services/verdict_engine.dart](lib/services/verdict_engine.dart))
with unit tests covering expiry formats, near-miss counterfeit spellings, and recall hits.

### Gemma 4 capabilities used (all on-device, fully offline)

| Capability | Where |
|---|---|
| Vision OCR | Pack photo → structured JSON extraction |
| Native audio input | Spoken follow-up questions (16kHz WAV, no separate ASR stack) |
| Multilingual generation | Counseling + answers in English and Asante Twi |
| Edge inference | Gemma 4 E2B (2.4GB) via flutter_gemma / LiteRT-LM, GPU-accelerated |

## Project layout

```
lib/
  theme/        design tokens + theme (see DESIGN.md — the anti-AI-slop contract)
  models/       Product, Extraction, Verdict, ScanRecord
  services/     gemma (inference), verdict_engine (decisions), registry (snapshot),
                history, tts, prefs
  screens/      onboarding, home, scan, result, history, settings
  widgets/      verdict banner, counseling, follow-up Q&A, facts
tool/
  build_db.dart        compiles tool/data/*.tsv → assets/db/registry.db (+ self-check)
  scrape_register.py   full FDA register export, for when the public server is reachable
  data/                curated snapshot: real products, real FDA recalls, lookalike pairs
test/verdict_test.dart the safety logic's unit checks
```

## Running it

```sh
flutter pub get
dart run tool/build_db.dart      # rebuild the register snapshot (optional; committed)
flutter run                      # on an Android device (arm64) — the real target
flutter run --dart-define=FAKE_GEMMA=true   # UI development without inference
```

First launch downloads Gemma 4 E2B (2.4GB, ungated, one time, Wi-Fi recommended) — or
import the `.litertlm` file from Settings if you already have it. After that, airplane
mode changes nothing: scanning, verdicts, counseling, and voice Q&A are fully offline.

### The register snapshot

The Ghana FDA's public register (30,000+ products) is served from
`fdaghana.gov.gh/product-register/`; its backend is intermittently unreachable, so the
committed snapshot is a curated subset of real products compiled from FDA Ghana public
alerts, WHO medical product alerts, Ghana's essential medicines list, and common
registered brands (sources per row in [tool/data/products.tsv](tool/data/products.tsv)).
The app labels it honestly as a snapshot. When the server responds,
`tool/scrape_register.py` exports the full register and `tool/build_db.dart` folds it in
automatically.

## Honest limits (v1)

- The snapshot is a subset — "not found" therefore means *verify*, never *fake*.
- Twi output is code-switched everyday Twi; spoken Twi awaits an online Khaya TTS tier.
- Blister packs with tiny embossed dates can defeat OCR; the app asks for better light
  rather than guessing.
- Ewe, Dagbani and Hausa are the next languages on the roadmap.

## License

Apache 2.0. Built with [flutter_gemma](https://pub.dev/packages/flutter_gemma),
Gemma 4 (Google DeepMind), and data from FDA Ghana public notices.
