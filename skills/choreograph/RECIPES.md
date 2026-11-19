# Choreography Recipes

Copy-ready SwiftUI patterns for the relationships in [SKILL.md](SKILL.md). The values are starting points, so tune them on a recording (Simulator ▸ Debug ▸ Slow Animations, then step the screen recording frame by frame).

## Overlap: per-view delays

For one-shot entrances (an onboarding hero, a first-run screen). Each view carries its own delay, so you don't need one modifier per item. The gaps shrink as the group goes on (120 ms, then 80 ms), so it reads as a wave, not a metronome.

```swift
import SwiftUI

struct Entrance: ViewModifier {
    let appeared: Bool
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // CSS `ease`, 600 ms: a marketing-tier entrance, seen once.
    private let curve: Animation = .emilEase(0.6)

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            // Reduce Motion: fade only, no rise, no delay — the group appears together.
            .offset(y: appeared || reduceMotion ? 0 : 10)
            .animation(curve.delay(reduceMotion ? 0 : delay), value: appeared)
    }
}

struct WelcomeHero: View {
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome to Ledger")
                .font(.largeTitle.bold())
                .modifier(Entrance(appeared: appeared, delay: 0))
            Text("Track every shared expense in one place.")
                .font(.title3)
                .modifier(Entrance(appeared: appeared, delay: 0)) // same beat as the title
            Text("Invite your household and settle up in a tap.")
                .font(.body)
                .foregroundStyle(.secondary)
                .modifier(Entrance(appeared: appeared, delay: 0.12))
            Button("Get Started") {}
                .buttonStyle(.borderedProminent)
                .modifier(Entrance(appeared: appeared, delay: 0.2))
        }
        .padding()
        // On screen when the screen appears: there's no insertion for a transition to hang on,
        // so flipping state on appear is the trigger.
        .onAppear { appeared = true }
    }
}
```

- A delayed view sits at its start value until its delay elapses, so later items don't flash their final state first, and it holds the end value afterwards. No fill mode to set.
- The button is tappable the moment it's visible; nothing disables hit testing during the entrance.
- The `appeared` flag lives in the screen, not in the environment or high up the tree: it changes once, so the cost is nothing here. Don't drive per-frame values (a drag) through state high in a large tree.

## Overlap: role-based stagger with shrinking gaps

```swift
import SwiftUI

/// Delay for the item at `index`: the first gap is `step`, and each later gap shrinks by `decay`,
/// so the group reads as a wave. Delays radiate from `origin` (pass the index the user touched).
/// Items more than `cap` away share the last delay, so a long list never waits longer.
func staggerDelay(index: Int, step: Double = 0.06, decay: Double = 0.8, from origin: Int = 0, cap: Int = 4) -> Double {
    let distance = min(abs(index - origin), cap)
    return (0..<distance).reduce(0) { total, k in total + step * pow(decay, Double(k)) }
}

struct ReleaseNotesHeader: View {
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Decoration: fades in place.
            Text("New")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.tint.opacity(0.15), in: .capsule)
                .stagger(shown, rise: 0, duration: 0.3, delay: staggerDelay(index: 0), reduceMotion: reduceMotion)
            // Lead: travels furthest, lasts longest.
            Text("Version 4")
                .font(.largeTitle.bold())
                .stagger(shown, rise: 12, duration: 0.5, delay: staggerDelay(index: 1), reduceMotion: reduceMotion)
            // Support: shorter, smaller.
            Text("Shared budgets, faster sync.")
                .font(.title3)
                .stagger(shown, rise: 6, duration: 0.4, delay: staggerDelay(index: 2), reduceMotion: reduceMotion)
            Button("See What's New") {}
                .stagger(shown, rise: 6, duration: 0.4, delay: staggerDelay(index: 3), reduceMotion: reduceMotion)
        }
        .onAppear { shown = true }
    }
}

extension View {
    /// Each role sets its own distance and duration; the stagger only decides when it starts.
    func stagger(_ shown: Bool, rise: CGFloat, duration: Double, delay: Double, reduceMotion: Bool) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : rise)
            .animation(.emilEaseOut(duration).delay(reduceMotion ? 0 : delay), value: shown)
    }
}
```

- With the defaults the gaps are 60, 48, 38, 31 ms — inside the 30–80 ms band — and the fifth item and everything after it starts at ~177 ms, so the group stays under ~300 ms.
- `staggerDelay(index: i, step: 0.05, from: count / 2)` radiates out from the middle. `staggerDelay(index: i, from: tappedIndex)` radiates outward from the item the user touched; for a grid, use the distance from the touched cell instead of `abs(index - origin)`.

## Together: remove the leaving view from the flow

Siblings close the gap *while* the removed chip fades, not after.

```swift
import SwiftUI

struct FilterChips: View {
    struct Chip: Identifiable { let id: UUID = UUID(); let label: String }
    @State private var chips = ["Groceries", "Rent", "Travel", "Gifts"].map { Chip(label: $0) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(chips) { chip in
                Button {
                    // One transaction: the chip leaves layout now, siblings slide into the gap as it fades.
                    withAnimation(reduceMotion ? nil : .emilEaseOut(0.2)) {
                        chips.removeAll { $0.id == chip.id }
                    }
                } label: {
                    Label(chip.label, systemImage: "xmark")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(chip.label)")
                // No entrance (the web's initial={false}); exit only.
                .transition(.asymmetric(insertion: .identity,
                                        removal: .opacity.combined(with: .scale(scale: 0.95))))
            }
        }
    }
}
```

This works because a stack lays out without the removed view the moment the state changes, then lets it play its removal where it was. Verify it under Slow Animations in your layout: a custom `Layout` or a `List` behaves differently (`List` row deletion is system motion).

## Together: crossfade views in a resizing container

The container's height and the content swap are one object: same timing family.

```swift
import SwiftUI

struct PlanDetails: View {
    enum Pane: Hashable { case summary, breakdown }

    @State private var pane: Pane = .summary
    @State private var heights: [Pane: CGFloat] = [:]
    @State private var fadeDuration: Double = 0.15
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The container: a strong ease-out, 270 ms.
    private let heightCurve: Animation = .timingCurve(0.25, 1, 0.5, 1, duration: 0.27)

    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .top) {
                content(for: pane)
                    .id(pane) // a new identity is what tells SwiftUI a view left
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { [pane] height in
                        heights[pane] = height
                    }
                    // The content: a lighter curve from the same family, timed to the jump.
                    .transition(
                        (reduceMotion ? AnyTransition.opacity : .opacity.combined(with: .scale(scale: 0.96)))
                            .animation(.easeOut(duration: fadeDuration))
                    )
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .clipped()

            Button(pane == .summary ? "Show Breakdown" : "Show Summary") {
                show(pane == .summary ? .breakdown : .summary)
            }
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
    }

    private func show(_ next: Pane) {
        // The fade scales with how far the container moves: clamp(0.15 s, Δheight / 500, 0.27 s).
        if let from = heights[pane], let to = heights[next] {
            fadeDuration = min(max(abs(to - from) / 500, 0.15), 0.27)
        } else {
            fadeDuration = 0.15 // first visit: nothing measured yet
        }
        withAnimation(heightCurve) { pane = next }
    }

    @ViewBuilder private func content(for pane: Pane) -> some View {
        switch pane {
        case .summary:
            Text("Family plan · 4 members").font(.headline)
        case .breakdown:
            VStack(alignment: .leading, spacing: 8) {
                Text("Family plan").font(.headline)
                Text("Base: $12.00").font(.body)
                Text("Extra members: $6.00").font(.body)
                Text("Storage add-on: $3.00").font(.body)
            }
        }
    }
}
```

- The height uses a strong ease-out, and the content uses a lighter curve from the same family, so the swap stays visible without falling out of sync.
- Heights are cached per pane as each one is shown, so the second visit onwards knows Δ before it animates.
- The incoming view reads the new `fadeDuration`; the outgoing view may still use the one it last rendered with (see "Direction-aware steps"). If the two fades visibly disagree, set `fadeDuration` one update before the swap.
- If the container is part of a larger component (a drawer), bring that component's own open duration in line with this one so the whole thing feels like one entity.

## Direction-aware steps

```swift
import SwiftUI

/// Slides 110% of the view's own width: in from the trailing edge going forward, out toward the leading edge.
/// `.offset` isn't mirrored for right-to-left, so the caller flips `direction` for RTL layouts.
struct StepSlide: Transition {
    var direction: CGFloat // +1 forward, −1 back

    func body(content: Content, phase: TransitionPhase) -> some View {
        let side: CGFloat = switch phase {
        case .willAppear: direction     // enters from the trailing side going forward
        case .didDisappear: -direction  // leaves toward the leading side going forward
        default: 0
        }
        return content
            .opacity(phase.isIdentity ? 1 : 0)
            .visualEffect { view, proxy in
                view.offset(x: side * proxy.size.width * 1.1) // 110% of its own width
            }
    }
}

struct SignupSteps: View {
    private let titles = ["Account", "Profile", "Household", "Done"]
    @State private var step = 0
    @State private var direction: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Text(titles[step])
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .id(step)
                    .transition(reduceMotion ? .opacity : AnyTransition(StepSlide(direction: direction)))
            }
            .clipped()

            // Back / Continue sit in the same stack, so they follow any height change in the same transaction.
            HStack {
                Button("Back") { go(-1) }.disabled(step == 0)
                Spacer()
                Button("Continue") { go(1) }.disabled(step == titles.count - 1)
            }
        }
        .padding()
    }

    private func go(_ delta: Int) {
        let forward: CGFloat = delta > 0 ? 1 : -1
        direction = layoutDirection == .rightToLeft ? -forward : forward
        // The leaving view keeps the transition from its last render, so let it render
        // the new direction before the step changes. Changing both at once slides it the old way.
        Task { @MainActor in
            withAnimation(.spring(duration: 0.5, bounce: 0)) { step += delta }
        }
    }
}
```

**The first reversal needs the new direction.** The leaving view has to slide the *new* way (Motion solves this by putting `custom` on both `AnimatePresence` and the child). In SwiftUI a removed view animates with the transition it carried when it was last rendered, so if `direction` and `step` change in the same update, the first Back slides the leaving step the old way. That is why `go` sets `direction` first and changes the step from a `Task { @MainActor in … }`, one update later. Both behaviours were checked with the [probe app](../../Examples/README.md) on an iOS 26.5 simulator. Still tap Continue, Continue, Back under Slow Animations in your own layout.

For small containers or similar views, swap the 110% slide for a crossfade with an 8 pt shift and a light `.blur`. The eyes barely move and the change still reads.

## Sequence: one draw after another

```swift
import SwiftUI

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.maxY - rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY + rect.height * 0.28))
        return path
    }
}

struct DrawnCheckbox: View {
    let title: String
    @Binding var isOn: Bool
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 24
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // cubic-bezier(0.645, 0.045, 0.355, 1)
    private func draw(_ duration: Double) -> Animation {
        .timingCurve(0.645, 0.045, 0.355, 1, duration: duration)
    }

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: size / 4)
                        .trim(from: 0, to: isOn ? 1 : 0)
                        .stroke(.tint, lineWidth: 2)
                        .animation(reduceMotion ? nil : (isOn ? draw(0.6) : .emilEaseOut(0.2)), value: isOn)
                    CheckmarkShape()
                        .trim(from: 0, to: isOn ? 1 : 0)
                        .stroke(.tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        // Starts 0.1 s before the square's 0.6 s ends. Unchecking: both at once, shorter.
                        .animation(reduceMotion ? nil : (isOn ? draw(0.4).delay(0.5) : .emilEaseOut(0.2)), value: isOn)
                }
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: size / 4).stroke(.quaternary, lineWidth: 2))
                Text(title).font(.body)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
```

`.trim(from:to:)` works on normalized path length, so both shapes go 0 → 1 with round numbers — the native version of `pathLength="100"` with a dash offset. Starting the checkmark 0.1 s before the square finishes makes the handoff read as one gesture.

## Sequence: morph between two rich states

When a container changes width *and* height between dense views, the safe default is to let the old content leave before the new content starts, while the container itself morphs straight away. With two states, the sizes are hardcoded per state; the bounce is 0, because a tap applies no force.

```swift
import SwiftUI

struct IslandMorph: View {
    enum Mode: Hashable { case compact, expanded }

    @State private var requested: Mode = .compact // drives the container
    @State private var shown: Mode? = .compact    // drives the content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button { request(requested == .compact ? .expanded : .compact) } label: {
            ZStack {
                if let shown {
                    content(for: shown)
                        .id(shown)
                        .transition(.opacity)
                }
            }
            .frame(width: size(for: requested).width, height: size(for: requested).height)
            .background(.black, in: .rect(cornerRadius: requested == .compact ? 20 : 32))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Timer")
        .accessibilityValue(requested == .compact ? "Collapsed" : "Expanded")
    }

    private func request(_ next: Mode) {
        // The container morphs now. A tap applies no force, so no bounce. (If a drag drove the morph,
        // the smaller state would get more bounce than the larger one.)
        let spring: Animation = reduceMotion ? .spring(.emilUI) : .spring(duration: 0.5, bounce: 0)
        withAnimation(spring) { requested = next }

        guard shown != nil else { return } // an exit is in flight; its completion reads `requested`
        withAnimation(.emilEaseOut(0.15)) {
            shown = nil
        } completion: {
            // Re-read the latest request, not a captured value: a second tap mid-exit must win.
            withAnimation(.emilEaseOut(0.2)) { shown = requested }
        }
    }

    private func size(for mode: Mode) -> CGSize {
        mode == .compact ? CGSize(width: 120, height: 40) : CGSize(width: 340, height: 160)
    }

    @ViewBuilder private func content(for mode: Mode) -> some View {
        switch mode {
        case .compact:
            Label("12:04", systemImage: "timer").font(.subheadline.monospacedDigit())
        case .expanded:
            VStack(spacing: 8) {
                Text("Pasta").font(.headline)
                Text("12:04").font(.largeTitle.monospacedDigit())
                Text("remaining").font(.caption)
            }
        }
    }
}
```

To keep a crossfade between the two dense views anyway, you don't need the web's duplicate copy: a SwiftUI removal transition already renders the outgoing view where it was while the incoming one enters.

1. Swap with `.id(mode)` in a `ZStack` inside one `withAnimation`, and give the view an `.asymmetric` transition: plain opacity on insertion, opacity plus a scale on removal.
2. Give the outgoing view its own transform depending on where the container is going. Scale it up if the next state is larger and down if it's smaller, with a horizontal scale (`.scaleEffect(x:y:)` inside `AnyTransition.modifier(active:identity:)`) pulling it toward the center when the container narrows so it doesn't bleed out of the edges.
3. With a handful of states, hardcode these values per state pair. Keep the bounce at 0 for a tap; only a drag-driven morph earns bounce, and then smaller states get more.

The removal transform depends on the *next* state, so it hits the same last-rendered-transition question as direction-aware steps: verify each pair under Slow Animations.

## Carry: steer a shared-geometry animation through its parent

You can't customize the path a `matchedGeometryEffect` takes, but you can move the container it lands in.

```swift
import SwiftUI

struct MoveToBin: View {
    struct Photo: Identifiable { let id: Int; let symbol: String }

    @Namespace private var namespace
    @State private var library = [Photo(id: 1, symbol: "leaf"), Photo(id: 2, symbol: "flame"), Photo(id: 3, symbol: "drop")]
    @State private var bin: [Photo] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 32) {
            HStack(spacing: 12) {
                ForEach(library) { thumbnail($0) }
            }
            .frame(height: 56)

            HStack(spacing: -24) {
                ForEach(bin) { thumbnail($0).scaleEffect(0.6) }
            }
            .frame(width: 120, height: 80)
            .background(.quaternary, in: .rect(cornerRadius: 12))
            // Carry: the bin drops, and the photos morphing into it drop with it.
            .offset(y: bin.isEmpty || reduceMotion ? 0 : 73)
            .animation(reduceMotion ? nil : .emilEaseOut(0.3).delay(0.13), value: bin.isEmpty)

            Button("Delete All", role: .destructive) {
                withAnimation(reduceMotion ? nil : .emilEaseOut(0.3)) {
                    bin += library
                    library = []
                }
            }
            .disabled(library.isEmpty)
        }
    }

    private func thumbnail(_ photo: Photo) -> some View {
        Image(systemName: photo.symbol)
            .font(.title)
            .frame(width: 56, height: 56)
            .background(.thinMaterial, in: .rect(cornerRadius: 8))
            .matchedGeometryEffect(id: photo.id, in: namespace)
            .accessibilityLabel("Photo \(photo.id)")
    }
}
```

The photos morph into the bin *and* drop with it. The intent: `matchedGeometryEffect` interpolates their layout frames, and the bin's `.offset` (a render-time effect, outside layout) is applied on top. Check the combined path under Slow Animations; if the photos land where the bin *was*, move the drop into the bin's layout instead (for example, padding above it inside the same transaction). If the bin has a front face drawn above the photos, show it with a delay timed to when they have almost landed, so they never visibly pass through it.

## Orchestrated sequence across several events

Use this only when several views coordinate across several events (pointer hover, tap, idle timer) and you need to wait for completion. Everything below is state; nothing queries views.

```swift
import SwiftUI

struct InviteIcon: View {
    @State private var isHovering = false
    @State private var idleArmed = true
    @State private var taps = 0
    @State private var nudges = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let reset: Animation = .emilEaseOut(0.3)

    var body: some View {
        Button { taps += 1 } label: {
            Image(systemName: "hand.tap")
                .font(.largeTitle)
                .offset(y: isHovering && !reduceMotion ? -4 : 0)
                .overlay(alignment: .topTrailing) { motionLines }
                // Idle nudge: y 0 → −3 → 0. (The loop below never runs under Reduce Motion.)
                .keyframeAnimator(initialValue: 0.0, trigger: nudges) { view, y in
                    view.offset(y: y)
                } keyframes: { _ in
                    CubicKeyframe(-3, duration: 0.2)
                    CubicKeyframe(0, duration: 0.2)
                }
                // A repeat action skips the buildup: the pulse plays the instant the tap lands.
                .keyframeAnimator(initialValue: 1.0, trigger: taps) { view, scale in
                    view.scaleEffect(reduceMotion ? 1 : scale)
                } keyframes: { _ in
                    CubicKeyframe(0.96, duration: 0.4 / 3)
                    CubicKeyframe(1.02, duration: 0.4 / 3)
                    CubicKeyframe(1, duration: 0.4 / 3)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Invite")
        .onHover { hovering in
            if hovering {
                idleArmed = false // cancels the idle loop below
                withAnimation(reset) { isHovering = true }
            } else {
                withAnimation(reset) {
                    isHovering = false
                } completion: {
                    // Resume idling only once the reset has finished, and only if still not hovering.
                    if !isHovering { idleArmed = true }
                }
            }
        }
        // ~2.5 s before the first nudge, ~6 s between. A new id cancels the old loop, so loops never stack.
        .task(id: idleArmed) {
            guard idleArmed, !reduceMotion else { return }
            var wait: Duration = .seconds(2.5)
            while (try? await Task.sleep(for: wait)) != nil {
                nudges += 1
                wait = .seconds(6)
            }
        }
    }

    private var motionLines: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Capsule()
                    .frame(width: 2, height: 8)
                    .scaleEffect(y: isHovering && !reduceMotion ? 1 : 0, anchor: .bottom)
                    // Lands in the last ~20% of the 0.5 s hover move (70% → 90%):
                    // start at 0.35 s, take 0.1 s. The most important (middle) line goes first, the others 40 ms behind.
                    // The reset reuses `reset`, so the hover-out completion covers the lines too.
                    .animation(
                        isHovering ? .emilEaseOut(0.1).delay(0.35 + (index == 1 ? 0 : 0.04)) : reset,
                        value: isHovering
                    )
            }
        }
        .accessibilityHidden(true)
    }
}
```

- Re-hovering mid-reset is safe: the completion checks `isHovering` before re-arming, and `.task(id:)` cancels a loop the moment `idleArmed` changes.
- A re-triggered `keyframeAnimator` rebuilds its track from the current value and keeps velocity, but it always plays the authored pulse — right for a fixed pulse, wrong for anything that must follow a changing target (keep those as state animations).
- On touch there is no hover; the idle loop and the tap pulse still apply.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `--delay` custom property per item; "a custom property on a parent recalculates every descendant" | No CSS variables | A delay argument per view; keep per-frame state in the view that moves |
| `animation-fill-mode: both` / `forwards` | State animations hold start and end values on their own | None needed |
| Older Motion `staggerChildren` vs `delayChildren: stagger()` | Library-version detail | `staggerDelay(index:)` helper above |
| `position: absolute` + FLIP for the exiting element without a library | Stacks already lay out without the removed view while it transitions | `withAnimation` around the removal |
| `useMeasure` (react-use-measure) | React hook | `.onGeometryChange(for:of:action:)` |
| Duplicate-view crossfade (copy B at `opacity: 0` with a keyframe exit) | The removal transition already renders the outgoing view | `.asymmetric` transition with a per-pair removal transform |
| `data-animate` selectors inside a `useAnimate` scope | No DOM to query | One state value per moving part |
| `await Promise.all(...)` when durations differ | Animations aren't promises | `withAnimation` `completion:`; give a reset one shared animation |
