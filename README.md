# Pusula

BIST hisse araştırma uygulaması. Arayüz [FireVibe.ai](https://firevibe.ai) ile
üretilmiş şablondan geliştirildi; **tüm veriler ücretsiz ve anahtarsız** Yahoo
Finance uç noktalarından çekilir. Sunucu, abonelik veya API anahtarı yoktur.

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
| **Hisse Detay** (her hisse) | 4 sekme: **Özet** (piyasa değeri, 52 hafta, hacim, analist konsensüsü + hedef fiyat), **Rasyolar** (F/K, PD/DD, EPS, marjlar, ROE...), **Bilanço** (gelir, borç, nakit, cari oran...), **Teknik** (SMA'lar, kanal, güven puanı). Ana Sayfa'daki kartlardan ve Formasyonlar'dan tıklanınca açılır. |

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
  models/  quote.dart · candle.dart · stock_detail.dart
  services/
    yahoo_finance.dart         # ücretsiz veri servisi + crumb akışı
    technical.dart             # SMA / kanal / güven puanı
    app_settings.dart          # kalıcı tercihler + Katılım listesi
    format.dart                # TL / % / tarih (intl, tr_TR)
  widgets/ sparkline.dart      # gerçek seriden mini grafik
  screens/ ana_sayfa · hisse_ara · hisse_detay · formasyonlar · ayarlar_ve_filtreler
```

## Bilinen sınırlar

- Katılım Endeksi uygunluğu ücretsiz resmî API'si olmadığı için `app_settings.dart`
  içinde sabit bir liste ile belirlenir.
- KAP haber akışı entegre değil.
- Yahoo uç noktaları bildirim yapmadan değişebilir; ticari kullanımda lisanslı
  bir sağlayıcıya geçilmelidir.
