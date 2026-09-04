#!/usr/bin/env python3
# ============================================================================
#  Pusula — KAP Bildirimi / Şirket Haberi Önbellek Üreticisi (Python)
#  GitHub Actions'ta günde 1 kez, diğer önbellek betikleriyle birlikte çalışır.
#
#  KAP (kap.org.tr) 2024 sonrası tamamen JS-render bir SPA'ya geçti ve kararlı
#  bir genel API'si kalmadı (bkz. scripts/kap.mjs). Aynı stratejiyi burada da
#  izliyoruz: hisse bazında güvenilir ve bakım gerektirmeyen tek kaynak —
#  Yahoo Finance per-symbol RSS (feeds.finance.yahoo.com). KAP özel durum
#  açıklamaları ve şirket haberleri çoğunlukla buraya da düşer.
#
#  Çıktı, mevcut Node önbelleğine (data/cache/kap.json) DOKUNMAZ — ayrı bir
#  klasöre yazar:
#    data/cache/kap_news/<KOD>.json   (hisse başına son bildirimler)
#    data/cache/kap_news/index.json   (tüm evren, tarihe göre sıralı, birleşik)
#    data/cache/kap_news/kap_news.csv (aynı veri, düz tablo — analiz/Excel için)
#
#  Kullanım:
#    python kap_news.py                  # tüm evren
#    python kap_news.py --only ASELS THYAO
# ============================================================================

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import time
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path

import requests

from symbols import BIST_UNIVERSE

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

SCRIPT_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR.parent / "data" / "cache" / "kap_news"
SCHEMA_VERSION = 1

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/122.0 Safari/537.36"
)

# Yahoo'yu yormamak için küçük gruplar + gruplar arası bekleme.
CHUNK = 8
GAP_SEC = 1.0
PER_SYMBOL_LIMIT = 6
REQUEST_TIMEOUT = 15

ITEM_RE = re.compile(r"<item>(.*?)</item>", re.DOTALL | re.IGNORECASE)
TAG_RE_CACHE: dict[str, re.Pattern] = {}


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def decode_entities(s: str | None) -> str | None:
    if not s:
        return None
    s = re.sub(r"<!\[CDATA\[(.*?)\]\]>", r"\1", s, flags=re.DOTALL)
    s = (
        s.replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", '"')
        .replace("&#39;", "'")
        .replace("&amp;", "&")
    )
    return s.strip()


def tag(block: str, name: str) -> str | None:
    pattern = TAG_RE_CACHE.get(name)
    if pattern is None:
        pattern = re.compile(rf"<{name}[^>]*>(.*?)</{name}>", re.DOTALL | re.IGNORECASE)
        TAG_RE_CACHE[name] = pattern
    m = pattern.search(block)
    return decode_entities(m.group(1)) if m else None


def parse_pub_date(raw: str | None) -> str | None:
    if not raw:
        return None
    try:
        dt = parsedate_to_datetime(raw)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc).isoformat()
    except (TypeError, ValueError):
        return None


def parse_rss_items(xml: str) -> list[dict]:
    items = []
    for block in ITEM_RE.findall(xml):
        title = tag(block, "title")
        link = tag(block, "link")
        pub = tag(block, "pubDate") or tag(block, "updated") or tag(block, "published")
        desc = tag(block, "description") or tag(block, "summary")
        summary = re.sub(r"<[^>]+>", "", desc)[:400] if desc else None
        items.append(
            {
                "title": title,
                "link": link,
                "publishedAt": parse_pub_date(pub),
                "summary": summary,
            }
        )
    return items


def fetch_symbol_feed(code: str) -> list[dict]:
    sym = f"{code}.IS"
    url = (
        "https://feeds.finance.yahoo.com/rss/2.0/headline"
        f"?s={sym}&region=TR&lang=tr-TR"
    )
    try:
        res = requests.get(url, headers={"User-Agent": UA}, timeout=REQUEST_TIMEOUT)
        if not res.ok:
            return []
        items = parse_rss_items(res.content.decode("utf-8", errors="replace"))
        for it in items:
            it["code"] = code
        return items[:PER_SYMBOL_LIMIT]
    except requests.RequestException:
        return []


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    kb = path.stat().st_size / 1024
    print(f"  ✓ {path.relative_to(OUT_DIR.parent)}  ({kb:.1f} KB)")


def write_csv(path: Path, rows: list[dict]) -> None:
    fields = ["code", "title", "publishedAt", "link", "summary"]
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k) for k in fields})
    kb = path.stat().st_size / 1024
    print(f"  ✓ {path.relative_to(OUT_DIR.parent)}  ({kb:.1f} KB)")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*", default=None)
    args = parser.parse_args()

    universe = [s.upper() for s in args.only] if args.only else BIST_UNIVERSE

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print(f"▶ KAP / şirket haberi önbelleği başladı — {len(universe)} sembol\n")

    all_items: list[dict] = []
    failures: list[dict] = []

    for i in range(0, len(universe), CHUNK):
        chunk = universe[i : i + CHUNK]
        for code in chunk:
            try:
                items = fetch_symbol_feed(code)
                write_json(
                    OUT_DIR / f"{code}.json",
                    {
                        "schemaVersion": SCHEMA_VERSION,
                        "code": code,
                        "updatedAt": now_iso(),
                        "items": items,
                    },
                )
                all_items.extend(items)
            except Exception as e:
                failures.append({"code": code, "error": str(e)[:200]})
                print(f"  ✗ {code}: {e}")
        if i + CHUNK < len(universe):
            time.sleep(GAP_SEC)

    all_items.sort(key=lambda it: it.get("publishedAt") or "", reverse=True)

    write_json(
        OUT_DIR / "index.json",
        {
            "schemaVersion": SCHEMA_VERSION,
            "updatedAt": now_iso(),
            "generator": "github-actions-python",
            "source": "yahoo-finance-rss",
            "counts": {
                "requested": len(universe),
                "withNews": sum(1 for c in universe if any(it["code"] == c for it in all_items)),
                "totalItems": len(all_items),
                "failed": len(failures),
            },
            "items": all_items,
            "failures": failures,
        },
    )
    write_csv(OUT_DIR / "kap_news.csv", all_items)

    print(
        f"\n✔ Bitti: {len(all_items)} bildirim, {len(universe)} sembol tarandı, "
        f"{len(failures)} hata. Çıktı: data/cache/kap_news/"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
