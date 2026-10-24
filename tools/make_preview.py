#!/usr/bin/env python3
"""make_preview.py vox.json out.html [three.js file to inline | cdn]"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from brainrot_names import NAMES
data = open(sys.argv[1]).read()
three = '<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>'
if len(sys.argv) > 3 and sys.argv[3] != "cdn":
    three = "<script>" + open(sys.argv[3]).read() + "</script>"
tpl = open(os.path.join(os.path.dirname(__file__), "voxel_preview.html")).read()
open(sys.argv[2], "w").write(tpl.replace("<!--THREE-->", three).replace("/*DATA*/null", data).replace("/*NAMES*/null", json.dumps(NAMES)))
