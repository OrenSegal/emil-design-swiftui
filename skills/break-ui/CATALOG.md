# Worst-Case Catalog

Realistic values that break UI, grouped by what kind of value the view renders, plus the native environments that break it without any data changing. Use the rows that apply to the fields in your Phase 1 table. Each value is something a real user could produce; the note says what it tends to break in SwiftUI.

Use `example.com`, `example.org`, or `.test` domains for emails and URLs, so the fixture never points at a real inbox or site.

---

## People and names

| Value | Breaks |
| --- | --- |
| `Aleksandra Wiśniewska-Kowalczyk` | Long, hyphenated, diacritics; wraps to two lines (the hyphen is a line-break point), or gets silently tail-truncated under `.lineLimit(1)` |
| `Christopher Alexander Montgomery III` | Long with a suffix; naive first + last initials give `CI` (`PersonNameComponentsFormatter` `.abbreviated` gives `CM`) |
| `Konstantin Oberhauser-Wettstein` | Long and compound; truncates in single-line rows |
| `Jo` | Two letters; leaves the name column mostly empty |
| `J` | One letter; single-character initials, a tiny tap target if the name is the only tappable thing (keep rows ≥ 44pt) |
| `Ólafur Darri Ólafsson` | Leading accented capital; uppercase/sort logic (use `localizedStandardCompare`), initials `ÓÓ` |
| `Đặng Thị Ngọc Hân` | Stacked Vietnamese diacritics; clipped by a fixed `.frame(height:)` + `.clipped()` or negative `lineSpacing` |
| `王秀英` | CJK, no spaces; "first + last word" initials logic finds one word, and CJK wraps anywhere |
| `نور الهدى عبد الرحمن` | RTL; mixed with LTR text (an email next to it), punctuation and icons can land on the wrong side |
| `Seán O'Brien-Ó Súilleabháin` | Apostrophe and accents; initials, search (use diacritic-insensitive `localizedStandardContains`) |
| `María José de la Cruz y Fernández` | Lowercase particles; initials `MD` or `MF`, sorting by "last name" |
| `dana` | All lowercase; initials should still be uppercase |
| `🦊 Fox` | Emoji first; Swift's `Character` keeps the emoji whole, but initials logic may return the emoji or nothing at all |
| `👩🏽‍💻 Priya` | ZWJ emoji sequence; the emoji is one `Character` but 4 Unicode scalars and 7 UTF-16 units, so code that counts `unicodeScalars` or `utf16` (character limits, `NSRange` math) cuts it apart |
| `  Sam   Lee ` | Leading, trailing, and repeated spaces; empty words from `split(separator: " ")` with `omittingEmptySubsequences: false`, odd gaps |
| *(missing)* | No name at all, only an email; the view must fall back to something |

## Emails, URLs, identifiers

Unbreakable strings: they have no spaces, so `Text` either breaks them between arbitrary characters or truncates them.

| Value | Breaks |
| --- | --- |
| `bartholomew.fitzgerald@northwind-industries-holdings.example.com` | The classic. Compresses every sibling in the `HStack`, or wraps character by character into a ragged block |
| `a@b.test` | Shortest realistic; a layout that assumed a long email looks empty |
| `first.last+billing-notifications@example.com` | Plus-addressing; validation that rejects `+`, end-truncation that hides the meaningful part |
| `ops@sub.department.region.example.test` | Many subdomains; "domain" extraction logic |
| `https://example.com/workspaces/acme/projects/q3-launch/docs/9f8e7d6c5b4a?tab=comments&filter=unresolved` | Long URL; end-truncation hides the part that differs (`.truncationMode(.middle)`) |
| `9f8e7d6c-5b4a-4c3d-8e2f-1a0b9c8d7e6f` | UUID; `.monospaced()` width, middle-truncation candidate |
| `Q3 Board Deck — FINAL (revised) v12 [approved by legal].pdf` | File name; end-truncation hides the version and extension |
| `IMG_20250914_183022_HDR_portrait_edited_edited.HEIC` | Camera file name; unbreakable, uppercase extension |
| `@a` / `@thisisaverylongusernamethatisallowed` | Handle extremes |

## Labels, titles, and copy from data

| Value | Breaks |
| --- | --- |
| `Senior Product Design Engineer, Platform Infrastructure` | Long job title; wraps to three lines in a secondary slot |
| `Invitation expired 12 days ago` | Long status badge; badge wraps or squeezes the name column |
| `Benachrichtigungseinstellungen` | German compound (30 chars, no spaces); a `Toggle` or `LabeledContent` label truncates or pushes its control |
| `Paramètres de confidentialité et de sécurité` | French expansion of "Privacy & security"; UI copy runs ~30% longer in translation, including navigation titles and tab bar items |
| Twelve tags on one item: `design`, `frontend`, `q3`, `urgent`, `needs-review`, … | Tag rows that need a custom wrapping `Layout` or a `+8` overflow |
| A tag named `customer-feedback-from-enterprise-onboarding` | One tag wider than its container |
| `Untitled` / empty string / `   ` | Title missing; a `Text("")` collapses to zero height, an empty `.navigationTitle` |
| `**bold**` / `[tap me](https://example.com)` / `<script>alert(1)</script>` | Markdown: rendered as bold or a live link if user data reaches a `LocalizedStringKey` or `AttributedString(markdown:)`. Must render as literal text (`Text(verbatim:)`) |
| `Line one` + newline + `Line two` | Newline in a single-line field; doubles row height, or gets truncated after the first line under `.lineLimit(1)` |
| A 2,000-character pasted description | Clamps, "show more", and `TextField(axis: .vertical)` growth (cap it with `.lineLimit(1...6)`) |

## Numbers and money

| Value | Breaks |
| --- | --- |
| `0` | Zero states: "0 members", empty `ProgressView`, division by zero in percentages |
| `1` | Plurals: "1 members", "1 days ago" (`inflect: true` or String Catalog plural variants) |
| `1284` | Needs a grouping separator: `1284.formatted()` gives `1,284` in en-US |
| `1000000` | Width of the count badge; compact form (`.number.notation(.compactName)` gives `1M` in en-US) where precision doesn't matter |
| `12345678.9` as currency | `.formatted(.currency(code: "USD"))` gives `$12,345,678.90`; overflows totals columns |
| `-42.5` | Negative sign, red color logic, accounting formats |
| `0.1 + 0.2` | `"\(0.1 + 0.2)"` renders `0.30000000000000004`; `.formatted()` gives `0.3` |
| `142%` / `-3%` | `ProgressView(value:)` and `Gauge` past their bounds (clamp the value) |
| `nil` / `.nan` / `.infinity` | Rendered literally via `"\(value)"`, or a crash on `Int(value)` |
| `1.284` in `de-DE` vs `1,284` in `en-US` | Locale formatting; hardcoded separators are wrong for half the world. Always `formatted()` |
| A value that changes live (`99` → `100`) | Width jump and jitter without `.monospacedDigit()` |

## Collections

| Value | Breaks |
| --- | --- |
| 0 items | The empty state, and whether one exists at all (`ContentUnavailableView`) |
| 1 item | Grids that look broken with one card; "1 of 1" |
| Exactly page size, and page size + 1 | Off-by-one in "Showing 40 of 40", a "load more" that fetches an empty page |
| 1,000+ items, unpaginated | Build time and memory if rows are in a non-lazy `VStack`; also "Showing 40 of 1,284" copy |
| One item 10× the size of the others | `Grid` / `LazyVGrid` rows stretching to the tallest item |
| Items with identical names | Lists where the name is the only distinguishing field; also `ForEach(id: \.name)` duplicates, which break diffing and animations |

## Time

| Value | Breaks |
| --- | --- |
| Now | `.relative(presentation: .named)` gives "5 seconds ago" for a few seconds back; show "Just now" under a minute if that's the product's voice |
| 12 days ago, 11 months ago, 3 years ago | Relative-time thresholds; switch to an absolute `.dateTime` date after 7 days |
| A future date | "in 3 days" vs "-3 days ago" |
| `1970-01-01` | A zero timestamp (`Date(timeIntervalSince1970: 0)`) shown as a real date |
| `2025-12-31T23:30:00-08:00` | Shows as a different day in UTC and the user's time zone |
| Very long duration (`1,284 hours`) | Duration formatting that never rolls up to days (`Duration.formatted(.units(...))`) |

Use `Date.formatted(.relative(presentation:))`, `Date.FormatStyle`, and `Duration` format styles, not hand-built strings.

## Images and media

| Value | Breaks |
| --- | --- |
| Avatar URL that 404s | `AsyncImage` shows its placeholder forever or nothing, instead of the initials fallback, unless the `.failure` phase is handled |
| No avatar at all | The fallback itself: initials, color, size parity with real avatars |
| 4000×200 panorama as avatar or cover | Distortion with `.resizable()` alone; needs `.scaledToFill()` + a fixed `.frame` + `.clipped()` |
| 200×4000 tall image | Same, other axis; `.scaledToFit()` can also blow out a card's height |
| Transparent PNG logo, dark logo in dark mode | Invisible on the background; give the asset an appearance variant or a backing shape |
| Slow-loading image | Layout jump when the image arrives, unless the frame is fixed or `.aspectRatio` is set up front |

## States

| Value | Breaks |
| --- | --- |
| Loading | Placeholders that don't match the final layout (`.redacted(reason: .placeholder)` on the real view keeps them matched), spinners that shift content |
| Error from the API | No error state, or a raw `error.localizedDescription` (a decoding error message) shown to the user |
| Partial data | Some optional fields filled, others not, in the same list; misaligned rows |
| Every status at once | All enum cases in one list (`active`, `invited`, `expired`, `suspended`); badge widths vary |
| No permission | `.disabled(true)` actions; does the row still lay out the same, and does VoiceOver say why? |
| The current user in the list | "You" labels, actions that shouldn't apply to yourself |

## Environment

Not data, but checked the same way: switch to the worst case, then change these. Each row says how to set it. Code overrides go in a `#Preview`; the rest are device settings.

| Condition | How to set it | Breaks |
| --- | --- | --- |
| Largest accessibility text (AX5) | `.environment(\.dynamicTypeSize, .accessibility5)`; `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large` | Fixed frames that clip, rows that squeeze to one word per line, toolbars that truncate, tab bar labels |
| Smallest text (`.xSmall`) | `.environment(\.dynamicTypeSize, .xSmall)` | Layouts tuned at Large that look stranded small; tap targets that shrink with the text |
| Bold Text | `.environment(\.legibilityWeight, .bold)`; Settings ▸ Accessibility | Wider glyphs in fixed-width boxes; custom fonts that ignore it |
| Increase Contrast | `xcrun simctl ui booted increase_contrast enabled`; Xcode Environment Overrides (read-only in code) | Low-opacity separators and text that disappear; custom colors without High Contrast variants |
| Reduce Transparency | Xcode Environment Overrides, or Settings ▸ Accessibility (read-only in code) | Text over custom `opacity` fills; system materials already adapt |
| RTL | `.environment(\.layoutDirection, .rightToLeft)`; the Right-to-Left pseudolanguage for the whole app | `.left`/`.right` padding and alignment, unmirrored custom icons, the order of trailing actions, swipe direction |
| Long translation | Scheme ▸ App Language (a real long language, or a double-length pseudolanguage) | Button and label truncation, navigation titles, segmented controls |
| Locale formatting | `.environment(\.locale, Locale(identifier: "de_DE"))` | Hand-built number, date, and currency strings |
| Narrow iPhone | The smallest-screen simulator you support; `.fixedLayout(width: 320, height: …)` preview trait as a narrow-column proxy | Every truncation above, at once |
| iPad Split View / Slide Over | Run on an iPad simulator and resize the split; the narrow side gets a compact horizontal size class | Layouts that branch on device instead of `horizontalSizeClass`; wide layouts squeezed into a phone-width column |
| iPad full width, landscape | iPad simulator, landscape | Lines too long to read; content stranded on one side (cap with `.frame(maxWidth:)` sized from the font) |
| iPhone landscape | `.landscapeLeft` preview trait; rotate the simulator | Vertical space runs out: fixed headers, sheets, keyboard covering fields |
| iPhone Duo, outer and inner display | An iPhone Duo simulator; fold and unfold while the screen is open | Outer display is wide and short, so a layout sized for a tall phone pushes its bottom actions out of reach (scroll or `ViewThatFits`); inner display is regular width and height even for a portrait-only app; state inside a size-class branch resets on fold |
| Dark mode | `.preferredColorScheme(.dark)` in the preview; `xcrun simctl ui booted appearance dark` | Hardcoded colors, invisible borders and logos |
| VoiceOver | Device, or Xcode's Accessibility Inspector against the Simulator | Reading order, five stops per row, icons with no label, truncated `accessibilityLabel`s built from data |
| Voice Control | Settings ▸ Accessibility ▸ Voice Control on a device, with Show Names on | A button whose label changes live (a price, a count, a timer) can't be spoken as a command: give it `.accessibilityInputLabels(["Apple"])`; icon-only buttons with no text label at all |
| Differentiate Without Color | Xcode Environment Overrides, or Settings ▸ Accessibility ▸ Display & Text Size (read-only in code) | Status, selection or chart series told apart by color alone; add a symbol, pattern, stroke or label when `accessibilityDifferentiateWithoutColor` is on |
| Pointer (iPad trackpad) | iPad simulator with pointer, or a real trackpad | Hover-only affordances; never make hover the only way to reveal an action |
