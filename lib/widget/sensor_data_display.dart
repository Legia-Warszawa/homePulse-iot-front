import 'package:flutter/material.dart';
import 'sensor_card.dart';

class SensorDataDisplay extends StatelessWidget {
  final Map<String, dynamic> sensorData;

  const SensorDataDisplay({
    super.key, // Zmienione na super.key dla nowszych standardów
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Usunąłem nagłówek "Dane z czujników", bo jest redundantny (powtarza się na kartach)
        // Jeśli chcesz go zachować, upewnij się że ma kolor Theme.of(context).colorScheme.onBackground
        
        SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Wyświetl timestamp
                if (sensorData['timestamp'] != null)
                  Container( // Zamiast Card używam Container dla większej kontroli
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // W DarkMode: lekko przezroczysty kolor primary lub surface
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50), // "Pastylka"
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // Dopasuj szerokość do tekstu
                      children: [
                        Icon(
                          Icons.access_time, 
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ostatnia aktualizacja: ${sensorData['timestamp']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                
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