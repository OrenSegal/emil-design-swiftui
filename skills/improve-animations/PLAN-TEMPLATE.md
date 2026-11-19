# Plan Template

Every plan written by `improve-animations` follows this structure. The executor may be a less capable model with zero context and zero taste — the plan must contain everything, exactly. No references to "the audit above" or "the easing we discussed."

````markdown
# NNN — <Short imperative title>

- **Status**: TODO
- **Commit**: <output of `git rev-parse --short HEAD` when this plan was written>
- **Severity**: HIGH | MEDIUM | LOW
- **Category**: <audit category>
- **Estimated scope**: <n files, rough size>

## Problem

What is wrong, where, and why it matters to how the product feels. Cite every
location as `path/to/File.swift:123` and include the current code verbatim:

```swift
// Sources/Feed/FilterDropdown.swift:14 — current
struct FilterDropdown: View {
    @State private var isOpen = false

    var body: some View {
        VStack(alignment: .leading) {
            Button("Filter") { isOpen.toggle() }
            if isOpen {
                Text("Newest").transition(.scale)
            }
        }
        .animation(.easeIn(duration: 0.4), value: isOpen)
    }
}
```

## Target

The exact end state. Every value spelled out — curves (`timingCurve` control
points), durations in seconds, spring parameters, anchors, the Reduce Motion
branch. Never "use a nicer easing":

```swift
// target
struct FilterDropdown: View {
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading) {
            Button("Filter") {
                // .emilEaseOut(0.2) == .timingCurve(0.23, 1, 0.32, 1, duration: 0.2)
                withAnimation(.emilEaseOut(0.2)) { isOpen.toggle() }
            }
            .buttonStyle(.pressable)
            if isOpen {
                Text("Newest")
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.95, anchor: .topLeading).combined(with: .opacity))
            }
        }
    }
}
```

## Repo conventions to follow

How this codebase already does it, with one exemplar the executor should
imitate (token names, file placement, modifier patterns):

- Motion tokens live in `Sources/DesignSystem/Motion.swift`; add new curves there, e.g. `static func emilEaseOut(_ duration: TimeInterval = 0.2) -> Animation { .timingCurve(0.23, 1, 0.32, 1, duration: duration) }`.
- <exemplar File.swift:line that already does this correctly>

## Steps

1. <One concrete edit per step: file, what changes, resulting code.>
2. …

## Boundaries

- Do NOT touch <files/components out of scope>.
- Do NOT change view structure or layout — motion modifiers only (unless a step says otherwise).
- Do NOT retime, re-curve, or disable system motion (`NavigationStack`, `.sheet`, `.popover`, `Menu`, `TabView`, keyboard).
- Do NOT add new Swift packages or pods.
- If a step doesn't match the code you find (drift since the commit stamp), STOP and report instead of improvising.

## Verification

- **Mechanical**: <exact commands with expected outcome, e.g. `xcodebuild -scheme App -destination 'platform=iOS Simulator,name=iPhone 16' build` succeeds with no new warnings; `xcodebuild test ...` passes>.
- **Feel check**: run the app, trigger <interaction>, and confirm:
  - <observable check, e.g. "the dropdown grows from the Filter button's corner, not from its center">
  - <e.g. "tapping Filter rapidly never makes the panel jump; it reverses from where it is">
  - With Simulator ▸ Debug ▸ Slow Animations on, confirm <detail>.
  - Turn on Settings ▸ Accessibility ▸ Motion ▸ Reduce Motion and confirm movement is dropped but the opacity change remains.
  - <for gestures or haptics: on a real device, confirm …; the Simulator has no haptics, real touch latency, or ProMotion>
- **Done when**: <machine- or eye-checkable completion criteria>.
````

## Notes for the plan author

- One plan per finding. If two findings share every file and the same fix pattern (e.g. the same easing token swap across components), they may merge into one plan.
- Pull every value from [AUDIT.md](AUDIT.md) — never approximate from memory.
- Code in Problem and Target must be real Swift the executor can match against the file: verbatim for Problem, complete for Target.
- The feel check is not optional. Motion can be mechanically correct and still feel wrong; give the executor (or the human reviewing the executor's diff) concrete things to watch for in slow motion.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| DevTools Animations panel at 10% playback | Browser tooling | Simulator ▸ Debug ▸ Slow Animations; Instruments for timing |
| Rendering-panel `prefers-reduced-motion` toggle | Browser tooling | Settings ▸ Accessibility ▸ Motion ▸ Reduce Motion |
| `transform-origin: var(--transform-origin)` in the target example | React library variable | `anchor:` on the scale transition |
