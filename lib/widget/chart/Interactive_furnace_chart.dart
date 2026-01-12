import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:homepulse/widget/quick_date_button.dart';
import 'package:homepulse/servises/history_servis.dart';
import 'package:homepulse/widget/show_data_picker.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../model/devices_iot.dart';

class InteractiveFurnaceChart extends StatefulWidget {
  final List<EspFurnanceC02> furnaceData;

  const InteractiveFurnaceChart({Key? key, required this.furnaceData})
    : super(key: key);

  @override
  _InteractiveFurnaceChartState createState() =>
      _InteractiveFurnaceChartState();
}

class _InteractiveFurnaceChartState extends State<InteractiveFurnaceChart> {
  List<EspFurnanceC02> _displayData = [];
  double minX = 0;
  double maxX = 50;
  double minY = 0;
  double maxY = 1;
  DateTime selectedDate = DateTime.now();
  double _tempScale = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setAndSortData(widget.furnaceData);
    _fetchDataForDate(selectedDate);
  }

  @override
  void didUpdateWidget(covariant InteractiveFurnaceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.furnaceData != widget.furnaceData && !_isLoading) {
      _setAndSortData(widget.furnaceData);
      _updateChartBounds();
    }
  }

  void _setAndSortData(List<EspFurnanceC02> data) {
    if (data.isEmpty) return;
    final List<EspFurnanceC02> sorted = List.from(data);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    setState(() {
      _displayData = sorted;
    });
  }

  Future<void> _fetchDataForDate(DateTime date) async {
    setState(() {
      selectedDate = date;
      _isLoading = true;
    });

    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final List<Map<String, dynamic>> rawData =
          await HistoryService.getEspPiecHistory(
            date: formattedDate,
            limit: 1000,
          );

      if (mounted) {
        final List<EspFurnanceC02> newData = rawData
            .map((json) => EspFurnanceC02.fromJson(json))
            .toList();
        _setAndSortData(newData);
        _updateChartBounds();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Błąd pobierania danych pieca: $e');
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
      setState(() {
        minX = 0;
        maxX = 50;
        minY = 0;
        maxY = 100;
      });
      return;
    }

    final rawTemps = _displayData.map((e) => e.temperature.toDouble()).toList();
    final maxRaw = rawTemps.reduce((a, b) => a > b ? a : b);
    _tempScale = maxRaw > 1000.0 ? 100.0 : 1.0;

    final ys = _displayData.map((d) => d.temperature / _tempScale).toList();
    double tmin = ys.reduce((a, b) => a < b ? a : b);
    double tmax = ys.reduce((a, b) => a > b ? a : b);

    double range = tmax - tmin;
    double padding = range < 1.0 ? 5.0 : range * 0.2;

    setState(() {
      minX = 0;
      maxX = (_displayData.length - 1).toDouble();
      minY = tmin - padding;
      maxY = tmax + padding;
    });
  }

  // --- NAWIGACJA I ZOOM ---
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
      maxX = math.min(
        (_displayData.length - 1).toDouble(),
        center + newRange / 2,
      );
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
    final chartHeight = (MediaQuery.of(context).size.height * 0.35).clamp(
      200.0,
      450.0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ujednolicony Nagłówek: Tytuł + Nawigacja Datami
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Piec - Historia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                    onTap: () async {
                    final DateTime? picked =
                        await showChartDatePicker(context, initialDate: selectedDate);
                    if (picked != null) {
                      _fetchDataForDate(picked);
                    }
                  },
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _fetchDataForDate(
                          selectedDate.subtract(const Duration(days: 1)),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        DateFormat('dd.MM').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () {
                          final next = selectedDate.add(const Duration(days: 1));
                          if (next.isBefore(
                            DateTime.now().add(const Duration(seconds: 1)),
                          ))
                            _fetchDataForDate(next);
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Ujednolicone Przyciski szybkiego wyboru
           
              
               Row(
                children: [
                  QuickDateButton(
                    label: 'Dziś',
                    onPressed: () => _fetchDataForDate(DateTime.now()),
                    isSelected: _isSameDay(selectedDate, DateTime.now()),
                  ),
                  const SizedBox(width: 8),
                  QuickDateButton(
                    label: 'Wczoraj',
                    onPressed: () => _fetchDataForDate(
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                    isSelected: _isSameDay(
                      selectedDate,
                      DateTime.now().subtract(const Duration(days: 1)),
                    ),
                  ),
                ],
              ),
            

            const SizedBox(height: 12),

            // Ujednolicone Kontrolki wykresu (Zoom i Przesuwanie)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _panLeft,
                  icon: const Icon(Icons.arrow_back),
                ),
                IconButton(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.zoom_in),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.zoom_out),
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  onPressed: () => setState(() {
                    minX = 0;
                    maxX = (_displayData.length - 1).toDouble();
                  }),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  onPressed: _panRight,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Obszar wykresu
            SizedBox(
              height: chartHeight,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayData.isEmpty
                  ? const Center(child: Text('Brak danych dla wybranej daty'))
                  : LineChart(_mainChartData()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      clipData: FlClipData.all(),

      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots
                .map((spot) {
                  final int idx = spot.x.toInt();
                  if (idx < 0 || idx >= _displayData.length) return null;
                  final item = _displayData[idx];
                  final temp = (spot.y * _tempScale).toStringAsFixed(1);
                  final time = DateFormat('HH:mm:ss').format(item.timestamp);
                  return LineTooltipItem(
                    '$time\n$temp°C',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                })
                .whereType<LineTooltipItem>()
                .toList();
          },
        ),
        getTouchedSpotIndicator: (LineChartBarData bar, List<int> indicators) {
          return indicators.map((i) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.grey.withOpacity(0.6), strokeWidth: 1),
              FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeColor: bar.color ?? Colors.blue,
                  strokeWidth: 2,
                ),
              ),
            );
          }).toList();
        },
      ),

      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, meta) => Text(
              '${val.toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 10),
            ),
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
                return Text(
                  DateFormat('HH:mm').format(_displayData[i].timestamp),
                  style: const TextStyle(fontSize: 9),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade300),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _displayData
              .asMap()
              .entries
              .map(
                (e) =>
                    FlSpot(e.key.toDouble(), e.value.temperature / _tempScale),
              )
              .toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
