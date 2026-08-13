# 0001. Settings are Glance preferences

## Status

Accepted

## Context

DeepWeather is a menu-bar-only macOS app. Settings already live in the same panel and cover Saved Locations, units, refresh, launch at login, and updates. The next pass could either turn Settings into a larger weather “command center” (alerts, maps, extra tools) or keep it as preferences for the Glance.

## Decision

Settings is only a compact preferences surface for the Glance. New work must serve that glance: where weather comes from, how numbers appear, how often they refresh, and whether the app starts with the Mac. Alerts, maps, widgets, and a full dashboard stay out of this app.

## Consequences

The Settings UI can stay inside the menu-bar panel and stay small. Feature ideas that do not change the glance are rejected. The iOS app remains the place for a richer weather experience.
