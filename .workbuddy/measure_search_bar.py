# -*- coding: utf-8 -*-
"""Measure the search bar geometry/colors from the reference screenshot.

像素实测脚本（分析用，非交付物）：定位浅色主题商店首页顶部搜索栏，
输出 dp 几何（按 393 dp 设计宽缩放）与关键取色。
"""
from PIL import Image

PATH = r"C:\Users\zmt\.workbuddy\clipboard-images\clipboard-2026-10-16T07-02-37-707Z-1b32e0ff.jpg"

im = Image.open(PATH).convert("RGB")
W, H = im.size
S = 393.0 / W  # px -> dp
px = im.load()
print(f"SIZE = {W}x{H}  scale = {S:.5f} dp/px")


def diff(a, b):
    return max(abs(a[0] - b[0]), abs(a[1] - b[1]), abs(a[2] - b[2]))


# --- vertical scan: find the search bar band (row where x=72% differs from x=2%) ---
xl, xr = int(W * 0.02), int(W * 0.72)
runs = []
start, last = -1, -1
for y in range(int(H * 0.04), int(H * 0.30)):
    d = diff(px[xr, y], px[xl, y])
    if d > 12:
        if start < 0:
            start = y
        last = y
    elif start >= 0 and y - last > 8:
        runs.append((start, last))
        start = -1
if start >= 0:
    runs.append((start, last))
print("RUNS =", "; ".join(f"{a}..{b}(h={b-a+1})" for a, b in runs))

min_h = int(0.030 * H)
run = next((r for r in runs if r[1] - r[0] >= min_h), None)
if not run:
    raise SystemExit("NO BAR RUN FOUND")

top, bot = run
h = bot - top + 1
ym = (top + bot) // 2
print(f"BAR y={top}..{bot}  h={h}px = {h*S:.1f} dp  top={top*S:.1f} dp")

# --- horizontal edges at mid height ---
bg = px[2, ym]
left = next((x for x in range(2, int(W * 0.30)) if diff(px[x, ym], bg) > 10), -1)
right = next((x for x in range(W - 2, int(W * 0.60), -1) if diff(px[x, ym], bg) > 10), -1)
span = right - left + 1
print(
    f"BAR x={left}..{right}  w={span}px = {span*S:.1f} dp  "
    f"leftInset={left*S:.1f} dp  rightInset={(W-1-right)*S:.1f} dp"
)

# --- fill color: sample empty right part of the bar interior ---
sx1, sx2 = max(left + 1, right - 45), right - 12
samples = [px[x, y] for x in range(sx1, sx2 + 1, 6) for y in range(top + 8, bot - 8, 6)]
fr = round(sum(c[0] for c in samples) / len(samples))
fg = round(sum(c[1] for c in samples) / len(samples))
fb = round(sum(c[2] for c in samples) / len(samples))
print(f"FILL = #{fr:02X}{fg:02X}{fb:02X} (n={len(samples)})")

# --- page bg: left of the bar ---
bs = [px[x, y] for x in range(3, 16, 4) for y in range(ym - 12, ym + 13, 6)]
br = round(sum(c[0] for c in bs) / len(bs))
bgg = round(sum(c[1] for c in bs) / len(bs))
bb = round(sum(c[2] for c in bs) / len(bs))
print(f"PAGE BG = #{br:02X}{bgg:02X}{bb:02X}")

# --- icon / placeholder groups in the left 40% of the bar ---
fill = (fr, fg, fb)
x_end = left + int(0.40 * span)
cnt = {}
for x in range(left, x_end + 1):
    cnt[x] = sum(1 for y in range(top, bot + 1) if diff(px[x, y], fill) > 18)

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
        if gap > 2:
            groups.append((gs, x - gap))
            gs = -1
if gs >= 0:
    groups.append((gs, x_end))

for x1, x2 in groups:
    ys, dk, dkc = [], 999, None
    for x in range(x1, x2 + 1):
        for y in range(top, bot + 1):
            if diff(px[x, y], fill) > 18:
                ys.append(y)
                c = px[x, y]
                if sum(c) < dk:
                    dk, dkc = sum(c), c
    print(
        f"GROUP x={x1}..{x2} dx={(x1-left)*S:.1f} dp w={(x2-x1+1)*S:.1f} dp  "
        f"y={min(ys)}..{max(ys)} h={(max(ys)-min(ys)+1)*S:.1f} dp  "
        f"ink=#{dkc[0]:02X}{dkc[1]:02X}{dkc[2]:02X}"
    )

# --- left edge profile (corner radius check): inset of first non-bg px vs dy ---
prof = []
for dy in (2, 6, 12, 24, 40):
    yy = top + dy
    if yy <= bot:
        for x in range(left, left + 220):
            if diff(px[x, yy], bg) > 10:
                prof.append(f"dy{dy}={(x-left)*S:.1f}")
                break
print("LEFT EDGE INSET(dp) =", " ".join(prof))

# --- icon stroke: vertical scan through icon columns for ink extent ---
# (placeholder text baseline check: darkest ink row of the 2nd group = text core)
