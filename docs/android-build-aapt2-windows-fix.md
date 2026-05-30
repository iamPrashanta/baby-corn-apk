# 🛠️ Android Build Fix: AAPT2 Daemon Startup Crash on Windows (AGP 8.11.1 + SDK 36)

> **Status:** Resolved  
> **Platform:** Windows (all versions)  
> **Flutter Version:** 3.x  
> **Android Gradle Plugin:** 8.11.1 (broken) → 8.7.3 (fixed)  
> **Date Encountered:** May 2025  

---

## 🔴 The Error

When running `flutter build apk` or `flutter build apk --release` on **Windows**, the build fails deep inside the Gradle task `:cloud_firestore:verifyReleaseResources` (or similar AAR metadata tasks) with this message:

```
FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':cloud_firestore:verifyReleaseResources'.
> A failure occurred while executing com.android.build.gradle.tasks.VerifyLibraryResourcesTask$Action
   > There was a failure while executing work items
      > A failure occurred while executing com.android.build.gradle.internal.res.Aapt2CompileRunnable
         > AAPT2 aapt2-8.11.1-12782657-windows Daemon #0: Daemon startup failed
           Please check if you installed the Windows Universal C Runtime.
           This should not happen under normal circumstances, please file an issue if it does.
```

The key line is:

```
AAPT2 aapt2-8.11.1-12782657-windows Daemon #0: Daemon startup failed
Please check if you installed the Windows Universal C Runtime.
```

---

## 🤔 What Is AAPT2 and Why Does It Matter?

**AAPT2** (Android Asset Packaging Tool 2) is the tool that compiles and packages your app's resources (layouts, drawables, strings, manifests) into the binary format that Android understands. Without it, your APK or AAB cannot be built.

AAPT2 is bundled **directly inside** the Android Gradle Plugin (AGP) as a platform-specific native binary. On Windows, this binary is a `.exe` file like:

```
aapt2-8.11.1-12782657-windows.exe
```

This binary is downloaded automatically from Maven when Gradle resolves your build dependencies — you never install it manually. This means:

> **If the AAPT2 binary inside a specific AGP version is broken or not properly compiled for Windows, every single Windows developer using that AGP version will hit this crash.**

---

## 🧩 Why compileSdk 36 Is Involved

### The Plugin Version Chain Reaction

Modern Flutter plugins (like `connectivity_plus`, `google_sign_in_android`, `image_picker_android`, etc.) continuously update their own `compileSdk` in line with the latest Android SDK. As of mid-2025, many commonly used plugins bumped their requirement to **SDK 36** (Android 16 Preview).

When your app's `compileSdk` is set **lower** than what a plugin requires, Gradle refuses to build and shows:

```
Your project is configured to compile against Android SDK 35, but the following plugin(s)
require to be compiled against a higher Android SDK version:
- connectivity_plus compiles against Android SDK 36
- file_picker compiles against Android SDK 36
...
Fix this issue by compiling against the highest Android SDK version (they are backward compatible).
```

So you are **forced** to set `compileSdk = 36`. You cannot avoid it if you use these plugins.

### The Trap: Two Errors That Seem Contradictory

This creates a frustrating loop on Windows:

| Action | Result |
|---|---|
| Set `compileSdk = 35` | ❌ Build fails — plugins demand SDK 36 |
| Set `compileSdk = 36` | ❌ Build fails — AAPT2 daemon crashes on Windows |

It looks like there is no solution. But the real culprit is **not the SDK version** — it is the **AGP version**.

---

## 🔬 Root Cause: AGP 8.11.1 Has a Broken AAPT2 on Windows

Android Gradle Plugin **8.11.1** (released early 2025) ships an AAPT2 binary that was incorrectly compiled or linked for Windows. When this binary tries to start its internal JVM daemon to compile resources, it crashes immediately.

The error message `"Please check if you installed the Windows Universal C Runtime"` is misleading. The Visual C++ Runtime (UCRT) is almost certainly already installed on any modern Windows machine. The actual problem is that AGP 8.11.1's AAPT2 binary has an internal linkage or startup issue specific to Windows.

This is **not a user error**. It is a bug in the AGP 8.11.1 release.

---

## ✅ The Fix: Pin to AGP 8.7.3 (Stable)

The solution is to **keep `compileSdk = 36`** (as required by plugins) but **downgrade AGP from 8.11.1 to 8.7.3** — the latest stable release with a properly compiled AAPT2 binary for Windows.

AGP 8.7.3 fully supports `compileSdk = 36` and all modern AndroidX dependencies, so nothing breaks.

### Version Compatibility Table

Every AGP version has a specific required Gradle version and tested Kotlin version. Mixing them causes separate build failures. Here are the correct combinations:

| Android Gradle Plugin | Minimum Gradle | Recommended Kotlin |
|---|---|---|
| 8.7.x | 8.9 | 2.1.x |
| 8.8.x | 8.10 | 2.1.x |
| 8.11.x | 8.14 | 2.2.x |

So when you move from AGP 8.11.1 to 8.7.3, you **must also** adjust Gradle and Kotlin accordingly.

---

## 📁 Files to Change

There are exactly **three files** to modify. None of them are in your Flutter/Dart code.

---

### 1. `android/settings.gradle.kts`

This is where the AGP and Kotlin versions are declared.

**Before (broken):**
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false   // ❌ AAPT2 crashes on Windows
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
```

**After (fixed):**
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false    // ✅ Stable, working AAPT2
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false  // ✅ Compatible with AGP 8.7.x
}
```

---

### 2. `android/gradle/wrapper/gradle-wrapper.properties`

This file controls which Gradle version is downloaded to run your build.

**Before (broken):**
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.1-all.zip
```

**After (fixed):**
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-all.zip
```

> **Why 8.11.1 for Gradle?** AGP 8.7.3 requires a minimum of Gradle 8.9, and works well up to 8.11.1. Gradle 8.14.1 is paired with AGP 8.11.x and above — using it with AGP 8.7.3 can cause compatibility warnings or failures.

---

### 3. `android/app/build.gradle.kts`

Keep `compileSdk = 36` and `targetSdk = 36`. Do **not** change these.

```kotlin
android {
    compileSdk = 36   // ✅ Keep — plugins require this

    defaultConfig {
        targetSdk = 36   // ✅ Keep — plugins require this
        minSdk = 24
        ...
    }
}
```

---

## 🔍 How to Diagnose This Issue Yourself

If you encounter a build failure and want to determine if this is your problem, look for these specific signals:

### Signal 1 — AAPT2 Daemon in the error message
```
AAPT2 aapt2-X.X.X-XXXXXXXX-windows Daemon #N: Daemon startup failed
```
The `windows` in the binary name confirms this is a Windows-specific crash.

### Signal 2 — It mentions "Windows Universal C Runtime"
```
Please check if you installed the Windows Universal C Runtime.
```
This is always misleading. UCRT is installed by default on Windows 10+. The problem is the binary itself.

### Signal 3 — Only fails on release builds, not debug
AAPT2 resource shrinking and optimization runs more aggressively on release builds. If `flutter run` works fine but `flutter build apk --release` fails, AAPT2 is the prime suspect.

### Signal 4 — The AGP version contains the issue
Check your `android/settings.gradle.kts`. If `com.android.application` is set to `8.11.x`, this is the known broken version on Windows.

### Signal 5 — Conflicting SDK errors
If lowering `compileSdk` to 35 produces errors like:
```
Your project is configured to compile against Android SDK 35, but the following plugin(s) 
require to be compiled against a higher Android SDK version...
```
...then you are caught in the exact trap described in this document.

---

## 🚀 Step-by-Step Fix Checklist

```
[ ] 1. Open android/settings.gradle.kts
        Change AGP: "8.11.1" → "8.7.3"
        Change Kotlin: "2.2.20" → "2.1.20"

[ ] 2. Open android/gradle/wrapper/gradle-wrapper.properties
        Change Gradle URL: gradle-8.14.1-all.zip → gradle-8.11.1-all.zip

[ ] 3. Open android/app/build.gradle.kts
        Ensure compileSdk = 36  (do NOT lower this)
        Ensure targetSdk = 36   (do NOT lower this)

[ ] 4. Run: flutter clean

[ ] 5. Run: flutter build apk --release
```

---

## 📊 Summary of All Changes

| Component | Broken Value | Fixed Value | Why |
|---|---|---|---|
| `compileSdk` | 36 | **36** (unchanged) | Plugins require SDK 36 |
| `targetSdk` | 36 | **36** (unchanged) | Plugins require SDK 36 |
| Android Gradle Plugin | `8.11.1` | **`8.7.3`** | AGP 8.11.1 ships broken AAPT2 on Windows |
| Kotlin Gradle Plugin | `2.2.20` | **`2.1.20`** | Must be compatible with AGP 8.7.x |
| Gradle | `8.14.1` | **`8.11.1`** | Must be compatible with AGP 8.7.x |

---

## 🧠 Key Concepts Explained

### What is AGP (Android Gradle Plugin)?
AGP is a Gradle plugin maintained by Google that knows how to take your Android project and produce an APK or AAB. It manages the entire Android build pipeline — resource compilation (AAPT2), DEX compilation, manifest merging, signing, and packaging. It is distinct from Gradle itself.

### What is Gradle?
Gradle is the build system (the engine). AGP is a plugin that runs inside Gradle. Think of Gradle as a car engine and AGP as the driver who knows how to build Android apps with it.

### Why do these versions have to match?
Each AGP version is developed and tested against a specific range of Gradle versions. AGP 8.11.x expects Gradle 8.14.x's APIs to be present. If you use AGP 8.7.x with Gradle 8.14.x, some internal APIs may have changed or been removed, causing failures. Always use compatible pairs.

### What is compileSdk vs targetSdk vs minSdk?
| Setting | Meaning |
|---|---|
| `minSdk` | Minimum Android version your app can *install* on |
| `compileSdk` | Android SDK version used to *compile* your app code |
| `targetSdk` | Android version your app is *designed and tested* for |

`compileSdk` and `targetSdk` can be set independently. This is why the Flutter team says "you can update `compileSdk` without changing `targetSdk`" — but in practice, modern libraries often require both to match.

---

## 🔗 Related Resources

- [AGP Release Notes](https://developer.android.com/build/releases/gradle-plugin)
- [AGP / Gradle Compatibility Matrix](https://developer.android.com/build/releases/gradle-plugin#updating-gradle)
- [Flutter Android Build Docs](https://docs.flutter.dev/deployment/android)
- [Migrate to Built-in Kotlin Guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)

---

*This document was written based on a real production build failure encountered in May 2025 while building a Flutter application on Windows with AGP 8.11.1.*
