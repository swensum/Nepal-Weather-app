# Advance Weather 3D — Flutter Weather App

A widget-based, glassmorphic "3D" weather app. Every section of the home
page (current conditions header, hourly strip, 7-day forecast, metrics
grid, sunrise/sunset arc, air quality) is its **own standalone widget**,
so you can drop them onto any screen, reorder them, or reuse the
`CurrentWeatherHeader` alone as a compact header elsewhere in your app.

Weather data comes from **[Open-Meteo](https://open-meteo.com)** —
free, no API key, no signup. Current conditions, 48h hourly forecast,
7-day daily forecast, UV index, wind, pressure, visibility, cloud
cover, sunrise/sunset, and full air quality (US & European AQI,
PM2.5, PM10, ozone, NO₂, SO₂, CO) are all included.

## 1. Get it running

```bash
flutter create --project-name weather_app_3d --overwrite .
# ^ only needed if you want Flutter to (re)generate the android/ ios/
#   platform folders; skip if you already have a Flutter project shell.

flutter pub get
flutter run
```

If you generated fresh `android/` and `ios/` folders, add the
permissions below (also saved as snippet files in this project):

- **Android**: copy the 3 lines from `android_permissions_snippet/AndroidManifest_additions.xml`
  into `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`, above `<application>`).
- **iOS**: copy the 2 keys from `ios_permissions_snippet/Info_plist_additions.xml`
  into `ios/Runner/Info.plist`.

The app will ask for location permission on first launch. If denied,
it automatically falls back to a default city (Kathmandu) so it's
never blank — you can change that fallback in
`lib/screens/home_screen.dart` → `_loadByDeviceLocation()`.

## 2. Project structure

```
lib/
  main.dart                        # App entry point
  theme/app_theme.dart             # Colors, gradients, typography (single source of truth)
  models/
    weather_model.dart             # CurrentWeather, HourlyWeather, DailyWeather, WeatherCode
    air_quality_model.dart         # AirQualityData
  services/
    weather_service.dart           # Open-Meteo forecast + air quality + geocoding calls
    location_service.dart          # Device GPS via geolocator
  widgets/                         # <-- the reusable "home page widgets"
    glass_card_3d.dart             # Core 3D glass panel + Floating3DIcon
    weather_icon.dart              # Weather-code -> icon/color mapping
    current_weather_header.dart    # Big hero header (city, temp, condition)
    hourly_forecast_widget.dart    # Horizontal scrolling 24h strip
    daily_forecast_widget.dart     # 7-day list with high/low range bars
    weather_metrics_grid.dart      # Wind / humidity / UV / pressure / visibility / etc.
    air_quality_card.dart          # AQI gauge + pollutant breakdown
    sun_arc_card.dart              # Custom-painted sunrise→sunset arc
    city_search_sheet.dart         # Search-and-pick-a-city bottom sheet
  screens/
    home_screen.dart               # Assembles all the widgets above
```

## 3. The "3D" design system

- **`GlassCard3D`** (`lib/widgets/glass_card_3d.dart`) is the single
  building block every card uses: frosted blur, soft ambient shadow +
  tight contact shadow, a light gradient edge, and an interactive
  perspective tilt that responds to drag gestures (`Matrix4` with a
  perspective entry). Set `interactive3D: false` on cards where you
  don't want the tilt (e.g. scrollable lists).
- **`Floating3DIcon`** slowly bobs and rotates the big hero weather
  icon on a sine wave for a subtle "floating" feel.
- **`AppTheme.skyGradient()`** picks a background gradient based on
  time-of-day (`is_day`) and current WMO weather code (clear / cloudy
  / rain / snow / storm), so the whole screen's mood shifts with the
  weather.

## 4. Using it as a "homepage header" elsewhere

Any widget here can be dropped directly into another screen:

```dart
import 'widgets/current_weather_header.dart';

// inside some other screen's build():
CurrentWeatherHeader(weather: myWeatherData),
```

Same for `HourlyForecastWidget`, `WeatherMetricsGrid`, etc. — each
only needs the relevant slice of `WeatherData` / `AirQualityData`.

## 5. Customizing / extending

- **Units**: `WeatherService.fetchWeather()` takes `tempUnit`
  (`celsius`/`fahrenheit`) and `windUnit` (`kmh`/`mph`/`ms`/`kn`) —
  wire these to a settings screen if you want a unit toggle.
- **More data**: Open-Meteo exposes many more `hourly`/`daily`
  variables (dew point, soil temperature, snow depth, CAPE, etc.) —
  just add the field name to the relevant list in
  `weather_service.dart` and to the parsing in `weather_model.dart`.
- **Switching providers**: only `weather_service.dart` talks to the
  network. Point it at OpenWeatherMap/WeatherAPI/Tomorrow.io instead
  and adjust the JSON parsing in the two model files — no widget
  changes needed.
- **Charts**: `fl_chart` is already in `pubspec.yaml` if you want to
  add a temperature line graph across the hourly/daily data.
- **Persistence**: `shared_preferences` is included for saving the
  user's last city / preferred units between launches.
- **True OS home-screen widgets** (the little widget you can pin to
  your phone's home screen, separate from the app itself) require a
  platform-specific integration — on Android via Glance/AppWidget and
  on iOS via WidgetKit — typically wired up through a package like
  `home_widget`. The in-app "widgets" here are the modular Flutter
  building blocks; add `home_widget` if you also want a literal
  pinnable OS widget showing e.g. `CurrentWeatherHeader`'s data.

## 6. Notes

- No API key management needed anywhere — Open-Meteo's endpoints used
  here are free for non-commercial and most commercial use at
  reasonable volume; check their site for heavy production use.
- All network calls are plain `http` GETs returning JSON — easy to
  swap for `dio` if you want interceptors/caching later.
