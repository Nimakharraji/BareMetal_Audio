# Baremetal Audio Engine 🚀

A high-performance, **lock-free** audio DSP engine for Flutter, powered by **C++17** and **Miniaudio**.
Designed for real-time visualization, sample-accurate playback, and zero-latency synchronization.

![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-orange.svg)
![Language](https://img.shields.io/badge/backend-C%2B%2B17-green.svg)

## 🔥 Features

* **⚡ Zero-Latency FFI Bridge:** Direct memory access between C++ and Dart (no `MethodChannels`).
* **🎤 Real-time FFT Analysis:** Built-in Fast Fourier Transform (1024 bins) for high-FPS audio visualization.
* **⏱️ Sample-Accurate Clock:** Perfect synchronization for subtitles, lyrics, or rhythm games (drift-free).
* **🛡️ Crash-Proof Architecture:** Persistent singleton design with buffer overflow protection (tested on low-end Android devices).
* **🎛️ Dual Mode:**
    * **Capture Mode:** Low-latency microphone input for visualizers.
    * **Playback Mode:** File playback with auto-resampling (44.1kHz -> 48kHz) and seek support.
* **📉 RMS Metering:** Atomic thread-safe volume level monitoring.

---

## 📸 Demo

<p align="center">
  <img src="screenshots/demo_capture.gif" alt="Microphone Visualizer" width="45%" style="margin-right: 10px;">
</p>

---

## 🛠️ Installation

Add `baremetal_audio` to your `pubspec.yaml`:

```yaml
dependencies:
  baremetal_audio: ^1.0.2
```

### Android Setup
Add microphone permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS Setup
Add this to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to the microphone for real-time audio analysis.</string>
```

---

## 💡 Usage

### 1. Initialize Engine

```dart
import 'package:baremetal_audio/baremetal_audio.dart';

// Mode 1: Microphone Capture
BaremetalAudio.init(mode: EngineMode.capture);

// Mode 2: File Playback
BaremetalAudio.init(mode: EngineMode.playback, filePath: "/path/to/song.mp3");
```

### 2. Real-time Visualization (60 FPS)
Use a Timer to fetch data directly from C++ memory (Zero-Copy):

```dart
Timer.periodic(const Duration(milliseconds: 16), (_) {
  // Get FFT Spectrum (Float32List pointer)
  final ptr = BaremetalAudio.getFftArray();
  if (ptr != nullptr) {
    final spectrum = ptr.asTypedList(512); // Read first 512 bins
    // Draw spectrum...
  }
  
  // Get Volume Level
  final rms = BaremetalAudio.getRmsLevel();
});
```

### 3. Subtitle Synchronization
Load an SRT string and get the current line instantly:

```dart
// Load subtitles
BaremetalAudio.loadSubtitles(srtContent);

// In your loop:
final currentLine = BaremetalAudio.getCurrentSubtitle();
final time = BaremetalAudio.getMediaTime(); // Accurate to 0.001s
```

### 4. Cleanup

```dart
BaremetalAudio.stop();
```

---

## 🧠 How it Works

Unlike standard Flutter audio plugins that rely on platform channels (Java/Obj-C), **Baremetal Audio** runs a native C++ thread using `miniaudio`. It writes FFT and RMS data directly to a shared memory block. Dart reads this memory via `dart:ffi` without any serialization overhead.

* **Backend:** C++17 (Miniaudio)
* **Bridge:** Dart FFI (Foreign Function Interface)
* **Thread Safety:** `std::atomic` for lock-free communication.

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
