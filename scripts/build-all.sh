#!/usr/bin/env bash
# Builds every game into build/<Name>.rbxlx and (optionally) type-checks it.
# Needs `rojo` on PATH. Set LUAU_LSP and ROBLOX_DEFS to also run the type checker.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
status=0
for project in games/*/default.project.json; do
	dir=$(dirname "$project")
	name=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['name'])" "$project")
	rojo build "$project" -o "build/$name.rbxlx" >/dev/null
	echo "built build/$name.rbxlx"
	if [[ -n "${LUAU_LSP:-}" ]]; then
		map=$(mktemp)
		rojo sourcemap "$project" -o "$map" >/dev/null
		if ! (cd "$dir" && "$LUAU_LSP" analyze --sourcemap="$map" --definitions=@roblox="$ROBLOX_DEFS" --platform=roblox src ../../shared); then
			status=1
		fi
		rm -f "$map"
	fi
done
exit $status
