---
name: ask-emil
description: Ask which skill or flow fits your SwiftUI situation. A router over the skills in this repo.
disable-model-invocation: true
---

# Ask Emil (SwiftUI)

> Adapted from Emil Kowalski's [`ask-emil`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c/skills/ask-emil) skill. The design judgment is his. The SwiftUI is this port's, so report problems with it to [emil-design-swiftui](https://github.com/OrenSegal/emil-design-swiftui/issues), not to Emil.

Before stating what a skill does or recommending one, read that skill's SKILL.md: the summaries here are for orientation only. Then recommend **one** skill (or one short sequence) for the user's situation, say why in a sentence, and name the skill they'd reach for next. Don't list the whole map back at them.

A **flow** is a path through the skills. Most UI work travels one **main flow**, from idea to shipped. Some skills are **upkeep** you run on a codebase that already exists, some are **references** that sit underneath everything, and a few stand alone.

## The main flow: idea → ship

1. **Not sure what it should look or feel like?** Detour through **`/prototype`**. It builds several genuinely different versions behind a live switcher, then promotes the one you pick into the real code. Reach for it whenever a design question is hard to settle in words.

2. **Build it.** Pick the builder by what's moving:
   - **`/pick-ui-library`** first if the task needs a component (menu, dialog, sheet, picker, chart, drag and drop, long list). It points to the first-party SwiftUI component. Don't let the agent hand-roll what the system ships.
   - **`/animate`** for one animation: whether to animate at all, then tool, properties, curve, duration, interruption, exit.
   - **`/choreograph`** when several views move together: staggers, entrances, view swaps, a row leaving while its siblings close the gap.
   - **`/gestures`** when the user's finger drives it: drag, swipe, sheets, detents, swipe-to-dismiss.

3. **Try to break it.** Before calling it done:
   - **`/break-ui`** feeds it worst-case data (long names, empty lists, huge counts, emoji, non-Latin text) plus the largest Dynamic Type sizes and right-to-left layout, and reports what broke.
   - **`/review-animations`** reviews the motion in the diff against a strict bar. Default to flagging; approval is earned.
   - **`/animation-performance`** if anything hitches or drops frames.
   - Test on a real device. The Simulator has no haptics, no real touch, and no ProMotion.

4. **Learn from the session.** **`/learn-taste`** closes the loop. Run it at the end, in the same session, before you clear: it collects every design correction you made (including edits you made yourself) and turns each into a rule with its why, so the next agent doesn't repeat the mistake.

## Upkeep: a codebase that already exists

Not feature work. Run these when you have a spare moment, or when the app "feels off".

- **The motion needs work across the app** → **`/improve-animations`**. Read-only: it audits every animation and writes prioritized, self-contained plans another agent (or a cheaper model) can execute.
- **It feels static** → **`/find-animation-opportunities`**. Read-only: it proposes motion with exact values, and rejects everything that shouldn't move. Build the ones you accept with `/animate`.
- **It feels slow or over-animated** → **`/remove-animations`**. Edits code, but only to subtract: motion on keyboard actions, high-frequency surfaces, decoration with no purpose.

These three cover different questions. If the user isn't sure which, ask whether the problem is *bad* motion, *missing* motion, or *too much* motion.

## References underneath

Model-invoked skills the others lean on. Reach for them directly when the **knowledge**, not a process, is what's missing.

- **`/emil-design-eng`**: the core philosophy for UI polish, component interactions, and the invisible details. The fallback when no narrower skill fits.
- **`/apple-design`**: Apple's principles for interface design and fluid, physical motion, in SwiftUI terms.
- **`/animation-vocabulary`**: when the problem is the **word**. "What's it called when…" turns a vague description into the exact term, and the SwiftUI API that produces it.
- **`/write-swift`**: modern Swift, Swift 6 concurrency, performance, and testing. Reach for it when the problem is the Swift rather than the design.

## Mostly flagged

- **`/mobile-native`**: the web original fixes web apps on phones. Natively, most of it doesn't apply; the skill keeps the few rules that do (safe areas, keyboard, paging, real-device testing).

## Not ported

- **`animate-expo`** (React Native) and **`ask-sonner`** (a React toast library). Use `/animate` and `/gestures` for native motion; the Sonner principles are in `/emil-design-eng`.

## Common situations

| You say | Reach for |
| --- | --- |
| "Animate this" | `/animate` |
| "These should come in one after another" | `/choreograph` |
| "It doesn't follow my finger" | `/gestures` |
| "It stutters" / "it hitches" | `/animation-performance` |
| "Does this animation feel right?" | `/review-animations` |
| "Make the app feel better" | `/improve-animations` |
| "What could animate here?" | `/find-animation-opportunities` |
| "Too much is moving" | `/remove-animations` |
| "Give me a few options" | `/prototype` |
| "Which component should I use?" | `/pick-ui-library` |
| "Try the worst case" | `/break-ui` |
| "What's that bouncy thing called?" | `/animation-vocabulary` |
| "This Swift won't compile / data race" | `/write-swift` |
| "Stop making that mistake" | `/learn-taste` |

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| `/mobile-native` as a main-flow step ("if it runs on a phone as a web app") | A native app isn't a web app on a phone | Real-device testing, kept in step 3 |
| `/animate-expo`, `/ask-sonner` routes | React Native and React libraries | `/animate`, `/gestures`, `/emil-design-eng` |
