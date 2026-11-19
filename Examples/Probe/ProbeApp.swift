// Runtime probe for claims the skills could only make from documentation.
// It drives state changes from code (no taps needed) and logs every interpolated frame
// through an Animatable modifier, the one place SwiftUI hands out in-flight values.
// Run: tools/probe.sh. Output lines: PROBE <scenario> <ms since start> <value>
import SwiftUI
import QuartzCore

@main
struct ProbeApp: App {
    var body: some Scene { WindowGroup { ProbeView() } }
}

/// Logs each value SwiftUI interpolates. The setter runs once per rendered frame.
struct Trace: ViewModifier, @MainActor Animatable {
    var x: Double
    let scenario: String
    static var start = CACurrentMediaTime()

    var animatableData: Double {
        get { x }
        set {
            x = newValue
            let ms = (CACurrentMediaTime() - Trace.start) * 1000
            print("PROBE \(scenario) \(Int(ms)) \(String(format: "%.2f", newValue))")
        }
    }
    func body(content: Content) -> some View { content.offset(x: x) }
}

struct Scenario {
    let name: String
    let animation: Animation
}

// Each scenario animates 0 -> 100, then reverses to 0 after 100 ms, mid-flight.
let scenarios: [Scenario] = [
    .init(name: "spring-emilUI", animation: .spring(.emilUI)),
    .init(name: "curve-emilEaseOut-0.3", animation: .emilEaseOut(0.3)),
    .init(name: "curve-emilEaseInOut-0.3", animation: .emilEaseInOut(0.3)),
]

func log(_ scenario: String, _ text: String) {
    print("PROBE \(scenario) mark \(text) at \(Int((CACurrentMediaTime() - Trace.start) * 1000))")
}

func slide(_ scenario: String, from x: Double) -> AnyTransition {
    .modifier(active: Trace(x: x, scenario: scenario), identity: Trace(x: 0, scenario: scenario))
}

struct ProbeView: View {
    @State private var values = Array(repeating: 0.0, count: scenarios.count)
    // Removal that interrupts an insertion.
    @State private var shown = false
    // Step flow whose direction flips in the same update as the step change.
    @State private var step = 0
    @State private var forward = true
    @State private var run = "same-update"
    // Keyframe pulse, re-triggered mid-track.
    @State private var pulse = 0

    var body: some View {
        VStack(spacing: 40) {
            ForEach(scenarios.indices, id: \.self) { i in
                Circle().frame(width: 40, height: 40)
                    .modifier(Trace(x: values[i], scenario: scenarios[i].name))
            }
            ZStack {
                if shown {
                    Circle().frame(width: 40, height: 40)
                        .transition(slide("transition-insert-then-remove", from: -100))
                }
            }
            ZStack {
                Circle().frame(width: 40, height: 40).id(step)
                    .transition(.asymmetric(
                        insertion: slide("\(run)-step\(step)-in", from: forward ? 100 : -100),
                        removal: slide("\(run)-step\(step)-out", from: forward ? -100 : 100)))
            }
            Circle().frame(width: 40, height: 40)
                .keyframeAnimator(initialValue: 0.0, trigger: pulse) { content, x in
                    let ms = Int((CACurrentMediaTime() - Trace.start) * 1000)
                    print("PROBE keyframe-retrigger \(ms) \(String(format: "%.2f", x))")
                    return content.offset(x: x)
                } keyframes: { _ in
                    KeyframeTrack {
                        SpringKeyframe(100, duration: 0.3, spring: .emilUI)
                        SpringKeyframe(0, duration: 0.3, spring: .emilUI)
                    }
                }
        }
        .task {
            try? await Task.sleep(for: .seconds(1))  // let launch settle
            for (i, s) in scenarios.enumerated() {
                Trace.start = CACurrentMediaTime()
                log(s.name, "go-100")
                withAnimation(s.animation) { values[i] = 100 }
                try? await Task.sleep(for: .milliseconds(100))
                log(s.name, "reverse-0")
                withAnimation(s.animation) { values[i] = 0 }
                try? await Task.sleep(for: .seconds(1.5))
            }

            // Insert from -100, then remove 100 ms in: does the removal start from where the view is?
            Trace.start = CACurrentMediaTime()
            log("transition-insert-then-remove", "insert")
            withAnimation(.spring(.emilUI)) { shown = true }
            try? await Task.sleep(for: .milliseconds(100))
            log("transition-insert-then-remove", "remove")
            withAnimation(.spring(.emilUI)) { shown = false }
            try? await Task.sleep(for: .seconds(1.5))

            // Forward to step 1, then Back. Back flips `forward` and the step in one update.
            // Correct: step1-out moves toward +100 (the new, backward direction). Wrong: toward -100.
            Trace.start = CACurrentMediaTime()
            log("step", "forward-to-1")
            withAnimation(.spring(.emilUI)) { forward = true; step = 1 }
            try? await Task.sleep(for: .seconds(1.5))
            Trace.start = CACurrentMediaTime()
            log("step", "back-to-0-same-update")
            withAnimation(.spring(.emilUI)) { forward = false; step = 0 }
            try? await Task.sleep(for: .seconds(1.5))

            // The fix the choreograph recipe suggests: render the new direction first, change the step next.
            run = "fixed"
            withAnimation(.spring(.emilUI)) { forward = true; step = 1 }
            try? await Task.sleep(for: .seconds(1.5))
            Trace.start = CACurrentMediaTime()
            log("step", "back-to-0-direction-first")
            forward = false
            try? await Task.sleep(for: .milliseconds(20))  // one frame, so the leaving view renders the new direction
            withAnimation(.spring(.emilUI)) { step = 0 }
            try? await Task.sleep(for: .seconds(1.5))

            // Same fix with only a Task hop and no sleep, as the recipe writes it.
            run = "task-hop"
            withAnimation(.spring(.emilUI)) { forward = true; step = 1 }
            try? await Task.sleep(for: .seconds(1.5))
            Trace.start = CACurrentMediaTime()
            log("step", "back-to-0-task-hop")
            forward = false
            Task { @MainActor in withAnimation(.spring(.emilUI)) { step = 0 } }
            try? await Task.sleep(for: .seconds(1.5))

            // Keyframe pulse re-triggered 150 ms in: does it restart from the on-screen value or jump?
            Trace.start = CACurrentMediaTime()
            log("keyframe-retrigger", "trigger")
            pulse += 1
            try? await Task.sleep(for: .milliseconds(150))
            log("keyframe-retrigger", "retrigger")
            pulse += 1
            try? await Task.sleep(for: .seconds(1.2))

            print("PROBE done")
            exit(0)
        }
    }
}
