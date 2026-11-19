---
name: gestures
description: Build drag, swipe, and sheet interactions in SwiftUI that track the finger 1:1 and stay interruptible. Use when building or fixing anything the user drags, swipes, flings, holds, or dismisses with a gesture on iOS — custom drawers and sheets, presentationDetents, swipe-to-dismiss toasts and cards, drag-to-reorder, pull-to-refresh, hold-to-confirm, haptics on snap — or when a DragGesture feels laggy, trails the finger, jumps on release, ignores a flick, or can't be caught mid-animation. Triggers on — DragGesture, @GestureState, gesture velocity, predictedEndTranslation, interpolatingSpring, sheet, presentationDetents, snap points, rubber-band, sensoryFeedback, onLongPressGesture, swipeActions, refreshable, "doesn't follow my finger", "jumps when I let go", "can't grab it mid-animation".
---

# Gesture-Driven UI

> Adapted from Emil Kowalski's [`gestures`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/gestures) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

How to build gestures that feel physical. A gesture is direct manipulation: while the finger is down, the UI is the finger; the moment it lifts, physics takes over. Every rule below follows from that split.

Shared tokens (`.emilEaseOut()`, `.emilDrawer()`, `Spring.emilUI`, `Spring.emilMomentum`, `project(velocity:)`, `rubberband(_:dimension:)`) live in [`tools/Motion.swift`](https://raw.githubusercontent.com/OrenSegal/emil-design-swiftui/main/tools/Motion.swift).

## First decision: build it, or use what the system ships?

Doing a drawer gesture *right* means momentum-based dragging, overlay opacity matched to drag progress, velocity-aware dismissal, focus trapping, and an escape route. That is weeks of edge cases, not an afternoon. On the web Emil's answer is Vaul, which exists precisely because this is hard to hand-roll. On iOS the answer is the system: it already ships most of these interactions, correct, with the muscle memory users bring from every other app.

| Interaction | Use | Hand-roll only when |
| --- | --- | --- |
| Bottom sheet / drawer | `.sheet` + `.presentationDetents` | See "When a custom sheet is warranted" below |
| Swipe a list row to reveal actions or delete | `.swipeActions` on `List` rows | The swipe commits something different in kind (swipe-to-archive with momentum, a card stack) |
| Pull to refresh | `.refreshable` | It's a signature interaction, not plumbing |
| Drag to reorder | `List` + `.onMove`, or `.draggable` / `.dropDestination` | Free-form canvas reordering |
| Paging / snapping carousel | `ScrollView` + `.scrollTargetBehavior(.paging)` or `.viewAligned` | Never, for a plain carousel: the system's deceleration is the one users know |
| Press-and-hold preview / menu | `.contextMenu(menuItems:preview:)` | Never |
| Card that expands into a screen and drags back | `.matchedTransitionSource` + `.navigationTransition(.zoom(...))` | Never; the interactive dismiss comes with it |

Build the gesture yourself only when nothing above covers the interaction (custom swipe cards, bespoke drag interactions, an in-screen drawer). When unsure, read `../pick-ui-library/SKILL.md`.

### The system sheet, configured properly

```swift
struct FiltersHost: View {
    @State private var showFilters = false
    @State private var contentHeight: CGFloat = 300

    var body: some View {
        Button("Filters") { showFilters = true }
            .sheet(isPresented: $showFilters) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filters").font(.headline)
                    Toggle("In stock only", isOn: .constant(true))
                    Toggle("Free shipping", isOn: .constant(false))
                }
                .padding()
                // Measure, don't hardcode: Dynamic Type changes the height.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .presentationDetents([.height(contentHeight), .large])
                .presentationDragIndicator(.visible)
                // A parallel, non-blocking panel: no dimming up to the first detent.
                .presentationBackgroundInteraction(.enabled(upThrough: .height(contentHeight)))
                // Scrolling content scrolls first; the sheet resizes only from its edges.
                .presentationContentInteraction(.scrolls)
            }
    }
}
```

The system sheet gives you velocity-aware detent snapping, grab-mid-flight, the scrim, the parent push-back for stacked sheets, VoiceOver focus containment, and Reduce Motion handling. Don't retime it.

Two details from the platform's own sheet:

- **There is no "fit to contents" detent.** Measure the content (as above) and pass `.height(_:)`. Content with no intrinsic height (a `ScrollView` root, a view that only `maxHeight: .infinity`) has nothing to measure.
- **The grabber is not the only affordance.** `.presentationDragIndicator(.visible)` tells sighted touch users it drags; a visible Done/Close button serves everyone else.

### When a custom sheet is warranted

- The drawer **lives inside a screen's layout** and is never "presented" (a Maps-style persistent panel the user works around). `presentationBackgroundInteraction` plus `interactiveDismissDisabled()` covers a lot of this, so try it first.
- It's a **small floating drawer** not attached to the screen edge.
- Something **behind it must move with it**, linked to drag progress, in a way the system sheet doesn't do.
- The snap physics or detent logic is the product (a bespoke card stack, a game piece).

If none of those hold, use `.sheet`.

## The two phases of every gesture

Walk this split for any gesture you build. Mixing the phases up is the #1 cause of gestures that feel wrong.

```
Is the finger currently down?
├── Yes → TRACK phase (.onChanged / .updating): position maps 1:1 to the finger.
│         No easing. No duration. No spring. No withAnimation. The view IS the finger.
└── No  → RELEASE phase (.onEnded): physics finishes the motion.
          A spring seeded with the release velocity, or a timing curve
          when there is no velocity to carry (button-driven, hold-to-confirm). Never a keyframe.
```

### Track phase rules

- **1:1 means 1:1.** Write the translation straight into `@GestureState` or a local `@State` with no animation. The classic SwiftUI bug is an `.animation(.spring, value: offset)` on the dragged view: it catches every drag update and makes the view trail the finger, like dragging something through syrup. Animate only inside `.onEnded`.
- **Respect the grab offset.** Move the view by `value.translation`, added to where it was when the drag began, never by `value.location`. Positioning by `location` snaps the view's center to the finger on the first frame and breaks the illusion.
- **Keep per-frame state in the view that moves.** Emil's web rule is "write `transform` on the dragged element, never a CSS variable on a parent", because Vaul's drag got laggy past ~20 list items when it drove children through an inherited variable. The SwiftUI version: don't push the drag value into an `@Observable` model, the environment, or a parent's `@State`. Every view that reads it re-evaluates its body every frame. Keep it local and apply it with `.offset`.
- **State per move is the mechanism here, so make it cheap.** React's advice is "no state per pointermove". In SwiftUI, gesture updates *are* state updates; the cost is the body that re-evaluates. Keep the dragged view's body small, pass heavy content in as a stored subview, and move it with render-time effects (`.offset`, `.scaleEffect`, `.opacity`), never `.frame` or `.padding`, which re-run layout every frame. Measure in Instruments (SwiftUI template, Animation Hitches).
- **Rubber-band at the edges.** Dragging past a boundary should move the view a fraction of the distance, not stop dead. Hard stops feel like hitting a wall; resistance says "there's nothing further" physically. Emil's web value is Motion's `dragElastic` ≈ 0.2 (a constant fraction: `overshoot * 0.2`). Apple's version, `rubberband(_:dimension:)` in Motion.swift, resists progressively and never exceeds `dimension`. The examples below use Apple's.

### Release phase rules

- **Custom drags finish with a spring, seeded with the gesture's velocity.** The view should leave the finger at the speed it was moving. A fixed-duration ease here makes every fling land identically, which reads as fake. `DragGesture.Value.velocity` is in **pt/s**. Hand it to `.interpolatingSpring(_:initialVelocity:)`, which takes velocity *relative to the remaining distance*: `velocity / (target − current)`. (The SDK doc gives the unit: the spring produces unit-range values that interpolate the property's from→to range, and the `duration:bounce:` / `mass:stiffness:damping:` overloads describe `initialVelocity` as a [0, 1] value "representing the magnitude of the value being animated". The normalization follows from that; the doc doesn't write the formula out.) Guard the divide when the remaining distance is near zero.
- **Dismiss on distance OR velocity.** Passing a distance threshold (~40–50% of travel) dismisses, and so does a fast flick over a short distance: Emil's Motion example uses `velocity > 500` (px/s, so 500 pt/s). Read both from `.onEnded`: `value.translation` and `value.velocity`. Or fold them into one test by projecting the release (`current + project(velocity:)`) and comparing the projection to the threshold. Distance-only thresholds make flicks feel ignored. (Emil's other velocity form, distance ÷ elapsed time > ~0.11 px/ms, is ≈ 110 pt/s averaged over the whole drag; `value.velocity` is the release velocity, so the two numbers are not interchangeable.)
- **Bounce belongs only at the end of a drag.** A drag applies force, like throwing a ball at a wall, so a slight bounce on release feels physical. The same view closed by a button press gets **zero** bounce: no force was applied. Keep bounce at 0.1–0.3 (`Spring(duration:bounce:)`), and remember bounce scales inversely with view size: smaller views need more bounce to read the same.
- **Dismissal doesn't overshoot.** A view leaving the screen settles critically damped (`Spring.emilUI`), or it springs back past the edge and flashes a gap.
- **Snap-back is fast.** If the gesture doesn't pass the threshold, return quickly with the spring. A slow snap-back feels like the UI is disagreeing with the user in slow motion.

### The canonical drag: swipe-to-dismiss toast

Sonner's toast enters from the bottom, so it dismisses downward (see *Spatial consistency*).

```swift
struct SwipeToDismissToast: View {
    let message: String
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var dragStart: CGFloat?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // shortcut: fixed travel, measure the toast's height + bottom safe-area inset for real use.
    private let travel: CGFloat = 160

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
            .offset(y: offset)
            // Linked value: fades with the same offset that moves it, so the two can't drift apart.
            .opacity(1 - Double(min(max(offset, 0) / travel, 1)))
            .gesture(
                DragGesture() // minimumDistance defaults to 10 pt: intent before commitment
                    .onChanged { value in
                        let start = dragStart ?? offset // where it was when the finger landed
                        dragStart = start
                        let next = start + value.translation.height
                        // Down is the exit axis and tracks 1:1; up has nowhere to go, so it resists.
                        offset = next >= 0 ? next : rubberband(next, dimension: 60)
                    }
                    .onEnded { value in
                        dragStart = nil
                        let velocity = value.velocity.height // pt/s
                        let dismiss = offset > travel * 0.5 || velocity > 500
                        settle(to: dismiss ? travel : 0, velocity: velocity, dismiss: dismiss)
                    }
            )
            .accessibilityElement(children: .combine)
            // The swipe is not the only way out.
            .accessibilityAction(named: "Dismiss") { onDismiss() }
    }

    private func settle(to target: CGFloat, velocity: CGFloat, dismiss: Bool) {
        let remaining = target - offset
        let relative = abs(remaining) > 1 ? velocity / remaining : 0
        let animation: Animation =
            if reduceMotion {
                .emilEaseOut(0.2) // short and plain: no fling, no bounce
            } else if dismiss {
                .interpolatingSpring(.emilUI, initialVelocity: relative) // no overshoot back into view
            } else {
                .interpolatingSpring(Spring(response: 0.3, dampingRatio: 0.8), initialVelocity: relative)
            }
        withAnimation(animation) { offset = target } completion: {
            if dismiss { onDismiss() }
        }
    }
}
```

## Interruptibility is non-negotiable

The user must be able to catch a sheet mid-close and drag it back. Springs allow this: when retargeted mid-flight they merge and keep their current velocity, so the redirect is seamless. `keyframeAnimator` and `phaseAnimator` play an authored track: a re-triggered `keyframeAnimator` rebuilds from the current value and keeps velocity, but it can't follow a changing target like a finger, so it can't be caught. That is the SwiftUI form of Emil's `@keyframes` lesson: Sonner's early CSS enter animation made toasts jump when a second toast arrived. **Never use a keyframe or phase animator on anything a gesture can touch.** Springs only (timing curves for button-driven changes that no finger interrupts).

One SwiftUI-specific gap you have to know about: **SwiftUI doesn't expose the presentation (on-screen) value.** In the examples here, `dragStart = offset` reads the *model* value, which during a release animation is already the target. What a non-animated drag update does to an in-flight spring, and so whether a mid-flight grab tracks cleanly, jumps, or drifts, is not documented. Test it on a device by grabbing the view mid-release. If it misbehaves, don't make the track phase a spring by default (that breaks 1:1). The options are:

1. Accept it where the release is short (a 0.3 s toast is rarely caught).
2. Use the system sheet or `ScrollView`, which handle the catch natively. This is the strongest reason to prefer them.
3. Drop to UIKit (`UIViewPropertyAnimator` is pausable and scrubbable, and a layer's `presentation()` is readable) for the one interaction that needs it.

## Linked values

The dragged view is rarely alone: an overlay fades, the page behind scales. Derive these from drag progress in `body`. Don't animate them separately:

```swift
struct DimmingOverlay: View {
    let drawerOffset: CGFloat // 0 = open, drawerHeight = closed
    let drawerHeight: CGFloat

    var body: some View {
        Color.black
            .opacity(0.4 * (1 - min(max(drawerOffset / drawerHeight, 0), 1)))
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
```

One source of truth means the overlay is always exactly as faded as the drawer is dismissed: mid-gesture, when the user reverses, and during the release spring (the release animation drives `drawerOffset`, so the overlay rides the same spring). Two separate animations drift apart the moment a gesture is interrupted.

## A custom snap-point drawer

The full recipe for when a custom sheet is warranted: 1:1 tracking, rubber-band past both ends, a momentum-projected detent choice, velocity handoff, a linked scrim, a haptic when a new detent catches, Reduce Motion, and a VoiceOver/Switch Control path that never touches the gesture.

```swift
struct SnapDrawer<Content: View>: View {
    /// Visible heights the drawer rests at, smallest first.
    var detents: [CGFloat] = [120, 360, 640]
    @ViewBuilder var content: Content

    @State private var height: CGFloat = 120
    @State private var dragStart: CGFloat?
    @State private var detentIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bleed: CGFloat = 80 // panel extends this far below the largest detent, so overshoot never shows a gap
    private var minH: CGFloat { detents.first ?? 0 }
    private var maxH: CGFloat { detents.last ?? 0 }
    private var progress: Double { maxH > minH ? Double(min(max((height - minH) / (maxH - minH), 0), 1)) : 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3 * progress) // linked to `height`, never animated on its own
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                grabber
                content
            }
            .frame(maxWidth: .infinity)
            .frame(height: maxH + bleed, alignment: .top)
            .background(.regularMaterial, in: .rect(topLeadingRadius: 16, topTrailingRadius: 16))
            .offset(y: maxH + bleed - height) // move with offset, not frame: no layout per frame; the bleed hangs off-screen
            .gesture(drag)
            .sensoryFeedback(.impact(weight: .light), trigger: detentIndex) // a new detent caught
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var grabber: some View {
        Capsule()
            .fill(.secondary)
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity, minHeight: 44) // 44 pt target around a 5 pt visual
            .contentShape(.rect)
            .accessibilityElement()
            .accessibilityLabel("Drawer")
            .accessibilityValue("\(detentIndex + 1) of \(detents.count)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: snap(to: detentIndex + 1)
                case .decrement: snap(to: detentIndex - 1)
                @unknown default: break
                }
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                let start = dragStart ?? height
                dragStart = start
                let proposed = start - value.translation.height // finger up = taller
                height = if proposed > maxH {
                    maxH + rubberband(proposed - maxH, dimension: bleed)
                } else if proposed < minH {
                    minH - rubberband(minH - proposed, dimension: bleed)
                } else {
                    proposed
                }
            }
            .onEnded { value in
                dragStart = nil
                let velocity = -value.velocity.height // pt/s, up = positive
                // Choose the detent nearest where the flick was going, not where it was released.
                let projected = height + project(velocity: velocity)
                let index = detents.indices.min { abs(detents[$0] - projected) < abs(detents[$1] - projected) } ?? 0
                let remaining = detents[index] - height
                let relative = abs(remaining) > 1 ? velocity / remaining : 0
                let animation: Animation = reduceMotion
                    ? .emilEaseOut(0.2)
                    // Apple's drawer spring (damping 0.8, response 0.3): a drag applied force, so a little bounce.
                    : .interpolatingSpring(Spring(response: 0.3, dampingRatio: 0.8), initialVelocity: relative)
                withAnimation(animation) { height = detents[index] }
                detentIndex = index // same update as the spring start, so haptic and motion should land together (feel-check)
            }
    }

    /// Button / VoiceOver path: no force was applied, so no bounce.
    private func snap(to index: Int) {
        guard detents.indices.contains(index) else { return }
        withAnimation(reduceMotion ? .emilEaseOut(0.2) : .spring(.emilUI)) { height = detents[index] }
        detentIndex = index
    }
}
```

Two things to check on a device: the mid-flight grab (see *Interruptibility*), and whether the haptic should fire at release (the commit, as here) or when the spring arrives. Release is the causal moment, so start there.

## Gesture → animation handoff

The release is a seam. The details that hide it, beyond the rules above:

- **Capture on grab.** Record where the view was when the finger landed (`dragStart` above) and add the translation to that. Never start from 0 or from the drag's start location, or a second grab teleports the view.
- **Intent before commitment.** `DragGesture()` waits 10 pt (`minimumDistance`, default 10 in the SDK) before it starts, which is Apple's ~10 pt hysteresis. Keep it. `minimumDistance: 0` turns every tap into a drag.
- **Declare the axis.** SwiftUI has no axis lock like a pan recognizer's active offset. A plain `DragGesture` on a row inside a vertical `ScrollView` competes with the scroll. In order of preference:
  1. `.swipeActions` in a `List`.
  2. A `.simultaneousGesture` that ignores the drag until `abs(translation.width) > abs(translation.height)`.
  3. For full control, a `UIPanGestureRecognizer` through `UIGestureRecognizerRepresentable` (iOS 18), with a delegate that refuses to begin unless the velocity is horizontal.

  Option 2 can still let the scroll move alongside the swipe, so how it feels is unverified. Try it on a device.
- **`predictedEndTranslation` is a shorter throw than `project(velocity:)`.** In the iOS SDK, `velocity` is computed as `4 × (predictedEndLocation − location)`. So the prediction is the current position plus a quarter-second of the current velocity, about half what `project(velocity:)` returns at 0.998 (`UIScrollView.DecelerationRate.normal`). This is inferred from the SDK's inlined source, not documented. Either works for choosing a snap target. Pick one, keep it consistent across the app, and use `project(velocity:decelerationRate: 0.99)` (`.fast`) for snappier, shorter throws.

## Motion drag props

There's no SwiftUI equivalent of Motion's `drag` / `dragConstraints` / `dragElastic` / `dragMomentum` props. Each is a line in the examples above:

| Motion prop | SwiftUI |
| --- | --- |
| `drag="y"` | Read only `translation.height` |
| `dragConstraints={{ top: 0 }}` | Clamp in `.onChanged` (with `rubberband` past the bound) |
| `dragElastic={0.2}` | `overshoot * 0.2`, or `rubberband(_:dimension:)` |
| `dragMomentum={false}` | The default: nothing moves after `.onEnded` unless you animate it |
| `animate(y, 0, { velocity })` | `withAnimation(.interpolatingSpring(_, initialVelocity: relative))` |

## Sheets without springs: the Vaul curve

Vaul mimics the iOS sheet with pure CSS to stay small: `cubic-bezier(0.32, 0.72, 0, 1)` over **500 ms**. That is `.emilDrawer()` in Motion.swift. The curve is extremely steep at the start, which is what lets a 500 ms duration still feel snappy while it lands with a spring-like gentle settle. On iOS you rarely need it (the system sheet *is* the original). Use it for a custom edge-attached panel opened by a button, where there's no gesture velocity to carry. Two rules from it:

- A **small floating drawer** (not touching the screen edge) should override to ~200 ms. The 500 ms iOS timing only reads right on a full-width, edge-attached sheet. Vaul's override curve is `cubic-bezier(0.165, 0.84, 0.44, 1)`:

```swift
struct FloatingDrawer: View {
    @Binding var isOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            if isOpen {
                Color.black.opacity(0.3).ignoresSafeArea()
                    .onTapGesture { isOpen = false }
                    .accessibilityHidden(true)
                    .transition(.opacity)
                VStack(spacing: 12) {
                    Text("Share").font(.headline)
                    Button("Close") { isOpen = false }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: .rect(cornerRadius: 24))
                .padding()
                .accessibilityAddTraits(.isModal)
                .accessibilityAction(.escape) { isOpen = false }
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        // One timing for drawer and scrim: 200 ms, Vaul's small-drawer curve.
        .animation(.timingCurve(0.165, 0.84, 0.44, 1, duration: 0.2), value: isOpen)
    }
}
```

- **The component must feel like a single entity.** If the drawer opens in 200 ms, its height changes and content crossfades must live in the same timing family. One slow sub-animation makes the whole thing feel broken.

Vaul marks interactive children with `data-vaul-no-drag` so pressing a button inside the drawer doesn't start a drag. In SwiftUI, `Button`, `Slider`, and other controls handle their own touches, but how a parent `DragGesture` arbitrates with a drag that *starts* on a control is worth testing per control. If the drawer moves when it shouldn't, for your drawer, attach the `DragGesture` to the grabber/header region only, not to the whole panel.

## Spatial consistency

**A view dismisses in the direction it entered.** Sonner's toast slides up from the bottom, so swipe-down dismisses it. Enter and exit share one axis, which makes the gesture discoverable and intuitive without instruction. A gesture that dismisses along an axis the view never moved on has to be learned; one that reverses the entrance is *felt*. In SwiftUI: if the insertion is `.move(edge: .bottom)`, the dismiss drag is vertical and downward, and the removal transition is the same edge.

## Hold gestures are asymmetric

Hold-to-delete and similar press-and-hold interactions use **`.linear`** during the hold. The animation visualizes time passing, and time passes linearly; any other curve lies about how long is left. On release before completion, snap back fast with an ease-out. The deliberate phase is slow and honest; the cancel is instant. Symmetric timing here is a bug.

```swift
struct HoldToDelete: View {
    let onDelete: () -> Void
    var holdDuration: Double = 2 // same 2 s as every hold-to-delete in this repo

    @State private var holding = false
    @State private var deletions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Hold to delete")
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .background {
                ZStack(alignment: .leading) {
                    Capsule().fill(.red.opacity(0.55))
                    // The fill is a progress indicator in place, not travel, so it stays under Reduce Motion.
                    Capsule().fill(.red)
                        .mask(alignment: .leading) {
                            Rectangle().scaleEffect(x: holding ? 1 : 0, anchor: .leading)
                        }
                        .animation(holding ? .linear(duration: holdDuration)
                                           : (reduceMotion ? nil : .emilEaseOut(0.2)),
                                   value: holding)
                }
            }
            // No velocity handoff: nothing is thrown, the hold is pure time.
            // Feel-check: the fill should snap back after perform fires (onPressingChanged(false)).
            .onLongPressGesture(minimumDuration: holdDuration) {
                deletions += 1
                onDelete()
            } onPressingChanged: { holding = $0 }
            .sensoryFeedback(.impact(weight: .medium), trigger: deletions)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Delete")
            .accessibilityHint("Deletes immediately")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onDelete() } // VoiceOver/Switch Control: the double-tap is already deliberate
    }
}
```

## Haptics

Mobile has a sense the web doesn't. Used sparingly, haptics become the thing that makes the app feel expensive. Used everywhere, they get turned off. `.sensoryFeedback(_:trigger:)` fires when `trigger` changes, so attach it to the same state change that drives the motion.

| Moment | Feedback |
| --- | --- |
| A value ticks past a step: picker, slider detent, segmented control | `.selection` |
| Something snaps home, a sheet detent catches, a drag commits | `.impact(weight: .light)` |
| A heavy object lands, a destructive action fires | `.impact(weight: .medium)` |
| Operation succeeded or failed | `.success` / `.error` |

Three rules, and they're absolute:

- **Same frame as the visual.** A haptic that lags its animation reads as a glitch, not feedback. Fire it at the causal moment (the detent catching), not when the animation finishes: change the trigger in the same handler that starts the animation.
- **One per semantic event**: a step, a snap, a commit. Never on scroll, never per frame, never on an entrance animation the user didn't cause. For "fire once when a drag crosses a threshold", make the trigger a `Bool` derived from the drag and fire only on the rising edge with the `condition:` overload:

```swift
// fragment
.sensoryFeedback(.impact(weight: .light), trigger: pull > threshold) { _, isArmed in isArmed } // rising edge only
```

- **Never the only feedback.** Many users turn haptics off system-wide, the Simulator has none, and you shouldn't count on iPad hardware producing them. The visual has to stand alone.

## Touch checklist

Run through this for every gesture you ship:

- **Test on a real iPhone.** The Simulator has no haptics and no real touch latency, and a mouse drag lies about how a finger feels. A 60 Hz Mac display hides roughness that a 120 Hz ProMotion phone shows. On ProMotion, if a custom animation looks capped at 60 Hz, check that `CADisableMinimumFrameDurationOnPhone` is `YES` in Info.plist (it is needed for custom `CADisplayLink`/Core Animation work above 60 Hz; whether SwiftUI's own animations need it isn't clearly documented, so measure). Judge feel in a Release build: Debug builds are slower.
- **Hit targets ≥ 44×44 pt.** Grow the tappable area, not the visual: `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(.rect)` around a smaller glyph. (The web trick is an invisible `::before` that doesn't grow layout. A negative-inset `contentShape` is the nearest SwiftUI form, but whether hits outside the view's frame register is unverified. Test it before relying on it.)
- **Every gesture has a non-gesture path.** `.accessibilityAction(named:)` or `.accessibilityAdjustableAction` for VoiceOver and Switch Control, and a visible button where sighted users might not discover the swipe. A gesture-only UI is an accessibility failure.
- **Custom modal surfaces behave modally.** `.accessibilityAddTraits(.isModal)` keeps VoiceOver inside (Vaul's focus trap), and `.accessibilityAction(.escape)` gives VoiceOver's two-finger scrub a way out (Vaul's Escape-to-close). Add `.onKeyPress(.escape)` if hardware keyboards matter.

## Reduced motion

Tracking is direct manipulation: the user is producing the motion, so it stays. What reduces is momentum flings, bounce, and any decorative motion around the gesture. On release under `accessibilityReduceMotion`, settle with a short opacity or position change (`.emilEaseOut(0.2)`, no velocity, no bounce) instead of a bouncy spring. Custom animations don't opt out on their own, so branch in every release path, as the examples do. System sheets and scroll views already adapt.

## When it still feels wrong

A "weird" spring is usually fixed by raising `dampingRatio` toward 1 (Emil's web phrasing: increase `damping`). A gesture that stutters is a performance problem: check the track-phase rules above first, then use the `animation-performance` skill and Instruments (SwiftUI, Animation Hitches). To diagnose a feeling you can't name, screen-record the gesture on the device and scrub it frame by frame, or turn on Simulator ▸ Debug ▸ Slow Animations for the release phase.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Default to Vaul for drawers | React library | `.sheet` + `.presentationDetents` |
| Motion `drag` / `dragConstraints` / `dragElastic` / `dragMomentum` props | Library API | One line each in `.onChanged` / `.onEnded` (table above) |
| `useMotionValue` / `useTransform` to bypass React renders | No render-bypassing value in SwiftUI; gesture updates are state updates | Local `@State` / `@GestureState`, small body, render-time effects |
| CSS-transition release for CSS-only components | No CSS | Timing curve via `withAnimation` when there's no velocity |
| `data-vaul-no-drag` | Vaul attribute | Controls win their own touches; scope the `DragGesture` to the grabber |
| `touch-action: pan-x` / `pan-y` | Browser scroll arbitration | No direct equivalent; `.swipeActions`, `.simultaneousGesture` with an axis check, or `UIGestureRecognizerRepresentable` |
| Gate hover behind `@media (hover: hover) and (pointer: fine)` | Touches don't fire `.onHover`, so there are no phantom hovers | Hover is pointer-only (iPad, Mac): never the only affordance; prefer `.hoverEffect` |
| Test via the dev server on local IP | Web workflow | Run a Release build on a real iPhone |
| Invisible `::before` hitbox | CSS pseudo-element | `.contentShape` (see checklist caveat) |
