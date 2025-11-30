import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/devices_iot.dart';

class InteractiveOutsideChart extends StatefulWidget {
  final List<EspOutside_1> outsideData;

  const InteractiveOutsideChart({Key? key, required this.outsideData}) : super(key: key);

  @override
  _InteractiveOutsideChartState createState() => _InteractiveOutsideChartState();
}

class _InteractiveOutsideChartState extends State<InteractiveOutsideChart> {
  double minX = 0;
  double maxX = 50; // Pokaż 50 punktów na raz
  double minY = -10;
  double maxY = 110;

  @override
  void initState() {
    super.initState();
    if (widget.outsideData.isNotEmpty) {
      maxX = widget.outsideData.length > 50 ? 50 : widget.outsideData.length.toDouble();
      
      // Automatyczne skalowanie Y na podstawie danych
      final temps = widget.outsideData.map((e) => e.temperature).toList();
      final humidity = widget.outsideData.map((e) => e.humidity).toList();
      final pressure = widget.outsideData.map((e) => e.pressure - 900).toList(); // Przeskalowane ciśnienie
      
      final allValues = [...temps, ...humidity, ...pressure];
      minY = allValues.reduce((a, b) => a < b ? a : b) - 5;
      maxY = allValues.reduce((a, b) => a > b ? a : b) + 5;
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
      if (maxX > widget.outsideData.length) {
        maxX = widget.outsideData.length.toDouble();
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
      if (maxX > widget.outsideData.length) maxX = widget.outsideData.length.toDouble();
    });
  }

  void _resetZoom() {
    setState(() {
      minX = 0;
      maxX = widget.outsideData.length > 50 ? 50 : widget.outsideData.length.toDouble();
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
              'Dane Zewnętrzne ',
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
              height: 300, // Większa wysokość dla 3 linii
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
                            if (spot.x.toInt() < widget.outsideData.length && spot.x.toInt() >= 0) {
                              final data = widget.outsideData[spot.x.toInt()];
                              
                              // Różne tooltips dla różnych linii
                              if (spot.barIndex == 0) { // Temperatura
                                return LineTooltipItem(
                                  'Temp: ${data.temperature.toStringAsFixed(1)}°C\n${data.timeOnly}',
                                  TextStyle(color: Colors.white, fontSize: 11),
                                );
                              } else if (spot.barIndex == 1) { // Wilgotność
                                return LineTooltipItem(
                                  'Wilgotność: ${data.humidity.toStringAsFixed(1)}%\n${data.timeOnly}',
                                  TextStyle(color: Colors.white, fontSize: 11),
                                );
                              } else if (spot.barIndex == 2) { // Ciśnienie
                                return LineTooltipItem(
                                  'Ciśnienie: ${data.pressure.toStringAsFixed(0)}hPa\n${data.timeOnly}',
                                  TextStyle(color: Colors.white, fontSize: 11),
                                );
                              }
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
                      horizontalInterval: (maxY - minY) / 8,
                      verticalInterval: (maxX - minX) / 6,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 70,
                          interval: (maxY - minY) / 8,
                          getTitlesWidget: (value, meta) {
                            // Różne jednostki dla różnych zakresów
                            if (value >= -10 && value <= 40) {
                              return Text('${value.toInt()}°C', style: TextStyle(fontSize: 8));
                            } else if (value >= 40 && value <= 100) {
                              return Text('${value.toInt()}%', style: TextStyle(fontSize: 8));
                            } else {
                              return Text('${(value + 900).toInt()}', style: TextStyle(fontSize: 8));
                            }
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (maxX - minX) / 6,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < widget.outsideData.length) {
                              final time = widget.outsideData[value.toInt()].timestamp;
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
                      // Temperatura
                      LineChartBarData(
                        spots: widget.outsideData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
                            .toList(),
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        preventCurveOverShooting: true,
                      ),
                      // Wilgotność
                      LineChartBarData(
                        spots: widget.outsideData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.humidity))
                            .toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 2,
                        dotData: FlDotData(show: false),
                        preventCurveOverShooting: true,
                      ),
                      // Ciśnienie (przeskalowane z 1000hPa do ~100)
                      LineChartBarData(
                        spots: widget.outsideData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.pressure - 900))
                            .toList(),
                        isCurved: true,
                        color: Colors.purple,
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
            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Temperatura (°C)', Colors.red),
                _buildLegendItem('Wilgotność (%)', Colors.green),
                _buildLegendItem('Ciśnienie (900+hPa)', Colors.purple),
              ],
            ),
            SizedBox(height: 8),
            // Informacja o aktualnym zakresie
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Wyświetlane punkty: ${minX.toInt()} - ${maxX.toInt()} z ${widget.outsideData.length}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10)),
      ],
    );
  }
}