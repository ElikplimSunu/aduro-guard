# Offline voices: what we ship, and what we tried

Aduro Guard reads its guidance aloud without a network. English uses the
phone's own text-to-speech engine. The Ghanaian languages need real voice
models on the device.

## What ships

| Language | Voice | Source |
| --- | --- | --- |
| English | device TTS | Android, via `flutter_tts` |
| Twi | MMS `aka` | [willwade/mms-tts-multilingual-models-onnx](https://huggingface.co/willwade/mms-tts-multilingual-models-onnx) |
| Ewe | MMS `ewe` | same |
| Hausa | MMS `hau` | same |
| Ga | none | text only |
| Dagbani | none | text only |

The three MMS voices are VITS models from Meta's Massively Multilingual
Speech project (CC BY-NC 4.0), taken as community ONNX exports. Each is an
optional one-time download of roughly 115 MB, stored under
`documents/voices/<code>/` and synthesized on device by `sherpa_onnx` in a
persistent warm worker isolate.

## Ga: no model exists

There is no open text-to-speech model for Ga that we can find. Meta's MMS
does not include `gaa`. GhanaNLP publishes about a hundred models and none of
them is Ga TTS; their Ghanaian collections cover Twi, Ewe, Dagbani, Hausa,
Yoruba, Krio, Luganda, Swahili and others, but not Ga. GhanaNLP's hosted
Khaya API does offer Ga speech, but it is an online service, which is exactly
the dependency this app exists to remove.

So Ga ships as text: the interface, the verdicts and the counseling are all
in Ga, and the read-aloud button simply does not appear.

## Dagbani: a model exists, our export does not run yet

GhanaNLP publishes
[ghananlpcommunity/dagbani_tts-2025_v2](https://huggingface.co/ghananlpcommunity/dagbani_tts-2025_v2),
a VITS checkpoint with the same shape as the MMS voices we already use:
`VitsModel`, 16 kHz, a 30-symbol vocabulary. On paper it drops straight into
the existing sherpa-onnx path, so we wrote
[tool/export_vits_onnx.py](../tool/export_vits_onnx.py) to convert it.

How far that got, in order:

1. **Export runs.** The checkpoint converts to a 114 MB ONNX graph.
2. **sherpa-onnx rejected the frontend.** It picks a text frontend from the
   graph metadata; without `frontend=characters` it demands a pronunciation
   lexicon. Adding that key fixed it.
3. **sherpa-onnx rejected the token file.** Its character frontend reads
   `<one symbol> <id>` per line, so the tokenizer's multi-character `<unk>`
   entry is unreadable and has to be dropped, and each letter needs a second
   line for its uppercase form pointing at the same id, the way the MMS token
   files do. Fixed.
4. **Generation segfaults.** This is where it stands. Our graph takes the
   HuggingFace forward signature, `(input_ids, attention_mask)`, but
   sherpa-onnx feeds a VITS model `x`, `x_length` and the noise and length
   scales as separate tensors. The shapes do not line up and the native
   library aborts.

Closing that gap means exporting VITS inference with the scales threaded
through as tensor inputs rather than read from the config, which is a
rewrite of the model's forward pass rather than a wrapper around it. It is
tractable, and the script is committed so the next person starts from step 4
instead of step 1, but it is not something to land untested in a medicine
app.

One thing that failure taught us, and that is fixed: voice models load
through native code, so a bad one aborts the process instead of throwing an
error Dart can catch. The app used to warm the current language's voice at
launch, which turned a bad voice into an app that would not start at all and
could only be recovered by clearing its data. Voices now warm on the result
screen instead, where the worst case costs one screen rather than the whole
app.

## Refreshing or adding a voice

```sh
# needs torch 2.2 / transformers 4.44 / numpy 1.x on Python 3.12
python tool/export_vits_onnx.py <hf-repo-id> <lang-code> voices/<lang-code>
```

The app looks for `model.onnx` and `tokens.txt` per language. MMS voices come
from the Hugging Face repo above; anything we export ourselves is served from
this repository's releases. See `lib/services/voices.dart`.
