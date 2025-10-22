import 'package:flutter/material.dart';
import 'package:homepulse/servises/connect_server.dart';
import '../widget/sensor_data_display.dart';

class StartsScreen extends StatefulWidget {
  const StartsScreen({super.key});

  @override
  State<StartsScreen> createState() => _StartsScreenState();
}

class _StartsScreenState extends State<StartsScreen> {
  String connectionStatus = 'Nie sprawdzono';
  bool isLoading = false;
  Map<String, dynamic>? sensorData;

  Future<void> testServerConnection() async {
    setState(() {
      isLoading = true;
      connectionStatus = 'Sprawdzanie...';
      sensorData = null;
    });

    var message = await ConnectServer.getLatestMessage();

    setState(() {
      if (message != null) {
        connectionStatus = 'Połączenie OK!';
        sensorData = message;
      } else {
        connectionStatus = 'Brak połączenia z serwerem';
        sensorData = null;
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Home Pulse')),
        leading: IconButton(
          onPressed: isLoading ? null : testServerConnection,
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.refresh),
          iconSize: 28,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Welcome to the Home Pulse!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: connectionStatus.contains('OK')
                      ? Colors.green
                      : connectionStatus.contains('Brak')
                          ? Colors.red
                          : theme.colorScheme.secondary,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    connectionStatus.contains('OK')
                        ? Icons.check_circle
                        : connectionStatus.contains('Brak')
                            ? Icons.error
                            : Icons.info,
                    color: connectionStatus.contains('OK')
                        ? Colors.green
                        : connectionStatus.contains('Brak')
                            ? Colors.red
                            : theme.colorScheme.secondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Status: $connectionStatus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: connectionStatus.contains('OK')
                          ? Colors.green
                          : connectionStatus.contains('Brak')
                              ? Colors.red
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (sensorData != null)
              Expanded(
                child: SensorDataDisplay(sensorData: sensorData!),
              )
            else if (connectionStatus != 'Nie sprawdzono' &&
                connectionStatus != 'Sprawdzanie...')
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sensors_off,
                        size: 64,
                        color: theme.colorScheme.secondary.withOpacity(0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Brak danych do wyświetlenia',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}