# Vipassana Timer — Web

A web version of the Vipassana meditation timer: plain HTML/CSS/JS, no
build step, no backend, no dependencies.

## Features

- **Timer** — sitting and walking sessions, 5–90 min, synthesized bell
  (Web Audio API) at start and end.
- **Streaks** — current and longest consecutive-day streaks, total session
  count.
- **Calendar** — monthly view marking practiced days.
- **History** — full session log, delete any entry.
- **Data** — stored locally in the browser (`localStorage`). Export/import
  as JSON from Settings for backup or moving between devices.
- **Installable (PWA)** — has a manifest + service worker, so it can be
  added to a phone or desktop home screen and works offline after the
  first load.

## Apple Health / iHealth

Browsers have no access to Apple Health or HealthKit — that integration
only exists in the native iOS app in `../VipassanaTimer`. This web app is
a fully local, cross-platform alternative (works on any phone/desktop
browser) but does not sync with Health.

## Running it

Any static file server works, e.g.:

```bash
cd VipassanaTimerWeb
python3 -m http.server 8080
```

Then open `http://localhost:8080`. Opening `index.html` directly via
`file://` also works in most browsers, though `localStorage` and the
service worker behave more reliably over `http(s)://`.

## Deploying

Since this repo already hosts a static site, you can publish this folder
the same way (e.g. GitHub Pages) — just point to `VipassanaTimerWeb/index.html`.
