# DeepWeather

A menu-bar glance for current weather on macOS. It is not a dashboard, a full weather studio, or a second weather app.

## Language

**Glance**:
The menu-bar panel: current conditions, charts, hourly, and forecast for one place at a time.
_Avoid_: dashboard, window, home screen

**Settings**:
A compact preferences surface for the Glance: where weather comes from, how numbers are shown, how often they refresh, and whether the app starts with the Mac.
_Avoid_: command center, second weather app, control panel

**Saved Location**:
A user-chosen city stored by name, region, and coordinates. Selecting one makes it the active place for the Glance.
_Avoid_: favorite, pin, place bookmark

**Automatic Location**:
The place inferred from the public IP when no Saved Location is selected.
_Avoid_: GPS, current location, device location

**Measurement**:
One optional cell in the Glance detail grid (feels like, humidity, wind, UV, pressure, visibility, precipitation, cloud cover, sunrise, sunset, moonrise, moonset). Hidden IDs are what we persist; missing ID means the cell is shown.
_Avoid_: metric, widget, stat, tile

**Display**:
The Settings section that chooses which Measurements appear on the Glance. It has two groups: Conditions and Sun & Moon Times.
_Avoid_: appearance, theme, layout editor

**Conditions**:
The Display group of atmospheric Measurements: feels like, humidity, wind, UV, pressure, visibility, precipitation, cloud cover.
_Avoid_: details, stats

**Sun & Moon Times**:
The Display group of astronomy Measurements: sunrise, sunset, moonrise, moonset.
_Avoid_: moon section, astronomy (that name already means the moon-phase row on the Glance)

