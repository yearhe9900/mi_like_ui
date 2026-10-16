# -*- coding: utf-8 -*-
"""Search bar measurement, round 3: icon/text bboxes via luminance mask.

Round 2 用「与填充色差」会把圆角 AA（#E7→#F3 渐变）误判为内容；
本轮改用亮度掩码（<200 = 墨迹；填充 #E7=231、页底 #F3=243 都在掩码外），
分离出放大镜图标与占位文字的精确包围盒、字距、取色。
"""
from PIL import Image

PATH = r"C:\Users\zmt\.workbuddy\clipboard-images\clipboard-2026-10-16T07-02-37-707Z-1b32e0ff.jpg"

im = Image.open(PATH).convert("RGB")
W, H = im.size
S = 393.0 / W
px = im.load()

# bar band from round 2
TOP, BOT, LEFT, RIGHT = 117, 215, 27, 853
ym = (TOP + BOT) // 2
LUM = 200  # ink threshold: fill #E7(231) / bg #F3(243) excluded

# --- full-bar ink column profile (checks right half too) ---
cols = []
for x in range(LEFT, RIGHT + 1):
    n = sum(1 for y in range(TOP, BOT + 1) if max(px[x, y]) < LUM)
    cols.append((x, n))

ink_cols = [x for x, n in cols if n > 0]
print(f"ink columns span: {min(ink_cols)}..{max(ink_cols)}" if ink_cols else "NO INK")

# contiguous runs of ink columns (gap > 3 splits groups)
groups, gs, gap = [], None, 0
for x, n in cols:
    if n > 0:
        if gs is None:
            gs = x
        gap = 0
    elif gs is not None:
        gap += 1
        if gap > 3:
            groups.append((gs, x - gap))
            gs = None
if gs is not None:
    groups.append((gs, ink_cols[-1]))
print("INK GROUPS (x ranges):", groups)

for x1, x2 in groups:
    pts = [(x, y) for x in range(x1, x2 + 1) for y in range(TOP, BOT + 1) if max(px[x, y]) < LUM]
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    # modal ink color: darkest-decile mean (stroke cores)
    lums = sorted((sum(px[p]), p) for p in pts)
    cores = [p for _, p in lums[: max(1, len(lums) // 10)]]
    mr = sum(px[p][0] for p in cores) // len(cores)
    mg = sum(px[p][1] for p in cores) // len(cores)
    mb = sum(px[p][2] for p in cores) // len(cores)
    print(
        f"GROUP x={x1}..{x2}  dx={(x1-LEFT)*S:.1f}..{(x2-LEFT)*S:.1f} dp  "
        f"w={(x2-x1+1)*S:.1f} dp  y={min(ys)}..{max(ys)}  "
        f"dyTop={(min(ys)-TOP)*S:.1f}  h={(max(ys)-min(ys)+1)*S:.1f} dp  "
        f"ink=#{mr:02X}{mg:02X}{mb:02X}"
    )

# --- per-character boxes inside a text group (gap > 1) ---
text_groups = [g for g in groups if (g[1] - g[0]) > 20]
for x1, x2 in text_groups:
    sub, gs, gap = [], None, 0
    for x in range(x1, x2 + 2):
        n = sum(1 for y in range(TOP, BOT + 1) if x <= x2 and max(px[min(x, x2), y]) < LUM) if x <= x2 else 0
        if n > 0:
            if gs is None:
                gs = x
            gap = 0
        elif gs is not None:
            gap += 1
            if gap > 1:
                sub.append((gs, x - gap))
                gs = None
    if gs is not None:
        sub.append((gs, x2))
    print(f"  chars in {x1}..{x2}:", [(a, b, f"{(b-a+1)*S:.1f}dp") for a, b in sub])
    if len(sub) >= 2:
        adv = (sub[1][0] - sub[0][0]) * S
        print(f"  char advance = {adv:.1f} dp -> fontSize ~{adv:.1f}")

# --- right half content check ---
right_ink = [
    x
    for x in range(LEFT + int((RIGHT - LEFT) * 0.5), RIGHT + 1)
    if any(max(px[x, y]) < LUM for y in range(TOP, BOT + 1))
]
print("right-half ink columns:", right_ink if right_ink else "none (empty)")

# --- icon vertical stroke width: horizontal run lengths at icon mid row ---
gx1, gx2 = groups[0]
mid_runs = []
run = 0
for x in range(gx1, gx2 + 1):
    if max(px[x, ym]) < LUM:
        run += 1
    else:
        if run:
            mid_runs.append(run)
        run = 0
if run:
    mid_runs.append(run)
print(
    f"icon mid-row ink runs @y={ym}: {mid_runs} px "
    f"(-> {[round(r*S,1) for r in mid_runs]} dp)"
)
