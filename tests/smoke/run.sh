#!/usr/bin/env bash
# Offline smoke test: runs each game's server + client scripts in a mocked Roblox and reports runtime errors.
# Usage: tests/smoke/run.sh path/to/API-Dump.json [game-dir-name ...]
# Needs `luau` on PATH (or LUAU=/path/to/luau).
set -euo pipefail
cd "$(dirname "$0")/../.."
api="$1"
shift
games=("$@")
if [ ${#games[@]} -eq 0 ]; then
	games=($(ls games))
fi
out=$(mktemp -d)
python3 tests/smoke/gen_reflection.py "$api" | sed '1s/^return /REFLECTION = /' > "$out/reflection.luau"
cp tests/smoke/datatypes.luau tests/smoke/roblox.luau tests/smoke/services.luau "$out/"
status=0
for g in "${games[@]}"; do
	python3 - "games/$g/default.project.json" > "$out/manifest.luau" <<'PY'
import json, os, sys
project = sys.argv[1]
base = os.path.dirname(project)
tree = json.load(open(project))["tree"]
entries = []
def add_dir(path_parts, directory):
    for name in sorted(os.listdir(directory)):
        full = os.path.join(directory, name)
        if os.path.isdir(full):
            add_dir(path_parts + [name], full)
            continue
        for suffix, cls in ((".server.luau", "Script"), (".client.luau", "LocalScript"), (".luau", "ModuleScript")):
            if name.endswith(suffix):
                entries.append((path_parts + [name[: -len(suffix)]], cls, open(full).read()))
                break
def walk(node, parts):
    if "$path" in node:
        add_dir(parts, os.path.normpath(os.path.join(base, node["$path"])))
    for key, child in node.items():
        if not key.startswith("$") and isinstance(child, dict):
            walk(child, parts + [key])
walk(tree, [])
print("MANIFEST = {")
for parts, cls, src in entries:
    assert "]==]" not in src
    print("{ path = {" + ",".join(json.dumps(p) for p in parts) + "}, class = \"" + cls + "\", source = [==[" + src + "]==] },")
print("}")
PY
	cat "$out/reflection.luau" "$out/manifest.luau" tests/smoke/run_game.luau > "$out/main.luau"
	echo "=== $g"
	if ! (cd "$out" && "${LUAU:-luau}" main.luau) > "$out/result.txt" 2>&1; then
		status=1
	fi
	cat "$out/result.txt"
	grep -q "RESULT: PASS" "$out/result.txt" || status=1
done
rm -rf "$out"
exit $status
