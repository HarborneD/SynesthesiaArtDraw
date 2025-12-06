# Synesthesia Art Draw
A Flutter application that combines drawing with generative music.

## Keyboard Shortcuts

| Key | Action |
| --- | --- |
| **Space** | Play/Pause |
| **M** | Toggle Metronome |
| **S** | Toggle Sustain |
| **ESC** | Close currently open pane |
| **Left/Right Arrows** | Cycle SoundFonts |
| **Up/Down Arrows** | Cycle Instruments (Programs) |
| **+** / **-** | Prev / Next SoundFont (Alternate) |
| **L** | Line Mode |
| **B** | Gradient Mode |
| **E** | Eraser Mode |
| **G** | Toggle grid lines |
| **1-7** | Toggle Scale Degrees |
| **Scroll** | Adjust Tempo |

A windows, mac, android and ios app that offers a canvas for uers to draw whilst hearing their art represented as music. 

The app offers a simple set of drawing tools (compatible with touch or mouse) that allow for creating a colourscape background and vector lines. 

The key of the music is determined by the colours selected. 

The music is ambience and the drone notes are determined by the proportion of each colour in teh background. 

When you draw a vector line, the start determines the start note and the movement of the line determines the melody, with moving upward increasing the pitch and moving downward decreasing the pitch and the length of the line determines the number of notes in the melody.

When drawing starts the midi starts to be generated (thus the canvas acts as a realtime instrument).


For example, if we say that starting the drawing of a line at for MinPixels(default 1 i.e as soon as you touch the canvas it starts) but less than SegmentLength (the vector line distnace since last segment before we trigger a new midi note) distance creates one note at a pitch determined by the starting Y poisition (where the y axis is divided regions corrosponding to relative pitches in the current key), then moving upward and beyond SegmentLength distance, adds a note to this vector lines melody, with the pitch determined by the Y position where the new segment starts. this means lines can, go straight, curve, double back on themselves, etc. and as they get longer and move up and down the y axis, they create more notes in the melody. The midi being output by the line should be recorded and be quantised. SO that after the user stops drawing the line it can be periodically replayed. 

The Y divisions are determined by dividing the Y height by the number of pitches in the key (some degrees can be turned off) and the number of octaves to be included (set in a settings panel) 

The notes are output as midi using https://pub.dev/packages/flutter_midi_command .

This can be listened to by external midi devices or midi apps.

There is an option to listen to the stream within the app, using flutter_midi_command and isntrumenting using sound fonts via https://pub.dev/packages/flutter_midi_pro. 


## Running the App

### macOS
To run the application on macOS, execute the following command in the project root:
```bash
flutter run -d macos
```

### Android
To run the application on an Android device:

1.  **Connect your device**: Ensure your Android device is connected and USB debugging is enabled.
2.  **Find Device ID**: Run the following command to see connected devices:
    ```bash
    flutter devices
    ```
    You will see output similar to:
    ```text
    SM X400 (mobile) • R52YA05JJGB • android-arm64 • Android 15 (API 35)
    ```
    In this example, `R52YA05JJGB` is the device ID.

3.  **Run the App**:
    Use the device ID or `android` if it's the only Android device connected:
    ```bash
    flutter run -d <device_id>
    ```
    *Example:*
    ```bash
    flutter run -d R52YA05JJGB
    ```
    *Or generically:*
    ```bash
    flutter run -d android
    ```
