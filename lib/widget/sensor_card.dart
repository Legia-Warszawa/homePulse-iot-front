import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String name;
  final Map<String, dynamic> data;

  const SensorCard({
    super.key,
    required this.name,
    required this.data,
  });

  IconData _getIconForType(String key) {
    final k = key.toLowerCase();
    if (k.contains('temp')) return Icons.thermostat;
    if (k.contains('hum')) return Icons.water_drop;
    if (k.contains('press')) return Icons.speed;
    if (k.contains('light')) return Icons.light_mode;
    if (k.contains('batt') || k.contains('volts')) return Icons.battery_std;
    return Icons.sensors;
  }

  Color _getColorForType(String key, bool isDark) {
    // W Dark Mode kolory muszą być jaśniejsze (pastele/neony)
    final k = key.toLowerCase();
    if (k.contains('temp')) return isDark ? Colors.orangeAccent : Colors.orange;
    if (k.contains('hum')) return isDark ? Colors.lightBlueAccent : Colors.blue;
    if (k.contains('press')) return isDark ? Colors.tealAccent : Colors.teal;
    return isDark ? Colors.grey : Colors.grey.shade700;
  }

  String _getUnit(String key) {
    final k = key.toLowerCase();
    if (k.contains('temp')) return '°C';
    if (k.contains('hum')) return '%';
    if (k.contains('press')) return ' hPa';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedName = name.replaceAll('ESP_', '').replaceAll('_', ' ');

    return Card(
      // Tło karty bierze się z Theme (AppTheme.darkTheme -> cardTheme -> color)
      // Jeśli tu widzisz białe, to znaczy, że Theme nie działa.
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Parametry",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.router, // Można zmienić ikonę w zależności od typu
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const Divider(height: 30),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final entry = data.entries.elementAt(index);
                return _buildValueTile(context, entry.key, entry.value, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile(BuildContext context, String key, dynamic value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // TO BYŁ WINOWAJCA:
        // W Dark Mode dajemy 5% bieli (przezroczyste), co na ciemnym tle wygląda elegancko.
        // W Light Mode dajemy jasnoszary.
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getColorForType(key, isDark).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForType(key),
              size: 20,
              color: _getColorForType(key, isDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$value${_getUnit(key)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}