# -*- coding: utf-8 -*-
"""Round 5: 用亮/暗两张完整分类页截图实测搜索栏填充与页底，反推半透明 alpha。

目标：判定搜索栏半透明填充的 alpha 取值（亮：黑@? 叠页底；暗：白@? 叠页底），
验证能否与 MiTransparencyTokens.fillAlphaSubtle(15) 同源。
图片来源（剪贴板）：
  light = clipboard-2026-10-15T14-25-32-210Z-97900053.jpg
  dark  = clipboard-2026-10-15T14-26-19-602Z-fc8225e0.jpg
"""
from PIL import Image
import statistics as st

CLIP = r"C:\Users\zmt\.workbuddy\clipboard-images"
IMGS = {
    "light": CLIP + r"\clipboard-2026-10-15T14-25-32-210Z-97900053.jpg",
    "dark": CLIP + r"\clipboard-2026-10-15T14-26-19-602Z-fc8225e0.jpg",
}
SCALE = 393.0  # dp 设计宽


def hexs(c):
    return "#%02X%02X%02X" % (c[0], c[1], c[2])


def lum(c):
    return (c[0] + c[1] + c[2]) / 3.0


def probe(path, name):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    px = im.load()
    s = SCALE / W
    print(f"\n=== {name}  {W}x{H}  scale={s:.5f} dp/px ===")

    # 1) 在 0.75W 列（栏内右段、无图标无文字）自上而下找搜索栏填充 run
    x = int(W * 0.75)
    # 页底：取顶部状态栏区背景的众数（y=0.010H..0.030H）
    def modal(y0, y1, x0=0, x1=None):
        x1 = x1 or W
        cnt = {}
        for yy in range(int(y0 * H), int(y1 * H)):
            for xx in range(x0, x1, max(1, (x1 - x0) // 60)):
                c = px[xx, yy]
                cnt[c] = cnt.get(c, 0) + 1
        return max(cnt.items(), key=lambda kv: kv[1])[0]

    page = modal(0.010, 0.030)
    print("页底(顶区众数) =", hexs(page))

    # 搜索栏大约在 y=0.045H..0.13H（缩略图 60..130 / 1076）。扫该区间找与页底不同的连续 run
    y0, y1 = int(0.035 * H), int(0.150 * H)
    run = None
    y = y0
    while y < y1:
        c = px[x, y]
        if max(abs(c[i] - page[i]) for i in range(3)) >= 6:
            yy = y
            while yy < y1 and max(abs(px[x, yy][i] - page[i]) for i in range(3)) >= 6:
                yy += 1
            if run is None or (yy - y) > (run[1] - run[0]):
                run = (y, yy - 1)
            y = yy
        else:
            y += 1
    assert run, "未找到栏填充 run"
    top, bot = run
    hpx = bot - top + 1
    print(f"栏纵向 run y={top}..{bot}  h={hpx}px ≈ {hpx*s:.1f}dp  (rowCenter={(top+bot)//2})")

    # 2) 栏水平范围：在栏中心行走，从左/右向内找填充
    yc = (top + bot) // 2
    xl = 0
    while xl < W and max(abs(px[xl, yc][i] - page[i]) for i in range(3)) < 6:
        xl += 1
    xr = W - 1
    while xr > 0 and max(abs(px[xr, yc][i] - page[i]) for i in range(3)) < 6:
        xr -= 1
    print(f"栏横向 x={xl}..{xr}  w={xr-xl+1}px ≈ {(xr-xl+1)*s:.1f}dp  左inset={xl*s:.1f}dp 右inset={(W-1-xr)*s:.1f}dp")

    # 3) 填充取值：栏内右段矩形中位数（避开图标/文字/圆角）
    x0, x1 = int(W * 0.55), int(W * 0.90)
    y0r, y1r = top + max(2, int(hpx * 0.15)), bot - max(2, int(hpx * 0.15))
    fill_px = [px[xx, yy] for yy in range(y0r, y1r, 2) for xx in range(x0, x1, 2)]
    fr = int(st.median([c[0] for c in fill_px]))
    fg_ = int(st.median([c[1] for c in fill_px]))
    fb = int(st.median([c[2] for c in fill_px]))
    fill = (fr, fg_, fb)
    print(f"填充(中位数) = {hexs(fill)}  n={len(fill_px)}")

    # 页底也取栏邻近（栏上方 8px、栏下方到胶囊行之间）
    bg_near = px[int(W * 0.75), max(0, top - 8)]
    print(f"页底(栏上8px) = {hexs(bg_near)}")

    # 4) 图标 / 占位文字墨色（相对栏左，dx 与 881 图同比例的 dp 值直接换算）
    # 图标 dx=15.2..33.0dp, 文字 dx=45.1..67dp（相对栏左），全高内
    def ink(dx0, dx1, label):
        xs0 = xl + int(dx0 / s)
        xs1 = min(xr, xl + int(dx1 / s))
        pts = [px[xx, yy] for yy in range(top + 2, bot - 1) for xx in range(xs0, xs1)]
        pts.sort(key=lum)
        n = max(2, len(pts) // 20)
        core = pts[:n]
        r = int(st.median([c[0] for c in core]))
        g = int(st.median([c[1] for c in core]))
        b = int(st.median([c[2] for c in core]))
        print(f"{label} 墨色核心(darkest5%) = #{r:02X}{g:02X}{b:02X}  min={min(lum(c) for c in core):.0f}")

    ink(15.2, 33.0, "图标")
    ink(45.1, 90.0, "文字")

    # 5) 反推 alpha（假设填充为纯黑/纯白的半透明层，平底合成）
    return {"W": W, "H": H, "s": s, "page": page, "fill": fill, "top": top, "bot": bot}


def implied(bg, fill, fg):
    """fill = bg*(1-a) + fg*a  =>  a (0-255)"""
    a = []
    for i in range(3):
        if fg[i] == bg[i]:
            a.append(None)
            continue
        a.append((fill[i] - bg[i]) / (fg[i] - bg[i]) * 255)
    return a


res = {k: probe(p, k) for k, p in IMGS.items()}

print("\n=== 反推 alpha（平底合成 fill = bg*(1-a) + fg*a） ===")
for name, fg in (("纯黑", (0, 0, 0)), ("纯白", (255, 255, 255))):
    for k in res:
        r = res[k]
        a = implied(r["page"], r["fill"], fg)
        if all(v is not None for v in a):
            print(f"{k:5s} + {name}: a = {a[0]:.1f}/{a[1]:.1f}/{a[2]:.1f}  (整数≈{round(st.mean(a))})")

print("\nMiTransparencyTokens.fillAlphaSubtle = 15 合成检验：")
for k in res:
    r = res[k]
    bg, fg = r["page"], (0, 0, 0)
    if k == "dark":
        fg = (255, 255, 255)
    comp = tuple(round(bg[i] * (1 - 15 / 255) + fg[i] * (15 / 255)) for i in range(3))
    print(f"{k:5s}: 页底{hexs(bg)} @a=15 → 合成{hexs(comp)}  实测{hexs(r['fill'])}")
