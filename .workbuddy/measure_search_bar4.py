# -*- coding: utf-8 -*-
"""Search bar measurement, round 4: icon internal geometry + true ink colors.

Round 3 的亮度阈值 200 偏高（细笔画抗锯齿被裁掉）：
本轮用 (fill+min)/2 做 50% 覆盖阈值还原真实包围盒，
逐行输出图标墨迹 run 重建「镜片圆 + 手柄」几何，并取文字/图标最深像素。
"""
from PIL import Image

PATH = r"C:\Users\zmt\.workbuddy\clipboard-images\clipboard-2026-10-16T07-02-37-707Z-1b32e0ff.jpg"

im = Image.open(PATH).convert("RGB")
W, H = im.size
S = 393.0 / W
px = im.load()

TOP, BOT, LEFT, RIGHT = 117, 215, 27, 853
ym = (TOP + BOT) // 2

# fill luminance
fill = 231  # #E7E7E7

# --- icon box (x 55..110): per-row ink runs at 50% coverage threshold ---
IX1, IX2 = 55, 110
lum_min = min(max(px[x, y]) for x in range(IX1, IX2 + 1) for y in range(TOP, BOT + 1))
thr = (fill + lum_min) // 2
print(f"icon region lum_min={lum_min}  thr(50%)={thr}")

rows = []
for y in range(TOP, BOT + 1):
    runs, run = [], 0
    for x in range(IX1, IX2 + 1):
        if max(px[x, y]) < thr:
            run += 1
        else:
            if run:
                runs.append((x - run, x - 1))
            run = 0
    if run:
        runs.append((IX2 - run + 1, IX2))
    if runs:
        rows.append((y, runs))

print("icon row runs (y, [(x1,x2),...]) :")
for y, runs in rows:
    print(f"  y={y}: {runs}")

if rows:
    ys = [y for y, _ in rows]
    xs = [x for _, rs in rows for a, b in rs for x in (a, b)]
    print(
        f"icon bbox x={min(xs)}..{max(xs)} ({(max(xs)-min(xs)+1)*S:.1f} dp) "
        f"y={min(ys)}..{max(ys)} ({(max(ys)-min(ys)+1)*S:.1f} dp) "
        f"dx={(min(xs)-LEFT)*S:.1f} dp dyTop={(min(ys)-TOP)*S:.1f} dp"
    )
    # true icon color: darkest 5% pixels
    pts = [
        (x, y)
        for y, rs in rows
        for a, b in rs
        for x in range(a, b + 1)
    ]
    pts.sort(key=lambda p: sum(px[p]))
    core = pts[: max(2, len(pts) // 20)]
    mr = sum(px[p][0] for p in core) // len(core)
    mg = sum(px[p][1] for p in core) // len(core)
    mb = sum(px[p][2] for p in core) // len(core)
    print(f"icon ink core (darkest 5%) = #{mr:02X}{mg:02X}{mb:02X}  min={px[pts[0]]}")

# --- text true color (chars at x 128..198) ---
tpts = [
    (x, y)
    for x in range(125, 202)
    for y in range(TOP, BOT + 1)
    if max(px[x, y]) < thr
]
if tpts:
    tpts.sort(key=lambda p: sum(px[p]))
    tcore = tpts[: max(2, len(tpts) // 20)]
    tr = sum(px[p][0] for p in tcore) // len(tcore)
    tg = sum(px[p][1] for p in tcore) // len(tcore)
    tb = sum(px[p][2] for p in tcore) // len(tcore)
    print(f"text ink core (darkest 5%) = #{tr:02X}{tg:02X}{tb:02X}  min={px[tpts[0]]}")
    txs = [p[0] for p in tpts]
    tys = [p[1] for p in tpts]
    print(
        f"text bbox x={min(txs)}..{max(txs)} y={min(tys)}..{max(tys)} "
        f"h={(max(tys)-min(tys)+1)*S:.1f} dp dyTop={(min(tys)-TOP)*S:.1f}"
    )
