# Emil Kowalski's Skills, for SwiftUI

[Emil Kowalski](https://emilkowal.ski)'s skills for designers and engineers, adapted for native iOS apps. The design judgment is his, unchanged. Only the implementation is new: SwiftUI in place of CSS, Motion and React.

This is an unofficial adaptation of [emilkowalski/skills](https://github.com/emilkowalski/skills). Emil did not write, review or endorse it.

## Credit

These skills are Emil's work. He wrote them from his years of building interfaces at companies like Vercel and Linear, and they hold the small decisions that make an interface feel right: which curve, how fast, where the motion starts, and when to leave it out. Agents tend to get those decisions wrong, which he explains in [Agents with Taste](https://emilkowal.ski/ui/agents-with-taste).

If these help you, go to the source:

- Read the originals, with examples and prompts to try, at [aiforui.dev/skills](https://aiforui.dev/skills).
- [Sign up to his newsletter](https://aiforui.dev/newsletter) for new skills.
- For anything that runs in a browser, use his web skills: `npx skills@latest add emilkowalski/skills`.

I'm [Oren Segal](https://github.com/OrenSegal), and I ported them to SwiftUI from upstream commit [`64eb3de`](https://github.com/emilkowalski/skills/tree/64eb3deb9a5fbfa041faf783e0bc3fd635872e9c). Every place this port departs from his rules is listed in [CONVERSION.md](CONVERSION.md) and [FLAGGED.md](FLAGGED.md). Any mistake in the SwiftUI is mine, not his, so please report it [here](https://github.com/OrenSegal/emil-design-swiftui/issues) rather than on his repo.

## What it is

Every rule keeps Emil's reasoning and his original values. The web implementation has been replaced with native SwiftUI. Rules that only exist because of the browser are not translated. They are listed in [FLAGGED.md](FLAGGED.md) and at the end of each skill, so you can see what was left out and why.

Target: iOS 18 and Swift 6. APIs newer than iOS 18, like Liquid Glass, only appear behind `#available` with a fallback.

## Install

```bash
npx skills@latest add OrenSegal/emil-design-swiftui
```

Or copy the folders in `skills/` into `~/.claude/skills/` (or a project's `.claude/skills/`). Then copy [`tools/Motion.swift`](tools/Motion.swift) into your app target. The skills use its curves, springs and press style by name.

The skill names match Emil's originals, so cross-references keep working. If you already have the web versions installed, install these into a project folder instead, or remove the web ones first.

## What changed from the web version

- **Kept as is:** every rule about frequency, purpose, easing, duration, origin, interruption, asymmetry and restraint, with Emil's original values.
- **One new rule:** leave system motion alone. Sheets, navigation pushes, menus and popovers already move the way iOS users expect, and they already respect Reduce Motion. Emil's curves are for the components you build.
- **Reframed:** some rules hold but for a different reason natively. For example, an interrupted spring hands its velocity to the new target, so springs play the role CSS transitions play on the web. A timing curve keeps running and stacks with the new one, which is why curves are the wrong choice for anything the user can reverse. [CONVERSION.md](CONVERSION.md) lists every mapping.
- **Not ported:** `animate-expo` (React Native) and `ask-sonner` (a React library). The ideas from them that apply natively live in `animate`, `gestures` and `emil-design-eng`.
- **Unchanged:** `write-swift` was already native.

## Checking the code

Two checks run on every push (`.github/workflows/check.yml`). The first checks structure: front matter the installer needs, every upstream skill accounted for, and links and cross-references that resolve:

```bash
tools/validate.sh
```

The second typechecks every Swift snippet in the ported skills against the iOS 18 SDK in Swift 6 mode, debug code included:

```bash
tools/check-snippets.sh $(ls skills/*/*.md | grep -v /write-swift/) *.md
```

Run it outside any sandbox, since the Swift macro plugin server needs its own. Three blocks in `write-swift` fail on purpose. That skill is Emil's original, unchanged. Its examples are fragments that call made-up helpers.

## Reference

- **[emil-design-eng](skills/emil-design-eng/SKILL.md)**: the core skill. Mostly animation, plus component polish.
- **[animate](skills/animate/SKILL.md)**: builds one animation, choosing curve, duration, properties and exit.
- **[review-animations](skills/review-animations/SKILL.md)**: a strict review of the motion in a diff.
- **[improve-animations](skills/improve-animations/SKILL.md)**: audits every animation in an app and writes plans another agent can run.
- **[find-animation-opportunities](skills/find-animation-opportunities/SKILL.md)**: finds where motion would help, and says where it wouldn't.
- **[remove-animations](skills/remove-animations/SKILL.md)**: removes the motion an app doesn't need.
- **[choreograph](skills/choreograph/SKILL.md)**: coordinates several views moving together.
- **[animation-performance](skills/animation-performance/SKILL.md)**: fixes dropped frames, written for the SwiftUI render pipeline.
- **[animation-vocabulary](skills/animation-vocabulary/SKILL.md)**: names a motion effect and the SwiftUI API that makes it.
- **[apple-design](skills/apple-design/SKILL.md)**: Apple's fluid-interface principles, back on their home platform.
- **[gestures](skills/gestures/SKILL.md)**: drags, swipes and sheets that track the finger and carry the release velocity.
- **[pick-ui-library](skills/pick-ui-library/SKILL.md)**: the first-party component for each task. It names no third-party packages.
- **[prototype](skills/prototype/SKILL.md)**: several versions of a view behind a switcher.
- **[mobile-native](skills/mobile-native/SKILL.md)**: mostly flagged, since a native app has none of the web-on-a-phone problems. The few rules that carry over are kept.
- **[break-ui](skills/break-ui/SKILL.md)**: worst-case data, plus Dynamic Type, right-to-left and accessibility settings.
- **[learn-taste](skills/learn-taste/SKILL.md)**: turns a session's design corrections into rules.
- **[ask-emil](skills/ask-emil/SKILL.md)**: points you to the right skill.
- **[write-swift](skills/write-swift/SKILL.md)**: modern Swift and Swift 6 concurrency.

## License

MIT, as in the original. See [LICENSE](LICENSE).
