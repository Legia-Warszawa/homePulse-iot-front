# homepulse

A new Flutter project.

## 🌐 API Endpoints

- Base URL: `http://100.105.194.33:8000`
- Latest data: `/items/latest`

# uruchamianie aplikacji bez crud - to działa 
flutter run -d chrome --web-browser-flag "--disable-web-security"
# zwykłe  uruchamianie
flutter run 
# pakiety najnowsza wersja
flutter upgrade
# pakiety instalacja 
flutter pub get    

## 🏗️ Architecture

```
lib/
├── main.dart              # App entry point
├── theme/
│   └── app_theme.dart     # App theming
├── screens/
│   └── starts_screen.dart # Main screen
├── services/
│   └── connect_server.dart # API connection
└── widgets/
    ├── sensor_card.dart
    └── sensor_data_display.dart

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

`
