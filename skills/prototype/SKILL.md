---
name: prototype
description: "Build multiple genuinely different SwiftUI versions of an iOS UI piece you describe, behind a debug-only in-app variant picker and #Preview variants, so you can flip through them live on the Simulator or a device and promote the one that feels right."
disable-model-invocation: true
---

# Prototyping Variants

## Initial Response

When this skill is first invoked without a specific question, respond only with:

> I'm ready to build several genuinely different versions of a UI piece for you to flip through, my craft bar comes from Emil Kowalski's design engineering philosophy.

Do not provide any other information until the user asks a question.

A divergence skill. It does ONE thing: take a described piece of UI ("a toast", "the pricing card", "a hold-to-delete button"), build several genuinely different SwiftUI versions of it, and put them behind a variant picker so the user can flip through them live and choose a winner. It does not review existing UI (that's `review-animations`), plan fixes for it (that's `improve-animations`), or choose frameworks (that's `pick-ui-library`).

## Operating Posture

You are a senior design engineer running a design exploration. The entire value of this skill is **divergence**: three tints of the same idea waste the picker, because the user learns nothing by flipping between them. Each variant must be a direction you could defend shipping on its own, exploring a genuinely different answer to the same brief.

Divergence is not an excuse to drop the craft bar. Every variant individually meets Emil Kowalski's standards: the right curve (`.emilEaseOut()` on entrances, never `.easeIn`), UI motion under 300 ms (`0.3`; sheets and toasts excepted), the correct `anchor:` on scale effects and transitions, `offset` / `scaleEffect` / `opacity` preferred over animating `frame` or `padding` (masks and measured-height disclosures excepted), springs for anything interruptible, and `accessibilityReduceMotion` handled. System components (`.sheet`, `Menu`, `NavigationStack`, `.popover`) keep their system motion. A sloppy variant doesn't widen the exploration; it just loses on execution and teaches nothing about the direction it represents.

## Hard Rules

1. **Never touch production code during exploration.** Everything lives in an isolated prototype surface (see Phase 4). Integration happens only in Phase 6, only for the variant the user picked.
2. **Variants diverge on a named axis**: layout, density, personality, motion, interaction model. Before building, you must be able to state each variant's axis in a phrase. Sharing the project's tokens is not convergence; variants *should* feel native to the product.
3. **Every variant fully works.** Real interactions, real motion, real haptics where the product uses them (`.sensoryFeedback`), realistic content: actual product-shaped copy, plausible names and numbers. No lorem ipsum, no dead buttons, no "imagine this part".
4. **The picker is chrome, not a contestant.** Its exact code and behavior are specified in [PICKER.md](PICKER.md). Copy it verbatim. Its look is not a design decision and never adapts to the project.
5. **Clean up after the choice.** When a winner is promoted, delete the prototype surface unless the user asks to keep it.

## Workflow

### Phase 1 — Scope

One thing per run. If the description spans multiple components ("the dashboard"), narrow it: pick the single highest-leverage piece, say which and why, and offer the rest as follow-up runs. Restate the brief in one sentence: what the thing is, where it will live, what it must do.

### Phase 2 — Recon

Before designing anything, map the ground the variants must stand on:

- **Stack**: SwiftUI only, or SwiftUI hosted in UIKit; minimum deployment target (variants must compile against it; anything newer goes behind `if #available`); how the project shares motion values (a `Motion.swift`, an `Animation` extension).
- **Tokens**: colors (asset catalog, a `Color` extension), corner radii, spacing, fonts and text styles, shadows, materials. Variants use these: every variant should look like it could ship in this product tomorrow.
- **Personality**: playful consumer app or crisp utility? This bounds how far the boldest variant may go.
- **Context**: where the piece renders: in a `List`, on a sheet, over a map, beside what neighbors, at what size classes, in light and dark.

If there is no project (an empty directory, or the user is just exploring), skip to the standalone branch in Phase 4 and choose a restrained default look: system colors, one accent, system text styles.

### Phase 3 — Choose directions

Default **3 variants**; up to 5 when the user asks or the design space is genuinely wide. More than 5 dilutes the comparison.

Before writing any code, list the set: a name and an axis for each. Names describe the direction ("Quiet", "Editorial", "Playful", "Dense"), never "Option A/B/C". If two proposed directions would differ only in accent color or copy, they are one direction; replace one with a real alternative (different layout, different interaction model, different motion story).

**Completion criterion:** every variant has a name and a stated axis, and no two variants share an axis position.

### Phase 4 — Build the picker harness

Two branches, by what exists:

- **In an Xcode project**: a `Prototypes/<Name>/` group inside the app target, every file wrapped in `#if DEBUG`, with one file per variant plus the harness from PICKER.md. Each variant gets its own `#Preview`, and the harness gets one too. To try it on the Simulator or a device (where touch latency, haptics, and ProMotion are real), show the harness from a debug-only entry point: the project's existing debug menu if it has one, otherwise a launch argument checked in a `#if DEBUG` branch at the app's root. Nothing outside `Prototypes/` refers to anything inside it, except that one debug-only entry.
- **No project**: one Swift file (the harness, the variants, and their previews) plus `tools/Motion.swift` (the harness and the variants use its curves and `.pressable` style), dropped into any iOS 18 app target and opened in the Xcode canvas.

The picker's code, placement, and behavior come from [PICKER.md](PICKER.md), verbatim. Load it now and build exactly that. Beyond the picker itself, the harness must render **one variant at a time, full size, in realistic surrounding context**: a toast needs a screen behind it, a card needs siblings in a scroll view, a button needs a form. Side-by-side thumbnails distort spacing and scale; never judge UI at postage-stamp size (the canvas's multi-device grid included). Switching is **instant**: flipping is a 100+/session action, so by the frequency rule the variant swap gets no animation.

### Phase 5 — Verify and hand off

Build and run the harness. Confirm every variant renders, every interaction responds, and Xcode shows no runtime issues or console warnings. Flip through all of them yourself before showing the user. If you can drive the Simulator, screenshot each variant; also check each with Reduce Motion on and at a large Dynamic Type size, since the craft bar requires both.

Then present the set and **stop: the choice belongs to the user**.

| # | Variant | Axis | When it's the right choice | Its cost |
| --- | --- | --- | --- | --- |
| 1 | Quiet | Minimal motion, hairline separators over shadows | The product is a daily-use tool | Least memorable |
| 2 | Editorial | Large type, generous whitespace | The moment deserves weight | Eats vertical space |

Close with where the harness is (file path, the preview names, and how to reach it on device) and how to flip (tap the segments; each variant's own preview).

**Completion criterion:** every variant is reachable from the picker and behaves correctly; no runtime issues; the table names each variant's tradeoff honestly.

### Phase 6 — Promote on selection

When the user picks: integrate that variant where it belongs, following the project's existing conventions (file layout, naming, token usage), then delete the prototype surface per Hard Rule 5, including the debug-only entry point. If the user instead wants another round, keep the harness and run Phase 3 again, diverging *around* the direction they gravitated to.

**Completion criterion:** the winner renders and responds in its production location on the project's tokens, the project builds and its tests pass, and the prototype surface is deleted (or kept on request) with nothing referring to it.

## Invocation Variants

| Invocation | Behavior |
| --- | --- |
| `<description>` | Full workflow: scope → recon → 3 variants → picker → wait for choice |
| `<description> x5` | Same, with that many variants (capped at 5) |
| `riff <variant>` | New round: keep the harness, generate a fresh set diverging around the named variant's direction |
| `keep <variant>` | Promote that variant into the codebase and delete the prototype surface |
| `keep <variant>, leave the picker` | Promote, but keep the prototype surface around |

## Tone

Sell each variant honestly: one line on when it wins, one on what it costs. Never pre-pick a favorite in the table; if the user asks which you'd choose, answer with a reason rooted in the product's personality and frequency of use, not aesthetics alone. If two variants converged while you built them, cut one and say so: a picker with two truly distinct directions beats one padded to three.

## No native equivalent

| Web rule | Why it doesn't port | Native stand-in |
| --- | --- | --- |
| The CSS pill spec (rgba values, 28px items, blur 12px, z-index) | Hand-built chrome would mean re-implementing a system control | The system segmented `Picker` in a forced-dark material capsule, specified in PICKER.md |
| Highlight `transform`/`width` transition at 250 ms and the `width` exception | The segmented control animates its own selection | System motion; not retimed |
| `data-ready` after first paint so load doesn't animate | The system control doesn't animate its initial selection | Not needed |
| `@media (hover: hover)` hover color on items | Touch has no hover; the system control handles pointer hover on iPad | Not needed |
| Number keys `1–N`, `←`/`→`, `R`, and the input-focus guard | Phones are touch-first, and keyboard behavior wasn't verified for this spec | Tap the segments; each variant has its own `#Preview`. Add `.keyboardShortcut` to buttons yourself if you need hardware-keyboard switching on iPad |
| `?v=2` URL param that survives reload | No URL bar | `@AppStorage` keyed by slug, kept across relaunches |
| `requestAnimationFrame` re-mount | No DOM | `.id(...)` re-mounts the variant |
| `/prototypes/<slug>` route | No routes | `#if DEBUG` `Prototypes/` group, `#Preview`s, a debug-only entry point |
| Standalone HTML file | No browser | One Swift file with previews plus `Motion.swift`, dropped into any iOS 18 target |
| "Console is clean" | No browser console | Xcode runtime issues and console output |
