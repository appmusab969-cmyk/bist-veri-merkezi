import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama genelindeki kalıcı tercihler. Ayarlar ekranı bunları değiştirir;
/// Ana Sayfa ve Formasyonlar bunları dinler.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kParticipation = 'participationFilter';
  static const _kHighConfidence = 'highConfidenceOnly';
  static const _kSimpleText = 'simpleExplanations';
  static const _kPatterns = 'preferredPatterns';

  bool _participationFilter = false;
  bool _highConfidenceOnly = true;
  bool _simpleExplanations = true;
  Set<String> _preferredSignals = {'Yükseliş', 'Kırılım'};

  bool get participationFilter => _participationFilter;
  bool get highConfidenceOnly => _highConfidenceOnly;
  bool get simpleExplanations => _simpleExplanations;
  Set<String> get preferredSignals => _preferredSignals;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _participationFilter = p.getBool(_kParticipation) ?? false;
    _highConfidenceOnly = p.getBool(_kHighConfidence) ?? true;
    _simpleExplanations = p.getBool(_kSimpleText) ?? true;
    final saved = p.getStringList(_kPatterns);
    if (saved != null) _preferredSignals = saved.toSet();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kParticipation, _participationFilter);
    await p.setBool(_kHighConfidence, _highConfidenceOnly);
    await p.setBool(_kSimpleText, _simpleExplanations);
    await p.setStringList(_kPatterns, _preferredSignals.toList());
  }

  void setParticipationFilter(bool v) {
    _participationFilter = v;
    notifyListeners();
    _save();
  }

  void setHighConfidenceOnly(bool v) {
    _highConfidenceOnly = v;
    notifyListeners();
    _save();
  }

  void setSimpleExplanations(bool v) {
    _simpleExplanations = v;
    notifyListeners();
    _save();
  }

  void togglePreferredSignal(String name) {
    if (_preferredSignals.contains(name)) {
      _preferredSignals.remove(name);
    } else {
      _preferredSignals.add(name);
    }
    notifyListeners();
    _save();
  }
}

/// Katılım Endeksi'ne uygunluğu için ücretsiz, statik bir liste.
/// (Resmi API yok; TKYD Katılım-100 bileşenlerinden yaygın olanlar.)
const kParticipationStocks = <String>{
  'ASELS', 'TUPRS', 'BIMAS', 'KCHOL', 'SAHOL', 'FROTO', 'TOASO', 'SISE',
  'EREGL', 'KRDMD', 'PETKM', 'OYAKC', 'TCELL', 'TTKOM', 'THYAO', 'PGSUS',
  'AEFES', 'CCOLA', 'MGROS', 'SOKM', 'ULKER', 'TAVHL', 'ENKAI', 'GUBRF',
  'HEKTS', 'KOZAL', 'KOZAA', 'ODAS', 'SASA', 'ALARK', 'AKSEN', 'ZOREN',
  'VESTL', 'ARCLK', 'TKFEN', 'DOAS', 'EKGYO', 'ISDMR', 'KARSN', 'OTKAR',
};

bool isParticipationStock(String bistCode) =>
    kParticipationStocks.contains(bistCode.toUpperCase());
