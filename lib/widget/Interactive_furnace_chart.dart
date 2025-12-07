import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  double minX = 0;
  double maxX = 50;
  double minY = 0;
  double maxY = 40;

  @override
  void initState() {
    super.initState();
    _filterDataForSelectedDay();
  }

  // ============================================================
  //      FILTROWANIE DANYCH NA PODSTAWIE WYBRANEJ DATY
  // ============================================================
  void _filterDataForSelectedDay() {
    filteredData = widget.furnaceData.where((d) {
      return d.timestamp.year == selectedDay.year &&
             d.timestamp.month == selectedDay.month &&
             d.timestamp.day == selectedDay.day;
    }).toList();

    if (filteredData.isEmpty) {
      minX = 0;
      maxX = 1;
      minY = 0;
      maxY = 1;
      return;
    }

    maxX = filteredData.length > 50 ? 50 : filteredData.length.toDouble();

    final temps = filteredData.map((e) => e.temperature).toList();
    minY = temps.reduce((a, b) => a < b ? a : b) - 1;
    maxY = temps.reduce((a, b) => a > b ? a : b) + 1;
  }

  // ============================================================
  //                  NAWIGACJA (PAN + ZOOM)
  // ============================================================
  void _panLeft() {
    if (filteredData.isEmpty) return;

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
    if (filteredData.isEmpty) return;

    setState(() {
      double range = maxX - minX;
      maxX += 10;
      minX = maxX - range;
      if (maxX > filteredData.length) {
        maxX = filteredData.length.toDouble();
        minX = maxX - range;
      }
    });
  }

  void _zoomIn() {
    if (filteredData.isEmpty) return;

    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 0.8;
      minX = center - range / 2;
      maxX = center + range / 2;

      if (minX < 0) minX = 0;
      if (maxX > filteredData.length) maxX = filteredData.length.toDouble();
    });
  }

  void _zoomOut() {
    if (filteredData.isEmpty) return;

    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 1.25;
      minX = center - range / 2;
      maxX = center + range / 2;

      if (minX < 0) minX = 0;
      if (maxX > filteredData.length) maxX = filteredData.length.toDouble();
    });
  }

  void _resetZoom() {
    if (filteredData.isEmpty) return;

    setState(() {
      minX = 0;
      maxX = filteredData.length > 50 ? 50 : filteredData.length.toDouble();
    });
  }

  // ============================================================
  //                           UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================================================
            //           WYBÓR DNIA Z KALENDARZA
            // ================================================
            TextButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text(
                "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}",
              ),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  setState(() {
                    selectedDay = picked;
                    _filterDataForSelectedDay();
                  });
                }
              },
            ),

            SizedBox(height: 8),

            Text(
              'Temperatura - Piec (24h)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // ================================================
            //                PRZYCISKI ZOOM + PAN
            // ================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: _panLeft, icon: Icon(Icons.arrow_back)),
                IconButton(onPressed: _zoomIn, icon: Icon(Icons.zoom_in)),
                IconButton(onPressed: _zoomOut, icon: Icon(Icons.zoom_out)),
                IconButton(onPressed: _panRight, icon: Icon(Icons.arrow_forward)),
              ],
            ),

            SizedBox(height: 16),

            // ================================================
            //                     WYKRES
            // ================================================
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: filteredData.isEmpty
                    ? Center(child: Text("Brak danych dla wybranego dnia"))
                    : LineChart(
                        LineChartData(
                          minX: minX,
                          maxX: maxX,
                          minY: minY,
                          maxY: maxY,

                          clipData: FlClipData.all(),

                          // ===============================
                          //      TOOLTIP (odwrócony index)
                          // ===============================
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  int reversedIndex = filteredData.length - 1 - spot.x.toInt();
                                  final data = filteredData[reversedIndex];
                                  return LineTooltipItem(
                                    "${data.temperature.toStringAsFixed(1)}°C\n${data.timeOnly}",
                                    TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),

                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: (maxY - minY) / 6,
                            verticalInterval: (maxX - minX) / 6,
                          ),

                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (maxY - minY) / 6,
                                getTitlesWidget: (value, meta) {
                                  return Text("${value.toStringAsFixed(1)}°C", style: TextStyle(fontSize: 9));
                                },
                              ),
                            ),

                            // ===============================
                            //    OŚ CZASU (odwrócony index)
                            // ===============================
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (maxX - minX) / 6,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  int i = value.toInt();
                                  if (i >= 0 && i < filteredData.length) {
                                    final realIndex = filteredData.length - 1 - i;
                                    final time = filteredData[realIndex].timestamp;
                                    return Transform.rotate(
                                      angle: -0.3,
                                      child: Text(
                                        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                                        style: TextStyle(fontSize: 8),
                                      ),
                                    );
                                  }
                                  return Text("");
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

                          // ===============================
                          //       WYKRES (odwrócony)
                          // ===============================
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(filteredData.length, (i) {
                                final reversedIndex = filteredData.length - 1 - i;
                                return FlSpot(
                                  i.toDouble(),
                                  filteredData[reversedIndex].temperature,
                                );
                              }),
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            SizedBox(height: 8),

            Center(
              child: Text(
                "Wyświetlane punkty: ${minX.toInt()} - ${maxX.toInt()} z ${filteredData.length}",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
