import 'package:flutter/material.dart';
import 'package:homepulse/servises/history_servis.dart';
import '../model/devices_iot.dart';
import 'dart:async';

class InteractiveHouseMap extends StatefulWidget {
  const InteractiveHouseMap({super.key});

  @override
  State<InteractiveHouseMap> createState() => _InteractiveHouseMapState();
}

class _InteractiveHouseMapState extends State<InteractiveHouseMap> {
  EspRoom1? roomData;
  EspOutside_1? outsideData;
  EspFurnanceC02? furnaceData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);
    try {

      final roomRaw = await HistoryService.getEspPokojHistory(limit: 1);
      final outsideRaw = await HistoryService.getEspZewnatrzHistory(limit: 1);
      final furnaceRaw = await HistoryService.getEspPiecHistory(limit: 1); 

      if (mounted) {
        setState(() {
          if (roomRaw.isNotEmpty) roomData = EspRoom1.fromJson(roomRaw.first);
          if (outsideRaw.isNotEmpty) outsideData = EspOutside_1.fromJson(outsideRaw.first);
          if (furnaceRaw.isNotEmpty) furnaceData = EspFurnanceC02.fromJson(furnaceRaw.first);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Błąd podczas pobierania danych: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Domowy - HomePulse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- KARTA: POKOJ 1 ---
                  _buildDataCard(
                    title: 'Pokój 1',
                    icon: Icons.meeting_room,
                    color: Colors.blue,
                    content: _buildRow('Temperatura', '${roomData?.temperature.toStringAsFixed(1) ?? "--"}°C'),
                    timestamp: roomData?.timeOnly,
                  ),

                  const SizedBox(height: 16),

                  // --- KARTA: NA ZEWNATRZ ---
                  _buildDataCard(
                    title: 'Na zewnątrz',
                    icon: Icons.cloud,
                    color: Colors.green,
                    content: Column(
                      children: [
                        _buildRow('Temperatura', '${outsideData?.temperature.toStringAsFixed(1) ?? "--"}°C'),
                        const Divider(),
                        _buildRow('Wilgotność', '${outsideData?.humidity.toStringAsFixed(1) ?? "--"}%'),
                        const Divider(),
                        _buildRow('Ciśnienie', '${outsideData?.pressure.toStringAsFixed(0) ?? "--"} hPa'),
                      ],
                    ),
                    timestamp: outsideData?.timeOnly,
                  ),

                  const SizedBox(height: 16),

                  // --- KARTA: PIEC / CO2 ---
                  _buildDataCard(
                    title: 'Piec / System grzewczy',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    content: _buildRow('Temp. Pieca', '${furnaceData?.temperature.toStringAsFixed(1) ?? "--"}°C'),
                    timestamp: furnaceData?.timeOnly,
                  ),
                ],
              ),
            ),
    );
  }


  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
    String? timestamp,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (timestamp != null)
                  Text(timestamp, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}