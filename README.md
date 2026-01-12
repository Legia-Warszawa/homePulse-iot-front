# HomePulse — Flutter IoT Frontend

Krótki, czytelny interfejs web / mobile dla systemu HomePulse — pobiera i wyświetla dane z urządzeń ESP (pokój, na zewnątrz, piec).

## Najważniejsze informacje

- Base API: `http://100.105.194.33:8000`
- Endpoints:
  - Latest: `/items/latest`
  - History (dzień): `/history/esp-pokoj/{date}`, `/history/esp-zewnatrz/{date}`, `/history/esp-piec/{date}`
  - Stats (dzień): `/history/esp-pokoj/stats/{date}`, `/history/esp-zewnatrz/stats/{date}`, `/history/esp-piec/stats/{date}`

## Uruchamianie (lokalnie / web)

- Bezpieczne uruchomienie (domyślne):
  ```bash
  flutter run
  ```
- Uruchomienie web bez polityki CORS (tylko do dewelopmentu lokalnego):
  ```bash
  flutter run -d chrome --web-browser-flag "--disable-web-security"
  ```
  Uwaga: ta flaga wyłącza zabezpieczenia przeglądarki i nie powinna być używana w produkcji.

## Wymagania

- Flutter 3.x / 4.x (zalecane najnowsze stable)
- Połączenie sieciowe z serwerem backend (adres powyżej)

## Struktura projektu (skrót)

- lib/
  - model/ — modele urządzeń (EspRoom1, EspOutside_1, EspFurnanceC02)
  - servises/ — komunikacja z API (connect_server, history_servis, ...)
  - widget/chart/ — wykresy interaktywne
  - screns/ — ekrany aplikacji
  - theme/ — motyw aplikacji

## Development

1. Pobierz zależności:
   ```bash
   flutter pub get
   ```
2. Uruchom aplikację:
   ```bash
   flutter run
   ```
   lub (web, bez CORS podczas developmentu):
   ```bash
   flutter run -d chrome --web-browser-flag "--disable-web-security"
   ```

## Testy / CI

- (Dodaj skrypty testowe i instrukcje CI zgodnie z własnym pipeline)

## Contributing

1. Fork → utwórz branch feature: `git checkout -b feature/nazwa`
2. Commituj zmiany: `git commit -m "Opis zmiany"`
3. Push → otwórz Pull Request

## Kontakt / Uwagi

- Repozytorium: lokalnie w katalogu projektu
- Zgłaszaj błędy przez PR lub issue w trackerze repozytorium
