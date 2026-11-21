---
name: pick-ui-library
description: Pick the first-party SwiftUI or Apple framework component for an iOS UI task, working through the task list from Emil Kowalski's curated web picks (primitives, toasts, drawers and sheets, command menus, OTP, animated numbers, charts, long lists, drag and drop, state, styling, theming), and say plainly when there is no first-party answer.
disable-model-invocation: true
---

# Picking The Right Component

> Adapted from Emil Kowalski's [`pick-ui-library`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/pick-ui-library) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to find the first-party SwiftUI component for your task. The task list comes from Emil Kowalski's curated library picks; the answers are Apple's frameworks, not his picks.

Do not provide any other information until the user asks a question.

A lookup skill. When invoked with a task ("I need a bottom sheet", "what should I use for drag and drop?"), match the task to the list below and name the first-party component that covers it. Emil's web list is a set of deliberate, taste-driven library picks. This port keeps his *tasks* and his judgment about what each task needs, but it makes no third-party picks: he hasn't endorsed any Swift packages, so presenting one as his choice would be made up. The native version of "use the library that handles the edge cases" is "use the system component, which already handles them": accessibility, Dynamic Type, Reduce Motion, RTL, and motion users already know.

## How to use this

1. **Identify the task**, not the component the user named. "I need to show a dropdown" is a primitives task (`Menu` or `Picker`), even if they asked about something else.
2. **Check what's already in the project.** Look at `Package.swift`, `Package.resolved` (for an app, inside `<App>.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`), the package dependencies in the `.xcodeproj`, and any `Podfile` or `Cartfile`. If the project already depends on a package for this task, keep using it and say so; don't churn the dependency without being asked. Also check the deployment target: every answer below assumes iOS 18.
3. **Recommend one component**, say in one sentence what it's for, and wire it up if that's part of the request. Don't present a menu of options when the list has a clear answer.
4. **If the task has no first-party answer** (the `## No native equivalent` table), say so plainly: "no first-party component; build it with the house rules or pick a package yourself — not an Emil pick". Never name a third-party package as a recommendation.
5. **If the task isn't on the list at all**, say so explicitly, then answer from your own knowledge of Apple's frameworks, making clear you've left the list.

## The list

### UI components & primitives

| Task | First-party answer |
| --- | --- |
| Accessible UI components (dialogs, popovers, menus, selects…) | `Menu` (actions), `Picker` (choose one; `.menu` / `.segmented` / `.inline` styles), `.popover`, `.alert` and `.confirmationDialog`, `.sheet`, `Toggle`, `DisclosureGroup`. They ship focus handling, VoiceOver, dismissal, and system motion |
| Drawers / bottom sheets | `.sheet` with `.presentationDetents([.medium, .large])`, `.presentationDragIndicator(.visible)`, and `.presentationBackgroundInteraction(.enabled(upThrough: .medium))` for a sheet that leaves the screen behind it usable |
| One-time password / verification code inputs | Partial: a `TextField` with `.textContentType(.oneTimeCode)` and `.keyboardType(.numberPad)` gets the system's code suggestion above the keyboard. There's no first-party segmented-box OTP field (see the flag table) |
| Command menus (⌘K palettes) | No first-party palette on iOS; see the flag table |
| Toasts / notifications | No first-party toast; see the flag table |
| Customizable GUIs / control panels | No first-party tweak panel; see the flag table |

### Motion & visuals

| Task | First-party answer |
| --- | --- |
| General-purpose animation (springs, layout animations, enter/exit) | SwiftUI's own animation system: `withAnimation` / `.animation(_:value:)` with springs, `.transition` for enter and exit, `matchedGeometryEffect` and `.navigationTransition(.zoom(...))` for shared elements, `keyframeAnimator` / `phaseAnimator` for fixed sequences. House curves in [`tools/Motion.swift`](https://raw.githubusercontent.com/OrenSegal/emil-design-swiftui/main/tools/Motion.swift) |
| Animating numbers (counters, prices, stats) | `.contentTransition(.numericText(value:))` with `.monospacedDigit()`, changed inside `withAnimation` |
| Animated text components | No first-party component; see the flag table |
| 3D globes | No first-party component; see the flag table |
| Dynamic OG images | No first-party equivalent; see the flag table |
| Syntax highlighting | No first-party highlighter; see the flag table |

Emil's split still applies: reach for the heavier tools (`keyframeAnimator`, `matchedGeometryEffect`, gesture-driven springs) only when you need them. A simple fade or press state is one `.animation(_:value:)` or a `ButtonStyle`.

### Charts

| Task | First-party answer |
| --- | --- |
| Real-time / streaming charts | Swift Charts (`import Charts`): append points to the data you chart, and use `.chartScrollableAxes(.horizontal)` with `.chartXVisibleDomain(length:)` to keep a moving time window. Swift Charts renders what you give it; the streaming and the window logic are yours |
| General charts (static or interactive dashboards) | Swift Charts: `Chart` with `LineMark`, `BarMark`, `AreaMark`, `PointMark`, `RuleMark`, and `.chartXSelection(value:)` for scrubbing |

The split carries over: live points on a scrolling time axis need the window and append logic around the chart; everything else is a plain `Chart`.

### Interaction & performance

| Task | First-party answer |
| --- | --- |
| Drag and drop | `.draggable(_:)` and `.dropDestination(for:action:isTargeted:)` with `Transferable` types; inside a `List`, `.onMove` for reordering |
| Virtualization (long lists, large tables) | `List` (lazy, with cell reuse), or `LazyVStack` / `LazyVGrid` in a `ScrollView`; `Table` for multi-column data on iPad |

### State & styling

| Task | First-party answer |
| --- | --- |
| State management | `@Observable` models (Observation framework), passed with `.environment(model)` and read with `@Environment(Model.self)`; `@State` for view-local state; `@Bindable` for bindings into an observable model |
| Constructing `className` strings conditionally | No equivalent; see the flag table |
| Type-safe, variant-driven styling | No equivalent; see the flag table |
| Theme switching / dark mode (no flash on load) | No equivalent needed; see the flag table |

A few of these together, as a reference:

```swift
import Charts

@Observable @MainActor
final class StatsModel {
    var total = 1_284
    var points: [Sample] = (0..<30).map { Sample(index: $0, value: Double($0 % 7) * 3) }

    struct Sample: Identifiable {
        let index: Int
        let value: Double
        var id: Int { index }
    }
}

struct StatsScreen: View {
    @State private var model = StatsModel()
    @State private var showsFilters = false
    @State private var code = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            // Animated number: digits roll instead of the whole label swapping.
            Text(model.total, format: .number)
                .font(.largeTitle.weight(.semibold))
                .monospacedDigit()
                .contentTransition(reduceMotion ? .identity : .numericText(value: Double(model.total)))

            Button("Add member") {
                withAnimation(.snappy) { model.total += 1 }
            }
            .buttonStyle(.pressable)

            // Live chart: append points, keep a moving 20-point window.
            Chart(model.points) { point in
                LineMark(x: .value("Time", point.index), y: .value("Value", point.value))
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 20)
            .frame(height: 200)
            .accessibilityLabel("Activity over time")

            // Verification code: system code suggestion; no segmented boxes.
            TextField("Verification code", text: $code)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)

            // Drag and drop between views with a Transferable type (String).
            Text("Drag me")
                .padding()
                .background(.fill.secondary, in: .rect(cornerRadius: 8))
                .draggable("Drag me")
        }
        .padding()
        .toolbar {
            Button("Filters", systemImage: "line.3.horizontal.decrease") { showsFilters = true }
        }
        // Drawer: a system sheet with detents. Don't retime its motion.
        .sheet(isPresented: $showsFilters) {
            Text("Filters")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }
}

struct DropZone: View {
    @State private var received: [String] = []
    @State private var isTargeted = false

    var body: some View {
        List(received, id: \.self) { Text($0) }
            .overlay { if received.isEmpty { ContentUnavailableView("Drop here", systemImage: "tray") } }
            .background(isTargeted ? Color.accentColor.opacity(0.1) : .clear)
            .dropDestination(for: String.self) { items, _ in
                received.append(contentsOf: items)
                return true
            } isTargeted: { isTargeted = $0 }
    }
}
```

## Common mismatches to catch

- **A toast built as a full-screen modal or an `.alert` for non-blocking news** → no first-party toast exists, so build a small custom overlay with the house rules (enter with `.emilEaseOut()`, a `.move(edge:)` + `.opacity` transition, Reduce Motion handled, announced with `AccessibilityNotification.Announcement`), or pick a package yourself; it's not an Emil pick. Never use `.alert` for something that doesn't need a decision.
- **A hand-rolled dropdown or dialog (a `ZStack` overlay with manual dismissal and focus)** → `Menu`, `Picker`, `.popover`, `.confirmationDialog`, or `.sheet`, which handle VoiceOver focus, dismissal, and system motion.
- **Animating a number by swapping the whole `Text`** → `.contentTransition(.numericText(value:))` with `.monospacedDigit()`.
- **Rendering 1,000+ rows in a `VStack` inside a `ScrollView`** → `List` or `LazyVStack` before reaching for pagination.
- **A web of `@Binding`s threaded through five views for shared state** → one `@Observable` model in the environment.
- **Long chains of conditional modifiers or `if` branches that rebuild a view to restyle it** → put the condition in the modifier's value (`.opacity(isOn ? 1 : 0.5)`), which keeps the view's identity; for a component with real variants (size, intent), a custom `ButtonStyle` with an enum.

## No native equivalent

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
