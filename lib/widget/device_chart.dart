import 'package:flutter/material.dart';
// Pakiet fl_chart nie jest potrzebny w tym pliku, ale go zostawię dla kontekstu:
import 'package:fl_chart/fl_chart.dart'; 

// Importy Twoich lokalnych widgetów i modeli
import 'package:homepulse/widget/Interactive_furnace_chart.dart';
import 'package:homepulse/widget/Interactive_outside_chart.dart';
import 'package:homepulse/widget/Interactive_room_chart.dart';
import 'package:homepulse/widget/led_control_widget.dart'; // <--- WIDŻET STEROWANIA
import '../model/devices_iot.dart';

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
  
  // Pomocniczy widget do legendy (został w pliku, gdzie jest używany)
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
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          
          // ===========================================
          // 🚀 WIDŻET STEROWANIA LEDAMI
          // ===========================================
          const LedControlWidget(),
          
          const SizedBox(height: 20),

          // Wykres Pokoju 1
          if (roomData.isNotEmpty) InteractiveRoomChart(roomData: roomData),
          const SizedBox(height: 20),

          // Wykres Danych Zewnętrznych
          if (outsideData.isNotEmpty) InteractiveOutsideChart(outsideData: outsideData),
          const SizedBox(height: 20),

          // Wykres Pieca
          if (furnaceData.isNotEmpty) InteractiveFurnaceChart(furnaceData: furnaceData),
          
          // Jeśli masz inne widgety, które używały _buildOutsideChart()
          // ... to te widżety powinny być używane zamiast nich.
        ],
      ),
    );
  }
}