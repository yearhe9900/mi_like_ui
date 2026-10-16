# -*- coding: utf-8 -*-
"""像素实测「我的关注」页的蓝色胶囊关注按钮（亮/暗两张参考图）。

分析用脚本（非交付物）：定位蓝按钮连通域，输出 393dp 设计宽下的几何、
填充色、按钮文字色/字高，以及页面底色。
"""
from collections import deque

from PIL import Image

DARK = r"D:\Software\Tencent\WeChat\xwechat_files\wxid_4745747467312_d114\temp\RWTemp\2026-10\9e20f478899dc29eb19741386f9343c8\907229fe989497a039e16fbc8cd50472.jpg"
LIGHT = r"D:\Software\Tencent\WeChat\xwechat_files\wxid_4745747467312_d114\temp\RWTemp\2026-10\9e20f478899dc29eb19741386f9343c8\e5968ff0d91559cf6ad0bccdff0b1b30.jpg"


def is_blue(c):
    r, g, b = c
    return b > 170 and b - r > 60 and b - g > 40 and r < 160


def clusters(mask, W, H, min_area=800):
    seen = [[False] * W for _ in range(H)]
    out = []
    for y in range(H):
        row = mask[y]
        for x in range(W):
            if row[x] and not seen[y][x]:
                q = deque([(y, x)])
                seen[y][x] = True
                pix = []
                while q:
                    cy, cx = q.popleft()
                    pix.append((cy, cx))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < H and 0 <= nx < W and mask[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            q.append((ny, nx))
                if len(pix) >= min_area:
                    ys = [p[0] for p in pix]
                    xs = [p[1] for p in pix]
                    out.append((min(ys), min(xs), max(ys), max(xs), pix))
    return out


def med(vals):
    s = sorted(vals)
    return s[len(s) // 2]


def measure(path, tag):
    im = Image.open(path).convert("RGB")
    W, H = im.size
    S = 393.0 / W
    px = im.load()
    print(f"\n=== {tag}  SIZE={W}x{H}  scale={S:.5f} dp/px ===")

    # 页底色：取列表区域右缘内侧一列的中位数（避开按钮）
    bg = [px[W - 6, y] for y in range(int(H * 0.25), int(H * 0.9), 7)]
    print(f"page bg  = #{med([c[0] for c in bg]):02X}{med([c[1] for c in bg]):02X}{med([c[2] for c in bg]):02X}")

    mask = [[is_blue(px[x, y]) for x in range(W)] for y in range(H)]
    boxes = clusters(mask, W, H)
    print(f"blue clusters = {len(boxes)}")
    if not boxes:
        return
    # 取第 2 个按钮（第 1 个可能被状态栏/裁切影响）——所有按钮同规格
    for i, (y0, x0, y1, x1, pix) in enumerate(boxes[:3]):
        w, h = x1 - x0 + 1, y1 - y0 + 1
        # 填充色：取按钮中心 40% 区域的中位数（避开文字）
        cx0, cx1 = x0 + int(w * 0.08), x1 - int(w * 0.08)
        cy0, cy1 = y0 + int(h * 0.30), y1 - int(h * 0.30)
        core = [px[x, y] for y in range(cy0, cy1 + 1) for x in range(cx0, cx1 + 1)
                if not (abs(px[x, y][0] - 255) < 40 and abs(px[x, y][1] - 255) < 40 and abs(px[x, y][2] - 255) < 40)]
        if core:
            fr, fg, fb = med([c[0] for c in core]), med([c[1] for c in core]), med([c[2] for c in core])
            fill = f"#{fr:02X}{fg:02X}{fb:02X}"
        else:
            fill = "?"
        # 按钮内白字 bbox
        whites = [(y, x) for (y, x) in pix if px[x, y][0] > 225 and px[x, y][1] > 225 and px[x, y][2] > 225]
        if whites:
            wy0 = min(p[0] for p in whites); wy1 = max(p[0] for p in whites)
            wx0 = min(p[1] for p in whites); wx1 = max(p[1] for p in whites)
            txt = (f"txt h={wy1 - wy0 + 1}px({(wy1 - wy0 + 1) * S:.1f}dp) "
                   f"w={wx1 - wx0 + 1}px({(wx1 - wx0 + 1) * S:.1f}dp)")
        else:
            txt = "txt ?"
        print(f"  btn{i}: bbox=({x0},{y0})-({x1},{y1}) {w}x{h}px = {w * S:.1f}x{h * S:.1f}dp  "
              f"R>=h/2  fill={fill}  {txt}  right_gap={(W - 1 - x1) * S:.1f}dp")


for p, t in ((DARK, "DARK"), (LIGHT, "LIGHT")):
    measure(p, t)
