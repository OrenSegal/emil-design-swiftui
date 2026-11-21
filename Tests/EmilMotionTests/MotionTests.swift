import SwiftUI
import Testing
@testable import EmilMotion

@Suite struct MotionTests {
    @Test func curvesMatchTheWebValues() {
        #expect(Animation.emilEaseOut(0.2) == .timingCurve(0.23, 1, 0.32, 1, duration: 0.2))
        #expect(Animation.emilEaseInOut() == .timingCurve(0.77, 0, 0.175, 1, duration: 0.3))
        #expect(Animation.emilDrawer() == .timingCurve(0.32, 0.72, 0, 1, duration: 0.5))
        #expect(Animation.emilEase() == .timingCurve(0.25, 0.1, 0.25, 1, duration: 0.2))
        #expect(Animation.emilPress == .timingCurve(0.23, 1, 0.32, 1, duration: 0.16))
    }

    @Test func springsAreDampedAsDocumented() {
        #expect(Spring.emilUI == Spring(response: 0.4, dampingRatio: 1.0))
        #expect(Spring.emilMomentum == Spring(response: 0.35, dampingRatio: 0.8))
    }

    @Test func projectionMatchesAppleFormula() {
        #expect(project(velocity: 0) == 0)
        // 1000 pt/s at 0.998: 1 * 0.998 / 0.002 = 499 pt
        #expect(abs(project(velocity: 1000) - 499) < 0.001)
        #expect(project(velocity: -1000) == -project(velocity: 1000))
    }

    @Test func rubberbandIsMonotonicAndBounded() {
        #expect(rubberband(0, dimension: 400) == 0)
        let a = rubberband(50, dimension: 400), b = rubberband(500, dimension: 400)
        #expect(a > 0 && b > a)
        #expect(b < 400) // never exceeds dimension
        #expect(rubberband(-50, dimension: 400) == -a)
    }

    @Test func pressStyleDefaults() {
        #expect(PressableButtonStyle().scale == 0.97)
    }
}
