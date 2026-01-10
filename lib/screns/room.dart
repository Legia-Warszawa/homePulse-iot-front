import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/chart/Interactive_room_chart.dart';
import '../model/devices_iot.dart';

class RoomChartScreen extends StatefulWidget {
  final List<EspRoom1> roomData;
  const RoomChartScreen({Key? key, this.roomData = const []}) : super(key: key);

  @override
  State<RoomChartScreen> createState() => _RoomChartScreenState();
}

class _RoomChartScreenState extends State<RoomChartScreen> {
  bool isLoading = false;
  String connectionStatus = 'Oczekiwanie na dane...';
  Map<String, dynamic>? sensorData;
  List<EspRoom1> roomData = [];

  @override
  void initState() {
    super.initState();
    // Pobierz dane przy starcie
    uploadData();
  }

  /// Główna funkcja pobierająca i filtrująca dane
  Future<void> uploadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Pobierz aktualny status z serwera
      var message = await ConnectServer.getLatestMessage();

      // 2. Pobierz historię z serwera
      var piecRoomRaw = await HistoryService.getEspPokojHistory(limit: 1000);
      
      // 3. Mapowanie JSON -> Model z FILTROWANIEM błędnych rekordów (np. > 100°C)
      List<EspRoom1> cleanData = piecRoomRaw
          .map((json) => EspRoom1.fromJson(json))
          .where((record) {
            // ZABEZPIECZENIE: Akceptuj tylko realne temperatury pokojowe.
            // Odrzucamy wszystko powyżej 60 stopni (Twoje piki 100+ znikną).
            return record.temperature < 60.0 && record.temperature > -15.0;
          })
          .toList();

      print('Pokój - pobrano: ${piecRoomRaw.length}, po filtracji: ${cleanData.length}');

      setState(() {
        roomData = cleanData;
        sensorData = message;
        connectionStatus = roomData.isNotEmpty 
            ? 'Połączenie OK! Dane przefiltrowane.' 
            : 'Brak poprawnych danych w historii.';
      });

    } catch (e) {
      print('BŁĄD POKÓJ: $e');
      setState(() {
        connectionStatus = 'Błąd połączenia: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Funkcja wywoływana przyciskiem odświeżania
  Future<void> testServerConnection() async {
    await uploadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connectionStatus),
          duration: const Duration(seconds: 2),
          backgroundColor: connectionStatus.contains('Błąd') ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokój - Wykres'),
        actions: [
          IconButton(
            onPressed: isLoading ? null : testServerConnection,
            icon: isLoading
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pasek postępu ładowania
          if (isLoading) const LinearProgressIndicator(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: roomData.isEmpty && !isLoading
                  ? _buildEmptyState()
                  : InteractiveRoomChart(roomData: roomData),
            ),
          ),
          
          // Stopka z informacją o ostatniej aktualizacji
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              connectionStatus,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Brak danych do wyświetlenia na wykresie'),
          TextButton(
            onPressed: uploadData,
            child: const Text('Spróbuj ponownie'),
          )
        ],
      ),
    );
  }
}