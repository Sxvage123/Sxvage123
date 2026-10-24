#!/usr/bin/env python3
"""Checks property tables passed to our part()/UI helpers against the Roblox API dump.

The Luau type checker can't see into `part({ Colr = ... })` style dictionaries, so typos there
would only blow up at runtime. Usage: scripts/check_props.py path/to/API-Dump.json
"""
import json
import re
import sys
from pathlib import Path

api = json.load(open(sys.argv[1]))
classes = {c["Name"]: c for c in api["Classes"]}


def props(name):
    out = set()
    while name and name in classes:
        c = classes[name]
        for m in c["Members"]:
            if m["MemberType"] == "Property":
                out.add(m["Name"])
        name = c.get("Superclass")
    return out


# helper call -> class, and how many leading args to skip before the table
HELPERS = [
    (re.compile(r"\b(?:part|killer|attach)\(\s*\{"), lambda m: "Part"),
    (re.compile(r'\bUI\.new\(\s*"(\w+)"\s*,\s*\{'), lambda m: m.group(1)),
    (re.compile(r"\bUI\.Label\([^{]*?,\s*\{"), lambda m: "TextLabel"),
    (re.compile(r"\bUI\.Button\([^{]*?,\s*[^{]*?,\s*\{"), lambda m: "TextButton"),
]


def table_keys(src, start):
    """Top-level `Key =` names of the table literal opening at src[start] == '{'."""
    depth, i, keys = 0, start, []
    while i < len(src):
        ch = src[i]
        if ch == '"':
            i = src.index('"', i + 1)
        elif ch in "{(":
            depth += 1
        elif ch in "})":
            depth -= 1
            if depth == 0:
                break
        elif depth == 1:
            m = re.match(r"([A-Za-z_]\w*)\s*=(?!=)", src[i:])
            if m and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] in "._")):
                keys.append(m.group(1))
                i += m.end()
                continue
        i += 1
    return keys


problems = 0
for path in sorted(Path(".").glob("**/*.luau")):
    if "build" in path.parts:
        continue
    src = path.read_text()
    for pattern, cls_of in HELPERS:
        for m in pattern.finditer(src):
            cls = cls_of(m)
            valid = props(cls) | {"Parent", "Name"}
            if not classes.get(cls):
                print(f"{path}: unknown class {cls}")
                problems += 1
                continue
            for key in table_keys(src, m.end() - 1):
                if key not in valid:
                    line = src.count("\n", 0, m.start()) + 1
                    print(f"{path}:{line}: {cls} has no property '{key}'")
                    problems += 1
print(f"{problems} problem(s)")
sys.exit(1 if problems else 0)
