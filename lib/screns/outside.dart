import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/chart/Interactive_outside_chart.dart';
import '../model/devices_iot.dart';

class OutsideChartScreen extends StatefulWidget {
  final List<EspOutside_1> outsideData;
  const OutsideChartScreen({Key? key, this.outsideData = const []})
      : super(key: key);

  @override
  State<OutsideChartScreen> createState() => _OutsideChartScreenState();
}

class _OutsideChartScreenState extends State<OutsideChartScreen> {
  bool isLoading = false;
  String connectionStatus = 'Nie sprawdzono';
  Map<String, dynamic>? sensorData;
  List<EspOutside_1> outsideData = [];

  @override
  void initState() {
    super.initState();
    // Przy starcie ładujemy dane początkowe (dzisiejsze)
    uploadData();
  }

  Future<void> uploadData() async {
    setState(() {
      isLoading = true;
      sensorData = null;
    });
    try {
      // Pobieramy aktualne dane (latest)
      var message = await ConnectServer.getLatestMessage();

      // Pobieramy historię dzisiejszą na start
      var zewnatrzHistoryRaw = await HistoryService.getEspZewnatrzHistory(
        limit: 1000,
      );
      
      setState(() {
        outsideData = zewnatrzHistoryRaw
            .map((json) => EspOutside_1.fromJson(json))
            .toList();
        sensorData = message;
        connectionStatus = 'Zaktualizowano dane';
        isLoading = false;
      });
    } catch (e) {
      print('BŁĄD podczas pobierania danych: $e');
      setState(() {
        connectionStatus = 'Błąd połączenia: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF2E7D32);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Na zewnątrz - Wykres'),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: primaryColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelColor: Colors.white,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Temperatura'),
                  Tab(text: 'Wilgotność'),
                  Tab(text: 'Ciśnienie'),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: isLoading ? null : uploadData,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Wykres temperatury (zakładka 0)
              InteractiveOutsideChart(
                outsideData: outsideData,
                selectedTab: 0,
              ),
              // Wykres wilgotności (zakładka 1)
              InteractiveOutsideChart(
                outsideData: outsideData,
                selectedTab: 1,
              ),
              // Wykres ciśnienia (zakładka 2)
              InteractiveOutsideChart(
                outsideData: outsideData,
                selectedTab: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}