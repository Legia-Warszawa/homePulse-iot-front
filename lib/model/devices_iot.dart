class EspFurnanceC02 {
  final int id;
  final double temperature;
  final DateTime timestamp;

  EspFurnanceC02({
    required this.id,
    required this.temperature,
    required this.timestamp,
  });

  // Factory constructor do tworzenia z JSON
  factory EspFurnanceC02.fromJson(Map<String, dynamic> json) {
  return EspFurnanceC02(
    id: json['id'] ?? 0,
    temperature: (json['temperature'] ?? 0.0).toDouble(),
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );
}

  // Konwersja do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Gettery do wydzielenia daty i czasu
  String get dateOnly => '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
  
  String get timeOnly => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  
  String get fullDateTime => '${dateOnly} ${timeOnly}';
}

class EspOutside_1 {
  final int id;
  final double temperature;
  final double humidity;
  final double pressure;
  final DateTime timestamp;

  EspOutside_1({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.timestamp,
  });

 
  factory EspOutside_1.fromJson(Map<String, dynamic> json) {
  return EspOutside_1(
    id: json['id'] ?? 0,
    temperature: (json['temperature'] ?? 0.0).toDouble(),
    humidity: (json['humidity'] ?? 0.0).toDouble(),
    pressure: (json['pressure'] ?? 0.0).toDouble(),
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );
}

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Gettery do wydzielenia daty i czasu
  String get dateOnly => '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
  
  String get timeOnly => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  
  String get fullDateTime => '${dateOnly} ${timeOnly}';
}

class EspRoom1 {
  final int id;
  final double temperature;
  final DateTime timestamp;

  EspRoom1({
    required this.id,
    required this.temperature,
    required this.timestamp,
  });

  // Factory constructor do tworzenia z JSON
  factory EspRoom1.fromJson(Map<String, dynamic> json) {
  return EspRoom1(
    id: json['id'] ?? 0,
    temperature: (json['temperature'] ?? 0.0).toDouble(),
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );
}

  // Konwersja do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Gettery do wydzielenia daty i czasu
  String get dateOnly => '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
  
  String get timeOnly => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  
  String get fullDateTime => '${dateOnly} ${timeOnly}';
}