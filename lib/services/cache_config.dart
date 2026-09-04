/// Önbellek dağıtım ayarları.
///
/// Günlük script `data/cache/*.json` dosyalarını repoya yazar; jsDelivr bu
/// dosyaları global CDN'den **ücretsiz ve sınırsız** servis eder. 10.000
/// kullanıcının açılış isteği Yahoo'ya değil bu CDN'e gider.
///
/// Kurulum: aşağıdaki [ghUser] / [ghRepo] / [ghBranch] değerlerini kendi
/// GitHub deponuza göre doldurun. Başka hiçbir yeri değiştirmeniz gerekmez.
class CacheConfig {
  static const String ghUser = 'KULLANICI_ADIN';
  static const String ghRepo = 'pusula';
  static const String ghBranch = 'main';

  /// jsDelivr taban adresi. `@latest` yerine dal adı kullanıyoruz ki
  /// günlük commit sonrası en güç 12 saat içinde tazelensin (jsDelivr TTL).
  static String get base =>
      'https://cdn.jsdelivr.net/gh/$ghUser/$ghRepo@$ghBranch/data/cache';

  /// CDN erişilemezse doğrudan ham GitHub içeriği (TTL yok, biraz yavaş).
  static String get rawBase =>
      'https://raw.githubusercontent.com/$ghUser/$ghRepo/$ghBranch/data/cache';

  static String indexUrl(String b) => '$b/index.json';
  static String kapUrl(String b) => '$b/kap.json';
  static String stockUrl(String b, String code) =>
      '$b/stock/${code.toUpperCase()}.json';

  /// Diskteki kopyayı bu süreden eskiyse "bayat" say (yine de göster, arkada yenile).
  static const Duration freshFor = Duration(hours: 18);

  /// Ağ isteği zaman aşımı.
  static const Duration timeout = Duration(seconds: 10);

  static bool get isConfigured => ghUser != 'KULLANICI_ADIN';
}
