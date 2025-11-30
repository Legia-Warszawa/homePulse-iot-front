import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../model/devices_iot.dart';

class InteractiveRoomChart extends StatefulWidget {
  final List<EspRoom1> roomData;

  const InteractiveRoomChart({Key? key, required this.roomData}) : super(key: key);

  @override
  _InteractiveRoomChartState createState() => _InteractiveRoomChartState();
}

class _InteractiveRoomChartState extends State<InteractiveRoomChart> {
  double minX = 0;
  double maxX = 50; // Pokaż 50 punktów na raz
  double minY = 20;
  double maxY = 26;

  @override
  void initState() {
    super.initState();
    if (widget.roomData.isNotEmpty) {
      maxX = widget.roomData.length > 50 ? 50 : widget.roomData.length.toDouble();
      
      // Automatyczne skalowanie Y na podstawie danych
      final temps = widget.roomData.map((e) => e.temperature).toList();
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
      if (maxX > widget.roomData.length) {
        maxX = widget.roomData.length.toDouble();
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
      if (maxX > widget.roomData.length) maxX = widget.roomData.length.toDouble();
    });
  }

  void _resetZoom() {
    setState(() {
      minX = 0;
      maxX = widget.roomData.length > 50 ? 50 : widget.roomData.length.toDouble();
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
              'Temperatura - Pokój',
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
                         //tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: EdgeInsets.all(8),
                        tooltipMargin: 16,
                        // WAŻNE: Ustawienia pozycji tooltip
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            if (spot.x.toInt() < widget.roomData.length) {
                              final data = widget.roomData[spot.x.toInt()];
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
                    
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 70,
                          interval: (maxY - minY) / 8,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toStringAsFixed(1)}°C', 
                              style: TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: (maxX - minX) / 8,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < widget.roomData.length) {
                              final time = widget.roomData[value.toInt()].timestamp;
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Transform.rotate(
                                  angle: -0.5,
                                  child: Text(
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 9),
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
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.roomData
                            .asMap()
                            .entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
                            .toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Informacja o aktualnym zakresie
            Container(
              width: double.infinity,
              child: Text(
                'Wyświetlane punkty: ${minX.toInt()} - ${maxX.toInt()} z ${widget.roomData.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}