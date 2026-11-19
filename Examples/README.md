# Probe

A tiny app that checks, at runtime, claims the skills first made from Apple's documentation. It changes state from code, so it needs no taps, and it logs every frame SwiftUI interpolates through an `Animatable` modifier.

```bash
tools/probe.sh
```

It needs Xcode and xcodegen, and must run outside any sandbox. It creates its own simulator called `emil-probe`.

## Results (iOS 26.5 simulator, 2026-11-18)

Each view animates from 0 to 100, and 100 ms later is sent back to 0. Full log: [probe-ios26.5.log](probe-ios26.5.log).

| Animation | Value when reversed | What happened next |
| --- | --- | --- |
| `.spring(.emilUI)` | 46 | Kept its velocity for one frame (peak 52), then eased smoothly back to 0. |
| `.emilEaseOut(0.3)` | 72 | Turned back at once. The first curve was almost spent, so stacking barely shows. |
| `.emilEaseInOut(0.3)` | 4 | Kept heading for the old target and peaked at **68** before coming back. |

This confirms the reframed rule in [CONVERSION.md](../CONVERSION.md): an interrupted spring hands its velocity to the new target, while a timing curve keeps running and stacks with the new one. So anything the user can reverse mid-flight should use a spring.

## Still needs a real device

These involve touch, so the probe can't drive them (taps also don't reach apps in the Xcode 27 Simulator):

- Grabbing a view mid-release (`gestures`, *Interruptibility*).
- Whether a negative-inset `contentShape` registers hits outside the view's frame (`gestures`, hit targets).
- How a horizontal swipe inside a `ScrollView` feels (`gestures`, option 2).
