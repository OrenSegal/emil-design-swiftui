# Performance Cheatsheet

| Problem                             | Solution                                                  |
| ----------------------------------- | --------------------------------------------------------- |
| Animation stutters                  | Animate `offset`/`scaleEffect`/`opacity`, not `frame`/`padding` |
| Long list scrolls slowly            | `List` or `LazyVStack` with stable `id`s and cheap rows (already virtualized) |
| Blur causes perf issues             | Keep animated `blur(radius:)` small and on small views; measure (the web's 20px is a Safari number) |
| Motion's `x`/`y` drops frames       | n/a natively — Motion-library version issue; nearest native cause: a busy main thread during the animation |
| Random properties animate           | No broad `withAnimation` / high `.animation`; scope with `.animation(_:value:)` or `.animation(_:body:)` |
| React re-renders every frame        | Per-frame state (drag, scroll, timer) local to the moving view: `@GestureState`, `TimelineView` |
| Element shifts 1px as motion starts | n/a natively — no `will-change` layer hand-off; if children tear during a resize, `geometryGroup()` |
| Custom animations capped at 60Hz on iPhone | Add `CADisableMinimumFrameDurationOnPhone` (Boolean, YES) to Info.plist; confirm on a ProMotion device (added for SwiftUI) |
| Hitches only while loading          | Decode/parse off the main actor; measure with Instruments ▸ Animation Hitches (added for SwiftUI) |
