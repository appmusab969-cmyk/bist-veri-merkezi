# Pusula — Veri Önbellek Sistemi

10.000 aktif kullanıcıyı **0 TL** maliyetle taşımak için tasarlanmış statik
önbellek mimarisi.

## Neden?

Uygulamanın önceki hâlinde **her kullanıcı açılışta** doğrudan Yahoo Finance'e
4+ istek atıyordu. 10.000 kullanıcı = dakikada binlerce istek = rate-limit,
IP ban, tutarsız veri.

Çözüm: dış kaynaklar günde **1 kez**, arka planda sorgulanır; sonuç statik
JSON'a yazılır; kullanıcılar bu JSON'u global CDN'den okur.

```
┌─────────────────────┐   günde 1x    ┌──────────────────┐
│  GitHub Actions      │──────────────▶│ Yahoo Finance    │  fiyat, temel,
│  (cron 07:30 UTC)    │               │ (chart + summary)│  OHLC seri
│  scripts/build-cache │──────────────▶│ Yahoo per-symbol │  haber / KAP
│                      │               │ RSS              │  bildirimleri
│         │            │               └──────────────────┘
│         ▼            │
│  data/cache/*.json ──┼──▶ repoya commit
└─────────────────────┘
          │
          ▼  jsDelivr CDN  (ücretsiz, sınırsız, global)
┌─────────────────────┐
│  Flutter uygulaması  │  MarketRepository → CacheClient
│  • 1 statik istek     │  bellek → disk → CDN → raw.githubusercontent
│  • çevrimdışı çalışır │  (ilk başarılı kazanır)
│  • grafik: TradingView│  WebView widget — bize/Yahoo'ya yük yok
└─────────────────────┘
```

## Üretilen dosyalar (`data/cache/`)

| Dosya | İçerik | Uygulamada kim okur |
|---|---|---|
| `index.json` | Endeks + tüm evren için özet satır (fiyat, %değişim, spark, katılım) + `failures` | Ana Sayfa, Formasyonlar |
| `stock/<KOD>.json` | Tam `detail` (rasyolar, bilanço, tavsiye) + 1 yıllık OHLC | Hisse Detay |
| `kap.json` | Bildirim/haber akışı (hisse kodu eşlemeli) | Hisse Detay → KAP & Risk |
| `fundamentals_tr/<KOD>.json` | yfinance fiyat özeti + İş Yatırım'dan son 3 yıllık bilanço/gelir tablosu kalemleri | (opsiyonel, Node önbelleğini tamamlar) |
| `fundamentals_tr/index.json` | Python üretiminin özeti + `failures` | — |
| `prices_tr/<KOD>.csv` | yfinance'ten 1 yıllık günlük OHLCV | — |
| `kap_news/<KOD>.json` | Hisse başına son bildirimler/haberler (Yahoo per-symbol RSS) | — |
| `kap_news/index.json` | Tüm evren, tarihe göre sıralı birleşik akış + `failures` | — |
| `kap_news/kap_news.csv` | Aynı bildirim verisi düz tablo (analiz/Excel için) | — |

`fundamentals_tr/`, `prices_tr/` ve `kap_news/`, sırasıyla `build_fundamentals.py`
ve `kap_news.py` (Python) tarafından üretilir; mevcut Node şemasına (`stock/`,
`index.json`, `kap.json`) hiç dokunmazlar — ayrı bir veri kaynağı olarak
dururlar, ileride uygulamaya entegre edilebilirler.

Tüm sayısal alanlar **ham** tutulur; sektör ortalaması, 10 yıllık bant,
Piotroski/Altman skorları uygulamada **istemci tarafında** türetilir
(`lib/models/fundamental_analysis.dart`). Script asla finansal hesap yapmaz —
sadece güvenilir alanları isimlendirir.

## Kurulum

### 1. Depoyu GitHub'a itin

```bash
git add .
git commit -m "feat: statik önbellek sistemi"
git push
```

### 2. Uygulamayı depoya bağlayın

`lib/services/cache_config.dart` içinde:

```dart
static const String ghUser   = 'GITHUB_KULLANICI_ADIN';
static const String ghRepo   = 'pusula';
static const String ghBranch = 'main';
```

`ghUser` hâlâ `KULLANICI_ADIN` ise uygulama otomatik olarak **canlı Yahoo**
moduna düşer (geliştirme için pratik, ölçek için değil).

### 3. GitHub Actions'ı etkinleştirin

`.github/workflows/build-cache.yml` hazır. Depo → **Settings → Actions →
General → Workflow permissions → "Read and write permissions"** seçili olmalı
(iş akışının `data/cache`'i commit edebilmesi için).

İlk çalıştırma: **Actions → Build data cache → Run workflow**.

Sonrası: her gün 07:30 UTC (≈ 10:30 TR, BIST açılışından sonra) otomatik.

### 4. (İsteğe bağlı) jsDelivr tazeleme

jsDelivr dal-bazlı istekleri ~12 saat önbelleğe alır. Anında tazelemek için
commit sonrası bir kez şu adres çağrılabilir:
`https://purge.jsdelivr.net/gh/<user>/<repo>@<branch>/data/cache/index.json`
(workflow'a eklenebilir; zorunlu değil).

## Elle çalıştırma (yerel)

```bash
cd scripts
node build-cache.mjs                    # tüm evren
node build-cache.mjs --only ASELS THYAO # alt küme (hızlı test)
```

Node 20+ gerekir. Bağımlılık yok (yerleşik `fetch`).

### Python — Türkçe temel analiz / bilanço

```bash
cd scripts
pip install -r requirements.txt
python build_fundamentals.py                    # tüm evren
python build_fundamentals.py --only ASELS THYAO  # alt küme (hızlı test)
```

Python 3.10+ gerekir. Fiyat/piyasa verisi **yfinance**'ten, bilanço/gelir
tablosu kalemleri **isyatirimhisse** (İş Yatırım) üzerinden çekilir.
Bankalar farklı bir bilanço şablonu (UFRS) kullandığından script sırasıyla
XI_29 → UFRS → UFRS_K gruplarını dener ve ilk dolu sonucu kullanır.

### Python — KAP bildirimi / şirket haberi

```bash
cd scripts
pip install -r requirements.txt
python kap_news.py                    # tüm evren
python kap_news.py --only ASELS THYAO # alt küme (hızlı test)
```

KAP'ın (kap.org.tr) 2024 sonrası kararlı bir genel API'si kalmadığından
(tamamen JS-render SPA), `scripts/kap.mjs` ile aynı stratejiyi izler: hisse
başına Yahoo Finance RSS akışı (KAP özel durum açıklamaları çoğunlukla buraya
da düşer). Tüm istekler başarısız olursa boş liste döner, script hata vermez.

## Evren: artık dinamik (TÜM BIST)

`scripts/symbols.mjs` (Node) ve `scripts/symbols.py` (Python), BIST'te işlem
gören **tüm** hisseleri + borsa yatırım fonlarını (BYF) + kapalı uçlu yatırım
ortaklıklarını TradingView'in genel scanner API'sinden (`scanner.tradingview.com`)
her çalıştırmada dinamik olarak çeker — elle tutulan sabit bir liste yok.

- `discoverUniverse()` / `discover_universe()`: ham sonucu `{code, name, type,
  subtype}` olarak döner (`type/subtype`: `stock/common` adi hisse,
  `fund/etf` BYF, `fund/closedend` kapalı uçlu yatırım ortaklığı).
- `getUniverseCodes()` / `get_universe_codes()`: yalnızca kod listesini döner,
  isteğe bağlı `kinds` filtresiyle alt küme alınabilir.

TradingView'e erişilemezse (rate-limit, geçici kesinti) sırasıyla yerel
`.universe_cache.json` dosyasına, o da yoksa küçük sabit `FALLBACK_UNIVERSE`
listesine düşülür — script hiçbir zaman boş evrenle çalışmaz. Bu iki dosya
(`.mjs`/`.py`) aynı TradingView endpoint'ini ve filtreyi kullanır ama
birbirinden bağımsız import edildiği için mantık değişikliği HER İKİSİNE de
uygulanmalıdır.

**Not:** Tam evren (~650 sembol) ile çalıştırmalar önemli ölçüde daha uzun
sürer (Node fiyat/temel: onlarca dakika; Python fundamentals: İş Yatırım'ın
banka fallback denemeleri nedeniyle saatler mertebesinde olabilir). Uzun
çalışmalar kesintiye uğrarsa `build_fundamentals.py --resume` ve
`kap_news.py --resume` zaten tamamlanmış sembolleri atlayıp kaldığı yerden
devam eder.

## Maliyet tablosu

| Bileşen | Ücretsiz katman | Bu projenin kullanımı |
|---|---|---|
| GitHub Actions | 2.000 dk/ay (özel repo), sınırsız (public) | ~5 dk/gün ≈ 150 dk/ay |
| GitHub depo | 1 GB | ~2 MB önbellek |
| jsDelivr CDN | Sınırsız istek/bant genişliği | Tüm kullanıcı okumaları |
| TradingView widget | Ücretsiz | Tüm grafikler |
| **Toplam** | | **0 TL** |
