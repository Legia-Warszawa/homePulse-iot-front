// ...existing code...
import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/chart/Interactive_outside_chart.dart';
import 'package:homepulse/widget/quick_date_button.dart';
import '../model/devices_iot.dart';

class OutsideChartScreen extends StatefulWidget {
  final List<EspOutside_1> outsideData;
  const OutsideChartScreen({Key? key, this.outsideData = const []})
    : super(key: key);

  @override
  State<OutsideChartScreen> createState() => _OutsideChartScreenState();
}

class _OutsideChartScreenState extends State<OutsideChartScreen> {
  DateTime? selectedDate;
  bool isLoading = false;
  String connectionStatus = 'Nie sprawdzono';
  Map<String, dynamic>? sensorData;

  List<EspOutside_1> outsideData = [];

  @override
  void initState() {
    super.initState();
    uploadData();
    selectedDate = null;
  }

  void _selectToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  void _selectYesterday() {
    setState(() {
      selectedDate = DateTime.now().subtract(Duration(days: 1));
    });
  }

  void _selectSevenDaysAgo() {
    setState(() {
      selectedDate = DateTime.now().subtract(Duration(days: 7));
    });
  }

  void _selectPreviousDay() {
    if (selectedDate == null) return;
    setState(() {
      selectedDate = selectedDate!.subtract(Duration(days: 1));
    });
  }

  void _selectNextDay() {
    if (selectedDate == null) return;
    setState(() {
      final next = selectedDate!.add(Duration(days: 1));
      if (next.isBefore(DateTime.now().add(Duration(days: 1))))
        selectedDate = next;
    });
  }

  void _pickDate() async {
    final validDates = outsideData
        .where((d) => d.timestamp != null)
        .map((d) => d.timestamp!)
        .toList();
    if (validDates.isEmpty) return;
    validDates.sort();
    final initial = selectedDate ?? validDates.last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: validDates.first,
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> uploadData() async {
    setState(() {
      sensorData = null;
      outsideData.clear();
    });
    try {
      var message = await ConnectServer.getLatestMessage();

      var zewnatrzHistoryRaw = await HistoryService.getEspZewnatrzHistory(
        limit: 1000,
      );
      outsideData = zewnatrzHistoryRaw
          .map((json) => EspOutside_1.fromJson(json))
          .toList();
      print('Zewnątrz - ilość rekordów: ${outsideData.length}');

      setState(() {
        if (outsideData.isNotEmpty) {
          connectionStatus = 'Połączenie OK! Pobrano dane historyczne.';
          sensorData = message;
        } else {
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
    // Pobieramy primary color raz, żeby użyć go spójnie
    final primaryColor = const Color(0xFFFF5722); 

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
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(50),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4), 
                labelColor: primaryColor, 
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14 ),
                unselectedLabelColor: Colors.white, // Tu zostawiłeś Black, upewnij się czy nie lepiej Colors.white.withOpacity(0.8)
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
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
          // Zmieniłem z .only(top: 12) na .symmetric(...)
          // horizontal: 16.0 doda ładny odstęp z lewej i prawej strony
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), 
          child: TabBarView(
            physics: const BouncingScrollPhysics(), 
            children: [
              InteractiveOutsideChart(
                outsideData: outsideData,
                selectedTab: 0,
                selectedDate: selectedDate,
                onDateSelected: (date) => setState(() => selectedDate = date),
                onSelectToday: _selectToday,
                onSelectYesterday: _selectYesterday,
                onSelectSevenDaysAgo: _selectSevenDaysAgo,
                onSelectLastData: () {
                  final valid = outsideData.where((d) => d.timestamp != null).toList();
                  if (valid.isNotEmpty) setState(() => selectedDate = valid.last.timestamp);
                },
                onSelectPreviousDay: _selectPreviousDay,
                onSelectNextDay: _selectNextDay,
              ),
              InteractiveOutsideChart(
                outsideData: outsideData,
                selectedTab: 1,
                selectedDate: selectedDate,
                onDateSelected: (date) => setState(() => selectedDate = date),
                onSelectToday: _selectToday,
                onSelectYesterday: _selectYesterday,
                onSelectSevenDaysAgo: _selectSevenDaysAgo,
                onSelectLastData: () {
                  final valid = outsideData.where((d) => d.timestamp != null).toList();
                  if (valid.isNotEmpty) setState(() => selectedDate = valid.last.timestamp);
                },
                onSelectPreviousDay: _selectPreviousDay,
                onSelectNextDay: _selectNextDay,
              ),
              InteractiveOutsideChart(
                outsideData: outsideData,
                selectedTab: 2,
                selectedDate: selectedDate,
                onDateSelected: (date) => setState(() => selectedDate = date),
                onSelectToday: _selectToday,
                onSelectYesterday: _selectYesterday,
                onSelectSevenDaysAgo: _selectSevenDaysAgo,
                onSelectLastData: () {
                  final valid = outsideData.where((d) => d.timestamp != null).toList();
                  if (valid.isNotEmpty) setState(() => selectedDate = valid.last.timestamp);
                },
                onSelectPreviousDay: _selectPreviousDay,
                onSelectNextDay: _selectNextDay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}