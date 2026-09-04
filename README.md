# Pusula

BIST hisse araştırma uygulaması. Arayüz [FireVibe.ai](https://firevibe.ai) ile
üretilmiş şablondan geliştirildi; **tüm veriler ücretsiz ve anahtarsız** Yahoo
Finance uç noktalarından çekilir. Sunucu, abonelik veya API anahtarı yoktur.

## Ölçek mimarisi — sıfır sunucu maliyeti

10.000 aktif kullanıcıyı **0 TL** ile taşımak için veriler her kullanıcıdan
değil, günde 1 kez **GitHub Actions** içinde çekilip statik JSON'a önbelleklenir
ve **jsDelivr CDN**'den servis edilir. Ayrıntı: [`scripts/README.md`](scripts/README.md).

```
GitHub Actions (cron, günde 1x)  →  Yahoo + KAP/haber RSS  →  data/cache/*.json
        │
        ▼ jsDelivr CDN (ücretsiz, sınırsız)
Flutter · MarketRepository → CacheClient   (bellek → disk → CDN → raw)
        • açılışta tek statik istek · çevrimdışı çalışır
        • grafik: TradingView WebView widget'ı (bize/Yahoo'ya yük yok)
```

Uygulamayı deponuza bağlamak için `lib/services/cache_config.dart` içindeki
`ghUser` / `ghRepo` / `ghBranch` alanlarını doldurun. Doldurulmazsa uygulama
otomatik olarak canlı Yahoo moduna düşer (yalnızca geliştirme için).

## Çalıştırma

```bash
flutter pub get
flutter run              # bağlı cihaz / emülatör
flutter build apk --release
```

Flutter 3.22+ / Dart 3.4+.

## Ekranlar ve durum

| Ekran | Durum |
|---|---|
| **Ana Sayfa** | BIST 100 + takip listesi (ASELS/OYAKC/TOASO) canlı. "Piyasa Özeti" satırı yalnızca canlı fiyatlardan hesaplanır (kaç yükselen/düşen, ortalama). Aşağı çekerek yenilenir. Katılım filtresi anahtarı buradan da açılır. |
| **Hisse Ara** | Yahoo `search` ile canlı arama; her sonuç için anlık fiyat + gün içi grafik. |
| **Formasyonlar** | 30 hisselik evren taranır; her biri için 6 aylık günlük seriden **teknik sinyal** hesaplanır (SMA20 kesişimi, SMA20/SMA50 dizilişi, 20 günlük kanal kırılımı, momentum). Filtre çipleri (Tümü / Yükseliş sinyali / Katılım / Yüksek güven) gerçekten filtreler. **LLM kullanılmaz.** |
| **Ayarlar** | Anahtarlar `SharedPreferences` ile kalıcıdır ve Ana Sayfa + Formasyonlar'a canlı uygulanır. "Yüksek güvenli sinyaller" → Formasyonlar'da güven < 60 gizlenir. "KAP haber etkisi" henüz veri kaynağı olmadığı için pasiftir (dürüstçe "yakında" etiketli). |
| **Hisse Detay** (her hisse) | 5 sekme: **Özet Kokpit** (sağlık skoru + 2x2 akıllı kart), **Grafik** (TradingView WebView widget'ı — %100 doğru, sunucu yükü yok), **Pro Analiz** (Piotroski F-Score, Altman Z, DuPont), **Rasyolar & 10Y**, **KAP & Risk** (KAP/haber bildirimleri + borç/likidite/nakit döngüsü). Veriler `MarketRepository` üzerinden statik önbellekten okunur. |

## Veri kaynağı — `lib/services/yahoo_finance.dart`

| İşlev | Uç nokta | Anahtar? |
|---|---|---|
| Fiyat + geçmiş seri | `query1.finance.yahoo.com/v8/finance/chart/<SEMBOL>.IS` | Hayır |
| Sembol arama | `query2.finance.yahoo.com/v1/finance/search` | Hayır |
| Temel veriler (F/K, marj, borç…) | `.../v10/finance/quoteSummary/<SEMBOL>.IS` | **crumb + cookie** |

**crumb akışı:** `quoteSummary` tarayıcı oturumu ister. Uygulama `dart:io HttpClient`
ile `fc.yahoo.com` → yönlendirmeleri izleyip çerezleri toplar, ardından
`/v1/test/getcrumb`'dan crumb alır. Alınamazsa detay ekranı **kısmi moda** düşer:
fiyat, grafik, 52 hafta, hacim ve teknik sekme yine çalışır; Rasyolar/Bilanço
"veri alınamadı" mesajı gösterir.

BIST kodları otomatik `.IS` sonekiyle Yahoo sembolüne çevrilir. Bu uç noktalar
resmi olarak dokümante edilmemiştir; kişisel/eğitim amaçlıdır, fiyatlar ~15 dk
gecikmeli olabilir. **Yatırım tavsiyesi değildir.**

## Teknik sinyal — `lib/services/technical.dart`

Saf hesaplama, dış servis yok:
- `SMA(20)` fiyatı yukarı/aşağı kesişimi
- `SMA(20)` / `SMA(50)` dizilişi
- Son 20 günün en yüksek/en düşük seviyesinin kırılması (Donchian)
- 20 günlük momentum büyüklüğü → 0–100 güven puanı

## Proje yapısı

```
lib/
  main.dart                    # MaterialApp + 3 sekmeli MainShell
  theme.dart                   # AppColors token'ları + AppTheme.dark (ColorScheme)
  models/  quote.dart · candle.dart · stock_detail.dart · fundamental_analysis.dart
  services/
    cache_config.dart          # CDN adresi (ghUser/ghRepo/ghBranch)
    cache_client.dart          # katmanlı önbellek okuyucu: bellek→disk→CDN→raw
    market_repository.dart     # ekranların TEK veri girişi (önbellek + canlı yedek)
    yahoo_finance.dart         # canlı yedek veri servisi + crumb akışı
    technical.dart             # SMA / kanal / güven puanı
    app_settings.dart          # kalıcı tercihler + Katılım listesi
    format.dart                # TL / % / tarih / göreli süre (intl, tr_TR)
  widgets/ sparkline.dart · tradingview_chart.dart · health_ring.dart · smart_card.dart
  screens/ ana_sayfa · hisse_ara · hisse_detay · formasyonlar · ayarlar_ve_filtreler

scripts/                       # günlük önbellek üreticisi (Node 20+, bağımlılıksız)
  build-cache.mjs · yahoo.mjs · fundamentals.mjs · kap.mjs · symbols.mjs
.github/workflows/build-cache.yml   # cron 07:30 UTC + workflow_dispatch
data/cache/                    # üretilen statik JSON (Actions commit eder)
```

## Bilinen sınırlar

- Katılım Endeksi uygunluğu ücretsiz resmî API'si olmadığı için `app_settings.dart`
  ve `scripts/symbols.mjs` içinde sabit bir liste ile belirlenir.
- KAP resmî RSS/API'si 2024 sonrası SPA'ya geçtiğinden bildirimler Yahoo
  per-symbol RSS akışından toplanır (haber + basın bültenleri + çoğu özel durum
  açıklaması). Tam KAP arşivi için lisanslı bir sağlayıcı gerekir.
- Yahoo uç noktaları bildirim yapmadan değişebilir; ticari kullanımda lisanslı
  bir sağlayıcıya geçilmelidir. Önbellek katmanı bu geçişi tek dosyada
  (`scripts/yahoo.mjs`) izole eder — uygulama kodu etkilenmez.
- Hisse Detay'daki grafik `webview_flutter` gerektirir (Android/iOS). Web/masaüstü
  derlemelerinde yerli sparkline'a düşer.
