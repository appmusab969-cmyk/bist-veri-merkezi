#!/usr/bin/env python3
# ============================================================================
#  Pusula — Türkçe Temel Analiz / Bilanço Önbellek Üreticisi
#  GitHub Actions'ta günde 1 kez, Node build-cache.mjs ile birlikte çalışır.
#
#  Fiyat / piyasa verisi : yfinance          (Yahoo Finance)
#  Bilanço / temel veri  : isyatirimhisse    (İş Yatırım)
#
#  Çıktı, mevcut Node önbelleğinin (data/cache/stock, index.json) ŞEMASINA
#  DOKUNMAZ — ayrı bir alt klasöre yazar:
#    data/cache/fundamentals_tr/<KOD>.json   (bilanço + oranlar, İş Yatırım)
#    data/cache/prices_tr/<KOD>.csv          (günlük OHLCV, yfinance)
#    data/cache/fundamentals_tr/index.json   (özet + hata listesi)
#
#  Kullanım:
#    python build_fundamentals.py                  # tüm evren
#    python build_fundamentals.py --only ASELS THYAO
# ============================================================================

from __future__ import annotations

import argparse
import json
import math
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

import pandas as pd
import yfinance as yf
from isyatirimhisse import fetch_financials

from symbols import get_universe_codes, INDEX_SYMBOL

SCRIPT_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR.parent / "data" / "cache"
FUNDAMENTALS_DIR = OUT_DIR / "fundamentals_tr"
PRICES_DIR = OUT_DIR / "prices_tr"
SCHEMA_VERSION = 1

# İş Yatırım'ı yormamak için sembol grupları arasında bekleme.
CHUNK = 5
GAP_SEC = 1.5


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def to_yahoo_symbol(code: str) -> str:
    code = code.strip().upper()
    return code if "." in code else f"{code}.IS"


def clean_number(value):
    """NaN/Inf -> None; numpy sayısal tipleri -> yerel Python tipi."""
    if value is None:
        return None
    try:
        f = float(value)
    except (TypeError, ValueError):
        return None
    if math.isnan(f) or math.isinf(f):
        return None
    return f


def fetch_price_data(code: str) -> dict:
    """yfinance: güncel fiyat + son 1 yıllık günlük OHLCV."""
    sym = to_yahoo_symbol(code)
    ticker = yf.Ticker(sym)

    hist = ticker.history(period="1y", interval="1d", auto_adjust=False)
    if hist.empty:
        raise ValueError(f"yfinance: boş geçmiş veri ({sym})")

    hist = hist.reset_index()
    hist.to_csv(PRICES_DIR / f"{code}.csv", index=False)

    last = hist.iloc[-1]
    prev_close = float(hist.iloc[-2]["Close"]) if len(hist) > 1 else float(last["Close"])
    price = float(last["Close"])

    info = {}
    try:
        info = ticker.info or {}
    except Exception:
        info = {}

    return {
        "symbol": sym,
        "code": code,
        "shortName": info.get("shortName") or info.get("longName") or code,
        "longName": info.get("longName"),
        "sector": info.get("sector"),
        "industry": info.get("industry"),
        "currency": info.get("currency") or "TRY",
        "price": clean_number(price),
        "previousClose": clean_number(prev_close),
        "change": clean_number(price - prev_close),
        "changePercent": clean_number(
            ((price - prev_close) / prev_close) * 100 if prev_close else 0
        ),
        "dayLow": clean_number(info.get("dayLow")),
        "dayHigh": clean_number(info.get("dayHigh")),
        "fiftyTwoWeekLow": clean_number(info.get("fiftyTwoWeekLow")),
        "fiftyTwoWeekHigh": clean_number(info.get("fiftyTwoWeekHigh")),
        "marketCap": clean_number(info.get("marketCap")),
        "volume": clean_number(info.get("volume")),
        "trailingPE": clean_number(info.get("trailingPE")),
        "forwardPE": clean_number(info.get("forwardPE")),
        "priceToBook": clean_number(info.get("priceToBook")),
        "dividendYield": clean_number(info.get("dividendYield")),
        "candleCount": len(hist),
    }


def financials_to_records(df: pd.DataFrame) -> list[dict]:
    """İş Yatırım'ın geniş (dönem-sütunlu) tablosunu dönem başına satırlara çevirir."""
    period_cols = [
        c for c in df.columns
        if c not in ("FINANCIAL_ITEM_CODE", "FINANCIAL_ITEM_NAME_TR",
                     "FINANCIAL_ITEM_NAME_EN", "SYMBOL")
    ]
    records = []
    for _, row in df.iterrows():
        item = {
            "code": row["FINANCIAL_ITEM_CODE"],
            "nameTr": row["FINANCIAL_ITEM_NAME_TR"],
            "nameEn": row.get("FINANCIAL_ITEM_NAME_EN"),
            "values": {p: clean_number(row[p]) for p in period_cols},
        }
        records.append(item)
    return records


FINANCIAL_GROUP_LABELS = {"1": "XI_29", "2": "UFRS", "3": "UFRS_K"}


def fetch_fundamentals(code: str, current_year: int) -> dict:
    """isyatirimhisse: son 3 yıllık bilanço/gelir tablosu kalemleri.

    Sanayi şirketleri 'XI_29' (grup 1) formatını kullanır; bankalar ve bazı
    finans kuruluşları farklı bir bilanço şablonuna (UFRS, grup 2) sahiptir.
    Grup 1 boş dönerse grup 2, o da boş dönerse grup 3 denenir.
    """
    last_error = None
    for group in ("1", "2", "3"):
        try:
            df = fetch_financials(
                [code],
                start_year=current_year - 2,
                end_year=current_year,
                financial_group=group,
            )
        except Exception as e:
            last_error = e
            continue
        if df is not None and not df.empty:
            return {
                "source": "isyatirimhisse",
                "financialGroup": FINANCIAL_GROUP_LABELS[group],
                "items": financials_to_records(df),
            }
    raise ValueError(f"İş Yatırım: boş bilanço verisi ({code}): {last_error}")


def build_one(code: str, current_year: int) -> dict:
    price = fetch_price_data(code)
    fundamentals_error = None
    fundamentals = None
    try:
        fundamentals = fetch_fundamentals(code, current_year)
    except Exception as e:  # İş Yatırım tarafı ayrı başarısız olabilir; fiyatı kaybetme.
        fundamentals_error = str(e)[:200]

    return {
        "schemaVersion": SCHEMA_VERSION,
        "code": code,
        "updatedAt": now_iso(),
        "price": price,
        "fundamentals": fundamentals,
        "fundamentalsError": fundamentals_error,
        "partial": fundamentals is None,
    }


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    kb = path.stat().st_size / 1024
    print(f"  ✓ {path.relative_to(OUT_DIR)}  ({kb:.1f} KB)")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", nargs="*", default=None)
    parser.add_argument(
        "--resume",
        action="store_true",
        help="fundamentals_tr/<KOD>.json zaten var olan sembolleri atla",
    )
    args = parser.parse_args()

    universe = [s.upper() for s in args.only] if args.only else get_universe_codes()

    FUNDAMENTALS_DIR.mkdir(parents=True, exist_ok=True)
    PRICES_DIR.mkdir(parents=True, exist_ok=True)

    if args.resume:
        done = {p.stem for p in FUNDAMENTALS_DIR.glob("*.json") if p.stem != "index"}
        skipped = len(universe) - len([c for c in universe if c not in done])
        universe = [c for c in universe if c not in done]
        print(f"[Bilgi] --resume: {skipped} sembol zaten var, atlandı.\n")

    print(f"▶ Türkçe temel analiz önbelleği başladı — {len(universe)} sembol\n")

    current_year = datetime.now().year
    summary_rows = []
    failures = []

    for i in range(0, len(universe), CHUNK):
        chunk = universe[i : i + CHUNK]
        for code in chunk:
            try:
                result = build_one(code, current_year)
                write_json(FUNDAMENTALS_DIR / f"{code}.json", result)
                summary_rows.append(
                    {
                        "code": code,
                        "name": result["price"].get("longName") or result["price"].get("shortName"),
                        "price": result["price"].get("price"),
                        "changePercent": result["price"].get("changePercent"),
                        "hasFundamentals": result["fundamentals"] is not None,
                    }
                )
            except Exception as e:
                failures.append({"code": code, "error": str(e)[:200]})
                print(f"  ✗ {code}: {e}")
        if i + CHUNK < len(universe):
            time.sleep(GAP_SEC)

    write_json(
        FUNDAMENTALS_DIR / "index.json",
        {
            "schemaVersion": SCHEMA_VERSION,
            "updatedAt": now_iso(),
            "generator": "github-actions-python",
            "sources": {"price": "yfinance", "fundamentals": "isyatirimhisse"},
            "counts": {
                "requested": len(universe),
                "ok": len(summary_rows),
                "failed": len(failures),
            },
            "stocks": sorted(summary_rows, key=lambda r: r["code"]),
            "failures": failures,
        },
    )

    print(
        f"\n✔ Bitti: {len(summary_rows)}/{len(universe)} sembol, "
        f"{len(failures)} hata. Çıktı: data/cache/fundamentals_tr/, data/cache/prices_tr/"
    )

    return 1 if not summary_rows else 0


if __name__ == "__main__":
    sys.exit(main())
