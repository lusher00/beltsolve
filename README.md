# beltsolve

**Parametric timing-belt drive solver — using exact open-drive geometry, not the 180° shortcut.**

🔗 **Live demo:** https://lusher00.github.io/beltsolve

Lay out a belt drive by fixing what you've already committed to and solving for the rest. Lock any one of {pulley A, pulley B, center distance, belt}, leave the others on *solve*, and beltsolve fills in the gaps — and it does the geometry honestly, so the belt it hands you is the belt that actually fits.

---

## Why this exists

Every motor reduction starts the same way: you've got two pulleys and a rough idea of how far apart the shafts sit, and you need the belt that closes the loop — or you've got a belt in a drawer and need to know where to drill the second shaft.

The math isn't hard, but most calculators cheat on it. They assume the belt wraps each pulley by exactly 180°. That's only true when both pulleys are the same size. The moment your pulleys differ — which is the whole point of a reduction — the belt wraps the big one by *more* than 180° and the small one by *less*, and the 180° assumption quietly undercounts the belt length. A few percent at normal spacing; worse as the center distance shrinks or the ratio climbs. You find out when the belt won't go on, or goes on slack.

beltsolve carries the real wrap angles. The number it gives you is buildable.

---

## What it solves

A standard open (external) two-pulley drive. Pick the **lock/solve** state for each of the four variables:

| Variable | Lock when… | Solve when… |
|---|---|---|
| Pulley A (teeth) | the driver is fixed | you're choosing a ratio |
| Pulley B (teeth) | the driven is fixed | you're choosing a ratio |
| Center distance | the frame is already drilled | the frame isn't built yet |
| Belt (length / teeth) | you have a belt in hand | you're free to order one |

Anchor the solve with at least a center distance *or* a belt — those are the two that set physical scale. Everything else follows.

---

## The math

Pitch radius from tooth count and belt pitch *p*:

    r = N · p / (2π)

Center offset between the two pitch circles:

    d = |r₂ − r₁|

Wrap half-angle — this is the term the shortcut throws away:

    α = asin(d / C)

Exact open-belt length:

    L = 2·√(C² − d²)  +  π·(r₁ + r₂)  +  2·d·α
        └─ straight runs ─┘   └─ base wrap ─┘   └─ wrap asymmetry ─┘

And the wrap angles themselves, if you need them for tension or tooth-engagement checks:

    θ_large = π + 2α
    θ_small = π − 2α

**Constraint:** `C > r₁ + r₂`, or the pulleys overlap. In practice you want real clearance beyond that.

The common shortcut keeps the first two terms and drops `2·d·α`. For equal pulleys `d = 0` and it vanishes — fine. For anything else, that's the error.

---

## Worked example

20T driver, 60T driven, 3GT belt (3 mm pitch), shafts ~80 mm apart:

    r₁ = 20·3/(2π) =  9.55 mm
    r₂ = 60·3/(2π) = 28.65 mm
    d  = 19.10 mm
    α  = asin(19.10/80) = 0.241 rad

    L  = 2·√(80² − 19.10²) + π·(38.20) + 2·19.10·0.241
       = 155.37 + 120.00 + 9.21
       = 284.6 mm   →  94.9 teeth

The 180° shortcut would have said **275.4 mm** — about 9 mm, or 3.2%, short. On a 3 mm pitch that's three teeth of belt you don't have. Shrink the center distance or widen the ratio and the gap grows.

---

## Belts are discrete — the workflow that matters

Solving for "belt" gives you a continuous length, but you can't buy 94.9 teeth. So the move on the bench is two passes:

1. Lock the pulleys, solve the belt → get the ideal length (here, 94.9T).
2. Snap to a real belt — say a stock **95T (285 mm)** — lock *that*, and solve the center distance.

Now you've got the exact spacing to build to for the belt you can actually order, at the tension you want. That second solve is the one that saves you a reprint.

---

## Use

Open `index.html` in any browser, or just hit the [live demo](https://lusher00.github.io/beltsolve). Toggle **LOCK** on what's fixed, leave the rest on **SOLVE**, run it.

**Pitch presets:** GT2 (2 mm) · 3GT/GT3 (3 mm) · HTD 5M (5 mm) — or enter a custom pitch.

No install, no dependencies, no data leaves the page. It's one static HTML file.

---

## Roadmap

- `beltsolve.py` — same solver as a CLI, for scripting and BOM generation
- Idler / tensioner placement
- Nearest-stock-belt lookup baked into the solve

---

## License

MIT. Use it, fork it, ship it in your own tools.
