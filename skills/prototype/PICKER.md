# The Picker

The picker's appearance is **not a design decision**: it is this spec. Copy the harness below verbatim; the only values that change per run are the slug, the variant names and count, the edge, and whether replay is on. It stays identical across every project so it always reads as harness chrome, never as part of the design being judged. Do not restyle it with the project's tokens, fonts, accent color, or button styles.

It is the system segmented control in a dark material capsule, floating over the bottom center of the screen. The capsule is forced dark (`.environment(\.colorScheme, .dark)`) because dark glass reads on top of any screen, light or dark, which is why it is not theme-aware. It is the system control on purpose: its selection highlight already slides with system motion, its selected segment is already announced to VoiceOver, and it already handles Dynamic Type and Increase Contrast. Don't retime or replace that motion (house rule: don't fight the system).

## The harness

One file, `PrototypeHarness.swift`, inside the prototype surface:

```swift
#if DEBUG
import SwiftUI

/// Prototype harness chrome. Identical in every project: never restyle it.
struct PrototypeHarness<Content: View>: View {
    let variants: [String]
    let edge: VerticalEdge
    let hasReplay: Bool
    @ViewBuilder let content: (Int) -> Content

    @AppStorage private var selection: Int
    @State private var replayCount = 0

    /// - slug: names the stored selection, so each prototype remembers its own.
    /// - edge: `.top` only when a variant owns the bottom of the screen (toasts, sheets, a dock).
    /// - hasReplay: only when at least one variant has an entrance or state animation to re-run.
    init(slug: String, variants: [String], edge: VerticalEdge = .bottom, hasReplay: Bool = false,
         @ViewBuilder content: @escaping (Int) -> Content) {
        self.variants = variants
        self.edge = edge
        self.hasReplay = hasReplay
        self.content = content
        _selection = AppStorage(wrappedValue: 0, "prototype.\(slug).variant")
    }

    private var current: Int { variants.indices.contains(selection) ? selection : 0 }

    var body: some View {
        content(current)
            // Switching or replaying re-mounts the variant, so its entrance runs again.
            // The swap itself is not animated: flipping is a 100+/session action.
            .id("\(current)-\(replayCount)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: edge == .top ? .top : .bottom) { picker }
            .onAppear { if !variants.indices.contains(selection) { selection = 0 } }
    }

    private var picker: some View {
        HStack(spacing: 4) {
            Picker("Prototype variants", selection: $selection) {
                ForEach(variants.indices, id: \.self) { index in
                    Text(variants[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()

            if hasReplay {
                Divider().frame(height: 16)
                Button { replayCount += 1 } label: {
                    // Frame and shape inside the label: the style's label is the hit area.
                    Label("Replay animation", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(.ultraThinMaterial, in: .capsule)
        .overlay { Capsule().strokeBorder(.white.opacity(0.08)) }
        .shadow(color: .black.opacity(0.24), radius: 12, y: 8)
        .environment(\.colorScheme, .dark)
        .tint(.white)
        .padding(24)
    }
}

// Usage: one harness per prototype, one preview per variant plus the harness itself.
struct QuietVariant: View {
    var body: some View { Text("Quiet").font(.title2) }
}
struct EditorialVariant: View {
    var body: some View { Text("Editorial").font(.largeTitle.weight(.semibold)) }
}
struct PlayfulVariant: View {
    var body: some View { Text("Playful").font(.title2.weight(.heavy)) }
}

struct PricingCardPrototype: View {
    var body: some View {
        PrototypeHarness(slug: "pricing-card", variants: ["Quiet", "Editorial", "Playful"]) { index in
            switch index {
            case 1: EditorialVariant()
            case 2: PlayfulVariant()
            default: QuietVariant()
            }
        }
    }
}

#Preview("Picker") { PricingCardPrototype() }
#Preview("1 · Quiet") { QuietVariant() }
#Preview("2 · Editorial") { EditorialVariant() }
#Preview("3 · Playful") { PlayfulVariant() }
#endif
```

## Rules

- **Verbatim.** These values are the spec. No project fonts, no brand colors, no theme switching, no extra shadows or borders.
- **The highlight slides; the variant swap stays instant.** The segmented control's own selection motion is system motion and stays as it is. The variant being previewed switches with no transition: the selection is never set inside `withAnimation`, and the harness adds no `.transition`.
- **One allowed modification:** if a variant occupies the bottom of the screen (a toast stack, a bottom sheet, a dock, a tab bar), pass `edge: .top` so the picker never covers the work. Nothing else about it may move or change.
- **Replay is conditional.** Pass `hasReplay: true` only when at least one variant has an entrance or state animation worth re-triggering; a static comparison gets a shorter capsule with no divider.
- **It floats; it doesn't take space.** It is an `.overlay`, not a `.safeAreaInset`, so the variant lays out exactly as it would in production.

## Behavior contract

The contract is fixed regardless of where the harness renders:

- Tapping a segment switches to it; exactly one segment is selected at all times, and VoiceOver announces it as selected (the system control does this).
- The selection persists across relaunches via `@AppStorage`, keyed by slug, falling back to variant 1 when the stored index is out of range.
- Switching re-mounts the variant (`.id`), so entrance animations re-run; replay re-mounts without switching.
- Each variant also has its own `#Preview`, so the Xcode canvas can show any one of them full size without the picker.
