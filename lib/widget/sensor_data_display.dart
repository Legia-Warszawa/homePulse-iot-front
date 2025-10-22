import 'package:flutter/material.dart';
import 'sensor_card.dart';

class SensorDataDisplay extends StatelessWidget {
  final Map<String, dynamic> sensorData;

  const SensorDataDisplay({
    Key? key,
    required this.sensorData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Dane z czujników:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Wyświetl timestamp
                if (sensorData['timestamp'] != null)
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Ostatnia aktualizacja: ${sensorData['timestamp']}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                // Wyświetl dane z każdego ESP
                ...sensorData.entries
                    .where(
                      (entry) =>
                          entry.key.startsWith('ESP_') &&
                          entry.value != null,
                    )
                    .map(
                      (entry) => SensorCard(
                        name: entry.key,
                        data: Map<String, dynamic>.from(entry.value),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}