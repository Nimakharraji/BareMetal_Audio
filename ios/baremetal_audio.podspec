#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint baremetal_audio.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'baremetal_audio'
  s.version          = '1.0.0'
  s.summary          = 'High-performance lock-free DSP engine.'
  s.description      = <<-DESC
  A sample-accurate, C++17 audio engine using Miniaudio via Dart FFI.
  Supports real-time FFT, Subtitle Sync, and raw buffer access.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Nima Haraji' => 'nima@haraji.dev' }
  
  # This implies the source is local (standard for Flutter plugins)
  s.source           = { :path => '.' }

  # --- SOURCE CONFIGURATION (Single Source of Truth) ---
  # We point CocoaPods to the C++ files residing in the android folder
  # to avoid duplicating code.
  s.source_files = 'Classes/**/*', '../android/src/main/cpp/**/*.{h,cpp,c}'
  s.public_header_files = 'Classes/**/*.h', '../android/src/main/cpp/*.h'

  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # --- C++ COMPILER FLAGS ---
  # 1. Force C++17 Standard
  # 2. Link libc++
  # 3. Suppress warnings from Miniaudio implementation
  s.library = 'c++'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_WARN_INHIBIT_ALL_WARNINGS' => 'YES' 
  }
  
  s.swift_version = '5.0'
end