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
            labelColor: Theme.of(
              context,
            ).colorScheme.primary, // kolor tekstu wybranej
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
          child: Column(
            children: [
              // kontrolki daty (kalendarz + prev/next)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                     
                    ],
                  ),
                  // przycisk odśwież w AppBar nadal działa
                ],
              ),
              SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      // pierwsze 3 przyciski maksymalnie z lewej
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _selectPreviousDay,
                            icon: Icon(Icons.chevron_left),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickDate,
                            icon: Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              selectedDate != null
                                  ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                                  : 'Data',
                            ),
                          ),
                          IconButton(
                            onPressed: _selectNextDay,
                            icon: Icon(Icons.chevron_right),
                          ),
                          //SizedBox(width: 15),
                        ],
                      ),

                      // reszta przycisków wyśrodkowana
                      Expanded(
                       // child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              QuickDateButton(
                                label: 'Dziś',
                                onPressed: _selectToday,
                                isSelected:
                                    selectedDate != null &&
                                    selectedDate!
                                            .difference(DateTime.now())
                                            .inDays ==
                                        0,
                              ),
                              SizedBox(width: 8),
                              QuickDateButton(
                                label: 'Wczoraj',
                                onPressed: _selectYesterday,
                                isSelected:
                                    selectedDate != null &&
                                    selectedDate ==
                                        DateTime.now().subtract(
                                          Duration(days: 1),
                                        ),
                              ),
                              SizedBox(width: 8),
                              QuickDateButton(
                                label: '7 dni temu',
                                onPressed: _selectSevenDaysAgo,
                                isSelected:
                                    selectedDate != null &&
                                    selectedDate ==
                                        DateTime.now().subtract(
                                          Duration(days: 7),
                                        ),
                              ),
                              SizedBox(width: 8),
                              QuickDateButton(
                                label: 'Ostatnie dane',
                                onPressed: () {
                                  final valid = outsideData
                                      .where((d) => d.timestamp != null)
                                      .toList();
                                  if (valid.isNotEmpty)
                                    setState(
                                      () => selectedDate = valid.last.timestamp,
                                    );
                                },
                                isSelected:
                                    selectedDate != null &&
                                    outsideData
                                        .where((d) => d.timestamp != null)
                                        .isNotEmpty &&
                                    selectedDate ==
                                        outsideData
                                            .where((d) => d.timestamp != null)
                                            .toList()
                                            .last
                                            .timestamp,
                              ),
                            ],
                          ),
                       // ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  children: [
                    InteractiveOutsideChart(
                      outsideData: outsideData,
                      selectedTab: 0,
                      selectedDate: selectedDate,
                    ),
                    InteractiveOutsideChart(
                      outsideData: outsideData,
                      selectedTab: 1,
                      selectedDate: selectedDate,
                    ),
                    InteractiveOutsideChart(
                      outsideData: outsideData,
                      selectedTab: 2,
                      selectedDate: selectedDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
