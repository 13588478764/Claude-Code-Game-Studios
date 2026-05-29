#!/bin/bash
# =============================================================================
# 按钮纹理裁剪脚本
# 从 1024×1024 出图裁剪中心横条 → 512×128
# 需要 ImageMagick (magick/convert)
#
# 用法:
#   bash tools/comfyui/crop_buttons.sh          # 预览
#   bash tools/comfyui/crop_buttons.sh --commit  # 执行
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/assets/ui/frames"
COMFY_BTN_DIR="${COMFY_OUT:-/Users/lingang/Downloads/workspace/ComfyUI/ComfyUI-master/output}/button_textures_512"

DRY_RUN=1
[[ "$1" == "--commit" ]] && DRY_RUN=0

if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
    echo "错误: 需要 ImageMagick"
    exit 1
fi
CONVERT_CMD="magick"
command -v magick &>/dev/null || CONVERT_CMD="convert"

if [[ ! -d "$COMFY_BTN_DIR" ]]; then
    echo "错误: 按钮纹理目录不存在: $COMFY_BTN_DIR"
    echo "请先在 ComfyUI 中运行 W23 工作流"
    exit 1
fi

echo "按钮纹理裁剪: 512×512 → 512×128 (中心横条)"

for src in "$COMFY_BTN_DIR"/*.png; do
    [[ ! -f "$src" ]] && continue
    base=$(basename "$src" | sed -E 's/_[0-9]{5}_\.png$/.png/')
    dst="${SRC_DIR}/${base}"

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [预览] $(basename "$src") → $base (512×128)"
    else
        # 裁剪中心横条: 从 y=192 开始取 128px 高 (512 的中心 25%)
        $CONVERT_CMD "$src" -gravity Center -crop 512x128+0+0 +repage "$dst"
        echo "  ✓ $base"
    fi
done

if [[ $DRY_RUN -eq 1 ]]; then
    echo "预览无误后执行: $0 --commit"
fi
