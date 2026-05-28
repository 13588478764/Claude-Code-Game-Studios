#!/bin/bash
# =============================================================================
# 队伍头像生成脚本
# 从 assets/ui/portraits/ 已有 512×512 立绘裁剪中心区域 → 60×60 圆角头像
# 不需要 ComfyUI，仅需 ImageMagick (magick/convert)
#
# 用法:
#   bash tools/comfyui/generate_party_portraits.sh          # 预览
#   bash tools/comfyui/generate_party_portraits.sh --commit  # 执行
# =============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/assets/ui/portraits"
DST_DIR="${PROJECT_ROOT}/assets/ui/party_portraits"

DRY_RUN=1
[[ "$1" == "--commit" ]] && DRY_RUN=0

# 检查 ImageMagick
if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
    echo "错误: 需要 ImageMagick (magick 或 convert 命令)"
    echo "  macOS: brew install imagemagick"
    exit 1
fi

# 选择命令
CONVERT_CMD="magick"
command -v magick &>/dev/null || CONVERT_CMD="convert"

# 立绘名 → 队伍头像名映射
declare -A PORTRAIT_MAP=(
    ["portrait_protagonist_male"]="party_member_protagonist_male"
    ["portrait_protagonist_female"]="party_member_protagonist_female"
    ["portrait_yunzhonghe"]="party_member_yunzhonghe"
    ["portrait_liuruyan"]="party_member_liuruyan"
    ["portrait_xuanjizi"]="party_member_xuanjizi"
    ["portrait_xiaohanye"]="party_member_xiaohanye"
    ["portrait_murongxue"]="party_member_murongxue"
    ["portrait_tiewushuang"]="party_member_tiewushuang"
    ["portrait_lingxi"]="party_member_lingxi"
    ["portrait_guchangge"]="party_member_guchangge"
    ["portrait_chutiannan"]="party_member_chutiannan"
    ["portrait_shenqingluo"]="party_member_shenqingluo"
)

echo "╔══════════════════════════════════════╗"
echo "║   队伍头像生成: 立绘 → 60×60 头像    ║"
echo "╚══════════════════════════════════════╝"

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] 预览模式"
else
    echo "[COMMIT] 执行模式"
    mkdir -p "$DST_DIR"
fi

count=0
for src_name in "${!PORTRAIT_MAP[@]}"; do
    src_file="${SRC_DIR}/${src_name}.png"
    dst_name="${PORTRAIT_MAP[$src_name]}"
    dst_file="${DST_DIR}/${dst_name}.png"

    if [[ ! -f "$src_file" ]]; then
        echo "  ⚠ 源文件不存在: $src_name.png"
        continue
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [预览] $src_name → $dst_name (60×60)"
    else
        # 裁剪中心 70% 区域 (头部为主) → 缩放到 60×60
        $CONVERT_CMD "$src_file" \
            -gravity North \
            -crop 70%x70%+0+0 \
            +repage \
            -resize 60x60 \
            -quality 95 \
            "$dst_file"
        echo "  ✓ $dst_name.png"
    fi
    ((count++))
done

echo ""
echo "共 $count 个头像"
if [[ $DRY_RUN -eq 1 ]]; then
    echo "预览无误后执行: $0 --commit"
fi
