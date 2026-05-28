#!/bin/bash
# =============================================================================
# AI 资源回流脚本 — ComfyUI output/ -> Godot assets/ui/
# 用途: 把生成的图按规范名复制到游戏资源目录，自动去掉 ComfyUI 的 _00001_ 后缀
# 默认 DRY RUN（预览），加 --commit 才真正复制
# =============================================================================

set -e

# ===== 路径配置（可通过环境变量覆盖）=====
COMFY_OUT="${COMFY_OUT:-/Users/lingang/Downloads/workspace/ComfyUI/ComfyUI-master/output}"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ASSETS_UI="${PROJECT_ROOT}/assets/ui"

# ===== 参数解析 =====
DRY_RUN=1
for arg in "$@"; do
    case $arg in
        --commit) DRY_RUN=0 ;;
        --help|-h)
            cat <<EOF
用法: $0 [--commit]

默认是 DRY RUN（预览模式），不会实际复制文件。
加 --commit 才真正执行。

环境变量:
  COMFY_OUT  ComfyUI 输出根目录（默认 /Users/lingang/Downloads/workspace/ComfyUI/ComfyUI-master/output）

示例:
  $0                    # 预览将复制什么
  $0 --commit           # 实际复制
  COMFY_OUT=/other/path $0 --commit
EOF
            exit 0 ;;
    esac
done

# ===== 颜色输出 =====
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ===== 前置检查 =====
if [[ ! -d "$COMFY_OUT" ]]; then
    echo -e "${RED}[错误]${NC} ComfyUI output 目录不存在: $COMFY_OUT"
    echo "       请用环境变量指定: COMFY_OUT=/your/path $0"
    exit 1
fi

# ===== 核心：处理一个类别 =====
# 参数: comfy 子目录 | assets/ui 子目录 | 描述
process_category() {
    local src_subdir="$1"
    local dst_subdir="$2"
    local desc="$3"

    local src_dir="${COMFY_OUT}/${src_subdir}"
    local dst_dir="${ASSETS_UI}/${dst_subdir}"

    # 源目录不存在直接跳过（说明该类别还没出图）
    [[ ! -d "$src_dir" ]] && return 0

    echo ""
    echo -e "${BLUE}═══ ${desc} ═══${NC}"
    echo "  源: $src_dir"
    echo "  目标: $dst_dir"

    # 列出所有 .png 的去后缀基础名
    local bases
    bases=$(ls "$src_dir"/*.png 2>/dev/null | \
            sed -E 's|.*/||; s|_[0-9]{5}_\.png$||' | \
            sort -u)

    if [[ -z "$bases" ]]; then
        echo "  (空)"
        return 0
    fi

    mkdir -p "$dst_dir"

    local count=0
    local skipped=0
    while IFS= read -r base; do
        [[ -z "$base" ]] && continue
        # 取该基础名最新版本（按 mtime 排序，取第一个）
        local latest
        latest=$(ls -t "$src_dir/${base}_"*.png 2>/dev/null | head -1)
        [[ -z "$latest" ]] && continue

        local dst_file="${dst_dir}/${base}.png"

        # 跳过未更新的文件（目标存在且不比源旧）
        if [[ -f "$dst_file" && ! "$latest" -nt "$dst_file" ]]; then
            ((skipped++))
            continue
        fi

        if [[ $DRY_RUN -eq 1 ]]; then
            echo -e "  ${YELLOW}[预览]${NC} $(basename "$latest") -> ${base}.png"
        else
            cp "$latest" "$dst_file"
            echo -e "  ${GREEN}✓${NC} ${base}.png"
        fi
        ((count++))
    done <<< "$bases"

    if [[ $skipped -gt 0 ]]; then
        echo -e "  ${count} 个新/更新, ${skipped} 个跳过(未变)"
    else
        echo "  $count 个文件"
    fi
}

# ===== 头信息 =====
echo "╔════════════════════════════════════════════════════════╗"
echo "║      AI 资源回流: ComfyUI -> Godot assets/ui/         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo "源根目录: $COMFY_OUT"
echo "目标根目录: $ASSETS_UI"

if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "${YELLOW}[DRY RUN 模式]${NC} 仅预览，不实际复制（加 --commit 真正执行）"
else
    echo -e "${GREEN}[COMMIT 模式]${NC} 将实际复制文件"
fi

# ===== 类别映射（与 assets/specs/ui/ 中各清单对齐）=====
# 注: ComfyUI 子目录名需要在工作流 SaveImage 节点里手动改成对应名

# 图标类（128x128）
process_category "wuxia_icon_flux_128"   "element_icons"   "五行元素图标 (128×128)"
process_category "wuxia_realm_128"       "realm_icons"     "十大境界图标 (128×128)"
process_category "wuxia_combat_128"      "status_icons"    "战斗状态图标 Down/Break/Link/Execute/Parry (128×128)"
process_category "wuxia_skill_128"       "skill_icons"     "武学技能图标 (128×128)"
process_category "wuxia_talent_128"      "talent_icons"    "天赋节点图标 (128×128)"
process_category "wuxia_item_128"        "item_icons"      "物品图标 (128×128)"

# Buff/Debuff 图标（64x64,HUD 32x32 显示）
process_category "wuxia_buff_64"         "buff_icons"      "Buff 增益图标 (64×64)"
process_category "wuxia_debuff_64"       "buff_icons"      "Debuff 减益图标 (64×64,与 Buff 同目录)"

# 系统/任务/地图图标（96x96,HUD 48x48 显示,三类同目录前缀区分）
process_category "wuxia_system_96"       "system_icons"    "系统/任务/地图综合图标 (96×96)"

# 立绘类（512x512）— 第四批 W18/W19
process_category "portraits_allies_512"  "portraits"        "主角/队友立绘 (512×512)"
process_category "portraits_enemies_512" "enemy_portraits"  "敌人立绘 (512×512)"

# 背景（1024x1024 原始，后续手动放大）— 第四批 W20
process_category "backgrounds_final"     "backgrounds"     "场景背景 (1024×1024)"

# 次要NPC立绘（512x512）— 第五批 W21
process_category "npc_secondary_512"     "portraits"        "次要NPC立绘 (512×512)"

# 奇遇场景插图（512x512）— 第五批 W22
process_category "encounter_scenes_512"  "encounter_scenes" "奇遇场景插图 (512×512)"

# 边框装饰
process_category "wuxia_frame_256"       "frames"          "边框装饰 (256×256)"

# 备份高清母版（开发期参考用，不入游戏包）
process_category "wuxia_icon_flux_1024"  "_masters/icons_1024"   "🗄 1024 元素图标母版备份"
process_category "wuxia_realm_1024"      "_masters/realms_1024"  "🗄 1024 境界图标母版备份"
process_category "wuxia_combat_1024"     "_masters/combat_1024"  "🗄 1024 战斗状态图标母版备份"
process_category "wuxia_buff_1024"       "_masters/buff_1024"    "🗄 1024 Buff 增益图标母版备份"
process_category "wuxia_debuff_1024"     "_masters/debuff_1024"  "🗄 1024 Debuff 减益图标母版备份"
process_category "wuxia_talent_1024"     "_masters/talent_1024"  "🗄 1024 天赋图标母版备份"
process_category "wuxia_skill_1024"      "_masters/skill_1024"   "🗄 1024 武学图标母版备份"
process_category "wuxia_system_1024"     "_masters/system_1024"  "🗄 1024 系统综合图标母版备份"
process_category "wuxia_item_1024"       "_masters/items_1024"   "🗄 1024 物品图标母版备份"
process_category "wuxia_frame_1024"      "_masters/frames_1024"  "🗄 1024 UI 边框母版备份"
process_category "portraits_allies_1024" "_masters/portraits_allies_1024" "🗄 1024 主角队友立绘母版备份"
process_category "portraits_enemies_1024" "_masters/portraits_enemies_1024" "🗄 1024 敌人立绘母版备份"
process_category "backgrounds_1024"      "_masters/backgrounds_1024" "🗄 1024 背景母版备份"
process_category "npc_secondary_1024"    "_masters/npc_secondary_1024" "🗄 1024 次要NPC母版备份"
process_category "encounter_scenes_1024" "_masters/encounter_scenes_1024" "🗄 1024 奇遇场景母版备份"

# ===== 收尾 =====
echo ""
echo "═══════════════════════════════════════════════════════════"
if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "${YELLOW}▲ DRY RUN 完成${NC}"
    echo "  预览无误后执行: $0 --commit"
else
    echo -e "${GREEN}✓ 回流完成${NC}"
    echo "  下一步:"
    echo "    1. 启动 Godot 编辑器，会自动生成 .import 元数据"
    echo "    2. 在 UI 场景里把 placeholder 替换为新资产"
fi
echo "═══════════════════════════════════════════════════════════"
