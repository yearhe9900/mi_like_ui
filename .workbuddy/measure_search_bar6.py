# -*- coding: utf-8 -*-
"""Round 6: 字面 advance / 明暗墨色核心 / 图标笔画宽（亮暗双图交叉实测）。

图片（剪贴板，均 881x1920）：
  light = clipboard-2026-10-15T14-25-32-210Z-97900053.jpg
  dark  = clipboard-2026-10-15T14-26-19-602Z-fc8225e0.jpg
栏体：y=117..215，左缘 x=27(亮)/26(暗)，填充 亮#E7E7E7/暗#242424。
"""
from PIL import Image
import statistics as st

CLIP = r"C:\Users\zmt\.workbuddy\clipboard-images"
IMGS = {
    "light": (CLIP + r"\clipboard-2026-10-15T14-25-32-210Z-97900053.jpg", 27, 0),
    "dark": (CLIP + r"\clipboard-2026-10-15T14-26-19-602Z-fc8225e0.jpg", 26, 255),
}
S = 393.0 / 881
TOP, BOT = 117, 215


def lum(c):
    return (c[0] + c[1] + c[2]) / 3.0


def analyze(name, path, xl, tint):
    im = Image.open(path).convert("RGB")
    px = im.load()
    fill = px[int(881 * 0.75), 166]
    ink_is_dark = lum(fill) > 128  # 亮栏：墨比填充暗；暗栏：墨比填充亮
    print(f"\n=== {name}  fill=#{fill[0]:02X}{fill[1]:02X}{fill[2]:02X} ===")

    # 文本列剖面：x=110..215, y=130..200，50% 覆盖阈值
    lums = []
    for yy in range(130, 201):
        for xx in range(110, 216):
            lums.append(lum(px[xx, yy]))
    mn = min(lums)
    thr = (lum(fill) + mn) / 2
    print(f"text region lum_min={mn:.0f} thr={thr:.0f}")

    def ink(c):
        return lum(c) < thr if ink_is_dark else lum(c) > thr

    cols = []
    for xx in range(110, 216):
        n = sum(1 for yy in range(130, 201) if ink(px[xx, yy]))
        cols.append((xx, n))
    # 列 run（字元分段）
    runs, cur = [], None
    for xx, n in cols:
        if n > 0 and cur is None:
            cur = [xx, xx]
        elif n > 0:
            cur[1] = xx
        elif cur:
            runs.append(tuple(cur))
            cur = None
    if cur:
        runs.append(tuple(cur))
    print("文字列 run:", runs)
    if len(runs) >= 2:
        adv = (runs[1][0] - runs[0][0]) * S
        print(f"字面 advance = {runs[1][0]-runs[0][0]}px ≈ {adv:.1f}dp  (ink_h 见下)")

    # 文字行剖面（行 run = 字高）
    rows = []
    for yy in range(TOP, BOT + 1):
        n = sum(1 for xx in range(110, 216) if ink(px[xx, yy]))
        rows.append((yy, n))
    ys = [yy for yy, n in rows if n > 0]
    if ys:
        print(f"文字 ink 行 y={ys[0]}..{ys[-1]}  h={ys[-1]-ys[0]+1}px ≈ {(ys[-1]-ys[0]+1)*S:.1f}dp")

    # 墨色核心：区域内按亮度排序取核心 5%（亮栏取最暗 / 暗栏取最亮）
    def core(x0, x1, label):
        pts = [px[xx, yy] for yy in range(TOP + 2, BOT - 1) for xx in range(x0, x1)]
        pts.sort(key=lum, reverse=not ink_is_dark)
        n = max(2, len(pts) // 20)
        c = pts[:n]
        r = int(st.median([p[0] for p in c]))
        g = int(st.median([p[1] for p in c]))
        b = int(st.median([p[2] for p in c]))
        print(f"{label}: core=#{r:02X}{g:02X}{b:02X}  extreme={c[0]}")

    # 图标区 / 文字区（相对栏左 dx）
    ix0 = xl + round(15.2 / S)
    ix1 = xl + round(33.0 / S)
    tx0 = xl + round(45.1 / S)
    tx1 = xl + round(80.0 / S)
    core(ix0, ix1 + 1, "图标墨色")
    core(tx0, tx1, "文字墨色")

    # 图标列/行剖面（几何 + 笔画宽）
    icols = []
    for xx in range(ix0 - 4, ix1 + 5):
        n = sum(1 for yy in range(TOP, BOT + 1) if ink(px[xx, yy]))
        icols.append((xx, n))
    xs = [xx for xx, n in icols if n > 0]
    print(f"图标列 ink x={xs[0]}..{xs[-1]}  w={xs[-1]-xs[0]+1}px ≈ {(xs[-1]-xs[0]+1)*S:.1f}dp"
          f"  dx={(xs[0]-xl)*S:.1f}dp")
    irows = []
    for yy in range(TOP, BOT + 1):
        n = sum(1 for xx in range(ix0, ix1 + 1) if ink(px[xx, yy]))
        irows.append((yy, n))
    ys = [yy for yy, n in irows if n > 0]
    print(f"图标行 ink y={ys[0]}..{ys[-1]}  h={ys[-1]-ys[0]+1}px ≈ {(ys[-1]-ys[0]+1)*S:.1f}dp"
          f"  dyTop={(ys[0]-TOP)*S:.1f}dp  垂心偏移={((ys[0]+ys[-1])/2-(TOP+BOT)/2)*S:+.1f}dp")

    # 镜片圆赤道行（图标上半段中部）的左右环 run 宽 = 笔画宽
    eq = ys[0] + (ys[-1] - ys[0]) // 3
    row = [xx for xx in range(ix0 - 4, ix1 + 5) if ink(px[xx, eq])]
    runs2, cur = [], None
    for xx in row:
        if cur and xx == cur[1] + 1:
            cur[1] = xx
        else:
            if cur:
                runs2.append(tuple(cur))
            cur = [xx, xx]
    if cur:
        runs2.append(tuple(cur))
    print(f"赤道行 y={eq} 环 run: {runs2}  笔画宽={[(b-a+1) for a, b in runs2]}px"
          f" ≈ {[(b-a+1)*S for a, b in runs2]}dp")


for k, (p, xl, tint) in IMGS.items():
    analyze(k, p, xl, tint)
