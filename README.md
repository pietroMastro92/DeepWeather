# DeepWeather

A minimal macOS menu bar weather app with resilient multi-provider data (Open-Meteo & wttr.in), civil protection meteorological alerts, and pure astronomical calculations. Just the weather, right in your menu bar — no dock icon, no window, no clutter.

![macOS](https://img.shields.io/badge/macOS-14%2B-black) ![iOS](https://img.shields.io/badge/iOS-17%2B-blue)

> An independent **iOS app** (dashboard, widgets, notifications, iPad layout) lives in [`pietroMastro92/DeepWeather-iOS`](https://github.com/pietroMastro92/DeepWeather-iOS). This project is the macOS menu bar app.

## Features

- **Menu bar widget**: SF Symbol condition icon + current temperature
- **Multi-source resilience**: Auto mode with official national meteorological models (ECMWF, DWD, NOAA, Météo-France via Open-Meteo) and automatic failover + anomaly protection
- **Severe Weather & Civil Protection Alerts**: Real-time alerts for extreme heat, intense freeze, gale-force winds, and severe storms with local authority attribution (e.g. Dipartimento della Protezione Civile, NWS, Met Office, DWD)
- **Current conditions**: feels like, humidity, wind, UV index, pressure, visibility, precipitation, cloud cover, sunrise/sunset, moonrise/moonset
- **Temperature chart** (3 days) and **precipitation probability chart**, native Swift Charts, with day separators and a "now" marker
- **Astronomical Moon phases** per day: phase icon, name and illumination calculated via pure Swift astronomical engine
- **Hourly strip** for today with rain chance
- **3-day forecast**: min/max with condition icons
- **Multiple saved locations**: add as many cities as you want, switch between them from a menu right in the panel or manage them in Settings (select / delete)
- **Accurate city search**: type-ahead autocomplete via Open-Meteo geocoding; the app then queries by exact coordinates
- Automatic location (IP-based) or a saved city; saved cities persist across restarts
- Optional launch at login (macOS login item)
- Metric / Imperial units, configurable refresh interval (10–60 min)
- Settings in the panel: choose provider, units, refresh, launch at login, and measurement display
- Native macOS look: dark/light mode, LSUIElement (menu bar only), Universal Binary (Apple Silicon + Intel)

## Installation

1. Download the latest `DeepWeather-<version>.zip` from the [Releases](https://github.com/pietroMastro92/DeepWeather/releases) page.
2. Unzip and drag `DeepWeather.app` into your `Applications` folder.
3. First launch: the app is not notarized, so macOS Gatekeeper will block it. Open it once with:
   - Right-click `DeepWeather.app` → **Open** → **Open**, or
   - Remove the quarantine attribute in Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/DeepWeather.app
     ```
4. The icon with the temperature appears in your menu bar. Click it for the full panel.

## Building from source

Requires Xcode 16+ and [Tuist](https://tuist.dev) (`brew install tuist`).

```bash
git clone https://github.com/pietroMastro92/DeepWeather.git
cd DeepWeather
./run-menubar.sh    # generate project, build and launch
./stop-menubar.sh   # quit the app
```

## Data sources

- Weather data: [Open-Meteo](https://open-meteo.com) (official national meteorological models) & [wttr.in](https://wttr.in)
- Geocoding: [Open-Meteo Geocoding API](https://open-meteo.com) (no API key required)

## License

[MIT](LICENSE)
