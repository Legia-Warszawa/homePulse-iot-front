import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../model/devices_iot.dart';
import '../../widget/quick_date_button.dart';

class InteractiveOutsideChart extends StatefulWidget {
  final List<EspOutside_1> outsideData;
  final int selectedTab; // 0=temp, 1=hum, 2=press
  final DateTime? selectedDate;
  final ValueChanged<DateTime?>? onDateSelected;
  final VoidCallback? onSelectToday;
  final VoidCallback? onSelectYesterday;
  final VoidCallback? onSelectSevenDaysAgo;
  final VoidCallback? onSelectLastData;
  final VoidCallback? onSelectPreviousDay;
  final VoidCallback? onSelectNextDay;

  const InteractiveOutsideChart({
    Key? key,
    required this.outsideData,
    this.selectedTab = 0,
    this.selectedDate,
    this.onDateSelected,
    this.onSelectToday,
    this.onSelectYesterday,
    this.onSelectSevenDaysAgo,
    this.onSelectLastData,
    this.onSelectPreviousDay,
    this.onSelectNextDay,
  }) : super(key: key);

  @override
  _InteractiveOutsideChartState createState() =>
      _InteractiveOutsideChartState();
}

class _InteractiveOutsideChartState extends State<InteractiveOutsideChart> {
  double minX = 0;
  double maxX = 50;
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

  // --- KOLORY I STYLE (Twoje oryginalne) ---
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
        belowBarData: BarAreaData(show: false), // Brak tła pod wykresem
      ),
    ];
  }

  void _adjustRanges() {
    final list = _activeData;
    if (list.isEmpty) {
      if (mounted) {
        setState(() {
          minX = 0;
          maxX = 1;
          minY = 0;
          maxY = 1;
        });
      }
      return;
    }

    final values = list.map((d) {
      if (widget.selectedTab == 0) return d.temperature;
      if (widget.selectedTab == 1) return d.humidity;
      return d.pressure - 900;
    }).toList();

    double vMin = values.reduce((a, b) => a < b ? a : b);
    double vMax = values.reduce((a, b) => a > b ? a : b);
    final padding = math.max((vMax - vMin) * 0.12, 0.5);

    if (mounted) {
      setState(() {
        minY = vMin - padding;
        maxY = vMax + padding;
        minX = 0;
        maxX = list.length > 50 ? 50.0 : list.length.toDouble();
        if (maxX <= minX) maxX = minX + 1;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _adjustRanges());
  }

  @override
  void didUpdateWidget(covariant InteractiveOutsideChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outsideData != widget.outsideData ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.selectedTab != widget.selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _adjustRanges());
    }
  }

  // --- GESTY ---
  void _handleDragUpdate(DragUpdateDetails details, double chartWidth) {
    if (_activeData.isEmpty) return;
    
    final double range = maxX - minX;
    final double sensitivity = range / chartWidth; 
    final double delta = -details.primaryDelta! * sensitivity;

    setState(() {
      double newMinX = minX + delta;
      double newMaxX = maxX + delta;

      if (newMinX < 0) {
        newMinX = 0;
        newMaxX = range;
      }
      if (newMaxX > _activeData.length) {
        newMaxX = _activeData.length.toDouble();
        newMinX = newMaxX - range;
      }

      minX = newMinX;
      maxX = newMaxX;
    });
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
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double chartHeight = (mq.size.height * 0.55).clamp(
      250.0,
      mq.size.height * 0.75,
    );
    final int activeTab = widget.selectedTab;

    return SingleChildScrollView(
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- NAGŁÓWEK ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dane Zewnętrzne',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  
                  // --- NOWY UKŁAD: STRZAŁKI NA ZEWNĄTRZ ---
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Strzałka w lewo
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 24),
                        color: isDark ? Colors.white : Colors.black87, // Kolor adaptacyjny
                        onPressed: widget.onSelectPreviousDay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(), // Usuwa domyślne marginesy
                        tooltip: 'Poprzedni dzień',
                      ),
                      
                      const SizedBox(width: 8),

                      // Kapsułka z datą (mniejsza)
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: widget.selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            widget.onDateSelected?.call(picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 24, // Mniejsza wysokość
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary, // Tło Primary
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                widget.selectedDate != null
                                    ? DateFormat('dd/MM').format(widget.selectedDate!)
                                    : 'Data',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Strzałka w prawo
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 24),
                        color: isDark ? Colors.white : Colors.black87, // Kolor adaptacyjny
                        onPressed: widget.onSelectNextDay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Następny dzień',
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              // --- FILTRY ---
              widget.onSelectToday != null
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QuickDateButton(
                              label: 'Dziś',
                              onPressed: widget.onSelectToday!,
                              isSelected: widget.selectedDate != null &&
                                  widget.selectedDate!.difference(DateTime.now()).inDays == 0,
                            ),
                            const SizedBox(width: 8),
                            QuickDateButton(
                              label: 'Wczoraj',
                              onPressed: widget.onSelectYesterday!,
                              isSelected: widget.selectedDate != null &&
                                  widget.selectedDate ==
                                      DateTime.now().subtract(const Duration(days: 1)),
                            ),
                            const SizedBox(width: 8),
                            QuickDateButton(
                              label: '7 dni temu',
                              onPressed: widget.onSelectSevenDaysAgo!,
                              isSelected: widget.selectedDate != null &&
                                  widget.selectedDate ==
                                      DateTime.now().subtract(const Duration(days: 7)),
                            ),
                            const SizedBox(width: 8),
                            QuickDateButton(
                              label: 'Ostatnie dane',
                              onPressed: widget.onSelectLastData!,
                              isSelected: widget.selectedDate != null &&
                                  widget.outsideData.where((d) => d.timestamp != null).isNotEmpty &&
                                  widget.selectedDate ==
                                      widget.outsideData.where((d) => d.timestamp != null).toList().last.timestamp,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(),
              
              const SizedBox(height: 8),

              // --- KONTROLKI ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(onPressed: _panLeft, icon: const Icon(Icons.arrow_back)),
                  IconButton(onPressed: _zoomIn, icon: const Icon(Icons.zoom_in)),
                  IconButton(onPressed: _zoomOut, icon: const Icon(Icons.zoom_out)),
                  IconButton(onPressed: _resetZoom, icon: const Icon(Icons.refresh)),
                  IconButton(onPressed: _panRight, icon: const Icon(Icons.arrow_forward)),
                ],
              ),

              const SizedBox(height: 12),

              // --- WYKRES ---
              Container(
                height: chartHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: data.isEmpty
                      ? Center(
                          child: Text(
                            'Brak danych',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            final width = context.size?.width ?? mq.size.width;
                            _handleDragUpdate(details, width);
                          },
                          child: LineChart(
                            LineChartData(
                              minX: minX,
                              maxX: maxX,
                              minY: minY,
                              maxY: maxY,
                              clipData: FlClipData.all(),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipPadding: const EdgeInsets.all(8),
                                  tooltipMargin: 12,
                                  getTooltipColor: (touchedSpot) => isDark ? Colors.white : Colors.black87,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                          final idx = spot.x.toInt();
                                          if (idx >= 0 && idx < data.length) {
                                            final d = data[idx];
                                            if (activeTab == 0) {
                                              return LineTooltipItem(
                                                'Temp: ${d.temperature.toStringAsFixed(1)}°C\n${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}',
                                                TextStyle(color: isDark ? Colors.black : Colors.white),
                                              );
                                            } else if (activeTab == 1) {
                                              return LineTooltipItem(
                                                'Wilgotność: ${d.humidity.toStringAsFixed(1)}%\n${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}',
                                                TextStyle(color: isDark ? Colors.black : Colors.white),
                                              );
                                            } else {
                                              return LineTooltipItem(
                                                'Ciśnienie: ${d.pressure.toStringAsFixed(0)} hPa\n${d.timestamp!.hour.toString().padLeft(2, '0')}:${d.timestamp!.minute.toString().padLeft(2, '0')}',
                                                TextStyle(color: isDark ? Colors.black : Colors.white),
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
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            '${value.toInt()}°C',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      } else if (activeTab == 1) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            '${value.toInt()}%',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      } else {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            '${(value + 900).toInt()}',
                                            style: const TextStyle(fontSize: 10),
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
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Transform.rotate(
                                            angle: -0.3,
                                            child: Text(
                                              '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(fontSize: 9),
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              ),

              const SizedBox(height: 8),
              
              // --- LEGENDA ---
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

              const SizedBox(height: 8),
              
              // --- LICZNIK ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
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
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}