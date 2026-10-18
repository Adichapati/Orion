"""Builds ORION's isometric room mock-ups from art/maps/rooms.json.

Usage (from anywhere):
    python art/_scripts/build_maps.py

It turns rooms.json into a Lua table, joins it with maps_render.lua and runs the
result in Aseprite in batch mode. Output goes to art/maps/ (one .aseprite and two
PNGs per room). Set the ASEPRITE environment variable if aseprite.exe is not at
C:/aseprite/build/bin/aseprite.exe or on PATH.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

ART = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lua(value):
    if isinstance(value, dict):
        return "{" + ",".join(f"[{lua(k)}]={lua(v)}" for k, v in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ",".join(lua(v) for v in value) + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if value is None:
        return "nil"
    return json.dumps(value, ensure_ascii=False)


def find_aseprite():
    candidates = [os.environ.get("ASEPRITE"), "C:/aseprite/build/bin/aseprite.exe", shutil.which("aseprite")]
    for c in candidates:
        if c and os.path.exists(c):
            return c
    sys.exit("Aseprite not found: set the ASEPRITE environment variable to aseprite.exe")


def main():
    with open(os.path.join(ART, "maps", "rooms.json"), encoding="utf-8") as f:
        data = json.load(f)
    with open(os.path.join(ART, "_scripts", "maps_render.lua"), encoding="utf-8") as f:
        renderer = f.read()
    root = ART.replace("\\", "/")
    script = f"ROOT = {json.dumps(root)}\nDATA = {lua(data)}\n" + renderer
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as tmp:
        tmp.write(script)
        tmp_path = tmp.name
    try:
        result = subprocess.run([find_aseprite(), "-b", "--script", tmp_path], capture_output=True, text=True)
        print(result.stdout.strip())
        if result.stderr.strip():
            print(result.stderr.strip(), file=sys.stderr)
        sys.exit(result.returncode)
    finally:
        os.remove(tmp_path)


if __name__ == "__main__":
    main()
