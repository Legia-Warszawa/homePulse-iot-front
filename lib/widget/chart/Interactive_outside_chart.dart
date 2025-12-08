// ...existing code...
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/devices_iot.dart';

class InteractiveOutsideChart extends StatefulWidget {
  final List<EspOutside_1> outsideData;
  final int selectedTab; // 0=temp,1=hum,2=press
  final DateTime? selectedDate;
  const InteractiveOutsideChart({
    Key? key,
    required this.outsideData,
    this.selectedTab = 0,
    this.selectedDate,
  }) : super(key: key);

  @override
  _InteractiveOutsideChartState createState() =>
      _InteractiveOutsideChartState();
}

class _InteractiveOutsideChartState extends State<InteractiveOutsideChart> {
  double minX = 0;
  double maxX = 50; // Pokaż do 50 punktów na raz (liczba punktów)
  double minY = 0;
  double maxY = 1;

  List<EspOutside_1> get _data => widget.outsideData;

  List<EspOutside_1> get _sortedOutsideData {
    final valid = widget.outsideData.where((d) => d.timestamp != null).toList();
    valid.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    return valid;
  }

  List<EspOutside_1> _getFilteredDataByDay() {
    final all = _sortedOutsideData;
    if (widget.selectedDate == null) return all;
    return all.where((d) {
      final ts = d.timestamp!;
      return ts.year == widget.selectedDate!.year &&
          ts.month == widget.selectedDate!.month &&
          ts.day == widget.selectedDate!.day;
    }).toList();
  }

  List<EspOutside_1> get _activeData => _getFilteredDataByDay();

  List<LineChartBarData> _barsForTab(int tab) {
    final list = _activeData;
    final spots = list.asMap().entries.map((e) {
      final x = e.key.toDouble();
      double y;
      if (tab == 0) {
        y = e.value.temperature;
      } else if (tab == 1) {
        y = e.value.humidity;
      } else {
        y = e.value.pressure - 900;
      }
      return FlSpot(x, y);
    }).toList();

    final color = (tab == 0)
        ? Colors.red
        : (tab == 1)
        ? Colors.green
        : Colors.purple;

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2,
        dotData: FlDotData(show: false),
        preventCurveOverShooting: true,
      ),
    ];
  }

  void _adjustRanges() {
    final list = _activeData;
    if (list.isEmpty) {
      setState(() {
        minX = 0;
        maxX = 1;
        minY = 0;
        maxY = 1;
      });
      return;
    }

    // wybierz wartości dla aktywnej zakładki
    final values = list.map((d) {
      if (widget.selectedTab == 0) return d.temperature;
      if (widget.selectedTab == 1) return d.humidity;
      return d.pressure - 900;
    }).toList();

    double vMin = values.reduce((a, b) => a < b ? a : b);
    double vMax = values.reduce((a, b) => a > b ? a : b);
    final padding = math.max((vMax - vMin) * 0.12, 0.5);

    setState(() {
      minY = vMin - padding;
      maxY = vMax + padding;
      minX = 0;
      // pokaż maksymalnie 50 punktów na raz lub mniej jeśli danych mniej
      maxX = list.length > 50 ? 50.0 : list.length.toDouble();
      if (maxX <= minX) maxX = minX + 1;
    });
  }

  @override
  void initState() {
    super.initState();
    // ustaw zakresy po pierwszym zbudowaniu (jeśli są dane)
    WidgetsBinding.instance.addPostFrameCallback((_) => _adjustRanges());
  }

  @override
  void didUpdateWidget(covariant InteractiveOutsideChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // jeśli zmieniły się dane lub wybrana data/zakładka — dopasuj zakresy
    if (oldWidget.outsideData != widget.outsideData ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.selectedTab != widget.selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _adjustRanges());
    }
  }

  void _panLeft() {
    setState(() {
      if (minX > 0) {
        double range = maxX - minX;
        minX = (minX - 10).clamp(0.0, double.infinity);
        maxX = minX + range;
      }
    });
  }

  void _panRight() {
    setState(() {
      double range = maxX - minX;
      maxX = (maxX + 10).clamp(0.0, widget.outsideData.length.toDouble());
      minX = (maxX - range).clamp(0.0, double.infinity);
    });
  }

  void _zoomIn() {
    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 0.8;
      minX = (center - range / 2).clamp(0.0, double.infinity);
      maxX = minX + range;
    });
  }

  void _zoomOut() {
    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 1.25;
      minX = (center - range / 2).clamp(0.0, double.infinity);
      maxX = minX + range;
      if (maxX > widget.outsideData.length)
        maxX = widget.outsideData.length.toDouble();
    });
  }

  void _resetZoom() {
    setState(() {
      minX = 0;
      maxX = widget.outsideData.length > 50
          ? 50
          : widget.outsideData.length.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _getFilteredDataByDay();
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final double chartHeight = (mq.size.height * 0.35).clamp(
      160.0,
      mq.size.height * 0.55,
    );
    final int activeTab = widget.selectedTab; // używamy parametru od rodzica

    return SingleChildScrollView(
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dane Zewnętrzne',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
      
              // Przyciski kontrolne (pan/zoom)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(onPressed: _panLeft, icon: Icon(Icons.arrow_back)),
                  IconButton(onPressed: _zoomIn, icon: Icon(Icons.zoom_in)),
                  IconButton(onPressed: _zoomOut, icon: Icon(Icons.zoom_out)),
                  IconButton(onPressed: _resetZoom, icon: Icon(Icons.refresh)),
                  IconButton(
                    onPressed: _panRight,
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              ),
      
              SizedBox(height: 12),
      
              Container(
                height: chartHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: data.isEmpty
                      ? Center(
                          child: Text(
                            'Brak danych',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
                            clipData: FlClipData.all(),
                            lineTouchData: LineTouchData(
                              enabled: true,
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBorderRadius: BorderRadius.circular(8),
                                tooltipPadding: EdgeInsets.all(8),
                                tooltipMargin: 12,
                                fitInsideHorizontally: true,
                                fitInsideVertically: true,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots
                                      .map((spot) {
                                        final idx = spot.x.toInt();
                                        if (idx >= 0 && idx < data.length) {
                                          final d = data[idx];
                                          if (activeTab == 0) {
                                            return LineTooltipItem(
                                              'Temp: ${d.temperature.toStringAsFixed(1)}°C\n${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}',
                                              TextStyle(color: Colors.white),
                                            );
                                          } else if (activeTab == 1) {
                                            return LineTooltipItem(
                                              'Wilgotność: ${d.humidity.toStringAsFixed(1)}%\n${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}',
                                              TextStyle(color: Colors.white),
                                            );
                                          } else {
                                            return LineTooltipItem(
                                              'Ciśnienie: ${d.pressure.toStringAsFixed(0)} hPa\n${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}',
                                              TextStyle(color: Colors.white),
                                            );
                                          }
                                        }
                                        return null;
                                      })
                                      .whereType<LineTooltipItem>()
                                      .toList();
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: (maxY - minY) / 8,
                              verticalInterval: (maxX - minX) / 6,
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  interval: (maxY - minY) / 8,
                                  getTitlesWidget: (value, meta) {
                                    if (activeTab == 0) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Text(
                                          '${value.toInt()}°C',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      );
                                    } else if (activeTab == 1) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Text(
                                          '${value.toInt()}%',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      );
                                    } else {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Text(
                                          '${(value + 900).toInt()}',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: (maxX - minX) / 6,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < data.length) {
                                      final ts = data[idx].timestamp!;
                                      return Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Transform.rotate(
                                          angle: -0.3,
                                          child: Text(
                                            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      );
                                    }
                                    return Text('');
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            lineBarsData: _barsForTab(activeTab),
                          ),
                        ),
                ),
              ),
      
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    activeTab == 0
                        ? 'Temperatura (°C)'
                        : activeTab == 1
                        ? 'Wilgotność (%)'
                        : 'Ciśnienie (hPa)',
                    activeTab == 0
                        ? Colors.red
                        : activeTab == 1
                        ? Colors.green
                        : Colors.purple,
                  ),
                ],
              ),
      
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Wyświetlane punkty: ${minX.toInt()} - ${maxX.toInt()} z ${data.length}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11)),
      ],
    );
  }
}
// ...existing code...