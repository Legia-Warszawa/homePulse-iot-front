import 'package:flutter/material.dart';

/// Pokazuje standardowy dialog wyboru daty, z initialDate (domyślnie teraz)
/// i ograniczeniem max do dzisiaj. Zwraca wybraną datę lub null.
Future<DateTime?> showChartDatePicker(BuildContext context, {DateTime? initialDate}) {
  final DateTime now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? now,
    firstDate: DateTime(2000),
    lastDate: now,
    helpText: 'Wybierz datę',
    selectableDayPredicate: (day) => !day.isAfter(now),
  );
}