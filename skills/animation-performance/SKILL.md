---
name: animation-performance
description: Keep SwiftUI animations inside the frame budget on iPhone. Animate render-time effects instead of layout, keep per-frame state local so `body` doesn't re-run across the tree, keep the main thread free during transitions, and find the cause with Instruments when an animation hitches. Use when a SwiftUI animation is janky, choppy, stutters, or hitches; when a drag gets slower as content grows; when choosing which modifier to animate; when reaching for `drawingGroup()`, `compositingGroup()` or `geometryGroup()`; or when a transition stutters only while data loads. For choosing easing, duration, or whether to animate at all use animate; for reviewing motion as a whole use review-animations.
---

# Animation Performance

> Adapted from Emil Kowalski's [`animation-performance`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/animation-performance) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to find out why your animation hitches and make it smooth, my knowledge comes from Emil Kowalski's design engineering philosophy.

Do not provide any other information until the user asks a question.

A diagnostic skill. It does ONE thing: make motion land every frame. It does not pick easing or duration (that's `animate`), or judge whether the motion should exist (that's `review-animations`). The question here is never "does it look right?" but "does each frame finish in time?".

This skill is a rewrite, not a translation. Emil's web original is built on the browser pipeline (layout, paint, composite, compositor threads, `will-change`). SwiftUI has a different pipeline, so the mechanics here are native. The method is his: name the cause, measure before fixing, and don't trust a fast machine.

## Why This Matters

Imagine [Sonner](https://sonner.emilkowal.ski/) running at 30fps. Same easing, same durations, same code. Nobody would have cared. (Web-origin example; the lesson transfers.) Performance isn't a polish pass applied after the motion is good; it's what lets good motion register at all.

## Operating Posture

You are a design engineer who has shipped sheets, cards, and lists to real iPhones and has had each of the traps below bite in production. You know the Simulator on an M-series Mac is the least representative device the animation will ever run on: it has no ProMotion and no real touch latency, and it borrows the Mac's CPU and GPU.

Two failure modes, and the first is worse:

1. **"It's smooth in the Simulator."** A fast Mac hides almost every problem in this skill. The bar is an older iPhone on device, and on a ProMotion screen the budget is half what you think.
2. **Sprinkling `drawingGroup()` and calling it fixed.** It's the last step, not the first. Most hitches are a layout-driving animation, state that re-evaluates too much of the tree, or a busy main thread, and `drawingGroup()` fixes none of them.

## Hard Rules

1. **Render-time effects by default.** Animate `offset`, `scaleEffect`, `rotationEffect`, and `opacity`. Animating `frame`, `padding`, or font size re-runs layout every frame. Anything else needs a reason. If a cheaper modifier produces the same visual, use it, even when the expensive one "seems fine".
2. **Name the cause before changing code.** Every fix you propose names which of the causes below it addresses. "Added `drawingGroup()`, seems smoother" is not a diagnosis.
3. **Never conclude "it's fine" from the Simulator or a new phone.** Say which findings you verified from code and which need an Instruments recording on a real device.
4. **Never a broad animation.** A `withAnimation` around a large state change, or `.animation(_:value:)` high in the tree, animates every change in that transaction, including layout nobody meant to animate. Scope it to the view that changes, or use `.animation(_:body:)` to limit it to specific modifiers.
5. **Don't trade correctness for a best-effort optimization.** `drawingGroup()` and friends change how things render, and they can break things (see below). Which modifiers you animate and where state lives are things you control. Spend effort there.

## The Symptom Table

Start here. Match what the user is seeing, then read the matching section.

| Problem | Solution |
| --- | --- |
| Animation stutters | Animate `offset`/`scaleEffect`/`opacity`, not `frame`/`padding` |
| Shadow animation is choppy | Give the shadow a shape: put it on a `background(Shape)` instead of on the content; measure |
| Hitches only during navigation or loading | Move the work off the main thread; don't decode, parse, or sort during the transition |
| Drag gets laggier as the screen grows | Per-frame state is stored too high; keep it in the dragged view with `@GestureState` |
| Hand-rolled per-frame animation hitches | Use a SwiftUI animation, `TimelineView`, or Core Animation, not a `Timer` writing state |
| Scroll stutters in a long list | `LazyVStack` / `List`, stable `id`s, cheap rows |
| Size-reading view hitches while scrolling | `onGeometryChange` instead of a `GeometryReader` writing state |
| Blur transition lags | Keep the blur radius small, on a small view; measure |
| Unexpected properties animate | Replace a broad `withAnimation` / high `.animation` with a scoped one |
| Children fly in from the wrong place during a resize | `geometryGroup()` on the container |
| Many-layer vector art hitches | `drawingGroup()`, once measured |

## The Frame Budget

60fps gives each frame **16.7 ms** (1000/60). ProMotion iPhones can refresh up to 120Hz, which leaves **8.3 ms**. Design against the smaller number.

Two things decide whether you stay inside it:

1. **What you animate**: how much work each frame costs (layout, rendering, offscreen passes).
2. **Where it runs**: whether that work can be blocked by everything else the main thread is doing.

### ProMotion

On iPhone, Core Animation caps your own animations at 60Hz unless the app opts in. Add this Boolean key to the app's Info.plist:

```xml
<key>CADisableMinimumFrameDurationOnPhone</key>
<true/>
```

Apple's article "Optimizing ProMotion refresh rates for iPhone 13 Pro and iPad Pro" covers it. Without the key, expect custom animations on iPhone to stay at 60Hz. Even with it, the system decides the actual rate, so confirm on device instead of assuming 120. The Simulator can't show any of this.

For a `CADisplayLink` you drive yourself, set `preferredFrameRateRange` (iOS 15+) to say what the animation needs instead of assuming 120.

## What You Animate

SwiftUI roughly does three kinds of work for a visual change:

- **Evaluate**: re-run `body` for every view whose dependencies changed.
- **Layout**: ask views for sizes and place them.
- **Render**: draw and composite the result (via Core Animation and the render server).

Every modifier enters at a different point:

| Tier | Modifiers | Cost |
| --- | --- | --- |
| Render-time effects | `offset`, `scaleEffect`, `rotationEffect`, `opacity`, `visualEffect` | Cheapest. They change how a view is drawn, not where it sits, so nothing is re-measured. |
| Offscreen passes | `shadow` on non-shape content, `blur`, `mask`, materials, `compositingGroup`, `drawingGroup` | No re-layout, but each can force the view to render into an offscreen buffer first. Cost grows with the view's size. |
| Layout | `frame`, `padding`, `font` size, `fixedSize`, inserting views into a stack | Most expensive. A growing view re-lays-out its siblings and parent every frame. |

**Swapping down a tier:**

| Instead of | Animate |
| --- | --- |
| `frame(width:height:)` / `padding` to grow or shrink | `scaleEffect(_:anchor:)` |
| `padding` / `position` / alignment to move | `offset` (or `visualEffect` to move by the view's own size) |
| `if` removing a view to hide it mid-gesture | `opacity`, then remove it when the gesture ends |
| `shadow` on a complex view | the same `shadow` on its `background(RoundedRectangle(...))` |

```swift
struct Card: View {
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Plan")
            .font(.headline)
            .padding()
            .background(
                // shadow on the background shape, not on the whole content tree; measure the difference
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.background)
                    .shadow(radius: 8, y: 4)
            )
            // render-time grow instead of animating frame/padding
            .scaleEffect(isExpanded && !reduceMotion ? 1.04 : 1)
            .opacity(isExpanded && reduceMotion ? 0.9 : 1)
            .animation(.emilEaseOut(), value: isExpanded)
    }
}
```

Two things follow, unchanged from the web version:

- **Layout animations don't always hitch.** A small, isolated view may animate its `frame` without visible cost. But when `scaleEffect` gives the look you want (it scales children too and keeps the layout space), only it can't regress on a slower device. Pick it.
- **Layout animations also move the wrong things.** Animating a sidebar's width pushes every sibling in the `HStack` on every frame; `offset` doesn't.

Sometimes the layout really must change (an accordion, a list row expanding). Then animate it, scope the animation to that view, and keep the subtree that re-lays-out small. Measure it.

## Where It Runs

**SwiftUI evaluates its animations in-process, on the main thread, every frame.** A spring or timing curve on `offset` is cheap, but the main thread has to be free to produce each frame. When it's busy decoding an image, parsing JSON, or running a large `body`, the frame is late and Instruments records a hitch.

Core Animation is the exception: an animation committed to a `CALayer` (`UIView.animate`, `CABasicAnimation`) runs on the render server once committed, so a busy main thread doesn't stop it mid-flight. That's the closest native analogue to "CSS runs on the compositor". In practice you rarely need to drop to Core Animation; you need to keep the main thread free.

**The pattern to watch for is motion that runs while the app is doing heavy work**: a push while the next screen loads, a sheet presenting while its content decodes, a tab change that triggers a fetch. Emil's web example: Vercel's dashboard tab indicator dropped frames because the next page was loading at the same moment. The native version of the fix is not "move it to CSS", it's "move the work":

```swift
struct DetailScreen: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            // load and decode off the main actor, so the push transition keeps its frames
            image = await Self.load(url)
        }
    }

    @concurrent nonisolated static func load(_ url: URL) async -> UIImage? {
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return await UIImage(data: data)?.byPreparingForDisplay()
    }
}
```

Also look for, on the main actor: synchronous `Data(contentsOf:)`, `JSONDecoder` on large payloads, sorting or filtering big arrays inside `body`, `DateFormatter` creation per row, and Core Data / SwiftData fetches kicked off by `onAppear` of the destination screen.

## Don't Animate Through Shared State

The web trap is `setState` every frame. The SwiftUI trap is the same shape: a value that changes every frame stored somewhere that many views read. Every reader re-runs `body` each frame.

Per-frame values are drag translations, scroll offsets, and timer ticks. Keep them in the view that moves:

```swift
struct DraggableChip: View {
    // Only the reset (finger lifted) animates; tracking stays 1:1. An `.animation(_, value: drag == .zero)`
    // would also animate the first tracking update, when the Bool flips, so the chip would lag the finger.
    @GestureState(resetTransaction: Transaction(animation: .spring(.emilUI)))
    private var drag: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Drag me")
            .font(.body)
            .padding()
            .background(.thinMaterial, in: Capsule())
            // only this view re-evaluates per frame; nothing above it reads `drag`
            .offset(drag)
            .gesture(
                DragGesture().updating($drag) { value, state, _ in
                    state = value.translation
                }
            )
            // Reduce Motion: the snap-back jumps instead of springing.
            .transaction { if reduceMotion { $0.animation = nil } }
            .accessibilityLabel("Draggable chip")
    }
}
```

Look for:

- A drag or scroll offset in an `@Observable` model, `@EnvironmentObject`, or the environment, read by a whole screen.
- An `ObservableObject` with `@Published` per-frame values: every view observing it re-evaluates, not just the ones reading that property. `@Observable` tracks per property, which helps, but only if per-frame values are read by few views.
- A `Timer.publish` or `Timer` writing `@State` at 60Hz high in the tree. For clocks and continuous motion, use `TimelineView(.animation)` around just the view that changes.

**The SwiftUI version of Vaul's CSS-variable trap:** Vaul's drag got laggy as the drawer filled up, because the drag distance was written where every child depended on it (web-origin anecdote). Native symptom: a drag gets slower as the screen gains content, with Instruments showing many `body` evaluations per frame. Cause: the drag value lives in a parent or the environment. Fix: `@GestureState` in the dragged view, as above.

## Two Traps That Look Correct

Both use render-time effects and still hitch.

**`GeometryReader` writing state.** A `GeometryReader` that stores its size in `@State` inside `onAppear` or `onChange` causes a second layout pass, and inside a scroll view it can do so every frame. Use `onGeometryChange` (back-deployed to iOS 16), which reports only the value you extract and only when it changes:

```swift
struct HeaderHeightReader: View {
    @State private var headerHeight: CGFloat = 0

    var body: some View {
        VStack {
            Text("Header").font(.largeTitle)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { newHeight in
                    headerHeight = newHeight
                }
            Text("Header is \(Int(headerHeight)) pt").font(.footnote)
        }
    }
}
```

For effects that only need geometry to draw (parallax, scale by position), skip state entirely: `visualEffect { content, proxy in ... }` or `scrollTransition` read geometry at render time without re-running `body`.

**Blur, masks, and materials.** `blur(radius:)`, `mask`, and `.ultraThinMaterial` render offscreen, and the cost grows with the radius and the size of the view. Emil's web number (keep animated blur under 20px; 2-5px softens a crossfade) is a Safari measurement, not a SwiftUI one. The native rule is the same in spirit: keep animated blur small and on small views, prefer `.transition(.blurReplace)` for the crossfade bridge, and measure before blurring anything full-screen.

## `drawingGroup()`, `compositingGroup()`, `geometryGroup()`

SwiftUI has no `will-change`. These three are the nearest tools, and each changes behaviour, not just speed.

| Modifier | What it does | Use when | Cost / risk |
| --- | --- | --- | --- |
| `drawingGroup()` | Apple: "Composites this view's contents into an offscreen image before final display." | Many overlapping shapes, gradients, or paths (charts, particle-like art) that animate together, once measured | Offscreen buffer the size of the view; UIKit-backed views (text fields, maps) may not render inside it, so check; measure that it helps |
| `compositingGroup()` | Apple: makes ancestor effects "such as opacity and the blend mode, take effect before this view is rendered" | Fading a group so overlapping children don't show through each other | An offscreen pass; correctness tool first, not a speed tool |
| `geometryGroup()` (iOS 17+) | Apple: "Isolates the geometry (e.g. position and size) of the view from its parent view," so children don't animate from stale positions | Children that "fly in" or tear apart while a parent's size or position animates | Changes animation behaviour; use to fix a visual bug, not speculatively |

**Add any of them only once you see the problem in a recording.** On the common path they do nothing useful, and each offscreen buffer costs memory.

## Long Lists

The web says "virtualize". SwiftUI already does it:

- `List` reuses rows. `LazyVStack` / `LazyVGrid` create rows only when they scroll near the screen. A plain `VStack` in a `ScrollView` builds every row up front.
- Give rows stable identity (`id:` from your model, never `\.self` on mutable values or `indices` of a collection that changes), or SwiftUI can't tell rows apart and rebuilds them.
- Keep row `body` cheap: no formatting, sorting, or image decoding inside it.
- Don't put a per-row `GeometryReader` writing state into a lazy stack. Use `onGeometryChange` or `scrollTransition`.

## Should You Drop to Core Animation?

Rarely. SwiftUI animations only suffer when the main thread is busy during them or when the work per frame is too large, and both are fixable in SwiftUI.

SwiftUI gives you things that are awkward in Core Animation: springs that keep velocity when interrupted, `matchedGeometryEffect`, removal transitions, state-driven gestures. The question is whether you need those, not whether SwiftUI animation is "allowed".

**The working split:** SwiftUI animations for almost everything; system components (`NavigationStack`, `.sheet`, `TabView`) for system motion; a `UIViewRepresentable` with Core Animation only for a measured case where something must keep moving while the main thread is unavoidably blocked (a loading spinner during a synchronous step you can't move).

## Workflow

### Phase 1: Find what animates

List every animation in scope with its driver and what it changes:

| Element | Driver | Changes | Plays during |
| --- | --- | --- | --- |
| Tab indicator | `matchedGeometryEffect` | frame (layout) | screen push |
| Sheet content | `.sheet` (system) | system | data load |
| Card | `withAnimation` around model update | everything in the transaction | tap |

Expand broad `withAnimation` blocks and high `.animation` modifiers into what they actually animate.

### Phase 2: Diagnose

Work down this list, roughly in order of how often each is the cause:

1. **What changes per frame?** Anything other than `offset`/`scaleEffect`/`rotationEffect`/`opacity` is the first suspect: `frame`, `padding`, and stack insertions first, then shadows on non-shape content, blur, masks, and materials, which don't look like layout and are easy to miss.
2. **Does the hitch coincide with the app being busy?** Navigation, fetching, decoding, a large first `body`. Move that work off the main thread or after the transition.
3. **Is `body` re-evaluated per frame across the tree?** Per-frame state stored high, in the environment, or in a broad `ObservableObject`.
4. **Does it get worse as content grows?** Shared per-frame state, a non-lazy stack, unstable `id`s, or a `GeometryReader` per row.
5. **Is a `GeometryReader` writing state, or a `Timer` driving `@State`?**
6. **Any large animated blur, mask, or material?**
7. **Still hitching on many-layer art, or children tearing during a resize?** Now consider `drawingGroup()` or `geometryGroup()`.

Confirm with a recording, not by feel. Profile a Release build on a real device:

- **Instruments ▸ SwiftUI** template: view body evaluations and update counts. Shows which views re-run per frame and why.
- **Instruments ▸ Animation Hitches**: which frames were late, and when.
- **Instruments ▸ Time Profiler**: what the main thread was doing during the hitch.
- **Simulator ▸ Debug ▸ Slow Animations** to see motion clearly (not to judge performance).
- In code, `let _ = Self._printChanges()` inside `body` logs why a view re-evaluated. Debug only; remove it before shipping.

Test on an older iPhone, not the newest one on your desk, and once on a ProMotion device with the Info.plist key set.

### Phase 3: Report

For each finding:

```
**[Element]**: `CardView.swift:42`
Cause: [which of the causes above]
Before: `.frame(height: isOpen ? 300 : 80)` animated by a screen-wide withAnimation (layout per frame)
After: `.scaleEffect(...)` scoped with `.animation(.emilEaseOut(), value: isOpen)`
Verified: from code / needs an Instruments recording on device
```

When the user wants a review table, use the required Before / After / Why format:

| Before | After | Why |
| --- | --- | --- |
| `.padding(isPressed ? 12 : 16)` animated | `.scaleEffect(isPressed ? 0.97 : 1)` | Padding re-runs layout every frame; scale is a render-time effect |
| Drag offset in an `@Observable` screen model | `@GestureState` in the dragged view | Only the dragged view re-evaluates per frame |
| `GeometryReader` + `@State` per row | `onGeometryChange(for:)` | No extra layout pass per frame |

Order findings by cost: layout before offscreen, busy-main-thread before idle. Then stop. Apply fixes when asked.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Layout / paint / composite tiers | Browser pipeline; SwiftUI has evaluate / layout / render | Render-time effects vs offscreen passes vs layout (tier table above) |
| `will-change: transform` | No developer-facing layer promotion in SwiftUI | Measure first; `drawingGroup()` only for measured many-layer art |
| CSS/WAAPI runs on the compositor thread | No compositor thread to opt into from SwiftUI; its animations evaluate in-process | Keep the main thread free; Core Animation via `UIViewRepresentable` for a measured case |
| CSS vs JS animation split | No CSS; SwiftUI is the default driver | SwiftUI animations by default; Core Animation only when measured |
| Motion `x`/`y` vs `transform` string, Motion 14.2+ | Library-specific | None needed |
| Motion layout animations on the main thread | Library-specific | `matchedGeometryEffect` also evaluates on the main thread; keep it free |
| `filter: drop-shadow()` instead of `box-shadow` | Browser-specific compositing behaviour | `shadow` on a `Shape` background; measure |
| `ref.current.style` instead of `setState` | React render model | `@GestureState` / local `@State` / `TimelineView` |
| Inherited CSS variables recalc every child | CSS cascade | Per-frame state stored high or in the environment (same symptom, different cause) |
| Chrome not accelerating percentage transforms | Browser-specific | None; `.move(edge:)` and `visualEffect` size by the view itself |
| Blur under 20px (Safari number) | Measured on Safari, not SwiftUI | Keep it small and measure |
| "Layout can take over 100 ms" (web figure) | Browser measurement; no native source | Measure in Instruments |
| DevTools Performance / Animations panel, remote debugging, CPU throttling | Browser tooling | Instruments (SwiftUI, Animation Hitches, Time Profiler) on device; Slow Animations |
