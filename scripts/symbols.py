# BIST evreni — artık statik değil, TradingView'in genel scanner API'sinden
# dinamik olarak keşfedilir (tüm işlem gören hisseler + BYF/ETF'ler + kapalı
# uçlu yatırım ortaklıkları). Node tarafı (scripts/symbols.mjs) hâlâ elle
# tutulan küçük bir alt kümeyi kullanır; bu dosya (Python) tam evreni hedefler.
#
# Ağ isteği başarısız olursa (rate-limit, geçici kesinti) FALLBACK_UNIVERSE'e
# düşülür, böylece script asla boş evrenle çalışmaz.

from __future__ import annotations

import json
import sys
from pathlib import Path

import requests

SCRIPT_DIR = Path(__file__).resolve().parent
CACHE_FILE = SCRIPT_DIR / ".universe_cache.json"

TRADINGVIEW_SCAN_URL = "https://scanner.tradingview.com/turkey/scan"
UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/122.0 Safari/537.36"
)

INDEX_SYMBOL = "XU100.IS"

# Son çare: TradingView erişilemezse kullanılan küçük, likit alt küme
# (önceki elle tutulan liste). Script'in tamamen boş dönmesini engeller.
FALLBACK_UNIVERSE = [
    "ASELS", "THYAO", "TUPRS", "BIMAS", "KCHOL", "SAHOL", "FROTO", "TOASO",
    "SISE", "EREGL", "KRDMD", "PETKM", "OYAKC", "TCELL", "PGSUS", "AEFES",
    "CCOLA", "MGROS", "ULKER", "TAVHL", "ENKAI", "SASA", "ALARK", "HEKTS",
    "GUBRF", "VESTL", "ARCLK", "TKFEN", "DOAS", "ISDMR", "YKBNK", "AKBNK",
    "GARAN", "ISCTR", "HALKB", "VAKBN", "TTKOM", "BRSAN", "KONTR", "SMRTG",
    "ODAS", "ENJSA", "AKSEN", "ZOREN", "CIMSA", "AGHOL", "BUCIM", "OTKAR",
    "KARSN", "TTRAK", "EKGYO", "ISGYO", "TSKB", "ALBRK", "SKBNK", "MPARK",
    "LKMNH", "SELEC", "BAGFS", "GLYHO", "MAVI",
]

# Katılım Endeksi'ne uygun (faizsiz) hisseler — uygulamadaki liste ile aynı olmalı.
PARTICIPATION = {
    "ASELS", "BIMAS", "FROTO", "TOASO", "TUPRS", "EREGL", "KRDMD", "PETKM",
    "SASA", "HEKTS", "GUBRF", "BAGFS", "CIMSA", "BUCIM", "OYAKC", "ENKAI",
    "TKFEN", "OTKAR", "TTRAK", "KONTR", "SMRTG", "ODAS", "AKSEN", "ZOREN",
    "MGROS", "ULKER", "CCOLA", "AEFES", "SELEC", "MPARK", "LKMNH", "MAVI",
}


def _fetch_tradingview_universe(timeout: int = 20) -> list[dict]:
    """TradingView'in genel scanner API'sinden BIST'teki tüm sembolleri çeker.

    type/subtype ile sınıflandırılmış döner:
      - ('stock', 'common')     : adi hisse senetleri
      - ('fund', 'etf')         : borsa yatırım fonları (BYF)
      - ('fund', 'closedend')   : kapalı uçlu yatırım ortaklıkları
    """
    payload = {
        "filter": [{"left": "exchange", "operation": "equal", "right": "BIST"}],
        "columns": ["name", "description", "type", "subtype"],
        "range": [0, 1000],
    }
    res = requests.post(
        TRADINGVIEW_SCAN_URL,
        json=payload,
        headers={"User-Agent": UA, "Content-Type": "application/json"},
        timeout=timeout,
    )
    res.raise_for_status()
    body = res.json()
    rows = body.get("data", [])

    result = []
    for row in rows:
        code, name, kind, subtype = row["d"][0], row["d"][1], row["d"][2], row["d"][3]
        code = str(code).strip().upper()
        if not code.isalnum():
            continue
        result.append({"code": code, "name": name, "type": kind, "subtype": subtype})
    return result


def discover_universe(*, use_cache_fallback: bool = True, save_cache: bool = True) -> list[dict]:
    """Tüm BIST evrenini (hisse + BYF + kapalı uçlu fon) döner.

    Her satır {"code", "name", "type", "subtype"} içerir. Ağ hatası durumunda
    son başarılı sonucun yerel önbelleğine, o da yoksa FALLBACK_UNIVERSE'e düşer.
    """
    try:
        rows = _fetch_tradingview_universe()
        if not rows:
            raise ValueError("TradingView boş liste döndürdü")
        if save_cache:
            try:
                CACHE_FILE.write_text(
                    json.dumps(rows, ensure_ascii=False), encoding="utf-8"
                )
            except OSError:
                pass
        return rows
    except Exception as e:
        print(f"[Uyarı] TradingView evren keşfi başarısız: {e}", file=sys.stderr)
        if use_cache_fallback and CACHE_FILE.exists():
            try:
                cached = json.loads(CACHE_FILE.read_text(encoding="utf-8"))
                if cached:
                    print(
                        f"[Bilgi] Yerel önbellekten {len(cached)} sembol kullanılıyor.",
                        file=sys.stderr,
                    )
                    return cached
            except (OSError, json.JSONDecodeError):
                pass
        print(
            f"[Bilgi] Sabit FALLBACK_UNIVERSE kullanılıyor ({len(FALLBACK_UNIVERSE)} sembol).",
            file=sys.stderr,
        )
        return [{"code": c, "name": None, "type": "stock", "subtype": "common"} for c in FALLBACK_UNIVERSE]


def get_universe_codes(*, kinds: set[tuple[str, str]] | None = None) -> list[str]:
    """Sadece sembol kodlarının düz listesini döner (alfabetik sıralı).

    kinds verilirse yalnızca o (type, subtype) çiftlerine ait semboller alınır,
    örn. {("stock", "common")} yalnızca adi hisseler, None ise hepsi.
    """
    rows = discover_universe()
    if kinds is not None:
        rows = [r for r in rows if (r["type"], r["subtype"]) in kinds]
    return sorted({r["code"] for r in rows})


# NOT: Modül import edildiğinde ağ isteği YAPILMAZ. Betikler evreni almak için
# açıkça get_universe_codes() çağırmalı (BIST_UNIVERSE sabit değişkeni artık
# yok — dinamik keşif her çalıştırmada güncel sonuç vermeli, import zamanında
# donmuş bir listeye ihtiyaç duymamalı).
