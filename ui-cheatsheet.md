# UI Cheatsheet (SwiftUI)

| Problem                            | Solution                                                                 |
| ---------------------------------- | ------------------------------------------------------------------------ |
| Old timestamps read "340 days ago" | Switch to an absolute date after a week: `.formatted(.relative(presentation: .named))` under 7 days, `.formatted(date: .abbreviated, time: .omitted)` after |
| Numbers jitter when they change    | `.monospacedDigit()`; animated: `.contentTransition(.numericText(value:))` |
| Large headings look off            | Tighter tracking on custom display sizes, e.g. `.tracking(-0.5)`. SF already tracks by size, so leave system styles alone |
| Body text looks awkward            | Cap the line at about 65 characters with `.frame(maxWidth:)`, scaled with `@ScaledMetric` so it grows with Dynamic Type |
| Button feels unresponsive          | Custom card/tile/chip: `ButtonStyle` with `.scaleEffect(configuration.isPressed ? 0.97 : 1)` (`.buttonStyle(.pressable)` in `tools/Motion.swift`). Rows and text buttons: system highlight or opacity dim, no scale |
| Avatar squished into an oval       | Fixed `.frame(width:height:)` plus `.clipShape(.circle)`; give the text `.layoutPriority` instead of the image |
| Gradient fade has a visible edge   | Use an eased gradient: extra `Gradient.Stop`s placed along an ease curve |
| Transition still feels off         | `.transition(.blurReplace)` (it also scales: `.opacity` under Reduce Motion), or a 2pt `.blur(radius:)` during the change |
| Dropdown feels sluggish            | Ease-out (`.emilEaseOut()`) under 0.3 s, never `.easeIn`. Better: use `Menu` |
| Popover grows from the wrong spot  | `anchor:` toward the trigger on `.scale(scale:anchor:)`, or system `.popover` (modals stay centered) |
| Count reads "1 members"            | Automatic grammar agreement: `Text("^[\(count) member](inflect: true)")` |
| Custom motion ignores Reduce Motion | Read `@Environment(\.accessibilityReduceMotion)` and fade instead of move. Only system components opt out on their own |
| You retimed a sheet or push        | Remove it. System sheet, navigation and menu motion stays as the system ships it |
