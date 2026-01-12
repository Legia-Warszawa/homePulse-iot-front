import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ConnectServer {
  static const String baseUrl = 'http://100.105.194.33:8000';
  static const String api = 'items';
  static const String rawEndpoint = 'eventhub/raw';

  // Test połączenia
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // Pobieranie danych z /items/eventhub/raw
  static Future<Map<String, dynamic>?> getLatestMessage() async {
    try {
      // Budujemy nowy adres URL
      final String fullUrl = '$baseUrl/$api/$rawEndpoint';
      
      print('Pobieranie danych RAW z: $fullUrl');
      
      final response = await http
          .get(
            Uri.parse(fullUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Błąd serwera: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Błąd żądania (RawData): $e');
      return null;
    }
  }
}