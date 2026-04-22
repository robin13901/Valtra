# Valtra Design System v2.0 — "Aurora Bento"

## Design Philosophy

**Style: Aurora Bento** — A fusion of Apple-style Bento Grid layouts with subtle Aurora gradient accents and Soft UI Evolution components.

**Inspiration:** Linear, Revolut, Arc Browser, Apple Weather
**Keyword:** Premium utility — functional beauty, data-first, effortlessly modern.

**Core Principles:**
1. **Data First** — Information hierarchy drives every layout decision
2. **Quiet Confidence** — Premium without being flashy; let the content breathe
3. **Alive but Calm** — Subtle gradients and motion give life without distraction
4. **Consistent Rhythm** — Every element follows the 4px grid

---

## 1. Color System

### 1.1 Brand Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `primary` | `#1B6EF3` | `#4A91FF` | Primary actions, active states, links |
| `primaryContainer` | `#E8F0FE` | `#1A2B4A` | Primary tinted surfaces |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text on primary |
| `secondary` | `#6366F1` | `#818CF8` | Secondary actions, accents |
| `secondaryContainer` | `#EEF2FF` | `#1E1B4B` | Secondary tinted surfaces |

### 1.2 Semantic / Category Colors

| Token | Hex | Usage | Light Container | Dark Container |
|-------|-----|-------|-----------------|----------------|
| `electricity` | `#F59E0B` | Electricity meters | `#FEF3C7` | `#422006` |
| `gas` | `#F97316` | Gas meters | `#FFF7ED` | `#431407` |
| `water` | `#06B6D4` | Water meters | `#ECFEFF` | `#083344` |
| `heating` | `#EF4444` | Heating meters | `#FEF2F2` | `#450A0A` |
| `smartPlug` | `#8B5CF6` | Smart plugs | `#F5F3FF` | `#2E1065` |

### 1.3 Neutral Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `background` | `#F8FAFC` | `#0C0F14` | App background |
| `surface` | `#FFFFFF` | `#161B22` | Cards, sheets |
| `surfaceVariant` | `#F1F5F9` | `#1C2432` | Elevated surfaces, inputs |
| `surfaceTertiary` | `#E2E8F0` | `#243044` | Tertiary surfaces |
| `border` | `#E2E8F0` | `#2D3748` | Card borders, dividers |
| `borderSubtle` | `#F1F5F9` | `#1E293B` | Subtle separators |

### 1.4 Text Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `textPrimary` | `#0F172A` | `#F1F5F9` | Headlines, body text |
| `textSecondary` | `#475569` | `#94A3B8` | Secondary info, labels |
| `textTertiary` | `#94A3B8` | `#64748B` | Hints, placeholders |
| `textOnColor` | `#FFFFFF` | `#FFFFFF` | Text on colored backgrounds |

### 1.5 Feedback Colors

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `success` | `#10B981` | `#34D399` | Positive changes, savings |
| `warning` | `#F59E0B` | `#FBBF24` | Caution states |
| `error` | `#EF4444` | `#F87171` | Errors, deletion |
| `info` | `#3B82F6` | `#60A5FA` | Informational |

### 1.6 Aurora Gradient Tokens

```
auroraGradient1: LinearGradient(
  colors: [#1B6EF3, #6366F1, #8B5CF6],  // Blue → Indigo → Violet
  begin: topLeft, end: bottomRight
)

auroraGradient2: LinearGradient(
  colors: [#06B6D4, #1B6EF3, #6366F1],  // Cyan → Blue → Indigo
  begin: topCenter, end: bottomRight
)

auroraGradientSubtle: LinearGradient(
  colors: [background, primaryContainer.withOpacity(0.3), background],
  begin: topCenter, end: bottomCenter
)
```

**Usage:** Aurora gradients are used ONLY for:
- Home screen hero/header area (subtle, behind content)
- Empty state illustrations
- Onboarding screens
- NOT for cards, buttons, or everyday UI

---

## 2. Typography

### 2.1 Font: Plus Jakarta Sans

**Why:** Friendly yet professional. Geometric character with warm personality. Excellent number rendering (critical for a meter-reading app). Supports Latin extended (DE/EN). Free on Google Fonts.

**Flutter:** `google_fonts: ^6.0.0` → `GoogleFonts.plusJakartaSans()`

### 2.2 Type Scale (4px grid aligned)

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `displayLarge` | 32px | 700 (Bold) | 40px | -0.5px | Hero numbers (total consumption) |
| `displayMedium` | 28px | 700 (Bold) | 36px | -0.3px | Screen titles |
| `headlineLarge` | 24px | 600 (SemiBold) | 32px | -0.2px | Section headers |
| `headlineMedium` | 20px | 600 (SemiBold) | 28px | 0px | Card titles |
| `titleLarge` | 18px | 600 (SemiBold) | 24px | 0px | Subsections |
| `titleMedium` | 16px | 500 (Medium) | 24px | 0.1px | List item titles |
| `bodyLarge` | 16px | 400 (Regular) | 24px | 0.1px | Primary body text |
| `bodyMedium` | 14px | 400 (Regular) | 20px | 0.15px | Secondary body text |
| `bodySmall` | 12px | 400 (Regular) | 16px | 0.2px | Captions, timestamps |
| `labelLarge` | 14px | 600 (SemiBold) | 20px | 0.1px | Buttons, tabs |
| `labelMedium` | 12px | 500 (Medium) | 16px | 0.3px | Badges, small labels |
| `labelSmall` | 10px | 500 (Medium) | 14px | 0.4px | Overline, micro labels |

### 2.3 Number Display

For meter readings and consumption values, use **tabular figures** (monospaced numbers):
```dart
GoogleFonts.plusJakartaSans(
  fontFeatures: [FontFeature.tabularFigures()],
)
```

---

## 3. Spacing & Grid

### 3.1 Base Unit: 4px

All spacing is a multiple of 4px.

| Token | Value | Usage |
|-------|-------|-------|
| `space2` | 2px | Micro spacing (icon-to-text inline) |
| `space4` | 4px | Tight spacing |
| `space8` | 8px | Small gaps (between chips, small padding) |
| `space12` | 12px | Medium-small (card internal gaps) |
| `space16` | 16px | Standard padding, gap between elements |
| `space20` | 20px | Section padding |
| `space24` | 24px | Large gaps, section breaks |
| `space32` | 32px | Major section separation |
| `space48` | 48px | Screen-level vertical rhythm |

### 3.2 Screen Padding

| Context | Value |
|---------|-------|
| Screen horizontal | 20px |
| Screen top (below AppBar) | 16px |
| Screen bottom (above nav) | 100px (nav safe area) |

### 3.3 Bento Grid Layout

The home screen uses a Bento Grid with these cell sizes:

```
┌─────────────────────┐
│     HEADER AREA     │  ← Hero stat / household name
│  (aurora gradient)  │
├──────────┬──────────┤
│          │          │
│  STROM   │  GAS     │  ← 1x1 cells (square-ish)
│  ⚡       │  🔥      │
├──────────┼──────────┤
│          │          │
│  WASSER  │ HEIZUNG  │  ← 1x1 cells
│  💧       │  ♨️       │
├──────────┴──────────┤
│                     │
│    SMART PLUGS      │  ← 2x1 cell (wide)
│    🔌                │
└─────────────────────┘
```

Grid specs:
- Gap: 12px
- Card aspect ratio: ~1.2:1 (slightly taller than wide)
- Wide card: 2:1 ratio
- Card min-height: 120px

---

## 4. Components

### 4.1 Cards

**Bento Card (Primary)**
```
┌─────────────────────────┐
│  ╭─────╮                │
│  │ ICN │  Category Name │  ← Icon pill + title
│  ╰─────╯                │
│                          │
│  1,247.5 kWh             │  ← Primary value (displayLarge)
│  ↑ 3.2% vs Vorjahr      │  ← Delta indicator
│                          │
│  Letzter Eintrag: 15.03  │  ← Subtitle (bodySmall, textTertiary)
└─────────────────────────┘

Specs:
- Background: surface
- Border: 1px solid border
- Border radius: 20px
- Padding: 16px
- Shadow: 0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.02)
- Hover/Press: scale(0.98) + shadow lift
```

**Data Card (Analytics)**
```
┌─────────────────────────┐
│  Monatsverbrauch    ···  │  ← Title + options menu
│                          │
│  ┃ ┃     ┃              │
│  ┃ ┃ ┃   ┃              │  ← Bar chart area
│  ┃ ┃ ┃ ┃ ┃ ┃ ┃          │
│  J F M A M J J ...      │
│                          │
│  ⬤ 2026  ◯ 2025        │  ← Legend
└─────────────────────────┘

Specs:
- Same as Bento Card base
- Chart fills available space
- Legend uses labelSmall
```

**List Card (Reading Entry)**
```
┌─────────────────────────────────┐
│  15. März 2026            12:30 │  ← Date + time
│  ───────────────────────────── │
│  Zählerstand        4,521.3 m³ │  ← Label + value
│  Verbrauch             +12.7   │  ← Delta (success color if down)
│  Kosten                €34.20  │  ← Cost (if enabled)
└─────────────────────────────────┘

Specs:
- Border radius: 16px
- Interpolated readings: opacity 0.5, dashed left border
- Swipeable for edit/delete
```

### 4.2 Bottom Navigation

**Style: Floating Island**
```
                    ┌───┐
                    │ + │  ← FAB (contextual)
                    └───┘
┌────────────────────────────────────┐
│  ◉ Analyse    ○ Liste    ○ Mehr  │
└────────────────────────────────────┘

Specs:
- Position: fixed bottom, centered
- Width: screen width - 40px (20px each side)
- Height: 56px
- Border radius: 28px (pill)
- Background: surface with 0.95 opacity
- Border: 1px solid borderSubtle
- Shadow: 0 4px 20px rgba(0,0,0,0.08)
- Blur: BackdropFilter 20px (subtle glass, NOT glassmorphism)
- FAB: 48px circle, primary color, floats 8px above nav
- Active item: primary color dot below icon
- Inactive: textTertiary
```

### 4.3 App Bar

**Style: Clean Minimal**
```
┌─────────────────────────────────────┐
│  ← Strom          🏠 Mein Haus ▾  │
└─────────────────────────────────────┘

Specs:
- Height: 56px
- Background: transparent (scrolls with content)
- On scroll: surface background fades in + bottom border appears
- Title: headlineMedium, textPrimary
- Back button: 24px icon, textSecondary
- Household selector: chip style (surfaceVariant bg, 20px radius)
```

### 4.4 Buttons

**Primary Button**
```
Specs:
- Height: 48px
- Border radius: 12px
- Background: primary
- Text: labelLarge, onPrimary
- Press: darken 10%
- Disabled: opacity 0.4
```

**Secondary Button**
```
Specs:
- Height: 48px
- Border radius: 12px
- Background: transparent
- Border: 1px solid border
- Text: labelLarge, textPrimary
- Press: surfaceVariant background
```

**Ghost Button**
```
Specs:
- Height: 40px
- Border radius: 8px
- Background: transparent
- Text: labelLarge, primary
- Press: primaryContainer background
```

**Icon Button**
```
Specs:
- Size: 40x40px
- Border radius: 10px
- Background: transparent
- Icon: 20px, textSecondary
- Press: surfaceVariant background
```

### 4.5 Inputs

**Text Field**
```
┌─────────────────────────────┐
│  Zählerstand                │  ← Label (floating, labelMedium)
│  4,521.3                    │  ← Value (bodyLarge)
│                  kWh        │  ← Suffix
└─────────────────────────────┘

Specs:
- Height: 56px
- Border radius: 12px
- Background: surfaceVariant
- Border: none (unfocused), 2px primary (focused)
- Label: floats up on focus, labelSmall when floating
- Error: 2px error border + error text below
```

### 4.6 Chips & Badges

**Filter Chip (e.g., year selector)**
```
┌──────────┐
│ ◀ 2026 ▶ │
└──────────┘

Specs:
- Height: 36px
- Border radius: 18px (pill)
- Background: surfaceVariant
- Text: labelLarge, textPrimary
- Active: primaryContainer bg, primary text
```

**Status Badge**
```
Specs:
- Height: 20px
- Border radius: 10px
- Padding: 4px 8px
- Text: labelSmall
- Variants: success (green), warning (amber), info (blue)
```

**Category Pill (icon + label)**
```
┌───────────┐
│ ⚡ Strom  │
└───────────┘

Specs:
- Height: 28px
- Border radius: 14px
- Background: category container color
- Icon: 14px, category color
- Text: labelMedium, category color
```

### 4.7 Dialogs & Sheets

**Bottom Sheet (preferred over AlertDialog)**
```
┌─────────────────────────────────┐
│  ───── (drag handle)            │
│                                  │
│  Neuen Eintrag hinzufügen       │  ← Title
│                                  │
│  ┌───────────────────────────┐  │
│  │  Zählerstand              │  │  ← Input
│  │  _________                │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Datum                    │  │
│  │  15.03.2026               │  │
│  └───────────────────────────┘  │
│                                  │
│  ┌───────────────────────────┐  │
│  │       Speichern           │  │  ← Primary button
│  └───────────────────────────┘  │
└─────────────────────────────────┘

Specs:
- Border radius: 24px (top corners only)
- Background: surface
- Drag handle: 32x4px, borderSubtle, centered
- Padding: 24px
- Max height: 90% screen
- Overlay: #000000 at 0.3 opacity
```

**Confirmation Dialog**
```
Specs:
- Border radius: 20px
- Background: surface
- Padding: 24px
- Width: 320px
- Title: headlineMedium
- Body: bodyMedium, textSecondary
- Actions: row of Ghost + Primary buttons
```

---

## 5. Charts

### 5.1 General Chart Style

```
Colors: Use category colors (electricity=#F59E0B, etc.)
Background: transparent (sits on card surface)
Grid lines: borderSubtle, 1px, dashed
Axis labels: bodySmall, textTertiary
Value labels: labelMedium, textPrimary
Tooltip: surface bg, 12px radius, soft shadow
```

### 5.2 Monthly Bar Chart

```
┃                ┃
┃      ██        ┃
┃  ██  ██  ██    ┃
┃  ██  ██  ██ ██ ┃
┃──────────────── ┃
   J  F  M  A

Specs:
- Bar width: 60% of available space
- Bar radius: 6px (top corners)
- Comparison year: same bar, 30% opacity, behind
- Active month: full opacity + value label above
- Inactive: 70% opacity
- Animation: bars grow from bottom, staggered 50ms
```

### 5.3 Year Comparison (Overlay)

```
Current year: solid bars, category color
Previous year: outline bars, category color at 30% opacity
Gap between pairs: 4px
```

### 5.4 Consumption Pie (Smart Plugs)

```
Specs:
- Donut style (not filled pie)
- Stroke width: 24px
- Inner radius: 40%
- Center: total value (displayLarge)
- Max segments: 6 (group rest as "Sonstige")
- Colors: generate from category base using HSL shifts
- Animation: draw clockwise from top, 600ms ease-out
```

### 5.5 Sparkline (for Bento cards on Home)

```
Specs:
- Mini line chart, no axes, no labels
- Height: 40px
- Stroke: 2px, category color
- Fill: gradient from category color 20% → transparent
- Shows last 6 months trend
- Animation: draw left-to-right, 400ms
```

---

## 6. Icons

### 6.1 Icon Set: Lucide (via lucide_icons package)

**Why:** Consistent 24px grid, 1.5px stroke, rounded caps. Huge library. Active development. MIT license.

### 6.2 Category Icons

| Category | Icon | Lucide Name |
|----------|------|-------------|
| Electricity | ⚡ | `Zap` |
| Gas | 🔥 | `Flame` |
| Water | 💧 | `Droplets` |
| Heating | ♨️ | `Thermometer` |
| Smart Plugs | 🔌 | `Plug` |
| Households | 🏠 | `Home` |
| Settings | ⚙️ | `Settings` |
| Rooms | 🚪 | `DoorOpen` |
| Analytics | 📊 | `BarChart3` |
| List | 📋 | `List` |
| Add | ➕ | `Plus` |
| Edit | ✏️ | `Pencil` |
| Delete | 🗑️ | `Trash2` |
| Back | ← | `ChevronLeft` |
| Cost | 💰 | `CircleDollarSign` or `Wallet` |

### 6.3 Icon Containers

```
Category icon on cards:
- Container: 40x40px
- Border radius: 12px
- Background: category container color
- Icon: 20px, category color
```

---

## 7. Motion & Animation

### 7.1 Timing

| Type | Duration | Curve |
|------|----------|-------|
| Micro (opacity, color) | 150ms | easeOut |
| Small (chip, button) | 200ms | easeInOut |
| Medium (card, sheet) | 300ms | easeInOutCubic |
| Large (page transition) | 400ms | easeInOutCubic |
| Chart drawing | 600ms | easeOutCubic |
| Stagger delay | 50ms | — |

### 7.2 Page Transitions

```dart
// Shared axis transition (vertical)
// New screen slides up from bottom, old fades out
// Duration: 400ms
// Use: PageRouteBuilder with SlideTransition + FadeTransition
```

### 7.3 Card Interactions

```
Press: scale(0.98), 150ms, easeOut
Release: scale(1.0), 200ms, easeOutBack (slight bounce)
```

### 7.4 List Animations

```
Items appear with staggered fade + slide up:
- Offset: 16px from bottom
- Duration: 300ms per item
- Stagger: 50ms between items
- Curve: easeOutCubic
```

### 7.5 Number Transitions

```
When consumption values change (e.g., year navigation):
- Use implicit animation (AnimatedSwitcher)
- Old value fades out + slides up
- New value fades in + slides up from below
- Duration: 300ms
- Curve: easeInOutCubic
```

---

## 8. Dark Mode

### 8.1 Philosophy

Dark mode is NOT just inverted colors. It's a separate, carefully crafted experience.

### 8.2 Key Differences

| Element | Light | Dark |
|---------|-------|------|
| Background | `#F8FAFC` | `#0C0F14` (true dark, not grey) |
| Surface | `#FFFFFF` | `#161B22` (elevated dark) |
| Card border | `#E2E8F0` | `#2D3748` (subtle, not invisible) |
| Card shadow | subtle outset | NONE (use border instead) |
| Primary | `#1B6EF3` | `#4A91FF` (brighter for contrast) |
| Category colors | standard | slightly desaturated + brighter |
| Aurora gradient | visible on bg | more vivid (looks great on dark) |
| Text primary | `#0F172A` | `#F1F5F9` |
| Charts | standard colors | slightly brighter, NO dark outlines |

### 8.3 Elevation in Dark Mode

In dark mode, elevation = lighter surface (not shadow):
```
Level 0 (background): #0C0F14
Level 1 (card):       #161B22
Level 2 (sheet):      #1C2432
Level 3 (dialog):     #243044
Level 4 (tooltip):    #2D3748
```

---

## 9. Screen-by-Screen Layout Guide

### 9.1 Home Screen

```
┌──────────────────────────────────┐
│  ← (none)       🏠 Mein Haus ▾ │  AppBar
├──────────────────────────────────┤
│                                  │
│  ░░░░ AURORA GRADIENT BG ░░░░░  │
│                                  │
│  Guten Morgen 👋                 │  Greeting (headlineLarge)
│  Gesamtverbrauch März            │  Subtitle (bodyMedium, secondary)
│                                  │
│  ┌──────────┐ ┌──────────┐      │
│  │ ⚡ Strom  │ │ 🔥 Gas    │     │
│  │          │ │          │      │
│  │ 247 kWh  │ │ 12.3 m³  │     │  Bento Grid
│  │ ~~trend~~│ │ ~~trend~~│     │  with sparklines
│  └──────────┘ └──────────┘      │
│  ┌──────────┐ ┌──────────┐      │
│  │ 💧 Wasser │ │ ♨️ Heizung│     │
│  │          │ │          │      │
│  │ 8.4 m³   │ │ 2,140    │     │
│  │ ~~trend~~│ │ ~~trend~~│     │
│  └──────────┘ └──────────┘      │
│  ┌────────────────────────┐      │
│  │ 🔌 Smart Plugs              │  │
│  │ 5 Geräte · 47.3 kWh   │     │  Wide card
│  │ Top: Waschmaschine     │     │
│  └────────────────────────┘      │
│                                  │
│  ┌────────────────────────┐      │
│  │ 💰 Kosten diesen Monat      │  │
│  │ €127.40 (↑12%)         │     │  Summary card
│  └────────────────────────┘      │
│                                  │
└──────────────────────────────────┘
```

### 9.2 Meter Screen (e.g., Electricity)

```
┌──────────────────────────────────┐
│  ← Strom         🏠 Mein Haus ▾ │  AppBar
├──────────────────────────────────┤
│                                  │
│  ┌─ ANALYSE ─┬── LISTE ────┐   │  Tabs (inside floating nav)
│                                  │
│  ◀ 2026 ▶                       │  Year selector chip
│                                  │
│  ┌────────────────────────────┐  │
│  │  Gesamtverbrauch           │  │
│  │  2,847.3 kWh               │  │  Hero number card
│  │  Hochgerechnet: 3,120 kWh  │  │
│  │  ↑ 3.2% vs 2025           │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │  Monatsverbrauch           │  │
│  │  ┃     ┃                   │  │
│  │  ┃ ┃   ┃                   │  │  Monthly bar chart
│  │  ┃ ┃ ┃ ┃ ┃                 │  │
│  │  J F M A M J J A S O N D  │  │
│  │  ⬤ 2026  ◯ 2025          │  │
│  └────────────────────────────┘  │
│                                  │
│  ┌────────────────────────────┐  │
│  │  Kosten                    │  │
│  │  €847.20                   │  │  Cost card (if profile exists)
│  │  Ø €70.60/Monat           │  │
│  └────────────────────────────┘  │
│                                  │
│               ┌───┐              │
│               │ + │              │  FAB
│               └───┘              │
│  ┌────────────────────────────┐  │
│  │  ◉ Analyse   ○ Liste      │  │  Floating nav
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

### 9.3 List Tab (Readings)

```
┌──────────────────────────────────┐
│  ← Strom         🏠 Mein Haus ▾ │
├──────────────────────────────────┤
│                                  │
│  ┌──────────────────────────┐   │
│  │  📋 3 Einträge in 2026   │   │  Summary chip
│  └──────────────────────────┘   │
│                                  │
│  MÄRZ 2026                      │  Section header (sticky)
│  ┌──────────────────────────┐   │
│  │ 15.03   12:30            │   │
│  │ Stand: 4,521.3 kWh       │   │  Reading card
│  │ Verbrauch: +127.4 kWh    │   │
│  └──────────────────────────┘   │
│  ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐   │
│  ┆ 01.03   (interpoliert)  ┆   │  Interpolated (dashed border)
│  ┆ Stand: ~4,480.0 kWh     ┆   │
│  ┆ Verbrauch: ~85.2 kWh    ┆   │
│  └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘   │
│                                  │
│  FEBRUAR 2026                   │
│  ┌──────────────────────────┐   │
│  │ 15.02   09:15            │   │
│  │ Stand: 4,393.9 kWh       │   │
│  │ Verbrauch: +134.1 kWh    │   │
│  └──────────────────────────┘   │
│                                  │
└──────────────────────────────────┘
```

### 9.4 Settings Screen

```
┌──────────────────────────────────┐
│  ← Einstellungen                 │
├──────────────────────────────────┤
│                                  │
│  DARSTELLUNG                     │  Section header
│  ┌────────────────────────────┐  │
│  │  Design        ☀️ 🌙 📱    │  │  Segmented control
│  ├────────────────────────────┤  │
│  │  Sprache       DE | EN    │  │  Toggle
│  └────────────────────────────┘  │
│                                  │
│  ZÄHLER                         │
│  ┌────────────────────────────┐  │
│  │  Gas-Umrechnung      ▸    │  │
│  ├────────────────────────────┤  │
│  │  Kostenprofile       ▸    │  │  Navigation items
│  ├────────────────────────────┤  │
│  │  Haushalte           ▸    │  │
│  └────────────────────────────┘  │
│                                  │
│  DATEN                          │
│  ┌────────────────────────────┐  │
│  │  Backup exportieren  ▸    │  │
│  ├────────────────────────────┤  │
│  │  Backup importieren  ▸    │  │
│  └────────────────────────────┘  │
│                                  │
│  Valtra v2.0.0 (42)             │  Version footer
└──────────────────────────────────┘
```

---

## 10. Design Tokens Summary (Flutter)

```dart
// Spacing
static const space2 = 2.0;
static const space4 = 4.0;
static const space8 = 8.0;
static const space12 = 12.0;
static const space16 = 16.0;
static const space20 = 20.0;
static const space24 = 24.0;
static const space32 = 32.0;
static const space48 = 48.0;

// Radii
static const radiusSmall = 8.0;
static const radiusMedium = 12.0;
static const radiusLarge = 16.0;
static const radiusXL = 20.0;
static const radiusRound = 28.0;  // pills
static const radiusFull = 999.0;  // circles

// Shadows (light mode only)
static const shadowSmall = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 3, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x05000000), blurRadius: 2, offset: Offset(0, 1)),
];
static const shadowMedium = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
];
static const shadowLarge = [
  BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
];

// Durations
static const durationFast = Duration(milliseconds: 150);
static const durationNormal = Duration(milliseconds: 200);
static const durationMedium = Duration(milliseconds: 300);
static const durationSlow = Duration(milliseconds: 400);
static const durationChart = Duration(milliseconds: 600);

// Curves
static const curveDefault = Curves.easeInOutCubic;
static const curveSnap = Curves.easeOut;
static const curveBounce = Curves.easeOutBack;
```

---

## 11. Accessibility

- All text: minimum 4.5:1 contrast ratio (WCAG AA)
- Touch targets: minimum 44x44px
- Focus indicators: 2px primary ring, 2px offset
- Reduced motion: respect `MediaQuery.disableAnimations`
- Semantic labels on all icons and interactive elements
- Chart data: provide text alternative (e.g., "247 kWh in March")
- Color is never the ONLY indicator (always pair with text/icon)

---

## 12. Key Differences from v1 (Glassmorphism)

| Aspect | v1 (Current) | v2 (Aurora Bento) |
|--------|-------------|-------------------|
| Style | Glassmorphism (heavy blur) | Clean Bento + subtle Aurora |
| Cards | Transparent glass | Solid surface with thin border |
| Navigation | Custom LiquidGlass | Floating pill island |
| Colors | Ultra Violet primary | Blue primary (more neutral) |
| Font | System default | Plus Jakarta Sans |
| Shadows | Purple-tinted | Neutral, minimal |
| Home | 2x2 grid + center | Bento grid with data |
| Charts | Basic | Refined with animations |
| Inputs | Outline | Filled (surfaceVariant) |
| Dialogs | AlertDialog | Bottom sheets |
| Dark mode | Surface shift | True dark (#0C0F14) |
| Performance | Heavy (blur effects) | Excellent (no blur) |
| Icons | Material | Lucide (consistent stroke) |

---

## 13. Implementation Priority

### Phase 1: Foundation
1. New `AppTheme` with all color tokens
2. Typography setup (Plus Jakarta Sans)
3. Spacing constants
4. Light + Dark theme data

### Phase 2: Core Components
5. New card components (BentoCard, DataCard, ListCard)
6. Floating navigation bar
7. Clean AppBar
8. Button variants
9. Input fields
10. Bottom sheets

### Phase 3: Screens
11. Home screen (Bento grid with sparklines)
12. Meter screens (Analytics + List tabs)
13. Settings screen (grouped list)
14. All remaining screens

### Phase 4: Polish
15. Chart redesign (animations, style)
16. Page transitions
17. List animations
18. Number transition animations
19. Empty states with aurora illustrations
20. Final dark mode polish
