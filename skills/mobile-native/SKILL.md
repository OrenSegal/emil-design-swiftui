---
name: mobile-native
description: "The platform-layer details that make a SwiftUI iPhone app feel right in the hand, ported from a skill about making web apps feel native. Most of the original (100vh, tap highlight, input zoom, the 300 ms tap delay, touch-action, viewport-fit, overscroll-behavior, theme-color, PWA) doesn't exist in a native app and is flagged. What remains: safe areas, keyboard type and avoidance, scroll and overscroll behaviour, press feedback on touch-down, text selection on controls versus content, paging carousels with scrollTargetBehavior, status bar style, and testing on real hardware. Use when reviewing an iPhone screen's edges, keyboard, scroll, or touch feel, or when a web developer asks for the native version of a mobile-web fix. For motion itself use animate; for drags and sheets use gestures."
---

# Feeling Native On Mobile

> Adapted from Emil Kowalski's [`mobile-native`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/mobile-native) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to check the platform details that make your iPhone app feel right in the hand, my knowledge comes from Emil Kowalski's design engineering philosophy.

Do not provide any other information until the user asks a question.

Emil's original is a fix-it skill for web apps on phones: remove, one by one, the tells that give away "a website in a browser". A SwiftUI app doesn't have those tells; it is installed. So this port is short and mostly flagged (see `## No native equivalent`). What's left are the rules that still have a native meaning: edges, keyboard, scroll, touch feel, and the real-device rule.

It does not design motion (that's `animate`) or build drags and sheets (that's `gestures`).

## Operating Posture

You are a senior design engineer who has shipped sheets and gesture-driven UI to real iPhones. You know the Simulator is not a phone: it has no real touch latency, no haptics, no ProMotion, and a keyboard you type into with a Mac.

The user's phone is the source of truth. If you can't run it on hardware, say which fixes you can verify from code and which need a real device.

Two failure modes, and the first is worse:

1. **Fixing what the Simulator shows you.** Touch feel, keyboard behaviour, and edge gestures need a device.
2. **Hand-rolling what the system does.** Most items here are one modifier or a system default you shouldn't fight. A custom keyboard-height observer is the wrong tool; SwiftUI's keyboard avoidance is the right one.

## Hard Rules

1. **Every fix ships with the reason.** Apply each rule where its *why* applies. `.textSelection(.disabled)` is the default on controls; `.textSelection(.enabled)` on body text that users copy (addresses, error messages, order numbers) is correct.
2. **Capability over device guessing.** The native version of "media queries over UA sniffing": read the environment (`horizontalSizeClass`, `dynamicTypeSize`, `accessibilityReduceMotion`) and the safe area. Never branch on device model, idiom, orientation or screen height to guess layout. Choose the expanded layout with `horizontalSizeClass == .regular`: size classes are optional, so `!= .compact` treats a `nil` as roomy. When size classes pick different view hierarchies, keep selection and navigation state above the branch, because the swapped-out hierarchy loses its state. iPhone Duo makes this concrete: it reports a phone, its outer display is wide and short, its inner display is regular in both directions even in a portrait-only app, and folding resizes the scene without relaunching the app or changing `scenePhase`.
3. **Touch and pointer coexist.** iPad with a trackpad, iPhone apps running on Mac. Write for both: press feedback that works on touch, `.hoverEffect` as a pointer extra, never hover as the only affordance.
4. **Never cap Dynamic Type to protect a layout.** The native meaning of "never disable zoom": don't clamp `.dynamicTypeSize(...)` to stop text growing. Fix the layout instead (`ViewThatFits`, stacking, scrolling).
5. **Test on hardware before calling it done.** Run on a real iPhone from Xcode. The Simulator can't reproduce touch latency, haptics, ProMotion, or how the keyboard and edge gestures feel.

## The Symptom Table

| Problem | Solution |
| --- | --- |
| Content under the Dynamic Island / home indicator | Let backgrounds `.ignoresSafeArea()`; keep content in the safe area; pin bars with `.safeAreaInset(edge:)` |
| Keyboard covers the field or button | Rely on SwiftUI's keyboard avoidance; put bottom actions in `.safeAreaInset(edge: .bottom)` |
| Wrong keyboard, wrong return key | `.keyboardType`, `.textContentType`, `.submitLabel`, `.textInputAutocapitalization`, `.autocorrectionDisabled` |
| Keyboard won't go away when scrolling | `.scrollDismissesKeyboard(.interactively)` |
| Tap feels laggy | Feedback on touch-down: a `ButtonStyle` reading `isPressed` (`.pressable`) |
| Short content bounces oddly | `.scrollBounceBehavior(.basedOnSize)` |
| Long-press selects control text | Nothing: controls aren't selectable. Don't add `.textSelection(.enabled)` to them |
| Carousel doesn't snap page by page | `.scrollTargetBehavior(.paging)` or `.viewAligned` + `.scrollTargetLayout()` |
| Status bar unreadable over a custom header | Match the scheme with `.toolbarColorScheme(_:for:)` or the header's `preferredColorScheme` |
| Right in the Simulator, wrong on the phone | Test on real hardware |

## The Fixes

### 1. Safe areas

The web needs `viewport-fit=cover` plus `env(safe-area-inset-*)`. SwiftUI starts the other way round: content is already inside the safe area. The native rule is the same: paint edge to edge, pad *content* away from the Dynamic Island and home indicator.

```swift
struct EdgeToEdgeScreen: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(0..<30, id: \.self) { index in
                    Text("Row \(index)").font(.body)
                }
            }
            .padding(.horizontal)
        }
        // background goes under the system bars; content stays in the safe area
        .background(Color.indigo.opacity(0.1).ignoresSafeArea())
        // a custom bottom bar that also shrinks the scroll view's safe area
        .safeAreaInset(edge: .bottom) {
            Button("Continue") {}
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.bar)
        }
    }
}
```

Use `.ignoresSafeArea()` on backgrounds, never on text or controls. When readable or interactive content really must extend past the safe area, name the edges (`.ignoresSafeArea(edges: .top)`). Attach custom bars with `.safeAreaInset` (on iOS 26, `.safeAreaBar`, which also gives the bar the system scroll-edge effect), so the scroll view knows about the bar and nothing hides under it. Don't hard-code a bottom gap to clear the home indicator: SwiftUI already respects it and its height varies. Don't replace that gap with `.safeAreaPadding` either; `.safeAreaPadding` and `.contentMargins` add a deliberate margin on top of the safe area, so use them only when you want that extra space. On iOS 26, extend imagery behind a sidebar, inspector or vertical bar with `.backgroundExtensionEffect()` rather than `.ignoresSafeArea`, which hides part of the image under the bar.

### 2. Keyboard

There is no input zoom to fix natively. What carries over is the second half of Emil's section: give each field the right keyboard and return key.

```swift
struct CheckoutFields: View {
    @State private var email = ""
    @State private var code = ""
    @State private var amount = ""

    var body: some View {
        Form {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
            TextField("Verification code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
                .submitLabel(.done)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
```

| Web | SwiftUI |
| --- | --- |
| `inputmode="numeric"` | `.keyboardType(.numberPad)` |
| `inputmode="decimal"` | `.keyboardType(.decimalPad)` |
| `type="email"` / `type="tel"` | `.keyboardType(.emailAddress)` / `.phonePad`, plus `.textContentType` |
| `autocapitalize="none"` / `autocorrect="off"` | `.textInputAutocapitalization(.never)` / `.autocorrectionDisabled()` |
| `enterkeyhint="send"` / `"search"` / `"done"` | `.submitLabel(.send)` / `.search` / `.done` |
| `interactive-widget=resizes-content` | Default: SwiftUI shrinks the safe area for the keyboard. Don't `.ignoresSafeArea(.keyboard)` on screens with fields |

### 3. Tap feels laggy

The 300 ms delay doesn't exist natively (flagged). The other half of Emil's rule transfers exactly: **feedback on press, not release.** A `ButtonStyle`'s `configuration.isPressed` flips on touch-down. Keep press feedback at 100-160 ms (`0.1`-`0.16`) and ease-out; the house token is `.emilPress`.

```swift
struct SaveButton: View {
    var body: some View {
        Button {
            // save
        } label: {
            // styling lives in the label, so the whole capsule scales and takes the tap
            Text("Save")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.tint, in: Capsule())
                .foregroundStyle(.white)
        }
        // PressableButtonStyle scales on touch-down and handles Reduce Motion
        .buttonStyle(.pressable)
    }
}
```

Don't fake buttons with `.onTapGesture`: it fires on release, gives no press state, and loses the button trait for VoiceOver.

### 4. Scroll and overscroll

Native scroll views rubber-band, and that's correct: don't fight it. There's no page-level pull-to-refresh to disable, because there's no page; refresh only happens where you add `.refreshable`. What does carry over:

- Short content that bounces looks broken. `.scrollBounceBehavior(.basedOnSize)` bounces only when the content overflows.
- The web's `overscroll-behavior: contain` exists to stop a sheet's scroll from moving the page. Natively, the system `.sheet` coordinates its scroll view with its own drag. Use it rather than a hand-rolled drawer (see `gestures`).
- Don't attach a `DragGesture` to a whole scroll view to block bounce. It steals scrolling. Use `.simultaneousGesture` only when you really need both.

### 5. Text selection on controls

Native controls never select their labels on long-press, and `Text` isn't selectable unless you opt in. The rule from the web transfers as the inverse: **make content selectable, keep controls not.**

```swift
struct OrderSummary: View {
    let orderNumber: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order \(orderNumber)")
                .font(.body.monospacedDigit())
                // content the user may want to copy
                .textSelection(.enabled)
            Button("Track order") {}
                .buttonStyle(.pressable)
        }
    }
}
```

### 6. Carousels

The web needs `touch-action: pan-y` so the browser knows which axis the carousel owns. A horizontal `ScrollView` inside a vertical one already resolves the axis by the direction of the drag. Emil's closing advice is the one that matters: **native scroll physics beat a hand-rolled spring**. The native `scroll-snap-type` is `scrollTargetBehavior`.

```swift
struct Carousel: View {
    let colors: [Color] = [.red, .orange, .green, .blue]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(colors.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(colors[index].gradient)
                        .containerRelativeFrame(.horizontal)
                        .frame(height: 200)
                        .accessibilityLabel("Slide \(index + 1)")
                }
            }
            .scrollTargetLayout()
        }
        // snap to each slide; use .paging for full-width pages without spacing
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}
```

A custom `DragGesture` carousel is only worth it when the motion can't be expressed as scrolling. If you build one, see `gestures` for velocity and rubber-banding.

### 7. Status bar

There's no `theme-color`. By default the status bar text follows the screen's color scheme (dark text in light mode, light text in dark mode), not the pixels behind it. So it goes unreadable over custom headers that don't match that scheme, like a dark hero image in light mode. Fixes:

- Inside a `NavigationStack`, set `.toolbarColorScheme(.dark, for: .navigationBar)` with `.toolbarBackground(.visible, for: .navigationBar)` on a dark bar.
- For a full-screen dark hero, set `.preferredColorScheme(.dark)` on the presented screen only, or keep text readable with a scrim.
- Hide it (`.statusBarHidden()`) only for immersive media, never to gain space.

### 8. Right in the Simulator, wrong on the phone

- Run on a real iPhone from Xcode. Test on one a few years old, not the newest on your desk.
- Test with the keyboard open, in landscape once, with large Dynamic Type once, and with Reduce Motion on.
- Test edge gestures: does your bottom bar or custom drag fight the home indicator or the back swipe? If a full-screen game-like surface really needs the edge, `.defersSystemGestures(on:)` delays the system gesture; use it rarely.
- Haptics (`.sensoryFeedback`) only exist on device.

## Baseline

Most of the web baseline is meta tags and CSS a native app doesn't have. The native floor for a new screen:

- Backgrounds ignore the safe area; content doesn't.
- Every field has a keyboard type, content type, and submit label.
- Every custom button uses a `ButtonStyle` with touch-down feedback.
- Scroll views that may be short use `.scrollBounceBehavior(.basedOnSize)`.
- Text styles are Dynamic Type styles (`.font(.body)`), never fixed sizes.

## Never Ship

| Never | Instead |
| --- | --- |
| Clamping `.dynamicTypeSize` to protect a layout | Fix the layout (`ViewThatFits`, stack, scroll) |
| `.onTapGesture` as a button | `Button` with a `ButtonStyle` |
| `.ignoresSafeArea()` on content or controls | Only on backgrounds; `.safeAreaInset` for bars |
| `.ignoresSafeArea(.keyboard)` on a screen with fields | Default keyboard avoidance |
| A hand-rolled snapping carousel when scrolling works | `scrollTargetBehavior` |
| `.textSelection(.enabled)` on controls, or never on copyable content | Selectable content, unselectable controls |
| Branching on device model or screen height | Size classes, Dynamic Type size, safe area |
| Declaring it fixed from the Simulator | Real hardware |

## Output

Apply the fixes. Then, in at most a few lines:

- **What was wrong**: the symptom from the table, and the one-line why.
- **What changed**: file and modifier, one line each (`File.swift:line`).
- **What needs a phone**: which fixes you verified from code and which the user must confirm on hardware.

Don't pad this into a report. The code is the deliverable.

## Tone

Opinionated and brief. Most of these are one modifier; say it and the reason and move on. When the honest answer is "this is a web problem your app doesn't have", say that. When it's "I can't verify this without a device", say that instead of claiming it's fixed.

## No native equivalent

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
