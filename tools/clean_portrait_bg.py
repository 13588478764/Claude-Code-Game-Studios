#!/usr/bin/env python3
# =============================================================================
# 一次性清理脚本：处理 Part A 两张背景不干净的立绘（2026-07-21）
#
# - portrait_tangxiaoqi.png：浅灰白底未去净 → 边缘 BFS 泛洪去除连通浅色背景
#   （容差 48；仅去除与图像边缘连通的近背景色区域，不误伤人物内部浅色件）
# - portrait_saodidaoren.png：全图一层 8%~18% 淡雾 → alpha<64 截断为 0
#
# 输入为 2048 备份原图，输出覆盖 1024 母版 + 512 游戏图（同 process_ai_assets.py）。
# 若 tangxiaoqi 色键抠图边缘效果不佳，应在生成工具中重新导出透明底版本。
# =============================================================================

from collections import Counter, deque
from pathlib import Path

from PIL import Image

SRC_DIR = Path("assets/ui/_masters/npc_secondary_2048_src")
MASTER_DIR = Path("assets/ui/_masters/npc_secondary_1024")
GAME_DIR = Path("assets/ui/portraits")
MASTER_SIZE, GAME_SIZE, CONTENT_RATIO = 1024, 512, 0.97


def estimate_bg_color(img):
    """取边缘不透明像素的众数色（32 级量化）作为背景色"""
    w, h = img.size
    pixels = img.load()
    samples = []
    for x in range(0, w, 10):
        samples += [pixels[x, 0], pixels[x, h - 1]]
    for y in range(0, h, 10):
        samples += [pixels[0, y], pixels[w - 1, y]]
    opaque = [p[:3] for p in samples if p[3] > 200]
    cnt = Counter((r // 32 * 32, g // 32 * 32, b // 32 * 32) for r, g, b in opaque)
    q = cnt.most_common(1)[0][0]
    return (q[0] + 16, q[1] + 16, q[2] + 16)  # 反量化为簇中心


def flood_clear(img, tol=48):
    """从全部边缘像素 BFS，将连通且接近背景色的区域置为全透明"""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    bg = estimate_bg_color(img)
    tol2 = tol * tol * 3  # RGB 欧氏距离平方（×3 通道）

    def is_bg(p):
        return (p[0] - bg[0]) ** 2 + (p[1] - bg[1]) ** 2 + (p[2] - bg[2]) ** 2 <= tol2

    visited = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if is_bg(px[x, y]):
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if is_bg(px[x, y]):
                q.append((x, y))

    cleared = 0
    while q:
        x, y = q.popleft()
        idx = y * w + x
        if visited[idx]:
            continue
        visited[idx] = 1
        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, 0)
        cleared += 1
        for nx, ny in ((x+1, y), (x-1, y), (x, y+1), (x, y-1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny * w + nx] and is_bg(px[nx, ny]):
                q.append((nx, ny))
    print(f"  背景色≈{bg}, 清除 {cleared}px ({cleared*100//(w*h)}%)")
    return img


def alpha_cut(img, floor=64):
    """alpha < floor 截断为 0（清除全图淡雾）"""
    img = img.convert("RGBA")
    r, g, b, a = img.split()
    a = a.point(lambda v: 0 if v < floor else v)
    return Image.merge("RGBA", (r, g, b, a))


def finish(img, name):
    """trim → 等比缩放 → 居中 1024 画布 → 输出母版 + 游戏图"""
    mask = img.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    bbox = mask.getbbox()
    if bbox:
        img = img.crop(bbox)
    target = int(MASTER_SIZE * CONTENT_RATIO)
    img.thumbnail((target, target), Image.LANCZOS)
    canvas = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((MASTER_SIZE - img.width) // 2, (MASTER_SIZE - img.height) // 2))
    canvas.save(MASTER_DIR / name, "PNG")
    canvas.resize((GAME_SIZE, GAME_SIZE), Image.LANCZOS).save(GAME_DIR / name, "PNG")
    print(f"  trim{bbox} -> 1024 + 512 已输出")


print("[1/2] portrait_tangxiaoqi.png — 泛洪去浅灰白底")
finish(flood_clear(Image.open(SRC_DIR / "portrait_tangxiaoqi.png")), "portrait_tangxiaoqi.png")

print("[2/2] portrait_saodidaoren.png — alpha 截断去淡雾")
finish(alpha_cut(Image.open(SRC_DIR / "portrait_saodidaoren.png")), "portrait_saodidaoren.png")

print("完成")
