import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:homepulse/widget/quick_date_button.dart';
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
  double minX = 0;
  double maxX = 50;
  double minY = 0;
  double maxY = 1;
  DateTime? selectedDate;
  double _tempScale = 1.0;

  @override
  void initState() {
    super.initState();
    selectedDate = null;
    if (widget.furnaceData.isNotEmpty) {
      final valid = widget.furnaceData
          .where((d) => d.timestamp != null)
          .toList();
      if (valid.isNotEmpty) {
        selectedDate = valid.last.timestamp;
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateChartData());
      }
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveFurnaceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.furnaceData != widget.furnaceData) {
      final valid = widget.furnaceData
          .where((d) => d.timestamp != null)
          .toList();
      if (valid.isNotEmpty) {
        if (selectedDate == null || _isSameDay(selectedDate!, DateTime.now())) {
          selectedDate = valid.last.timestamp;
        }
      }
      _updateChartData();
    }
  }

  double _safeInterval(double range, int parts, {double min = 0.1}) {
    if (range.isNaN || range <= 0) return min;
    final v = range / parts;
    return (v.isNaN || v <= 0) ? min : v;
  }

  List<EspFurnanceC02> _getFilteredData() {
    if (selectedDate == null) return [];
    final list = widget.furnaceData.where((d) {
      if (d.timestamp == null) return false;
      return d.timestamp!.year == selectedDate!.year &&
          d.timestamp!.month == selectedDate!.month &&
          d.timestamp!.day == selectedDate!.day;
    }).toList();
    list.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    return list;
  }

  void _updateChartData() {
    if (selectedDate == null) return;
    final dayData = _getFilteredData();
    if (dayData.isEmpty) {
      setState(() {
        minX = 0;
        maxX = 0;
        minY = 0;
        maxY = 1;
        _tempScale = 1.0;
      });
      return;
    }

    final plotted = dayData
        .where((d) => d.timestamp != null && d.temperature != null)
        .toList();
    if (plotted.isEmpty) {
      setState(() {
        minX = 0;
        maxX = 0;
        minY = 0;
        maxY = 1;
        _tempScale = 1.0;
      });
      return;
    }

    final rawTemps = plotted.map((e) => e.temperature!.toDouble()).toList();
    final maxRaw = rawTemps.reduce((a, b) => a > b ? a : b);

    // DLA PIECA: traktuj wartości 60..100 jako prawdziwe stopnie — nie dzielimy przez 10.
    // Skalowanie stosujemy tylko dla naprawdę dużych/nieprawidłowych liczb.
    double scale = 1.0;
    if (maxRaw > 1000.0) {
      // bardzo duże wartości -> podejrzenie innej jednostki (np. centy)
      scale = 100.0;
    } else {
      // domyślnie brak skalowania dla pieca
      scale = 1.0;
    }
    _tempScale = scale;

    final spots = plotted
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            e.value.temperature!.toDouble() / _tempScale,
          ),
        )
        .toList();

    final ys = spots.map((s) => s.y).toList();
    double tmin = ys.reduce((a, b) => a < b ? a : b);
    double tmax = ys.reduce((a, b) => a > b ? a : b);

    if ((tmax - tmin).abs() < 1e-9) {
      tmin -= 1.5;
      tmax += 1.5;
    } else {
      final baseRange = tmax - tmin;
      final visibleCount = plotted.length;
      final extraTopFactor =
          (0.15 + math.min(0.5, (visibleCount / 1000) * 0.5));
      final topPad = baseRange * extraTopFactor;
      final bottomPad = baseRange * 0.05;
      tmin -= bottomPad;
      tmax += topPad;
    }

    tmax = math.max(tmax, ys.reduce((a, b) => a > b ? a : b) + 1.0);

    setState(() {
      minX = 0;
      maxX = (spots.isNotEmpty) ? (spots.length - 1).toDouble() : 0;
      minY = tmin;
      maxY = tmax;
    });
  }

  void _selectToday() {
    setState(() {
      selectedDate = DateTime.now();
      _updateChartData();
    });
  }

  void _selectYesterday() {
    setState(() {
      selectedDate = DateTime.now().subtract(Duration(days: 1));
      _updateChartData();
    });
  }

  void _selectPreviousDay() {
    if (selectedDate == null) return;
    setState(() {
      selectedDate = selectedDate!.subtract(Duration(days: 1));
      _updateChartData();
    });
  }

  void _selectNextDay() {
    if (selectedDate == null) return;
    setState(() {
      final nextDay = selectedDate!.add(Duration(days: 1));
      if (nextDay.isBefore(DateTime.now().add(Duration(days: 1)))) {
        selectedDate = nextDay;
        _updateChartData();
      }
    });
  }

  void _selectDate() async {
    if (selectedDate == null) return;
    final validDates = widget.furnaceData
        .where((d) => d.timestamp != null)
        .map((d) => d.timestamp!)
        .toList();
    if (validDates.isEmpty) return;
    validDates.sort();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: validDates.first,
      lastDate: DateTime.now(),
      helpText: 'Wybierz datę dla danych pieca',
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _updateChartData();
      });
    }
  }

  void _panLeft() {
    setState(() {
      final range = maxX - minX;
      final shift = math.max(1, (range * 0.2).round());
      minX = math.max(0, minX - shift);
      maxX = minX + range;
    });
  }

  void _panRight() {
    final dayData = _getFilteredData();
    setState(() {
      final range = maxX - minX;
      maxX = math.min(
        dayData.length.toDouble() - 1,
        maxX + math.max(1, (range * 0.2).round()),
      );
      minX = maxX - range;
      if (minX < 0) minX = 0;
    });
  }

  void _zoomIn() {
    setState(() {
      double center = (minX + maxX) / 2;
      double range = math.max(1, (maxX - minX) * 0.8);
      minX = math.max(0, center - range / 2);
      maxX = minX + range;
    });
  }

  void _zoomOut() {
    final dayData = _getFilteredData();
    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 1.25;
      minX = center - range / 2;
      maxX = center + range / 2;
      if (minX < 0) minX = 0;
      if (maxX > (dayData.length - 1).toDouble())
        maxX = (dayData.length - 1).toDouble();
    });
  }

  void _resetZoom() {
    final dayData = _getFilteredData();
    setState(() {
      minX = 0;
      maxX = dayData.length > 50
          ? 50
          : (dayData.isNotEmpty ? dayData.length - 1 : 0).toDouble();
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final dayData = _getFilteredData();
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final double chartHeight = (mq.size.height * 0.45).clamp(
      180.0,
      mq.size.height * 0.6,
    );

    if (selectedDate == null) {
      return Card(
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: chartHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'Ładowanie danych...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // nagłówek
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Temperatura - Piec',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _selectPreviousDay,
                        icon: Icon(Icons.chevron_left),
                        padding: EdgeInsets.all(4),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          selectedDate != null
                              ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}'
                              : 'Data',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size(0, 32),
                        ),
                      ),
                      IconButton(
                        onPressed: _selectNextDay,
                        icon: Icon(Icons.chevron_right),
                        padding: EdgeInsets.all(4),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickDateButton(
                      label: 'Dziś',
                      onPressed: _selectToday,
                      isSelected:
                          selectedDate != null &&
                          _isSameDay(selectedDate!, DateTime.now()),
                    ),
                    SizedBox(width: 8),
                    QuickDateButton(
                      label: 'Wczoraj',
                      onPressed: _selectYesterday,
                      isSelected:
                          selectedDate != null &&
                          _isSameDay(
                            selectedDate!,
                            DateTime.now().subtract(Duration(days: 1)),
                          ),
                    ),
                    SizedBox(width: 8),
                    QuickDateButton(
                      label: '7 dni temu',
                      onPressed: () {
                        setState(() {
                          selectedDate = DateTime.now().subtract(
                            Duration(days: 7),
                          );
                          _updateChartData();
                        });
                      },
                      isSelected:
                          selectedDate != null &&
                          _isSameDay(
                            selectedDate!,
                            DateTime.now().subtract(Duration(days: 7)),
                          ),
                    ),
                    SizedBox(width: 8),
                    QuickDateButton(
                      label: 'Ostatnie dane',
                      onPressed: () {
                        final valid = widget.furnaceData
                            .where((d) => d.timestamp != null)
                            .toList();
                        if (valid.isNotEmpty) {
                          setState(() {
                            selectedDate = valid.last.timestamp;
                            _updateChartData();
                          });
                        }
                      },
                      isSelected:
                          selectedDate != null &&
                          widget.furnaceData
                              .where((d) => d.timestamp != null)
                              .isNotEmpty &&
                          _isSameDay(
                            selectedDate!,
                            widget.furnaceData
                                .where((d) => d.timestamp != null)
                                .toList()
                                .last
                                .timestamp!,
                          ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: dayData.isNotEmpty ? _panLeft : null,
                    icon: Icon(Icons.arrow_back),
                  ),
                  IconButton(
                    onPressed: dayData.isNotEmpty ? _zoomIn : null,
                    icon: Icon(Icons.zoom_in),
                  ),
                  IconButton(
                    onPressed: dayData.isNotEmpty ? _zoomOut : null,
                    icon: Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    onPressed: dayData.isNotEmpty ? _resetZoom : null,
                    icon: Icon(Icons.refresh),
                  ),
                  IconButton(
                    onPressed: dayData.isNotEmpty ? _panRight : null,
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              ),

              SizedBox(height: 16),

              SizedBox(
                height: chartHeight,
                child: Container(
                  height: chartHeight,
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: dayData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.no_sim,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Brak danych',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'dla dnia ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
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
                                  final day = _getFilteredData();
                                  return touchedSpots
                                      .map((spot) {
                                        final idx = spot.x.toInt();
                                        if (idx >= 0 && idx < day.length) {
                                          final d = day[idx];
                                          if (d.timestamp != null &&
                                              d.temperature != null) {
                                            final temp =
                                                (d.temperature!.toDouble() /
                                                _tempScale);
                                            final time =
                                                '${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}';
                                            return LineTooltipItem(
                                              '${temp.toStringAsFixed(1)}°C\n$time',
                                              TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
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
                              horizontalInterval: _safeInterval(maxY - minY, 6),
                              verticalInterval: _safeInterval(
                                maxX - minX,
                                6,
                                min: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              // wyłącz tytuły u góry i po prawej
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),

                              // przywrócone etykiety po lewej (temperatura)
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  interval: _safeInterval(
                                    maxY - minY,
                                    6,
                                    min: 0.1,
                                  ),
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Text(
                                      '${value.toStringAsFixed(1)}°C',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),

                              // dolne (czas) pozostawiam bez zmian
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: _safeInterval(
                                    maxX - minX,
                                    6,
                                    min: 1,
                                  ),
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    final day = _getFilteredData();
                                    if (idx >= 0 && idx < day.length) {
                                      final ts = day[idx].timestamp;
                                      if (ts != null) {
                                        return Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Transform.rotate(
                                            angle: -0.3,
                                            child: Text(
                                              '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(fontSize: 8),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                    return Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _getFilteredData()
                                    .where(
                                      (d) =>
                                          d.timestamp != null &&
                                          d.temperature != null,
                                    )
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.temperature!.toDouble() /
                                            _tempScale,
                                      ),
                                    )
                                    .toList(),
                                isCurved: true,
                                color: Colors.orange,
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                                preventCurveOverShooting: true,
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  dayData.isNotEmpty
                      ? 'Dane z ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}: ${dayData.length} punktów'
                      : 'Wybierz inną datę aby zobaczyć dane',
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
}

// Quick button widget (kopiowane z room chart)
