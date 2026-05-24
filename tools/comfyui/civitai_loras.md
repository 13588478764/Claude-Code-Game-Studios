# Civitai LoRA / 模型推荐清单 — 武侠奇遇录

> 针对 [assets/specs/ui/](../../assets/specs/ui/) 资源生成所需的 LoRA、Checkpoint、辅助模型推荐。
> 全部以 Apple M4 Pro 48GB / ComfyUI v0.18.0 为前提。

## ⚠️ 重要说明

- **Civitai 部分内容需登录**: 注册免费账号即可
- **下载方式**: 推荐手动下载或用 `civitai-downloader` 工具
- **存放位置**:
  - LoRA → `ComfyUI-master/models/loras/`
  - Checkpoint → `ComfyUI-master/models/checkpoints/`
  - Embedding → `ComfyUI-master/models/embeddings/`
- **版本兼容**: LoRA 必须匹配 base 模型版本（SDXL LoRA 不能用于 FLUX，反之亦然）

## 推荐路线对比

| 路线 | base 模型 | 推荐 LoRA 数 | 速度（M4 Pro） | 质量 | 建议场景 |
|------|----------|-------------|---------------|------|---------|
| **A. SDXL + 国风 LoRA** | SDXL Base | 2-3 | 30-45s/张 | ⭐⭐⭐⭐ | 图标批量、首选 |
| **B. FLUX dev + LoRA** | FLUX dev | 1-2 | 2-5min/张 | ⭐⭐⭐⭐⭐ | 立绘、背景、Boss |
| **C. 国风专用 SDXL Checkpoint** | 国风 Checkpoint | 0-1 | 30-45s/张 | ⭐⭐⭐⭐⭐ | 风格最一致 |

**推荐组合**: 路线 C（国风 Checkpoint） + 路线 B（FLUX 关键资源）

---

## 一、国风 / 水墨风格 Checkpoint（强烈推荐）

### 1.1 麦橘 MeinaMix / GhostMix（古风兼容）

| 项 | 值 |
|---|---|
| 类型 | SD1.5 Checkpoint |
| Civitai 搜索 | `meinamix` 或 `ghostmix` |
| 适用 | 中国风物品、图标 |
| 备注 | 老牌国风模型，下载基数大 |

### 1.2 **GuoFeng (国风) 系列** ⭐⭐⭐⭐⭐

| 项 | 值 |
|---|---|
| 类型 | SDXL Checkpoint |
| Civitai 搜索 | `guofeng` 或 `Chinese Style` |
| 推荐版本 | GuoFeng4 XL / GuoFeng3.4 |
| 适用 | 全部资源（图标、立绘、背景） |
| 显存 | 与 SDXL Base 相同 |
| **首选理由** | 国人训练，对中文古风理解最深 |

### 1.3 **AnythingXL / RevAnimated**

| 项 | 值 |
|---|---|
| 类型 | SDXL Checkpoint |
| 适用 | 角色立绘 |
| 备注 | 偏二次元风格，需配合工笔 LoRA 拉回古风 |

### 1.4 FLUX 古风微调版

| 项 | 值 |
|---|---|
| Civitai 搜索 | `flux chinese` 或 `flux guofeng` |
| 状态 | 2025 年起逐渐增多 |
| 备注 | FLUX 自身已能出不错的中国风，微调版锦上添花 |

---

## 二、水墨 / 工笔 LoRA（必装）

### 2.1 中国水墨画 LoRA

**搜索关键词** (Civitai):
- `chinese ink painting`
- `ink wash painting style`
- `sumi-e`
- `水墨画`

**推荐型号**:
- `MoXin (墨心)` — 水墨风老牌 LoRA
- `Chinese Ink Painting LoRA` (各版本均可)
- `Ink Scenery` — 偏背景

**触发词** (常见): `inkpainting`, `ink wash`, `chinese painting style`

**推荐权重**: 0.6 - 0.9

### 2.2 工笔重彩 LoRA（角色立绘必备）

**搜索关键词**:
- `gongbi painting`
- `chinese gongbi`
- `traditional chinese painting`
- `工笔画`

**推荐型号**:
- `Gongbi Style LoRA`
- `Chinese Traditional Painting`

**触发词**: `gongbi`, `gongbi painting`, `traditional chinese painting`

### 2.3 仙侠 / 武侠风 LoRA

**搜索关键词**:
- `xianxia`
- `wuxia`
- `cultivation immortal`
- `chinese fantasy`
- `仙侠`
- `修仙`

**推荐型号**:
- `Xianxia Style`
- `Chinese Immortal Cultivation`
- `Wuxia Martial Arts`

**触发词**: `xianxia`, `wuxia`, `immortal cultivator`, `daoist robes`

---

## 三、角色一致性方案（06 主角立绘必备）

### 3.1 IPAdapter Plus + FaceID（推荐首选）

已在 [setup_comfyui_assets.sh](setup_comfyui_assets.sh) 中自动下载。

**工作流**:
1. 用 IPAdapter Plus 锁定整体风格
2. 用 FaceID Plus v2 锁定脸部
3. 同时挂工笔 LoRA 保证风格统一

### 3.2 PuLID FLUX（FLUX 专用锁脸 — 最强）

| 项 | 值 |
|---|---|
| Custom Node | `ComfyUI-PuLID-Flux` |
| 模型 | `pulid_flux_v0.9.1.safetensors` |
| HuggingFace | `https://huggingface.co/guozinan/PuLID/tree/main` |
| 优势 | 单图参考即可锁脸，FLUX 专属 |
| 显存 | 需额外 4GB |

### 3.3 训练角色 LoRA（终极方案）

适合主要角色（云中鹤 / 柳如烟 / 萧寒夜）：

- **工具**: `Kohya_ss GUI` (macOS 可用)
- **训练图**: 每角色 15-20 张
- **耗时**: M4 Pro 约 30-60 分钟/角色
- **效果**: 一致性 95%+

详细教程: https://github.com/bmaltais/kohya_ss

---

## 四、辅助模型（无需 Civitai，HuggingFace 直链）

> 以下已包含在 `setup_comfyui_assets.sh` 中自动下载，列出仅供参考。

### 4.1 Clip Vision

```
URL: https://huggingface.co/h94/IP-Adapter/resolve/main/sdxl_models/image_encoder/model.safetensors
存放: models/clip_vision/
大小: ~2.5GB
```

### 4.2 IPAdapter Models

```
ip-adapter-plus_sdxl_vit-h.safetensors        # 风格参考
ip-adapter-faceid-plusv2_sdxl.bin             # 锁脸
ip-adapter_sdxl_vit-h.safetensors             # 基础版

存放: models/ipadapter/
源: https://huggingface.co/h94/IP-Adapter
```

### 4.3 Upscaler 放大模型

```
4x-UltraSharp.pth     # 综合最佳
RealESRGAN_x4plus.pth # 备用
4x_NMKD-Siax_200k.pth # 写实风格
4x-AnimeSharp.pth     # 二次元 (立绘可选)

存放: models/upscale_models/
源: https://upscale.wiki/wiki/Model_Database
```

### 4.4 BRIA-RMBG（透明背景）

```
URL: https://huggingface.co/briaai/RMBG-1.4
存放: models/rmbg/RMBG-1.4/
大小: ~176MB
节点会自动下载，无需手动
```

### 4.5 ControlNet（构图控制，按需）

| 用途 | 模型 |
|------|------|
| OpenPose 姿势 | `control-lora-openposeXL2-rank256.safetensors` |
| Canny 边缘 | `control-lora-canny-rank256.safetensors` |
| Depth 深度 | `control-lora-depth-rank256.safetensors` |
| 软边缘（线稿） | `control-lora-sketch-rank256.safetensors` |

源: https://huggingface.co/stabilityai/control-lora

---

## 五、按资源清单匹配推荐

| 清单文件 | 必装 | 强烈推荐 | 可选 |
|---------|------|---------|------|
| [01 境界图标](../../assets/specs/ui/01-icons-realm.md) | SDXL + 水墨 LoRA | GuoFeng XL | 仙侠 LoRA |
| [02 五行图标](../../assets/specs/ui/02-icons-elements-status.md) | SDXL | 水墨 LoRA | — |
| [03 Buff/Debuff](../../assets/specs/ui/03-icons-buff-debuff.md) | SDXL | 水墨 LoRA | — |
| [04 武学/天赋](../../assets/specs/ui/04-icons-skills-talents.md) | SDXL + 水墨 LoRA | GuoFeng XL | 仙侠 LoRA |
| [05 系统图标](../../assets/specs/ui/05-icons-system-quest.md) | SDXL | 水墨 LoRA | — |
| [06 主角立绘](../../assets/specs/ui/06-portraits-protagonist-allies.md) | **GuoFeng XL + 工笔 LoRA + IPAdapter FaceID** | PuLID FLUX | 角色 LoRA |
| [07 敌人立绘](../../assets/specs/ui/07-portraits-enemies.md) | GuoFeng XL + 工笔 LoRA | FLUX (Boss) | ControlNet OpenPose |
| [08 背景](../../assets/specs/ui/08-backgrounds.md) | **FLUX dev** | 水墨 LoRA (FLUX 版) | — |
| [09 边框装饰](../../assets/specs/ui/09-frames-decoration.md) | SDXL | — | PS 手工切片 |
| [10 物品图标](../../assets/specs/ui/10-items.md) | SDXL + 水墨 LoRA | GuoFeng XL | — |

---

## 六、下载工具推荐

### 6.1 civitai-downloader（命令行批量下载）

```bash
# 安装
pip install civitai-model-downloader

# 用法
civitai-dl --url "https://civitai.com/models/XXXXX" \
           --dest /Users/lingang/Downloads/workspace/ComfyUI/ComfyUI-master/models/loras/
```

### 6.2 ComfyUI-Manager 内置下载

setup 脚本装好 Manager 后，在 UI 中直接搜索安装大部分模型。

### 6.3 HuggingFace 直链下载

```bash
# 单文件
curl -L -o models/loras/xxx.safetensors \
  "https://huggingface.co/USER/REPO/resolve/main/xxx.safetensors"

# 整个仓库
git lfs install
git clone https://huggingface.co/USER/REPO models/loras/REPO/
```

---

## 七、推荐下载顺序

### 🥇 第一批（今晚就装，约 5-8GB）

1. **GuoFeng XL Checkpoint** (~7GB) — 一站式国风
2. **中国水墨 LoRA** (~150MB)
3. **仙侠 LoRA** (~150MB)
4. **工笔画 LoRA** (~150MB)
5. **4x-UltraSharp** (~67MB)  ← setup 脚本已下载

### 🥈 第二批（角色立绘前装，约 3-5GB）

6. **IPAdapter SDXL + FaceID** ← setup 脚本已下载
7. **CLIP-ViT-H Vision** ← setup 脚本已下载
8. **ControlNet OpenPose** (~700MB)

### 🥉 第三批（终极一致性，约 5-10GB）

9. **PuLID FLUX** (~1.4GB)
10. **训练角色 LoRA** (自己产出，每个 ~144MB)

---

## 八、Apple Silicon 性能预期（M4 Pro 48GB）

| 配置 | 1024×1024 单张 | 1920×1080 单张 |
|------|---------------|---------------|
| SDXL Base | 30-45 秒 | 60-90 秒 |
| SDXL + 2 LoRA | 35-50 秒 | 70-100 秒 |
| GuoFeng XL | 35-50 秒 | 70-100 秒 |
| FLUX dev (25 步) | 2-5 分钟 | 4-8 分钟 |
| FLUX Schnell (4 步) | 30-60 秒 | 1-2 分钟 |
| + 4x 放大 | +30 秒 | +60 秒 |

**Tip**: 启动 ComfyUI 时加 `--force-fp16` 参数可降低显存占用、略微提速。

---

## 九、版权与商用提示

- 大部分 Civitai LoRA 个人非商用免费
- 商用需查看每个模型的 **License** 字段
- 国内商业项目建议选择 `Stable Diffusion License`（允许商用）的模型
- 训练自己角色 LoRA 完全无版权风险

---

**清单版本**: v1.0  
**配套脚本**: [setup_comfyui_assets.sh](setup_comfyui_assets.sh)  
**配套工作流**: [workflows/](workflows/)
