import 'package:flutter/material.dart';
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
    // Używamy ScrollView, aby użytkownik mógł przewijać listę wykresów
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // 1. Wykres temperatury wewnątrz (Pokój)
          if (roomData.isNotEmpty) 
            InteractiveRoomChart(roomData: roomData),
          
          const SizedBox(height: 16),

          // 2. Wykres danych zewnętrznych (Temp, Wilg, Ciśnienie)
          // Zakładam, że InteractiveOutsideChart obsługuje logikę wielu linii
          if (outsideData.isNotEmpty) 
            InteractiveOutsideChart(outsideData: outsideData),
          
          const SizedBox(height: 16),

          // 3. Wykres Pieca
          if (furnaceData.isNotEmpty) 
            InteractiveFurnaceChart(furnaceData: furnaceData),
          
          // Dodatkowy odstęp na dole dla lepszego wyglądu
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Jeśli zdecydowałbyś się użyć lokalnego widżetu zamiast InteractiveOutsideChart,
  // poniżej znajduje się poprawiona metoda budująca legendę i rzędy danych.
  
  Widget _buildLegendSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Wrap( // Wrap jest lepszy niż Row, bo automatycznie przeniesie legendę do nowej linii na małym ekranie
        spacing: 15,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem('Temperatura', Colors.red, Icons.thermostat),
          _buildLegendItem('Wilgotność', Colors.green, Icons.water_drop),
          _buildLegendItem('Ciśnienie (-900hPa)', Colors.purple, Icons.compress),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}