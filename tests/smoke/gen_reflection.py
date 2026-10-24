#!/usr/bin/env python3
"""Turns Roblox's API-Dump.json into a Luau table the smoke-test mocks validate against."""
import json
import sys

api = json.load(open(sys.argv[1]))
out = ["return {", "Classes = {"]
for c in api["Classes"]:
    tags = set(c.get("Tags") or [])
    props, events, funcs, callbacks = [], [], [], []
    for m in c["Members"]:
        mt = m["MemberType"]
        name = m["Name"]
        if not name.isidentifier():
            continue
        if mt == "Property":
            vt = m.get("ValueType", {})
            ro = "ReadOnly" in (m.get("Tags") or [])
            props.append(f'{name}="{vt.get("Category","")}:{vt.get("Name","")}:{"R" if ro else ""}"')
        elif mt == "Event":
            events.append(f"{name}=true")
        elif mt == "Function":
            funcs.append(f"{name}=true")
        elif mt == "Callback":
            callbacks.append(f"{name}=true")
    sup = c.get("Superclass") or ""
    out.append(
        f'["{c["Name"]}"]={{S="{sup}",NC={str("NotCreatable" in tags).lower()},SV={str("Service" in tags).lower()},'
        f'P={{{",".join(props)}}},E={{{",".join(events)}}},F={{{",".join(funcs)}}},CB={{{",".join(callbacks)}}}}},'
    )
out.append("},")
out.append("Enums = {")
for e in api["Enums"]:
    items = ",".join(f'["{i["Name"]}"]={i["Value"]}' for i in e["Items"])
    out.append(f'["{e["Name"]}"]={{{items}}},')
out.append("},")
out.append("}")
print("\n".join(out))
