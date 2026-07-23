# Latency work: inference and language output

Notes on reducing perceived and real latency across the scan → extract →
counsel → follow-up pipeline and the offline text-to-speech path. Written
after landing the changes, so this is a record of what shipped and what it's
built on, not a plan.

## Why

Two things felt slow: waiting on Gemma between a scan and a verdict, and
waiting on the offline voice every time counseling text was read aloud —
especially the second, third, Nth "listen" tap in the same session, and
switching back to a language already generated during the same scan.

## What changed

### Gemma inference (`lib/services/gemma.dart`, `lib/screens/scan.dart`,
`lib/screens/onboarding.dart`)

- **Model warmup.** `Gemma.warmUp()` loads weights and runs one throwaway
  generation to force GPU shader/JIT costs to happen right after onboarding's
  model download finishes, not on the user's first real scan. `_ensureModel()`
  now caches the in-flight `Future`, not just the resolved model, so a scan
  started mid-warmup shares one load instead of racing a second.
- **Speculative decoding.** `enableSpeculativeDecoding: true` on
  `getActiveModel(...)`. Confirmed live on-device that the downloaded
  `.litertlm` bundle includes an `mtp_drafter` section, so this is a real
  decode-time optimization, not a no-op flag.
- **Image resize before `extract()`.** Gemma's vision encoder center-crops
  and resizes to a fixed 896×896 regardless of input size, so anything sent
  above roughly 1024px on the shorter edge is pure wasted transfer/decode.
  `lib/services/image_prep.dart` downscales captured/imported photos to that
  bound (aspect-preserving, off the UI thread via `compute()`) before they
  reach the model. On the reference low-end device (camera capped at
  1280×720) this correctly no-ops — verified in the device log, no behavior
  change there.
- **Streaming extraction with early-abort.** `extract()` now consumes
  `getResponseAsync()` token-by-token instead of blocking on `getResponse()`.
  Since the prompt puts `"legible"` first, an unreadable-photo response
  completes as a tiny JSON object within the first few tokens; detecting that
  early calls `session.stopGeneration()` instead of waiting out the full
  512-token budget.
- **Session reuse for follow-up Q&A only.** `Gemma.startFollowUpChat(...)`
  returns a `FollowUpChat` wrapping one `InferenceChat` per scan. The pack
  facts are sent once with the first question; later questions in the same
  scan reuse the session (its KV-cache) and the model can refer back to an
  earlier answer. Deliberately scoped to the follow-up loop only —
  `extract()` and `counsel()` keep their own tuned temperatures (0.1 and 0.6)
  untouched, avoiding a shared-temperature compromise.

### Offline text-to-speech (`lib/services/tts.dart`, `lib/main.dart`,
`lib/screens/result.dart`)

- **Persistent warm worker isolate.** `Tts.speak()` used to spawn a fresh
  isolate and reload the ~115MB sherpa-onnx VITS model on every single
  "listen" tap (~1s), even the 2nd or 3rd in the same session. It now owns a
  long-lived worker isolate that keeps exactly one loaded voice resident,
  reloading only when the language actually changes.
- **Preloading.** `Tts.warmUp(langCode)` primes a language's voice without
  synthesizing anything. Called on app start for the current language, on
  every language switch (`AduroApp.setLanguage`, the single chokepoint all UI
  language changes go through), and alongside the start of a scan's
  extraction/verdict wait in `result.dart` — using that otherwise-dead time
  to have the voice ready before the user ever reaches "listen".

### Counseling text cache per language (`lib/widgets/counseling_section.dart`)

Switching languages back and forth on the same scan was re-running
`Gemma.instance.counsel()` from scratch every time, even for a language
already generated earlier in the same scan. `_CounselingSectionState` now
keeps a `Map<String, String>` of finished guidance text per language for the
lifetime of that scan's widget; switching back to a cached language shows the
stored text instantly with no new model call. Cache is scoped to one scan
(a fresh `CounselingSection` — and thus a fresh cache — is created whenever
the extraction changes, e.g. after "add another side").

### Small fix (`lib/services/prefs.dart`)

`Prefs._set()`'s disk write is now `writeAsString` instead of
`writeAsStringSync`, since the in-memory `_data` is already updated for reads
and the write itself doesn't need to block the UI thread (most noticeable on
every language switch, which writes a pref).

## Verified on-device (itel S688LN, Android 15, no NPU delegate)

- `flutter analyze`: no issues. `flutter test`: 25/25 passing.
- Full scan → extract → counsel → follow-up flow run live; no crashes,
  exceptions, or `StateError`s in the device log across multiple runs.
- Image resize confirmed correctly inert on this device's 720p camera
  (shorter edge already below the 1024px bound).
- Speculative decoding confirmed active (model file has an `mtp_drafter`
  section, per the native loader's own log).
- Counseling-text language cache confirmed working: switching back to an
  already-generated language in the same scan shows text instantly, with no
  new `counsel()` call in the log.

## Deferred, on purpose

- **Backend-selection caching** (skip re-probing GPU on a device where it's
  known to fail): not built, because it needs a measurement first — the SDK
  already falls back to CPU internally, so there's no confirmed cost to
  cache around yet.
- **Response caching for `counsel()`/`ask()` across scans**: not pursued.
  Low realistic hit rate, and for a medicine-safety tool, silently serving a
  cached answer instead of a fresh model read is a trust trade-off, not a
  pure engineering call.
- **Streamed/incremental TTS audio playback** (`generateWithCallback` +
  playing PCM as it's synthesized, rather than waiting for the full WAV):
  real extra win on longer counseling text, but `audioplayers` isn't built
  for streaming PCM sinks, so it needs either a different playback approach
  or a different audio package. Worth it after the warm-worker win above is
  measured in the field.
