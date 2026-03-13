---
phase: 23-app-branding-splash
plan: 02
subsystem: ui
tags: [flutter_native_splash, splash-screen, startup, android12, ios, provider]

# Dependency graph
requires:
  - phase: 23-01
    provides: "App icon at assets/icon/icon.png used as splash logo source"
provides:
  - "Native splash screen with Ultra Violet (#5F4A8B) background on Android (pre-12 and 12+) and iOS"
  - "Splash persists from app launch until HouseholdProvider stream fires first event"
  - "removeSplashWhenReady() function in main.dart with @visibleForTesting injection point"
  - "test/main_splash_test.dart with 2 tests covering splash removal lifecycle"
affects:
  - "23-03 and beyond: startup experience established, no empty-screen flicker"

# Tech tracking
tech-stack:
  added:
    - "flutter_native_splash ^2.4.7 (runtime dependency)"
  patterns:
    - "Splash preserve in main() before async work: FlutterNativeSplash.preserve(widgetsBinding)"
    - "Splash remove via HouseholdProvider listener + addPostFrameCallback"
    - "Test: register listener BEFORE pumpWidget to match production flow (pumpWidget drains stream event)"

key-files:
  created:
    - "assets/splash/splash_logo.png"
    - "test/main_splash_test.dart"
    - "android/app/src/main/res/values-v31/styles.xml (Android 12+ splash)"
    - "android/app/src/main/res/values-night-v31/styles.xml (Android 12+ dark splash)"
  modified:
    - "pubspec.yaml (added flutter_native_splash dep + config block)"
    - "pubspec.lock"
    - "lib/main.dart (preserve call + removeSplashWhenReady function)"
    - "android/app/src/main/res/drawable*/launch_background.xml (generated)"
    - "ios/Runner/Assets.xcassets/LaunchImage.imageset/ (generated)"
    - "web/index.html + web/splash/ (generated)"

key-decisions:
  - "Splash logo reuses assets/icon/icon.png (copied to assets/splash/splash_logo.png)"
  - "android_12 block required to prevent white flash on Android 12+ devices"
  - "removeSplashWhenReady waits for first HouseholdProvider notifyListeners after init (stream event), not isInitialized"
  - "Tests register listener BEFORE tester.pumpWidget because pumpWidget drains the Drift stream event queue"
  - "Drift stream cleanup: pumpWidget(Container()) + pump(1s) pattern to clear pending timers in testWidgets"

patterns-established:
  - "Splash test pattern: init provider -> removeSplashWhenReady -> pumpWidget -> pump -> expect"
  - "Production flow: preserve before async -> await inits -> runApp -> removeSplashWhenReady"

# Metrics
duration: 14min
completed: 2026-03-13
---

# Phase 23 Plan 02: Native Splash Screen Summary

**flutter_native_splash with Ultra Violet background persists until HouseholdProvider stream fires first event, eliminating empty-screen flicker on app startup**

## Performance

- **Duration:** 14 min
- **Started:** 2026-03-13T13:56:45Z
- **Completed:** 2026-03-13T14:11:32Z
- **Tasks:** 2
- **Files modified:** ~55 (mostly generated platform splash assets)

## Accomplishments
- Native splash screen generated for Android (pre-12 and 12+), iOS, and Web with Ultra Violet (#5F4A8B) background and centered logo
- Splash lifecycle wired in main.dart: `FlutterNativeSplash.preserve` called before any async init, `removeSplashWhenReady` called after `runApp`
- `removeSplashWhenReady` waits for HouseholdProvider's first stream event (not just `isInitialized`) to ensure no flicker between splash removal and home screen render
- 1079 total tests passing (1077 existing + 2 new splash removal tests)

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure and generate native splash screen** - `049ba5b` (feat)
2. **Task 2: Wire splash preserve/remove lifecycle in main.dart** - `46a7901` (feat)

**Plan metadata:** _(pending final commit)_

## Files Created/Modified
- `assets/splash/splash_logo.png` - Splash logo (copied from assets/icon/icon.png)
- `pubspec.yaml` - Added flutter_native_splash ^2.4.7 dependency + configuration block
- `lib/main.dart` - Added preserve call, removeSplashWhenReady function and invocation
- `test/main_splash_test.dart` - 2 tests for splash removal lifecycle
- `android/app/src/main/res/values-v31/styles.xml` - Android 12+ splash style
- `android/app/src/main/res/drawable*/` - Generated Android splash images (multiple densities)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` - Generated iOS splash images
- `web/index.html` + `web/splash/` - Generated Web splash assets

## Decisions Made

1. **Splash logo = app icon**: Reused `assets/icon/icon.png` as splash logo since a dedicated splash logo doesn't yet exist. Can be updated later when brand assets are finalized.

2. **android_12 block is mandatory**: Without it, Android 12+ devices show a white flash before the Flutter engine loads. The `android_12:` block in pubspec.yaml generates `values-v31/styles.xml` which covers modern Android.

3. **Wait for stream event, not isInitialized**: `isInitialized` is already true when `removeSplashWhenReady` is called (after `await householdProvider.init()`). The meaningful signal is the first DB stream event which confirms the household list has been read. This avoids the empty-state flicker window.

4. **Test listener registration order**: `tester.pumpWidget` in Flutter tests processes pending microtasks including Drift stream events. The listener must be registered BEFORE `pumpWidget` to mirror the production flow (where `removeSplashWhenReady` is called before `runApp` returns and the widget tree builds).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test structure required listener registration before pumpWidget**
- **Found during:** Task 2 (test/main_splash_test.dart)
- **Issue:** Plan specified the test pattern with `removeSplashWhenReady` called AFTER `pumpWidget`. In Flutter's test binding, `pumpWidget` drains the event queue including Drift stream events - this means the stream event fires before the listener is added, and the listener never fires.
- **Fix:** Restructured tests to call `removeSplashWhenReady` BEFORE `pumpWidget`, mirroring the production flow where the listener is registered before `runApp` builds the widget tree.
- **Files modified:** `test/main_splash_test.dart`
- **Verification:** Both tests pass with `flutter test test/main_splash_test.dart`
- **Committed in:** `46a7901` (Task 2 commit)

**2. [Rule 2 - Missing Critical] Added Drift stream cleanup pattern to tests**
- **Found during:** Task 2 (test/main_splash_test.dart)
- **Issue:** Test threw "A Timer is still pending even after the widget tree was disposed" from Drift stream cleanup after `provider.dispose()`.
- **Fix:** Applied the established project pattern: `provider.dispose()` followed by `pumpWidget(Container())` + `pump(Duration(seconds: 1))` to allow pending timers to complete.
- **Files modified:** `test/main_splash_test.dart`
- **Verification:** No pending timer warnings in test output
- **Committed in:** `46a7901` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug in test structure, 1 missing critical test cleanup)
**Impact on plan:** Both auto-fixes required for correct test operation. No scope creep; production code unchanged.

## Issues Encountered

None in production code. Test timing quirks required understanding of Flutter test binding's event loop behavior.

## User Setup Required

None - no external service configuration required. The splash screen assets are generated and committed; no additional setup needed beyond building the app.

## Next Phase Readiness

- Native splash screen complete and configured for Android (pre-12, 12+) and iOS
- App startup experience improved: Ultra Violet background from first frame, no white flash
- Splash persists through the async initialization window (DB open, SharedPreferences, stream)
- Ready to proceed with Phase 23 Plan 03 (if any) or Phase 24 (Bottom Nav Redesign)

---
*Phase: 23-app-branding-splash*
*Completed: 2026-03-13*
