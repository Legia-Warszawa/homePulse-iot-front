import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/model/devices_iot.dart';
import 'package:homepulse/widget/device_chart.dart';
import '../widget/sensor_data_display.dart';

class StartsScreen extends StatefulWidget {
  const StartsScreen({super.key});

  @override
  State<StartsScreen> createState() => _StartsScreenState();
}

class _StartsScreenState extends State<StartsScreen> {
  String connectionStatus = 'Nie sprawdzono';
  bool isLoading = false;
  Map<String, dynamic>? sensorData;

  // Dane dla wykresów
  List<EspRoom1> roomData = [];
  List<EspOutside_1> outsideData = [];
  List<EspFurnanceC02> furnaceData = [];

  @override
  void initState() {
    super.initState();
    testServerConnection();
  }

  Future<void> testServerConnection() async {
    setState(() {
      isLoading = true;
      connectionStatus = 'Sprawdzanie...';
      sensorData = null;
      roomData.clear();
      outsideData.clear();
      furnaceData.clear();
    });

    try {
      // Testujemy podstawowe połączenie
      var connection = await ConnectServer.testConnection();
      var message = await ConnectServer.getLatestMessage();

      // Pobieramy dane historyczne z wszystkich urządzeń
      print('=== POBIERANIE DANYCH HISTORYCZNYCH ===');

      var pokojHistoryRaw = await HistoryService.getEspPokojHistory(limit: 1000);
      var zewnatrzHistoryRaw = await HistoryService.getEspZewnatrzHistory(limit: 1000,);
      var piecHistoryRaw = await HistoryService.getEspPiecHistory(limit: 1000);

      // Konwertujemy dane do modeli
      roomData = pokojHistoryRaw
          .map((json) => EspRoom1.fromJson(json))
          .toList();
      outsideData = zewnatrzHistoryRaw
          .map((json) => EspOutside_1.fromJson(json))
          .toList();
      furnaceData = piecHistoryRaw
          .map((json) => EspFurnanceC02.fromJson(json))
          .toList();

      print('Pokój - ilość rekordów: ${roomData.length}');
      print('Zewnątrz - ilość rekordów: ${outsideData.length}');
      print('Piec - ilość rekordów: ${furnaceData.length}');

      if (roomData.isNotEmpty) {
        print(
          'Pierwszy rekord pokoju: ${roomData.first.fullDateTime} - ${roomData.first.temperature}°C',
        );
      }

      print('=== KONIEC POBIERANIA DANYCH ===\n');

      setState(() {
        if (message != null ||
            roomData.isNotEmpty ||
            outsideData.isNotEmpty ||
            furnaceData.isNotEmpty) {
          connectionStatus = 'Połączenie OK! Pobrano dane historyczne.';
          sensorData = message;
        } else {
          connectionStatus = 'Połączenie OK, ale brak danych historycznych.';
          sensorData = message;
        }
        isLoading = false;
      });
    } catch (e) {
      print('BŁĄD podczas pobierania danych: $e');
      setState(() {
        connectionStatus = 'Błąd połączenia: $e';
        sensorData = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Home Pulse')),
        leading: IconButton(
          onPressed: isLoading ? null : testServerConnection,
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.refresh),
          iconSize: 28,
        ),
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Welcome to the Home Pulse!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 20),

            // Wyświetlanie wykresów gdy mamy dane
            if (roomData.isNotEmpty ||
                outsideData.isNotEmpty ||
                furnaceData.isNotEmpty)
              Expanded(
                child: DeviceChartsWidget(
                  roomData: roomData,
                  outsideData: outsideData,
                  furnaceData: furnaceData,
                ),
              )
            else if (sensorData != null)
              Expanded(child: SensorDataDisplay(sensorData: sensorData!))
            else if (connectionStatus != 'Nie sprawdzono' &&
                connectionStatus != 'Sprawdzanie...')
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sensors_off,
                        size: 64,
                        color: theme.colorScheme.secondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Brak danych do wyświetlenia',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
