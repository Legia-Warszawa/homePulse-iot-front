// ...existing code...
import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/chart/Interactive_outside_chart.dart';
import '../model/devices_iot.dart';

class OutsideChartScreen extends StatefulWidget {
  final List<EspOutside_1> outsideData;
  const OutsideChartScreen({Key? key, this.outsideData = const []}) : super(key: key);

  @override
  State<OutsideChartScreen> createState() => _OutsideChartScreenState();
}

class _OutsideChartScreenState extends State<OutsideChartScreen> {
  //late List<EspOutside_1> _outsideData;
  bool isLoading = false;
  String connectionStatus = 'Nie sprawdzono';
  Map<String, dynamic>? sensorData;

  List<EspOutside_1> outsideData = [];

  @override
  void initState() {
    super.initState();
    uploadData();
  }
  Future<void> uploadData() async {
    setState(() {
      sensorData = null;
      outsideData.clear();
    });
    try {
       var message = await ConnectServer.getLatestMessage();

      var zewnatrzHistoryRaw = await HistoryService.getEspZewnatrzHistory(limit: 1000,);
      outsideData = zewnatrzHistoryRaw
          .map((json) => EspOutside_1.fromJson(json))
          .toList();
      print('Zewnątrz - ilość rekordów: ${outsideData.length}');

      setState(() {
           if (outsideData.isNotEmpty) {
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Na zewnątrz - Wykres'),
          bottom: TabBar(
             indicator: BoxDecoration(
              color: Colors.white, // tło aktywnej zakładki
              borderRadius: BorderRadius.circular(6),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Theme.of(context).colorScheme.primary, // kolor tekstu wybranej
            unselectedLabelColor: Colors.white, // kolor tekstu nie wybranej
            labelStyle: TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: 'Temperatura'),
              Tab(text: 'Wilgotność'),
              Tab(text: 'Ciśnienie'),
            ],
          ),
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
          child: TabBarView(

            children: [
              // każda karta otrzymuje tab index jako selectedTab
              InteractiveOutsideChart(outsideData: outsideData, selectedTab: 0),
              InteractiveOutsideChart(outsideData: outsideData, selectedTab: 1),
              InteractiveOutsideChart(outsideData: outsideData, selectedTab: 2),
            ],
          ),
        ),
      ),
    );
  }
}