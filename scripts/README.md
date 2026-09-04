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

## Evreni genişletme

`scripts/symbols.mjs` → `BIST_UNIVERSE` dizisine kod ekleyin. Uygulama evreni
`index.json`'dan okur; ayrıca kod değişikliği gerekmez.

## Maliyet tablosu

| Bileşen | Ücretsiz katman | Bu projenin kullanımı |
|---|---|---|
| GitHub Actions | 2.000 dk/ay (özel repo), sınırsız (public) | ~5 dk/gün ≈ 150 dk/ay |
| GitHub depo | 1 GB | ~2 MB önbellek |
| jsDelivr CDN | Sınırsız istek/bant genişliği | Tüm kullanıcı okumaları |
| TradingView widget | Ücretsiz | Tüm grafikler |
| **Toplam** | | **0 TL** |
