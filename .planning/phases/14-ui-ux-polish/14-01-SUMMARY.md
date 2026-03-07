---
phase: 14-ui-ux-polish
plan: 01
subsystem: localization, formatting, theme
tags: [locale-provider, number-format, umlauts, dark-mode, l10n, shared-preferences]
dependency-graph:
  requires: [ThemeProvider pattern, SharedPreferences, intl package]
  provides: [LocaleProvider, ValtraNumberFormat]
  affects: [app_de.arb, app_en.arb, app_theme.dart, generated l10n files]
tech-stack:
  added: []
  patterns: [ChangeNotifier + SharedPreferences persistence, static utility class with intl NumberFormat/DateFormat]
key-files:
  created:
    - lib/providers/locale_provider.dart
    - lib/services/number_format_service.dart
    - test/providers/locale_provider_test.dart
    - test/services/number_format_service_test.dart
  modified:
    - lib/l10n/app_de.arb
    - lib/l10n/app_en.arb
    - lib/app_theme.dart
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_de.dart
    - lib/l10n/app_localizations_en.dart
decisions:
  - "LocaleProvider uses null locale as default (follow device), with 'de' as fallback for localeString"
  - "ValtraNumberFormat uses intl DateFormat.yMMMM for both date() and monthYear() methods"
  - "German time format uses H:mm (no leading zero) with ' Uhr' suffix; English uses HH:mm (24h with leading zero)"
  - "Date formatting requires initializeDateFormatting() call — tests use setUpAll, app initialization handles this"
metrics:
  duration: "~8 minutes"
  completed: "2026-03-07"
  tasks: 2/2
  tests-added: 52
  total-tests: 759
  analyze-issues: 0
---

# Phase 14 Plan 01: Foundation Utilities Summary

LocaleProvider for in-app DE/EN language toggle with SharedPreferences persistence, ValtraNumberFormat for locale-aware number/time/date formatting using intl package, 16 umlaut fixes in German ARB, 4 new l10n keys, and dark mode onSecondary fix for black text on Lemon Chiffon backgrounds.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | LocaleProvider and ValtraNumberFormat with tests (TDD) | 0d0dec2 | locale_provider.dart, number_format_service.dart, locale_provider_test.dart, number_format_service_test.dart |
| 2 | Fix umlaut encoding, add l10n keys, fix dark mode | c7c09b9 | app_de.arb, app_en.arb, app_theme.dart, generated l10n files |

## What Was Built

### LocaleProvider (lib/providers/locale_provider.dart)
- ChangeNotifier following ThemeProvider pattern
- SharedPreferences key: 'app_locale' (stores 'de' or 'en')
- `Locale? _locale` — null = follow device, defaults to German
- `init()` loads persisted locale, notifies listeners only if saved value found
- `setLocale(Locale)` persists and notifies immediately
- `localeString` getter returns language code or 'de' if null
- `locale` getter for MaterialApp.locale binding

### ValtraNumberFormat (lib/services/number_format_service.dart)
- Static utility class using intl NumberFormat and DateFormat
- `consumption(double, String)` — 1 decimal (DE: "1.234,5", EN: "1,234.5")
- `waterReading(double, String)` — 3 decimals (DE: "12,345", EN: "12.345")
- `currency(double, String)` — 2 decimals (DE: "78,50", EN: "78.50")
- `time(DateTime, String)` — DE: "9:43 Uhr", EN: "09:43"
- `date(DateTime, String)` — DateFormat.yMMMM (DE: "Marz 2026", EN: "March 2026")
- `monthYear(DateTime, String)` — same as date

### Umlaut Fixes in app_de.arb
16 replacements across the German ARB file:
- Aufschluesselung -> Aufschlusselung (x2)
- fuer -> fur (x2), Jaehrlich -> Jahrlich, Zaehlereinstellungen -> Zahlereinstellungen
- Ueber -> Uber, gueltige -> gultige, Grundgebuehr -> Grundgebuhr (x2)
- hinzufuegen -> hinzufugen, Gueltig -> Gultig, Waehrung -> Wahrung
- Geschaetzte -> Geschatzte, Jaehrliche -> Jahrliche, loeschen -> loschen (x2)
- Kostenuebersicht -> Kostenubersicht, geloescht -> geloscht

### New Localization Keys
Both ARB files updated with:
- `monthlyProgress`: DE "Monatsverlauf", EN "Monthly Progress"
- `language`: DE "Sprache", EN "Language"
- `languageDE`: DE "Deutsch", EN "German"
- `languageEN`: DE "Englisch", EN "English"

### Dark Mode Fix (lib/app_theme.dart)
- Changed `onSecondary: AppColors.darkOnSurface` to `onSecondary: Colors.black`
- Ensures readable black text on Lemon Chiffon accent backgrounds in dark mode

## Test Coverage

- **15 locale provider tests**: default state, init with/without saved value, setLocale, persistence across instances, localeString
- **37 number format tests**: consumption (9), waterReading (7), currency (7), time (6), date (4), monthYear (4) — each testing DE and EN locales plus edge cases (zero, negative, large numbers, midnight)
- **Total: 52 new tests, 759 project total, all passing**

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `flutter test test/providers/locale_provider_test.dart test/services/number_format_service_test.dart`: 52/52 passed
- `flutter test`: 759/759 passed
- `flutter analyze`: 0 issues
- Grep for ae/oe/ue in app_de.arb: only legitimate German words remain (keine, neue, Haus, etc.)

## Self-Check: PASSED

All created files exist and all commits verified.
