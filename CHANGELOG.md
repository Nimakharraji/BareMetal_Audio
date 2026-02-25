## 1.0.3

* **Documentation:** Fixed broken GIF previews on pub.dev by migrating from relative local paths to absolute GitHub raw URLs.

## 1.0.2

* **Documentation:** Added comprehensive DartDoc comments (`///`) to 100% of the public API (classes, methods, and typedefs) to achieve maximum `pub.dev` score.
* **Dependencies:** Updated `flutter_bloc` to `^9.1.1` and `equatable` to `^2.0.8` to support the latest stable versions and resolve dependency constraint penalties.

## 1.0.1

Documentation update: Improved formatting in README.md.
Added detailed instructions for UI/UX integration and exact FFI bridge usage.

## 1.0.0

* Initial release of Baremetal Audio Engine.
* High-performance C++ audio engine using Miniaudio.
* Supported features:
    * Real-time microphone capture (FFT & RMS).
    * Sample-accurate file playback.
    * Zero-latency FFI bridge.
* **Platform Support:** Android (ARM64). iOS coming soon.