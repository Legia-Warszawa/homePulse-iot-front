import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HistoryService {
  static const String baseUrl = 'http://100.105.194.33:8000';
  static const String historyEndpoint = '/items/history';
  
  static const String pokuj = 'esp-pokoj';
  static const String zewnatrz = 'esp-zewnatrz';
  static const String piec = 'esp-piec';
  static const int defaultLimit = 1000;

  static Future<List<Map<String, dynamic>>> _fetchData(String device, int limit, String? date) async {
    try {
      // Jeśli data nie jest podana, bierzemy dzisiejszą (format 2026-01-12)
      final String targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // NOWY ADRES: baseUrl/items/history/esp-pokoj/2026-01-12?limit=1000
      final String url = '$baseUrl$historyEndpoint/$device/$targetDate?limit=$limit';

      print('API Request ($device): $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        // Obsługa formatu Mapa (z Twojego nowego API)
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('history')) {
            return List<Map<String, dynamic>>.from(decodedData['history']);
          } else if (decodedData.containsKey('data')) {
            return List<Map<String, dynamic>>.from(decodedData['data']);
          }
          return [];
        } else if (decodedData is List) {
          return decodedData.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        print('Błąd serwera ${response.statusCode} dla $url');
        return [];
      }
    } catch (e) {
      print('Wyjątek w HistoryService: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getEspPokojHistory({int limit = defaultLimit, String? date}) async =>
      await _fetchData(pokuj, limit, date);

  static Future<List<Map<String, dynamic>>> getEspZewnatrzHistory({int limit = defaultLimit, String? date}) async =>
      await _fetchData(zewnatrz, limit, date);

  static Future<List<Map<String, dynamic>>> getEspPiecHistory({int limit = defaultLimit, String? date}) async =>
      await _fetchData(piec, limit, date);

  static Future<Map<String, List<Map<String, dynamic>>>> getAllDevicesHistory({int limit = defaultLimit, String? date}) async {
    final futures = await Future.wait([
      getEspPokojHistory(limit: limit, date: date),
      getEspZewnatrzHistory(limit: limit, date: date),
      getEspPiecHistory(limit: limit, date: date),
    ]);
    return {'esp-pokoj': futures[0], 'esp-zewnatrz': futures[1], 'esp-piec': futures[2]};
  }
}