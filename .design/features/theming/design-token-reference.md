# RefereeIQ Design Token Reference

Source of truth: [`lib/theme.dart`](../../../lib/theme.dart)

---

## Colour palette

| Token | Hex / computed | Use |
|---|---|---|
| `primary` | `#FBD823` (yellow) | AppBar bg, FilledButton bg, selected chip, user chat bubble, active tab indicator |
| `onPrimary` | `#212121` (near-black) | Text/icons **on** primary surfaces |
| `secondary` | `#212121` | Secondary interactive elements |
| `onSecondary` | `#FFFFFF` | Text/icons **on** secondary surfaces |
| `tertiary` | `#0C2E55` (navy) | Links, deep-navy accents |
| `onTertiary` | `#FFFFFF` | Text/icons **on** tertiary surfaces |
| `surface` | `#FFFFFF` | Page / scaffold background |
| `onSurface` | `#212121` | Primary body text, headings, icons |
| `onSurfaceVariant` | computed | Secondary/hint text, timestamps, subtitles, muted icons |
| `surfaceContainerHighest` | computed | Card fills, bot chat bubbles, chip backgrounds, image placeholders |
| `outline` | computed | Input borders, dividers |
| `primaryContainer` | computed | Warm card backgrounds (law cards), blockquote fills |
| `secondaryContainer` | computed | Sub-category chip selected fill |
| `error` | `Colors.red` | Destructive actions, badge fills, error icons |
| `onError` | `#FFFFFF` | Badge count text, text **on** error surfaces |
| `shadow` | computed | Box-shadow colour (always pair with low alpha) |

---

## Button hierarchy

| Intent | Widget | Style source |
|---|---|---|
| Primary action (Google, Save, Submit) | `FilledButton` | `filledButtonTheme` in `theme.dart` |
| Secondary action (Sign Up, Email) | `FilledButton.tonal` | M3 default tonal |
| Tertiary / low-emphasis (Log In, Cancel) | `OutlinedButton` | M3 default outlined |
| Destructive (Delete Account) | `TextButton` with `style: TextButton.styleFrom(foregroundColor: colorScheme.error)` | inline |
| Retry / utility | `FilledButton.icon` with `Icons.refresh` | `filledButtonTheme` |

---

## Typography

All text uses **Inter** via `GoogleFonts.interTextTheme()`. The theme sets this globally; do not override font family in individual widgets unless there is a specific design reason.

---

## Rules

### Always use
```dart
final colorScheme = Theme.of(context).colorScheme;
```

### Never hard-code
| ❌ Hard-coded | ✅ Token |
|---|---|
| `Colors.grey.shade500/600/700` | `colorScheme.onSurfaceVariant` |
| `Colors.black` / `Colors.black87` | `colorScheme.onSurface` |
| `Colors.white` (fills) | `colorScheme.surface` or `surfaceContainerHighest` |
| `Color(0xFF212121)` | `colorScheme.onSurface` or `colorScheme.onPrimary` (context-dependent) |
| `Colors.grey[200/300]` (fills) | `colorScheme.surfaceContainerHighest` |
| `Color(0xFFFEF7E6)` (warm card) | `colorScheme.primaryContainer` |
| `Color(0xFFF0CF1E)` (sub-chip) | `colorScheme.secondaryContainer` |
| `Colors.red` (badge) | `colorScheme.error` |
| Badge count `Colors.white` | `colorScheme.onError` |
| `Color(0xFFFBD823)` (brand yellow) | `colorScheme.primary` |

---

## Component quick-ref

| Component | Key tokens |
|---|---|
| AppBar | `primary` bg · `onPrimary` fg — set via `AppBarTheme`, no per-screen overrides needed |
| TabBar | `onPrimary` label · `onPrimary @ 0.6` unselected · `onPrimary` indicator — set via `TabBarTheme` |
| Chips (category) | `primary` selected · `surfaceContainerHighest` unselected · `onPrimary`/`onSurface` labels — set via `ChipTheme` |
| Chat bubbles (user) | `primary` bg · `onPrimary` text |
| Chat bubbles (bot) | `surfaceContainerHighest` bg · `onSurface` text |
| Cards / law rows | `primaryContainer` bg |
| Error badge | `error` fill · `onError` count text |
| Timestamps / subtitles | `onSurfaceVariant` |
| Destructive text | `error` |
| Disabled states | `surfaceContainerHighest` bg · `onSurfaceVariant` text (let M3 defaults handle where possible) |
