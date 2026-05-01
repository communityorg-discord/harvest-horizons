#!/usr/bin/env python3
"""Post-export cache buster.

Godot's web export always names files index.{wasm,pck,js,...}. Browsers
aggressively cache those across deploys. This script renames them to
include a short version stamp so the URL changes every build, forcing
clients to fetch fresh content.

Run from project root:  python3 scripts/cache_bust.py
"""
import os, re, time, glob, sys

PLAY_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "play"))

stamp = time.strftime("%Y%m%d%H%M%S")

# 1. Clean up stale versioned files from prior runs FIRST (before any renames).
for f in os.listdir(PLAY_DIR):
    if re.match(r"^index\.\d{14}\.", f):
        os.remove(os.path.join(PLAY_DIR, f))
        print(f"  removed stale {f}")

# 2. Plan renames for the freshly-exported "index.<ext>" files.
renames = {}
for old in sorted(os.listdir(PLAY_DIR)):
    if not old.startswith("index."):
        continue
    if old == "index.html":
        continue
    ext = old[len("index."):]
    new = f"index.{stamp}.{ext}"
    renames[old] = new

if not renames:
    print("nothing to rename")
    sys.exit(0)

# 3. Apply renames.
for old, new in renames.items():
    os.rename(os.path.join(PLAY_DIR, old), os.path.join(PLAY_DIR, new))
    print(f"  {old} -> {new}")

# 4. Patch index.html: replace any "index.<ext>" references with versioned ones.
html_path = os.path.join(PLAY_DIR, "index.html")
with open(html_path, encoding="utf-8") as f:
    html = f.read()
patches = 0
for old, new in renames.items():
    for needle in (f'"{old}"', f'"./{old}"', f"'{old}'"):
        if needle in html:
            html = html.replace(needle, needle.replace(old, new))
            patches += 1
    needle_src = f'src="{old}"'
    if needle_src in html:
        html = html.replace(needle_src, f'src="{new}"')
        patches += 1

# Engine config has "executable":"index" — point it at "index.<stamp>".
exec_re = re.compile(r'"executable"\s*:\s*"index"')
if exec_re.search(html):
    html = exec_re.sub(f'"executable":"index.{stamp}"', html)
    patches += 1

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

print(f"patched {patches} references in index.html with stamp {stamp}")
