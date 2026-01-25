# ndr-ffi Integration Guide

This document describes how to build and integrate the ndr-ffi Rust library into the iris-chat-flutter app.

## Prerequisites

### For iOS
- macOS with Xcode installed (with command line tools)
- Rust toolchain with iOS targets:
  ```bash
  rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
  ```

### For Android
- Android NDK installed
- Rust toolchain with Android targets:
  ```bash
  rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
  ```

### Flutter
- Flutter SDK installed
- Dart SDK (comes with Flutter)

## Step 1: Build ndr-ffi Native Libraries

### iOS Build

```bash
cd /path/to/nostr-double-ratchet
./scripts/mobile/build-ios.sh --release
```

This creates:
- `rust/target/ios/NdrFfi.xcframework` - The compiled framework
- `rust/target/ios/bindings/ndr_ffi.swift` - Swift bindings

### Android Build

```bash
cd /path/to/nostr-double-ratchet
./scripts/mobile/build-android.sh --release
```

This creates:
- `rust/target/android/jniLibs/` - Native libraries for each architecture
- `rust/target/android/bindings/ndr_ffi.kt` - Kotlin bindings

## Step 2: Integrate into Flutter Project

### iOS Integration

1. **Add XCFramework to Xcode project:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `NdrFfi.xcframework` into the Runner project
   - Ensure it's added to "Frameworks, Libraries, and Embedded Content"
   - Set "Embed" to "Embed & Sign"

2. **Add Swift bindings:**
   - Copy `ndr_ffi.swift` to `ios/Runner/`
   - Add it to the Runner target in Xcode

3. **Update NdrFfiPlugin.swift:**
   - Uncomment `import NdrFfi` at the top
   - Uncomment all the UniFFI implementation blocks

4. **Register the plugin in AppDelegate.swift:**
   ```swift
   import UIKit
   import Flutter

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
       override func application(
           _ application: UIApplication,
           didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
       ) -> Bool {
           GeneratedPluginRegistrant.register(with: self)

           // Register ndr-ffi plugin
           if let controller = window?.rootViewController as? FlutterViewController {
               NdrFfiPlugin.register(with: controller.registrar(forPlugin: "NdrFfiPlugin")!)
           }

           return super.application(application, didFinishLaunchingWithOptions: launchOptions)
       }
   }
   ```

### Android Integration

1. **Add native libraries:**
   - Copy contents of `jniLibs/` to `android/app/src/main/jniLibs/`
   - Directory structure should be:
     ```
     android/app/src/main/jniLibs/
     ├── arm64-v8a/
     │   └── libndr_ffi.so
     ├── armeabi-v7a/
     │   └── libndr_ffi.so
     ├── x86/
     │   └── libndr_ffi.so
     └── x86_64/
         └── libndr_ffi.so
     ```

2. **Add Kotlin bindings:**
   - Copy `ndr_ffi.kt` to `android/app/src/main/kotlin/to/iris/chat/`
   - Ensure package declaration matches: `package to.iris.chat`

3. **Update NdrFfiPlugin.kt:**
   - Uncomment the UniFFI implementation blocks

4. **Update build.gradle:**
   Add to `android/app/build.gradle`:
   ```gradle
   android {
       // ... existing config ...

       packagingOptions {
           pickFirst '**/libndr_ffi.so'
       }
   }
   ```

5. **Register the plugin in MainActivity.kt:**
   ```kotlin
   package to.iris.chat

   import io.flutter.embedding.android.FlutterActivity
   import io.flutter.embedding.engine.FlutterEngine

   class MainActivity: FlutterActivity() {
       override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
           super.configureFlutterEngine(flutterEngine)
           flutterEngine.plugins.add(NdrFfiPlugin())
       }
   }
   ```

## Step 3: Generate Dart Code

Run the build_runner to generate Freezed and JSON serialization code:

```bash
cd /path/to/iris-chat-flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Step 4: Run the App

### iOS
```bash
flutter run -d ios
```

### Android
```bash
flutter run -d android
```

## Troubleshooting

### iOS: "Framework not found"
- Ensure XCFramework is properly linked in Xcode
- Check that it's embedded (not just linked)

### Android: "UnsatisfiedLinkError"
- Verify native libraries are in the correct jniLibs directories
- Check that the library name matches (`libndr_ffi.so`)
- Ensure NDK ABI filters include your device's architecture

### Dart: "MissingPluginException"
- Ensure the plugin is registered in AppDelegate (iOS) or MainActivity (Android)
- Run `flutter clean && flutter pub get`

### Build errors in native code
- Ensure Rust toolchain is up to date: `rustup update`
- Check that all required targets are installed
- On macOS, ensure Xcode command line tools are selected: `xcode-select --install`

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter (Dart)                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    NdrFfi class                          │    │
│  │  - generateKeypair()                                     │    │
│  │  - createInvite()                                        │    │
│  │  - sessionFromStateJson()                                │    │
│  └─────────────────────┬───────────────────────────────────┘    │
│                        │ Platform Channel                        │
│                        ▼                                         │
├─────────────────────────────────────────────────────────────────┤
│                    Native Layer                                  │
│  ┌──────────────────────┐   ┌──────────────────────┐            │
│  │  NdrFfiPlugin.swift  │   │  NdrFfiPlugin.kt     │            │
│  │  (iOS)               │   │  (Android)           │            │
│  └──────────┬───────────┘   └──────────┬───────────┘            │
│             │ UniFFI                    │ UniFFI                 │
│             ▼                           ▼                        │
│  ┌──────────────────────┐   ┌──────────────────────┐            │
│  │   ndr_ffi.swift      │   │   ndr_ffi.kt         │            │
│  │  (generated)         │   │  (generated)         │            │
│  └──────────┬───────────┘   └──────────┬───────────┘            │
│             │ FFI                       │ JNI                    │
│             ▼                           ▼                        │
├─────────────────────────────────────────────────────────────────┤
│                    Rust (ndr-ffi)                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  - InviteHandle (create, accept, serialize)             │    │
│  │  - SessionHandle (send, receive, encrypt, decrypt)      │    │
│  │  - Double Ratchet protocol implementation               │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Security Notes

- Private keys are stored in platform secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- Session state (containing ratchet keys) is stored encrypted in SQLite
- All message content is end-to-end encrypted using the Double Ratchet protocol
- The native library handles all cryptographic operations in Rust for security
