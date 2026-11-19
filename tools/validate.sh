#!/usr/bin/env bash
# Structure checks the skills installer and the cross-references depend on. Runs anywhere (no Xcode).
#   - every skills/<dir>/SKILL.md has front matter with name == <dir> and a non-empty description
#   - name is lowercase-hyphen, <= 64 chars; description <= 1024 chars
#   - every upstream skill is either ported here or listed as not ported
#   - every ported skill (all but write-swift) ends with a "## No native equivalent" section
#   - every relative Markdown link and ../<skill>/FILE.md reference resolves
#   - the upstream commit is the same in upstream-diff.sh, the README and every skill's link
#   - a skill works once installed: no link leaves skills/, and Motion.swift is linked where used
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
err() { echo "FAIL $*"; fail=1; }

# Upstream skills at commit 64eb3de. Update when re-syncing with emilkowalski/skills.
UPSTREAM="animate animate-expo animation-performance animation-vocabulary apple-design ask-emil ask-sonner break-ui choreograph emil-design-eng find-animation-opportunities gestures improve-animations learn-taste mobile-native pick-ui-library prototype remove-animations review-animations write-swift"
NOT_PORTED="animate-expo ask-sonner"

# One upstream commit, everywhere it is written down: tools/upstream-diff.sh holds it, and the README
# and each skill's "Adapted from" link have to point at the same one.
PIN=$(sed -n 's/^PIN=${PIN:-\([0-9a-f]\{40\}\)}$/\1/p' tools/upstream-diff.sh)
if [ -z "$PIN" ]; then
  err "tools/upstream-diff.sh: no 40-character PIN found"
else
  stale=$(grep -rnoE 'emilkowalski/skills/tree/[0-9a-f]+' README.md skills | grep -v "tree/$PIN")
  [ -n "$stale" ] && { echo "$stale" | sed "s/^/FAIL upstream link is not at pinned commit ${PIN:0:7}: /"; fail=1; }
  grep -q "\`${PIN:0:7}\`" README.md || err "README.md does not name the pinned commit ${PIN:0:7}"
  grep -q "^# Upstream skills at commit ${PIN:0:7}\." tools/validate.sh || err "tools/validate.sh: the UPSTREAM comment is not at ${PIN:0:7}"
fi

for s in $UPSTREAM; do
  if [[ " $NOT_PORTED " == *" $s "* ]]; then
    [ -d "skills/$s" ] && err "$s is listed as not ported but skills/$s exists"
    grep -q "$s" FLAGGED.md || err "$s not ported but not explained in FLAGGED.md"
  else
    [ -f "skills/$s/SKILL.md" ] || err "upstream skill $s missing: skills/$s/SKILL.md"
  fi
done

for f in skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$f")")
  [[ " $UPSTREAM " == *" $dir "* ]] || err "$dir is not an upstream skill (add it to UPSTREAM if intentional)"
  [ "$(head -1 "$f")" = "---" ] || { err "$f: no front matter"; continue; }
  # Parse with a real YAML parser, the way installers do: an unquoted " #" or ": " silently
  # truncates the description or drops the skill. Prints name<TAB>description, or ERROR.
  parsed=$(ruby -E UTF-8 -ryaml -e '
    raw = File.read(ARGV[0]); fm = raw[/\A---\n(.*?)\n---/m, 1]
    begin
      h = YAML.safe_load(fm); d = h["description"].to_s
      plain = raw[/^description: (.*)$/, 1].to_s
      if !plain.start_with?("\"", "\x27") && d != plain then puts "ERROR description truncated by YAML (#{d.size}/#{plain.size} chars): quote it"
      else puts "#{h["name"]}\t#{d}" end
    rescue => e then puts "ERROR #{e.message}" end' "$f")
  case "$parsed" in (ERROR*) err "$f: front matter: ${parsed#ERROR }"; continue ;; esac
  name=${parsed%%$'\t'*}
  desc=${parsed#*$'\t'}
  [ "$name" = "$dir" ] || err "$f: name '$name' != folder '$dir'"
  [[ "$name" =~ ^[a-z0-9-]{1,64}$ ]] || err "$f: name '$name' must be lowercase-hyphen, <= 64 chars"
  [ -n "$desc" ] || err "$f: empty description"
  [ ${#desc} -le 1024 ] || err "$f: description is ${#desc} chars (> 1024)"
  if [ "$dir" != write-swift ]; then
    grep -q '^## No native equivalent' "$f" || err "$f: missing '## No native equivalent'"
  fi
done

# Relative links: [text](path) not starting with http, #, or mailto; strip #anchor and :line.
links=$(find . -name '*.md' -not -path './.git/*' | while IFS= read -r md; do
  base=$(dirname "$md")
  grep -o '\]([^)]*)' "$md" | sed 's/^](//; s/)$//' | while IFS= read -r link; do
    # Spaces or "…" mean it's Swift's ^[text](inflect: true) syntax or an ellipsis, not a link.
    case "$link" in (http*|\#*|mailto:*|""|*" "*|*…*) continue ;; esac
    target=${link%%#*}; target=${target%%:*}
    [ -e "$base/$target" ] || echo "FAIL $md: broken link $link"
  done
  # Bare ../skill/FILE.md references in prose or backticks
  grep -o '\.\./[a-z0-9-]*/[A-Z-]*\.md' "$md" | sort -u | while IFS= read -r ref; do
    [ -e "$base/$ref" ] || echo "FAIL $md: broken reference $ref"
  done
done)
[ -n "$links" ] && { echo "$links"; fail=1; }

# The installer copies skills/<dir> and nothing else, so a skill has to work without the rest of
# this repo: a relative link may not climb out of skills/, and a file whose code uses the shared
# tokens has to say where tools/Motion.swift can be fetched from.
MOTION_URL="https://raw.githubusercontent.com/OrenSegal/emil-design-swiftui/main/tools/Motion.swift"
TOKENS='emil(EaseOut|EaseInOut|Drawer|Ease|Press|UI|Momentum)|\.pressable|rubberband\(|project\(velocity'
for md in skills/*/*.md; do
  grep -o '\]([^)]*)' "$md" | sed 's/^](//; s/)$//' | while IFS= read -r link; do
    case "$link" in (../../*) echo "FAIL $md: link $link leaves skills/ and breaks once the skill is installed" ;; esac
  done | grep . && fail=1
done
for d in skills/*/; do
  [ "$d" = skills/write-swift/ ] && continue
  if grep -qE "$TOKENS" "$d"*.md && ! grep -qF "]($MOTION_URL)" "${d}SKILL.md"; then
    err "${d}SKILL.md: the skill uses Motion.swift tokens but never links $MOTION_URL"
  fi
done

[ $fail -eq 0 ] && echo "validate: OK"
exit $fail
