import 'dart:convert';
import 'package:dio/dio.dart';

/// Fetches Philippine Standard Geographic Code (PSGC) data from GitHub.
/// No local asset — always pulls the latest online.
///
/// Data structure:
/// {
///   "01": {
///     "region_name": "Region I (Ilocos Region)",
///     "province_list": {
///       "Ilocos Norte": {
///         "municipality_list": {
///           "Adams": { "barangay_list": ["Adams (Poblacion)"] }
///         }
///       }
///     }
///   }
/// }
class PsgcService {
  static const _url =
      'https://raw.githubusercontent.com/flores-jacob/'
      'philippine-regions-provinces-cities-municipalities-barangays/master/'
      'philippine_provinces_cities_municipalities_and_barangays_2019v2.json';

  static PsgcService? _instance;
  Map<String, dynamic> _data = {};
  bool _loaded = false;

  PsgcService._();

  static PsgcService get instance {
    _instance ??= PsgcService._();
    return _instance!;
  }

  /// Fetches the PSGC JSON online (~2 MB). Called once, then cached in memory.
  Future<void> load() async {
    if (_loaded) return;

    final dio = Dio();
    final response = await dio.get<String>(
      _url,
      options: Options(
        responseType: ResponseType.plain,
        // 30s timeout in case of slow connection
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    _data = json.decode(response.data ?? '{}') as Map<String, dynamic>;
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  // ─── Regions ───────────────────────────────────────────────────────────
  List<String> get regions {
    return _data.values
        .map((r) => (r as Map)['region_name'] as String)
        .toList()
      ..sort();
  }

  // ─── Provinces ─────────────────────────────────────────────────────────
  List<String> provincesOf(String regionName) {
    final region = _findRegion(regionName);
    if (region == null) return [];
    return (region['province_list'] as Map).keys.cast<String>().toList()
      ..sort();
  }

  // ─── Cities / Municipalities ───────────────────────────────────────────
  List<String> citiesOf(String regionName, String provinceName) {
    final region = _findRegion(regionName);
    if (region == null) return [];
    final province = (region['province_list'] as Map)[provinceName];
    if (province == null) return [];
    return (province['municipality_list'] as Map).keys.cast<String>().toList()
      ..sort();
  }

  // ─── Barangays ─────────────────────────────────────────────────────────
  List<String> barangaysOf(
    String regionName,
    String provinceName,
    String cityName,
  ) {
    final region = _findRegion(regionName);
    if (region == null) return [];
    final province = (region['province_list'] as Map)[provinceName];
    if (province == null) return [];
    final city = (province['municipality_list'] as Map)[cityName];
    if (city == null) return [];
    return (city['barangay_list'] as List).cast<String>().toList()..sort();
  }

  // ─── Private helper ────────────────────────────────────────────────────
  Map? _findRegion(String regionName) {
    for (final r in _data.values) {
      if ((r as Map)['region_name'] == regionName) return r;
    }
    return null;
  }
}