// ...existing code...
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
  //late List<EspRoom1> _roomData;
  bool isLoading = false;
  String connectionStatus = 'Nie sprawdzono';
  Map<String, dynamic>? sensorData;

  List<EspRoom1> roomData = [];

  @override
  void initState() {
    super.initState();
    uploadData();
   // _roomData = List<EspRoom1>.from(widget.roomData);
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


  Future<void> testServerConnection() async {
    setState(() {
      isLoading = true;
      connectionStatus = 'Sprawdzanie...';
    });

    await Future.delayed(const Duration(seconds: 1)); 
    setState(() {
      connectionStatus = 'Zaktualizowano';
      isLoading = false;
    });
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
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: InteractiveRoomChart(roomData: roomData),
      ),
    );
  }
}