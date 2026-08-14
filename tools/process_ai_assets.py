#!/usr/bin/env python3
# =============================================================================
# 商业 AI 工具生成资产的标准化处理脚本
#
# 流程：备份原图 → trim 透明边距（alpha 阈值）→ 等比缩放 → 居中放方形透明画布
#       → 输出 1024 母版（覆盖 masters 目录）+ 512 游戏图（输出到游戏目录）
#
# 用法（Part A NPC 立绘，本次）:
#   python3 tools/process_ai_assets.py \
#       --src assets/ui/_masters/npc_secondary_1024 \
#       --game-out assets/ui/portraits \
#       --backup assets/ui/_masters/npc_secondary_2048_src
#
# 用法（Part B 敌人立绘，未来）:
#   python3 tools/process_ai_assets.py \
#       --src assets/ui/_masters/portraits_enemies_1024 \
#       --game-out assets/ui/enemy_portraits \
#       --backup assets/ui/_masters/portraits_enemies_2048_src \
#       --files enemy_wild_wolf.png enemy_mountain_wildman.png ...
#
# 依赖: Pillow（pip install pillow）；无 Pillow 时回退方案见
#       assets/specs/ui/11-portraits-act1-expansion.md 的 sips 命令
# =============================================================================

import argparse
import shutil
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("错误: 需要 Pillow（pip install pillow），或改用 sips 手动缩放")

MASTER_SIZE = 1024   # 母版边长
GAME_SIZE = 512      # 游戏图边长
CONTENT_RATIO = 0.97  # trim 后内容最长边占画布比例（留 3% 呼吸边距）
ALPHA_THRESHOLD = 8   # alpha > 8 才视为有效内容（防杂散半透明噪点影响 bbox）

# Part A 默认文件清单（10 张 NPC 立绘，见 11-portraits-act1-expansion.md）
DEFAULT_FILES = [
    "portrait_luping.png", "portrait_xuanchengzi.png", "portrait_gufei.png",
    "portrait_saodidaoren.png", "portrait_laozhou.png", "portrait_jinwanguan.png",
    "portrait_mystery_merchant.png", "portrait_tangxiaoqi.png",
    "portrait_baixiaosheng.png", "portrait_sunergou.png",
]


def process_one(src_path: Path, backup_dir: Path, game_dir: Path) -> str:
    # 1. 备份原图（仅首次，不覆盖已有备份）
    backup_dir.mkdir(parents=True, exist_ok=True)
    bak = backup_dir / src_path.name
    if not bak.exists():
        shutil.copy2(src_path, bak)

    # 2. 打开并转 RGBA
    img = Image.open(src_path).convert("RGBA")
    orig_size = img.size

    # 3. alpha 阈值 bbox → trim 透明边距
    alpha = img.getchannel("A")
    mask = alpha.point(lambda a: 255 if a > ALPHA_THRESHOLD else 0)
    bbox = mask.getbbox()
    if bbox:
        img = img.crop(bbox)

    # 4. 等比缩放：最长边 → MASTER_SIZE * CONTENT_RATIO
    target = int(MASTER_SIZE * CONTENT_RATIO)
    img.thumbnail((target, target), Image.LANCZOS)

    # 5. 居中粘贴到方形透明画布
    canvas = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), (0, 0, 0, 0))
    offset = ((MASTER_SIZE - img.width) // 2, (MASTER_SIZE - img.height) // 2)
    canvas.paste(img, offset)

    # 6. 输出：1024 母版（覆盖 src）+ 512 游戏图
    canvas.save(src_path, "PNG")
    game_dir.mkdir(parents=True, exist_ok=True)
    canvas.resize((GAME_SIZE, GAME_SIZE), Image.LANCZOS).save(
        game_dir / src_path.name, "PNG")

    return f"{src_path.name}: {orig_size[0]}x{orig_size[1]} -> trim{bbox} -> 1024 + 512"


def main() -> None:
    ap = argparse.ArgumentParser(description="标准化处理 AI 生成立绘")
    ap.add_argument("--src", required=True, type=Path, help="母版目录（原地覆盖为 1024）")
    ap.add_argument("--game-out", required=True, type=Path, help="512 游戏图输出目录")
    ap.add_argument("--backup", required=True, type=Path, help="原图备份目录")
    ap.add_argument("--files", nargs="*", default=None, help="文件名白名单（默认 Part A 10 张）")
    args = ap.parse_args()

    files = args.files if args.files else DEFAULT_FILES
    ok, failed = 0, []
    for name in files:
        src = args.src / name
        if not src.exists():
            failed.append(f"{name} (源文件不存在)")
            continue
        try:
            print(process_one(src, args.backup, args.game_out))
            ok += 1
        except Exception as e:  # noqa: BLE001 - 批量处理需跳过单张失败
            failed.append(f"{name} ({e})")

    print(f"\n完成: {ok}/{len(files)} 成功")
    if failed:
        print("失败清单:")
        for f in failed:
            print(f"  - {f}")
        sys.exit(1)


if __name__ == "__main__":
    main()
