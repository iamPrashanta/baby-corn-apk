# App Crash & Troubleshooting Guide

This guide explains the common types of app crashes that can occur in a Flutter application (like Baby Corn), why they happen, and how you as a developer can independently track down, debug, and fix them.

## Types of App Crashes

There are three primary categories of crashes in a Flutter/Dart application:

### 1. Dart Runtime Exceptions (Logic Errors)
These are the most common crashes. They occur when the Dart code encounters a logical impossibility or violated constraint while running.
*   **Null Pointer Exceptions (NullReferenceError):** Attempting to access a property or method on a variable that is `null`.
    *   *Example:* `final String name = baby.name;` (if `baby` is null).
*   **RangeError / IndexError:** Attempting to access an item in a list at an index that doesn't exist.
    *   *Example:* `final item = babies[5];` (when the list only has 2 items).
*   **Type Error (TypeError):** Trying to cast or use a variable as a type it is not.
    *   *Example:* `final int age = data['age'] as int;` (when the age is actually a `String`).
*   **StateError:** Calling a method when the object is in an invalid state.
    *   *Example:* Calling `firstWhere()` on an empty list without an `orElse` callback.

### 2. UI / Framework Exceptions (Render Errors)
These don't always "crash" the app entirely, but they paint a terrifying "Red Screen of Death" in debug mode or break the UI in production.
*   **RenderFlex Overflow:** The famous "A RenderFlex overflowed by X pixels" error. This happens when a widget (like a `Column` or `Row`) is too large to fit on the screen.
*   **Build during Build / SetState during Build:** Attempting to update state (`setState()` or Riverpod `ref.read().notifier`) while the widget tree is currently building.
*   **No MaterialLocalizations found:** Trying to use a widget that requires Material Design context (like a `Dialog` or `TextField`) too high up in the widget tree before `MaterialApp` is initialized.

### 3. Native Platform Crashes (Fatal Crashes)
These are the most severe crashes because they bypass Flutter entirely and crash at the iOS/Android operating system level. The app will suddenly close without any Flutter error screen.
*   **Out of Memory (OOM):** The app consumed too much RAM (e.g., loading too many high-resolution images). The OS kills the app to protect the phone.
*   **Missing Platform Permissions:** Attempting to use the camera, microphone, or system overlay without declaring it in `AndroidManifest.xml` or `Info.plist`, or without requesting user permission.
*   **Platform Channel Mismatch:** A Flutter plugin (like Firebase or Hive) tries to call native Swift/Kotlin code, but the native library failed to initialize or wasn't compiled correctly.

---

## How to Check, Debug, and Fix Bugs Yourself

When you encounter an issue, don't panic. Follow these steps to become an elite debugger:

### Step 1: Read the Console / Logs
Your IDE (Android Studio or VS Code) console is your best friend. 
1. Run the app in **Debug Mode** (`flutter run`).
2. Trigger the crash.
3. Look at the console. The stack trace will show exactly what went wrong and *which file and line number* caused it.
    *   *Tip:* Always look for lines in the stack trace that start with `package:baby_corn/...` — those point to *your* code, not Flutter's internal code.

### Step 2: Utilize `flutter analyze`
Before running the app, you can catch hundreds of bugs statically.
*   Open your terminal and run: `flutter analyze`
*   This command scans your entire codebase for unused variables, missing imports, syntax errors, and potential logic flaws. If `flutter analyze` reports "No issues found!", your code is structurally sound.

### Step 3: Check for Missing Imports
If you see errors like `The method 'X' isn't defined for the type 'Y'`, you usually have one of two problems:
1.  **Missing Import:** You haven't imported the file where the method or class is defined. Add `import 'path/to/file.dart';` at the top of your file.
2.  **Outdated Code:** The method was renamed or deleted elsewhere in the app. Use global search (`Ctrl+Shift+F` or `Cmd+Shift+F`) to find where that method is supposed to live.

### Step 4: Use Breakpoints (The Pro Way)
Instead of littering your code with `print()` statements:
1.  Click in the margin next to a line of code in your IDE to place a red dot (a **Breakpoint**).
2.  Run the app in Debug Mode.
3.  When the app reaches that line of code, it will freeze.
4.  You can now hover over variables to see their exact values at that exact moment in time. This is invaluable for tracking down why a variable is unexpectedly `null`.

### Step 5: Clean and Rebuild
Sometimes, the app crashes because of cached or corrupted build files, especially after adding new packages or changing native Android/iOS files.
If the error makes no sense, run these commands:
```bash
flutter clean
flutter pub get
flutter run
```

### Step 6: Fix Hive / Database Errors
If you change a Hive Model (like adding a new field to `BabyModel`), Hive will crash because the cached data format no longer matches the new code format.
*   **The Fix:** You need to increment the `typeId` or clear the app data. For development, the easiest fix is to completely uninstall the app from your emulator/phone and reinstall it.

---

### Summary Checklist When Fixing a Bug:
- [ ] Did I run `flutter analyze`?
- [ ] Did I read the stack trace to find the exact file and line number?
- [ ] Is the variable potentially `null`? Do I need a `?` or a fallback `??` value?
- [ ] Did I import all required packages at the top of the file?
- [ ] If it's a native/plugin error, did I run `flutter clean` and reinstall?
