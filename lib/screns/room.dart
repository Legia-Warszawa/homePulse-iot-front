import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/chart/Interactive_room_chart.dart';
import 'package:intl/intl.dart'; // Dodaj ten import dla dat
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
    // Pobierz dane dla dzisiejszego dnia przy starcie
    uploadData();
  }

  /// Główna funkcja pobierająca dane z nowego API opartego na dacie
  Future<void> uploadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Pobierz aktualny status (Live)
      var message = await ConnectServer.getLatestMessage();

      // 2. Pobierz historię z dzisiejszą datą (używając nowego systemu)
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      var roomRaw = await HistoryService.getEspPokojHistory(
        date: today, // WYMUSZAMY DATĘ
        limit: 1000
      );
      
      // 3. Mapowanie i filtrowanie
      List<EspRoom1> cleanData = roomRaw
          .map((json) => EspRoom1.fromJson(json))
          .where((record) {
            // ZABEZPIECZENIE: Realne temperatury pokojowe
            return record.temperature < 60.0 && record.temperature > -15.0;
          })
          .toList();

      if (mounted) {
        setState(() {
          roomData = cleanData;
          sensorData = message;
          connectionStatus = roomData.isNotEmpty 
              ? 'Zaktualizowano: ${DateFormat('HH:mm').format(DateTime.now())}' 
              : 'Brak danych na dzień dzisiejszy ($today)';
        });
      }

    } catch (e) {
      print('BŁĄD POKÓJ: $e');
      if (mounted) {
        setState(() {
          connectionStatus = 'Błąd: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokój - Wykres'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : uploadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: InteractiveRoomChart(roomData: roomData),
            ),
          ),
          
          // Pasek statusu na dole
          Container(
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            color: Colors.grey.withOpacity(0.1),
            child: Text(
              connectionStatus,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}