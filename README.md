# Valtra

Valtra ist eine App zur Erfassung und Analyse von Energie- und Wasserzählerständen (Strom, Gas, Wasser) über mehrere Haushalte hinweg, inklusive Verbrauchsstatistiken, Interpolation von Messwerten und Visualisierung der Nutzung bis auf Raum- und Geräteebene.

## Features

- **Electricity Tracking**: Main meter readings + smart plug consumption by room
- **Water Tracking**: Multiple meters (cold/hot water, washing machine, etc.)
- **Gas Tracking**: Gas meter readings with optional kWh conversion
- **Heating Meters**: Individual heating consumption meters per room
- **Multi-Household**: Manage meters for multiple properties
- **Analytics**: Monthly/yearly views with interpolation and charts
- **Offline-First**: All data stored locally with Drift/SQLite

## Tech Stack

- Flutter (Dart)
- Drift (SQLite) for local database
- Provider for state management
- fl_chart for visualizations
- LiquidGlass widgets for modern UI

## Design

- **Primary**: Ultra Violet (#5F4A8B)
- **Accent**: Lemon Chiffon (#FEFACD)

## Getting Started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
flutter analyze
```

## License

Private project - All rights reserved
