# Pusula

BIST hisse araştırma uygulaması. Arayüz [FireVibe.ai](https://firevibe.ai) ile
üretilmiş şablondan geliştirildi; canlı fiyatlar **ücretsiz ve anahtarsız**
Yahoo Finance uç noktalarından çekilir.

## Çalıştırma

```bash
flutter pub get
flutter run          # bağlı cihaz / emülatör
flutter run -d chrome
```

Flutter 3.22+ / Dart 3.4+ gerekir.

## Neler çalışıyor

| Ekran | Durum |
|---|---|
| **Ana Sayfa** | BIST 100 endeksi + takip listesi (ASELS, OYAKC, TOASO) **canlı**. Aşağı çekerek yenilenir. Mini grafikler gerçek fiyat serisinden çizilir. |
| **Hisse Ara** | Yahoo `search` ile **canlı arama**; her sonuç için anlık fiyat + gün içi grafik. |
| **Formasyonlar / Ayarlar** | Arayüz ve etkileşim çalışır; içerik **örnek (demo)** veridir. |
| **ASELS detay ekranları** | Şablon halinde; henüz canlı veriye bağlı değil. |

## Veri kaynağı

`lib/services/yahoo_finance.dart`

- `GET query1.finance.yahoo.com/v8/finance/chart/<SEMBOL>.IS` — fiyat + seri
- `GET query2.finance.yahoo.com/v1/finance/search?q=...` — sembol arama

BIST kodları otomatik olarak `.IS` sonekiyle Yahoo sembolüne çevrilir
(`ASELS` → `ASELS.IS`). Bu uç noktalar resmi olarak dokümante edilmemiştir;
kişisel/eğitim amaçlı kullanım içindir, ücretsizdir, API anahtarı istemez.
Fiyatlar borsaya göre ~15 dk gecikmeli olabilir.

## "Yapay zeka" metinleri

Şablondaki "YZ analizi / Yapay Zekânın Seçtikleri" gibi ifadeler gerçek bir
analiz üretmiyordu; **"Örnek içerik / Demo"** olarak dürüstçe etiketlendi.
Gerçek yorum üretimi (kural tabanlı veya LLM) ileride eklenebilir.

## Proje yapısı

```
lib/
  main.dart                 # MaterialApp + 3 sekmeli MainShell
  theme.dart                # AppColors token'ları + AppTheme.dark (ColorScheme)
  models/quote.dart         # Quote, SearchHit
  services/
    yahoo_finance.dart      # ücretsiz veri servisi
    format.dart             # TL / % / tarih biçimleme (intl, tr_TR)
  widgets/sparkline.dart    # gerçek seriden mini çizgi grafik
  screens/                  # ana_sayfa, hisse_ara, formasyonlar, ayarlar, asels_*
```

## Bilinen sınırlar

- Temel analiz (bilanço, rasyo, 10 yıllık) için ücretsiz + güvenilir tek bir
  kaynak yok; ASELS detay ekranları bu yüzden şablon halinde bırakıldı.
- KAP haber akışı entegre değil.
- Yahoo uç noktaları bildirim yapmadan değişebilir; ticari kullanımda lisanslı
  bir sağlayıcıya (ör. Finnhub, Twelve Data) geçilmelidir.
