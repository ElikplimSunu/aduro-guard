#!/usr/bin/env python3
"""Export the Ghana FDA public product register to tool/data/register_live.tsv.

The register (linked from fdaghana.gov.gh/product-register/) is a Laravel
DataTables app at http://196.61.32.245:55/publicsearch. It answers normal GETs
with HTML and AJAX GETs (X-Requested-With: XMLHttpRequest) with JSON pages of
{DT_RowIndex, client_name, product_name, product_category, expiry_date, status}.

The server is intermittently unreachable. Run this whenever it is up; if
register_live.tsv exists, tool/build_db.dart folds it into the app database
automatically. Resumes from the last saved offset.
"""

import csv
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

BASE = "http://196.61.32.245:55/publicsearch"
OUT = Path(__file__).parent / "data" / "register_live.tsv"
STATE = Path(__file__).parent / "data" / ".scrape_state"
PAGE = 200  # matches the app's own lengthMenu
TAG = re.compile(r"<[^>]+>")

COLS = ["DT_RowIndex", "client_name", "product_name", "product_category", "expiry_date", "status", "action"]


def dt_params(start: int, length: int) -> str:
    p: dict[str, str] = {"draw": "1", "start": str(start), "length": str(length), "search[value]": "", "search[regex]": "false"}
    for i, c in enumerate(COLS):
        p[f"columns[{i}][data]"] = c
        p[f"columns[{i}][name]"] = {"client_name": "tbl_client_details.client_name", "status": "tbl_products_details.status"}.get(c, c)
        p[f"columns[{i}][searchable]"] = "false" if c in ("DT_RowIndex", "action") else "true"
        p[f"columns[{i}][orderable]"] = "false" if c in ("DT_RowIndex", "action") else "true"
        p[f"columns[{i}][search][value]"] = ""
        p[f"columns[{i}][search][regex]"] = "false"
    p["order[0][column]"] = "2"  # product_name, stable order for resumable paging
    p["order[0][dir]"] = "asc"
    return urllib.parse.urlencode(p)


def fetch_page(start: int, length: int) -> dict:
    req = urllib.request.Request(
        f"{BASE}?{dt_params(start, length)}",
        headers={"X-Requested-With": "XMLHttpRequest", "Accept": "application/json", "User-Agent": "aduro-data-prep (hackathon demo snapshot)"},
    )
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read())


def clean(v) -> str:
    return TAG.sub("", str(v or "")).replace("\t", " ").strip()


def main() -> None:
    start = int(STATE.read_text()) if STATE.exists() else 0
    mode = "a" if start else "w"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open(mode, newline="") as f:
        w = csv.writer(f, delimiter="\t")
        if not start:
            w.writerow(["product_name", "manufacturer", "category", "registration_expiry", "status"])
        while True:
            try:
                page = fetch_page(start, PAGE)
            except Exception as e:  # noqa: BLE001
                print(f"stopped at offset {start}: {e}\nre-run to resume", file=sys.stderr)
                STATE.write_text(str(start))
                sys.exit(1)
            rows = page.get("data", [])
            total = page.get("recordsTotal", "?")
            for r in rows:
                w.writerow([clean(r.get("product_name")), clean(r.get("client_name")), clean(r.get("product_category")), clean(r.get("expiry_date")), clean(r.get("status"))])
            start += len(rows)
            print(f"{start}/{total}")
            STATE.write_text(str(start))
            if not rows or (isinstance(total, int) and start >= total):
                break
            time.sleep(1.0)  # ponytail: fixed polite delay; tune only if the export is huge
    STATE.unlink(missing_ok=True)
    print(f"done -> {OUT}")


if __name__ == "__main__":
    main()
