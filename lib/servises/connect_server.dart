import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ConnectServer {
  static const String baseUrl = 'http://100.105.194.33:8000';
  static const String api = 'items';
  static const String latestEndpoint = 'latest';


  // Test połączenia z serwerem
  static Future<bool> testConnection() async {
    try {
      if (kIsWeb) {
        print('Testowanie połączenia w przeglądarce...');
        var result = await getLatestMessage();
        return result != null;
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  // Tylko endpoint /items/latest
  static Future<Map<String, dynamic>?> getLatestMessage() async {
    try {
      print('Pobieranie danych z: $baseUrl/${api}/${latestEndpoint}');
      final response = await http
          .get(
            Uri.parse('$baseUrl/${api}/${latestEndpoint}'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Sukces! Dane otrzymane');
        return json.decode(response.body);
      } else {
        print('Błąd ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Request error: $e');
      return null;
    }
  }
}