#!/usr/bin/env python3
# =============================================================================
# VFX 战斗特效纹理标准化处理（Part D，20 张）
#
# 与 process_ai_assets.py（立绘流程）的差异：
#   1. 黑底 → 透明：unmultiply（alpha=max(r,g,b)，rgb/=alpha）——亮度即透明度，
#      黑底发光纹理的标准去黑算法，边缘无灰痕
#   2. 游戏图为 256×256（非 512）——代码中最大显示 180px
#   3. 按子目录分发 assets/ui/vfx/{weapon,element,common}/——
#      路径为 combat_vfx_manager.gd 硬编码引用
#
# 流程：备份原图 → 去黑转透明 → trim（alpha 阈值）→ 等比缩放居中放方形画布
#       → 1024 母版（覆盖 vfx_1024/）+ 256 游戏图（分发三子目录）
#
# 用法:
#   python3 tools/process_vfx_assets.py
#
# 依赖: Pillow + numpy
# 规格: assets/specs/ui/11-portraits-act1-expansion.md Part D
# =============================================================================

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SRC_DIR = Path("assets/ui/_masters/vfx_1024")          # 交付/母版目录（原地覆盖）
BACKUP_DIR = Path("assets/ui/_masters/vfx_2048_src")   # 原图备份
GAME_ROOT = Path("assets/ui/vfx")                      # 游戏图根目录

MASTER_SIZE = 1024
GAME_SIZE = 256
CONTENT_RATIO = 0.97    # 内容最长边占画布比例（留呼吸边距）
ALPHA_THRESHOLD = 8     # alpha > 8 才视为有效内容（防噪点影响 bbox）
ALPHA_FLOOR = 0.06      # 去黑后 alpha 低于此值置 0（黑底非纯黑，噪点雾约 4% 亮度）

# 文件名 → 子目录（combat_vfx_manager.gd 硬编码路径，不可改动）
SUBDIRS = {
    "weapon": ["vfx_slash_arc", "vfx_fist_wave", "vfx_palm_wind", "vfx_staff_impact"],
    "element": ["vfx_fire_burst", "vfx_ice_crystal", "vfx_lightning_bolt",
                "vfx_poison_cloud", "vfx_metal_glint", "vfx_dark_vortex",
                "vfx_light_burst", "vfx_water_splash", "vfx_wood_thorns",
                "vfx_earth_crack", "vfx_wind_spiral", "vfx_energy_default"],
    "common": ["vfx_particle_dot", "vfx_hit_spark", "vfx_critical_flash", "vfx_glow_ring"],
}


def black_to_alpha(img: Image.Image) -> Image.Image:
    """黑底转透明（unmultiply）。对已是透明底的图原样返回。"""
    rgba = np.asarray(img.convert("RGBA")).astype(np.float32) / 255.0
    # 已有透明底（存在近全透明像素）→ 不处理
    if rgba[..., 3].min() < 0.05:
        return img.convert("RGBA")
    rgb = rgba[..., :3]
    alpha = rgb.max(axis=2)                       # 亮度即透明度
    safe = np.where(alpha > 1e-6, alpha, 1.0)
    rgb_out = np.clip(rgb / safe[..., None], 0.0, 1.0)   # 还原发光体本色
    alpha = np.where(alpha < ALPHA_FLOOR, 0.0, alpha)    # 噪点雾截断
    out = np.dstack([rgb_out, alpha])
    return Image.fromarray((out * 255).astype(np.uint8), "RGBA")


def process_one(name: str, subdir: str) -> str:
    src = SRC_DIR / f"{name}.png"
    origin = BACKUP_DIR / f"{name}.png"   # 优先从备份取纯净原图（母版目录可能已被处理过）
    if not origin.exists() and not src.exists():
        return f"{name}: 源文件缺失，跳过"

    # 1. 备份（仅首次）
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    if src.exists() and not origin.exists():
        shutil.copy2(src, origin)

    img = Image.open(origin if origin.exists() else src)
    orig_size = img.size

    # 2. 去黑转透明
    img = black_to_alpha(img)

    # 3. trim 透明边距
    mask = img.getchannel("A").point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
    bbox = mask.getbbox()
    if bbox:
        img = img.crop(bbox)

    # 4. 等比缩放 → 居中方形画布
    target = int(MASTER_SIZE * CONTENT_RATIO)
    img.thumbnail((target, target), Image.LANCZOS)
    canvas = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    canvas.paste(img, ((MASTER_SIZE - img.width) // 2, (MASTER_SIZE - img.height) // 2))

    # 5. 输出：1024 母版 + 256 游戏图（子目录）
    canvas.save(src, "PNG")
    game_dir = GAME_ROOT / subdir
    game_dir.mkdir(parents=True, exist_ok=True)
    canvas.resize((GAME_SIZE, GAME_SIZE), Image.LANCZOS).save(game_dir / src.name, "PNG")

    return f"{name}: {orig_size[0]}x{orig_size[1]} -> trim{bbox} -> {subdir}/ 1024+256"


def main() -> None:
    ok, failed = 0, []
    for subdir, names in SUBDIRS.items():
        for name in names:
            try:
                print(process_one(name, subdir))
                ok += 1
            except Exception as e:  # noqa: BLE001 - 批量处理跳过单张失败
                failed.append(f"{name} ({e})")
    print(f"\n完成: {ok}/20 成功")
    if failed:
        print("失败清单:")
        for f in failed:
            print(f"  - {f}")
        sys.exit(1)


if __name__ == "__main__":
    main()
