#!/usr/bin/env bash
# Structure checks the skills installer and the cross-references depend on. Runs anywhere (no Xcode).
#   - every skills/<dir>/SKILL.md has front matter with name == <dir> and a non-empty description
#   - name is lowercase-hyphen, <= 64 chars; description <= 1024 chars
#   - every upstream skill is either ported here or listed as not ported
#   - every ported skill (all but write-swift) ends with a "## No native equivalent" section
#   - every relative Markdown link and ../<skill>/FILE.md reference resolves
set -u
cd "$(dirname "$0")/.."
fail=0
err() { echo "FAIL $*"; fail=1; }

# Upstream skills at commit 64eb3de. Update when re-syncing with emilkowalski/skills.
UPSTREAM="animate animate-expo animation-performance animation-vocabulary apple-design ask-emil ask-sonner break-ui choreograph emil-design-eng find-animation-opportunities gestures improve-animations learn-taste mobile-native pick-ui-library prototype remove-animations review-animations write-swift"
NOT_PORTED="animate-expo ask-sonner"

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

[ $fail -eq 0 ] && echo "validate: OK"
exit $fail
