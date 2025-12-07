import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryService {
  static const String baseUrl = 'http://192.168.1.12:8000';
  static const String historyEndpoint = '/items/history';
  static const String pokuj = 'esp-pokoj';
  static const String zewnatrz = 'esp-zewnatrz';
  static const String piec = 'esp-piec';
  static const int defaultLimit = 100;

  // Pobieranie historii dla ESP Pokój
  static Future<List<Map<String, dynamic>>> getEspPokojHistory({
    int limit = defaultLimit,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$historyEndpoint/$pokuj?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load ESP Pokój history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching ESP Pokój history: $e');
    }
  }

  // Pobieranie historii dla ESP Zewnątrz
  static Future<List<Map<String, dynamic>>> getEspZewnatrzHistory({
    int limit = defaultLimit,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$historyEndpoint/$zewnatrz?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load ESP Zewnątrz history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching ESP Zewnątrz history: $e');
    }
  }

  // Pobieranie historii dla ESP Piec
  static Future<List<Map<String, dynamic>>> getEspPiecHistory({
    int limit = defaultLimit,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$historyEndpoint/$piec?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load ESP Piec history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching ESP Piec history: $e');
    }
  }

  // Uniwersalna metoda do pobierania historii dla dowolnego urządzenia
  static Future<List<Map<String, dynamic>>> getDeviceHistory(
    String deviceName, {
    int limit = defaultLimit,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$historyEndpoint/$deviceName?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load $deviceName history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching $deviceName history: $e');
    }
  }

  // Pobieranie historii wszystkich urządzeń jednocześnie
  static Future<Map<String, List<Map<String, dynamic>>>> getAllDevicesHistory({
    int limit = defaultLimit,
  }) async {
    try {
      final futures = await Future.wait([
        getEspPokojHistory(limit: limit),
        getEspZewnatrzHistory(limit: limit),
        getEspPiecHistory(limit: limit),
      ]);

      return {
        'esp-pokoj': futures[0],
        'esp-zewnatrz': futures[1],
        'esp-piec': futures[2],
      };
    } catch (e) {
      throw Exception('Error fetching all devices history: $e');
    }
  }
}
