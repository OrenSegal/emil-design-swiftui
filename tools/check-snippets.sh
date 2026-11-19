#!/bin/zsh
# Typecheck every ```swift block in the given Markdown files against the iOS 18 simulator SDK (Swift 6).
# Each block is compiled on its own, together with tools/Motion.swift (the shared tokens).
# A block whose first line is `// fragment` is skipped (use sparingly: one-line modifier examples only).
# usage: tools/check-snippets.sh skills/**/*.md
# Note: needs to run outside any sandbox (the macro plugin server uses sandbox-exec).
set -u
HERE=${0:A:h}
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
OUT=${TMPDIR:-/tmp}/snippet-check.$$
mkdir -p "$OUT"
fail=0; total=0; skipped=0
for md in "$@"; do
  # split blocks into numbered files
  awk -v out="$OUT" -v base="${md:t:r}-${md:h:t}" '
    /^```swift[[:space:]]*$/ {inb=1; n++; f=sprintf("%s/%s-%02d.swift", out, base, n); print "import SwiftUI\nimport UIKit" > f; next}
    /^```/ && inb {inb=0; close(f); next}
    inb {print >> f}
  ' "$md"
done
for f in "$OUT"/*.swift(N); do
  if sed -n '3p' "$f" | grep -q '^// fragment'; then skipped=$((skipped+1)); continue; fi
  total=$((total+1))
  if ! err=$(xcrun swiftc -typecheck -sdk "$SDK" -target arm64-apple-ios18.0-simulator -swift-version 6 -D DEBUG \
        -module-cache-path "$HERE/.mc" "$HERE/Motion.swift" "$f" 2>&1); then
    fail=$((fail+1)); echo "FAIL ${f:t}"; echo "$err" | grep -E 'error:' | head -5
  fi
done
echo "checked=$total failed=$fail skipped_fragments=$skipped"
[ $fail -eq 0 ]
