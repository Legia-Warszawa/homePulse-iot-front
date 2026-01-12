import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
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
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    // Odświeżanie co 30 sekund
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchAllData(quiet: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAllData({bool quiet = false}) async {
    if (!quiet) setState(() => isLoading = true);
    
    try {
      final Map<String, dynamic>? rawData = await ConnectServer.getLatestMessage();

      if (mounted && rawData != null) {
        setState(() {
          // KLUCZE MUSZĄ BYĆ IDENTYCZNE JAK W JSON:
          // ESP_Pokoj_1, ESP_Zewnatrz_1, ESP_Piec_CO_2
          
          if (rawData.containsKey('ESP_Pokoj_1')) {
            roomData = EspRoom1.fromJson(rawData['ESP_Pokoj_1']);
          }
          
          if (rawData.containsKey('ESP_Zewnatrz_1')) {
            outsideData = EspOutside_1.fromJson(rawData['ESP_Zewnatrz_1']);
          }
          
          if (rawData.containsKey('ESP_Piec_CO_2')) {
            furnaceData = EspFurnanceC02.fromJson(rawData['ESP_Piec_CO_2']);
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Błąd parsowania danych: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePulse - Dane na żywo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchAllData(),
          ),
        ],
      ),
      body: isLoading && roomData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDataCard(
                    title: 'Pokój 1',
                    icon: Icons.meeting_room,
                    color: Colors.blue,
                    content: _buildRow('Temperatura', '${roomData?.temperature.toStringAsFixed(1) ?? "--"}°C'),
                    timestamp: roomData?.timeOnly,
                  ),
                  const SizedBox(height: 16),
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
                  _buildDataCard(
                    title: 'Piec CO',
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

  Widget _buildDataCard({required String title, required IconData icon, required Color color, required Widget content, String? timestamp}) {
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
                  Text("Godz: $timestamp", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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