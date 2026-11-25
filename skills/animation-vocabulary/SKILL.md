---
name: animation-vocabulary
description: "Reverse-lookup glossary that turns a vague description of an iOS / SwiftUI animation or motion effect into its exact term, and the SwiftUI API that produces it (\"the bouncy thing when a popover opens\" → Pop in, `.transition(.scale(scale:).combined(with: .opacity))` with a bouncy spring; \"the iOS rubber-band scroll\" → Rubber-banding, ScrollView's default). Use when the user asks \"what's it called when…\" or \"which SwiftUI modifier does…\", or describes a motion effect without knowing its name and wants the right word to prompt an AI or designer with. For naming an effect, not designing or building one."
model: haiku
---

# Animation Vocabulary

> Adapted from Emil Kowalski's [`animation-vocabulary`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/animation-vocabulary) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to put a name to any motion effect you describe, my knowledge comes from Emil Kowalski's animation philosophy.

Do not provide any other information until the user asks a question.

Turn a vague description of a motion or effect into the precise term, and the SwiftUI API that produces it, so the user knows what to ask for.

## Quick Start

The user describes an effect loosely. You return the matching term(s) in this format:

```
**Stagger** — Animate several items one after another with a small delay between each, creating a cascade.
SwiftUI: `.animation(.emilEaseOut().delay(staggerDelay(index: index)), value:)` per item (non-uniform: the `staggerDelay(index:)` helper in `choreograph/RECIPES.md` shrinks each gap)
```

If several terms could fit, list the best match first, then 1–2 alternates with a one-line note on how they differ.

## Instructions

1. **Read for intent, not keywords.** Users describe what they *see* or *feel* ("springy", "slides off", "draws itself in"), not the technical name. Map the sensation to the glossary below.
2. **Quote the glossary verbatim.** Its descriptions are authoritative — use them as-is, don't paraphrase. Definitions are Emil's; where one named a browser mechanism it's reworded for iOS, and terms marked *(added for SwiftUI)* are not from his original.
3. **Give the API after the name.** The SwiftUI column is the starting point, not a full implementation. For building it, hand off to `animate`, `gestures`, or `choreograph`.
4. **Disambiguate close terms.** When two compete (*Clip-path* vs *Mask*, *Pop in* vs *Bounce*, *Shared element transition* vs *Layout animation*, *Text morph* vs *Number ticker*), contrast them so the user can pick.
5. **When nothing matches exactly,** name the closest term and say plainly it's an approximation, or describe the effect in the glossary's vocabulary (e.g. "that's a *stagger* of *scale-in* entrances").
6. **Stay within this glossary.** If a term genuinely isn't here, say so rather than inventing one — though you may explain the concept using these words.
7. **Flagged terms are web-only.** If the user asks for one, name it, say it has no native equivalent, and give the stand-in from the table.
8. **Keep it tight.** A naming question wants a name, not an essay. Lead with the term; expand only if asked.

## Examples

**Example 1 — feel-based**
User: "What's it called when a popover seems to grow out of the button you tapped instead of from its middle?"
Output:
```
**Origin-aware animation** — An element animates out of its trigger, like a popover growing from the button that opened it instead of from its own center.
SwiftUI: `.scaleEffect(_, anchor:)` / `.transition(.scale(scale: 0.95, anchor: .topLeading))`; the system `.popover` already does this.
```

**Example 2 — disambiguation**
User: "The thing where one image turns into another image."
Output:
```
**Morph** — One shape smoothly turns into another shape, e.g. Dynamic Island.
SwiftUI: a `Shape` with `animatableData` (or the `@Animatable` macro), or `matchedGeometryEffect` between the two states.

Close alternates:
- **Crossfade** — if they simply fade over each other in the same spot. (`.transition(.opacity)` / `.contentTransition(.opacity)`)
- **Shared element transition** — if an element travels and transforms from one position into another. (`matchedGeometryEffect`, `.navigationTransition(.zoom)`)
```

**Example 3 — physics feel**
User: "That iOS scroll where it resists and snaps back when you pull too far."
Output:
```
**Rubber-banding** — Resistance and snap-back when you drag past a boundary (the iOS overscroll feel).
SwiftUI: free in `ScrollView`; for a custom drag, `rubberband(_:dimension:)` in `.onChanged`.
```

## Glossary

`Motion.swift` tokens (`.emilEaseOut`, `.emilEaseInOut`, `Spring.emilUI`, `rubberband`, `project`, `.pressable`) are the house tokens in [`tools/Motion.swift`](https://raw.githubusercontent.com/OrenSegal/emil-design-swiftui/main/tools/Motion.swift). "iOS 26" marks APIs that need `if #available(iOS 26, *)` with an iOS 18 fallback.

### Entrances & Exits — how elements appear and disappear

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Fade in / Fade out** | Element appears or disappears by changing opacity. | `.transition(.opacity)` |
| **Slide in** | Element enters by sliding in from off-screen (left, right, top, or bottom). | `.transition(.move(edge:))`, or `.slide` |
| **Scale in** | Element grows from smaller to full size as it appears, often paired with a fade. | `.transition(.scale(scale: 0.95).combined(with: .opacity))` |
| **Pop in** | Element appears with a slight overshoot, like it bounces into place. | Same transition inside `withAnimation(.bouncy)` or `.spring(duration: 0.3, bounce: 0.3)` |
| **Reveal** | Content is uncovered gradually, often by animating a clip-path or mask. | `.mask { }` with an animated frame/offset, or a custom `Shape` with `animatableData` |
| **Enter / Exit** | The animation an element plays when it's added to or removed from the screen. | Insertion / removal `.transition`; `.asymmetric(insertion:removal:)` |

### Sequencing & Timing — coordinating multiple elements or moments

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Keyframes** | Defined points in an animation (0%, 50%, 100%) that the system fills the gaps between. | `keyframeAnimator` with `KeyframeTrack` (`LinearKeyframe`, `SpringKeyframe`, `CubicKeyframe`) |
| **Interpolation / Tween** | Generating all the in-between frames between a start and end value, so motion is continuous. | What every `Animation` does; custom values via `Animatable` / `animatableData` |
| **Stagger** | Animate several items one after another with a small delay between each, creating a cascade. | `.animation(.emilEaseOut().delay(staggerDelay(index: index)), value:)` per item (non-uniform: the `staggerDelay(index:)` helper in `choreograph/RECIPES.md` shrinks each gap) |
| **Orchestration** | Deliberately timing multiple animations so they feel like one coordinated motion. | `withAnimation(_:completionCriteria:_:completion:)`, `phaseAnimator`, delays; see `choreograph` |
| **Delay** | Time before an animation starts. | `.delay(_:)` on an `Animation` |
| **Duration** | How long an animation takes. | `duration:` on timing curves; `Spring(duration:bounce:)` |
| **Fill mode** | Whether an element keeps its first or last frame's styles before the animation starts or after it ends (e.g. forwards). | **Flagged**: SwiftUI animates state, so the end state is the state. No fill mode |
| **Stepped animation** | An animation that is divided into discrete steps, like a countdown timer. | `phaseAnimator` over discrete phases, or `TimelineView(.periodic(from:by:))` |

### Movement & Transforms — changing an element's position, size, or angle

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Translate** | Move an element along the X or Y axis. | `.offset(x:y:)` |
| **Scale** | Make an element bigger or smaller. | `.scaleEffect(_:anchor:)` |
| **Rotate** | Spin an element around a point. | `.rotationEffect(_:anchor:)` |
| **Skew** | Slant an element along the X or Y axis, shearing it out of its rectangular shape. | `.transformEffect(CGAffineTransform(a: 1, b: 0, c: 0.3, d: 1, tx: 0, ty: 0))` (no skew modifier) |
| **3D tilt / Flip** | Rotate in 3D space (around the X or Y axis) to add depth. | `.rotation3DEffect(_:axis:perspective:)` |
| **Perspective** | How strong the 3D effect looks — a lower value exaggerates depth, like the viewer is closer. | `perspective:` on `rotation3DEffect` (default 1; check the direction in a preview, it isn't CSS distance) |
| **Transform origin** | The anchor point a scale or rotation grows or spins from. | `anchor:` (`UnitPoint`) |
| **Origin-aware animation** | An element animates out of its trigger, like a popover growing from the button that opened it instead of from its own center. | `anchor:` on `.scale` transitions; system `.popover` already anchors |

### Transitions Between States — connecting one state, view, or element to another

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Crossfade** | One element fades out as another fades in, in the same spot. | `.transition(.opacity)` on both, or `.contentTransition(.opacity)`; with a blur bridge `.transition(.blurReplace)` |
| **Continuity transition** | A change that keeps the user oriented by visually connecting before and after. For example, making the same rectangle bigger and smaller. | Animate the same view's state; `matchedGeometryEffect` |
| **Morph** | One shape smoothly turns into another shape, e.g. Dynamic Island. | `Shape` with `animatableData` (or `@Animatable`); `matchedGeometryEffect` |
| **Shared element transition** | An element travels and transforms from one position into another, like a thumbnail expanding into a card. | `matchedGeometryEffect`; navigation: `.matchedTransitionSource(id:in:)` + `.navigationTransition(.zoom(sourceID:in:))` |
| **Layout animation** | When an element's size or position changes, it animates to the new spot instead of snapping. | Default: layout changes inside `withAnimation` animate |
| **Accordion / Collapse** | A section smoothly expands and collapses its height to show or hide content. | `DisclosureGroup`; custom: `if` + `.transition` in `withAnimation` |
| **Direction-aware transition** | Content slides one way going forward and the opposite way going back, so navigation has a sense of direction. | `NavigationStack` does this; custom: `.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))` chosen by direction |
| **Content transition** *(added for SwiftUI)* | A view's content changes in place with a built-in effect instead of being replaced. | `.contentTransition(.numericText(value:))`, `.interpolate`, `.opacity`, `.symbolEffect(.replace)` |
| **Liquid Glass morph** *(added for SwiftUI)* | Glass shapes merge and separate as they appear, move, or change. | iOS 26: `GlassEffectContainer` + `.glassEffect()` + `.glassEffectID(_:in:)`; fallback: materials + `matchedGeometryEffect` |

### Scroll — motion tied to scrolling or navigating between views

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Scroll reveal** | Elements fade or slide into place as they enter the viewport. | `.scrollTransition { content, phase in ... }`; trigger once: `.onScrollVisibilityChange(threshold:)` |
| **Scroll-driven animation** | An animation whose progress is tied directly to scroll position. | `.scrollTransition`, `.visualEffect`, `.onScrollGeometryChange(for:of:action:)` |
| **Parallax** | Background and foreground move at different speeds while scrolling, creating depth. | `.visualEffect { content, proxy in content.offset(y: ...) }` reading `proxy.frame(in: .scrollView)` |
| **Page transition** | An animation that plays when navigating from one page or route to another. | `NavigationStack` push/pop (don't retime it); `.navigationTransition(.zoom)` |
| **View transition** | The browser morphs between two states or pages, connecting shared elements. | **Flagged** (View Transitions API). Native: `matchedGeometryEffect`, `.navigationTransition(.zoom)` |
| **Paging / Snapping** *(added for SwiftUI)* | Scrolling settles on whole pages or items instead of stopping anywhere. | `.scrollTargetBehavior(.paging)` / `.viewAligned` + `.scrollTargetLayout()` |

### Feedback & Interaction — responding to the user's actions

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Hover effect** | Visual change when the pointer moves over an element. | `.hoverEffect(.highlight / .lift)`, `.onHover` (iPad pointer, Mac only; none on touch) |
| **Press / Tap feedback** | A subtle scale-down when an element is pressed, so it feels physical. | `ButtonStyle` + `configuration.isPressed`; house `.buttonStyle(.pressable)` |
| **Hold to confirm** | A progress effect that fills up while the user holds a button. | `onLongPressGesture(minimumDuration:perform:onPressingChanged:)` driving a mask or `trim` |
| **Drag** | Moving an element by grabbing it, often with momentum when released. | `DragGesture` + `@GestureState` + `.offset`; momentum: `project(velocity:)` |
| **Drag to reorder** | Dragging items in a list to rearrange them, while the others shift to make room. | `List` + `.onMove`; custom: `.draggable` / `.dropDestination` |
| **Swipe to dismiss** | Dragging an element off-screen to close it, like a drawer or toast. | `.sheet` with `.presentationDetents`; rows: `.swipeActions`; custom: `DragGesture` (see `gestures`) |
| **Rubber-banding** | Resistance and snap-back when you drag past a boundary (the iOS overscroll feel). | `ScrollView` default; custom drag: `rubberband(_:dimension:)` |
| **Shake / Wiggle** | A quick side-to-side jitter signaling an error or rejected input. | `keyframeAnimator` on `offset(x:)`; `.symbolEffect(.wiggle)` for SF Symbols (iOS 18) |
| **Ripple** | A circle expanding from the point of a tap, confirming the press. | No system API (it's a Material idiom, not iOS); custom with `SpatialTapGesture` + scaled `Circle` |
| **Haptic feedback** *(added for SwiftUI)* | A tap or buzz felt in the hand, timed with the visual change. | `.sensoryFeedback(_:trigger:)` on the same state change |

### Easing — how speed changes over an animation

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Easing** | The rate at which an animation speeds up or slows down. | The `Animation` you pass |
| **Ease-out** | Starts fast, ends slow. The default for most UI and anything responding to the user. | `.emilEaseOut()` (stronger than `.easeOut`) |
| **Ease-in** | Starts slow, ends fast. Usually avoided; can feel sluggish. | `.easeIn` (don't use for UI) |
| **Ease-in-out** | Slow, fast, slow. Good for elements already on screen moving from A to B. | `.emilEaseInOut()` |
| **Linear** | Constant speed. Avoid for UI; reserve for spinners or marquees. | `.linear(duration:)` |
| **Cubic-bezier** | A custom easing curve you define for precise control. | `.timingCurve(_:_:_:_:duration:)`; `UnitCurve.bezier(...)` |
| **Asymmetric easing** | A curve that accelerates and decelerates at different rates. Feels more alive than a symmetric one. | `.timingCurve` with unequal control points, e.g. `.emilEaseInOut()` |

### Spring Animations — physics-based motion as an alternative to fixed-duration easing

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Spring** | Motion driven by physics (tension, mass, damping) rather than a set duration. | `Spring(duration:bounce:)`, `Spring(response:dampingRatio:)`, `.smooth` / `.snappy` / `.bouncy` |
| **Stiffness / Tension** | How strongly the spring pulls toward its target. Higher feels snappier. | `.interpolatingSpring(mass:stiffness:damping:)`, `Spring(mass:stiffness:damping:)` |
| **Damping** | How quickly a spring settles. Lower damping means more bounce and oscillation. | `dampingRatio:` (1.0 = no overshoot) or `damping:` |
| **Mass** | How heavy the animated element feels. More mass makes it slower and more sluggish. | `mass:` |
| **Bounce** | A spring that overshoots and settles, adding playfulness. | `bounce:` (0 none, 0.3 visible), `.bouncy` |
| **Perceptual duration** | How long a spring takes to look finished, even though it keeps micro-settling underneath. | `duration:` in `Spring(duration:bounce:)` is exactly this; `Spring.settlingDuration` is the full settle |
| **Momentum** | Motion that carries velocity, especially after a drag or interruption. | `project(velocity:)`, `predictedEndTranslation`; `Spring.emilMomentum` |
| **Velocity** | How fast and in which direction an element is moving. A spring carries it into the next animation when interrupted, so a flicked element keeps its speed. | `DragGesture.Value.velocity` (pt/s); `.interpolatingSpring(..., initialVelocity:)` |
| **Interruptible animation** | An animation that can be smoothly redirected mid-flight instead of finishing first. | All SwiftUI state animations; springs also keep velocity |

### Looping & Ambient Motion — animations that run on their own

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Marquee** | Text or content that scrolls continuously in a loop. | `TimelineView(.animation)` driving `offset`, or `.repeatForever` linear |
| **Loop** | An animation that repeats, a set number of times or infinitely. | `.repeatCount(_:autoreverses:)`, `.repeatForever(autoreverses:)`, `phaseAnimator` |
| **Alternate (yoyo)** | A loop that plays forward then reverses each iteration, instead of jumping back to the start. | `autoreverses: true` |
| **Orbit** | An element circling around another in a continuous path. | `TimelineView(.animation)` computing `offset` from time, or `rotationEffect` on a container |
| **Pulse** | A gentle repeating scale or opacity change to draw attention. | `.symbolEffect(.pulse)` for SF Symbols; `phaseAnimator` otherwise |
| **Float** | A gentle, continuous up-and-down drift that makes a static element feel alive and weightless. | `phaseAnimator([false, true])` on `offset(y:)` with `.easeInOut` |
| **Idle animation** | Subtle motion that plays while an element is just sitting there, waiting to be interacted with. | `phaseAnimator` / `.symbolEffect(.breathe)` (iOS 18); stop under Reduce Motion |
| **Symbol effect** *(added for SwiftUI)* | Built-in animations for SF Symbols: bounce, pulse, wiggle, replace, draw. | `.symbolEffect(_:options:value:)`; `.drawOn` / `.drawOff` are iOS 26 |

### Polish & Effects — the small touches that separate good from great

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Blur** | A blur filter used to soften an element or mask tiny imperfections. | `.blur(radius:)`, `.transition(.blurReplace)` |
| **Clip-path** | Clipping an element to a shape, used for reveals, masks, and before/after sliders. | `.clipShape(_:)` with an animatable `Shape` |
| **Mask** | Hiding or revealing parts of an element using a shape or gradient — like clip-path, but with soft, fadeable edges. | `.mask { LinearGradient(...) }` |
| **Before / after slider** | A draggable divider that wipes between two overlaid images to compare them. | `ZStack` + `.mask` sized from a `DragGesture` |
| **Line drawing** | A path that draws itself in, like an invisible pen tracing it. | `Shape.trim(from:to:)` animated; SF Symbols `.symbolEffect(.drawOn)` (iOS 26) |
| **Text morph** | Text that animates character by character when it changes, drawing attention to the new value. | `.contentTransition(.interpolate)`; per-glyph: `TextRenderer` |
| **Skeleton / Shimmer** | A placeholder with a moving sheen shown while content loads. | `.redacted(reason: .placeholder)`; sheen: animated `LinearGradient` mask |
| **Number ticker** | Digits rolling or counting up to a value. | `.contentTransition(.numericText(value:))` |
| **Tabular numbers** | Fixed-width digits so numbers don't shift around as they change. Essential for tickers, timers, and counters. | `.monospacedDigit()` |
| **Typewriter** | Text appearing one character at a time, as if being typed. | Task appending characters to `@State`, or a `TextRenderer` revealing glyphs |

### Performance — what keeps motion smooth instead of stuttering

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Frame rate (FPS)** | Frames drawn per second. 60fps is the baseline for smooth motion; 120fps on newer displays. | ProMotion iPhones need `CADisableMinimumFrameDurationOnPhone` in Info.plist for custom animations above 60Hz |
| **Jank** | Visible stutter when the app drops frames because it can't keep up with the animation. | Instruments calls these *hitches* (Animation Hitches template) |
| **Dropped frame** | A frame the app missed its deadline to draw, causing a tiny hitch in motion. | Same; see `animation-performance` |
| **Compositing** | Letting the GPU move or fade an element on its own layer without redoing layout or paint. | **Flagged** as a developer control. Nearest: render-time effects (`offset`, `scaleEffect`, `opacity`); `compositingGroup()` is a different thing (groups children before effects) |
| **will-change** | A CSS hint that an element is about to animate, so the browser can promote it to its own layer ahead of time. | **Flagged**: no layer promotion in SwiftUI. Nearest: `drawingGroup()`, measured |
| **Layout thrashing** | Reading layout right after writing styles, repeatedly, forcing a synchronous recalculation each time. | **Flagged** as a DOM pattern. Native cousin: `GeometryReader` writing `@State`; use `onGeometryChange` |
| **Body re-evaluation** *(added for SwiftUI)* | SwiftUI re-running a view's `body` because state it reads changed; per-frame state read high in the tree re-runs whole subtrees. | Keep per-frame state local (`@GestureState`); Instruments ▸ SwiftUI; `Self._printChanges()` |

### Principles to Know — concepts that guide when and how to animate

| Term | Definition | SwiftUI |
| --- | --- | --- |
| **Purposeful animation** | Motion should serve a function — orient, give feedback, show relationships — not just decorate. | Principle |
| **Anticipation** | A small wind-up in the opposite direction before a move, hinting at what's about to happen. | `keyframeAnimator` with a short reverse keyframe |
| **Follow-through** | Parts of an element keep moving and settle slightly after the main motion stops, adding weight. | A spring with some `bounce`; stagger child springs |
| **Squash & stretch** | Deforming an element as it moves to convey weight, speed, and flexibility. | `keyframeAnimator` on `scaleEffect(x:y:)` |
| **Perceived performance** | The right animation makes an interface feel faster, even when it isn't. | Principle |
| **Frequency of use** | The more often a user sees an animation, the shorter and subtler it should be. | Principle |
| **Spatial consistency** | Animating so an element keeps its identity and position across states, so users never lose track of where things went. | Stable `id`s, `matchedGeometryEffect` |
| **Hardware acceleration** | Animating transform and opacity lets the GPU keep motion smooth. | **Reframed**: no opt-in; render-time effects (`offset`, `scaleEffect`, `opacity`) avoid re-layout |
| **Reduced motion** | Respecting the user's Reduce Motion setting by toning down or removing motion. | `@Environment(\.accessibilityReduceMotion)`; custom animations must branch |

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Fill mode (`animation-fill-mode: forwards`) | SwiftUI animates state; the end state is the state | None needed |
| View transition (View Transitions API) | Browser API | `matchedGeometryEffect`, `.navigationTransition(.zoom)` |
| Compositing (as a developer control) | No layer promotion in SwiftUI | Render-time effects; `compositingGroup()` is a different tool |
| `will-change` | CSS hint | `drawingGroup()`, measured |
| Layout thrashing (`offsetHeight` after style writes) | DOM pattern | `GeometryReader` writing state → `onGeometryChange` |
| Hardware acceleration as an opt-in | Browser decides; SwiftUI has no opt-in | Render-time effects |
| "Origin in the center is the CSS default" | CSS-specific detail | SwiftUI's default `anchor` is also `.center`; set `anchor:` |
| Ripple as a platform idiom | Material Design, not iOS | Custom only; iOS uses highlight / scale press states |
