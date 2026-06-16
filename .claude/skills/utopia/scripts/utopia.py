#!/usr/bin/env python3
"""Generate Utopia fluid clamp() tokens for Domus.

Utopia (utopia.fyi) interpolates a value between a min size (at the min
viewport) and a max size (at the max viewport) with a single clamp(). This
script reproduces that math so type/space tokens can be regenerated without
the website.

Usage
-----
  utopia.py                      # print the full :root token block
  utopia.py 13.5 15              # one clamp() for a min->max px pair
  utopia.py --min-vw 320 --max-vw 1240 18 20
"""
import argparse
from decimal import Decimal, ROUND_HALF_UP

REM = 16.0  # 1rem assumed = 16px (browser default)


def round_(x, n=4):
    # Half-up rounding (matches Utopia), then trim trailing zeros.
    q = Decimal(10) ** -n
    d = Decimal(repr(x)).quantize(q, rounding=ROUND_HALF_UP)
    return format(d.normalize(), "f")


def clamp(min_px, max_px, min_vw, max_vw):
    """Return a Utopia-style clamp() string for min_px -> max_px."""
    slope = (max_px - min_px) / (max_vw - min_vw)
    vw = slope * 100
    intercept_rem = (min_px - slope * min_vw) / REM
    return (
        f"clamp({round_(min_px / REM)}rem, "
        f"{round_(intercept_rem)}rem + {round_(vw)}vw, "
        f"{round_(max_px / REM)}rem)"
    )


def type_scale(body_min, body_max, ratio_min, ratio_max):
    """Steps -2..5: body * ratio**n (min uses min ratio, max uses max ratio)."""
    steps = {}
    for n in range(-2, 6):
        name = f"--step-{n}" if n >= 0 else f"--step-{n}"
        steps[name] = (body_min * ratio_min**n, body_max * ratio_max**n)
    return steps


# Space multiples off the body base, in Utopia's naming.
SPACE_MULTIPLES = {
    "--space-3xs": 0.25,
    "--space-2xs": 0.5,
    "--space-xs": 0.75,
    "--space-s": 1.0,
    "--space-m": 1.5,
    "--space-l": 2.0,
    "--space-xl": 3.0,
    "--space-2xl": 4.0,
    "--space-3xl": 6.0,
}


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("pair", nargs="*", type=float,
                   help="min_px max_px for a single clamp()")
    p.add_argument("--min-vw", type=float, default=320)
    p.add_argument("--max-vw", type=float, default=1240)
    p.add_argument("--body-min", type=float, default=18)
    p.add_argument("--body-max", type=float, default=20)
    p.add_argument("--ratio-min", type=float, default=1.20)
    p.add_argument("--ratio-max", type=float, default=1.25)
    args = p.parse_args()

    if args.pair:
        if len(args.pair) != 2:
            p.error("provide exactly two numbers: min_px max_px")
        print(clamp(args.pair[0], args.pair[1], args.min_vw, args.max_vw))
        return

    print(":root {")
    print("  /* fluid type scale */")
    for name, (mn, mx) in type_scale(args.body_min, args.body_max,
                                     args.ratio_min, args.ratio_max).items():
        print(f"  {name}: {clamp(mn, mx, args.min_vw, args.max_vw)}; "
              f"/* {round_(mn, 2)} -> {round_(mx, 2)} */")
    print()
    print("  /* fluid space scale */")
    for name, mult in SPACE_MULTIPLES.items():
        mn, mx = args.body_min * mult, args.body_max * mult
        print(f"  {name}: {clamp(mn, mx, args.min_vw, args.max_vw)}; "
              f"/* {round_(mn, 2)} -> {round_(mx, 2)} */")
    print("}")


if __name__ == "__main__":
    main()
