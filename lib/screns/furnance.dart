// ...existing code...
import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/chart/Interactive_furnace_chart.dart';
import '../model/devices_iot.dart';

class FurnaceChartScreen extends StatefulWidget {
  final List<EspFurnanceC02> furnaceData;
  const FurnaceChartScreen({Key? key, this.furnaceData = const []})
    : super(key: key);

  @override
  State<FurnaceChartScreen> createState() => _FurnaceChartScreenState();
}

class _FurnaceChartScreenState extends State<FurnaceChartScreen> {
  late List<EspFurnanceC02> _furnaceData;
  bool isLoading = false;
  String connectionStatus = 'Nie sprawdzono';
  Map<String, dynamic>? sensorData;

  List<EspFurnanceC02> furnaceData = [];

  @override
  void initState() {
    super.initState();
   //_furnaceData = furnaceData;
    uploadData();
  }

  Future<void> uploadData() async {
    setState(() {
      sensorData = null;
      furnaceData.clear();
    });
    try {
       var message = await ConnectServer.getLatestMessage();

      var piecHistoryRaw = await HistoryService.getEspPiecHistory(limit: 1000);
      furnaceData = piecHistoryRaw
          .map((json) => EspFurnanceC02.fromJson(json))
          .toList();
      print('Piec - ilość rekordów: ${furnaceData.length}');

      setState(() {
           if (furnaceData.isNotEmpty) {
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

    await Future.delayed(
      const Duration(seconds: 1),
    ); // TODO: pobierz dane z serwera

    setState(() {
      connectionStatus = 'Zaktualizowano';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Piec - Wykres'),
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: InteractiveFurnaceChart(furnaceData: furnaceData),
      ),
    );
  }
}
