# Conversion Contract: Web → SwiftUI

This is how the skills in this repo were ported from Emil Kowalski's web skills (`emilkowalski/skills`, MIT) to SwiftUI. Every skill follows it, so the port stays consistent. Read it before you edit a skill.

## Target

- **iOS 18.0 minimum, Swift 6 language mode, Xcode 27 SDK.** Snippets are typechecked against that target.
- APIs newer than iOS 18 (Liquid Glass `glassEffect`, `scrollEdgeEffectStyle`, `GlassEffectContainer`) only appear behind `if #available(iOS 26, *)`, with an iOS 18 fallback.
- iPhone first. iPadOS pointer and macOS behaviour are noted where they differ. visionOS and watchOS are out of scope.

## The three rules

1. **Keep the judgment, replace the mechanism.** Emil's rules about *why* and *when* (frequency, purpose, easing choice, duration, origin, interruptibility, asymmetry, restraint, cohesion) transfer unchanged. Only the code that implements them changes: CSS, Motion, or DOM code becomes SwiftUI.
2. **Flag what doesn't transfer.** If a rule exists only because of the browser (compositor layers, `will-change`, the 300 ms tap delay, `100vh`, hover media queries, Motion version caveats), it isn't translated. It goes in the skill's `## No native equivalent` section, with one line on why and, if there is one, what plays that role natively.
3. **Don't fight the system.** Emil's durations and curves are for *custom* components. Don't retime or re-curve system motion: `NavigationStack` push and pop, `.sheet`, `.popover`, `Menu`, `.confirmationDialog`, keyboard, `TabView`. Users have that motion in muscle memory, and it already follows Reduce Motion. The native version of "use base-ui instead of hand-rolling a dropdown" is "use the system component instead of hand-rolling one."

## Mapping table

**Convert** means there's a native equivalent. **Reframe** means the rule holds but the reason or mechanism changes. **Flag** means there's no sensible native equivalent.

| Web rule / API | Disposition | SwiftUI |
| --- | --- | --- |
| `cubic-bezier(0.23,1,0.32,1)` etc. | Convert | `Animation.timingCurve(0.23, 1, 0.32, 1, duration:)`, exposed as `.emilEaseOut()` / `.emilEaseInOut()` / `.emilDrawer()` in `tools/Motion.swift` |
| `ease-out` / `ease-in-out` / `ease` / `linear` decision tree | Convert | Same tree. `.easeOut` / `.easeInOut` are the weak built-ins; use the Emil curves. `.linear` for constant motion. |
| "Never `ease-in`" | Convert | Never `.easeIn` for UI. |
| Springs `{duration, bounce}` | Convert | `Spring(duration:bounce:)` / `.spring(duration:bounce:)`; Apple form `Spring(response:dampingRatio:)`; presets `.smooth` (no bounce), `.snappy`, `.bouncy` |
| Motion `useSpring` following the mouse | Convert | Store the target in state and apply `.animation(.spring(...), value: target)`, or `withAnimation(.interactiveSpring)` per update. iPad pointer: `.onContinuousHover`. |
| CSS transitions retarget, keyframes restart | **Reframe** | Nothing in SwiftUI jumps on interruption, but the behaviours differ (SDK docs). **Springs merge**: the new target takes over the old velocity. **Timing curves stack**: the old curve keeps playing and the new one adds on top, so motion stays continuous but the old curve still finishes its run, which feels sluggish or overshoots on a reversal. **`keyframeAnimator`** rebuilds its track from the current value and keeps velocity when re-triggered, but it plays an authored track and can't follow a changing target. Rule: springs for anything the user can reverse or drive (gestures, toggles fired rapidly); keyframe/phase animators for authored one-shot sequences. |
| `transition: all` | **Reframe** | The SwiftUI version is a broad `withAnimation` or a `.animation(_:value:)` high in the tree. Both animate every change in that transaction. Scope with `.animation(_:value:)` on the view that changes, or `.animation(_:body:)` (iOS 17+) to limit it to specific modifiers. |
| `transform: scale()` | Convert | `.scaleEffect(_:anchor:)` |
| `transform-origin` | Convert | `anchor:` on `.scaleEffect`, `.rotationEffect`, and `.scale(scale:anchor:)` transitions. System `.popover` already anchors to its source. |
| `:active` press state | Convert | `ButtonStyle` + `configuration.isPressed`, which flips on touch-down. See `PressableButtonStyle` in `tools/Motion.swift`. **Put padding, frame and background inside the `label:`.** A style only transforms its label, so modifiers chained on the `Button` neither scale nor take the tap. |
| Never animate from `scale(0)` | Convert | `.transition(.scale(scale: 0.95).combined(with: .opacity))` |
| `@starting-style` / `useEffect(mounted)` | Convert | `.transition(...)` on a view inserted inside `if`, with the state change made in `withAnimation`. Don't use the `onAppear { mounted = true }` hack. |
| Exit animations (AnimatePresence) | Convert | Removal transitions; `.transition(.asymmetric(insertion:removal:))` |
| `translateY(100%)` (own size) | Convert | `.transition(.move(edge:))` moves by the view's own size. For a custom amount, use `.visualEffect { content, proxy in content.offset(y: proxy.size.height) }`. |
| `filter: blur()` crossfade bridge | Convert | `.transition(.blurReplace)` (iOS 17+) or `.blur(radius:)`. Keep the radius small: blur renders offscreen. `.blurReplace` also **scales** (SDK doc), so it falls back to `.opacity` under Reduce Motion. |
| Layout/shared-element (`layout`, `layoutId`) | Convert | `matchedGeometryEffect`; for navigation, `.matchedTransitionSource` + `.navigationTransition(.zoom(...))` (iOS 18) |
| `clip-path: inset()` reveals | Convert | `.mask { }` with an animated frame or offset, or a custom `Shape` with `animatableData`. Hold-to-confirm: `onLongPressGesture(minimumDuration:perform:onPressingChanged:)`. |
| `rotateX/Y`, `preserve-3d` | Convert | `.rotation3DEffect(_:axis:perspective:)` (no real z-sorting between siblings) |
| IntersectionObserver / `useInView` | Convert | `.onScrollVisibilityChange(threshold:)` (iOS 18), `.scrollTransition` |
| `font-variant-numeric: tabular-nums` | Convert | `.monospacedDigit()`; animated numbers: `.contentTransition(.numericText(value:))` |
| `letter-spacing` | Convert | `.tracking(_:)` in points. SF already applies size-specific tracking, so only tighten custom display sizes. |
| `max-width: 65ch` | Convert | `.frame(maxWidth: ...)`, sized from the font (scale it with `@ScaledMetric`) |
| `Intl.PluralRules` | Convert | Automatic grammar agreement `"^[\(n) member](inflect: true)"`, or String Catalog plural variants |
| Relative→absolute dates | Convert | `Date.formatted(.relative(presentation:))` under a week, `.dateTime` after |
| `flex-shrink: 0` on avatar | Convert | Fixed `.frame(width:height:)` + `.layoutPriority`, `.fixedSize()` |
| `backdrop-filter` | Convert | `.background(.ultraThinMaterial …)` (Materials); iOS 26: `.glassEffect()` |
| `prefers-reduced-motion` / `useReducedMotion` | Convert | `@Environment(\.accessibilityReduceMotion)`. **Custom animations do not opt out on their own**, so you must branch. |
| `prefers-reduced-transparency` | Convert | `@Environment(\.accessibilityReduceTransparency)` (system materials already adapt) |
| `prefers-contrast: more` | Convert | `@Environment(\.colorSchemeContrast) == .increased` |
| Vibration API / audio-haptic harmony | Convert | `.sensoryFeedback(_:trigger:)` on the same state change that drives the animation, so both fire on the same frame |
| Velocity in px/ms (`> 0.11`) | **Reframe** | Sonner's 0.11 px/ms is an *average* over the whole drag (distance / elapsed time). `DragGesture.Value.velocity` (iOS 17+) is the *release* velocity in pt/s, and the two aren't interchangeable. Test the release velocity against **500 pt/s**, or compute the average yourself and compare it with 110 pt/s. Never compare `value.velocity` with 110. |
| Momentum projection | Convert | `project(velocity:)` in `tools/Motion.swift`; or `DragGesture.Value.predictedEndTranslation` |
| Velocity handoff to spring | Convert | `.interpolatingSpring(..., initialVelocity:)`. Its velocity is **relative**: `gestureVelocity / (target − current)`. |
| Rubber-banding | Convert | `rubberband(_:dimension:)` in `tools/Motion.swift`, applied in `.onChanged` |
| 1:1 drag tracking | Convert | `@GestureState` translation applied with `.offset`, local to the dragged view |
| Stagger with `nth-child` delays | Convert | `.animation(.emilEaseOut().delay(...), value:)` per item, or `phaseAnimator` |
| Slow-motion debugging | Convert | Simulator ▸ Debug ▸ Slow Animations; Instruments ▸ SwiftUI / Animation Hitches; Xcode previews |
| Real-device testing | Convert | Still required: the Simulator has no haptics, no real touch latency, no ProMotion. |
| `setPointerCapture` | **Flag** | Not needed: a SwiftUI gesture keeps tracking after the finger leaves the view's bounds. |
| Multi-touch guard (`if (isDragging) return`) | **Reframe** | `DragGesture` follows one touch. Only custom `UIGestureRecognizer` code needs a guard. |
| `@media (hover: hover)` gate | **Reframe** | Touches don't fire `.onHover`, so there's no false positive to gate. Hover is pointer-only (iPad trackpad, Mac), so never make it the only affordance; prefer `.hoverEffect`. |
| Tooltip delay / instant subsequent tooltips | **Flag** | `.help()` timing belongs to the system (pointer only) and there are no tooltips on touch. The principle stays for custom hover UI on iPad/Mac. |
| "Only animate transform & opacity" | **Reframe** | `offset` / `scaleEffect` / `rotationEffect` / `opacity` are render-time effects. Animating `frame` / `padding` / font size re-runs layout every frame. Same advice, different pipeline. |
| CSS variable inheritance cost | **Reframe** | The SwiftUI version is fast-changing state stored high in the tree or in the environment, which re-evaluates whole subtrees. Keep per-frame state in the view that moves (`@GestureState`, `@State`). |
| `will-change`, GPU layers, compositor | **Flag** | There's no developer-facing layer promotion in SwiftUI. `drawingGroup()` (Metal flattening) and `compositingGroup()` are the nearest tools, each with costs; measure first. |
| CSS-on-compositor beats JS rAF under load | **Reframe** | SwiftUI evaluates its animations in-process, per frame, so a busy main thread hitches them. Core Animation (`UIView.animate`, `CALayer`) commits to the render server. Rule: keep the main thread free during transitions; measure hitches in Instruments. |
| Motion ≥14.2 / WAAPI / `transformTemplate` | **Flag** | Library- and browser-specific, nothing to port. |
| 300 ms tap delay, `touch-action`, tap highlight, `100vh`, input zoom, `overscroll-behavior`, `viewport-fit` | **Flag** | Browser artifacts that native apps don't have. |
| Sonner / Vaul / base-ui / cmdk / Motion library guidance | **Flag** | React libraries. The principles behind them (good defaults, invisible edge cases, transitions over keyframes) are kept. API specifics are not. |
| Emil's curated library picks | **Flag** | Third-party Swift packages aren't recommended here: Emil hasn't endorsed any, and presenting one as his pick would be fabricated. The skill points to first-party frameworks instead. |

## Writing rules

- **The voice stays Emil's: direct, opinionated, with reasons.** Keep his examples (Raycast, Sonner, Vercel, Linear, Family) where the lesson transfers. Mark them as web-origin when the mechanism doesn't.
- **Units:** milliseconds become seconds in code (`0.2`), and the prose can say both ("200 ms (`0.2`)"). px become pt.
- **Required review format:** the Before / After / Why markdown table stays, with SwiftUI code in the cells.
- **Every ```` ```swift ```` block must typecheck on its own** together with `tools/Motion.swift`. Write complete top-level declarations (`struct … : View`, `extension`, `func`), not bare modifier chains. A block can opt out only for a single illustrative modifier line, by making its first line `// fragment`. Run `tools/check-snippets.sh skills/**/*.md`.
- **Accessibility belongs inside the examples.** Every motion example that moves something handles `accessibilityReduceMotion`. Every custom control keeps its label and traits. Text uses Dynamic Type styles, not fixed sizes.
- **Every skill ends with `## No native equivalent`**, in this format:

  ```
  ## No native equivalent

  | Web rule | Why it doesn't port | Native stand-in |
  | --- | --- | --- |
  | `will-change: transform` | No developer-facing layer promotion | Measure first; `drawingGroup()` only for many-layer static art |
  ```

  If nothing was dropped, write "None: every rule in the web original transfers."
- **Front matter:** keep `name` (so the cross-references still work) and rewrite `description` to trigger on SwiftUI / iOS. Keep `disable-model-invocation` wherever the original had it.

## Skill dispositions

| Skill | Disposition |
| --- | --- |
| emil-design-eng, animate, choreograph, gestures, review-animations, improve-animations, find-animation-opportunities, remove-animations, break-ui, prototype, animation-vocabulary, learn-taste, ask-emil | Converted |
| apple-design | Converted back: the web original was Apple guidance translated *to* the web, so it's re-grounded in native APIs |
| animation-performance | Rewritten for the SwiftUI render pipeline; browser-pipeline rules flagged |
| mobile-native | Mostly flagged (web-in-a-phone fixes); the few rules with a native meaning are kept |
| pick-ui-library | Converted to "use the first-party component" for each task; tasks with no first-party answer are flagged, and no third-party picks are made |
| write-swift | Kept as-is: it was already native |
| animate-expo | **Not ported**: it's React Native. Its native-relevant ideas (haptics, gesture handoff, keeping work off the busy thread) live in `animate` and `gestures`. |
| ask-sonner | **Not ported**: Sonner is a React library. Its principles live in `emil-design-eng`. |

See `FLAGGED.md` for the full index of everything that didn't port.
