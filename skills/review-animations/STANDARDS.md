# Animation Standards Reference

The precise values, curves, and rules behind the review. Cite these in findings instead of approximating. Distilled from Emil Kowalski's design engineering philosophy, ported to SwiftUI (iOS 18, Swift 6). The shared tokens (`.emilEaseOut()`, `.emilEaseInOut()`, `.emilDrawer()`, `.emilPress`, `Spring.emilUI`, `Spring.emilMomentum`, `.pressable`, `project(velocity:)`, `rubberband(_:dimension:)`) live in `tools/Motion.swift`.

## Should it animate? (frequency table)

| Frequency | Decision |
| --- | --- |
| 100+ times/day (keyboard shortcuts, command palette toggle) | No animation. Ever. |
| Tens of times/day (pointer hover effects, list navigation) | Remove or drastically reduce |
| Occasional (custom modals, drawers, toasts) | Standard animation |
| Rare / first-time (onboarding, feedback, celebrations) | Can add delight |

**Never animate keyboard-initiated actions.** They repeat hundreds of times daily, and animation makes them feel slow and disconnected. In SwiftUI that means a `Button` (or `.onKeyPress` handler) carrying `.keyboardShortcut(...)` whose action wraps its state change in `withAnimation`, or whose result view has a `.transition`. (Raycast has no open/close animation, which is correct for something used hundreds of times a day.)

Valid purposes for motion: spatial consistency, state indication, explanation, feedback, preventing jarring change. "It looks cool" on a frequently-seen element is not valid.

## System motion stays system (native-specific)

Emil's durations and curves are for **custom** components. `NavigationStack` push/pop, `.sheet`, `.fullScreenCover`, `.popover`, `Menu`, `.confirmationDialog`, `.alert`, `TabView`, and the keyboard already have motion users know by muscle memory, and that motion already follows Reduce Motion. Don't retime or re-curve it, and don't hand-roll a replacement for it.

Findings:
- A custom "sheet" or "menu" built from an overlay plus `.transition(.move(edge: .bottom))` where `.sheet` / `Menu` would do. The native version of "use base-ui instead of hand-rolling a dropdown" is "use the system component".
- `withTransaction` / `transaction.disablesAnimations` or `UIView.setAnimationsEnabled(false)` used to strip system push/sheet motion, or a custom `UIViewControllerAnimatedTransitioning` replacing a standard push with no stated reason.
- A presentation's state change wrapped in `withAnimation(.emilEaseOut())` as an attempt to retime the system motion. The intent is the finding, whatever the result.

Allowed: system-provided hooks that keep system timing, such as `.navigationTransition(.zoom(sourceID:in:))` with `.matchedTransitionSource(id:in:)` (iOS 18) and `.presentationDetents`.

## Easing

Decision order:
- Entering or exiting → **ease-out** (starts fast, feels responsive): `.emilEaseOut()`
- Moving / morphing on screen → **ease-in-out**: `.emilEaseInOut()`
- Pointer hover / color change → **CSS `ease`**: `.emilEase()`, which is `.timingCurve(0.25, 0.1, 0.25, 1, duration:)` (CSS `ease`'s control points; there's no SwiftUI built-in with that name)
- Constant motion (marquee, progress) → **`.linear`**
- Default → **ease-out**

**Never `.easeIn` on UI** (same for `UIView.AnimationOptions.curveEaseIn` and `CAMediaTimingFunctionName.easeIn`). It starts slow, delaying the exact moment the user is watching. Ease-out at 200 ms *feels* faster than ease-in at 200 ms.

Springs are the default for anything touchable or reversible (`.spring(.emilUI)`, `.smooth`, `.snappy`); the curves below are for fixed one-shots. The built-in `.easeOut` / `.easeInOut` / `.default` are too weak for deliberate motion, as are CSS's built-ins. Use the strong curves from `tools/Motion.swift`:

```swift
// Emil's three web curves, ported 1:1 with timingCurve (same values as tools/Motion.swift).
enum CurveReference {
    static let easeOut = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)      // strong ease-out for UI
    static let easeInOut = Animation.timingCurve(0.77, 0, 0.175, 1, duration: 0.3)  // strong ease-in-out for on-screen movement
    static let drawer = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.5)      // iOS-like drawer curve (Ionic)
    static let cssEase = Animation.emilEase(0.2)                                    // CSS `ease` = timingCurve(0.25, 0.1, 0.25, 1), hover/color only
}
```

Find curves at [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/) (they give cubic-bezier control points, which drop straight into `timingCurve`). Don't hand-roll from scratch.

## Duration

| Element | Duration |
| --- | --- |
| Button press feedback | 100–160 ms (`0.1`–`0.16`) |
| Tooltips, small popovers (custom) | 125–200 ms (`0.125`–`0.2`) |
| Dropdowns, selects (custom) | 150–250 ms (`0.15`–`0.25`) |
| Modals, drawers (custom) | 200–500 ms (`0.2`–`0.5`) |
| Marketing / explanatory | Can be longer |

**Rule: UI animations stay under 300 ms. Modals, drawers, sheets, and toasts are the documented exceptions** (modals and drawers up to 500 ms; toasts follow Sonner's 400 ms `ease`, a web-origin value, see Cohesion). A 180 ms dropdown feels more responsive than a 400 ms one. Faster spinners make load feel faster (same actual time). Instant tooltips after the first (skip delay + animation) make a toolbar feel faster; on iOS that applies to custom hover UI on iPad/Mac only (see No native equivalent).

The budgets don't apply to system components; their timing is the system's.

## Physicality

- **Never from scale 0.** `.scaleEffect(0)` or `.transition(.scale)` (whose default scale is 0) look like they come from nowhere. Start from 0.9–0.97 plus opacity: `.transition(.scale(scale: 0.95).combined(with: .opacity))`.
- **Origin-aware popovers.** A custom popover or dropdown scales from its trigger, not center: pass `anchor:` to `.scaleEffect` or `.scale(scale:anchor:)`. The system `.popover` already anchors to its source; leave it alone. **Modals are exempt**: they appear centered, so `.center` is correct there.
- **Button press feedback.** Scale 0.97 on touch-down, 160 ms ease-out: `.buttonStyle(.pressable)` from `tools/Motion.swift`. Subtle (0.95–0.98). Applies to any pressable element. `configuration.isPressed` flips on touch-down, so the feedback fires on press, not on release; `onTapGesture` + `withAnimation` fires on release and is a finding.

```swift
struct AnchoredMenu: View {
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Filter") {
                withAnimation(.emilEaseOut(0.2)) { isOpen.toggle() }
            }
            .buttonStyle(.pressable)

            if isOpen {
                VStack(alignment: .leading) {
                    Text("Newest")
                    Text("Oldest")
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 12))
                // Grows from the trigger's corner, from 0.95 not 0. Reduce Motion: fade only.
                .transition(reduceMotion ? .opacity : .scale(scale: 0.95, anchor: .topLeading).combined(with: .opacity))
            }
        }
    }
}
```

## Springs

Springs feel natural because they simulate physics; they settle on parameters rather than a fixed duration. Use for: drag with momentum, "alive" elements (Dynamic Island), interruptible gestures, decorative pointer-tracking.

```swift
enum SpringReference {
    // Apple-style (easier to reason about), recommended. Emil's web value: { duration: 0.5, bounce: 0.2 }
    static let apple = Animation.spring(duration: 0.5, bounce: 0.2)
    // Roughly the same spring in the response/damping form.
    static let appleResponse = Animation.spring(response: 0.5, dampingFraction: 0.8) // ≈ the line above
    // Traditional physics (more control). Emil's web value: { mass: 1, stiffness: 100, damping: 10 }
    static let physics = Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 10)
    // House defaults from tools/Motion.swift.
    static let ui = Animation.spring(Spring.emilUI)
    static let momentum = Animation.spring(Spring.emilMomentum)
}
```

Keep bounce subtle (0.1–0.3); avoid bounce in most UI. Reserve it for drag-to-dismiss and playful interactions. `.bouncy` on a dashboard control is a cohesion finding. Springs merge when interrupted and hand their velocity to the new target. Timing curves don't merge: the old curve keeps playing and the new one adds on top, so motion stays continuous but the old curve plays out, which feels sluggish or overshoots on a reversal. `keyframeAnimator` rebuilds from the current value and keeps velocity, but plays its authored track and can't follow a changing target. So springs are the tool for gestures users may reverse mid-motion.

Pointer-following (iPad trackpad, Mac): don't tie the value straight to the pointer location (direct is artificial, no momentum). Store the target and let a spring chase it. Only do this when the motion is decorative.

```swift
struct TiltCard: View {
    @State private var tilt: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.blue.gradient)
            .frame(width: 240, height: 160)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : tilt), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(duration: 0.5, bounce: 0.2), value: tilt)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location): tilt = (location.x - 120) * 0.1
                case .ended: tilt = 0
                }
            }
            .accessibilityHidden(true) // decorative
    }
}
```

## Interruptibility

Nothing in SwiftUI jumps when it's interrupted, but the behaviours differ. **Springs merge: the new target takes over the old velocity. Timing curves stack:** the old curve keeps playing and the new one adds on top, so motion stays continuous but the old curve still finishes its run, which feels sluggish or overshoots on a reversal. `keyframeAnimator` and `phaseAnimator` are SwiftUI's "keyframes": a re-triggered `keyframeAnimator` rebuilds its track from the current value and keeps velocity, but it plays an authored track and can't follow a changing target. UIKit: use `UIViewPropertyAnimator` (pausable, reversible, scrubbable) for gesture-driven or reversible motion.

Rule: springs (or state-driven timing curves) for anything triggered rapidly or reversible mid-motion (toasts, toggles, drags, expand/collapse). Keyframe/phase animators only for fixed, authored sequences, never on gestures or state that retargets.

```swift
// Interruptible: good for dynamic UI. Each new toast retargets from where the stack is now.
struct ToastStack: View {
    @State private var toasts: [UUID] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toasts, id: \.self) { _ in
                Text("Saved")
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.regularMaterial, in: .capsule)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
            Button("Save") {
                withAnimation(.spring(duration: 0.4, bounce: 0)) { toasts.append(UUID()) }
            }
        }
    }
}
```

A `keyframeAnimator` toast is the wrong tool here: a re-trigger starts from the current value, but each toast plays the same authored path to a fixed point instead of following the stack as it reflows.

Entry: put the view inside an `if`, give it a `.transition(...)`, and make the state change in `withAnimation`. That's the native `@starting-style`. Don't use the `onAppear { mounted = true }` hack (the SwiftUI twin of the legacy `useEffect` + `data-mounted` fallback): it adds a frame at the hidden state and hides the start state in a flag.

## Asymmetric timing

Slow where the user is deciding, fast where the system responds.

```swift
struct HoldToDelete: View {
    @State private var progress: CGFloat = 0
    @State private var deletions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onDelete: () -> Void = {}

    var body: some View {
        Text("Hold to delete")
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(.red.opacity(0.15), in: .capsule)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule().fill(.red.opacity(0.35))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .onLongPressGesture(minimumDuration: 2) {
                deletions += 1
                onDelete()
            } onPressingChanged: { pressing in
                if pressing {
                    // Press: slow, deliberate, linear. 2 s. Kept under Reduce Motion: it's a progress
                    // indicator in place, not travel (there's no press scale here to drop).
                    withAnimation(.linear(duration: 2)) { progress = 1 }
                } else {
                    // Release: fast snap-back. 200 ms ease-out.
                    withAnimation(reduceMotion ? nil : .emilEaseOut(0.2)) { progress = 0 }
                }
            }
            // One haptic, on the causal event: the delete.
            .sensoryFeedback(.impact(weight: .medium), trigger: deletions)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Delete")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onDelete() } // default action: VoiceOver's double-tap deletes
    }
}
```

(The fill animates `frame` width inside an overlay, a deliberate exception like clip-path on the web; a `.mask` with an animated offset works too.)

## Performance

- **Prefer render-time effects: `offset`, `scaleEffect`, `rotationEffect`, `opacity`.** Animating `frame`, `padding`, font size, or an `HStack`'s spacing re-runs layout every frame. Same advice as the web's "transform and opacity", different pipeline. Masks and a measured-height accordion (`.frame(height:)` on a disclosure, or `DisclosureGroup`) are the documented exceptions.
- **Broad animation is the `transition: all` of SwiftUI.** `withAnimation { ... }` around a state change that several views read, or `.animation(.x, value:)` placed high in the tree (on a whole screen or a `List`), animates every change in that transaction, including ones you didn't intend. The deprecated `.animation(_:)` without `value:` is worse: it animates every change, forever. Scope with `.animation(_:value:)` on the view that changes, or `.animation(_:body:)` (iOS 17) to limit it to specific modifiers.

```swift
// Before: one animation for the whole screen. Every change in `items` and `isEditing` animates.
struct ScreenBroad: View {
    @State private var isEditing = false
    @State private var items = ["A", "B", "C"]

    var body: some View {
        VStack {
            ForEach(items, id: \.self) { Text($0) }
            Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
        }
        .animation(.easeInOut(duration: 0.4), value: isEditing)
        .animation(.easeInOut(duration: 0.4), value: items)
    }
}
```

```swift
// After: only the badge's scale and opacity animate, only when isEditing changes.
struct ScreenScoped: View {
    @State private var isEditing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            Text("Inbox")
            Image(systemName: "minus.circle.fill")
                .animation(.emilEaseOut(0.2)) { content in
                    content
                        .scaleEffect(isEditing || reduceMotion ? 1 : 0.95)
                        .opacity(isEditing ? 1 : 0)
                }
            Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
        }
    }
}
```

- **Don't put per-frame state high in the tree or in the environment.** A drag offset stored on a parent (or in an `@Observable` model many views read, or pushed through `.environment`) re-evaluates whole subtrees every frame. That's the SwiftUI version of updating a CSS variable on a parent. Keep per-frame state in the view that moves (`@GestureState`, `@State`).

```swift
// Good: the drag offset lives in the card that moves; the parent never re-evaluates per frame.
struct SwipeCard: View {
    // The reset springs home; tracking stays 1:1. (An `.animation(_, value: drag == .zero)` would
    // also animate the first tracking update, when the Bool flips, so the card lags the finger.)
    @GestureState(resetTransaction: Transaction(animation: .spring(Spring.emilUI)))
    private var drag: CGSize = .zero

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.orange)
            .frame(height: 120)
            .offset(x: drag.width)
            .gesture(DragGesture().updating($drag) { value, state, _ in state = value.translation })
    }
}
```

- **Keep the main thread free during transitions.** SwiftUI evaluates its animations in-process, per frame, so a busy main thread (decoding, layout of a huge list, synchronous I/O kicked off in the same action) hitches them. Core Animation (`UIView.animate`, `CALayer` animations) commits to the render server. Rule: start heavy work after, or off, the main actor; measure hitches in Instruments (SwiftUI / Animation Hitches templates).
- **Matched geometry and layout animations re-run layout**: `matchedGeometryEffect` and animated `frame` changes cost layout every frame. Fine for occasional moments; a finding on something that runs while the screen is busy.
- Keep transition-time blur small (`.blur(radius:)` well under 20 pt): blur renders offscreen.

## Transforms & masks

- **Own-size offsets.** `.transition(.move(edge: .bottom))` moves a view by its own size, the native `translateY(100%)` (how Sonner and Vaul position toasts and drawers on the web). For a custom fraction of its own size, read it in `.visualEffect { content, proxy in content.offset(y: proxy.size.height) }`. Prefer these to hardcoded point offsets.
- **`scaleEffect` scales children too** (text, icons, content): a feature for press feedback.
- **3D**: `.rotation3DEffect(_:axis:perspective:)` for flips and depth. There's no real z-sorting between siblings, unlike `preserve-3d`.
- **Masks are the native `clip-path: inset()`**: a `.mask { }` with an animated frame or offset, or a custom `Shape` with `animatableData`. Uses: reveal-on-scroll, hold-to-delete overlay, seamless tab color transitions (duplicate and mask the active copy), comparison sliders.

```swift
// A reveal that "eats in" from the bottom, like clip-path: inset(0 0 100% 0) → inset(0).
struct InsetReveal: Shape {
    var bottomInset: CGFloat // 0...1 of the height
    var animatableData: CGFloat {
        get { bottomInset }
        set { bottomInset = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * (1 - bottomInset)))
    }
}

struct RevealedHeadline: View {
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Ship faster")
            .font(.largeTitle.bold())
            .clipShape(InsetReveal(bottomInset: revealed || reduceMotion ? 0 : 1))
            .opacity(reduceMotion && !revealed ? 0 : 1)
            .onScrollVisibilityChange(threshold: 0.5) { visible in
                if visible && !revealed {
                    withAnimation(.emilEaseInOut(1.0)) { revealed = true }
                }
            }
    }
}
```

## Gestures & drag

- **Momentum dismissal**: don't require crossing a distance threshold. Read `DragGesture.Value.velocity` (iOS 17, **pt/s**) and dismiss above **~500 pt/s** release velocity. (Emil's 0.11 px/ms, ≈ 110 pt/s, is Sonner's *average* over the whole drag, distance ÷ elapsed time, not the release velocity: never compare `value.velocity` with 110.) A flick should be enough. Project where a throw would land with `project(velocity:)` or `predictedEndTranslation`.
- **Damping at boundaries**: dragging past a natural edge moves less the further you go. Apply `rubberband(_:dimension:)` in `.onChanged`.
- **Friction over hard stops**: allow over-drag with rising resistance rather than an invisible wall (`min`/`max` clamps in `.onChanged` are the wall).
- **Velocity handoff**: on release, `.interpolatingSpring(..., initialVelocity:)` with relative velocity `gestureVelocity / (target − current)`, so the settle continues the throw.
- Pointer capture and multi-touch guards: see No native equivalent.

```swift
struct DismissableSheetCard: View {
    @State private var offset: CGFloat = 0
    @State private var dragStart: CGFloat?
    @State private var isDismissed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !isDismissed {
            RoundedRectangle(cornerRadius: 24)
                .fill(.background)
                .frame(height: 300)
                .offset(y: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let start = dragStart ?? offset // grab mid-spring without a jump
                            dragStart = start
                            let y = start + value.translation.height
                            // Free downward, rubber-banded upward.
                            offset = y >= 0 ? y : rubberband(y, dimension: 300)
                        }
                        .onEnded { value in
                            dragStart = nil
                            let velocity = value.velocity.height              // release velocity, pt/s
                            let dismiss = velocity > 500 || offset > 150
                            let target: CGFloat = dismiss ? 600 : 0           // shortcut: fixed travel past the card
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
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                .accessibilityAction(named: "Dismiss") { withAnimation(.emilEaseOut(0.2)) { isDismissed = true } }
        }
    }
}
```

## Masking imperfect crossfades

When a crossfade shows two overlapping states despite tuning easing and duration, add a subtle blur during the transition so the two read as one transformation: `.transition(.blurReplace)` (iOS 17), or `.blur(radius: 2)` driven by the same state. For text and symbols, prefer `.contentTransition(.numericText(value:))` / `.contentTransition(.symbolEffect(.replace))`, which morph instead of double-exposing. Keep blur small (< 20 pt): it renders offscreen.

```swift
struct SaveButtonLabel: View {
    @State private var saved = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(.emilEaseOut(0.2)) { saved.toggle() }
        } label: {
            Group {
                if saved { Label("Saved", systemImage: "checkmark") } else { Label("Save", systemImage: "square.and.arrow.down") }
            }
            // blurReplace blurs *and scales*, so Reduce Motion falls back to a plain fade.
            .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
        }
        .buttonStyle(.pressable)
        .sensoryFeedback(.success, trigger: saved)
    }
}
```

## Stagger

Stagger group entrances; 30–80 ms (`0.03`–`0.08`) between items. Longer delays feel slow. Stagger is decorative: never block interaction while it plays. For group entrances, follow `../choreograph/SKILL.md` (one entrance per container, non-uniform delays).

```swift
struct StaggeredList: View {
    let items = ["Inbox", "Drafts", "Sent", "Archive"]
    let delays: [Double] = [0, 0.05, 0.09, 0.12] // non-uniform, front-loaded
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown || reduceMotion ? 0 : 8)
                    .animation(.emilEaseOut(0.3).delay(reduceMotion ? 0 : delays[index]), value: shown)
            }
        }
        .onAppear { shown = true }
    }
}
```

(Here the list is part of the screen, so `onAppear` triggers the entrance itself. That's different from the mounted-flag hack for a view's own insertion, which a `.transition` covers.)

## Accessibility

- **Reduce Motion**: `@Environment(\.accessibilityReduceMotion)` (UIKit: `UIAccessibility.isReduceMotionEnabled`). **Custom animations don't opt out on their own.** System components adapt; your `withAnimation`, `.transition`, `.offset`, `.scaleEffect`, `phaseAnimator`, `keyframeAnimator`, `UIView.animate`, and `CABasicAnimation` code does not. Every custom animation that moves something must branch.
- Reduced motion means fewer and gentler animations, **not zero**: keep opacity and color, drop position, scale, and 3D changes. A reduced-motion branch that passes `nil` to every animation (killing press feedback and fades too) is itself a finding.
- **Hover**: touches don't fire `.onHover` / `.onContinuousHover`, so there's no false-hover-on-tap to gate. Hover is pointer-only (iPad trackpad, Mac), so it must never be the only affordance. Prefer the system `.hoverEffect`.
- Haptics: `.sensoryFeedback(_:trigger:)` on the same state change that drives the animation, so both land on the same frame.

```swift
struct SidePanel: View {
    @Binding var isOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if isOpen {
            Rectangle()
                .fill(.regularMaterial)
                .frame(width: 280)
                // Full motion: slides from the leading edge. Reduce Motion: fades in place.
                .transition(reduceMotion ? .opacity : .move(edge: .leading).combined(with: .opacity))
        }
    }
}
```

## Debugging (recommend in reviews when feel is uncertain)

- **Slow motion**: Simulator ▸ Debug ▸ Slow Animations, or bump the duration 2–5× temporarily. Check colors crossfade cleanly, easing doesn't stop abruptly, the `anchor` is right, coordinated properties stay in sync.
- **Frame-by-frame / timing**: Instruments ▸ SwiftUI and Animation Hitches templates show drift and dropped frames; Xcode previews for quick iteration.
- **Real devices** for gestures (drawers, swipe) and haptics: the Simulator has no haptics, no real touch latency, no ProMotion.
- **Fresh eyes next day**: imperfections invisible during development surface later.

## Cohesion

Match motion to the component's personality: playful can be bouncier; a professional dashboard should be crisp and fast. Sonner (a web library) feels right partly because easing, duration, design, and even the name are in harmony: slightly slower, `ease` rather than ease-out, to feel elegant. The direct port of its toast timing is `.emilEase(0.4)` (CSS `ease`, `timingCurve(0.25, 0.1, 0.25, 1)`). Opacity + height in entering/exiting lists is trial and error; there's no formula. Adjust until it feels right.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Motion `x`/`y`/`scale` shorthands before `motion` 14.2; full `transform` string workaround | Library-version caveat for a React library | None needed. In SwiftUI the cost question is layout vs render-time effects (see Performance) |
| WAAPI (`element.animate`) for JS control with CSS performance | Browser API | `UIView.animate` / `CABasicAnimation` when you need Core Animation's render-server playback; otherwise plain SwiftUI state animation |
| "CSS animations run off the main thread, beat rAF under load" | Browser pipeline | Reframed: SwiftUI animations evaluate per frame in-process, so keep the main thread free during transitions and measure in Instruments |
| `@media (hover: hover) and (pointer: fine)` gate on hover motion | Touch doesn't fire SwiftUI hover, so there's no false positive to gate | Never make hover the only affordance; prefer `.hoverEffect` |
| Pointer capture once dragging starts | A SwiftUI gesture keeps tracking after the finger leaves the view's bounds | None needed |
| Multi-touch guard (`if (isDragging) return`) | `DragGesture` follows one touch | Only custom `UIGestureRecognizer` code needs a guard |
| Instant subsequent tooltips (skip delay + animation) | `.help()` timing belongs to the system (pointer only); no tooltips on touch | The principle stays for custom hover UI on iPad/Mac |
| DevTools Animations panel, Safari remote devtools, hitting the dev server by IP | Browser tooling | Simulator Slow Animations, Instruments, Xcode previews, run on a device from Xcode |
| `transform-origin: var(--transform-origin)` (Base UI) | React library variable | `anchor:` on scale effects and transitions; the system `.popover` already anchors |
