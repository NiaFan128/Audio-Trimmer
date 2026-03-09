# Audio Trimmer
<img src="AudioTrimmer/Assets.xcassets/AppIcon.appiconset/Audio Trimmer AppIcon_dark.png" width=120>

An iOS app for managing audio key time points and previewing trim selections, built with SwiftUI and The Composable Architecture (TCA).

Settings | Trimmer
-- | --
<img src="https://github.com/user-attachments/assets/03f67415-0ea2-4727-86e0-b79dbc76f613" height=500> | <img src="https://github.com/user-attachments/assets/dc3f2c02-a94c-4663-bd4d-1f940bd49830" height=500>

## Requirements

- Xcode 16+
- iOS 17+
- Swift 6.0
- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) 1.24.1

## Architecture

The app follows unidirectional data flow using TCA. State mutations happen exclusively through actions dispatched to reducers.

```
AudioTrimmerApp
├── Settings (SettingsFeature)
│   └── [presents] Trimmer (TrimmerFeature)
│
├── Model
│   ├── KeyTimePoint          — Identifiable percentage marker
│   └── AudioClient           — Dependency interface for future audio loading
│
└── Extensions
    └── Double+Rounded        — Precision helper for floating-point state
```

**AudioClient** is defined as a TCA `DependencyKey` with a `liveValue` that throws `notImplemented`. This establishes the interface for future real audio integration without requiring it now.

## Features

### Settings Screen

- Enter total track length in `mm:ss` format with automatic formatting and seconds clamping (≤ 59)
- Add key time points (increments by 10%, capped at 100%)
- Adjust each key time point with a Stepper (±5%), automatically sorted by percentage
- Delete key time points with swipe-to-delete
- Navigate to the Trimmer screen with the selection window pre-centered on the first key time point

### Trimmer Screen

- Key Time Selection view: tappable markers that jump the selection window with easeInOut animation
- Timeline view: draggable selection window over a simulated waveform with smooth transitions
  - Empty `waveformSamples` → SF Symbol tiling fallback
  - Populated `waveformSamples` → real amplitude bar rendering
- Draggable playhead to scrub within the full timeline
- Play/Pause toggle with spring animation and a 0.1-second simulated timer tick
- Reset restores the selection window and playhead to their initial positions
- Displays start time, end time, and current playback time

> Audio playback is simulated. No real audio file is required.

## Testing

Tests are written with **Swift Testing** (`@Suite`, `@Test`, `#expect`) and TCA `TestStore` for exhaustive state assertions.

**SettingsFeature**
- `formatMMSS` / `timeString` format helpers
- Key time add, delete, and update logic with auto-sort by percentage
- `editAudioTapped` selection range centered on first key time, with fallback default
- Unhappy paths: zero total length, duplicate percentages, delete out-of-bounds index

**TrimmerFeature**
- Playback state: play / pause / reset synchronization
- Playback effects: `TestClock` verifies timer lifecycle — tick emission, pause cancellation, reset cancellation, wrap at boundary
- Key time tap, playhead drag, and selection window movement with boundary clamping
- Unhappy paths: zero total length across timerTick, playhead drag, and selection move

**Integration: Settings → Trimmer**
- Operate in trimmer then dismiss — parent state unchanged
- Play in trimmer then dismiss — timer effect cancelled by `.ifLet`

**Decisions**
- Floating-point precision: `Double.rounded(places:)` applied in the reducer keeps state deterministic for exact equality assertions
- Deterministic UUIDs: `@Dependency(\.uuid)` with `.incrementing` produces predictable IDs in tests
- View logic extracted to testable static functions (`timeString`, `formatMMSS`)

## Future Integration

- **Real audio** — implement `AudioClient.liveValue` with AVFoundation to load duration and waveform samples
- **Waveform rendering** — `TrimmerFeature` already accepts `waveformSamples: [Float]`; the view branches on empty vs. populated
- **Persistence** — key time points and track length via `UserDefaults`
