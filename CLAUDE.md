# Project Context: Audio Trimmer (TCA)

## App Structure
- **Two screens**: Settings screen and Audio Trimmer screen.
- **Navigation**: Settings screen has an "Edit Audio" button that navigates to the Audio Trimmer screen.

### Settings Screen
- TextField to input total track length (e.g., 02:30 in mm:ss format)
- KeyTime Points section: display existing points as percentages, with a "+" button to dynamically add more
- Timeline length as % of total track (optional)

### Audio Trimmer Screen
Two main components stacked vertically:

**KeyTime Selection View** (top):
- Displays tappable key time points sourced from Settings
- Shows current trim range as % of total track length
- Syncs with the Music Timeline (jumping the waveform to the selected position when tapped)
- Displays current play time as % of total track length

**Music Timeline View** (bottom):
- Waveform visualisation with a draggable Selection Overlay (trim handles)
- Gesture interactions for scrubbing and adjusting the trim range
- UI animation and transitions (focus mode when interacting with the waveform)
- Play/Pause the currently selected audio segment (simulated, no real audio required)
- Reset play time to the start of the selection
- Display selected start and end times of the audio segment
- Display and track current play time progress

## Architecture Guidelines
- **Framework**: SwiftUI + The Composable Architecture (TCA).
- **TCA Version**: Use the latest Reducer protocol and @ObservableState macro.
- **State Management**: Keep state as simple as possible. Use IdentifiedArray for KeyTime point collections.
- **Naming**: Actions should be descriptive (e.g., `playButtonTapped`, `keyTimePointTapped`, `trimHandleDragged`).

## Coding Standards
- **Swift Version**: Swift 6.0 (strict concurrency where applicable).
- **UI**: SwiftUI-first. Avoid unnecessary third-party libraries; TCA is the approved exception.
- **Responsive**: All views must work on all screen sizes. Use GeometryReader for proportional layouts.
- **Animation**: Use spring animations for gesture interactions and state transitions (trim handle drag, key time tap, play/pause toggle).

## Development Constraints
- Prioritize core logic (Timer, Gesture, State Sync) over visual polish.
- Audio is simulated — do not implement real audio playback unless explicitly requested.
- If logic becomes too complex, propose a simplified version before implementing.
