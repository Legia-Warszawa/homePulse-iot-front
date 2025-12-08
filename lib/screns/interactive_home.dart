import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/led_controll_widget.dart';
import '../model/devices_iot.dart'; // Dla typu EspRoom1

// Zakladamy, ze potrzebujemy dostepu do danych (np. temperatury)
class InteractiveHouseMap extends StatefulWidget {
  //final List<EspRoom1> roomData;

  const InteractiveHouseMap(
    {super.key,
    // required this.roomData
     });

  @override
  State<InteractiveHouseMap> createState() => _InteractiveHouseMapState();
}

class _InteractiveHouseMapState extends State<InteractiveHouseMap> {
  // Symulacja stanow
  bool isKitchenLightOn = false;
  bool isLivingRoomLightOn = false;
  List<EspRoom1> roomData = [];
   Map<String, dynamic>? sensorData;
  String connectionStatus = 'Nie sprawdzono';

  void _toggleLight(String roomName, bool newState) {
    // Tutaj nalezy wywolac API dla konkretnego urzadzenia/pomieszczenia.
    // Na przyklad, jesli Kitchen to urzadzenie "ESP-KITCHEN":
    // LedControlWidget().createState()._setLedState(newState ? 'on' : 'off', deviceId: 'ESP-KITCHEN');
    
    setState(() {
      if (roomName == 'Kitchen') {
        isKitchenLightOn = newState;
      } else if (roomName == 'Living') {
        isLivingRoomLightOn = newState;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wysłano polecenie do $roomName: ${newState ? 'Włączono' : 'Wyłączono'}'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> uploadData() async {
    setState(() {
      sensorData = null;
      roomData.clear();
    });
    try {
       var message = await ConnectServer.getLatestMessage();

      var piecRoomRaw = await HistoryService.getEspPokojHistory(limit: 1000);
      roomData = piecRoomRaw
          .map((json) => EspRoom1.fromJson(json))
          .toList();
      print('Pokój - ilość rekordów: ${roomData.length}');

      setState(() {
           if (roomData.isNotEmpty) {
             connectionStatus = 'Połączenie OK! Pobrano dane historyczne.';
             sensorData = message;
           }else {
             connectionStatus = 'Połączenie OK, ale brak danych historycznych.';
          sensorData = message;
           }
      });
    } catch (e) {
        print('BŁĄD podczas pobierania danych: $e');
      setState(() {
        connectionStatus = 'Błąd połączenia: $e';
        sensorData = null;
      
      });
    }
  }

  // Pomocniczy widzet wlacznika swiatla z pozycjonowaniem procentowym
  Widget _buildLightSwitch(String roomName, double fractionalX, double fractionalY, bool isOn) {
    return Align(
        alignment: FractionalOffset(fractionalX, fractionalY),
        
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                IconButton(
                    iconSize: 30,
                    icon: Icon(
                        isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: isOn ? Colors.amber : Colors.grey.shade600,
                    ),
                    onPressed: () {
                        _toggleLight(roomName, !isOn);
                    },
                ),
                Text(
                    roomName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double roomTemp = roomData.isNotEmpty ? roomData.last.temperature : 0.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interaktywny Plan Domu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const LedControlWidget(),
              Card(
             margin: const EdgeInsets.all(16.0),
             elevation: 4,
            clipBehavior: Clip.hardEdge,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8.0, left: 8.0),
                    child: Text(
                      'Interaktywny Plan Domu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  SizedBox(
                    height: 400, // ustalona wysokość mapy
                    width: double.infinity,
                    child: ClipRect( // zapobiega overflow w poziomie
                      child: Stack(
                        children: [
                          // 1. Warstwa bazowa: Obraz mapy
                          Positioned.fill(
                            child: Image.asset(
                              'assets/floorplan.png',
                              fit: BoxFit.contain,
                            ),
                          ),
           
                         // 2. Wlacznik w Kuchni/Jadalni (lewy gorny)
                         _buildLightSwitch(
                           'Kitchen', 
                           0.40, // X: ~20% szerokosci
                           0.30, // Y: ~15% wysokosci
                           isKitchenLightOn,
                         ),
           
                         // 3. Wlacznik w Salonie (prawy gorny)
                         _buildLightSwitch(
                           'Living', 
                           0.57, // X: ~75% szerokosci
                           0.25, // Y: ~15% wysokosci
                           isLivingRoomLightOn,
                         ),
                         
                         // 4. Wskaznik temperatury Pokoju 1 (dolny lewy rog)
                         Align(
                           alignment: const FractionalOffset(0.63, 0.85), // Koordynaty nad toaleta
                           child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Icon(Icons.thermostat, color: Colors.blue, size: 30),
                               Text(
                                 roomData.isNotEmpty ? '${roomTemp.toStringAsFixed(1)}°C' : 'Ładowanie...',
                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                               ),
                               const Text('Pokój 1', style: TextStyle(fontSize: 10)),
                             ],
                           ),
                         ),
                       ],
                     ),
                   ),
                 ),
                 
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Statusy: Kuchnia: ${isKitchenLightOn ? "WŁ" : "WYŁ"} | Salon: ${isLivingRoomLightOn ? "WŁ" : "WYŁ"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
      ),
   );
 }
}