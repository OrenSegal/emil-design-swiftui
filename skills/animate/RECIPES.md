# Animation Recipes

Ready-to-build SwiftUI implementations for the cases that come up most. Start from the recipe, then adapt — don't rebuild from scratch.

Curves are the `.emilEaseOut()`, `.emilEaseInOut()`, `.emilDrawer()`, `.emilEase()` and `.emilPress` tokens from `tools/Motion.swift`, described in SKILL.md. `.emilEase()` is CSS `ease`, `.timingCurve(0.25, 0.1, 0.25, 1, duration:)`.

Several of these components exist in the system. **Check first**: `Menu`, `Picker`, `.popover`, `.sheet` with `.presentationDetents`, `.alert`, `.confirmationDialog`, `DisclosureGroup` and `.help()` already have motion, accessibility and Reduce Motion handled, and you shouldn't retime them. The recipes below are for the cases where you've decided a custom component is right.

---

## Button press

Any pressable element. Instant feedback that the interface heard the user.

```swift
import SwiftUI

struct SaveButton: View {
    let save: () -> Void

    var body: some View {
        Button(action: save) {
            // Inside the label: the style scales only its label, and the label is the hit area.
            Text("Save")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.tint, in: .capsule)
                .foregroundStyle(.white)
        }
        // scale 0.97 on touch-down, 160 ms ease-out; dims instead of scaling under Reduce Motion
        .buttonStyle(.pressable)
    }
}
```

`scaleEffect` scales children too — the label and icons come along, which is what makes it read as a physical press. `configuration.isPressed` flips on touch-down, so the feedback lands on the press, not the release.

No hover gating needed: `isPressed` is a real press on touch and pointer alike.

---

## Dropdown, popover, menu, select

Use `Menu`, `Picker` or `.popover` first; they anchor to their source and own their motion. For a custom inline panel, scale it out of its trigger, not out of thin air.

```swift
import SwiftUI

struct SortPanel: View {
    @State private var isOpen = false
    @State private var newestFirst = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button("Sort", systemImage: "arrow.up.arrow.down") { isOpen.toggle() }
                .accessibilityValue(isOpen ? "Expanded" : "Collapsed")
            if isOpen {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Newest First", isOn: $newestFirst)
                }
                .font(.body)
                .padding()
                .frame(maxWidth: 260)
                .background(.regularMaterial, in: .rect(cornerRadius: 12))
                // The anchor is the trigger: the panel drops from the top-trailing button.
                .transition(reduceMotion
                    ? .opacity
                    : .scale(scale: 0.95, anchor: .topTrailing).combined(with: .opacity))
            }
        }
        .animation(.emilEaseOut(0.2), value: isOpen)
    }
}
```

The `anchor:` is the whole point — the panel should look like it came out of the thing you tapped.

---

## Tooltip

Touch has no tooltips. On iPad with a pointer and on Mac, `.help("…")` is the system tooltip and its timing belongs to the system. Build a custom hover hint only when the content needs more than `.help` can show: same shape as a popover, faster.

```swift
import SwiftUI

struct HoverHint: View {
    let hint: String
    @State private var isHovering = false
    @State private var isPinned = false // tap toggles it, so touch users can reach it too
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button { isPinned.toggle() } label: {
            Image(systemName: "info.circle")
                .font(.body)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(hint)
        .onHover { isHovering = $0 } // pointer extra: hover shows it too
        .overlay(alignment: .top) {
            if isHovering || isPinned {
                Text(hint)
                    .font(.caption)
                    .padding(6)
                    .background(.regularMaterial, in: .rect(cornerRadius: 6))
                    .fixedSize()
                    .alignmentGuide(.top) { $0[.bottom] + 6 }
                    // Grows out of the icon below it.
                    .transition(reduceMotion
                        ? .opacity
                        : .scale(scale: 0.97, anchor: .bottom).combined(with: .opacity))
                    .accessibilityHidden(true) // the label already carries it
            }
        }
        .animation(.emilEaseOut(0.125), value: isHovering || isPinned)
    }
}
```

Hover never exists on touch, so the hint can't live behind hover alone: the icon is a button that toggles it, and hover is the pointer shortcut on top.

The detail most implementations miss still holds for custom hover UI: an initial delay prevents accidental activation, and once one hint is open, neighbours open instantly — no delay and no animation — which makes the whole toolbar feel faster. That needs shared "a hint is open" state across the toolbar; the system `.help` handles its own.

---

## Modal

Use `.sheet`, `.fullScreenCover` or `.alert` first. A custom centered card (a confirmation that must sit over a specific screen) is the one popover that stays centered.

```swift
import SwiftUI

struct ConfirmCard: View {
    @Binding var isPresented: Bool
    let confirm: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                    .accessibilityHidden(true)
                    .transition(.opacity)

                VStack(spacing: 16) {
                    Text("Discard draft?").font(.headline)
                    HStack {
                        Button("Cancel") { isPresented = false }
                        Button("Discard", role: .destructive) { confirm(); isPresented = false }
                    }
                }
                .padding(24)
                .background(.regularMaterial, in: .rect(cornerRadius: 20))
                .accessibilityAddTraits(.isModal)
                .accessibilityAction(.escape) { isPresented = false }
                // Centered on purpose: a modal isn't anchored to a trigger.
                .transition(reduceMotion
                    ? .opacity
                    : .scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.emilEaseOut(0.25), value: isPresented)
    }
}
```

The backdrop's opacity animates in the same transaction, so they read as one surface.

---

## Drawer / sheet

A modal bottom sheet is `.sheet` with `.presentationDetents([.medium, .large])` — its curve, drag and Reduce Motion belong to the system. A custom, non-modal drawer that lives inside your layout (a mini player, an inspector) slides by its own height on the drawer curve:

```swift
import SwiftUI

struct BottomDrawer<Content: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            if isOpen {
                content
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.regularMaterial, in: .rect(cornerRadius: 24))
                    // Moves by its own height, whatever the content.
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .animation(.emilDrawer(0.5), value: isOpen)
    }
}
```

`.move(edge: .bottom)` is the native `translateY(100%)`: the drawer is offset by its own height before it animates in.

Add drag and it becomes a gesture problem — see **Drag to dismiss** below.

---

## Toast

There's no system toast on iOS, so this one is custom.

```swift
import SwiftUI

struct ToastHost: View {
    let displayTime: Duration // how long it stays is a product decision
    @State private var message: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // CSS `ease`, 400 ms: tuned to the component, not to the generic UI budget.
    private let toastCurve: Animation = .emilEase(0.4)

    var body: some View {
        ZStack(alignment: .bottom) {
            Button("Save") {
                withAnimation(toastCurve) { message = "Saved" }
                AccessibilityNotification.Announcement("Saved").post()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let message {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: .capsule)
                    .padding(.bottom, 24)
                    // Enters from the bottom and leaves through the bottom.
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .task(id: message) {
                        guard (try? await Task.sleep(for: displayTime)) != nil else { return }
                        withAnimation(toastCurve) { self.message = nil }
                    }
            }
        }
    }
}
```

- `ease` rather than ease-out, slightly slower than typical UI: Sonner reads as elegant partly because its motion is tuned to the component's personality rather than to the generic UI budget.
- It's a state animation, not a `keyframeAnimator`, so tapping Save twice in a second heads for the new state from where the toast is. A keyframe track would also pick up from the current value, but it would play its authored path rather than follow the new target.

When toasts stack and the list reflows, the opacity change has to work against the height change. There's no formula for that pair — adjust until it feels right, then check it again the next day.

---

## Accordion / collapse

`DisclosureGroup` (and `List` sections with `isExpanded`) first. A custom one:

```swift
import SwiftUI

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                // Siblings move with the height change, so Reduce Motion makes it instant.
                withAnimation(reduceMotion ? nil : .emilEaseOut(0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(question).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .contentShape(.rect) // .plain hit-tests only drawn pixels: make the Spacer tappable too
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                Text(answer)
                    .font(.body)
                    .transition(.opacity)
            }
        }
        .clipped()
    }
}
```

Keep it short — this is one of the few animations that costs layout on every frame, so a long duration is expensive as well as sluggish. SwiftUI measures the content for you; you never animate toward a guessed height.

---

## Stagger a group entrance

For a list or grid the user sees occasionally — not for a list they scroll past all day. For group entrances, follow `../choreograph/SKILL.md` (one entrance per container, non-uniform delays).

```swift
import SwiftUI

struct OnboardingPoints: View {
    struct Point: Identifiable { let id: Int; let text: String }
    let points: [Point]
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // 0, 50, 90, 120 ms: shrinking gaps; items past the 4th arrive with the 4th.
    private let delays: [Double] = [0, 0.05, 0.09, 0.12]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                Text(point.text)
                    .font(.body)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared || reduceMotion ? 0 : 8)
                    .animation(
                        .emilEaseOut(0.3).delay(reduceMotion ? 0 : delays[min(index, delays.count - 1)]),
                        value: appeared
                    )
            }
        }
        // This content is on screen when the screen appears; there's no insertion for a
        // transition to hang on, so flipping state on appear is the trigger. (For a view
        // inserted by state, use a transition instead.)
        .onAppear { appeared = true }
    }
}
```

Stagger is decorative — it must never block interaction while it plays.

---

## Hold to confirm

For destructive actions where a plain tap is too easy to fire by accident.

```swift
import SwiftUI

struct HoldToDeleteButton: View {
    let onConfirm: () -> Void
    @State private var isHolding = false
    @State private var confirmations = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        label(confirmed: false)
            .overlay {
                // A copy in the confirmed style, revealed left to right: the native clip-path inset.
                label(confirmed: true)
                    .mask(alignment: .leading) {
                        Rectangle().scaleEffect(x: isHolding ? 1 : 0, anchor: .leading)
                    }
                    .accessibilityHidden(true)
            }
            // Scoped to the scale only: press timing here, while the fill keeps its 2 s linear.
            .animation(.emilPress) { $0.scaleEffect(isHolding && !reduceMotion ? 0.97 : 1) }
            .onLongPressGesture(minimumDuration: 2) {
                confirmations += 1
                onConfirm()
            } onPressingChanged: { pressing in
                // Press: slow and deliberate. Release: snappy.
                withAnimation(pressing ? .linear(duration: 2) : .emilEaseOut(0.2)) {
                    isHolding = pressing
                }
            }
            // One haptic, on the causal event: the delete itself, not the press.
            .sensoryFeedback(.impact(weight: .medium), trigger: confirmations)
            // VoiceOver can't do a 2 s hold: expose a plain button action.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Delete")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onConfirm() }
    }

    private func label(confirmed: Bool) -> some View {
        Text("Hold to Delete")
            .font(.body.weight(.semibold))
            .foregroundStyle(confirmed ? Color.white : Color.red)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(confirmed ? Color.red : Color.red.opacity(0.12), in: .capsule)
    }
}
```

`linear` is correct here — the fill is a progress indicator, and progress shouldn't ease. Under Reduce Motion the fill stays (it's the state indication) and the scale goes.

---

## Tab indicator with a color transition

Timing individual color transitions across a tab list never quite lands. Clip instead.

Duplicate the tab row. Style the copy as the active state — different background, different text color. Mask the copy so only the active tab shows, and animate the mask on change:

```swift
import SwiftUI

struct ClippedTabs: View {
    enum Tab: String, CaseIterable, Identifiable {
        case all = "All", unread = "Unread", flagged = "Flagged"
        var id: Self { self }
    }

    @State private var selection: Tab = .all
    @State private var frames: [Tab: CGRect] = [:]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        tabRow(active: false)
            .overlay {
                tabRow(active: true)
                    .mask(alignment: .topLeading) {
                        let frame = frames[selection] ?? .zero
                        Capsule()
                            .frame(width: frame.width, height: frame.height)
                            .offset(x: frame.minX, y: frame.minY)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .coordinateSpace(.named("tabs"))
            .animation(reduceMotion ? nil : .emilEaseInOut(0.25), value: selection)
    }

    private func tabRow(active: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases) { tab in
                Button { selection = tab } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(active ? Color.white : Color.primary)
                        .background(active ? Color.accentColor : Color.clear, in: .capsule)
                        // Inactive tabs draw only text: give the whole 44 pt cell the tap.
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("tabs")) } action: { frame in
                    if !active { frames[tab] = frame }
                }
            }
        }
    }
}
```

The text and background change together, in perfect sync, because they're one view being revealed rather than two colors being interpolated. If you only need a pill sliding behind unchanged labels, `matchedGeometryEffect` on the pill is simpler; the clip is for when the label color must flip exactly with it.

---

## Scroll reveal

Marketing and onboarding surfaces only. Don't do this to functional UI a user visits daily.

```swift
import SwiftUI

struct RevealOnScroll<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .mask(alignment: .top) {
                // Wipes down from the top; Reduce Motion fades instead.
                Rectangle().scaleEffect(x: 1, y: revealed || reduceMotion ? 1 : 0, anchor: .top)
            }
            .opacity(reduceMotion && !revealed ? 0 : 1)
            .onScrollVisibilityChange { visible in
                guard visible, !revealed else { return } // fire once
                withAnimation(.emilEaseInOut(0.6)) { revealed = true }
            }
    }
}
```

`.onScrollVisibilityChange(threshold:)` (iOS 18) is the native `IntersectionObserver`; its threshold is a fraction of the view, not a point margin. Fire it once — re-animating on every scroll-by is an interface fighting its reader. That's why this isn't `.scrollTransition`, which re-plays as the view scrolls in and out.

---

## Drag to dismiss

The gesture recipe. Springs, not durations, because the user can reverse mid-motion. The full treatment (snap points, velocity handoff, sheets) is in `../gestures/SKILL.md`.

```swift
import SwiftUI

struct SwipeDownCard: View {
    let dismissDistance: CGFloat // the component's own threshold
    let onDismiss: () -> Void
    @State private var offsetY: CGFloat = 0
    @State private var dragStart: CGFloat? // where the card was when the finger landed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("Now Playing")
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
            .offset(y: offsetY) // set on the dragged view itself, not via state high in the tree
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Grab it mid-spring and it continues from there instead of teleporting to 0.
                        let start = dragStart ?? offsetY
                        dragStart = start
                        let y = start + value.translation.height
                        // Down follows the finger 1:1. Up is past the natural edge: friction, not a wall.
                        offsetY = y >= 0 ? y : -rubberband(-y, dimension: 120)
                    }
                    .onEnded { value in
                        dragStart = nil
                        // Dismiss on a flick, not just on distance: release velocity in pt/s.
                        if offsetY >= dismissDistance || value.velocity.height > 500 {
                            onDismiss()
                        } else {
                            withAnimation(reduceMotion ? .spring(.emilUI) : .spring(duration: 0.5, bounce: 0.2)) {
                                offsetY = 0
                            }
                        }
                    }
            )
            .accessibilityAction(named: "Dismiss") { onDismiss() }
    }
}
```

Four details that separate a good drag from a bad one, in SwiftUI terms:

- **Tracking past the bounds** comes free: a `DragGesture` keeps tracking after the finger leaves the view (the web needs pointer capture for this).
- **One finger** comes free too: `DragGesture` follows a single touch. Only a custom `UIGestureRecognizer` needs an `isDragging` guard against a second finger making the view jump.
- **Damping past boundaries** — dragging beyond a natural edge moves the view less the further it goes (`rubberband(_:dimension:)`). Real things slow before they stop.
- **Friction, not a wall** — allow the over-drag with rising resistance rather than refusing it.

`value.velocity` is the release velocity in pt/s; test it against 500 pt/s. The web recipe's 0.11 px/ms (110 pt/s) is Sonner's *average* over the whole drag (distance ÷ elapsed time), not a release velocity, so never compare `value.velocity` with 110. If you want Sonner's exact behaviour, divide `translation` by the time since `.onChanged` first fired and compare that with 110.

Settle with a spring so an interrupted drag keeps its velocity: `.spring(duration: 0.5, bounce: 0.2)`.

---

## Masking a crossfade that won't settle

When two states overlap visibly during a transition and no amount of easing or duration tuning fixes it, blur the seam:

```swift
import SwiftUI

struct SyncStatus: View {
    let status: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Text(status)
                .font(.headline)
                .id(status) // new identity → old view leaves, new view enters
                .transition(reduceMotion ? .opacity : AnyTransition(.blurReplace))
        }
        .animation(.emilEase(0.2), value: status)
    }
}
```

Without blur the eye reads two distinct objects swapping. Blur blends them into one perceived transformation. For a manual version, `.blur(radius: 2)` with opacity `0.7` during the change. Keep it under 20 pt — blur renders offscreen, so heavy blur is expensive.

---

## Programmatic sequencing

When the motion needs code control — do this, then that — reach for `withAnimation`'s completion before anything heavier:

```swift
import SwiftUI

struct PhotoReveal: View {
    @State private var revealed = false
    @State private var showCaption = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.artframe")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .accessibilityLabel("Gallery cover")
                .mask(alignment: .top) {
                    Rectangle().scaleEffect(x: 1, y: revealed || reduceMotion ? 1 : 0, anchor: .top)
                }
                .opacity(reduceMotion && !revealed ? 0 : 1)
            if showCaption {
                Text("Spring Collection").font(.title3).transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.emilEaseInOut(1.0)) {
                revealed = true
            } completion: {
                withAnimation(.emilEaseOut()) { showCaption = true }
            }
        }
    }
}
```

Interruptible, no dependency, and it starts from the on-screen value if `revealed` changes mid-flight. When predetermined motion must stay smooth while the main thread is busy (a loading screen that's parsing data), that's the case for Core Animation — `UIView.animate` or a `CABasicAnimation` in a `UIViewRepresentable` — because the render server keeps playing it.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `useEffect(() => setMounted(true))` mount-flag fallback when `@starting-style` is unavailable | There's no "unavailable" case: transitions always run on insertion | `.transition(_:)` with the insertion in `withAnimation` |
| `var(--transform-origin)` from Base UI | React library variable | System `.popover` anchors itself; custom panels pass `anchor:` |
| `[data-instant]` tooltips via a CSS attribute | System `.help()` owns tooltip timing; touch has no tooltips | Shared "hint open" state for custom pointer hints on iPad/Mac |
| Measuring content height in JS to animate toward `auto` | SwiftUI lays the content out and animates the size itself | `if isExpanded { … }` inside `withAnimation` |
| `useInView` `margin: "-100px"` | `onScrollVisibilityChange` takes a visible fraction, not a point margin | `threshold:` |
| Pointer capture (`setPointerCapture`) | A `DragGesture` keeps tracking outside the view's bounds already | None needed |
| "Heavy blur is expensive, especially in Safari" | Safari-specific | Blur renders offscreen in SwiftUI too: keep the radius small and measure |
| WAAPI `element.animate()` | Browser API | `withAnimation(_:completion:)`; Core Animation when it must run on the render server |
