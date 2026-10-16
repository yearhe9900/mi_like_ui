# -*- coding: utf-8 -*-
"""Search bar measurement, round 2: target the band above the pill row.

第一轮阈值 12 漏检浅色搜索栏（#E5E5E5 vs #F3F3F3 差 12），
本轮在 y<pill 行(254) 区间用阈值 6 重新定位搜索栏。
"""
from PIL import Image

PATH = r"C:\Users\zmt\.workbuddy\clipboard-images\clipboard-2026-10-16T07-02-37-707Z-1b32e0ff.jpg"

im = Image.open(PATH).convert("RGB")
W, H = im.size
S = 393.0 / W
px = im.load()
print(f"SIZE = {W}x{H}  scale = {S:.5f} dp/px")


def diff(a, b):
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


# --- row profile in the top region: how many px differ from left-bg per row ---
xl = int(W * 0.01)
print("row profile (y, count of x in [0.03W..0.97W] differing from x=0.01W bg by >5):")
bands = []
in_band = False
for y in range(60, 260):
    bg = px[xl, y]
    cnt = sum(1 for x in range(int(W * 0.03), int(W * 0.97), 4) if diff(px[x, y], bg) > 5)
    if y % 5 == 0:
        print(f"  y={y}: {cnt}")
    if cnt > 40 and not in_band:
        bands.append([y, y])
        in_band = True
    elif cnt <= 40 and in_band:
        bands[-1][1] = y - 1
        in_band = False
if in_band:
    bands[-1][1] = 259
print("BANDS =", bands)

# take the first band with height in 40..140 px as the search bar
bar = next((b for b in bands if 40 <= b[1] - b[0] + 1 <= 140), None)
if not bar:
    raise SystemExit("no candidate band")
top, bot = bar
h = bot - top + 1
ym = (top + bot) // 2
print(f"\nBAR y={top}..{bot}  h={h}px = {h*S:.1f} dp  top={top*S:.1f} dp")

# horizontal edges at mid row vs page bg (sample bg above the bar)
bg = px[2, top - 8]
left = next((x for x in range(2, int(W * 0.30)) if diff(px[x, ym], bg) > 6), -1)
right = next((x for x in range(W - 2, int(W * 0.60), -1) if diff(px[x, ym], bg) > 6), -1)
span = right - left + 1
print(
    f"BAR x={left}..{right}  w={span}px = {span*S:.1f} dp  "
    f"leftInset={left*S:.1f} dp  rightInset={(W-1-right)*S:.1f} dp"
)

# fill: interior right half (avoid icon/text on the left)
sx1, sx2 = left + int(span * 0.55), right - 12
samples = [px[x, y] for x in range(sx1, sx2 + 1, 5) for y in range(top + 6, bot - 6, 5)]
fr = round(sum(c[0] for c in samples) / len(samples))
fg = round(sum(c[1] for c in samples) / len(samples))
fb = round(sum(c[2] for c in samples) / len(samples))
print(f"FILL = #{fr:02X}{fg:02X}{fb:02X} (n={len(samples)})")

bs = [px[x, y] for x in range(3, 16, 4) for y in range(top - 20, top - 4, 4)]
br = round(sum(c[0] for c in bs) / len(bs))
bgg = round(sum(c[1] for c in bs) / len(bs))
bb = round(sum(c[2] for c in bs) / len(bs))
print(f"PAGE BG = #{br:02X}{bgg:02X}{bb:02X}")

# icon + placeholder groups in the left 45% of the bar
fill = (fr, fg, fb)
x_end = left + int(0.45 * span)
cnt = {}
for x in range(left, x_end + 1):
    cnt[x] = sum(1 for y in range(top, bot + 1) if diff(px[x, y], fill) > 10)

blanks, bs0 = [], -1
for x in range(left, x_end + 1):
    if cnt[x] == 0:
        if bs0 < 0:
            bs0 = x
    else:
        if bs0 >= 0:
            blanks.append(f"{bs0}..{x-1}")
            bs0 = -1
if bs0 >= 0:
    blanks.append(f"{bs0}..{x_end}")
print("BLANK COLS =", " | ".join(blanks))

groups, gs, gap = [], -1, 0
for x in range(left, x_end + 1):
    if cnt[x] > 0:
        if gs < 0:
            gs = x
        gap = 0
    elif gs >= 0:
        gap += 1
        if gap > 3:
            groups.append((gs, x - gap))
            gs = -1
if gs >= 0:
    groups.append((gs, x_end))

fill_col = (fr, fg, fb)
for x1, x2 in groups:
    ys, dk, dkc = [], 999, None
    for x in range(x1, x2 + 1):
        for y in range(top, bot + 1):
            if diff(px[x, y], fill_col) > 10:
                ys.append(y)
                c = px[x, y]
                if sum(c) < dk:
                    dk, dkc = sum(c), c
    print(
        f"GROUP x={x1}..{x2} dx={(x1-left)*S:.1f} dp w={(x2-x1+1)*S:.1f} dp  "
        f"y={min(ys)}..{max(ys)} h={(max(ys)-min(ys)+1)*S:.1f} dp dy={(min(ys)-top)*S:.1f} dp  "
        f"ink=#{dkc[0]:02X}{dkc[1]:02X}{dkc[2]:02X}"
    )

# left edge corner profile
prof = []
for dy in (2, 6, 12, 24, 40):
    yy = top + dy
    if yy <= bot:
        for x in range(left, left + 220):
            if diff(px[x, yy], bg) > 6:
                prof.append(f"dy{dy}={(x-left)*S:.1f}")
                break
print("LEFT EDGE INSET(dp) =", " ".join(prof))

# gap: bar bottom -> pill row top (pill top measured at 254px in round 1)
print(f"bar bottom = {bot*S:.1f} dp, pill row top = {254*S:.1f} dp, gap = {(254-bot)*S:.1f} dp")
