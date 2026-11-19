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

struct ProbeView: View {
    @State private var values = Array(repeating: 0.0, count: scenarios.count)

    var body: some View {
        VStack(spacing: 40) {
            ForEach(scenarios.indices, id: \.self) { i in
                Circle().frame(width: 40, height: 40)
                    .modifier(Trace(x: values[i], scenario: scenarios[i].name))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1))  // let launch settle
            for (i, s) in scenarios.enumerated() {
                Trace.start = CACurrentMediaTime()
                print("PROBE \(s.name) mark go-100")
                withAnimation(s.animation) { values[i] = 100 }
                try? await Task.sleep(for: .milliseconds(100))
                print("PROBE \(s.name) mark reverse-0 at \(Int((CACurrentMediaTime() - Trace.start) * 1000))")
                withAnimation(s.animation) { values[i] = 0 }
                try? await Task.sleep(for: .seconds(1.5))
            }
            print("PROBE done")
            exit(0)
        }
    }
}
