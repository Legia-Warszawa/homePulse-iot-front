import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/devices_iot.dart';

class InteractiveRoomChart extends StatefulWidget {
  final List<EspRoom1> roomData;

  const InteractiveRoomChart({Key? key, required this.roomData})
    : super(key: key);

  @override
  _InteractiveRoomChartState createState() => _InteractiveRoomChartState();
}

class _InteractiveRoomChartState extends State<InteractiveRoomChart> {
  double minX = 0;
  double maxX = 50;
  double minY = 20;
  double maxY = 26;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.roomData.isNotEmpty) {
      // Znajdź pierwszą datę która nie jest null
      final validData = widget.roomData
          .where((data) => data.timestamp != null)
          .toList();
      if (validData.isNotEmpty) {
        selectedDate = validData.last.timestamp;
        _updateChartData();
      } else {
        // Fallback jeśli wszystkie daty są null
        selectedDate = DateTime.now();
      }
    } else {
      selectedDate = DateTime.now();
    }
  }

  void _updateChartData() {
    // Sprawdź czy selectedDate nie jest null
    if (selectedDate == null) return;

    // Filtruj dane dla wybranego dnia
    final dayData = _getFilteredData();

    if (dayData.isNotEmpty) {
      maxX = dayData.length > 50 ? 50 : dayData.length.toDouble();
      final temps = dayData
          .map((e) => e.temperature)
          .where((temp) => temp != null)
          .toList();
      if (temps.isNotEmpty) {
        minY = temps.reduce((a, b) => a < b ? a : b) - 1;
        maxY = temps.reduce((a, b) => a > b ? a : b) + 1;
      }
      minX = 0;
    }
  }

  // Pobierz dane dla wybranego dnia z null safety
  List<EspRoom1> _getFilteredData() {
    if (selectedDate == null) return [];

    return widget.roomData.where((data) {
      // Sprawdź czy timestamp nie jest null
      if (data.timestamp == null) return false;

      return data.timestamp!.year == selectedDate!.year &&
          data.timestamp!.month == selectedDate!.month &&
          data.timestamp!.day == selectedDate!.day;
    }).toList();
  }

  void _selectDate() async {
    if (selectedDate == null) return;

    // Znajdź pierwszą i ostatnią prawidłową datę
    final validDates = widget.roomData
        .where((data) => data.timestamp != null)
        .map((data) => data.timestamp!)
        .toList();

    if (validDates.isEmpty) return;

    validDates.sort();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: validDates.first,
      lastDate: DateTime.now(),
      helpText: 'Wybierz datę dla danych',
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _updateChartData();
      });
    }
  }

  // Szybkie przyciski dla wyboru dat
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

  @override
  Widget build(BuildContext context) {
    // Sprawdź czy selectedDate nie jest null
    if (selectedDate == null) {
      return Card(
        child: Center(child: Text('Błąd: Brak prawidłowych dat w danych')),
      );
    }

    final dayData = _getFilteredData();
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek z selektorem dat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Temperatura - Pokój',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    // Przycisk poprzedni dzień
                    IconButton(
                      onPressed: _selectPreviousDay,
                      icon: Icon(Icons.chevron_left),
                      tooltip: 'Poprzedni dzień',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    // Przycisk kalendarza z datą
                    ElevatedButton.icon(
                      onPressed: _selectDate,
                      icon: Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size(0, 32),
                      ),
                    ),
                    // Przycisk następny dzień
                    IconButton(
                      onPressed: _selectNextDay,
                      icon: Icon(Icons.chevron_right),
                      tooltip: 'Następny dzień',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),

            // Szybkie przyciski wyboru dat
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickDateButton(
                    label: 'Dziś',
                    onPressed: _selectToday,
                    isSelected: _isSameDay(selectedDate!, DateTime.now()),
                  ),
                  SizedBox(width: 8),
                  _QuickDateButton(
                    label: 'Wczoraj',
                    onPressed: _selectYesterday,
                    isSelected: _isSameDay(
                      selectedDate!,
                      DateTime.now().subtract(Duration(days: 1)),
                    ),
                  ),
                  SizedBox(width: 8),
                  _QuickDateButton(
                    label: '7 dni temu',
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime.now().subtract(
                          Duration(days: 7),
                        );
                        _updateChartData();
                      });
                    },
                    isSelected: _isSameDay(
                      selectedDate!,
                      DateTime.now().subtract(Duration(days: 7)),
                    ),
                  ),
                  SizedBox(width: 8),
                  _QuickDateButton(
                    label: 'Ostatnie dane',
                    onPressed: () {
                      final validData = widget.roomData
                          .where((data) => data.timestamp != null)
                          .toList();
                      if (validData.isNotEmpty) {
                        setState(() {
                          selectedDate = validData.last.timestamp;
                          _updateChartData();
                        });
                      }
                    },
                    isSelected: () {
                      final validData = widget.roomData
                          .where((data) => data.timestamp != null)
                          .toList();
                      return validData.isNotEmpty &&
                          _isSameDay(selectedDate!, validData.last.timestamp!);
                    }(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Przyciski kontrolne wykresu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: dayData.isNotEmpty ? _panLeft : null,
                  icon: Icon(Icons.arrow_back),
                  tooltip: 'Przesuń w lewo',
                ),
                IconButton(
                  onPressed: dayData.isNotEmpty ? _zoomIn : null,
                  icon: Icon(Icons.zoom_in),
                  tooltip: 'Przybliż',
                ),
                IconButton(
                  onPressed: dayData.isNotEmpty ? _zoomOut : null,
                  icon: Icon(Icons.zoom_out),
                  tooltip: 'Oddal',
                ),
                IconButton(
                  onPressed: dayData.isNotEmpty ? _resetZoom : null,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Reset widoku',
                ),
                IconButton(
                  onPressed: dayData.isNotEmpty ? _panRight : null,
                  icon: Icon(Icons.arrow_forward),
                  tooltip: 'Przesuń w prawo',
                ),
              ],
            ),

            SizedBox(height: 16),

            // Wykres lub komunikat o braku danych
            SizedBox(
              height: 250,
              child: Container(
                height: 250,
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
                              tooltipMargin: 16,
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots
                                    .map((spot) {
                                      if (spot.x.toInt() < dayData.length) {
                                        final data = dayData[spot.x.toInt()];
                                        // Sprawdź czy dane są prawidłowe
                                        if (data.timestamp != null) {
                                          return LineTooltipItem(
                                            '${data.temperature.toStringAsFixed(1)}°C\n${data.timestamp!.hour.toString().padLeft(2, '0')}:${data.timestamp!.minute.toString().padLeft(2, '0')}',
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
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 70,
                                interval: (maxY - minY) / 6,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toStringAsFixed(1)}°C',
                                    style: TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: (maxX - minX) / 6,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < dayData.length) {
                                    final data = dayData[value.toInt()];
                                    if (data.timestamp != null) {
                                      return Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Transform.rotate(
                                          angle: -0.5,
                                          child: Text(
                                            '${data.timestamp!.hour.toString().padLeft(2, '0')}:${data.timestamp!.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      );
                                    }
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
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: dayData
                                  .where(
                                    (data) =>
                                        data.timestamp != null &&
                                        data.temperature != null,
                                  )
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.temperature.toDouble(),
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Informacja o danych
            GestureDetector(
              onTap: openLimitData,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  dayData.isNotEmpty
                      ? 'Dane z ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}: ${dayData.length} punktów'
                      : 'Wybierz inną datę aby zobaczyć dane',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Reszta metod bez zmian ale z null safety...
  void _panLeft() {
    final dayData = _getFilteredData();
    setState(() {
      if (minX > 0) {
        double range = maxX - minX;
        minX -= 10;
        maxX = minX + range;
        if (minX < 0) {
          minX = 0;
          maxX = range;
        }
      }
    });
  }

  void _panRight() {
    final dayData = _getFilteredData();
    setState(() {
      double range = maxX - minX;
      maxX += 10;
      minX = maxX - range;
      if (maxX > dayData.length) {
        maxX = dayData.length.toDouble();
        minX = maxX - range;
      }
    });
  }

  void _zoomIn() {
    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 0.8;
      minX = center - range / 2;
      maxX = center + range / 2;
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
      if (maxX > dayData.length) maxX = dayData.length.toDouble();
    });
  }

  void _resetZoom() {
    final dayData = _getFilteredData();
    setState(() {
      minX = 0;
      maxX = dayData.length > 50 ? 50 : dayData.length.toDouble();
    });
  }

  void openLimitData() {
    if (selectedDate == null) return;

    final dayData = _getFilteredData();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Informacje o danych'),
          content: Text(
            'Wybrany dzień: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}\n'
            'Punkty danych: ${dayData.length}\n'
            'Całkowita liczba rekordów: ${widget.roomData.length}\n\n'
            'Użyj przycisków nawigacji aby zmienić datę lub zakres wykresu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }
}

// Widget dla szybkich przycisków wyboru dat
class _QuickDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  const _QuickDateButton({
    required this.label,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(16),
      color: isSelected
          ? theme.colorScheme.primary.withOpacity(0.2)
          : theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
