# Phase 28: Home & Nav Polish - Context

**Gathered:** 2026-04-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Refresh the home screen household card styling to frosted/liquid glass, integrate the FAB into the bottom navigation bar, remove the active dot indicator, and add person count storage and editing per household. No new screens or capabilities — visual refresh and one new data field.

</domain>

<decisions>
## Implementation Decisions

### Household card styling
- Frosted/liquid glass effect — Claude's discretion on intensity, based on existing LiquidGlass patterns
- Replace current blue-purple gradient with glass styling
- Name-focused layout: household name prominent, summary stats (meter count, person count) as subtle secondary info
- Keep current tap behavior unchanged
- Multiple households displayed as horizontal carousel (not vertical stack)

### FAB + nav bar integration
- FAB positioned at right end of the nav bar, integrated as the last item
- Visual style matches the nav bar (glass/translucent) — blends in, not accent-colored
- Keep current FAB action and icon unchanged
- FAB no longer floats above the pill — it's part of the nav bar

### Person count UX
- Displayed on the household card (read-only), editable in household settings screen
- Required field when creating a new household — no default value
- Input widget: Claude's discretion (stepper vs text field)
- Store only in this phase — per-capita analytics usage deferred to future phases
- Persists in database (new column on household table)

### Nav bar cleanup
- Remove active dot indicator
- Active tab indicated by color/tint change (e.g., brighter or accent color)
- Icons with text labels below each item
- Keep current tab set — no reorganization
- Keep glass/translucent nav bar background style

### Claude's Discretion
- Glass effect intensity on household card
- Person count input widget type (stepper vs text field)
- Exact active tab color treatment
- Card shadow, blur, border details
- Spacing and typography within cards

</decisions>

<specifics>
## Specific Ideas

- Household card should feel like a frosted glass card — no more blue-purple gradient
- FAB should feel like it belongs in the nav bar, not bolted on top
- Horizontal carousel for multiple households gives a swipe-to-browse feel

</specifics>

<deferred>
## Deferred Ideas

- Per-capita consumption calculations using person count — future analytics phases
- No other deferred ideas — discussion stayed within phase scope

</deferred>

---

*Phase: 28-home-nav-polish*
*Context gathered: 2026-04-01*
