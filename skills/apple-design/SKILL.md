---
name: apple-design
description: Apple's approach to interface design and fluid, physical motion, grounded in the native SwiftUI and UIKit APIs it came from. Use when building or reviewing iOS gesture-driven UI, Spring(response:dampingRatio:) animations, DragGesture velocity and momentum, interruptible transitions, Materials and Liquid Glass (glassEffect), sensoryFeedback, Reduce Motion / Reduce Transparency / Increase Contrast, Dynamic Type and SF typography (tracking, leading), or the design foundations (feedback, spatial consistency, restraint) behind Apple-style apps.
---

# Apple Design

> Adapted from Emil Kowalski's [`apple-design`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/apple-design) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to help you build fluid, Apple-style interfaces in SwiftUI, my knowledge comes from Apple's WWDC design talks, grounded in the native APIs they describe.

Do not provide any other information until the user asks a question.

How Apple builds interfaces that stop feeling like a computer and start feeling like an extension of you. This knowledge comes from Apple's WWDC design talks, chiefly *Designing Fluid Interfaces* (WWDC 2018). The web original of this skill translated those talks *to* the web. This version maps them back to the native APIs: `Spring`, `DragGesture`, `interpolatingSpring`, `UIScrollView.DecelerationRate`, Materials, `sensoryFeedback`, and the accessibility environment values.

The through-line: **an interface feels alive when motion starts from the current on-screen value, inherits the user's velocity, projects momentum forward, and can be grabbed and reversed at any instant.** Springs make all of this natural, because they're inherently interruptible and velocity-aware. On iOS you don't need a library for any of it.

Shared tokens (`Spring.emilUI`, `Spring.emilMomentum`, `.buttonStyle(.pressable)`, `project(velocity:)`, `rubberband(_:dimension:)`) live in `tools/Motion.swift`. For building specific drags, sheets, and haptics, see `../gestures/SKILL.md`.

## The Core Idea

> "When we align the interface to the way we think and move, something magical happens — it stops feeling like a computer and starts feeling like a seamless extension of us."

An interface is fluid when it behaves like the physical world: things respond instantly, move continuously, carry momentum, resist at boundaries, and can be redirected mid-motion. Everything below is a way to get closer to that.

Apple frames design as serving four human needs: **safety/predictability, understanding, achievement, and joy.** Every rule here serves one of them.

And first: **the system components already do all of this.** `NavigationStack`, `.sheet`, `ScrollView`, `List`, and `Menu` respond on touch-down, track 1:1, hand off velocity, and respect Reduce Motion. Don't retime or re-curve them. Everything below is for the custom components you build next to them.

## 1. Response — kill latency

The moment lag appears, the feeling of directness "falls off a cliff." Response is the foundation everything else is built on.

- **Respond on touch-down, not on release.** A `ButtonStyle`'s `configuration.isPressed` flips on touch-down, so press feedback lives there. `.onTapGesture` gives you nothing until the finger lifts, so don't build buttons from it.
- **Be vigilant about every latency.** Audit debounces, artificial `Task.sleep`s, `.task` work that blocks the first frame, and anything that waits for an animation to finish before accepting input. Anything on the input path that isn't essential is a regression.
- **Feedback must be continuous *during* the interaction, not just at the end.** For a drag, slider, or drawer, update the UI 1:1 with the finger the whole way through. Never animate only when the gesture completes.

```swift
struct SaveButton: View {
    let save: () -> Void

    var body: some View {
        Button(action: save) {
            // Inside the label: the style scales only its label, and the label is the hit area.
            Text("Save")
                .font(.body.weight(.semibold))
                .padding(.horizontal, 20)
                .frame(minHeight: 44)
                .background(.tint, in: .capsule)
                .foregroundStyle(.white)
        }
        // Scale 0.97 on touch-down, 160 ms ease-out; opacity instead under Reduce Motion.
        .buttonStyle(.pressable)
    }
}
```

(The web original's press transition was 100 ms ease-out. The house token `.emilPress` is 160 ms. Both sit inside the press budget, so pick one and use it everywhere.)

## 2. Direct manipulation — 1:1 tracking

> "Touch and content should move together."

When the user drags something, it must stay glued to the finger and respect the offset from *where they grabbed it*. Snapping to the view's center on grab breaks the illusion immediately.

- **Move by `value.translation`, added to where the view was when the drag began.** Positioning by `value.location` is what snaps the center to the finger.
- **You don't need a velocity history.** The web has to record the last few `pointermove` events to estimate velocity. `DragGesture.Value.velocity` (iOS 17+) gives it to you in pt/s, with `predictedEndTranslation` alongside.
- **Tracking continues outside the view's bounds.** A SwiftUI gesture keeps the touch after the finger leaves the view, so there is no `setPointerCapture` step.

The picture-in-picture example in §6 shows all of this together.

## 3. Interruptibility — the single most important principle

> "The thought and the gesture happen in parallel."

Every animation must be interruptible and redirectable at any moment. A user must be able to grab a moving view mid-flight and reverse it without waiting for the animation to finish. A closing modal the user grabs again should follow the finger. It shouldn't finish closing first, then reopen.

- **Never lock out input during a transition.** No `.disabled(isAnimating)`, no `.allowsHitTesting(false)` while something settles, no "ignore taps until the completion fires".
- **Animate from the *presentation* (current) value, never the target value.** SwiftUI does this for you when one animation interrupts another: the new animation starts from what's on screen. The gap is your own code. SwiftUI doesn't expose the presentation value, so a drag that starts mid-animation reads the *model* value, which is already the target. Whether a mid-flight grab then tracks cleanly isn't documented; verify it on a device (`../gestures/SKILL.md` has the options). This is the strongest reason to lean on system components for anything the user catches often. In UIKit, `layer.presentation()` and `UIViewPropertyAnimator` give you the live value directly.
- **Keyframe and phase animators are not for gestures.** `keyframeAnimator` and `phaseAnimator` play an authored track. A re-triggered `keyframeAnimator` rebuilds from the current value and keeps its velocity, but it still plays the track you wrote and can't follow a changing target like a finger. Springs only, for anything gesture-driven.
- **When a gesture reverses, blend velocity. Don't hard-cut it.** Replacing one animation with another at a reversal creates a velocity discontinuity, a "brick wall". SwiftUI never hard-cuts, but springs and curves blend differently. Springs merge: the new target takes over the old velocity. Timing curves (`.easeOut`, `.timingCurve`) don't merge: the old curve keeps running and the new one is added on top (SwiftUI's version of iOS's additive animations), so the motion is continuous but the old curve still plays out, which feels sluggish or overshoots on a reversal. That makes curves the wrong tool for a value that reverses.
- **Decompose 2D motion into independent X and Y springs.** A single spring on a 2D distance desyncs when X and Y have different velocities. In SwiftUI, keep X and Y as separate state, animate each in its own `withAnimation` with its own initial velocity, and apply them with separate modifiers (`.offset(x:)` then `.offset(y:)`). The separate modifiers are a precaution so the two transactions can't merge into one animated `CGSize`; that they would otherwise merge is an assumption, not documented behaviour.

## 4. Behavior over animation — use springs

> "Think of animation as a conversation between you and the object, not something prescribed by the interface."

A pre-scripted, fixed-duration animation can't respond to new input. A spring can: new input just changes the target, and the motion stays continuous. Reach for springs for anything a user can touch.

Apple deliberately replaced the physics triplet (mass/stiffness/damping) with two designer-friendly parameters, and SwiftUI takes them directly: `Spring(response:dampingRatio:)`.

- **Damping ratio** controls overshoot. `1.0` = critically damped: no bounce, smooth settle. `< 1.0` = overshoots and oscillates. Lower = bouncier.
- **Response** is how quickly the value reaches the target, in seconds. Lower = snappier. **This is not "duration"**: a spring has no fixed duration; its settle time emerges from the parameters. (SwiftUI's other initializer, `Spring(duration:bounce:)`, uses a *perceptual* duration. Its presets `.smooth`, `.snappy`, and `.bouncy` are fine, but the values below are Apple's, in Apple's form.)

**Defaults:**
- Start most UI at **damping `1.0`** (critically damped): graceful and non-distracting. That's `Spring.emilUI` (`response 0.4`).
- Add bounce (**damping ~`0.8`**) **only when the gesture itself carried momentum** (a flick, a throw, a drag release). That's `Spring.emilMomentum`. Overshoot on a menu that just faded in feels wrong; overshoot on a card you flicked feels right.

**Concrete values Apple ships:**

| Interaction | Damping | Response | SwiftUI |
| --- | --- | --- | --- |
| Move / reposition (e.g. PiP) | `1.0` | `0.4` | `Spring(response: 0.4, dampingRatio: 1.0)` |
| Rotation | `0.8` | `0.4` | `Spring(response: 0.4, dampingRatio: 0.8)` |
| Drawer / sheet | `0.8` | `0.3` | `Spring(response: 0.3, dampingRatio: 0.8)` |

```swift
struct ExpandableCard: View {
    @State private var expanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            // A tap applies no force: critically damped, no overshoot.
            withAnimation(reduceMotion ? .emilEaseOut(0.2) : .spring(.emilUI)) { expanded.toggle() }
        } label: {
            RoundedRectangle(cornerRadius: 20)
                .fill(.tint)
                .frame(height: 120)
                // Reduce Motion: no scale, just a fade between the two states.
                .scaleEffect(expanded || reduceMotion ? 1.0 : 0.92)
                .opacity(reduceMotion && !expanded ? 0.7 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Card")
        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
    }
}
```

## 5. Velocity handoff — the seam between drag and animation

When a gesture ends, the animation must **continue at the finger's exact velocity**, so there's no visible seam between dragging and animating. This is the detail that most separates "fluid" from "fine".

Pass the release velocity as the spring's initial velocity. SwiftUI's `.interpolatingSpring(_:initialVelocity:)` takes a single `Double` for any animatable value, so the velocity is **relative**: normalize it by the remaining distance to the target.

```
relativeVelocity = gestureVelocity / (targetValue − currentValue)
```

Example: view at `y = 50`, target `y = 150` (100 pt to go), finger moving 50 pt/s → initial spring velocity = `50 / 100 = 0.5`. Guard the divide when the remaining distance is near zero. The SDK doc gives the unit: `interpolatingSpring(_:initialVelocity:)` produces values in a unit range that interpolate the property's from→to range, and the `duration:bounce:` and `mass:stiffness:damping:` overloads describe `initialVelocity` as a [0, 1] value "representing the magnitude of the value being animated". Velocity ÷ remaining distance follows from that; the doc doesn't write the formula out. In UIKit, `UISpringTimingParameters(dampingRatio:initialVelocity:)` takes a `CGVector`, documented there as relative to the total animation distance.

Plain `withAnimation(.spring(...))` from `.onEnded` starts the spring at zero velocity. That is exactly the seam this section is about.

## 6. Momentum projection — animate to where the gesture is *going*

> "Take a small input and make a big output."

Don't snap to the nearest boundary from the *release point*. Use velocity to **project the resting position**, exactly like scroll deceleration, then snap to the target nearest that projected point. This is what makes a flick feel like it throws the view.

Apple's projection function from the *Designing Fluid Interfaces* sample code is `project(velocity:decelerationRate:)` in Motion.swift. Its default `0.998` is `UIScrollView.DecelerationRate.normal.rawValue`; use `.fast` (`0.99`) for snappier, shorter throws. Note: the physics-textbook `v²/(2·decel)` is *not* what Apple ships. Use the exponential-decay form. It's the standard behaviour in good bottom sheets and carousels, including the system's own.

`DragGesture.Value.predictedEndTranslation` is the built-in alternative, and it throws shorter: in the iOS SDK, `velocity` is computed as `4 × (predictedEndLocation − location)`, so the prediction is a quarter-second of current velocity (inferred from the SDK's inlined code, not documented). Pick one and use it consistently.

The PiP example: project on each axis, choose the nearest corner, hand off velocity per axis.

```swift
struct PictureInPicture: View {
    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    @State private var dragStart: CGPoint?
    @State private var corner = 3
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size = CGSize(width: 160, height: 90)
    private let inset: CGFloat = 16
    private let cornerNames = ["top left", "top right", "bottom left", "bottom right"]

    var body: some View {
        GeometryReader { proxy in
            let corners = cornerPoints(in: proxy.size)
            RoundedRectangle(cornerRadius: 12)
                .fill(.black)
                .frame(width: size.width, height: size.height)
                .offset(x: x) // separate modifiers, one per axis (precaution, see §3)
                .offset(y: y)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let start = dragStart ?? CGPoint(x: x, y: y) // respect the grab offset
                            dragStart = start
                            x = start.x + value.translation.width
                            y = start.y + value.translation.height
                        }
                        .onEnded { value in
                            dragStart = nil
                            let v = value.velocity
                            let projected = CGPoint(x: x + project(velocity: v.width), y: y + project(velocity: v.height))
                            let index = corners.indices.min {
                                hypot(corners[$0].x - projected.x, corners[$0].y - projected.y)
                                    < hypot(corners[$1].x - projected.x, corners[$1].y - projected.y)
                            } ?? 0
                            move(to: index, in: corners, velocity: v)
                        }
                )
                .onAppear { x = corners[corner].x; y = corners[corner].y }
                .accessibilityElement()
                .accessibilityLabel("Picture in picture, \(cornerNames[corner])")
                .accessibilityActions {
                    ForEach(cornerNames.indices, id: \.self) { i in
                        Button("Move to \(cornerNames[i])") { move(to: i, in: corners, velocity: .zero) }
                    }
                }
        }
    }

    private func cornerPoints(in container: CGSize) -> [CGPoint] {
        let maxX = container.width - size.width - inset
        let maxY = container.height - size.height - inset
        return [CGPoint(x: inset, y: inset), CGPoint(x: maxX, y: inset),
                CGPoint(x: inset, y: maxY), CGPoint(x: maxX, y: maxY)]
    }

    private func move(to index: Int, in corners: [CGPoint], velocity: CGSize) {
        corner = index
        let target = corners[index]
        guard !reduceMotion else {
            withAnimation(.emilEaseOut(0.2)) { x = target.x; y = target.y }
            return
        }
        // Reposition spring (damping 1.0, response 0.4), with relative velocity per axis.
        let dx = target.x - x, dy = target.y - y
        withAnimation(.interpolatingSpring(.emilUI, initialVelocity: abs(dx) > 1 ? velocity.width / dx : 0)) { x = target.x }
        withAnimation(.interpolatingSpring(.emilUI, initialVelocity: abs(dy) > 1 ? velocity.height / dy : 0)) { y = target.y }
    }
}
```

## 7. Spatial consistency — symmetric paths, anchored origins

> "If something disappears one way, we expect it to emerge from where it came."

- **Enter and exit along the same path.** A panel that slides in from the right must dismiss to the right: `.transition(.move(edge: .trailing))` is symmetric by default. Don't reach for `.asymmetric` with two different edges. In-from-right / out-the-bottom feels disconnected and confusing.
- **Anchor interactions to their source.** A menu, popover, or sheet should originate from the control that triggered it. System `.popover`, `Menu`, and `.contextMenu` already do. For custom ones, set `anchor:` on `.scaleEffect` / `.scale(scale:anchor:)` to the trigger's side. For a card that opens into a screen, `.matchedTransitionSource` + `.navigationTransition(.zoom(sourceID:in:))` (iOS 18) zooms from the card and drags back into it.

```swift
struct SidePanel: View {
    @State private var showPanel = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .trailing) {
            Button("Details") { withAnimation(.emilEaseOut(0.25)) { showPanel.toggle() } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if showPanel {
                Text("Details")
                    .frame(maxWidth: 280, maxHeight: .infinity)
                    .background(.regularMaterial)
                    // In from the trailing edge, out to the trailing edge.
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            }
        }
    }
}
```

## 8. Hint in the direction of the gesture

Humans predict a final state from a trajectory. Intermediate motion should telegraph where things are going: Control Center modules "grow up and out toward your finger." Make the in-between frames point at the outcome, not just interpolate blindly to it. In SwiftUI terms: drive the in-between state from gesture progress (scale, corner radius, or blur that already lean toward the end state while the finger is down), and anchor growth toward the finger with `anchor:` (a `UnitPoint` computed from the touch location).

## 9. Rubber-banding — soft boundaries

At an edge, resist progressively instead of stopping hard. A hard stop reads as "frozen"; continuous resistance reads as "responsive, but there's nothing more here." Apply damping that increases the further past the boundary the user drags. `ScrollView` does this natively. For custom drags, `rubberband(_:dimension:)` in Motion.swift is the same formula, applied in `.onChanged`:

```swift
// fragment
offset = proposed > maxOffset ? maxOffset + rubberband(proposed - maxOffset, dimension: containerHeight) : proposed
```

## 10. Gesture design details (the "feel" checklist)

- **Tap:** highlight on touch-*down* (instant), commit on touch-*up*. `Button` does this, including cancel-by-dragging-away and back, and it allows a bit of slop around the target. Give small targets a 44×44 pt hit area (`.frame(minWidth: 44, minHeight: 44)` + `.contentShape(.rect)`).
- **Drag/swipe:** require a small movement threshold (hysteresis) before committing to a direction, then track 1:1. `DragGesture()` already waits 10 pt (`minimumDistance` defaults to 10 in the SDK), and `onLongPressGesture` cancels after 10 pt of movement (`maximumDistance`). Keep the defaults.
- **Detect all plausible gestures in parallel from the first move**, then confidently cancel the losers once intent is clear. Compose with `.simultaneousGesture`, `.exclusively(before:)`, and `.sequenced(before:)`, or go to `UIGestureRecognizerRepresentable` (iOS 18) when you need delegate-level control. Avoid recognizers that only report a *final* state (`UISwipeGestureRecognizer`'s "did swipe left"). They throw away the continuous tracking you need for feedback. `DragGesture` with `.onChanged` is the continuous one.
- **Minimize disambiguation delays.** `.onTapGesture(count: 2)` on the same view as a single tap makes every single tap wait to see whether a second one is coming. Only pay that cost where double-tap truly exists.

## 11. Frame-level smoothness

Smoothness is about *what's in the frames*, not just the frame rate.

- For very fast motion, a subtle **motion blur / stretch** encodes speed and reads better than a hard, sharp streak. A small `.blur(radius:)` or a slight `.scaleEffect` along the axis of travel, scaled by velocity. Keep it small: blur renders offscreen.
- Apple's display-synced clock is `CADisplayLink`. SwiftUI animations already run on it, and `TimelineView(.animation)` gives you per-frame drawing when you need it. Animate render-time effects (`.offset`, `.scaleEffect`, `.rotationEffect`, `.opacity`), not `.frame` or `.padding`, which re-run layout every frame. Keep the main thread free while things move, because SwiftUI evaluates its animations in-process. See `../animation-performance/SKILL.md`.
- On ProMotion iPhones, check that `CADisableMinimumFrameDurationOnPhone` is set in Info.plist for custom animation above 60 Hz (see `../gestures/SKILL.md`).

## 12. Materials & depth — translucency conveys hierarchy

Apple uses translucent materials as a floating functional layer that brings structure without stealing focus. Natively, this is `Material` (`.ultraThinMaterial` through `.ultraThickMaterial`) and, on iOS 26, Liquid Glass (`.glassEffect`).

- **Build nav, toolbars, and sheets as translucent layers** with content scrolling underneath, not opaque bars that take a fixed strip. System navigation bars, tab bars, toolbars, and sheets already are. For custom floating chrome, put it in `.safeAreaInset(edge:)` over the scroll content, on a material.
- **Material weight encodes hierarchy:** thicker materials separate structural regions (sidebars); thinner ones draw attention to interactive elements (buttons). **Never stack a light translucent surface on another**: legibility collapses.
- **Bigger surfaces should read as thicker:** a heavier material and a deeper shadow than small chips. Consider context-aware shadow: heavier over busy or text content for separation, lighter over plain backgrounds.
- **Dim to focus, separate to keep flow.** A modal task pairs the surface with a dimming scrim and pushes the background back. `.sheet` and `.fullScreenCover` do this, and stacked sheets progressively dim and push back each parent. A parallel, non-blocking panel uses translucency and offset *without* a scrim so the flow isn't broken: `.presentationBackgroundInteraction(.enabled(upThrough:))`.
- **Vibrancy keeps text legible over changing backgrounds.** Don't use flat gray text on a material. Use hierarchical styles (`.foregroundStyle(.secondary)`), which the system renders vibrant over materials, and give small text slightly heavier weight and a small tracking bump (custom fonts only; SF tracks itself). Put color on a solid layer, not the translucent foreground.
- **Nested corners should be concentric.** A shape near a screen or sheet edge looks wrong with a fixed radius that doesn't match the container's corner. On iOS 26, `ConcentricRectangle()` (or `.rect(corners: .concentric)`) follows the container, declared with `.containerShape(_:)`. On iOS 18, compute the inner radius as the outer radius minus the inset, and keep `.rect(cornerRadius:)` for shapes away from those edges.
- **Scroll edge effects, not hard dividers.** Instead of a 1 pt rule under a sticky header, let content fade or blur where it meets floating chrome, and only where floating UI actually overlaps content. iOS 26: `.scrollEdgeEffectStyle(_:for:)`. iOS 18: system bars already switch to their scroll-edge appearance; for custom chrome, a material background is the fallback.
- **Materialize, don't just fade.** For glass and blur surfaces, bring blur and scale in together so the surface reads as a real material arriving, not a plain opacity fade. `.transition(.blurReplace)` (iOS 17+) is the iOS 18 form: it already blurs and scales together, so don't add another scale, and fall back to `.opacity` under Reduce Motion; iOS 26 glass has its own `glassEffectTransition`.

```swift
struct FloatingToolbar: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let bar = HStack(spacing: 28) {
            // Each icon gets a 44 × 44 tap target inside its label, not just the glyph.
            Button {} label: { Label("Share", systemImage: "square.and.arrow.up").frame(minWidth: 44, minHeight: 44).contentShape(.rect) }
            Button {} label: { Label("Favorite", systemImage: "heart").frame(minWidth: 44, minHeight: 44).contentShape(.rect) }
            Button {} label: { Label("Delete", systemImage: "trash").frame(minWidth: 44, minHeight: 44).contentShape(.rect) }
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .padding(.horizontal, 24)
        .frame(minHeight: 52)

        if #available(iOS 26, *) {
            bar.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            bar.background(.regularMaterial, in: .capsule)
                // Bright edge = light catching the material; solid under Increase Contrast.
                .overlay(Capsule().strokeBorder(.white.opacity(contrast == .increased ? 0.9 : 0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        }
    }
}
```

## 13. Multimodal feedback — motion + sound + haptics

Three rules for combining senses (from *Designing Audio-Haptic Experiences*):

1. **Causality.** It must be obvious what caused the feedback. Trigger it on the actual causal event (the toggle flipping, the item snapping home), and match its character to the action's physicality: `.selection` for a tick, `.impact(weight:)` for a landing, `.success` / `.error` for outcomes.
2. **Harmony.** The visual, the sound, and the haptic must fire on the **same frame**. Latency between them destroys the illusion. Use `.sensoryFeedback(_:trigger:)` on the same state change that drives the animation, so both land in one update.
3. **Utility.** Add feedback only where it earns its place. Reserve haptics and sound for meaningful moments (success, error, commit, snap). Over-feedback trains users to ignore all of it.

```swift
struct FavoriteButton: View {
    @State private var isFavorite = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            isFavorite.toggle() // one state change drives the symbol, the bounce, and the haptic
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                // Bounce is overshoot: under Reduce Motion the symbol just swaps.
                .symbolEffect(.bounce, value: reduceMotion ? false : isFavorite)
                .frame(minWidth: 44, minHeight: 44)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isFavorite)
        // A stable label; the state is a trait, so VoiceOver reads "Favorite, selected".
        .accessibilityLabel("Favorite")
        .accessibilityAddTraits(isFavorite ? [.isToggle, .isSelected] : .isToggle)
    }
}
```

## 14. Reduced motion & accessibility

Reduced motion doesn't mean *no* feedback. It means a gentler, non-vestibular equivalent. Respond to each signal independently and bake them into your components. **Custom animations don't opt out on their own; you must branch.** System components and materials adapt for you.

- **`@Environment(\.accessibilityReduceMotion)`**: replace slides, springs, and parallax with short opacity **cross-fades or static transitions**. Drop elastic and overshoot. Keep opacity and color changes that aid comprehension. `UIAccessibility.prefersCrossFadeTransitions` is the separate "Prefer Cross-Fade Transitions" setting; honour it for custom navigation-like transitions.
- **`@Environment(\.accessibilityReduceTransparency)`**: make translucent surfaces frostier or solid. System materials do this automatically. Custom translucency (a `Color.white.opacity(0.6)` fill) needs the branch.
- **`@Environment(\.colorSchemeContrast) == .increased`**: near-solid backgrounds with a defined, contrasting border.
- **`@Environment(\.accessibilityDifferentiateWithoutColor)`**: where color alone carries meaning (status dots, chart series, a selected state), add a second cue: a symbol, a pattern, a stroke or a label.

Also: avoid full-screen moving backgrounds, slow looping oscillations (near 0.2 Hz, one cycle per 5 s), and abrupt brightness jumps (the system eases its own dark/light switch; don't flash your own). Make large moving objects semi-transparent while they travel, and fade big surfaces out during a large reposition and back in once settled.

```swift
struct InfoCard: View {
    @Binding var isShown: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        if isShown {
            Text("Saved to Library")
                .padding()
                .background {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground))
                    } else {
                        // A material, not Color.white.opacity(0.6): white on white is unreadable in dark mode.
                        RoundedRectangle(cornerRadius: 16).fill(.regularMaterial)
                    }
                }
                .overlay {
                    if contrast == .increased {
                        RoundedRectangle(cornerRadius: 16).strokeBorder(.primary, lineWidth: 1)
                    }
                }
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        }
    }
}
```

## 15. Typography — optical sizing, tracking, leading

Apple designs type to change shape with size (from *The Details of UI Typography*, WWDC 2020). With San Francisco on iOS you get most of this for free. The discipline matters when you go custom.

- **Tracking is size-specific; never one value for all sizes.** Large display text wants *negative* tracking (letters read too far apart as they grow); small text wants slightly *positive* tracking for legibility. SF applies its own size-specific tracking table automatically, and switches between its Text and Display optical sizes at the right point, so don't add `.tracking` to system text styles. For a custom face, compute tracking from the size, since `.tracking(_:)` is in points: the web's `-0.02em` at 48 pt is `-0.96` pt.
- **Leading tracks size inversely.** Tight on large headings, looser on body copy. `.leading(.tight)` / `.leading(.loose)` on a system `Font`, or `.lineSpacing(_:)` to add space. Loosen for scripts with tall ascenders and descenders; tighten for dense, information-heavy UI.
- **Build hierarchy from weight + size + leading as a set,** not size alone. Emphasize with weight (`.fontWeight`, `.bold()`): it adds presence without taking more space. Respect Bold Text (`@Environment(\.legibilityWeight)`).
- **Respect the user's text size (Dynamic Type).** Use text styles (`.font(.body)`, `.font(.largeTitle)`), not fixed sizes. Scale custom sizes and spacing with `@ScaledMetric`, and custom fonts with `Font.custom(_:size:relativeTo:)`, so a larger setting doesn't break the layout. On iOS 26, `.font(.body.scaled(by:))` scales a text style too. To switch layout at the largest sizes, read `@Environment(\.dynamicTypeSize)` and check `.isAccessibilitySize`, not the older `sizeCategory`. Cap with `.dynamicTypeSize(...)` only where layout truly can't grow, never on body text.
- **Default to the system font** before a custom face. It already ships optical sizing, tracking tables, and legibility tuning. Override only with a reason.

```swift
struct ArticleHeader: View {
    let title: String
    let summary: String
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize: CGFloat = 48

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Custom display face: @ScaledMetric scales the size, so use fixedSize (custom(_:size:) would scale it twice);
            // negative tracking is computed from the same scaled size.
            Text(title)
                .font(.custom("Georgia-Bold", fixedSize: displaySize))
                .tracking(-0.02 * displaySize)
            // System text style: SF tracks itself; just set the leading.
            Text(summary)
                .font(.body.leading(.loose))
                .foregroundStyle(.secondary)
        }
    }
}
```

## 16. Design foundations — the eight principles

The motion and craft above serve Apple's eight design principles (*Principles of Great Design*, WWDC 2026). Use these as the names you reason with:

1. **Purpose.** Make with intention; decide what *not* to build. Every feature asks for the user's time, attention, and trust. Spend that budget only where it pays off.
2. **Agency.** Keep people in control: offer choices, don't force a single path. Back it with forgiveness. Give easy undo for slips (`@Environment(\.undoManager)`, an Undo action). Use a confirmation (`.confirmationDialog`, `.alert` with a `.destructive` role) only for genuinely destructive, irreversible actions, and use it sparingly: overuse trains people to click through.
3. **Responsibility.** Act in the user's interest. Privacy: ask at the right moment, only for what's needed, transparently (request permission when the feature is used, not at launch). Safety: anticipate misuse and harm, especially with AI (an allergy-aware recipe app must not suggest a harmful ingredient). Add previews, confirmations, and disclaimers; cut a feature whose risk outweighs its value.
4. **Familiarity.** Build on what people already know. Use metaphors that are neither too literal nor too abstract (a trash can means delete), and honor their physics. Be consistent: things that look the same must behave the same and live in the same place (close is always top-left on macOS) so people can predict what happens next. On iOS this mostly means using the system components and placements. Only break a familiar pattern if you can prove it's better, and then test it; don't assume.
5. **Flexibility.** Design for different contexts, devices, and the full range of abilities. Adapt to the platform (iPhone = quick touch; iPad and Mac = deeper workflows with precise pointer control) and to the situation. Design inclusively (age, language, expertise, accessibility). When no single layout fits everyone, let people personalize: rearrange controls, hide what they don't use.
6. **Simplicity — not minimalism.** Strip the unnecessary so the core purpose shines; burying everything in one place looks minimal but isn't simple. Be concise (plain language, no jargon, fewer steps) and clear (use hierarchy: order, spacing, contrast, so the most important thing is the most obvious). Every element earns its place, and sometimes *adding* context simplifies (a video scrubber that shows time remaining). Show the common path first, advanced options one level deeper.
7. **Craft.** Uncompromising attention to detail builds trust. Beautiful typography, colors that adapt to light and dark (semantic colors, asset-catalog variants), clear iconography (SF Symbols), and responsive animations that give immediate, natural feedback. Nothing is random: every spacing, timing, and alignment value is a deliberate choice you can defend. Jittery scroll, misaligned icons, and layouts that break on rotation read as carelessness. Craft needs iteration and longevity: keep evolving the design as features and hardware change.
8. **Delight.** The result of getting the other seven right, not confetti tacked on top. Decide the emotion you want people to feel (calm, confident, excited) and reinforce it in every decision.

Tactical rules that serve these:

- **Feedback comes in four kinds:** status, completion, warning, error. Confirm meaningful actions, expose ongoing status (`ProgressView`), warn before problems, and validate inline (not on submit).
- **Wayfinding.** Every screen should answer: Where am I? Where can I go? What's there? How do I get out? Never trap the user. A navigation title, a working back button and back swipe, and a dismiss control on every modal.
- **Grouping & mapping.** Proximity implies relationship. Place a control near what it affects and arrange controls to mirror what they change. If you need a label to explain a control, the mapping is weak.
- **Direct, specific labels beat safe generic ones.** Name tabs and nav items for their contents ("Progress", "Library"), not vague umbrellas ("Home"). Specificity creates predictability.

## 17. Process

- **Prototype interactively.** An interactive demo is worth "a million static designs." You discover the interface by building and playing with it; a working prototype also sets a concrete bar that prevents a mediocre final implementation. SwiftUI previews and a device build are the fastest loop.
- **Design interaction and visuals together.** "You shouldn't be able to tell where one ends and the other begins." Motion is not a layer added after the pixels.
- **Test with real people in real context**, on a real device. The Simulator has no haptics, no real touch, and no ProMotion. Review motion with fresh eyes: play it slowly (Simulator ▸ Debug ▸ Slow Animations) or screen-record on device and scrub frame by frame to catch what's invisible at full speed.

## Quick Reference

| Need | Technique | Concrete value |
| --- | --- | --- |
| Default UI spring | Critically damped, no overshoot | `Spring(response: 0.3–0.4, dampingRatio: 1.0)` / `Spring.emilUI` |
| Momentum / flick spring | Under-damped, slight bounce | `Spring(response: 0.3–0.4, dampingRatio: 0.8)` / `Spring.emilMomentum` |
| Gesture → spring velocity | Hand off release velocity | `.interpolatingSpring(s, initialVelocity: v / (target − current))` |
| Flick landing point | Project momentum | `current + project(velocity: v)`, `d = 0.998` (`DecelerationRate.normal`) |
| Interrupt cleanly | Start from the presentation value | SwiftUI animations do; your drag code reads the model value, so verify on device |
| Avoid reversal "brick wall" | Springs merge and hand over velocity; curves stack and the old one plays out | Springs, not timing curves |
| Decide reverse vs. commit | Snap to the point nearest the projected endpoint | in `.onEnded` |
| 1:1 drag | `value.translation` + start position | respect the grab offset; no animation in `.onChanged` |
| Feedback | On touch-down, continuous | `ButtonStyle` `isPressed`; never only at the end |
| Boundary | Rubber-band, don't hard-stop | `rubberband(_:dimension:)` |
| Translucent chrome | Material layer, content scrolls under | `.regularMaterial`; iOS 26 `.glassEffect()` |
| Haptic | Same state change as the visual | `.sensoryFeedback(_:trigger:)` |
| Type tracking | Size-specific, never fixed | SF: automatic; custom: `.tracking(-0.02 × size)` |
| Reduced motion | Cross-fade, not slide/spring | `@Environment(\.accessibilityReduceMotion)` branch |

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `setPointerCapture` | A SwiftUI gesture keeps the touch after it leaves the view | Nothing to do |
| Track a `pointermove` history to compute velocity | The framework provides it | `DragGesture.Value.velocity` (pt/s), `predictedEndTranslation` |
| ~300 ms tap delay audit | Browser artifact | `ButtonStyle` `isPressed` already fires on touch-down; audit `.onTapGesture(count: 2)` disambiguation instead |
| "Choose a spring library that re-targets from current velocity" (Motion / Framer Motion `bounce`/`duration` mapping) | No library needed | `Spring(response:dampingRatio:)` is native |
| `requestAnimationFrame` as the display clock | Browser API | `CADisplayLink`, `TimelineView(.animation)` |
| `will-change` after measuring | No developer-facing layer promotion | Measure in Instruments; `drawingGroup()` only for many-layer static art |
| `backdrop-filter: blur() saturate()` + rgba background | CSS approximation of a material | `Material`, iOS 26 `glassEffect` |
| `@media (prefers-*)` queries | CSS | Environment values (`accessibilityReduceMotion`, `accessibilityReduceTransparency`, `colorSchemeContrast`) |
| Spacing in `rem` / `em`, `clamp()` font sizes, `font-optical-sizing: auto` | CSS units and properties | `@ScaledMetric`, text styles, SF's automatic optical sizes |
| Vaul / Embla as the reference sheet and carousel | React libraries | `.sheet` + `.presentationDetents`; `ScrollView` + `.scrollTargetBehavior` |
