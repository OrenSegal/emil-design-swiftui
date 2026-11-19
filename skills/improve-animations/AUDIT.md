# Animation Audit Playbook

The audit categories, what to look for in each, and the exact target values to cite in findings and plans. Distilled from Emil Kowalski's design engineering philosophy ([emilkowal.ski](https://emilkowal.ski/)), ported to SwiftUI (iOS 18, Swift 6). Categories 1–8 are Emil's; 9 is the native addition. Never approximate a value that appears here — copy it. The tokens referenced (`.emilEaseOut()`, `.emilEaseInOut()`, `.emilDrawer()`, `.emilPress`, `Spring.emilUI`, `Spring.emilMomentum`, `.pressable`, `project(velocity:)`, `rubberband(_:dimension:)`) are defined in `tools/Motion.swift`; a plan for an app without them adds that file first.

## 1. Purpose & frequency

Every animation must answer "why does this animate?": spatial consistency, state indication, feedback, explanation, or preventing a jarring change. "It looks cool" on a frequently-seen element is not a purpose.

| Frequency | Decision |
| --- | --- |
| 100+ times/day (keyboard shortcuts, command palette toggle) | No animation. Ever. |
| Tens of times/day (pointer hover effects, list navigation) | Remove or drastically reduce |
| Occasional (custom modals, drawers, toasts) | Standard animation |
| Rare / first-time (onboarding, feedback, celebrations) | Can add delight |

Hunt for: `withAnimation` or a `.transition` behind a `.keyboardShortcut` / `.onKeyPress` action, command palettes with open/close transitions (Raycast has none — correct), decorative motion on `List` rows or hover states hit constantly, `.scrollTransition` effects on every row of a feed. The strongest fix is often **delete the animation**.

## 2. Easing & duration

Decision order for easing:

- Entering or exiting → **ease-out**: `.emilEaseOut()` = `.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)`
- Moving / morphing on screen → **ease-in-out**: `.emilEaseInOut()` = `.timingCurve(0.77, 0, 0.175, 1, duration: 0.3)`
- Pointer hover / color change → **CSS `ease`**: `.emilEase()` (`.timingCurve(0.25, 0.1, 0.25, 1, duration:)`)
- Constant motion (marquee, progress) → **`.linear`**
- Default → **ease-out**

**`.easeIn` on UI is always a finding** (also `UIView.AnimationOptions.curveEaseIn`, `CAMediaTimingFunctionName.easeIn`): it starts slow, delaying the exact moment the user is watching. The built-in `.easeOut` / `.easeInOut` / `.default` are too weak for deliberate motion; plans should introduce strong custom curves as tokens, matching repo conventions:

```swift
// Target token file. If the app has an Animation extension already, add these there instead.
extension Animation {
    static func appEaseOut(_ duration: TimeInterval = 0.2) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)        // strong ease-out for UI
    }
    static func appEaseInOut(_ duration: TimeInterval = 0.3) -> Animation {
        .timingCurve(0.77, 0, 0.175, 1, duration: duration)      // strong ease-in-out for on-screen movement
    }
    static func appDrawer(_ duration: TimeInterval = 0.5) -> Animation {
        .timingCurve(0.32, 0.72, 0, 1, duration: duration)       // iOS-like drawer curve
    }
}
```

(Same values as `tools/Motion.swift`'s `emil*` tokens; use whichever naming the repo already follows.)

Duration budgets — **custom UI animations stay under 300 ms. Modals, drawers, sheets, and toasts are the documented exceptions** (modals and drawers up to 500 ms; Sonner-style toasts, a web-origin pattern, use 400 ms CSS `ease`: `.emilEase(0.4)`):

| Element | Duration |
| --- | --- |
| Button press feedback | 100–160 ms (`0.1`–`0.16`) |
| Tooltips, small popovers (custom) | 125–200 ms (`0.125`–`0.2`) |
| Dropdowns, selects (custom) | 150–250 ms (`0.15`–`0.25`) |
| Modals, drawers (custom) | 200–500 ms (`0.2`–`0.5`) |
| Marketing / explanatory | Can be longer |

Hunt for: `.easeIn` anywhere, bare `.easeOut` / `.easeInOut` / `.default` / `.linear` on entrances (Sonner-style toasts excepted), `duration:` > `0.3` on custom UI other than modals, drawers, sheets, and toasts, springs whose settle time is obviously long for the element (`.spring(duration: 0.8)` on a toggle). System component timing is out of scope (category 9).

## 3. Physicality & origin

- **Never scale 0**: nothing in the real world appears from nothing. `.scaleEffect(0)` and bare `.transition(.scale)` (default scale 0) are findings. Target: `.transition(.scale(scale: 0.95).combined(with: .opacity))` (0.9–0.97).
- **Custom popovers/dropdowns scale from their trigger**, not center: `.scale(scale: 0.95, anchor: .topLeading)` (or whichever corner the trigger sits at), or `anchor:` on `.scaleEffect`. If the custom popover can be the system `.popover` / `Menu`, that's the better fix (category 9).
  **Modals are exempt**: they appear centered, so a centered anchor is correct there. Do not report it.
- **Press feedback**: scale 0.97 on touch-down, 160 ms ease-out: `.buttonStyle(.pressable)` (`PressableButtonStyle` in `tools/Motion.swift`). Keep it subtle (0.95–0.98). Feedback driven by `onTapGesture` fires on release and is a finding.

Hunt for: `.scaleEffect(0`, `.transition(.scale)`, pure-`.opacity` entrances with no initial scale or offset, `.scaleEffect` / `.scale(` with no `anchor:` on trigger-anchored custom UI, `Button`s with `.plain` style and no press state, `onTapGesture` used as a button.

## 4. Interruptibility

Nothing in SwiftUI jumps when interrupted, but **springs merge and hand their velocity to the new target, while timing curves stack**: the old curve keeps playing and the new one adds on top, so motion stays continuous but the old curve plays out (sluggish or overshooting on a reversal). `keyframeAnimator` / `phaseAnimator` are SwiftUI's "keyframes": a re-triggered `keyframeAnimator` rebuilds from the current value and keeps velocity, but plays an authored track and can't follow a changing target. Anything triggered rapidly or reversible mid-motion (toasts stacking, toggles, drags, expand/collapse) must use state-driven springs (or at least state-driven animations), never animator tracks.

- Entry: a view inserted inside `if` with a `.transition(...)` and the state change in `withAnimation`. Not the `onAppear { mounted = true }` flag.
- Gesture-driven motion uses springs; hand the release velocity over with `.interpolatingSpring(..., initialVelocity:)` (relative velocity: `gestureVelocity / (target − current)`).
- Spring configs, Apple-style (recommended): `.spring(duration: 0.5, bounce: 0.2)`. Keep bounce subtle (0.1–0.3); reserve visible bounce for drag-to-dismiss and playful moments. House defaults: `Spring.emilUI` (response 0.4, damping 1.0), `Spring.emilMomentum` (response 0.35, damping 0.8) after a flick only.
- **Asymmetric timing**: deliberate phases (press, hold, destructive confirm) animate slower; the system's response snaps. Hold-to-confirm target: `.linear(duration: 2)` while `onLongPressGesture(minimumDuration: 2, perform:onPressingChanged:)` is pressing, `.emilEaseOut(0.2)` on release. Symmetric timing on press-and-release is a finding.
- UIKit: gesture-driven or reversible motion belongs in a `UIViewPropertyAnimator` (pausable, reversible, scrubbable), not a fire-and-forget `UIView.animate`.

```swift
// Target shape for a draggable card: 1:1 tracking, velocity dismissal, rubber-banding, spring settle.
struct DraggableCard: View {
    @State private var offset: CGFloat = 0
    @State private var dragStart: CGFloat?
    @State private var isDismissed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !isDismissed {
            RoundedRectangle(cornerRadius: 20)
                .fill(.indigo)
                .frame(height: 160)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let start = dragStart ?? offset // grab mid-spring without a jump
                            dragStart = start
                            let x = start + value.translation.width
                            offset = x >= 0 ? x : rubberband(x, dimension: 300) // friction, not a wall
                        }
                        .onEnded { value in
                            dragStart = nil
                            let velocity = value.velocity.width // release velocity, pt/s
                            let dismiss = velocity > 500 || offset > 150
                            let target: CGFloat = dismiss ? 600 : 0 // shortcut: fixed travel past the card
                            let remaining = target - offset
                            let relative = abs(remaining) > 1 ? velocity / remaining : 0
                            // Velocity handoff; critically damped, so a dismissal never overshoots back.
                            let animation: Animation = reduceMotion
                                ? .emilEaseOut(0.2)
                                : .interpolatingSpring(.emilUI, initialVelocity: relative)
                            withAnimation(animation) { offset = target } completion: {
                                if dismiss { isDismissed = true }
                            }
                        }
                )
                .transition(reduceMotion ? .opacity : .move(edge: .trailing))
                .accessibilityAction(named: "Dismiss") { withAnimation(.emilEaseOut(0.2)) { isDismissed = true } }
        }
    }
}
```

Hunt for: `keyframeAnimator` / `phaseAnimator` on toasts/toggles/rapidly-triggered UI, gesture `.onEnded` handlers that tween with a fixed-duration curve, drags without velocity-based dismissal (dismiss on release velocity `DragGesture.Value.velocity` > ~500 pt/s, not distance thresholds alone; Emil's 0.11 px/ms ≈ 110 pt/s is Sonner's distance ÷ elapsed-time average, not a release velocity, so comparing `value.velocity` with 110 is itself a finding), hard `min`/`max` clamps at drag boundaries instead of rising friction.

## 5. Performance

- **Prefer render-time effects (`offset`, `scaleEffect`, `rotationEffect`, `opacity`); masks and a measured-height accordion are the documented exceptions.** Animating `frame` / `padding` / font size / stack spacing re-runs layout every frame.
- **Broad animation scope is SwiftUI's `transition: all`**: `withAnimation` around a state change many views read, `.animation(_:value:)` on a screen-level container, or the deprecated value-less `.animation(_:)`. It animates unintended changes and widens what re-layouts per frame. Always a finding. Target: `.animation(_:value:)` on the view that changes, or `.animation(_:body:)` (iOS 17) scoped to specific modifiers.
- **Layout-driven animation (`matchedGeometryEffect`, animated `frame`) costs layout every frame**: fine for occasional moments, a finding on motion that runs while the main thread is busy.
- **Don't put per-frame state on a parent or in the environment**: a drag offset or scroll value on a parent, in a shared `@Observable` model, or pushed through `.environment` re-evaluates whole subtrees every frame. Keep it in the view that moves (`@GestureState`, `@State`).
- **Keep the main thread free during transitions**: SwiftUI evaluates animations in-process, per frame, so work started in the same action (decoding, big list diffs, synchronous I/O) hitches them. Core Animation (`UIView.animate`, `CALayer`) commits to the render server. Target: defer heavy work until after the transition or move it off the main actor; measure in Instruments (Animation Hitches).
- Keep transition-time `.blur(radius:)` small (under 20 pt): blur renders offscreen.

Hunt for: `.animation(` on root containers, value-less `.animation(`, `withAnimation` around model reloads, `.frame(` / `.padding(` fed by animated state, `matchedGeometryEffect` on busy screens, `@Observable` / environment values updated from `DragGesture.onChanged` or scroll callbacks, `Timer` / `CADisplayLink` loops doing what a state animation could.

## 6. Accessibility

- **Custom animations don't opt out on their own.** System components follow Reduce Motion; custom `withAnimation`, `.transition`, offset/scale/rotation animations, `phaseAnimator`, `keyframeAnimator`, `UIView.animate`, and `CABasicAnimation` code does not. Read `@Environment(\.accessibilityReduceMotion)` (UIKit: `UIAccessibility.isReduceMotionEnabled`) and branch.
- Reduced motion means fewer and gentler animations, **not zero**: keep opacity and color transitions that aid comprehension, remove position, scale, and 3D changes.
- Hover (`.onHover`, `.onContinuousHover`) is pointer-only (iPad trackpad, Mac). Touch doesn't fire it, so there's no false hover to gate, but it must never be the only affordance. Prefer `.hoverEffect`.
- Custom controls keep their label and traits (`.accessibilityAddTraits(.isButton)`, `.accessibilityAction`) when motion is added or removed.

```swift
struct ReduceMotionAwareBanner: View {
    @Binding var isShown: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if isShown {
            Text("Copied")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.regularMaterial, in: .capsule)
                // Keep the fade (comprehension), drop the movement.
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }
}
```

Hunt for: files with movement and no `accessibilityReduceMotion` / `isReduceMotionEnabled`, Reduce Motion branches that pass `nil` to every animation (killing fades and press feedback too), hover-only affordances, `onTapGesture` controls with no button trait.

## 7. Cohesion & tokens

- Motion should match the product's personality: playful can be bouncier, a dashboard stays crisp. One `.bouncy` component in an otherwise crisp app is a finding.
- Curves and durations should live as shared tokens (one `Animation` / `Spring` extension). Five hand-typed `timingCurve`s or `.spring(response:dampingFraction:)` calls that almost match is a consolidation finding.
- Everything-at-once group entrances where a **30–80 ms (`0.03`–`0.08`) stagger** belongs. Stagger is decorative: it must never block interaction (`.allowsHitTesting(false)` during an entrance is a finding). For group entrances, follow `../choreograph/SKILL.md` (one entrance per container, non-uniform delays).
- A jarring crossfade that shows two overlapping states can be masked with a subtle blur during the transition: `.transition(.blurReplace)` (iOS 17; it blurs *and scales*, so fall back to `.opacity` under Reduce Motion) or `.blur(radius: 2)` on the same state. For text and symbols, `.contentTransition(.numericText(value:))` / `.contentTransition(.symbolEffect(.replace))`.
- Haptics belong to the same moment as the motion: `.sensoryFeedback(_:trigger:)` on the state change that drives the animation.

Hunt for: duplicated near-identical curves/durations/springs, one bouncy component in a crisp app, `ForEach` entrances with no stagger, `if/else` content swaps that visibly double-expose, `.sensoryFeedback` tied to a different value than the animation.

## 8. Missed opportunities

The additive category — places that don't animate but should:

- State changes that teleport (content swaps in `if/else`, layout jumps when a section expands) where a brief transition would prevent a jarring change.
- Spatially-connected UI (a custom panel that appears from a trigger) with no motion explaining where it came from. For navigation from a thumbnail, the system hook is `.matchedTransitionSource(id:in:)` + `.navigationTransition(.zoom(sourceID:in:))` (iOS 18).
- Rare, high-emotion moments (first-run, success, celebration) rendered with none of the delight budget they're allowed, including a matching `.sensoryFeedback(.success, trigger:)`.
- Own-size movement (`.transition(.move(edge:))`, which moves by the view's own size) and mask reveals (`.mask` / a `Shape` with `animatableData`, the native `clip-path: inset()`) as tools for these: no hardcoded point offsets.

Report at most 4, grounded in actual UX seams you observed — not a wishlist.

## 9. System motion (native addition)

Emil's budgets and curves are for **custom** components. `NavigationStack` push/pop, `.sheet`, `.fullScreenCover`, `.popover`, `Menu`, `.confirmationDialog`, `.alert`, `TabView`, and the keyboard keep system timing. Users have it in muscle memory and it already follows Reduce Motion.

- Retiming or re-curving system motion is a finding: a push, path change, or presentation wrapped in a custom `withAnimation(...)` to "match the house curve".
- Stripping it is a finding: `transaction.disablesAnimations = true` / `withTransaction` around a push or sheet, `UIView.setAnimationsEnabled(false)`, `UIView.performWithoutAnimation` around navigation, with no stated reason.
- Replacing it is a finding: a custom `UIViewControllerAnimatedTransitioning` for a standard push, or an overlay + `.transition(.move(edge: .bottom))` re-implementing `.sheet`, a custom dropdown re-implementing `Menu`. The fix is the system component.
- Not a finding: system-provided hooks that keep system timing (`.navigationTransition(.zoom(...))`, `.presentationDetents`, `.presentationBackground`).

```swift
// Before: a hand-rolled bottom sheet with its own curve. No drag-to-dismiss, no detents, no system Reduce Motion handling.
struct FakeSheetHost: View {
    @State private var isPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Button("Show details") {
                withAnimation(.easeInOut(duration: 0.45)) { isPresented = true }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isPresented {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.background)
                    .frame(height: 320)
                    .transition(.move(edge: .bottom))
            }
        }
    }
}
```

```swift
// After: the system sheet. Its motion, gestures, and Reduce Motion behaviour are the system's.
struct SystemSheetHost: View {
    @State private var isPresented = false

    var body: some View {
        Button("Show details") { isPresented = true }
            .sheet(isPresented: $isPresented) {
                Text("Details")
                    .presentationDetents([.medium, .large])
            }
    }
}
```

Hunt for: `disablesAnimations`, `setAnimationsEnabled`, `performWithoutAnimation`, `UIViewControllerAnimatedTransitioning`, `withAnimation` around `path.append` / `isPresented = true`, `ZStack` overlays with `.move(edge: .bottom)` that behave like sheets.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| CSS custom-property tokens (`--ease-out: cubic-bezier(...)`) | No stylesheet layer | An `Animation` extension with `timingCurve` tokens (category 2) |
| `transform-origin: var(--transform-origin)` (Base UI) | React library variable | `anchor:`; the system `.popover` already anchors |
| `@starting-style` / `data-mounted` in `useEffect` for entry | CSS / React | `.transition(...)` on an inserted view, state change in `withAnimation` |
| Motion `x`/`y`/`scale` shorthands before `motion` 14.2; full `transform` string; `layout`/`layoutId` main-thread caveat | Library-version caveat for a React library | Layout-driven motion (`matchedGeometryEffect`, animated `frame`) is the native cost to watch (category 5) |
| `setProperty('--x', …)` driving child transforms | CSS cascade | Reframed: per-frame state on a parent / in the environment (category 5) |
| "CSS and WAAPI beat rAF-based JS under load" | Browser pipeline | Reframed: keep the main thread free during transitions; Core Animation commits to the render server (category 5) |
| `@media (hover: hover) and (pointer: fine)` hover gating | Touch doesn't fire SwiftUI hover | Hover is never the only affordance; `.hoverEffect` (category 6) |
| `useReducedMotion()` in JS | React hook | `@Environment(\.accessibilityReduceMotion)` (category 6) |
| Instant tooltips after the first in a toolbar | `.help()` timing is the system's (pointer only); no tooltips on touch | The principle stays for custom hover UI on iPad/Mac |
| `Math.abs(distance)/elapsedMs > ~0.11` | px/ms units, and an average over the drag, not a release velocity | Release velocity `DragGesture.Value.velocity` > ~500 pt/s; or compute distance ÷ elapsed time yourself and compare with 110 pt/s (category 4) |
