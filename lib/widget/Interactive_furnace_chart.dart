import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Kluczowy import dla formatowania dat
import '../model/devices_iot.dart';

class InteractiveFurnaceChart extends StatefulWidget {
  final List<EspFurnanceC02> furnaceData;

  const InteractiveFurnaceChart({Key? key, required this.furnaceData}) : super(key: key);

  @override
  _InteractiveFurnaceChartState createState() => _InteractiveFurnaceChartState();
}

class _InteractiveFurnaceChartState extends State<InteractiveFurnaceChart> {
  DateTime selectedDay = DateTime.now();
  List<EspFurnanceC02> filteredData = [];

  // Zmienne X przechowują TIMESTAMPY (milisekundy od Epoki)
  late double minX;
  late double maxX;
  double minY = 0;
  double maxY = 40;
  
  // Stałe czasowe do operacji (w milisekundach)
  static const double msInHour = 3600 * 1000;
  static const double panDeltaHours = 2; // O ile godzin przesuwamy widok
  static const double initialRangeHours = 4; // Początkowy widok 4h

  @override
  void initState() {
    super.initState();
    // Inicjalizujemy zakresy na podstawie danych
    _filterDataAndInitializeLimits(); 
  }
  
  // ============================================================
  //     FILTROWANIE I INICJALIZACJA ZAKRESÓW CZASOWYCH
  // ============================================================
  void _filterDataAndInitializeLimits() {
    // 1. Filtracja
    filteredData = widget.furnaceData.where((d) {
      return d.timestamp.year == selectedDay.year &&
             d.timestamp.month == selectedDay.month &&
             d.timestamp.day == selectedDay.day;
    }).toList();
    
    // 2. Sortowanie (Kluczowe: Najnowsze dane na prawym skraju)
    filteredData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (filteredData.isEmpty) {
      minX = 0;
      maxX = 1;
      minY = 0;
      maxY = 1;
      return;
    }

    // 3. Inicjalizacja osi Y (Temperatura)
    final temps = filteredData.map((e) => e.temperature).toList();
    minY = temps.reduce((a, b) => a < b ? a : b) - 1;
    maxY = temps.reduce((a, b) => a > b ? a : b) + 1;
    
    // 4. Inicjalizacja osi X (TIMESTAMPY)
    final double absoluteMinX = filteredData.first.timestamp.millisecondsSinceEpoch.toDouble();
    final double absoluteMaxX = filteredData.last.timestamp.millisecondsSinceEpoch.toDouble();
    
    double currentRange = absoluteMaxX - absoluteMinX;

    // Ustawienie początkowego widoku na OSTATNIE 4H (lub cały zakres)
    if (currentRange > initialRangeHours * msInHour) {
      minX = absoluteMaxX - initialRangeHours * msInHour; 
      maxX = absoluteMaxX;
    } else {
      minX = absoluteMinX;
      maxX = absoluteMaxX;
    }
  }
  
  // ============================================================
  //     NAWIGACJA (PAN + ZOOM) OPARTA NA CZASIE (MS)
  // ============================================================
  
  void _pan(double hours) {
    if (filteredData.isEmpty) return;

    setState(() {
      final double delta = hours * msInHour; 
      double currentRange = maxX - minX;

      minX += delta;
      maxX += delta;

      final double absoluteMinX = filteredData.first.timestamp.millisecondsSinceEpoch.toDouble();
      final double absoluteMaxX = filteredData.last.timestamp.millisecondsSinceEpoch.toDouble();

      // Zabezpieczenie przed wyjściem poza skrajne wartości danych
      if (minX < absoluteMinX) {
        minX = absoluteMinX;
        maxX = absoluteMinX + currentRange;
      }
      if (maxX > absoluteMaxX) {
        maxX = absoluteMaxX;
        minX = absoluteMaxX - currentRange;
      }
    });
  }

  void _zoom(double factor) {
    if (filteredData.isEmpty) return;

    setState(() {
      double center = (minX + maxX) / 2;
      double newRange = (maxX - minX) * factor;

      // Ogranicz minimalny zoom do 1 godziny
      if (newRange < msInHour) return; 

      minX = center - newRange / 2;
      maxX = center + newRange / 2;

      final double absoluteMinX = filteredData.first.timestamp.millisecondsSinceEpoch.toDouble();
      final double absoluteMaxX = filteredData.last.timestamp.millisecondsSinceEpoch.toDouble();

      if (minX < absoluteMinX) {
         minX = absoluteMinX;
      }
      if (maxX > absoluteMaxX) {
         maxX = absoluteMaxX;
      }
    });
  }

  void _panLeft() => _pan(-panDeltaHours); 
  void _panRight() => _pan(panDeltaHours); 
  void _zoomIn() => _zoom(0.8);
  void _zoomOut() => _zoom(1.25);

  void _resetZoom() {
    if (filteredData.isEmpty) return;
    setState(() {
      _filterDataAndInitializeLimits(); // Resetuje do domyślnych 4h
    });
  }
  
  // --- POPRAWNA FUNKCJA Formatująca Tytuły na Osi X (Używa intl) ---

  Widget _getBottomTitles(double value, TitleMeta meta) {
    // value to timestamp w milisekundach
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    final format = DateFormat('HH:mm'); 

    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Transform.rotate(
        angle: -0.3,
        child: Text(
          format.format(dateTime),
          style: const TextStyle(fontSize: 8),
        ),
      ),
    );
  }

  // ============================================================
  //                          UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final double verticalIntervalMs = panDeltaHours * msInHour; // Interwał siatki co 2 godziny

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- WYBÓR DNIA Z KALENDARZA ---
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                DateFormat('yyyy-MM-dd').format(selectedDay),
              ),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (picked != null && picked != selectedDay) {
                  setState(() {
                    selectedDay = picked;
                    _filterDataAndInitializeLimits(); 
                  });
                }
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'Temperatura - Piec (Wizualizacja Czasowa)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // --- PRZYCISKI KONTROLNE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: _panLeft, icon: const Icon(Icons.arrow_back), tooltip: 'Starsze (2h wstecz)'),
                IconButton(onPressed: _zoomIn, icon: const Icon(Icons.zoom_in), tooltip: 'Przybliż'),
                IconButton(onPressed: _zoomOut, icon: const Icon(Icons.zoom_out), tooltip: 'Oddal'),
                IconButton(onPressed: _resetZoom, icon: const Icon(Icons.refresh), tooltip: 'Reset widoku'),
                IconButton(onPressed: _panRight, icon: const Icon(Icons.arrow_forward), tooltip: 'Nowsze (2h w przód)'),
              ],
            ),

            const SizedBox(height: 16),

            // --- WYKRES ---
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: filteredData.isEmpty
                    ? Center(child: Text("Brak danych dla ${DateFormat('yyyy-MM-dd').format(selectedDay)}"))
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
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  final dateTime = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                  // Użycie formatowania intl w tooltipie
                                  return LineTooltipItem(
                                    "${spot.y.toStringAsFixed(1)}°C\n${DateFormat('HH:mm:ss').format(dateTime)}",
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),

                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: (maxY - minY) / 6,
                            verticalInterval: verticalIntervalMs, // Interwał czasowy
                          ),

                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (maxY - minY) / 6,
                                reservedSize: 50,
                                // POPRAWKA BŁĘDU: Dodano 'meta'
                                getTitlesWidget: (value, meta) {
                                  return Text("${value.toStringAsFixed(1)}°C", style: const TextStyle(fontSize: 9));
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: verticalIntervalMs, // Interwał czasowy
                                reservedSize: 40,
                                getTitlesWidget: _getBottomTitles, // Używamy funkcji formatującej czas
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),

                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.grey.shade400),
                          ),

                          lineBarsData: [
                            LineChartBarData(
                              spots: filteredData
                                  // KLUCZOWE MAPOWANIE: Oś X = Timestamp w ms
                                  .map((e) => FlSpot(
                                        e.timestamp.millisecondsSinceEpoch.toDouble(),
                                        e.temperature,
                                      ))
                                  .toList(),
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              preventCurveOverShooting: true,
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Informacja o aktualnym zakresie czasowym
            Center(
              child: Text(
                "Wyświetlany zakres: ${DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(minX.toInt()))} - ${DateFormat('HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(maxX.toInt()))}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}