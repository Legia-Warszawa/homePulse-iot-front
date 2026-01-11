import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../model/devices_iot.dart';
import '../../widget/quick_date_button.dart';
import '../../servises/history_servis.dart'; // Import Twojego serwisu

class InteractiveOutsideChart extends StatefulWidget {
  final List<EspOutside_1> outsideData; // Dane początkowe (np. z dzisiaj)
  final int selectedTab; // 0=temp, 1=hum, 2=press

  const InteractiveOutsideChart({
    Key? key,
    required this.outsideData,
    this.selectedTab = 0,
  }) : super(key: key);

  @override
  _InteractiveOutsideChartState createState() =>
      _InteractiveOutsideChartState();
}

class _InteractiveOutsideChartState extends State<InteractiveOutsideChart> {
  List<EspOutside_1> _displayData = [];
  double minX = 0;
  double maxX = 50;
  double minY = 0;
  double maxY = 1;
  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Zainicjuj danymi startowymi i pobierz świeże dane z API
    _setAndSortData(widget.outsideData);
    _fetchDataForDate(selectedDate);
  }

  @override
  void didUpdateWidget(covariant InteractiveOutsideChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jeśli zmieniła się zakładka (np. z Temp na Wilgotność) - przelicz skalę
    if (oldWidget.selectedTab != widget.selectedTab) {
      _updateChartBounds();
    }
    // Jeśli dane z góry się odświeżyły (np. pull-to-refresh)
    if (oldWidget.outsideData != widget.outsideData && !_isLoading) {
      _setAndSortData(widget.outsideData);
      _updateChartBounds();
    }
  }

  // Gwarantuje kierunek czasu: od lewej (rano) do prawej (wieczór)
  void _setAndSortData(List<EspOutside_1> data) {
    final List<EspOutside_1> sorted = List.from(data);
    sorted.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    setState(() {
      _displayData = sorted;
    });
  }

  // Pobieranie danych z Twojego API: baseUrl/esp-zewnatrz/YYYY-MM-DD?limit=1000
  Future<void> _fetchDataForDate(DateTime date) async {
    setState(() {
      selectedDate = date;
      _isLoading = true;
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final rawData = await HistoryService.getEspZewnatrzHistory(
        date: formattedDate, 
        limit: 1000
      );
      
      if (mounted) {
        final List<EspOutside_1> newData = rawData.map((json) => EspOutside_1.fromJson(json)).toList();
        _setAndSortData(newData);
        _updateChartBounds();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Błąd pobierania danych zewnętrznych: $e');
      if (mounted) {
        setState(() {
          _displayData = [];
          _isLoading = false;
        });
      }
    }
  }

  void _updateChartBounds() {
    if (_displayData.isEmpty) {
      setState(() { minX = 0; maxX = 50; minY = 0; maxY = 1; });
      return;
    }

    // Wybierz wartości zależnie od aktywnej zakładki
    final values = _displayData.map((d) {
      if (widget.selectedTab == 0) return d.temperature;
      if (widget.selectedTab == 1) return d.humidity;
      return d.pressure - 900; // Skalowanie ciśnienia (np. 980 -> 80)
    }).toList();

    double vMin = values.reduce((a, b) => a < b ? a : b);
    double vMax = values.reduce((a, b) => a > b ? a : b);
    
    // Marginesy Y, żeby linia nie dotykała krawędzi
    double range = vMax - vMin;
    double padding = range < 1.0 ? 2.0 : range * 0.2;

    setState(() {
      minX = 0;
      maxX = (_displayData.length - 1).toDouble();
      minY = vMin - padding;
      maxY = vMax + padding;
    });
  }

  // --- ZOOM I PRZESUWANIE ---
  void _zoomIn() {
    setState(() {
      double range = maxX - minX;
      if (range < 2) return;
      double center = (minX + maxX) / 2;
      double newRange = range * 0.6;
      minX = center - newRange / 2;
      maxX = center + newRange / 2;
    });
  }

  void _zoomOut() {
    setState(() {
      double range = maxX - minX;
      double center = (minX + maxX) / 2;
      double newRange = range * 1.4;
      minX = math.max(0, center - newRange / 2);
      maxX = math.min((_displayData.length - 1).toDouble(), center + newRange / 2);
    });
  }

  void _panLeft() {
    setState(() {
      double range = maxX - minX;
      minX = math.max(0, minX - (range * 0.3));
      maxX = minX + range;
    });
  }

  void _panRight() {
    setState(() {
      double range = maxX - minX;
      double limit = (_displayData.length - 1).toDouble();
      maxX = math.min(limit, maxX + (range * 0.3));
      minX = maxX - range;
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) => 
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartHeight = (MediaQuery.of(context).size.height * 0.35).clamp(200.0, 400.0);
    final String title = widget.selectedTab == 0 ? 'Temperatura' : (widget.selectedTab == 1 ? 'Wilgotność' : 'Ciśnienie');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Nagłówek i zmiana dni
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _fetchDataForDate(selectedDate.subtract(const Duration(days: 1))), 
                      icon: const Icon(Icons.chevron_left)
                    ),
                    Text(DateFormat('dd.MM').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        final next = selectedDate.add(const Duration(days: 1));
                        if (next.isBefore(DateTime.now().add(const Duration(seconds: 1)))) _fetchDataForDate(next);
                      }, 
                      icon: const Icon(Icons.chevron_right)
                    ),
                  ],
                ),
              ],
            ),
            
            // Przyciski Nawigacji Wykresu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: _panLeft, icon: const Icon(Icons.arrow_back)),
                IconButton(onPressed: _zoomIn, icon: const Icon(Icons.zoom_in), color: theme.colorScheme.primary),
                IconButton(onPressed: _zoomOut, icon: const Icon(Icons.zoom_out), color: theme.colorScheme.primary),
                IconButton(onPressed: () => setState(() { minX = 0; maxX = (_displayData.length - 1).toDouble(); }), icon: const Icon(Icons.refresh)),
                IconButton(onPressed: _panRight, icon: const Icon(Icons.arrow_forward)),
              ],
            ),

            const SizedBox(height: 16),

            // Obszar Wykresu
            SizedBox(
              height: chartHeight,
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _displayData.isEmpty 
                  ? const Center(child: Text('Brak danych dla tej daty')) 
                  : LineChart(_mainChartData()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _mainChartData() {
    final Color color = widget.selectedTab == 0 ? Colors.red : (widget.selectedTab == 1 ? Colors.green : Colors.purple);

    return LineChartData(
      minX: minX, maxX: maxX, minY: minY, maxY: maxY,
      clipData: FlClipData.all(),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, 
            reservedSize: 50,
            getTitlesWidget: (val, meta) {
              String unit = widget.selectedTab == 0 ? '°' : (widget.selectedTab == 1 ? '%' : '');
              double displayVal = widget.selectedTab == 2 ? val + 900 : val;
              return Text('${displayVal.toStringAsFixed(0)}$unit', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: math.max(1, (maxX - minX) / 5),
            getTitlesWidget: (val, meta) {
              int i = val.toInt();
              if (i >= 0 && i < _displayData.length) {
                return Text(DateFormat('HH:mm').format(_displayData[i].timestamp!), style: const TextStyle(fontSize: 9));
              }
              return const Text('');
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      lineBarsData: [
        LineChartBarData(
          spots: _displayData.asMap().entries.map((e) {
            double y;
            if (widget.selectedTab == 0) y = e.value.temperature;
            else if (widget.selectedTab == 1) y = e.value.humidity;
            else y = e.value.pressure - 900;
            return FlSpot(e.key.toDouble(), y);
          }).toList(),
          isCurved: true,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
        ),
      ],
    );
  }
}