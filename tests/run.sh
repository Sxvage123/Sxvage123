#!/usr/bin/env bash
# Runs the shared-module tests under the plain Luau CLI with mocked Roblox APIs.
# Usage: tests/run.sh   (needs `luau` on PATH, or set LUAU=/path/to/luau)
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(mktemp -d)
python3 - "$out" <<'PY'
import glob, json, sys
out = sys.argv[1]
sources = {p: open(p).read() for p in glob.glob("shared/**/*.luau", recursive=True)}
with open(f"{out}/sources.luau", "w") as f:
    f.write("SOURCES = {\n")
    for path, src in sources.items():
        assert "]==]" not in src
        f.write(f"\t[{json.dumps(path)}] = [==[{src}]==],\n")
    f.write("}\n")
PY
cp tests/harness.luau tests/run.luau "$out/"
cat "$out/sources.luau" "$out/run.luau" > "$out/main.luau"
(cd "$out" && "${LUAU:-luau}" main.luau)
rm -rf "$out"
