#!/usr/bin/env python3
"""Export the Ghana FDA public product register to tool/data/register_live.tsv.

The register is a Laravel DataTables app at
https://verifypermit.fdaghana.gov.gh/publicsearch (an earlier deployment sat
at http://196.61.32.245:55). It answers normal GETs with HTML and AJAX GETs
(X-Requested-With: XMLHttpRequest) with JSON pages carrying full product
records: registration_number, product_name, generic_name, manufacturer,
client_name, product_category, expiry_date (registration validity), status.

Only the seven columns written below are kept, raw responses are never
saved, and the manufacturer is cut down to the business name: the register
appends postal addresses, GhanaPost GPS codes and phone numbers, which for
sole traders are personal data.

Run this whenever the server is up; if register_live.tsv exists,
tool/build_db.dart folds it into the app database automatically. Resumes from
the last saved offset.
"""

import html
import json
import re
import ssl
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

BASE = "https://verifypermit.fdaghana.gov.gh/publicsearch"

# The government server's TLS certificate was expired at scrape time; this is
# public read-only data, so skip verification rather than wait for their renewal.
SSL_CTX = ssl.create_default_context()
SSL_CTX.check_hostname = False
SSL_CTX.verify_mode = ssl.CERT_NONE
OUT = Path(__file__).parent / "data" / "register_live.tsv"
STATE = Path(__file__).parent / "data" / ".scrape_state"
PAGE = 200  # matches the app's own lengthMenu
TAG = re.compile(r"<[^>]+>")

COLS = ["DT_RowIndex", "client_name", "product_name", "product_category", "expiry_date", "status", "action"]


def dt_params(start: int, length: int, query: str = "") -> str:
    p: dict[str, str] = {"draw": "1", "start": str(start), "length": str(length), "search[value]": query, "search[regex]": "false"}
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


def fetch_page(start: int, length: int, query: str = "") -> dict:
    req = urllib.request.Request(
        f"{BASE}?{dt_params(start, length, query)}",
        headers={"X-Requested-With": "XMLHttpRequest", "Accept": "application/json", "User-Agent": "aduro-data-prep (hackathon demo snapshot)"},
    )
    with urllib.request.urlopen(req, timeout=45, context=SSL_CTX) as r:
        return json.loads(r.read())


def clean(v) -> str:
    s = html.unescape(TAG.sub("", str(v or "")))
    # Plain tab-joined lines: the Dart reader does a naive split, so tabs,
    # newlines and CRs inside values must die here.
    return re.sub(r"[\t\r\n]+", " ", s).strip()


# ponytail: heuristic, cuts at the first thing that looks like an address;
# a street name with no number or separator can survive. Tighten if seen.
ADDRESS = re.compile(
    r"[,;]|\s[-–]\s|\s[-–]?\d|\s\S*\d"  # separators, or the first word holding a digit
    r"|\bP\.?\s*O\.?\s*BOX\b|\bPLOT\b|\bH/NO\b|\bH(?:OUSE|SE)\.?\s*NO\b"
    r"|\b(?:OFF|NEAR|OPP|OPPOSITE|BEHIND|ADJACENT)\b"
    r"|\b[A-Z]{2}-?\d{3,4}-?\d{3,4}\b",  # GhanaPost GPS code
    re.I)
SUFFIX = re.compile(
    r"^.*?\b(?:LTD|LIMITED|INC|PLC|LLC|GMBH|CORP|CORPORATION|ENT|ENTERPRISES?|VENTURES)\b\.?"
    r"(?:\s+(?:LTD|LIMITED|INC|CO)\b\.?)*", re.I)


def maker_name(m: str) -> str:
    """The business name alone: no address, GPS code or phone number."""
    c = ADDRESS.search(m)
    if c:
        m = m[:c.start()]
    s = SUFFIX.match(m)
    if s:
        m = s.group(0)
    m = re.sub(r"[\s.,-]+$", "", m).strip()
    return m if len(m) > 2 and not m[0].isdigit() else ""


assert maker_name("Aayansh Wellness Pvt. Ltd - 12, Vinayak Estate, India") == "Aayansh Wellness Pvt. Ltd"
assert maker_name("Kofi Herbal Ent., GA-123-4567, Accra") == "Kofi Herbal Ent"
assert maker_name("Ama Foods GA-0415-1993 Tema") == "Ama Foods"
assert maker_name("ACME LTD 0244 123 456") == "ACME LTD"
assert maker_name("P.O. Box 123, Accra") == ""


def main() -> None:
    start = int(STATE.read_text()) if STATE.exists() else 0
    mode = "a" if start else "w"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open(mode) as f:
        # No csv module: quoting would confuse the app's naive tab-split reader.
        def w(row: list[str]) -> None:
            f.write("\t".join(row) + "\n")

        if not start:
            w(["product_name", "generic", "manufacturer", "category", "reg_no", "registration_expiry", "status"])
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
                w([
                    clean(r.get("product_name")),
                    clean(r.get("generic_name")),
                    maker_name(clean(r.get("manufacturer")) or clean(r.get("client_name"))),
                    clean(r.get("product_category")),
                    clean(r.get("registration_number")),
                    clean(r.get("expiry_date")),
                    clean(r.get("status")),
                ])
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
