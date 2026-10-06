#!/bin/bash
# Run the skill installer against a temp folder and check the copied files.
# Uses the checkout next to this script. It does not download from GitHub.
# Compiles the knob / D-Pad logic tests when swiftc is on PATH.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER="$ROOT/install-skills.sh"
SRC_SKILLS="$ROOT/plugins/tapkit-ios-sdk/skills"
SRC_RULE="$ROOT/.cursor/rules/tapkit-ios-sdk.mdc"

same_tree() {
  diff -rq "$1" "$2"
}

python3 - "$SRC_SKILLS" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve().parents[2]
plugin = root / "plugins" / "tapkit-ios-sdk"
skills = sorted(p for p in (plugin / "skills").iterdir() if p.is_dir())
if len(skills) < 8:
    raise SystemExit(f"expected at least 8 skills, found {len(skills)}")

claude = json.loads((root / ".claude-plugin" / "marketplace.json").read_text())
codex = json.loads((root / ".agents" / "plugins" / "marketplace.json").read_text())
if (root / claude["plugins"][0]["source"]).resolve() != plugin:
    raise SystemExit("Claude marketplace does not point at the plugin")
if (root / codex["plugins"][0]["source"]["path"]).resolve() != plugin:
    raise SystemExit("Codex marketplace does not point at the plugin")
for manifest in (".claude-plugin", ".codex-plugin"):
    name = json.loads((plugin / manifest / "plugin.json").read_text())["name"]
    if name != plugin.name:
        raise SystemExit(f"{manifest} name is {name}")

for skill in skills:
    text = (skill / "SKILL.md").read_text()
    front = re.match(r"^---\nname: (\S+)\ndescription: (.+)\n---\n", text)
    if not front:
        raise SystemExit(f"{skill.name} needs a one-line name + description frontmatter")
    if front.group(1) != skill.name:
        raise SystemExit(f"{skill.name} frontmatter name is {front.group(1)}")
    for link in re.findall(r"\]\((scripts/[^)]+)\)", text):
        if not (skill / link).exists():
            raise SystemExit(f"{skill.name} missing {link}")

getting_started = (plugin / "skills" / "tapkit-getting-started" / "SKILL.md").read_text()
for token in ("addDelegate", "setDefaultTAPInputMode", "start()"):
    if token not in getting_started:
        raise SystemExit(f"getting-started skill is missing {token}")
print(f"Checked {len(skills)} skill manifests.")
PY

work="$(mktemp -d)"
home="$(mktemp -d)"
trap 'rm -rf "$work" "$home"' EXIT

(
  cd "$work"
  "$INSTALLER" all
)

same_tree "$SRC_SKILLS" "$work/.claude/skills"
same_tree "$SRC_SKILLS" "$work/.agents/skills"
same_tree "$SRC_SKILLS" "$work/.cursor/skills"
cmp "$SRC_RULE" "$work/.cursor/rules/tapkit-ios-sdk.mdc"

awk 'BEGIN { keep = 1 } /^## Contributing to this repository/ { keep = 0 } keep' \
  "$ROOT/AGENTS.md" > "$work/expected-agents.md"
diff -u "$work/expected-agents.md" "$work/AGENTS.md"
if grep -q "Contributing to this repository" "$work/AGENTS.md"; then
  echo "Error: AGENTS.md still has the contributor section." >&2
  exit 1
fi

HOME="$home" "$INSTALLER" -g cursor
same_tree "$SRC_SKILLS" "$home/.cursor/skills"
cmp "$SRC_RULE" "$home/.cursor/rules/tapkit-ios-sdk.mdc"

HOME="$home" "$INSTALLER" -g agents
diff -u "$work/expected-agents.md" "$home/.codex/AGENTS.md"

printf 'my notes\n' > "$home/.codex/AGENTS.md"
if HOME="$home" "$INSTALLER" -g agents; then
  echo "Error: -g agents replaced an existing AGENTS.md." >&2
  exit 1
fi
[ "$(cat "$home/.codex/AGENTS.md")" = "my notes" ]

if command -v swiftc >/dev/null 2>&1; then
  swiftc -o "$work/skill-logic" \
    "$ROOT/plugins/tapkit-ios-sdk/skills/tapkit-knob/scripts/KnobTracker.swift" \
    "$ROOT/plugins/tapkit-ios-sdk/skills/tapkit-dpad/scripts/DpadController.swift" \
    "$ROOT/tests/SkillLogicTests.swift"
  "$work/skill-logic"
else
  echo "swiftc not on PATH; skipped knob and D-Pad compile."
fi

echo "Installer check passed."
