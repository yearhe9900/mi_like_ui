# -*- coding: utf-8 -*-
"""Round 7: 修正暗色掩码方向（亮取 lum_min / 暗取 lum_max），按 bbox 取明暗墨色核心。

沿用 r5/r6 结论：栏 y=117..215；亮 左缘27 填充#E7E7E7 页底#F3F3F3；
暗 左缘26 填充#242424 页底#000000；scale=393/881。
"""
from PIL import Image
import statistics as st

CLIP = r"C:\Users\zmt\.workbuddy\clipboard-images"
IMGS = {
    "light": CLIP + r"\clipboard-2026-10-15T14-25-32-210Z-97900053.jpg",
    "dark": CLIP + r"\clipboard-2026-10-15T14-26-19-602Z-fc8225e0.jpg",
}
S = 393.0 / 881
TOP, BOT = 117, 215


def lum(c):
    return (c[0] + c[1] + c[2]) / 3.0


for name, path in IMGS.items():
    im = Image.open(path).convert("RGB")
    px = im.load()
    xl = 27 if name == "light" else 26
    fill = px[int(881 * 0.75), 166]
    fl = lum(fill)
    light_mode = fl > 128
    # 全栏内部极值（避开圆角：x 取中段 0.2W..0.9W）
    vals = [lum(px[xx, yy]) for yy in range(TOP + 2, BOT - 1) for xx in range(176, 792)]
    ext = min(vals) if light_mode else max(vals)
    thr = (fl + ext) / 2
    print(f"\n=== {name}  fill=#{fill[0]:02X}{fill[1]:02X}{fill[2]:02X}  "
          f"lum_ext={ext:.0f} thr={thr:.0f} ===")

    def ink(c):
        l = lum(c)
        return l < thr if light_mode else l > thr

    # 图标 bbox（列/行剖面，范围相对栏左 8..40dp）
    cx0, cx1 = xl + round(8 / S), xl + round(40 / S)
    cols = [xx for xx in range(cx0, cx1)
            if any(ink(px[xx, yy]) for yy in range(TOP + 2, BOT - 1))]
    rows = [yy for yy in range(TOP + 2, BOT - 1)
            if any(ink(px[xx, yy]) for xx in range(xl + round(8 / S), xl + round(40 / S)))]
    print(f"图标 bbox x={cols[0]}..{cols[-1]} ({(cols[-1]-cols[0]+1)*S:.1f}dp, "
          f"dx={(cols[0]-xl)*S:.1f}dp)  y={rows[0]}..{rows[-1]} "
          f"({(rows[-1]-rows[0]+1)*S:.1f}dp, dyTop={(rows[0]-TOP)*S:.1f}dp)")

    # 文字 bbox（列剖面 40..100dp）
    tx0, tx1 = xl + round(40 / S), xl + round(100 / S)
    tcols = [xx for xx in range(tx0, tx1)
             if any(ink(px[xx, yy]) for yy in range(TOP + 2, BOT - 1))]
    trows = [yy for yy in range(TOP + 2, BOT - 1)
             if any(ink(px[xx, yy]) for xx in range(tx0, tx1))]
    if tcols:
        # 分段（字元）
        runs, cur = [], [tcols[0], tcols[0]]
        for x in tcols[1:]:
            if x == cur[1] + 1:
                cur[1] = x
            else:
                runs.append(tuple(cur))
                cur = [x, x]
        runs.append(tuple(cur))
        print(f"文字 bbox x={tcols[0]}..{tcols[-1]} y={trows[0]}..{trows[-1]} "
              f"(h={(trows[-1]-trows[0]+1)*S:.1f}dp, dyTop={(trows[0]-TOP)*S:.1f}dp) runs={runs}")
        if len(runs) >= 2:
            print(f"字面 advance={runs[1][0]-runs[0][0]}px ≈ {(runs[1][0]-runs[0][0])*S:.1f}dp")

    # 墨色核心（bbox 内，按模式取最暗/最亮 5%）
    def core(x0, x1, y0, y1, label):
        pts = [px[xx, yy] for yy in range(y0, y1 + 1) for xx in range(x0, x1) if ink(px[xx, yy])]
        if not pts:
            print(label, "no ink")
            return
        pts.sort(key=lum, reverse=not light_mode)
        n = max(2, len(pts) // 20)
        c = pts[:n]
        med = int(st.median([p[0] for p in c]))
        print(f"{label}: n_ink={len(pts)}  core=#{med:02X}{med:02X}{med:02X}  extreme={c[0][0]}")

    core(cols[0], cols[-1] + 1, rows[0], rows[-1], "图标")
    if tcols:
        core(tcols[0], tcols[-1] + 1, trows[0], trows[-1], "文字")

    # 镜片赤道行笔画
    eq = rows[0] + (rows[-1] - rows[0]) // 3
    rr, cur = [], None
    for xx in range(cols[0] - 3, cols[-1] + 4):
        if ink(px[xx, eq]):
            if cur and xx == cur[1] + 1:
                cur[1] = xx
            else:
                if cur:
                    rr.append(tuple(cur))
                cur = [xx, xx]
    if cur:
        rr.append(tuple(cur))
    print(f"赤道 y={eq} runs={rr} 笔画={[b-a+1 for a,b in rr]}px ≈ "
          f"{[(b-a+1)*S for a,b in rr]}dp")
