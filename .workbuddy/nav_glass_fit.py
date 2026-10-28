# -*- coding: utf-8 -*-
"""Nav glass sigma/alpha by synthetic-blur matching on the reference clips.

During scroll the SAME content passes sharp above the floating bar, then
blurred (and veiled) under it.  Align two frames by vertical shift, then
minimize  | under_nav - alpha*C - (1-alpha)*GaussSigma(sharp) |  over the
clean glass strip between the bar top and the icons.

Usage: python .workbuddy/nav_glass_fit.py
"""
import numpy as np
from PIL import Image

B = r"D:/Workspace/personal/mi_like_ui_demo/.workbuddy/vframes"


def lum(a):
    return 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]


def blur2d(img, sigma):
    """Separable Gaussian blur with exact sigma (px)."""
    if sigma < 0.6:
        return img.astype(float).copy()
    r = int(3 * sigma) + 1
    x = np.arange(-r, r + 1, dtype=float)
    k = np.exp(-x * x / (2 * sigma * sigma))
    k /= k.sum()
    a = img.astype(float)
    squeeze = a.ndim == 2
    if squeeze:
        a = a[..., None]
    h, w, c = a.shape
    pad = np.pad(a, ((r, r), (0, 0), (0, 0)), mode="edge")
    tmp = np.empty_like(a)
    for ci in range(c):
        for x0 in range(w):
            tmp[:, x0, ci] = np.convolve(pad[:, x0, ci], k, mode="same")[r:-r]
    pad2 = np.pad(tmp, ((0, 0), (r, r), (0, 0)), mode="edge")
    out = np.empty_like(a)
    for ci in range(c):
        for y0 in range(h):
            out[y0, :, ci] = np.convolve(pad2[y0, :, ci], k, mode="same")[r:-r]
    return out[..., 0] if squeeze else out


def best_shift(a, b, ylo=1950, yhi=2300, xlo=100, xhi=1120):
    """vertical shift dy such that b[y + dy] ~= a[y] (content moves up in b)."""
    best = None
    ref = lum(a[ylo:yhi, xlo:xhi])
    for dy in range(-620, 621, 2):
        y0, y1 = ylo + dy, yhi + dy
        if y0 < 0 or y1 > a.shape[0]:
            continue
        cand = lum(b[y0:y1, xlo:xhi])
        d = float(((ref - cand) ** 2).mean())
        if best is None or d < best[0]:
            best = (d, dy)
    return best


def fit(tag, sharp_path, blur_path, nav_top, veil_rgb):
    sharp = np.asarray(Image.open(sharp_path).convert("RGB"), dtype=float)
    under = np.asarray(Image.open(blur_path).convert("RGB"), dtype=float)
    d, dy = best_shift(sharp, under)
    print(f"[{tag}] shift dy={dy}px (rss={d:.1f})")
    ylo, yhi = nav_top + 7, nav_top + 39   # 纯净玻璃带（栏顶…图标之间）
    xlo, xhi = 420, 1070                   # 避开选中高亮与图标/文字
    target = lum(under[ylo:yhi, xlo:xhi])
    margin = 130
    # best_shift 约定 sharp[y] ≈ under[y + dy] → under[Y] 对应 sharp[Y - dy]
    y0 = ylo - dy - margin
    y1 = yhi - dy + margin
    if y0 < 0 or y1 > sharp.shape[0]:
        print(f"[{tag}] sharp rows out of range (dy={dy})")
        return
    src = sharp[y0:y1, xlo:xhi]
    best = None
    curve = []
    for sigma_px in np.arange(3, 66, 1.5):
        b = lum(blur2d(src, sigma_px))[margin:-margin]
        X = b
        # out ≈ c + t·X  （c = 膜+填充的常数项，t = 透射比；双参数 LS）
        Xf = X.reshape(-1)
        Yf = target.reshape(-1)
        A = np.stack([np.ones_like(Xf), Xf], axis=1)
        coef, *_ = np.linalg.lstsq(A, Yf, rcond=None)
        c, t = float(coef[0]), float(coef[1])
        resid = float(np.sqrt((((target - (c + t * X)) ** 2).mean())))
        curve.append((sigma_px, resid))
        if best is None or resid < best[0]:
            best = (resid, sigma_px, c, t)
    resid, sigma_px, c, t = best
    near = [(round(s, 1), round(r, 2)) for s, r in curve if abs(s - sigma_px) <= 7]
    print(f"[{tag}] sigma={sigma_px:.1f}px={sigma_px*0.32213:.2f}dp  "
          f"c={c:.1f} t={t:.2f}  resid={resid:.2f}")
    print(f"     curve near min: {near}")


if __name__ == "__main__":
    fit("dark  t4.0 vs t8.8", f"{B}/seq_dark/t8.8.jpg", f"{B}/seq_dark/t4.0.jpg", 2411, 0.0)
    fit("dark  t5.6 vs t8.8", f"{B}/seq_dark/t8.8.jpg", f"{B}/seq_dark/t5.6.jpg", 2411, 0.0)
    fit("dark  t7.2 vs t8.8", f"{B}/seq_dark/t8.8.jpg", f"{B}/seq_dark/t7.2.jpg", 2411, 0.0)
    fit("light t4.4 vs t8.4", f"{B}/seq_light/t8.4.jpg", f"{B}/seq_light/t4.4.jpg", 2411, 243.0)
    fit("light t5.6 vs t8.4", f"{B}/seq_light/t8.4.jpg", f"{B}/seq_light/t5.6.jpg", 2411, 243.0)
