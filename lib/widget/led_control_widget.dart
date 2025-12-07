import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Pamiętaj o dodaniu 'http' do pubspec.yaml
import 'dart:convert'; // Do parsowania odpowiedzi JSON

// --- STAŁA: Adres Twojego Backendu FastAPI ---
// Upewnij się, że ten adres jest dostępny z Twojego urządzenia/emulatora!
// Jeśli FastAPI jest na kontenerze w Proxmox, użyj IP hosta Proxmox, a nie localhost.
const String _baseUrl = 'http://192.168.1.12:8000'; 
// ---------------------------------------------

class LedControlWidget extends StatefulWidget {
  const LedControlWidget({super.key});

  @override
  State<LedControlWidget> createState() => _LedControlWidgetState();
}

class _LedControlWidgetState extends State<LedControlWidget> {
  // Stan kontrolny - opcjonalny, ale przydatny do śledzenia, co się dzieje
  String _statusMessage = 'Gotowy.';

  // Funkcja wysyłająca polecenie POST do FastAPI
  Future<void> _setLedState(String state) async {
    setState(() {
      _statusMessage = 'Wysyłanie polecenia: $state...';
    });

    final endpoint = Uri.parse('$_baseUrl/control/led/$state');
    
    try {
      final response = await http.post(endpoint);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _statusMessage = 'Sukces! LED: ${state.toUpperCase()}. Odp: ${data['device_response']['status']}';
        });
      } else {
        // Obsługa błędów HTTP (np. 404 Not Found, 500 Internal Server Error)
        setState(() {
          _statusMessage = 'Błąd serwera (HTTP ${response.statusCode}): ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      // Obsługa błędów połączenia (np. serwer niedostępny)
      setState(() {
        _statusMessage = 'Błąd połączenia: Nie udało się połączyć z $_baseUrl';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sterowanie LED',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // PRZYCISK WŁĄCZ
                ElevatedButton.icon(
                  onPressed: () => _setLedState('on'),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('WŁĄCZ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // PRZYCISK WYŁĄCZ
                ElevatedButton.icon(
                  onPressed: () => _setLedState('off'),
                  icon: Icon(Icons.lightbulb_outline_sharp),
                  label: const Text('WYŁĄCZ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Komunikat o statusie
            Text(
              'Status: $_statusMessage',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}