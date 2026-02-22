# Baremetal Audio

[![pub package](https://img.shields.io/pub/v/baremetal_audio.svg)](https://pub.dev/packages/baremetal_audio)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A high-performance, lock-free audio DSP architecture for Flutter.
This plugin leverages **C++17** and **Miniaudio** via `dart:ffi` to provide a sample-accurate master clock, real-time FFT analysis, and zero-latency subtitle synchronization.

> **Architectural Note:** This is not a wrapper around system media players (ExoPlayer/AVPlayer). It is a raw audio engine enabling direct pointer arithmetic on audio buffers, designed for visualizations, rhythm games, and precise timing applications.

## Core Architecture

The engine operates on a strict **Hybrid Core Strategy**:

* **Master Logic (C++):** Handles I/O (WASAPI/CoreAudio/AAudio), mixing, FFT processing (Radix-2), and timing.
* **Consumer (Dart):** Renders UI based on shared memory states using `std::atomic` variables.
* **Bridge (FFI):** Zero-copy access to C-heap memory.

## Key Features

* **Sample-Accurate Clock:** Time is derived strictly from processed audio frames (`total_frames / sample_rate`), eliminating drift caused by system timers.
* **Lock-Free State Management:** Uses `std::atomic` for communicating Gain, RMS, and Playhead position between the Audio Thread and UI Thread. Zero mutex contention.
* **Zero-Copy FFT:** The FFT magnitude array is allocated on the C heap and accessed directly by Dart via `ffi.Pointer`, avoiding expensive list copying per frame.
* **Event-Driven Subtitles:** Binary search for subtitle timestamps happens inside the audio callback (Real-time). Dart only receives a signal when the index changes.
* **Dual Mode:** Supports both File Playback and Microphone Capture (Visualizer).

## Installation

Add `baremetal_audio` to your `pubspec.yaml`:

```yaml
dependencies:
  baremetal_audio: ^1.0.0