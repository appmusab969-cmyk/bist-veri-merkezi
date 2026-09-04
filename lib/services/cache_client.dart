import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_config.dart';

/// Statik önbellek JSON'larını okuyan istemci.
///
/// Katmanlı okuma (hızlıdan yavaşa, ilk başarılı kazanır):
///   1. Bellek (aynı oturum içinde tekrar istek yapılmaz)
///   2. Disk / SharedPreferences (çevrimdışı da çalışır)
///   3. jsDelivr CDN  — asıl kaynak, ücretsiz ve ölçekli
///   4. raw.githubusercontent.com — CDN çökerse yedek
///
/// Her istek TEK bir HTTP çağrısıdır ve gün boyu değişmeyen bir dosyaya gider;
/// bu yüzden 10.000 kullanıcı bile arka uçta yük oluşturmaz.
class CacheClient {
  CacheClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  final Map<String, _Entry> _mem = {};

  static final CacheClient instance = CacheClient();

  // ------------------------------------------------------------ genel okuma

  /// [path] örn. `index.json`, `kap.json`, `stock/ASELS.json`.
  Future<Map<String, dynamic>> getJson(
    String path, {
    bool forceRefresh = false,
  }) async {
    final mem = _mem[path];
    if (!forceRefresh && mem != null && mem.isFresh) {
      return mem.data;
    }

    // Diskteki kopya — önce onu döndürüp arkada yenileyebiliriz.
    final disk = await _readDisk(path);
    if (!forceRefresh && disk != null && disk.isFresh) {
      _mem[path] = disk;
      unawaited(_refresh(path)); // sessiz tazeleme
      return disk.data;
    }

    try {
      final fresh = await _refresh(path);
      return fresh;
    } catch (e) {
      // Ağ yok: elde ne varsa onu ver.
      if (mem != null) return mem.data;
      if (disk != null) return disk.data;
      throw CacheException('Önbellek okunamadı ($path): $e');
    }
  }

  /// CDN -> raw yedeği sırasıyla dener, belleğe + diske yazar.
  Future<Map<String, dynamic>> _refresh(String path) async {
    Object? lastErr;
    for (final b in [CacheConfig.base, CacheConfig.rawBase]) {
      final url = '$b/$path';
      try {
        final res = await _http
            .get(Uri.parse(url))
            .timeout(CacheConfig.timeout);
        if (res.statusCode != 200) {
          lastErr = 'HTTP ${res.statusCode}';
          continue;
        }
        final data = jsonDecode(utf8.decode(res.bodyBytes))
            as Map<String, dynamic>;
        final entry = _Entry(data, DateTime.now());
        _mem[path] = entry;
        await _writeDisk(path, entry);
        return data;
      } catch (e) {
        lastErr = e;
      }
    }
    throw CacheException('Tüm kaynaklar başarısız ($path): $lastErr');
  }

  // ------------------------------------------------------------ kısayollar

  Future<Map<String, dynamic>> index({bool forceRefresh = false}) =>
      getJson('index.json', forceRefresh: forceRefresh);

  Future<Map<String, dynamic>> kap({bool forceRefresh = false}) =>
      getJson('kap.json', forceRefresh: forceRefresh);

  Future<Map<String, dynamic>> stock(String code,
          {bool forceRefresh = false}) =>
      getJson('stock/${code.toUpperCase()}.json', forceRefresh: forceRefresh);

  // ------------------------------------------------------------ disk

  static String _diskKey(String path) => 'cache::$path';

  Future<_Entry?> _readDisk(String path) async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_diskKey(path));
      if (raw == null) return null;
      final wrap = jsonDecode(raw) as Map<String, dynamic>;
      return _Entry(
        wrap['data'] as Map<String, dynamic>,
        DateTime.fromMillisecondsSinceEpoch(wrap['at'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(String path, _Entry e) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _diskKey(path),
        jsonEncode({'at': e.fetchedAt.millisecondsSinceEpoch, 'data': e.data}),
      );
    } catch (err) {
      if (kDebugMode) debugPrint('cache disk yazılamadı: $err');
    }
  }

  void dispose() => _http.close();
}

class _Entry {
  _Entry(this.data, this.fetchedAt);
  final Map<String, dynamic> data;
  final DateTime fetchedAt;

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) < CacheConfig.freshFor;
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
  @override
  String toString() => message;
}
