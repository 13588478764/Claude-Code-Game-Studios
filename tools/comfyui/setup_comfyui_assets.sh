#!/bin/bash
# =============================================================================
# ComfyUI 环境补全脚本 — 武侠奇遇录 UI 资源生成
# 适配: macOS / Apple Silicon (M4 Pro 48GB)
# 目标: 一键补齐 Manager + 关键插件 + Clip Vision + IPAdapter + Upscaler
# =============================================================================

set -e  # 任意命令失败即退出

# ===== 路径配置（按需调整）=====
COMFY_ROOT="/Users/lingang/Downloads/workspace/ComfyUI/ComfyUI-master"
CUSTOM_NODES="${COMFY_ROOT}/custom_nodes"
MODELS_DIR="${COMFY_ROOT}/models"

# ===== 国内镜像配置 =====
# 如果默认镜像访问不通，可以在命令前用环境变量覆盖，例如：
#   GITHUB_HOST=bgithub.xyz HF_HOST=hf-mirror.com ./setup_comfyui_assets.sh
# 备选 GitHub 镜像: kkgithub.com / bgithub.xyz / hub.fgit.cf
# 备选 HF 镜像:     hf-mirror.com（目前唯一稳定）
GITHUB_HOST="${GITHUB_HOST:-kkgithub.com}"
HF_HOST="${HF_HOST:-hf-mirror.com}"

# ===== 颜色输出 =====
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[ OK ]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_err()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }

# ===== 前置检查 =====
if [[ ! -d "${COMFY_ROOT}" ]]; then
    log_err "ComfyUI 根目录不存在: ${COMFY_ROOT}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    log_err "未安装 git，请先安装: brew install git"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    log_err "未安装 curl"
    exit 1
fi

log_info "ComfyUI 根目录: ${COMFY_ROOT}"
log_info "硬件: $(sysctl -n machdep.cpu.brand_string)"
log_info "内存: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GB"
echo ""

# ===== 步骤 1: 创建缺失的模型子目录 =====
log_info "Step 1/5: 创建模型子目录..."
mkdir -p "${MODELS_DIR}/clip_vision"
mkdir -p "${MODELS_DIR}/ipadapter"
mkdir -p "${MODELS_DIR}/upscale_models"
mkdir -p "${MODELS_DIR}/controlnet"
mkdir -p "${MODELS_DIR}/loras"
log_ok  "模型目录已就绪"

# ===== 步骤 2: 安装 ComfyUI-Manager（必备）=====
log_info "Step 2/5: 安装 ComfyUI-Manager..."
if [[ -d "${CUSTOM_NODES}/ComfyUI-Manager" ]]; then
    log_warn "ComfyUI-Manager 已存在，执行 git pull 更新..."
    (cd "${CUSTOM_NODES}/ComfyUI-Manager" && git pull --rebase --autostash)
else
    git clone https://${GITHUB_HOST}/ltdrdata/ComfyUI-Manager.git \
        "${CUSTOM_NODES}/ComfyUI-Manager"
fi
log_ok "ComfyUI-Manager 安装完成"

# ===== 步骤 3: 安装核心 Custom Nodes =====
log_info "Step 3/5: 安装关键 Custom Nodes..."

declare -a NODES=(
    "https://${GITHUB_HOST}/ltdrdata/ComfyUI-Impact-Pack.git|脸部细化 / 检测分割"
    "https://${GITHUB_HOST}/cubiq/ComfyUI_IPAdapter_plus.git|角色一致性核心"
    "https://${GITHUB_HOST}/rgthree/rgthree-comfy.git|工作流组织"
    "https://${GITHUB_HOST}/cubiq/ComfyUI_essentials.git|常用工具节点"
    "https://${GITHUB_HOST}/pythongosssss/ComfyUI-Custom-Scripts.git|含中文翻译节点"
    "https://${GITHUB_HOST}/ssitu/ComfyUI_UltimateSDUpscale.git|4K 放大"
    "https://${GITHUB_HOST}/Acly/comfyui-tooling-nodes.git|额外工具"
    "https://${GITHUB_HOST}/Suzie1/ComfyUI_Comfyroll_CustomNodes.git|图像处理批处理"
    "https://${GITHUB_HOST}/WASasquatch/was-node-suite-comfyui.git|超全节点合集"
    "https://${GITHUB_HOST}/jags111/efficiency-nodes-comfyui.git|高效率工作流节点"
)

for entry in "${NODES[@]}"; do
    repo_url="${entry%%|*}"
    desc="${entry##*|}"
    repo_name=$(basename "${repo_url}" .git)

    if [[ -d "${CUSTOM_NODES}/${repo_name}" ]]; then
        log_warn "[已存在] ${repo_name} - ${desc} | 跳过"
        continue
    fi

    log_info "安装 ${repo_name} (${desc})..."
    if git clone --depth 1 "${repo_url}" "${CUSTOM_NODES}/${repo_name}" 2>/dev/null; then
        log_ok "${repo_name} 完成"
    else
        log_warn "${repo_name} 安装失败，请稍后手动安装"
    fi
done

# 透明背景去除（BRIA-RMBG）
if [[ ! -d "${CUSTOM_NODES}/ComfyUI-BRIA_AI-RMBG" ]]; then
    log_info "安装 BRIA-RMBG（透明背景抠图）..."
    git clone --depth 1 https://${GITHUB_HOST}/ZHO-ZHO-ZHO/ComfyUI-BRIA_AI-RMBG.git \
        "${CUSTOM_NODES}/ComfyUI-BRIA_AI-RMBG" 2>/dev/null || \
        log_warn "BRIA-RMBG 安装失败，可改用 rembg 节点"
fi

log_ok "Custom Nodes 安装完成"

# ===== 步骤 4: 下载关键基础模型 =====
log_info "Step 4/5: 下载关键基础模型..."

download_if_missing() {
    local url="$1"
    local dest="$2"
    local desc="$3"
    local size_hint="$4"

    if [[ -f "${dest}" ]]; then
        local actual_size=$(wc -c < "${dest}")
        if [[ ${actual_size} -gt 1000 ]]; then
            log_warn "[已存在] ${desc} - 跳过"
            return
        fi
    fi

    log_info "下载 ${desc} (${size_hint})..."
    if curl -L --fail --progress-bar -o "${dest}" "${url}"; then
        log_ok "${desc} 下载完成"
    else
        log_err "${desc} 下载失败 URL: ${url}"
        rm -f "${dest}"
    fi
}

# 4.1 Clip Vision (IPAdapter 必备)
download_if_missing \
    "https://${HF_HOST}/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors" \
    "${MODELS_DIR}/clip_vision/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" \
    "Clip Vision (CLIP-ViT-H, IPAdapter 配套)" \
    "~2.5GB"

# 4.2 IPAdapter Plus for SDXL
download_if_missing \
    "https://${HF_HOST}/h94/IP-Adapter/resolve/main/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors" \
    "${MODELS_DIR}/ipadapter/ip-adapter-plus_sdxl_vit-h.safetensors" \
    "IPAdapter Plus SDXL (角色一致性)" \
    "~850MB"

# 4.3 IPAdapter FaceID Plus for SDXL（锁脸专用）
download_if_missing \
    "https://${HF_HOST}/h94/IP-Adapter-FaceID/resolve/main/ip-adapter-faceid-plusv2_sdxl.bin" \
    "${MODELS_DIR}/ipadapter/ip-adapter-faceid-plusv2_sdxl.bin" \
    "IPAdapter FaceID Plus v2 SDXL (锁脸)" \
    "~150MB"

# 4.4 4x-UltraSharp Upscaler（4K 放大）
download_if_missing \
    "https://${HF_HOST}/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth" \
    "${MODELS_DIR}/upscale_models/4x-UltraSharp.pth" \
    "4x-UltraSharp 放大模型" \
    "~67MB"

# 4.5 RealESRGAN_x4plus（备用放大）
download_if_missing \
    "https://${GITHUB_HOST}/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" \
    "${MODELS_DIR}/upscale_models/RealESRGAN_x4plus.pth" \
    "RealESRGAN x4plus" \
    "~64MB"

# 4.6 删除空占位 LoRA
if [[ -f "${MODELS_DIR}/loras/cyberpunk_style.safetensors" ]]; then
    actual_size=$(wc -c < "${MODELS_DIR}/loras/cyberpunk_style.safetensors")
    if [[ ${actual_size} -lt 1000 ]]; then
        log_warn "检测到空占位 LoRA (145B)，删除中..."
        rm "${MODELS_DIR}/loras/cyberpunk_style.safetensors"
    fi
fi

# ===== 步骤 5: 安装 Python 依赖 =====
log_info "Step 5/5: 检查并安装 Custom Nodes 的 Python 依赖..."

if [[ -d "${COMFY_ROOT}/venv" ]]; then
    PYTHON="${COMFY_ROOT}/venv/bin/python"
    log_info "检测到 venv，使用: ${PYTHON}"
else
    PYTHON="python3"
    log_warn "未检测到 venv，使用系统 python3。建议先创建虚拟环境。"
fi

for req_file in "${CUSTOM_NODES}"/*/requirements.txt; do
    if [[ -f "${req_file}" ]]; then
        node_name=$(basename "$(dirname "${req_file}")")
        log_info "安装 ${node_name} 的依赖..."
        ${PYTHON} -m pip install -q -r "${req_file}" 2>&1 | tail -3 || \
            log_warn "${node_name} 依赖安装可能失败，请手动检查"
    fi
done

# ===== 完成 =====
echo ""
log_ok "================================================================"
log_ok "ComfyUI 环境补全完成！"
log_ok "================================================================"
echo ""
log_info "已安装内容:"
echo "  ✓ ComfyUI-Manager"
echo "  ✓ 10+ Custom Nodes (IPAdapter / Impact Pack / Upscale / 等)"
echo "  ✓ Clip Vision (IPAdapter 必备)"
echo "  ✓ IPAdapter Plus + FaceID (角色一致性)"
echo "  ✓ 2 个放大模型 (4x-UltraSharp + RealESRGAN)"
echo ""
log_info "下一步:"
echo "  1. 重启 ComfyUI: cd ${COMFY_ROOT} && python main.py"
echo "  2. 浏览器打开 http://localhost:8188"
echo "  3. 通过左侧 Manager 安装更多 LoRA (见 civitai_loras.md 清单)"
echo "  4. 拖入 tools/comfyui/workflows/01_five_elements_icons.json 试跑首批"
echo ""
log_warn "尚未自动下载的（需手动从 Civitai 下载，见 tools/comfyui/civitai_loras.md）:"
echo "  - 水墨风格 LoRA (Chinese Ink Painting)"
echo "  - 仙侠风格 LoRA (Xianxia / Wuxia)"
echo "  - 工笔重彩 LoRA (Gongbi Painting)"
echo ""
log_info "Apple Silicon 启动建议命令:"
echo "  python main.py --force-fp16 --use-pytorch-cross-attention"
