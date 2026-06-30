# Vipassana Timer

A simple SwiftUI iOS app for Vipassana meditation practice.

## Features

- **Timer** — sitting and walking sessions, selectable duration (5–90 min), with a synthesized bell at start and end.
- **Streaks** — current and longest consecutive-day streaks, plus total session count.
- **Calendar** — monthly view marking days you practiced, with a breakdown of sessions per day.
- **History** — full list of past sessions, swipe to delete.
- **Apple Health sync** — completed sessions are saved to Apple Health as Mindful Minutes (`HKCategoryTypeIdentifier.mindfulSession`). Health then shares that data with any other connected app or device, including iHealth, if you've linked it there. Enable this from the Settings tab.

## Requirements

- Xcode 15 or later
- iOS 17.0+ deployment target
- A real Apple ID / development team for HealthKit to work on-device (HealthKit isn't available in the simulator's Health permissions UI in the same way as a device, though it does run in the simulator).

## Getting started

1. Open `VipassanaTimer.xcodeproj` in Xcode.
2. Select the `VipassanaTimer` target and set your own Team under **Signing & Capabilities** (the HealthKit capability is already configured via `VipassanaTimer.entitlements`).
3. Build and run on a simulator or device.

## Project layout

```
VipassanaTimer/
  VipassanaTimerApp.swift        App entry point
  ContentView.swift              Tab bar (Timer / Progress / History / Settings)
  Models/
    MeditationSession.swift      Session model + SessionType (sitting/walking)
    SessionStore.swift           Persistence (JSON in Documents) + streak math
  Services/
    MeditationTimerEngine.swift  Countdown state machine
    BellPlayer.swift             Synthesized bell tone (no audio assets needed)
    HealthKitManager.swift       HealthKit authorization + saving Mindful Minutes
  Views/
    TimerView.swift              Timer screen
    CalendarView.swift           Monthly calendar
    StreakView.swift             Streak stats + embeds CalendarView ("Progress" tab)
    HistoryView.swift            List of past sessions
    SettingsView.swift           Apple Health connection toggle
```

## Notes

- Sessions are stored locally as JSON in the app's Documents directory — no backend required.
- This project was scaffolded outside of Xcode, so do a clean build the first time you open it.
