#!/usr/bin/env bash
# Lists what changed in emilkowalski/skills since the commit this port is based on.
# Exit 0: up to date. Exit 1: upstream moved (the changed files are printed). Exit 2: couldn't check.
# After porting the changes, update PIN here, UPSTREAM in validate.sh, the commit link in README.md,
# and the "Adapted from" link at the top of each skills/*/SKILL.md. tools/validate.sh fails until they agree.
set -euo pipefail
PIN=${PIN:-64eb3deb9a5fbfa041faf783e0bc3fd635872e9c}
REPO=emilkowalski/skills
head=$(git ls-remote "https://github.com/$REPO" HEAD | cut -f1) || exit 2
[ -n "$head" ] || exit 2
if [ "$head" = "$PIN" ]; then echo "upstream: up to date at ${PIN:0:7}"; exit 0; fi
echo "upstream moved: ${PIN:0:7} -> ${head:0:7} (https://github.com/$REPO/compare/${PIN:0:7}...${head:0:7})"
curl -fsS ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} "https://api.github.com/repos/$REPO/compare/$PIN...$head" \
  | ruby -E UTF-8 -rjson -e 'JSON.parse(STDIN.read)["files"].each { |f| puts "  #{f["status"]}\t#{f["filename"]}" }' \
  || echo "  (could not list files)"
exit 1
