import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:homepulse/widget/chart/Interactive_furnace_chart.dart';
import 'package:homepulse/widget/chart/Interactive_outside_chart.dart';
import 'package:homepulse/widget/chart/Interactive_room_chart.dart';
import '../../model/devices_iot.dart';

class DeviceChartsWidget extends StatelessWidget {
  final List<EspRoom1> roomData;
  final List<EspOutside_1> outsideData;
  final List<EspFurnanceC02> furnaceData;

  const DeviceChartsWidget({
    Key? key,
    required this.roomData,
    required this.outsideData,
    required this.furnaceData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Interaktywny wykres temperatury pokoju
          if (roomData.isNotEmpty) InteractiveRoomChart(roomData: roomData),
          SizedBox(height: 20),

          // Wykres danych zewnętrznych
          if (outsideData.isNotEmpty) InteractiveOutsideChart(outsideData: outsideData),
          SizedBox(height: 20),

          // Wykres pieca
          if (furnaceData.isNotEmpty) InteractiveFurnaceChart(furnaceData: furnaceData),
        ],
      ),
    );
  }

  Widget _buildOutsideChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dane Zewnętrzne',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  // Ustawienie własnych granic osi
                  minY: -10, // Minimalna wartość Y
                  maxY: 110, // Maksymalna wartość Y
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 20, // Co 20 jednostek
                        getTitlesWidget: (value, meta) {
                          // Różne jednostki dla różnych zakresów
                          if (value == -10)
                            return Text('-10°C', style: TextStyle(fontSize: 9));
                          if (value == 10)
                            return Text('10°C', style: TextStyle(fontSize: 9));
                          if (value == 30)
                            return Text('30°C', style: TextStyle(fontSize: 9));
                          if (value == 50)
                            return Text('50%', style: TextStyle(fontSize: 9));
                          if (value == 70)
                            return Text('70%', style: TextStyle(fontSize: 9));
                          if (value == 90)
                            return Text(
                              '900hPa',
                              style: TextStyle(fontSize: 9),
                            );
                          return Text(
                            '${value.toInt()}',
                            style: TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0 &&
                              value.toInt() < outsideData.length) {
                            final time = outsideData[value.toInt()].timestamp;
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
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // Temperatura
                    LineChartBarData(
                      spots: outsideData
                          .asMap()
                          .entries
                          .map(
                            (e) =>
                                FlSpot(e.key.toDouble(), e.value.temperature),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    // Wilgotność
                    LineChartBarData(
                      spots: outsideData
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(e.key.toDouble(), e.value.humidity),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    // Ciśnienie (przeskalowane z 1000hPa do ~100)
                    LineChartBarData(
                      spots: outsideData
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              (e.value.pressure - 900),
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            // Poprawiona legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Temperatura (°C)', Colors.red),
                _buildLegendItem('Wilgotność (%)', Colors.green),
                _buildLegendItem('Ciśnienie (900+hPa)', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildFurnaceChart() {
  //   return Card(
  //     child: Padding(
  //       padding: EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Temperatura - Piec',
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //           SizedBox(height: 16),
  //           SizedBox(
  //             height: 200,
  //             child: LineChart(
  //               LineChartData(
  //                 gridData: FlGridData(show: true),
  //                 titlesData: FlTitlesData(
  //                   leftTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       reservedSize: 40,
  //                       getTitlesWidget: (value, meta) {
  //                         return Text('${value.toInt()}°C');
  //                       },
  //                     ),
  //                   ),
  //                   bottomTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       reservedSize: 30,
  //                       getTitlesWidget: (value, meta) {
  //                         if (value.toInt() < furnaceData.length) {
  //                           return Text(furnaceData[value.toInt()].timeOnly);
  //                         }
  //                         return Text('');
  //                       },
  //                     ),
  //                   ),
  //                   topTitles: AxisTitles(
  //                     sideTitles: SideTitles(showTitles: false),
  //                   ),
  //                   rightTitles: AxisTitles(
  //                     sideTitles: SideTitles(showTitles: false),
  //                   ),
  //                 ),
  //                 borderData: FlBorderData(show: true),
  //                 lineBarsData: [
  //                   LineChartBarData(
  //                     spots: furnaceData
  //                         .asMap()
  //                         .entries
  //                         .map(
  //                           (e) =>
  //                               FlSpot(e.key.toDouble(), e.value.temperature),
  //                         )
  //                         .toList(),
  //                     isCurved: true,
  //                     color: Colors.orange,
  //                     barWidth: 3,
  //                     dotData: FlDotData(show: false),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildRoomChart() {
  //   return Card(
  //     child: Padding(
  //       padding: EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Temperatura - Pokój (przeciągnij aby przesunąć, pinch aby zoomować)',
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           ),
  //           SizedBox(height: 16),
  //           SizedBox(
  //             height: 200,
  //             child: LineChart(
  //               LineChartData(
  //                 // DODAJ INTERAKTYWNOŚĆ
  //                 lineTouchData: LineTouchData(
  //                   enabled: true,
  //                   touchTooltipData: LineTouchTooltipData(
  //                     getTooltipItems: (touchedSpots) {
  //                       return touchedSpots.map((spot) {
  //                         final data = roomData[spot.x.toInt()];
  //                         return LineTooltipItem(
  //                           '${data.temperature.toStringAsFixed(1)}°C\n${data.timeOnly}',
  //                           TextStyle(color: Colors.white, fontSize: 12),
  //                         );
  //                       }).toList();
  //                     },
  //                   ),
  //                 ),
  //                 // WŁĄCZ PRZESUWANIE I ZOOM
  //                 minX: 0,
  //                 maxX: roomData.length.toDouble() - 1,
  //                 clipData: FlClipData.all(),

  //                 gridData: FlGridData(show: true),
  //                 titlesData: FlTitlesData(
  //                   leftTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       reservedSize: 70,
  //                       interval: 0.2,
  //                       getTitlesWidget: (value, meta) {
  //                         return Text(
  //                           '${value.toStringAsFixed(1)}°C',
  //                           style: TextStyle(fontSize: 10),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                   bottomTitles: AxisTitles(
  //                     sideTitles: SideTitles(
  //                       showTitles: true,
  //                       reservedSize: 50,
  //                       interval: 5,
  //                       getTitlesWidget: (value, meta) {
  //                         if (value.toInt() >= 0 &&
  //                             value.toInt() < roomData.length) {
  //                           final time = roomData[value.toInt()].timestamp;
  //                           return Padding(
  //                             padding: EdgeInsets.only(top: 8),
  //                             child: Transform.rotate(
  //                               angle: -0.5,
  //                               child: Text(
  //                                 '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
  //                                 style: TextStyle(fontSize: 9),
  //                               ),
  //                             ),
  //                           );
  //                         }
  //                         return Text('');
  //                       },
  //                     ),
  //                   ),
  //                   topTitles: AxisTitles(
  //                     sideTitles: SideTitles(showTitles: false),
  //                   ),
  //                   rightTitles: AxisTitles(
  //                     sideTitles: SideTitles(showTitles: false),
  //                   ),
  //                 ),
  //                 borderData: FlBorderData(show: true),
  //                 lineBarsData: [
  //                   LineChartBarData(
  //                     spots: roomData
  //                         .asMap()
  //                         .entries
  //                         .map(
  //                           (e) =>
  //                               FlSpot(e.key.toDouble(), e.value.temperature),
  //                         )
  //                         .toList(),
  //                     isCurved: true,
  //                     color: Colors.blue,
  //                     barWidth: 3,
  //                     dotData: FlDotData(show: false),
  //                   ),
  //                 ],
  //               ),
  //               // KLUCZOWE: Włącz obsługę gestów
  //               duration: Duration(milliseconds: 150),
  //               curve: Curves.linear,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
