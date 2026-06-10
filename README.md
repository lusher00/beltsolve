# beltsolve

Parametric timing-belt drive solver. Lock any of {pulley A, pulley B,
center distance, belt} and solve the rest, using exact open-drive
geometry (both wrap angles — not the small-angle approximation).

**Live demo:** https://lusher00.github.io/beltsolve

## Use
Open `index.html` in a browser, or deploy via GitHub Pages.
Toggle LOCK on what's fixed, leave the rest on SOLVE, hit run.
Anchor the solve with at least a center distance or a belt.

## Math
    L = 2·√(C²−d²) + π·(r₁+r₂) + 2·d·asin(d/C)
    r = N·p / 2π,  d = |r₂−r₁|

CLI (`beltsolve.py`) and tests to follow.
