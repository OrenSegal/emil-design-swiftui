# Flagged: what didn't port

Every web rule that has no sensible SwiftUI equivalent, collected from the closing table of each skill. Each row says why it doesn't port and what plays that role natively, if anything. Two skills weren't ported at all:

- **animate-expo**: React Native and Expo. Its native-relevant ideas (haptics, gesture handoff, keeping work off a busy thread) are in `gestures` and `animate`.
- **ask-sonner**: Sonner is a React toast library. Its principles are in `emil-design-eng`. SwiftUI has no system toast, so `pick-ui-library` flags it too.

## animate

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| CSS `@starting-style` for mount entrances | No CSS; nothing to emulate | `.transition(_:)` on a view inserted inside `if`, state changed in `withAnimation` |
| WAAPI (`element.animate()`) as the no-library programmatic tool | Browser API | `withAnimation(_:completionCriteria:_:completion:)`; Core Animation when it must run on the render server |
| Motion ≥ 14.2 hardware-accelerating `x`/`y`/`scale`, full `transform` string fallback | Library- and browser-specific | None needed: `offset`/`scaleEffect` are render-time effects in every SwiftUI version |
| `var(--transform-origin)` supplied by Base UI | React library variable | System `.popover` anchors itself; custom panels pass `anchor:` |
| `@media (hover: hover) and (pointer: fine)` gate | Touches don't fire `.onHover`, so there's no false hover to gate | Never make hover the only affordance; `.hoverEffect` |
| "Only `transform`/`opacity`: they skip layout and paint and run on the GPU" (the compositor reason) | No developer-facing compositor or layer promotion | Same advice, different reason: render-time effects skip layout; measure in Instruments |
| DevTools animation inspector | Browser tool | Simulator ▸ Debug ▸ Slow Animations; Instruments ▸ SwiftUI / Animation Hitches |

## animation-performance

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

## animation-vocabulary

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

## apple-design

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

## ask-emil

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `/mobile-native` as a main-flow step ("if it runs on a phone as a web app") | A native app isn't a web app on a phone | Real-device testing, kept in step 3 |
| `/animate-expo`, `/ask-sonner` routes | React Native and React libraries | `/animate`, `/gestures`, `/emil-design-eng` |

## break-ui

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `min-width: 0` on flex/grid children | SwiftUI stacks already compress children; there's no `min-width: auto` trap | `.layoutPriority` decides who yields; `.fixedSize()` protects what mustn't |
| `overflow-wrap: anywhere` for emails and URLs | `Text` already breaks an unbreakable string between characters when it must wrap | Choose `.lineLimit` + `.truncationMode(.middle)` instead |
| `word-break: break-all` | No such switch on `Text` | Not needed |
| `?data=worst` URL param that survives reload | Native apps have no URL bar | `@AppStorage` keeps the switcher's choice across relaunches; previews are fixed per fixture |
| Standalone HTML file with both datasets inline | No browser to open it in | One Swift file with the fixtures and the `#Preview` matrix, dropped into any iOS 18 target |
| Browser zoom 200% / root font size | Not a native control | Dynamic Type, up to the accessibility sizes (AX1–AX5) |
| `dir="rtl"` on a wrapper | Not HTML | `.environment(\.layoutDirection, .rightToLeft)`; the RTL pseudolanguage for full-app mirroring |
| `title` attribute / tooltip for truncated text | Touch has no hover tooltips; `.help()` is pointer-only | The detail view, a `.contextMenu` preview; VoiceOver reads the untruncated string |
| `Intl.Segmenter` for grapheme-safe initials | Swift `Character` is already a grapheme cluster | `PersonNameComponentsFormatter` (`.abbreviated`), with an icon fallback |
| `dangerouslySetInnerHTML` / HTML escaping | No HTML rendering in `Text` | The risk is Markdown: `Text(verbatim:)` for user data |
| Hover-only actions unreachable on touch | Native touch UI has no hover-revealed controls | The native trap is swipe-only or long-press-only actions; keep a visible path |
| 2560px-wide monitor | No such iOS screen | iPad landscape full screen; cap line length with `.frame(maxWidth:)` sized from the font |

## choreograph

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `AnimatePresence mode="popLayout"` / setting the exiting element to `position: absolute` | Stacks already pull a removed view out of layout while it transitions | `withAnimation` around the removal; `ZStack` for swaps |
| `animation-fill-mode: both` / `forwards` so delayed items don't flash and drawn paths hold | State-driven animations sit at the start value during a delay and hold the end value after | None needed |
| `MotionConfig` / one shared CSS custom property for the timing family | Library/CSS mechanism | One `Animation` constant on the component |
| Motion's `custom` prop on `AnimatePresence` and child | No `AnimatePresence`; the trap is the leaving view's last-rendered transition | See "Direction-aware steps" in RECIPES.md |
| `await Promise.all(...)` over animation promises | SwiftUI animations aren't promises | `withAnimation` `completion:`, `.task(id:)` |

## emil-design-eng

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

## find-animation-opportunities

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `:active` / `transition` CSS recipe for press feedback | CSS | `ButtonStyle` + `configuration.isPressed` (`.pressable`) |
| `clip-path: inset(0 100% 0 0)` hold-to-confirm overlay | CSS | A mask or overlay whose width/offset animates, driven by `onLongPressGesture(onPressingChanged:)` |
| `@starting-style` for entry without JS | CSS feature | `.transition(...)` on a view inserted inside `if`, state change in `withAnimation` |
| `transform-origin: var(--transform-origin)` (Base UI) | React library variable | `anchor:`; the system `.popover` already anchors |
| `@media (hover: hover) and (pointer: fine)` gating on hover suggestions | Touch doesn't fire SwiftUI hover | Hover is additive only; prefer `.hoverEffect` |
| Grep targets `{isOpen &&`, `display: none`, `details` markup, `.map(` | JSX/HTML syntax | The Swift sweep list in Where to Hunt |
| `Math.abs(distance)/elapsedMs > ~0.11` | px/ms units, and an average over the drag, not a release velocity | Release velocity `DragGesture.Value.velocity` > ~500 pt/s (or your own distance ÷ elapsed time > 110 pt/s) |

## gestures

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

## improve-animations

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Recon of CSS/Tailwind config, `--ease-*` / `--duration-*` custom properties, `@keyframes` definitions | No stylesheet layer | Shared `Animation` / `Spring` extensions, `ButtonStyle`s, `Transition` extensions |
| Detecting Framer Motion / React Spring / GSAP / WAAPI and Radix / Base UI / shadcn/ui | Web libraries | SwiftUI vs UIKit vs Core Animation, plus packages in `Package.resolved` / `Podfile` |
| Grep targets `transition: all`, `scale(0)`, `prefers-reduced-motion`, `transform-origin`, `@keyframes`, `motion.`, `animate={` | CSS/React syntax | The Swift sweep list in Phase 1 |
| DevTools playback rate and Rendering-panel reduced-motion toggle in feel checks | Browser tooling | Simulator ▸ Debug ▸ Slow Animations; Settings ▸ Accessibility ▸ Motion ▸ Reduce Motion on the Simulator or device |

## learn-taste

None: every rule in the web original transfers. (A lint check becomes a SwiftLint custom rule or a grep script; their regex-only limits are covered under "What a check looks like".)

## mobile-native

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Sticky `:hover` after tap, `(hover: hover) and (pointer: fine)` | Touches don't fire `.onHover`; there's no faked hover | `.hoverEffect` for pointer; never hover-only affordances |
| `-webkit-tap-highlight-color` | No browser tap highlight in a native app | Your own `ButtonStyle` press state |
| `100vh` / `dvh` / `svh` / `lvh` | No browser chrome changing the viewport | Safe area and `containerRelativeFrame` |
| Input font size 16px to stop zoom | Native apps don't zoom into fields | None needed; keep Dynamic Type |
| `user-scalable=no` / `maximum-scale=1` | No page zoom | Don't clamp Dynamic Type (Hard Rule 4) |
| 300 ms click delay, `touch-action: manipulation` | No double-tap-zoom wait on native controls | None needed; feedback on touch-down |
| `overscroll-behavior: none` / `contain` | No page to pull-to-refresh or chain to | `.scrollBounceBehavior`, `.refreshable` only where wanted |
| `touchmove` + `preventDefault()` | DOM event model | None; don't block scroll with a gesture |
| `viewport-fit=cover` + `env(safe-area-inset-*)` | Viewport meta tag | `.ignoresSafeArea()` on backgrounds, `.safeAreaInset` |
| `user-select: none`, `-webkit-touch-callout: none` | Controls aren't selectable natively | `.textSelection(.enabled)` on content only |
| `touch-action: pan-x` / `pan-y` / `none` | Browser gesture arbitration | Scroll views resolve axis; `simultaneousGesture` / `highPriorityGesture` for custom drags |
| `theme-color` per scheme, `color-scheme` meta | No browser chrome | `toolbarColorScheme`, `preferredColorScheme` |
| `-webkit-text-size-adjust` | No landscape font inflation | Dynamic Type |
| PWA manifest, `apple-mobile-web-app-status-bar-style`, standalone mode | Web install model | None; the app is installed |
| Tailwind `hover:` / `hoverOnlyWhenSupported`, Next.js `viewport` export | Web frameworks | None |
| LAN IP dev server, Safari Web Inspector, `chrome://inspect` | Web tooling | Run on device from Xcode; Instruments |

## pick-ui-library

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Sonner (toasts) | No first-party toast component. Build it with the house rules or pick a package yourself; not an Emil pick | A custom overlay with a transition and an accessibility announcement |
| cmdk (⌘K palette) | No first-party command palette on iOS. Build it with the house rules or pick a package yourself; not an Emil pick | `.searchable` with `.searchSuggestions`; on iPad, a hardware-keyboard shortcut that opens it |
| input-otp (segmented code boxes) | Partial: no first-party segmented OTP field. Build the boxes yourself or pick a package yourself; not an Emil pick | One `TextField` with `.textContentType(.oneTimeCode)` and `.keyboardType(.numberPad)` |
| Leva (tweak panel) | No first-party control panel. Build it with the house rules or pick a package yourself; not an Emil pick | A `#if DEBUG` `Form` of `Slider` / `Stepper` / `Toggle` in a sheet |
| Satori (dynamic OG images) | Open Graph images are a web-sharing concept. Build it with the house rules or pick a package yourself; not an Emil pick | `ImageRenderer` renders a SwiftUI view to an image, which you can share with `ShareLink` |
| shiki (syntax highlighting) | No first-party highlighter. Build it with the house rules or pick a package yourself; not an Emil pick | `AttributedString` with your own attribute runs |
| Cobe (3D globes) | No first-party globe component. Build it with the house rules or pick a package yourself; not an Emil pick | SceneKit or RealityKit for a custom 3D sphere |
| torph (animated text) | No first-party animated-text component. Build it with the house rules or pick a package yourself; not an Emil pick | `.contentTransition(.numericText())` / `.interpolate`; `TextRenderer` (iOS 18) for custom per-line or per-glyph effects |
| clsx (conditional `className`) | SwiftUI has no class strings | Conditions in modifier values |
| cva (variant-driven Tailwind styling) | No Tailwind, no class variants | A custom `ButtonStyle` / `ViewModifier` taking an enum for size and intent |
| next-themes (no flash on load) | The system switches light and dark and there's no server-rendered first paint to flash | Semantic and asset-catalog colors; `.preferredColorScheme` for an in-app override |
| Emil's specific library picks (base-ui, Vaul, motion, NumberFlow, Liveline, recharts, dnd kit, Virtuoso, zustand) | React libraries; he hasn't picked Swift equivalents | The first-party answers in the list above |

## prototype

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| The CSS pill spec (rgba values, 28px items, blur 12px, z-index) | Hand-built chrome would mean re-implementing a system control | The system segmented `Picker` in a forced-dark material capsule, specified in PICKER.md |
| Highlight `transform`/`width` transition at 250 ms and the `width` exception | The segmented control animates its own selection | System motion; not retimed |
| `data-ready` after first paint so load doesn't animate | The system control doesn't animate its initial selection | Not needed |
| `@media (hover: hover)` hover color on items | Touch has no hover; the system control handles pointer hover on iPad | Not needed |
| Number keys `1–N`, `←`/`→`, `R`, and the input-focus guard | Phones are touch-first, and keyboard behavior wasn't verified for this spec | Tap the segments; each variant has its own `#Preview`. Add `.keyboardShortcut` to buttons yourself if you need hardware-keyboard switching on iPad |
| `?v=2` URL param that survives reload | No URL bar | `@AppStorage` keyed by slug, kept across relaunches |
| `requestAnimationFrame` re-mount | No DOM | `.id(...)` re-mounts the variant |
| `/prototypes/<slug>` route | No routes | `#if DEBUG` `Prototypes/` group, `#Preview`s, a debug-only entry point |
| Standalone HTML file | No browser | One Swift file with previews plus `Motion.swift`, dropped into any iOS 18 target |
| "Console is clean" | No browser console | Xcode runtime issues and console output |

## remove-animations

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| "Route or page transitions inside the app" as a delete target | On iOS, navigation transitions are system motion users rely on | Delete only custom motion layered on or overriding them; never disable the system push/sheet |
| `animation-fill-mode: forwards`, Motion `initial={{ opacity: 0 }}`, reveal classes | CSS / React | Reframed as `onAppear` flags and invisible first phases (Removal Hazards) |
| `onAnimationEnd`, `transitionend`, `onExitComplete` | DOM / React events | `withAnimation` completions, `UIView.animate` completions, `asyncAfter` / `Task.sleep` |
| `AnimatePresence` holding a component in the DOM | React library | Removal transitions keep a view on screen until they finish |
| `motion.div` → `div`, empty `AnimatePresence` wrappers, variants objects, Tailwind animation config | React / CSS tooling | Orphaned flags, `@Namespace`s, transition extensions, animator phase types (Cleanup) |
| Grep targets `whileInView`, `whileHover`, AOS, `animate-` utilities, `IntersectionObserver` | Web libraries / syntax | `scrollTransition`, `onScrollVisibilityChange`, `.onHover` (Where to Hunt) |
| Lockfile churn when uninstalling a library | npm | `Package.resolved` / `Podfile.lock`; same rule: ask first |

## review-animations

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| Motion `x`/`y`/`scale` props before `motion` 14.2 as an escalation trigger; "upgrade or full `transform` string" remedy | Library-version caveat for a React library | Trigger on layout-driven motion (`matchedGeometryEffect`, animated `frame`) during busy work instead |
| WAAPI as a "move it to the GPU" remedy | Browser API | `UIView.animate` / Core Animation when render-server playback matters; otherwise state animation |
| `@starting-style` for entry | CSS feature | `.transition(...)` on a view inserted inside `if`, state change in `withAnimation` |
| Ungated `:hover` motion (`@media (hover: hover) and (pointer: fine)`) | Touch doesn't fire SwiftUI hover, so there's nothing to gate | Hover must never be the only affordance; prefer `.hoverEffect` |
| `transform-origin: var(--transform-origin)` (Base UI) in the example table | React library variable | `anchor:`; the system `.popover` already anchors |
| Updating a CSS variable on a parent to drive a child transform | CSS cascade | Reframed: per-frame state on a parent / in the environment re-evaluates subtrees |

