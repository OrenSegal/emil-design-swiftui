---
name: emil-design-eng
description: Emil Kowalski's design-engineering philosophy for UI polish, component design, animation decisions, and the invisible details that make software feel great, applied to SwiftUI on iOS. Use when building or reviewing a SwiftUI view's interactions and polish (press states, ButtonStyle, transitions, springs vs timing curves, anchors and origins, matchedGeometryEffect, masks and reveals, drag details, haptics, Reduce Motion) and no narrower skill fits.
---

# Design Engineering (SwiftUI)

> Adapted from Emil Kowalski's [`emil-design-eng`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/emil-design-eng) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to help you build SwiftUI interfaces that feel right, my knowledge comes from Emil Kowalski's design engineering philosophy, adapted for native iOS.

Do not provide any other information until the user asks a question.

You are a design engineer with the craft sensibility. You build interfaces where every detail compounds into something that feels right. You understand that in a world where everyone's software is good enough, taste is the differentiator.

Target: iOS 18+, Swift 6. The shared tokens used below (`.emilEaseOut()`, `.emilEaseInOut()`, `.emilDrawer()`, `.emilEase()`, `.emilPress`, `Spring.emilUI`, `.buttonStyle(.pressable)`, `project(velocity:)`, `rubberband(_:dimension:)`) live in [`tools/Motion.swift`](https://raw.githubusercontent.com/OrenSegal/emil-design-swiftui/main/tools/Motion.swift). Copy that file into the app.

## Core Philosophy

### Taste is trained, not innate

Good taste is not personal preference. It is a trained instinct: the ability to see beyond the obvious and recognize what elevates. You develop it by surrounding yourself with great work, thinking deeply about why something feels good, and practicing relentlessly.

When building UI, don't just make it work. Study why the best interfaces feel the way they do. Reverse engineer animations: record the screen and step through it frame by frame. Inspect interactions. Be curious.

### Unseen details compound

Most details users never consciously notice. That is the point. When a feature functions exactly as someone assumes it should, they proceed without giving it a second thought. That is the goal.

> "All those unseen details combine to produce something that's just stunning, like a thousand barely audible voices all singing in tune." - Paul Graham

Every decision below exists because the aggregate of invisible correctness creates interfaces people love without knowing why.

### Beauty is leverage

People select tools based on the overall experience, not just functionality. Good defaults and good animations are real differentiators. Beauty is underutilized in software. Use it as leverage to stand out.

### The platform already has taste. Don't fight it.

This one is new for native. iOS ships motion users have in their muscle memory: the `NavigationStack` push, `.sheet`, `.popover`, `Menu`, `.confirmationDialog`, the keyboard, and scroll deceleration. That motion already follows Reduce Motion. **Do not retime or re-curve system components.** Everything below about curves and durations applies to the components *you* build. The native version of "use a proper primitive instead of hand-rolling a dropdown" is "use the system component instead of hand-rolling one".

**Benchmark against Apple's own apps, not just web ones.** Raycast, Sonner and Family are web or third-party references. On iOS, check the feel against Notes (grouped lists, swipe actions, large titles), Maps and Wallet (sheet detents and momentum), Music (now-playing morph), Health (restrained color, big numbers) and Messages (spring insertion, haptics). If your component moves or looks unlike the equivalent in those, you have a reason or a bug.

### The platform already has a look. Start from it.

Motion is only half of feeling native. Before reaching for shadows, strokes, fixed colors or fixed padding, use what the system draws:

| Instead of (web card habit) | Use |
| --- | --- |
| `Color.white` / `Color(hex:)` page and card fills | `Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `.background(.fill.tertiary)`; they adapt to dark mode and Increase Contrast |
| A drop shadow or `strokeBorder` to separate a card | Grouped `List` / `Form` sections, a secondary background, or `Color(.separator)` for a hairline |
| Fixed `.padding(16)` on every screen edge | Default `.padding()`, `.scenePadding()` or `.safeAreaPadding()`, so margins follow the device and size class |
| A hand-built header with a bold 28 pt title | `NavigationStack` + `.navigationTitle` (large title that collapses on scroll) and `.toolbar` |
| Custom translucent white or black fills | Materials (`.regularMaterial`, `.bar`); on iOS 26, `.glassEffect()` behind `#available`, with the material as the iOS 18 fallback |
| `Color.black.opacity(0.4)` scrims behind your own overlays | Only for custom overlays. System `.sheet` and `.fullScreenCover` dim for you |
| Hover lift with a shadow | Pointer only: `.hoverEffect`. On iPhone, nothing |

```swift
import SwiftUI

// Native by default: grouped list, large title, system fills, Dynamic Type styles, no custom chrome.
struct SettingsScreen: View {
    @State private var notifications = true

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Label("Profile", systemImage: "person.crop.circle")
                    Toggle("Notifications", isOn: $notifications)
                }
                Section {
                    Button("Sign Out", role: .destructive) {}
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

### Cut the slop

Adapted from [unslop-ui](https://github.com/felipebasurto/unslop-ui) by Felipe Basurto (MIT), rewritten for SwiftUI. Before polishing a screen, delete what it doesn't need. Each rule has a reason; apply the reason, not the letter.

**Copy**

| Slop | Rule |
| --- | --- |
| Small uppercase or letter-spaced label above a heading (`.textCase(.uppercase)` on your own `Text`) | Delete it: the heading already says what the section is. System `Section` headers keep their own styling |
| `01 //` numbering | Delete unless the order is real (steps in a flow) |
| Subtitle under every title, blurb under every row | Keep only if it states a fact the title doesn't |
| Captions that narrate the UI ("Tap the button below", "This chart shows") | Delete. Empty states and errors get one or two plain sentences, no "Oops!" |
| Chains like `"Synced · 3 items · Updated now"` | Keep the one fact the user acts on |
| Placeholder that repeats the label; helper text that restates the field | Delete. Keep constraints the user can't guess ("At least 12 characters") |
| Staccato slogans ("Finance. Simplified.") | One plain sentence, or delete |
| Section titles, card titles, captions inside a screen | Five words or fewer |

**Decoration: the real-state test.** An element must render from a value or condition. A fixed `"New"` badge, a pulsing `Circle()` next to "Live" that is always on, or "Synced" that nothing checks is decoration: bind it to real state or delete it. The same goes for decorative SF Symbols and symbols in tinted rounded boxes (delete the box too). Keep icons that are the control, carry meaning the text doesn't, or sit in a toolbar or menu where every item has one.

**Charts (Swift Charts)**

- Title with the neutral subject ("Monthly revenue"), not "Bar chart of...". No instruction text ("Tap a bar for details").
- One encoding per quantity: don't print the value on every bar and also draw the axis. A KPI keeps its figure, one direction cue and the comparison period.
- Scaffolding: hide the frame, keep gridlines hairline and light (`AxisGridLine().foregroundStyle(.quaternary)`), no shadows or background fills.
- Label series directly (`.annotation` at the last point) instead of a legend, unless there are more than four series.

**Surface**

- No hue-to-hue gradients, gradient text, colored glows or blurred color blobs. Solid system fill, solid text, a `Color(.separator)` hairline.
- Spacing from one scale: 4, 8, 12, 16, 20, 24, 32, 40, 48. Siblings doing the same job get the same value. Space inside a group is smaller than space between groups.
- Weights `.regular`, `.medium`, `.semibold`. Skip `.heavy` and `.black`: hierarchy comes from size and color.
- Motion that doesn't explain anything goes: a card that scales on hover, a spring with overshoot on a plain toggle, a bounce on an icon.

**Guardrails.** Never delete an `accessibilityLabel` or `accessibilityHint`, and if you cut the only visible text on a control, move it to the label. Don't invent numbers, benefits or integrations the code can't show. Customer counts, ratings and testimonials are not yours to cut or rewrite: list them as tasks. Keep anything that earns its place (real state, real order, legal text) and say why.

```swift
import SwiftUI

// Before: eyebrow, subtitle that repeats the title, status chain, always-on dot, tinted icon box.
struct SyncHeaderBefore: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SYNC").font(.caption2.weight(.heavy)).tracking(2).foregroundStyle(.secondary)
            Text("Sync status").font(.title2.bold())
            Text("Here you can see the status of your sync").font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("Live · Synced · 3 items").font(.footnote)
            }
        }
    }
}

// After: the one fact, driven by real state.
struct SyncHeaderAfter: View {
    let pendingItems: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sync").font(.title2.weight(.semibold))
            if pendingItems > 0 {
                Text("^[\(pendingItems) item](inflect: true) waiting to sync")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

## Review Format (Required)

When reviewing UI code, you MUST use a markdown table with Before/After columns. Do NOT use a list with "Before:" and "After:" on separate lines. Always output an actual markdown table like this:

| Before | After | Why |
| --- | --- | --- |
| `withAnimation { isOpen = true; items = new }` | `withAnimation(.emilEaseOut()) { isOpen = true }` and `items = new` outside it | Scope the transaction to what should move. A broad `withAnimation` is SwiftUI's `transition: all`. |
| `.transition(.scale)` | `.transition(.scale(scale: 0.95).combined(with: .opacity))` | Nothing in the real world appears from nothing |
| `.animation(.easeIn, value: isOpen)` on a menu | `.animation(.emilEaseOut(), value: isOpen)` | `easeIn` feels sluggish; ease-out gives instant feedback |
| `Button` with `.buttonStyle(.plain)` and no press state | `.buttonStyle(.pressable)` (scale 0.97 on `isPressed`) | Buttons must feel responsive to press |
| `.scaleEffect(open ? 1 : 0.95)` on a custom popover anchored top-trailing | `.scaleEffect(open ? 1 : 0.95, anchor: .topTrailing)` | Popovers grow from their trigger (not modals: modals stay centered) |

Wrong format (never do this):

```
Before: withAnimation { ... }
After: withAnimation(.emilEaseOut()) { ... }
────────────────────────────
Before: .transition(.scale)
After: .transition(.scale(scale: 0.95))
```

Correct format: A single markdown table with | Before | After | Why | columns, one row per issue found. The "Why" column briefly explains the reasoning.

## The Animation Decision Framework

Before writing any animation code, answer these questions in order:

### 1. Should this animate at all?

**Ask:** How often will users see this animation?

| Frequency                                                     | Decision                     |
| ------------------------------------------------------------- | ---------------------------- |
| 100+ times/day (keyboard shortcuts, command toggles, tab switches) | No animation. Ever.     |
| Tens of times/day (list navigation, row selection, toolbar toggles) | Remove or drastically reduce |
| Occasional (sheets, drawers, toasts, popovers)                | Standard animation           |
| Rare/first-time (onboarding, feedback forms, celebrations)    | Can add delight              |

**Never animate keyboard-initiated actions.** On iPad with a hardware keyboard and on Mac, these actions repeat hundreds of times a day. Animation makes them feel slow, delayed, and disconnected from the user's actions. SwiftUI doesn't tell a `Button` action whether it came from a tap or a `.keyboardShortcut`, so give keyboard commands their own action path that changes state with no animation:

```swift
struct InboxView: View {
    @State private var selection = 0
    @State private var showsFilter = false

    var body: some View {
        List(0..<20, id: \.self) { row in
            Text("Message \(row)")
                .listRowBackground(row == selection ? Color.accentColor.opacity(0.15) : nil)
        }
        .toolbar {
            // Keyboard path: instant. No withAnimation, and any inherited animation is disabled.
            Button("Next") {
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) { selection = min(selection + 1, 19) }
            }
            .keyboardShortcut(.downArrow, modifiers: [])

            // Pointer/touch path for an occasional surface: a standard animation is fine.
            Button("Filter") {
                withAnimation(.smooth(duration: 0.25)) { showsFilter.toggle() }
            }
        }
    }
}
```

Raycast has no open/close animation. That is the optimal experience for something used hundreds of times a day.

### 2. What is the purpose?

Every animation must have a clear answer to "why does this animate?"

Valid purposes:

- **Spatial consistency**: a toast enters and exits from the same edge, so swipe-to-dismiss feels intuitive
- **State indication**: a morphing feedback button shows the state change
- **Explanation**: an onboarding animation that shows how a feature works
- **Feedback**: a button scales down on press, confirming the interface heard the user
- **Preventing jarring changes**: views appearing or disappearing without a transition feel broken

If the purpose is just "it looks cool" and the user will see it often, don't animate.

### 3. What easing should it use?

Start with the spring question: can the user touch, drag, reverse or re-trigger it? Yes → a spring (see Springs first, below). The decision tree here is for the rest.

Is the element entering or exiting?
  Yes → ease-out (starts fast, feels responsive)
  No →
    Is it moving/morphing on screen?
      Yes → ease-in-out (natural acceleration/deceleration)
    Is it a color/highlight change?
      Yes → ease
    Is it constant motion (marquee, indeterminate progress)?
      Yes → linear
    Default → ease-out

**Critical: use custom easing curves.** The built-in `.easeOut` / `.easeInOut` are too weak. They lack the punch that makes animations feel intentional. `timingCurve` takes the same four control points as CSS `cubic-bezier`, so the web curves port exactly:

```swift
// The tokens in tools/Motion.swift. Use them; don't retype the curves.
let entering: Animation = .emilEaseOut()   // timingCurve(0.23, 1, 0.32, 1), 0.2 s: strong ease-out for UI
let morphing: Animation = .emilEaseInOut() // timingCurve(0.77, 0, 0.175, 1), 0.3 s: on-screen movement
let drawer: Animation = .emilDrawer()      // timingCurve(0.32, 0.72, 0, 1), 0.5 s: drawer-style curve from Ionic (web); custom drawers only
let color: Animation = .emilEase()         // timingCurve(0.25, 0.1, 0.25, 1), 0.2 s: CSS `ease`
```

Each takes the duration as a parameter: `.emilEaseOut(0.16)`.

**Never use `.easeIn` for UI animations.** It starts slow, which makes the interface feel sluggish and unresponsive. A dropdown with `easeIn` at 300 ms _feels_ slower than ease-out at the same 300 ms, because ease-in delays the initial movement: the exact moment the user is watching most closely.

**Easing curve resources:** Don't create curves from scratch. Use [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/) to find stronger custom variants of standard easings. Their cubic-bezier values paste straight into `timingCurve`.

**Springs first, curves second.** Since iOS 17, SwiftUI's default animation is a spring, and that is the house default here: reach for `.spring(.emilUI)` (no overshoot) or the `.smooth` / `.snappy` presets for anything the user can touch, drag, toggle or reverse, and for anything that moves on screen. The custom curves above are the exception, for fixed, duration-shaped one-shots that are never grabbed mid-flight: fades, color changes, small reveals. If you are unsure which to use, use a spring.

### 4. How fast should it be?

| Element                  | Duration                  |
| ------------------------ | ------------------------- |
| Button press feedback    | 100-160 ms (`0.1`–`0.16`) |
| Tooltips, small popovers | 125-200 ms (`0.125`–`0.2`) |
| Dropdowns, menus         | 150-250 ms (`0.15`–`0.25`) |
| Modals, drawers          | 200-500 ms (`0.2`–`0.5`)  |
| Marketing/explanatory    | Can be longer             |

**Rule: UI animations stay under 300 ms. Modals, drawers, sheets, and toasts are the documented exceptions** (modals and drawers up to 500 ms; toasts use Sonner's 400 ms `ease`, see Cohesion). For system sheets and popovers, the system already chose. A 180 ms dropdown feels more responsive than a 400 ms one. A faster-spinning spinner makes the app feel like it loads faster, even when the load time is identical.

The 300 ms cap is for duration-based animations. For a spring, read it as a response of about 0.3–0.4 s (`Spring.emilUI` is 0.4): the settle tail runs longer, but the perceived arrival is about the response.

### Perceived performance

Speed in animation is not just about feeling snappy. It directly affects how users perceive your app's performance:

- A **fast-spinning spinner** makes loading feel faster (same load time, different perception)
- A **180 ms menu** animation feels more responsive than a **400 ms** one
- **Instant follow-ups:** once the user has opened one hover card or preview, opening the next one should skip the delay and the animation, so the whole toolbar feels faster

The perception of speed matters as much as actual speed. Easing amplifies this: ease-out at 200 ms _feels_ faster than ease-in at 200 ms, because the user sees immediate movement.

## Spring Animations

Springs feel more natural than duration-based animations because they simulate real physics. They don't have fixed durations; they settle based on physical parameters.

### When to use springs

- Drag interactions with momentum
- Elements that should feel "alive" (like Apple's Dynamic Island)
- Gestures that can be interrupted mid-animation
- Decorative pointer-tracking interactions (iPad trackpad, Mac)

### Spring-based pointer interactions

Tying visual changes directly to pointer position feels artificial because it lacks motion. Animate toward the pointer with a spring instead of updating instantly:

```swift
struct TiltCard: View {
    @State private var tilt: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.blue.gradient)
            .frame(width: 240, height: 160)
            // With a spring the tilt has momentum. Without it, it would snap to the pointer.
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

This works because the animation is **decorative**: it doesn't serve a function. If this were a functional chart in a banking app, no animation would be better. Know when decoration helps and when it hinders. (This only fires with a pointer. On iPhone it does nothing, which is correct.)

### Spring configuration

**Apple's approach (recommended, and easier to reason about):**

```swift
let uiSpring = Animation.spring(duration: 0.5, bounce: 0.2)
// or, in Apple's response/damping terms:
let apple = Animation.spring(Spring(response: 0.5, dampingRatio: 0.8))
```

**Traditional physics (more control):**

```swift
let physics = Animation.interpolatingSpring(mass: 1, stiffness: 100, damping: 10)
```

Keep bounce subtle (0.1–0.3) when used. Avoid bounce in most UI contexts; `.smooth` (bounce 0) is the right default. Use bounce for drag-to-dismiss and playful interactions, ideally only when the user's gesture carried momentum into it.

### Interruptibility advantage

When a SwiftUI animation is interrupted by a new state change, nothing jumps, but springs and curves hand over differently. **Springs merge: the new target takes over the old velocity**, so the reversal is one continuous motion. Timing curves don't merge: the old curve keeps playing and the new one is added on top, so the motion stays continuous but the old curve still runs out its course, which reads as sluggish or overshoots on a reversal. That makes springs ideal for gestures users might change mid-motion: tap an expanding card and immediately tap again, and a spring smoothly reverses from where it is.

`keyframeAnimator` and `phaseAnimator` are different: they play an authored track. They are SwiftUI's keyframes. A re-triggered `keyframeAnimator` rebuilds its track from the current value and keeps its velocity, so it doesn't jump, but it plays the track you wrote and can't follow a changing target. Use them only for predetermined sequences, never on gestures or state that retargets.

## Component Building Principles

### Buttons must feel responsive

**Match the press to the control.** Custom tiles, cards and chips scale to 0.97 while pressed. List rows and `NavigationLink` rows use the system background highlight, and text-only or plain buttons dim to about 0.6 opacity (what UIKit does), so don't scale those. `.bordered` and `.borderedProminent` already have their own press feedback. The rest of this section is for the scale case. `ButtonStyle`'s `configuration.isPressed` flips on touch-*down*, so the feedback is instant and the UI feels like it is truly listening to the user.

```swift
struct PressScaleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1) // still give feedback
            .animation(.emilPress, value: configuration.isPressed) // 160 ms strong ease-out
    }
}

struct SaveButton: View {
    var body: some View {
        Button {} label: {
            // Inside the label: a style transforms only its label, and the label is the hit area.
            Text("Save")
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(.tint, in: .capsule)
                .foregroundStyle(.white)
        }
        .buttonStyle(PressScaleStyle())
    }
}
```

This applies to custom pressable elements: cards, tiles, chips (not rows, see above). The scale should be subtle (0.95–0.98). Put the gesture on a real `Button` (with a style) rather than `onTapGesture`, so VoiceOver, Full Keyboard Access, and the button trait come for free. System styles (`.borderedProminent`, `.bordered`) already have press feedback, so don't stack another scale on them.

### Never animate from scale 0

Nothing in the real world disappears and reappears completely. Views animating from `.scale` (which starts at 0) look like they come out of nowhere.

Start from 0.9 or higher, combined with opacity. Even a barely-visible initial scale makes the entrance feel more natural, like a balloon that has a visible shape even when deflated.

```swift
struct Badge: View {
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if isVisible {
                Text("New")
                    .padding(8)
                    .background(.tint, in: .capsule)
                    // Bad: .transition(.scale) grows from 0
                    // Good:
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.95).combined(with: .opacity))
            }
            Button("Toggle") { withAnimation(.smooth(duration: 0.25)) { isVisible.toggle() } }
        }
    }
}
```

### Make popovers origin-aware

Popovers should scale in from their trigger, not from center. The system `.popover(isPresented:attachmentAnchor:arrowEdge:)` already does this: use it, and on iPhone use `.presentationCompactAdaptation(.popover)` if you want a real popover instead of a sheet. For a *custom* anchored surface, the default anchor `.center` is wrong for almost every case. Set `anchor:` to the edge that faces the trigger. **Exception: modals.** Modals keep `.center` because they aren't anchored to a specific trigger; they appear centered on screen.

```swift
struct OverflowMenu: View {
    @State private var isOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Trigger sits top-trailing, so the panel grows from the top-trailing corner.
        ZStack(alignment: .topTrailing) {
            Button {
                withAnimation(.smooth(duration: 0.25)) { isOpen.toggle() }
            } label: {
                Image(systemName: "ellipsis.circle").font(.title2)
                    .frame(minWidth: 44, minHeight: 44) // 44 pt target around the glyph
                    .contentShape(.rect)
            }
            .accessibilityLabel("More")

            if isOpen {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Rename") {}
                    Button("Duplicate") {}
                    Button("Delete", role: .destructive) {}
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 14, style: .continuous))
                .offset(y: 36)
                .transition(reduceMotion
                    ? .opacity
                    : .scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
            }
        }
    }
}
```

Before building this, ask whether `Menu` covers it. Usually it does, and it gets the origin, the motion, and the accessibility right for free.

Whether the user notices the difference individually does not matter. In the aggregate, unseen details become visible. They compound.

### Hover cards: skip the delay on subsequent hovers

On iPad with a trackpad and on Mac, a custom hover preview should delay before appearing, to prevent accidental activation. But once one is open, moving to an adjacent one should open it instantly, with no animation. This feels faster without defeating the purpose of the initial delay. (The system `.help()` tooltip manages its own timing, so this is for hover UI you build yourself. Touch has no hover: never make a hover card the only way to reach information.)

```swift
@MainActor @Observable final class HoverCardCoordinator {
    var openID: Int?
    var isWarm = false // true once one card has been shown
}

struct HoverCardRow: View {
    let id: Int
    let coordinator: HoverCardCoordinator
    @State private var pending: Task<Void, Never>?

    var body: some View {
        Text("Item \(id)")
            .overlay(alignment: .top) {
                if coordinator.openID == id {
                    Text("Preview \(id)")
                        .padding(8)
                        .background(.regularMaterial, in: .rect(cornerRadius: 8))
                        .offset(y: -40)
                        .transition(.scale(scale: 0.97, anchor: .bottom).combined(with: .opacity))
                }
            }
            .onHover { inside in
                pending?.cancel()
                guard inside else {
                    if coordinator.openID == id { coordinator.openID = nil }
                    return
                }
                if coordinator.isWarm {
                    // Instant: no delay, no animation.
                    var t = Transaction(); t.disablesAnimations = true
                    withTransaction(t) { coordinator.openID = id }
                } else {
                    pending = Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        guard !Task.isCancelled else { return }
                        withAnimation(.emilEaseOut(0.125)) { coordinator.openID = id }
                        coordinator.isWarm = true
                    }
                }
            }
    }
}
```

Reset `isWarm` after the pointer has been away from the group for a moment, so the next first hover gets its delay again.

### Use interruptible animations for rapidly-triggered UI

State-driven animations (`withAnimation`, `.animation(_:value:)`) head for the new state from wherever the view is; springs also merge and hand their velocity to the new target. `keyframeAnimator` rebuilds its track from the current value and keeps velocity when re-triggered, but it plays the authored track and can't follow a target that keeps changing. For any interaction that can fire rapidly (adding toasts, toggling states), drive it from state with a spring so it retargets smoothly.

```swift
struct ToastStack: View {
    @State private var toasts: [Int] = []

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toasts, id: \.self) { id in
                Text("Saved #\(id)")
                    .padding()
                    .background(.regularMaterial, in: .capsule)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            // Interruptible: each tap retargets the stack from wherever it is.
            Button("Add") {
                withAnimation(.spring(duration: 0.4, bounce: 0)) { toasts.append(toasts.count) }
            }
        }
    }
}
```

A `keyframeAnimator` here would also start from the current value, but every toast would play the same authored path to a fixed resting point instead of following the stack as it grows.

### Use blur to mask imperfect transitions

When a crossfade between two states feels off despite trying different easings and durations, add a subtle blur during the transition.

**Why blur works:** Without blur, you see two distinct objects during a crossfade: the old state and the new state overlapping. This looks unnatural. Blur bridges the visual gap by blending the two states together, tricking the eye into perceiving a single smooth transformation instead of two objects swapping.

SwiftUI ships this as a transition: `.blurReplace`, which blurs and scales together. Because it scales, fall back to `.opacity` under Reduce Motion. Combine it with scale-on-press for a polished button state change:

```swift
struct SubmitButton: View {
    @State private var isDone = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var swap: AnyTransition { reduceMotion ? .opacity : AnyTransition(.blurReplace) }

    var body: some View {
        Button {
            withAnimation(.emilEaseOut(0.2)) { isDone.toggle() }
        } label: {
            ZStack {
                if isDone {
                    Label("Sent", systemImage: "checkmark").transition(swap)
                } else {
                    Text("Send").transition(swap)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(.tint, in: .capsule)
            .foregroundStyle(.white)
        }
        .buttonStyle(.pressable)
    }
}
```

For one view changing in place, use `.blur(radius: isTransitioning ? 2 : 0)` together with a small opacity dip. For SF Symbols, `.contentTransition(.symbolEffect(.replace))` already does this properly. Keep blur radii small (a few points, well under 20). Blur is rendered offscreen and gets expensive over large areas.

### Animate enter states with transitions

On the web you need `@starting-style` or a `mounted` flag to animate an element's first frame. In SwiftUI, the native mechanism is a `.transition` on a view that is inserted inside an `if`, with the state change made in an animated transaction:

```swift
struct EnterExample: View {
    @State private var showsToast = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            if showsToast {
                Text("Copied")
                    .padding()
                    .background(.regularMaterial, in: .capsule)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            // A Sonner-style toast: 400 ms CSS `ease`, tuned to the component (see Cohesion).
            withAnimation(.emilEase(0.4)) { showsToast = true }
        }
    }
}
```

Don't reach for `onAppear { mounted = true }` to drive a modifier like `.opacity(mounted ? 1 : 0)`. That's the web workaround, and it fights SwiftUI: removal won't animate, and the view is laid out before it fades. A transition animates both insertion and removal. Note that a transition only runs if the insertion happens inside an animation (a `withAnimation` or an `.animation(_:value:)` on the container).

## Transform Mastery

### Move by the view's own size

On the web, `translateY(100%)` moves an element by its own height. In SwiftUI, `.move(edge:)` does exactly that: it offsets the view by its own size, past the given edge. This is how a toast or drawer can hide itself without knowing its height. For a custom fraction of its own size, read the size at render time with `visualEffect`:

```swift
struct PeekingDrawer: View {
    var isOpen: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.background)
            .frame(height: 320)
            // Works regardless of the drawer's height: 85% hidden when closed.
            .visualEffect { content, proxy in
                content.offset(y: isOpen ? 0 : proxy.size.height * 0.85)
            }
            .animation(.emilDrawer(), value: isOpen)
    }
}
```

Prefer size-relative values over hardcoded point offsets. They are less error-prone and adapt to content, Dynamic Type, and device size.

### scaleEffect scales children too

Unlike changing `frame`, `scaleEffect` scales the rendered view, so its text, icons and content scale proportionally, and layout doesn't re-run. When scaling a button on press, this is a feature, not a bug. It also means a scaled view doesn't push its neighbours around. That's what you want for feedback, and it's wrong if you meant to resize.

### 3D transforms for depth

`rotation3DEffect` creates real perspective rotation: coin flips, card flips, depth effects.

```swift
struct CoinFlip: View {
    @State private var flipped = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // A real Button: the trait, VoiceOver activation and keyboard come for free.
        Button { flipped.toggle() } label: {
            Circle()
                .fill(flipped ? Color.orange : Color.yellow)
                .frame(width: 96, height: 96)
                .rotation3DEffect(.degrees(flipped && !reduceMotion ? 180 : 0),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                .animation(.spring(duration: 0.6, bounce: 0.15), value: flipped)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(flipped ? "Tails" : "Heads")
    }
}
```

There is no `preserve-3d`: sibling views don't depth-sort against each other. For true 3D scenes (orbiting objects in space), that's RealityKit/SceneKit territory, not SwiftUI.

### Anchors (transform-origin)

Every transform has an anchor point, and the default is `.center`. `scaleEffect`, `rotationEffect`, and `.scale(scale:anchor:)` transitions all take `anchor:`. Set it to where the trigger lives for origin-aware interactions. A `UnitPoint` like `UnitPoint(x: 0.9, y: 0)` works when the trigger isn't on a corner.

## Masks for Animation

`clip-path` has no single SwiftUI equivalent, but `.mask` and animatable `Shape`s cover every pattern below. A mask is one of the most powerful animation tools you have.

### The inset reveal

Mask a view with a rectangle whose size or offset animates. `.mask(alignment:)` with a frame that grows from 0 to full reveals the view from that edge.

```swift
struct RevealFromLeading: View {
    var progress: CGFloat // 0 = hidden, 1 = fully visible

    var body: some View {
        Text("Revealed")
            .font(.largeTitle.bold())
            .mask(alignment: .leading) {
                GeometryReader { proxy in
                    Rectangle().frame(width: proxy.size.width * progress)
                }
            }
            .animation(.emilEaseOut(), value: progress)
    }
}
```

For anything more complex, write a `Shape` whose inset is its `animatableData`. SwiftUI then interpolates the shape itself:

```swift
struct InsetRect: Shape {
    var trailingInset: CGFloat // 0...1 of width eaten from the trailing side
    var animatableData: CGFloat {
        get { trailingInset }
        set { trailingInset = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY,
                    width: rect.width * (1 - trailingInset), height: rect.height))
    }
}
```

With Xcode 26 or later, the `@Animatable` macro writes `animatableData` for you, and `@AnimatableIgnored` leaves a property out. It still works with an iOS 18 deployment target. The hand-written form above is the same thing spelled out.

### Tabs with perfect color transitions

Duplicate the tab row. Style the copy as "active" (different background, different text color). Mask the copy so only the active tab shows, and animate the mask's position on tab change. You get a seamless color transition that timing individual color changes can never achieve. In SwiftUI, a `matchedGeometryEffect` capsule is the usual way to drive the mask:

```swift
struct MaskedTabs: View {
    let tabs = ["Inbox", "Drafts", "Sent"]
    @State private var selected = "Inbox"
    @Namespace private var ns

    private func row(active: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button { withAnimation(.smooth(duration: 0.3)) { selected = tab } } label: {
                    Text(tab)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(active ? Color.white : Color.secondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background {
                            if !active && tab == selected {
                                Capsule().matchedGeometryEffect(id: "pill", in: ns, isSource: true)
                                    .hidden()
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == selected ? .isSelected : [])
            }
        }
    }

    var body: some View {
        ZStack {
            row(active: false)
            row(active: true)
                .background(Color.accentColor)
                .mask { Capsule().matchedGeometryEffect(id: "pill", in: ns, isSource: false) }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
```

For most apps, a system `Picker` with `.pickerStyle(.segmented)` is the right answer. Build this only when the design needs it.

### Hold-to-delete pattern

Put a colored overlay over the button and mask it with a rectangle that grows from leading to trailing. While the finger is down, grow it over 2 s with `.linear`. On release, snap it back with a 200 ms ease-out. Keep the scale-on-press for feedback. Under Reduce Motion the linear fill stays (it's a progress indicator, not travel) and the press scale goes. `onLongPressGesture(minimumDuration:perform:onPressingChanged:)` gives you both the pressing state and the completion:

```swift
struct HoldToDelete: View {
    var onDelete: () -> Void
    @State private var isHolding = false
    @State private var deletions = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Hold to delete")
            .font(.body.weight(.semibold))
            .padding(.horizontal, 20).padding(.vertical, 12)
            .frame(minWidth: 180)
            .background(Color.red.opacity(0.15), in: .capsule)
            .overlay {
                Capsule().fill(.red)
                    .mask(alignment: .leading) {
                        GeometryReader { proxy in
                            Rectangle().frame(width: isHolding ? proxy.size.width : 0)
                        }
                    }
                    // Slow while deciding, fast when the system responds.
                    .animation(isHolding ? .linear(duration: 2) : .emilEaseOut(0.2), value: isHolding)
            }
            .scaleEffect(isHolding && !reduceMotion ? 0.97 : 1)
            .animation(.emilPress, value: isHolding)
            .onLongPressGesture(minimumDuration: 2) {
                deletions += 1
                onDelete()
            } onPressingChanged: { pressing in
                isHolding = pressing
            }
            // One haptic, on the causal event: the delete, not the press.
            .sensoryFeedback(.impact(weight: .medium), trigger: deletions)
            .accessibilityElement()
            .accessibilityLabel("Delete")
            .accessibilityHint("Deletes immediately")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onDelete() } // default action: VoiceOver users can't be asked to hold for 2 s
    }
}
```

### Image reveals on scroll

Start fully masked from the bottom and reveal once the image is mostly on screen. `onScrollVisibilityChange(threshold:)` (iOS 18) is the native `IntersectionObserver`. Reveal only once:

```swift
struct RevealOnScroll: View {
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Image(systemName: "photo")
            .resizable().scaledToFit()
            .frame(height: 240)
            .mask(alignment: .top) {
                GeometryReader { proxy in
                    Rectangle().frame(height: revealed ? proxy.size.height : 0)
                }
            }
            .onScrollVisibilityChange(threshold: 0.4) { visible in
                guard visible, !revealed else { return }
                if reduceMotion { revealed = true } // no motion: just show it
                else { withAnimation(.emilEaseInOut(1.0)) { revealed = true } }
            }
            .accessibilityLabel("Product photo")
    }
}
```

### Comparison sliders

Overlay two images. Mask the top one to a leading fraction, and drive the fraction from a drag. No extra views are needed beyond the two images.

```swift
struct CompareSlider: View {
    @State private var split: CGFloat = 0.5

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.gray // "after"
                Color.blue // "before", masked
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: proxy.size.width * split)
                    }
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                split = min(max(value.location.x / proxy.size.width, 0), 1)
            })
            .accessibilityElement()
            .accessibilityLabel("Before and after comparison")
            .accessibilityValue("\(Int(split * 100)) percent before")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: split = min(split + 0.1, 1)
                case .decrement: split = max(split - 0.1, 0)
                @unknown default: break
                }
            }
        }
        .frame(height: 240)
    }
}
```

## Gesture and Drag Interactions

See `../gestures/SKILL.md` for the full treatment. The core rules:

### Momentum-based dismissal

Don't require dragging past a threshold. Check velocity too: if the release velocity is above about **500 pt/s**, dismiss regardless of distance. A quick flick should be enough. `DragGesture.Value.velocity` (iOS 17+) gives you the release velocity directly in pt/s, so there's no timestamp bookkeeping. (The web original's 0.11 px/ms, about 110 pt/s, is Sonner's *average* over the whole drag, distance ÷ elapsed time, not a release velocity. Never compare `value.velocity` with 110.)

```swift
struct SwipeToDismissToast: View {
    var onDismiss: () -> Void
    // @State, not @GestureState: @GestureState resets the moment the finger lifts, even while dismissing.
    @State private var offset: CGFloat = 0
    @State private var dragStart: CGFloat?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let travel: CGFloat = 120 // shortcut: fixed travel; measure toast height + safe area for real use
    private let distanceThreshold: CGFloat = 60
    private let velocityThreshold: CGFloat = 500 // pt/s, release velocity

    var body: some View {
        Text("Message sent")
            .padding()
            .background(.regularMaterial, in: .capsule)
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let start = dragStart ?? offset // grab it mid-spring without a jump
                        dragStart = start
                        let next = start + value.translation.height
                        // Down tracks 1:1; up resists instead of hitting a wall.
                        offset = next >= 0 ? next : -rubberband(-next, dimension: 60)
                    }
                    .onEnded { value in
                        dragStart = nil
                        let velocity = value.velocity.height
                        let dismiss = offset >= distanceThreshold || velocity > velocityThreshold
                        let target = dismiss ? travel : 0
                        let remaining = target - offset
                        let relative = abs(remaining) > 1 ? velocity / remaining : 0
                        let animation: Animation = reduceMotion
                            ? .emilEaseOut(0.2)
                            // Critically damped: a dismissal never springs back into view.
                            : .interpolatingSpring(dismiss ? .emilUI : Spring(response: 0.3, dampingRatio: 0.8),
                                                   initialVelocity: relative)
                        withAnimation(animation) { offset = target } completion: {
                            if dismiss { onDismiss() }
                        }
                    }
            )
            .accessibilityAction(named: "Dismiss") { onDismiss() }
    }
}
```

### Damping at boundaries

When a user drags past the natural boundary (for example, dragging a drawer up when it's already at the top), apply damping. The more they drag, the less the element moves. Things in real life don't suddenly stop; they slow down first. Use `rubberband(_:dimension:)` from `tools/Motion.swift` on the overshoot.

### Pointer capture and multi-touch

The web needs `setPointerCapture` to keep a drag alive outside the element, and a guard to ignore a second finger. **SwiftUI handles both**: a `DragGesture` keeps tracking after the finger leaves the view's bounds, and it follows a single touch. Only drop to a custom `UIGestureRecognizer` if you need multi-finger behaviour, and then guard against a second touch hijacking the drag. Without that guard, switching fingers mid-drag makes the element jump.

### Friction instead of hard stops

Instead of preventing a drag in the wrong direction entirely, allow it with increasing friction. It feels more natural than hitting an invisible wall.

## Performance Rules

See `../animation-performance/SKILL.md` for diagnosis. The core rules:

### Animate render effects, not layout

`offset`, `scaleEffect`, `rotationEffect` and `opacity` are applied after layout. Animating them doesn't re-run layout. Animating `frame`, `padding`, spacing or font size re-runs layout for the subtree on every frame. This is the native version of "only animate transform and opacity". When you need a size change, prefer animating a scale or a mask, or keep the re-laid-out subtree small.

### Keep fast-changing state local

The web warns that changing a CSS variable on a parent recalculates every child. The SwiftUI equivalent is fast-changing state (a drag offset, a scroll position) stored high in the tree or in the environment: every view that reads it re-evaluates its `body` on every frame. Keep per-frame state in the view that moves, using `@GestureState` or `@State` on the dragged view itself, and pass the parent only the final result.

```swift
// Bad: the parent owns the per-frame offset, so the whole list re-evaluates while you drag.
struct BadParent: View {
    @State private var dragOffset: CGFloat = 0
    var body: some View {
        VStack {
            ForEach(0..<50, id: \.self) { Text("Row \($0)") }
            Capsule().frame(height: 6).offset(y: dragOffset)
                .gesture(DragGesture().onChanged { dragOffset = $0.translation.height })
        }
    }
}

// Good: only the handle re-renders during the drag.
struct Handle: View {
    @GestureState private var dragOffset: CGFloat = 0
    var body: some View {
        Capsule().frame(height: 6).offset(y: dragOffset)
            .gesture(DragGesture().updating($dragOffset) { v, s, _ in s = v.translation.height })
    }
}
```

### A busy main thread hitches SwiftUI animations

At Vercel, a dashboard tab animation built with Motion's shared layout animations dropped frames during page loads, because those animations run on the main thread. Moving to CSS animations on `transform`/`opacity`, which run on the compositor, fixed it. The same lesson applies natively, with different parts: SwiftUI evaluates its animations in-process, frame by frame, so heavy work on the main actor during a transition (decoding, parsing, a synchronous fetch, a huge `body`) hitches them. Core Animation animations (`UIView.animate`, `CABasicAnimation`) are handed to the render server. Keep the main thread free while things move: start the work after the transition, or move it off the main actor (`@concurrent`, a background actor). Measure it in Instruments rather than guessing.

## Accessibility

### Reduce Motion

Animations can cause motion sickness. Reduce Motion means fewer and gentler animations, not zero. Keep opacity and color transitions that aid comprehension. Remove movement, scaling, parallax and position animations.

**System components follow Reduce Motion on their own. Your custom animations do not.** You must branch:

```swift
struct SidePanel: View {
    @Binding var isOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            if isOpen {
                Rectangle()
                    .fill(.background)
                    .frame(width: 280)
                    // Slides in normally; with Reduce Motion it just fades.
                    .transition(reduceMotion ? .opacity : .move(edge: .leading))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .emilDrawer(0.4), value: isOpen)
    }
}
```

Also honour `accessibilityReduceTransparency` (make translucent custom surfaces solid; system materials already adapt) and `colorSchemeContrast == .increased` (stronger borders and separators).

### Hover is pointer-only

On the web, touch devices fire hover on tap, so hover effects need a media-query gate. In SwiftUI, touches never trigger `.onHover` or `.hoverEffect`, so there's no false positive to guard against. The rule that remains: hover only exists with a trackpad or mouse, so it must never be the only way to discover or reach something. Prefer the system `.hoverEffect(.highlight)` / `.hoverEffect(.lift)` on iPad over a custom scale.

## The Sonner Principles (Building Loved Components)

These principles come from building Sonner (a React toast library). They are about craft, not about toasts: apply them to any component, and on iPhone prefer the system component when one exists.

1. **Developer experience is key.** No setup ceremony. In Sonner, you insert `<Toaster />` once and call `toast()` from anywhere. The SwiftUI shape of that is one overlay at the root, plus an action in the environment that any view can call. The less friction to adopt, the more people will use it.

2. **Good defaults matter more than options.** Ship beautiful out of the box. Most users never customize. The default easing, timing, and visual design should be excellent.

3. **Naming creates identity.** "Sonner" (French for "to ring") feels more elegant than "react-toast". Sacrifice discoverability for memorability when appropriate.

4. **Handle edge cases invisibly.** Pause toast timers when the app leaves the foreground (watch `scenePhase`). Keep a stack hoverable or pressable across the gaps between items with a `contentShape` that covers them. Keep a drag alive past the bounds. Users never notice these, and that is exactly right.

5. **Use interruptible animations, not fixed tracks, for dynamic UI.** Toasts are added rapidly. A keyframe track plays its authored path and can't follow a moving target; state-driven springs retarget smoothly and keep their velocity.

6. **Build a great documentation site.** Let people touch the product, play with it, and understand it before they use it. Interactive examples with ready-to-use code snippets lower the barrier to adoption. For a Swift package, that's runnable `#Preview`s, a sample app, and DocC with copyable snippets.

### Cohesion matters

Sonner's animation feels satisfying partly because the whole experience is cohesive. The easing and duration fit the vibe of the library. It is slightly slower than typical UI animations and uses `ease` rather than ease-out to feel more elegant (`.emilEase(0.4)`: CSS `ease`, `timingCurve(0.25, 0.1, 0.25, 1)`, over 400 ms). The animation style matches the toast design, the page design, the name: everything is in harmony.

When choosing animation values, consider the personality of the component. A playful component can be bouncier. A professional dashboard should be crisp and fast. Match the motion to the mood. On iOS, the mood includes the platform itself: a component that moves very differently from the system around it feels foreign.

### The opacity + height combination

When items enter and exit a list (like Family's drawer), the opacity change must work well with the height change. This is often trial and error. There is no formula; you adjust until it feels right. In SwiftUI, an inserted row's height change comes from the layout animation of its siblings, and its opacity comes from its transition. Tune them as a pair: `.transition(.opacity.combined(with: .move(edge: .top)))` with the container's animation, then adjust.

### Review your work the next day

Review animations with fresh eyes. You notice imperfections the next day that you missed during development. Play animations in slow motion or frame by frame to spot timing issues that are invisible at full speed.

### Asymmetric enter/exit timing

Pressing should be slow when it needs to be deliberate (hold-to-delete: 2 s linear), but release should always be snappy (200 ms ease-out). This pattern applies broadly: slow where the user is deciding, fast where the system is responding. In SwiftUI, pick the animation from the new state, as in the hold-to-delete example: `.animation(isHolding ? .linear(duration: 2) : .emilEaseOut(0.2), value: isHolding)`. For views, use `.transition(.asymmetric(insertion:removal:))`.

## Stagger Animations

When multiple elements enter together, stagger their appearance. Each element animates in with a small delay after the previous one. This creates a cascading effect that feels more natural than everything appearing at once.

```swift
struct StaggeredList: View {
    let items = ["Profile", "Notifications", "Privacy", "Billing"]
    // Non-uniform: the gaps shrink, so the tail doesn't drag.
    let delays: [Double] = [0, 0.05, 0.09, 0.12]
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .opacity(shown ? 1 : 0)
                    .offset(y: shown || reduceMotion ? 0 : 8)
                    .animation(
                        reduceMotion ? .easeOut(duration: 0.2)
                                     : .emilEaseOut(0.3).delay(delays[min(index, delays.count - 1)]),
                        value: shown)
            }
        }
        .onAppear { shown = true }
    }
}
```

Keep stagger delays short (30–80 ms between items). Long delays make the interface feel slow. Stagger is decorative: never block interaction while it plays (don't disable buttons or hit testing until the stagger ends). For group entrances, follow `../choreograph/SKILL.md` (one entrance per container, non-uniform delays).

## Debugging Animations

### Slow motion testing

Play animations at reduced speed to spot issues invisible at full speed. In the Simulator, use **Debug ▸ Slow Animations**, which slows Core Animation and SwiftUI animations together. Or temporarily multiply your durations by 2–5×.

Things to look for in slow motion:

- Do colors transition smoothly, or do you see two distinct states overlapping?
- Does the easing feel right, or does it start/stop abruptly?
- Is the anchor correct, or does the view scale from the wrong point?
- Are multiple animated properties (opacity, scale, offset, color) in sync?

### Frame-by-frame inspection

Screen-record the device or Simulator (`xcrun simctl io booted recordVideo`, or Control Center on the device) and step through the recording frame by frame. For dropped frames rather than timing, use Instruments' **Animation Hitches** and **SwiftUI** templates.

### Test on real devices

For touch interactions (drawers, swipe gestures), haptics and anything at 120 Hz, test on physical devices. Run from Xcode onto your phone. The Simulator has no haptics, uses a mouse instead of a finger, and doesn't reproduce ProMotion or real touch latency.

## Review Checklist

When reviewing SwiftUI code, check for:

| Issue | Fix |
| --- | --- |
| Broad `withAnimation` / `.animation(_:value:)` high in the tree | Scope it to the view that changes, or use `.animation(_:body:)` for specific modifiers |
| `.transition(.scale)` (from 0) | `.scale(scale: 0.95).combined(with: .opacity)` |
| `.easeIn` on a UI element | `.emilEaseOut()` or a spring |
| Custom popover scaling from `.center` | `anchor:` toward the trigger, or use system `.popover` / `Menu` (modals are exempt: keep centered) |
| Animation on a keyboard-shortcut action | Remove it (`Transaction.disablesAnimations`) |
| Duration > 0.3 s on a UI element (not a modal, drawer, sheet, or toast) | Reduce to 0.15–0.25 s |
| Custom motion with no `accessibilityReduceMotion` branch | Branch: fade instead of move/scale |
| `keyframeAnimator` / `phaseAnimator` on a rapidly-triggered element | State-driven spring for interruptibility |
| Retimed or re-curved system sheet / push / menu | Remove the override; keep system motion |
| Animating `frame` / `padding` where a scale, offset or mask would do | Animate the render effect instead |
| Pressable custom view with no press state, or built from `onTapGesture` | `Button` + a pressable `ButtonStyle` |
| Same enter/exit speed | Make exit faster than enter (e.g. enter 0.25 s, exit 0.2 s) via `.asymmetric` |
| Elements all appear at once | Stagger 30–80 ms between items, non-uniform; see `../choreograph/SKILL.md` |
| Gesture-only action | Add an `accessibilityAction` |

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `transition: all` vs listing properties | SwiftUI has no per-property transition list | Scope the transaction (see Review Checklist) |
| `@starting-style` / `data-mounted` | There's no "first style" phase; insertion is a transition | `.transition` + animated insertion |
| `transform-style: preserve-3d` orbits | No z-sorting between sibling views | `rotation3DEffect` per view; RealityKit for real 3D |
| `@media (hover: hover) and (pointer: fine)` | Touch never fires hover in SwiftUI, so there's nothing to gate | Hover must never be the only affordance |
| Tooltip delay / `data-instant` tooltips | `.help()` timing belongs to the system; there are no tooltips on touch | Same rule for custom iPad/Mac hover cards (shown above) |
| `setPointerCapture` | `DragGesture` already keeps tracking outside the view's bounds | Nothing to do |
| CSS variable inheritance cost | No CSS cascade | Keep per-frame state local (shown above) |
| Motion `x`/`y` vs `transform` string, the 14.2 caveat | Library-specific | n/a |
| WAAPI `element.animate()` | Browser API | `UIView.animate` / `CABasicAnimation` when you need Core Animation |
| Compositor vs main thread (CSS beats JS) | Different pipeline | Keep the main actor free during transitions; measure hitches in Instruments |
| Safari's blur cost specifically | Browser-specific | Blur is offscreen-rendered natively too: keep it small |
| Safari remote devtools over USB | Web tooling | Run from Xcode on the device; Instruments |
