#!/usr/bin/env python3
"""Export a HuggingFace VITS text-to-speech model to sherpa-onnx form.

Aduro Guard speaks with Meta's MMS voices, which ship as ready-made ONNX
exports. Ga and Dagbani have no MMS voice, so for Dagbani we take GhanaNLP's
own VITS checkpoint (same architecture as MMS: VitsModel, 16kHz, 30-symbol
vocabulary) and do the export ourselves.

    python tool/export_vits_onnx.py ghananlpcommunity/dagbani_tts-2025_v2 dag

Writes <out>/model.onnx and <out>/tokens.txt, the two files the app's voice
downloader expects. sherpa-onnx reads the model's metadata to learn its
sample rate and symbol table, so both are written into the graph here.

Needs torch, transformers and onnx; on this Intel Mac that means Python 3.12
with torch 2.2, transformers 4.44 and numpy 1.x pinned together.
"""

import json
import sys
from pathlib import Path

import torch
from transformers import AutoTokenizer, VitsModel


class OnnxVits(torch.nn.Module):
    """Wraps VitsModel so the exported graph takes tokens and returns audio.

    The HuggingFace forward returns a dataclass and accepts keyword-only
    generation settings; ONNX needs plain positional tensors in and one
    tensor out.
    """

    def __init__(self, model: VitsModel):
        super().__init__()
        self.model = model
        self.model.eval()

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor):
        out = self.model(input_ids=input_ids, attention_mask=attention_mask)
        return out.waveform


def main() -> None:
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    repo, lang = sys.argv[1], sys.argv[2]
    out_dir = Path(sys.argv[3]) if len(sys.argv) > 3 else Path("voices") / lang
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"loading {repo}")
    model = VitsModel.from_pretrained(repo)
    tokenizer = AutoTokenizer.from_pretrained(repo)

    # The symbol table sherpa-onnx needs: one "symbol id" line per entry, in
    # id order. VITS vocabularies are single characters plus a blank.
    # sherpa-onnx's character frontend reads this file as "<one symbol> <id>"
    # per line. Two rules come from the MMS exports it already ships with:
    # multi-character entries such as <unk> are not representable and must be
    # dropped, and each letter gets a second line for its uppercase form
    # pointing at the same id, so capitalised input still maps to a symbol.
    vocab = tokenizer.get_vocab()
    by_id = {i: sym for sym, i in vocab.items()}
    tokens_path = out_dir / "tokens.txt"
    written = 0
    with tokens_path.open("w") as f:
        for i in sorted(by_id):
            sym = by_id[i]
            if len(sym) != 1:
                continue  # <unk> and friends: the frontend cannot read them
            f.write(f"{'' if sym == ' ' else sym} {i}\n")
            written += 1
            upper = sym.upper()
            if upper != sym and len(upper) == 1:
                f.write(f"{upper} {i}\n")
                written += 1
    print(f"wrote {tokens_path} ({written} lines)")

    wrapper = OnnxVits(model)
    ids = torch.randint(low=0, high=len(by_id), size=(1, 24), dtype=torch.int64)
    mask = torch.ones_like(ids)
    model_path = out_dir / "model.onnx"
    torch.onnx.export(
        wrapper,
        (ids, mask),
        str(model_path),
        opset_version=13,
        input_names=["x", "x_length_mask"],
        output_names=["y"],
        dynamic_axes={
            "x": {0: "N", 1: "L"},
            "x_length_mask": {0: "N", 1: "L"},
            "y": {0: "N", 2: "T"},
        },
    )

    # sherpa-onnx reads these keys off the graph rather than a side file.
    import onnx

    graph = onnx.load(str(model_path))
    meta = {
        "model_type": "vits",
        # sherpa-onnx picks its text frontend from this key. MMS-style VITS
        # models feed raw characters straight to the model, so without it
        # sherpa-onnx demands a pronunciation lexicon and refuses to load
        # (offline-tts-vits-impl.h: "Not a model using characters as
        # modeling unit").
        "frontend": "characters",
        "comment": f"GhanaNLP VITS, exported for Aduro Guard ({lang})",
        "language": lang,
        "add_blank": str(int(getattr(model.config, "add_blank", True))),
        "sample_rate": str(model.config.sampling_rate),
        "n_speakers": "1",
        "has_espeak": "0",
    }
    for k, v in meta.items():
        entry = graph.metadata_props.add()
        entry.key, entry.value = k, v
    onnx.save(graph, str(model_path))

    size_mb = model_path.stat().st_size / 1e6
    print(f"wrote {model_path} ({size_mb:.1f} MB)")
    print(json.dumps(meta, indent=2))


if __name__ == "__main__":
    main()
