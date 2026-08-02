# DeepWeather

A minimal macOS menu bar weather app powered by [wttr.in](https://github.com/chubin/wttr.in). Just the weather, right in your menu bar — no dock icon, no window, no clutter.

![macOS](https://img.shields.io/badge/macOS-14%2B-black)

## Features

- **Menu bar widget**: SF Symbol condition icon + current temperature
- **Current conditions**: feels like, humidity, wind, UV index, pressure, visibility, precipitation, cloud cover, sunrise/sunset, moonrise/moonset
- **Temperature chart** (3 days) and **precipitation probability chart**, native Swift Charts, with day separators and a "now" marker
- **Moon phases** per day: phase icon, name and illumination
- **Hourly strip** for today with rain chance
- **3-day forecast**: min/max with condition icons
- **Accurate city search**: type-ahead autocomplete via Open-Meteo geocoding (region/country shown to disambiguate homonyms); the app then queries wttr.in by exact coordinates — no more wrong fuzzy matches like "Potenza → Abriola"
- Automatic location (IP-based) or a saved city
- Metric / Imperial units, configurable refresh interval (10–60 min)
- Native macOS look: dark/light mode, Liquid Glass on macOS 26, LSUIElement (menu bar only)

## Installation

1. Download the latest `DeepWeather-<version>.zip` from the [Releases](https://github.com/pietroMastro92/DeepWeather/releases) page.
2. Unzip and drag `DeepWeather.app` into your `Applications` folder.
3. First launch: the app is not notarized (no paid Apple Developer account), so macOS Gatekeeper will block it. Open it once with:
   - Right-click `DeepWeather.app` → **Open** → **Open**, or
   - Remove the quarantine attribute in Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/DeepWeather.app
     ```
4. The icon with the temperature appears in your menu bar. Click it for the full panel.

## Building from source

Requires Xcode 26+ and [Tuist](https://tuist.dev) (`brew install tuist`).

```bash
git clone https://github.com/pietroMastro92/DeepWeather.git
cd DeepWeather
./run-menubar.sh    # generate project, build and launch
./stop-menubar.sh   # quit the app
```

## Data sources

- Weather data: [wttr.in](https://wttr.in) (WorldWeatherOnline data, `format=j1`)
- Geocoding: [Open-Meteo Geocoding API](https://open-meteo.com) (no API key required)

## License

[MIT](LICENSE)
