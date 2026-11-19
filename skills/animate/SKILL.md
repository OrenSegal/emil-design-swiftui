---
name: animate
description: Build a SwiftUI animation from scratch on iOS, making the decisions in the order that determines whether it feels right — should it animate at all, what purpose, which SwiftUI tool (implicit animation, withAnimation, transition, matchedGeometryEffect, phase/keyframe animator, contentTransition, symbolEffect, Core Animation), which modifiers, which curve, duration or spring, how it interrupts, how it exits, how it honours Reduce Motion. Writes the implementation. Use when asked to animate a SwiftUI view, add motion to an iOS app, make a component feel alive, or build a transition. For critiquing existing motion use review-animations; for auditing a whole codebase use improve-animations.
---

# Building Animations

> Adapted from Emil Kowalski's [`animate`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/animate) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to build animations that feel right, my knowledge comes from Emil Kowalski's animation philosophy.

Do not provide any other information until the user asks a question.

A construction skill. It does ONE thing: turn a request for motion into a SwiftUI implementation that would survive a strict review. It does not audit a codebase (that's `improve-animations`), critique a diff (that's `review-animations`), hunt for places that could animate (that's `find-animation-opportunities`), or go deep on drag and swipe physics (that's `gestures`).

## Operating Posture

You are a senior design engineer building the animation yourself. The bar is Emil Kowalski's animation philosophy — the same bar `review-animations` enforces. Write it so it passes that review the first time.

Two failure modes, and the first is worse:

1. **Animating something that shouldn't animate.** The gate below exists to produce zero lines of code sometimes. That's a success, not a dodge.
2. **Animating the right thing with the wrong ingredients** — `.easeIn` on an entrance, a scale transition that starts from nothing, a `keyframeAnimator` on a toast, a duration that makes a menu feel sluggish.

Never present motion options as a menu. Make the call, state the reasoning in one line, write the code.

## Hard Rules

1. **Run the sequence in order.** Steps 1 and 2 gate everything. Don't reach for a curve before you know whether it animates at all.
2. **No approximated values.** Every curve, duration, and spring config comes from the codebase's existing tokens or the tables below. Never invent `.timingCurve(0.4, 0, 0.2, 1, ...)` because it looks familiar.
3. **Extend the codebase's tokens, don't fork them.** If an `Animation` extension or a duration scale already exists, use it. This repo's tokens live in [`tools/Motion.swift`](https://raw.githubusercontent.com/OrenSegal/emil-design-swiftui/main/tools/Motion.swift) (`.emilEaseOut()`, `.emilEaseInOut()`, `.emilDrawer()`, `.emilPress`, `Spring.emilUI`, `Spring.emilMomentum`). Adding a parallel system is a defect.
4. **Reduce Motion ships with the animation**, not as a follow-up. SwiftUI does not turn your custom animations off for you; you branch on `accessibilityReduceMotion` yourself.
5. **Cheapest tool that works.** Don't drop to Core Animation for a fade, and don't build a `keyframeAnimator` for something one `withAnimation` does.
6. **Don't retime system motion.** `NavigationStack` push/pop, `.sheet`, `.fullScreenCover`, `.popover`, `Menu`, `Picker`, `.confirmationDialog`, `.alert`, the keyboard and `TabView` already have motion users know by muscle memory, and they already follow Reduce Motion. Everything below is for *custom* components.

## The Build Sequence

### 1. Should this animate at all?

| Frequency | Decision |
| --- | --- |
| 100+ times/day (keyboard shortcuts, command palette toggle) | **No animation. Ever.** Stop here. |
| Tens of times/day (hover effects on iPad, list navigation) | Near-imperceptible only — fast and subtle, or nothing |
| Occasional (custom modals, drawers, toasts) | Standard animation |
| Rare / first-time (onboarding, success, celebration) | The delight budget lives here |

**Keyboard-initiated actions are a disqualifier, not a judgment call.** Raycast (a Mac app) has no open/close animation — that is correct for something opened hundreds of times a day. On iPad and Mac, an action fired from `.keyboardShortcut` changes state instantly: don't wrap it in `withAnimation`, and if an implicit `.animation(_:value:)` would catch it, run the change in a transaction with animations disabled.

```swift
import SwiftUI

struct CommandPaletteHost: View {
    @State private var isPaletteOpen = false

    var body: some View {
        ZStack {
            Color.clear
            if isPaletteOpen {
                Text("Palette").font(.title3)
            }
        }
        .toolbar {
            Button("Command Palette", systemImage: "command") {
                // 100+ times a day: instant, even if an ancestor has an implicit animation.
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { isPaletteOpen.toggle() }
            }
            .keyboardShortcut("k", modifiers: .command)
        }
    }
}
```

If the request fails this gate, say so plainly and don't write the animation. Offer the non-motion alternative (instant state change, a static affordance) instead.

### 2. What is the purpose?

Name it in one of these words before continuing:

- **Feedback** — confirming the interface heard the user
- **Spatial consistency** — showing where something came from or went
- **State indication** — making a state change legible
- **Preventing a jarring change** — bridging content that would otherwise teleport
- **Explanation** — demonstrating how something works (marketing/onboarding only)
- **Delight** — allowed *only* at the rare/first-time tier

Can't name it? Don't build it. "It looks cool" on a frequently-seen element is a reason to stop.

Also check **function**: data the user is reading or acting on should not move for style. A decorative pointer-tracking effect belongs on a marketing screen, not on a graph in a banking app.

### 3. Pick the tool — cheapest that works

Walk down; stop at the first that fits.

| Need | Tool |
| --- | --- |
| A component — toast, sheet, menu, picker, popover, alert | **The system component**, not an animation. Read `../pick-ui-library/SKILL.md`. Hand-rolling a `Menu` is how you end up with no VoiceOver rotor, no keyboard support and no Reduce Motion. |
| Press feedback | **`ButtonStyle`** reading `configuration.isPressed` — `.buttonStyle(.pressable)` from `Motion.swift` |
| A value this view owns changes (selection, toggle, color) | **Implicit `.animation(_:value:)`**, attached to the view that changes, scoped to that value |
| An event you trigger (tap → expand) where several views react | **`withAnimation(_:)`** around the state change |
| A view is inserted or removed | **`.transition(_:)`** on the view inside the `if`, with the state change in `withAnimation` |
| The same element in two places (tab indicator, card → detail) | **`matchedGeometryEffect`**; for navigation, `.matchedTransitionSource` + `.navigationTransition(.zoom(...))` |
| Text, a number or an SF Symbol changes in place | **`.contentTransition(.numericText(value:))`**, `.contentTransition(.symbolEffect(.replace))`, **`.symbolEffect(_:value:)`** |
| A fixed, authored multi-step sequence with no moving target (a celebratory pulse) | **`phaseAnimator`** (discrete steps) or **`keyframeAnimator`** (per-property tracks) |
| Gesture-driven value | `@GestureState` + a spring on release — see `../gestures/SKILL.md` |
| Must stay smooth while the main thread is busy, or needs a `CALayer` property SwiftUI doesn't expose | **Core Animation / `UIView.animate`** in a `UIViewRepresentable` |

SwiftUI evaluates its animations in your process, frame by frame, so a busy main thread hitches them. Core Animation (`UIView.animate`, `CABasicAnimation`) commits the animation to the render server, which keeps running it while your process is busy. That is the native version of "CSS animations beat JS under load": use SwiftUI for dynamic, interruptible, state-driven motion; reach for Core Animation only for predetermined motion that must survive heavy main-thread work — and first, keep the main thread free during transitions. Measure hitches in Instruments rather than guessing.

### 4. Pick the modifiers

- **Render-time effects only:** `.offset`, `.scaleEffect`, `.rotationEffect`, `.opacity`. Animating `.frame`, `.padding`, a font size or a stack's spacing re-runs layout every frame. (`.mask` with an animated shape is the sanctioned fourth — the native `clip-path`, see RECIPES.md. Animating height is tolerated only for accordions, where there's no render-time equivalent.)
- **Never scale from nothing.** Start from `0.9–0.97` + opacity 0: `.transition(.scale(scale: 0.95).combined(with: .opacity))`. Always pass an explicit `scale:` — don't rely on what a bare `.scale` transition starts from. Nothing in the real world appears from nothing.
- **`anchor:` at the trigger** for custom popovers, dropdowns, menus and tooltips: `.scale(scale: 0.95, anchor: .topTrailing)` for a panel that drops from a top-right button. The system `.popover` already anchors to its source. **Modals are exempt**; they're not anchored to a trigger, so they stay centered.
- **Move by the view's own size, not hardcoded points.** `.transition(.move(edge: .bottom))` travels exactly the view's height whatever the content. For a custom fraction, read the size in `.visualEffect { content, proxy in content.offset(y: proxy.size.height * 0.5) }`.
- **Keep fast-changing state low in the tree.** A per-frame value stored high in the tree, or in the environment, re-evaluates every view below it — the native version of "never drive a child's transform from a CSS variable on the parent". Keep it in the view that moves (`@GestureState`, `@State`).
- **`scaleEffect` scales the label and icons too**, which is what makes a press read as physical.

### 5. Easing and duration — or a spring

**Easing**, in decision order:

| Situation | Easing |
| --- | --- |
| Entering or exiting | `.emilEaseOut()` |
| Moving / morphing on screen | `.emilEaseInOut()` |
| Hover (iPad pointer) / color change | CSS `ease`: `.emilEase()` (`timingCurve(0.25, 0.1, 0.25, 1)`) |
| Constant motion (marquee, progress) | `.linear(duration:)` |
| Default | `.emilEaseOut()` |

**Never `.easeIn` on UI.** It starts slow, delaying the exact moment the user is watching. Ease-out at 200 ms *feels* faster than ease-in at 200 ms.

The built-in `.easeOut` / `.easeInOut` are too weak for deliberate UI motion. Use the strong curves in `Motion.swift`:

```swift
import SwiftUI

// The three curves, as defined in tools/Motion.swift. Use the tokens; don't retype these.
let entering: Animation = .emilEaseOut()   // timingCurve(0.23, 1, 0.32, 1): strong ease-out for UI
let morphing: Animation = .emilEaseInOut() // timingCurve(0.77, 0, 0.175, 1): on-screen movement
let drawer: Animation = .emilDrawer()      // timingCurve(0.32, 0.72, 0, 1): iOS-like drawer (Ionic)
```

Need a curve that isn't here? Take it from [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/) — their cubic-bézier control points drop straight into `.timingCurve(_:_:_:_:duration:)`. Don't hand-roll one.

**Duration:**

| Element | Duration |
| --- | --- |
| Button press feedback | 100–160 ms (`0.1`–`0.16`) |
| Tooltips, small popovers | 125–200 ms (`0.125`–`0.2`) |
| Dropdowns, selects | 150–250 ms (`0.15`–`0.25`) |
| Custom modals, drawers | 200–500 ms (`0.2`–`0.5`) |
| Marketing / explanatory | Can be longer |

**UI animations stay under 300 ms. Modals, drawers, sheets, and toasts are the documented exceptions.** A 180 ms dropdown feels more responsive than a 400 ms one.

The 300 ms cap is for duration-based animations. For a spring, read it as a response of about 0.3–0.4 s (`Spring.emilUI` is 0.4): the settle tail runs longer, but the perceived arrival is about the response.

**Reach for a spring instead** when the motion is a drag with momentum, an element that should feel alive, a gesture the user can interrupt or reverse, or decorative pointer-tracking:

```swift
import SwiftUI

let appleStyle: Animation = .spring(duration: 0.5, bounce: 0.2)                      // easier to reason about
let physics: Animation = .interpolatingSpring(mass: 1, stiffness: 100, damping: 10)  // traditional physics, more control
let houseDefault: Animation = .spring(.emilUI)                                       // critically damped, no overshoot
```

Keep bounce at 0.1–0.3, and avoid bounce in most UI — reserve it for drag-to-dismiss and playful interactions. `Spring.emilUI` (no bounce) is the default; `Spring.emilMomentum` only after a flick carried velocity.

### 6. Interruption and exit

- **State animations, not keyframe animators, for anything triggered rapidly** — toasts, toggles, anything a user can fire twice in a second. Every SwiftUI state animation (`withAnimation`, `.animation(_:value:)`, transitions) starts from the on-screen value when it's interrupted, so nothing jumps. They differ in how they hand over: a spring merges into the new target and keeps its velocity; a timing curve doesn't merge — the old curve keeps playing and the new one adds on top, so motion stays continuous but the old curve still runs out, which feels sluggish or overshoots on a reversal. Use a spring when the user can reverse it. `phaseAnimator` and `keyframeAnimator` are SwiftUI's keyframes: a re-trigger rebuilds the track from the current value and keeps its velocity, but it still plays the authored track and can't follow a changing target. Keep them for fixed, authored sequences, off gestures and retargeting state.
- **Springs for gestures**, because they carry velocity through an interruption. Hand the gesture's velocity over with `.interpolatingSpring(..., initialVelocity:)` — see `../gestures/SKILL.md`.
- **Exit the way it entered.** A toast that slides in from the bottom leaves through the bottom: one `.move(edge: .bottom)` transition covers both. Symmetric paths are what make swipe-to-dismiss feel obvious.
- **Asymmetric timing where the user is deciding.** Slow on the deliberate phase (a hold-to-confirm press: 2 s linear), snappy on the system response (release: 200 ms ease-out). For insertion vs removal, `.transition(.asymmetric(insertion:removal:))`.

### 7. Reduce Motion and pointer hover

Ships with the animation, every time.

```swift
import SwiftUI

struct SlidingPanel: View {
    @Binding var isOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            if isOpen {
                Text("Filters")
                    .font(.headline)
                    .frame(maxHeight: .infinity)
                    .padding()
                    .background(.regularMaterial)
                    // Same timing, opacity only: drop the position change.
                    .transition(reduceMotion ? .opacity : .move(edge: .leading))
            }
        }
        .animation(.emilDrawer(0.4), value: isOpen)
    }
}
```

Reduce Motion means **fewer and gentler** animations, not zero — keep transitions that aid comprehension (opacity, color), remove movement, scaling and position changes.

**Hover is pointer-only.** Touches never fire `.onHover`, so there's no false hover on tap to gate the way the web does. But hover exists only on iPad with a trackpad and on Mac, so it must never be the only affordance. Prefer the system `.hoverEffect(.highlight)` / `.hoverEffect(.lift)`; for custom hover motion (a card lifting to `scale 1.05`) use `.onHover` with the CSS `ease` curve and the same Reduce Motion branch.

## Recipes

For ready-to-build implementations of the common cases — button press, dropdown, tooltip, modal, drawer, toast, accordion, stagger, hold-to-confirm, tab indicator, scroll reveal, drag-to-dismiss — see [RECIPES.md](RECIPES.md). Load it whenever the request matches one of those components; start from the recipe rather than from a blank file.

## Never Ship

Self-check before you finish. Each of these is an automatic block in `review-animations`:

| Never | Instead |
| --- | --- |
| A broad `withAnimation` around unrelated state, or `.animation(_:value:)` high in the tree (the native `transition: all`) | Scope `.animation(_:value:)` to the view that changes, or `.animation(_:body:)` to specific modifiers |
| A scale transition from nothing, or a bare `.scale` | `.scale(scale: 0.95).combined(with: .opacity)` |
| `.easeIn` on a UI element | `.emilEaseOut()` or a strong custom curve |
| Built-in `.easeOut` on a deliberate animation | `.emilEaseOut()` — `timingCurve(0.23, 1, 0.32, 1)` |
| Animation on a `.keyboardShortcut` or 100+/day action | No animation |
| UI duration over 300 ms with no reason | 150–250 ms |
| Centered `anchor` on a trigger-anchored custom popover | `anchor:` at the trigger (modals exempt) |
| `keyframeAnimator` / `phaseAnimator` on toasts, toggles, rapidly-triggered elements | State animation with a spring or a timing curve |
| Animating `.frame` / `.padding` / font size / spacing | `.offset` / `.scaleEffect` / `.opacity` |
| Retiming `.sheet`, `NavigationStack`, `Menu` or other system motion | Leave it; the system owns it |
| Custom hover motion as the only affordance | `.hoverEffect`, plus a visible touch affordance |
| No `accessibilityReduceMotion` branch | Gentler variant, not zero |
| Everything entering at once | 30–80 ms stagger |

## Output

Write the code. Then, in at most a few lines:

- **The gate result** — frequency tier and the named purpose. If something in the request was rejected, say which and why.
- **The ingredients** — tool, modifiers, curve, duration or spring config, in one line each.
- **What to feel-check** — if the result depends on feel you can't judge from code (a crossfade, a spring's bounce, the opacity/height balance in an entering list), say so and point at the check: play it with Simulator ▸ Debug ▸ Slow Animations or at 2–5× duration in an Xcode preview, record the screen and step it frame by frame, test gestures and haptics on a real device (the Simulator has no haptics, no real touch latency and no ProMotion), and look again the next day with fresh eyes.

Don't pad this into a report. The code is the deliverable.

## Tone

Opinionated and brief. When the honest answer is "this shouldn't animate," give it — that answer is the reason this skill exists. When feel genuinely can't be settled from code, say so instead of guessing at a value.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| CSS `@starting-style` for mount entrances | No CSS; nothing to emulate | `.transition(_:)` on a view inserted inside `if`, state changed in `withAnimation` |
| WAAPI (`element.animate()`) as the no-library programmatic tool | Browser API | `withAnimation(_:completionCriteria:_:completion:)`; Core Animation when it must run on the render server |
| Motion ≥ 14.2 hardware-accelerating `x`/`y`/`scale`, full `transform` string fallback | Library- and browser-specific | None needed: `offset`/`scaleEffect` are render-time effects in every SwiftUI version |
| `var(--transform-origin)` supplied by Base UI | React library variable | System `.popover` anchors itself; custom panels pass `anchor:` |
| `@media (hover: hover) and (pointer: fine)` gate | Touches don't fire `.onHover`, so there's no false hover to gate | Never make hover the only affordance; `.hoverEffect` |
| "Only `transform`/`opacity`: they skip layout and paint and run on the GPU" (the compositor reason) | No developer-facing compositor or layer promotion | Same advice, different reason: render-time effects skip layout; measure in Instruments |
| DevTools animation inspector | Browser tool | Simulator ▸ Debug ▸ Slow Animations; Instruments ▸ SwiftUI / Animation Hitches |
