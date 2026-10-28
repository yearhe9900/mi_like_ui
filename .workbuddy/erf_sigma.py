# -*- coding: utf-8 -*-
"""sigma(y) of the header glass via erf-fit of the banner side edges.

Model per row: f(x) = c0 + c1*x + A * Phi((x - x0) / (sigma * sqrt2))
(= linear content trend + blurred step).  Grid-search (x0, sigma),
closed-form LS for (c0, c1, A).  Robust to content ramps that defeat
the 10-90 plateau method.

Usage: python erf_sigma.py <frame.jpg> <xedge> <xwin0> <xwin1> <y0> <y1> <ystep>
"""
import sys, math
import numpy as np
from PIL import Image


def fit_edge(px, y, x0w, x1w, xe_lo, xe_hi):
    xs = np.arange(x0w, x1w, dtype=float)
    ys = np.array([0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
                   for p in (px[int(x), y] for x in xs)])
    best = None
    for sigma in np.arange(0.5, 42.0, 0.5):
        for x0 in np.arange(xe_lo, xe_hi, 1.0):
            Phi = 0.5 * (1.0 + np.vectorize(math.erf)((xs - x0) / (sigma * math.sqrt(2))))
            M = np.stack([np.ones_like(xs), xs, Phi], axis=1)
            coef, res, *_ = np.linalg.lstsq(M, ys, rcond=None)
            pred = M @ coef
            rss = float(((ys - pred) ** 2).sum())
            if best is None or rss < best[0]:
                best = (rss, sigma, x0, coef[2])
    return best


def main():
    path, xe, x0w, x1w, y0, y1, ystep = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]), int(sys.argv[7])
    im = Image.open(path).convert("RGB")
    px = im.load()
    print("frame:", path, " edge x≈%d" % xe)
    for y in range(y0, y1, ystep):
        rss, sigma, x0, amp = fit_edge(px, y, x0w, x1w, xe - 35, xe + 35)
        print(" y=%4d  sigma=%5.1fpx=%5.2fdp  x0=%5.1f  amp=%6.1f  rss=%8.1f"
              % (y, sigma, sigma * 0.32213, x0, amp, rss))


if __name__ == "__main__":
    main()
