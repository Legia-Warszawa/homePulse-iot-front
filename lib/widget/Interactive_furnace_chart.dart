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
  double minX = 0;
  double maxX = 50; // Pokaż 50 punktów na raz
  double minY = 20;
  double maxY = 26;

  @override
  void initState() {
    super.initState();
    if (widget.furnaceData.isNotEmpty) {
      maxX = widget.furnaceData.length > 50 ? 50 : widget.furnaceData.length.toDouble();
      
      // Automatyczne skalowanie Y na podstawie danych
      final temps = widget.furnaceData.map((e) => e.temperature).toList();
      minY = temps.reduce((a, b) => a < b ? a : b) - 1;
      maxY = temps.reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  void _panLeft() {
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
    setState(() {
      double range = maxX - minX;
      maxX += 10;
      minX = maxX - range;
      if (maxX > widget.furnaceData.length) {
        maxX = widget.furnaceData.length.toDouble();
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
    setState(() {
      double center = (minX + maxX) / 2;
      double range = (maxX - minX) * 1.25;
      minX = center - range / 2;
      maxX = center + range / 2;
      
      if (minX < 0) minX = 0;
      if (maxX > widget.furnaceData.length) maxX = widget.furnaceData.length.toDouble();
    });
  }

  void _resetZoom() {
    setState(() {
      minX = 0;
      maxX = widget.furnaceData.length > 50 ? 50 : widget.furnaceData.length.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperatura - Piec ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Przyciski kontrolne
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _panLeft,
                  icon: Icon(Icons.arrow_back),
                  tooltip: 'Przesuń w lewo',
                ),
                IconButton(
                  onPressed: _zoomIn,
                  icon: Icon(Icons.zoom_in),
                  tooltip: 'Przybliż',
                ),
                IconButton(
                  onPressed: _zoomOut,
                  icon: Icon(Icons.zoom_out),
                  tooltip: 'Oddal',
                ),
                // IconButton(
                //   onPressed: _resetZoom,
                //   icon: Icon(Icons.refresh),
                //   tooltip: 'Reset widoku',
                // ),
                IconButton(
                  onPressed: _panRight,
                  icon: Icon(Icons.arrow_forward),
                  tooltip: 'Przesuń w prawo',
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 250,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
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
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: EdgeInsets.all(8),
                        tooltipMargin: 16,
                        // WAŻNE: Ustawienia pozycji tooltip
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            if (spot.x.toInt() < widget.furnaceData.length && spot.x.toInt() >= 0) {
                              final data = widget.furnaceData[spot.x.toInt()];
                              return LineTooltipItem(
                                '${data.temperature.toStringAsFixed(1)}°C\n${data.timeOnly}',
                                TextStyle(color: Colors.white, fontSize: 12),
                              );
                            }
                            return null;
                          }).whereType<LineTooltipItem>().toList();
                        },
                      ),
                    ),
                    
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: true,
                      horizontalInterval: (maxY - minY) / 6,
                      verticalInterval: (maxX - minX) / 6,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          interval: (maxY - minY) / 6,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text(
                                '${value.toStringAsFixed(1)}°C', 
                                style: TextStyle(fontSize: 9),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (maxX - minX) / 6,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < widget.furnaceData.length) {
                              final time = widget.furnaceData[value.toInt()].timestamp;
                              return Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Transform.rotate(
                                  angle: -0.3,
                                  child: Text(
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.furnaceData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
                            .toList(),
                        isCurved: true,
                        color: Colors.orange, // Kolor charakterystyczny dla pieca
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
            // Informacja o aktualnym zakresie
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Wyświetlane punkty: ${minX.toInt()} - ${maxX.toInt()} z ${widget.furnaceData.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}