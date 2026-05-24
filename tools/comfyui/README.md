# ComfyUI 资源生成工具集

> 配合 [assets/specs/ui/](../../assets/specs/ui/) 资源清单使用，
> 在本地 ComfyUI 上批量生成《武侠奇遇录》UI 美术资产。

## 目录结构

```
tools/comfyui/
├── README.md                              # 本文件
├── setup_comfyui_assets.sh                # 环境一键补全脚本
├── civitai_loras.md                       # LoRA / 模型推荐清单
└── workflows/
    ├── 01_five_elements_icons.json        # 五行图标 (SDXL + 透明背景)
    └── 02_flux_background_landscape.json  # 场景背景 (FLUX dev)
```

## 快速开始（三步走）

### Step 1: 环境补全

```bash
cd /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios
./tools/comfyui/setup_comfyui_assets.sh
```

脚本会自动:
- 安装 ComfyUI-Manager 和 10+ 关键 Custom Nodes
- 下载 Clip Vision + IPAdapter + 放大模型
- 清理 145B 空占位 LoRA
- 安装所有 Python 依赖

### Step 2: 启动 ComfyUI

```bash
cd /Users/lingang/Downloads/workspace/ComfyUI/ComfyUI-master
python main.py --force-fp16 --use-pytorch-cross-attention
```

浏览器打开 http://localhost:8188

### Step 3: 装风格 LoRA

参照 [civitai_loras.md](civitai_loras.md) 第一批清单，从 Civitai 下载：
- GuoFeng XL Checkpoint
- 中国水墨 LoRA
- 仙侠 LoRA
- 工笔画 LoRA

放入 `ComfyUI-master/models/loras/` 和 `models/checkpoints/`。

### Step 4: 试跑工作流

在 ComfyUI 网页界面点 "Load"，拖入工作流 JSON:

- 试图标: `workflows/01_five_elements_icons.json`
- 试背景: `workflows/02_flux_background_landscape.json`

修改提示词中的元素名后点 "Queue Prompt"。

## 推荐生产顺序

| 顺序 | 资源类别 | 工作流 | 预计耗时 |
|------|---------|--------|---------|
| 1️⃣ | 五行图标 (5 张) | `01_five_elements_icons.json` | ~5 分钟 |
| 2️⃣ | Buff/Debuff (36 张) | 复用 01，改 prompt | ~30 分钟 |
| 3️⃣ | 境界图标 (9 张) | 复用 01 + 水墨 LoRA | ~10 分钟 |
| 4️⃣ | 系统/物品 (~85 张) | 复用 01 | ~70 分钟 |
| 5️⃣ | 场景背景 (15 张) | `02_flux_background_landscape.json` | ~1.5 小时 |
| 6️⃣ | 敌人立绘 (16 张) | 新建（用 SDXL + 工笔 LoRA） | ~30 分钟 |
| 7️⃣ | 主角/队友 (12 角色 × 4 表情) | 新建（IPAdapter FaceID） | ~3-4 小时 |
| 8️⃣ | 边框/装饰 (21 张) | 新建（部分需 PS） | ~1-2 小时 |

**Alpha 必备 P0 资源总耗时**: 约 6-8 小时纯生成时间（含调试和重抽）。

## 资源回流到游戏

生成的图存放在 `ComfyUI-master/output/`，需要：

1. **批量重命名** 按 `assets/specs/ui/` 中规定的 `snake_case` 命名
2. **复制到游戏目录** 按各清单中的路径约定（如 `assets/ui/element_icons/`）
3. **Godot 导入** 启动 Godot 编辑器后自动识别 `.import` 元数据
4. **替换占位符** 在 UI 场景中将 placeholder 替换为正式资产

可后续写一个 `tools/import_ai_assets.sh` 自动化此流程。

## 故障排查

### 启动 ComfyUI 时报 MPS 后端错误
```bash
python main.py --cpu  # 强制 CPU 模式（慢但稳）
```

### FLUX 出图全黑
- 检查 VAE 是否加载了 `ae.safetensors`（不是 SDXL 的 vae）
- 检查 CLIP 是否用了 `DualCLIPLoader` 而非 `CLIPLoader`

### IPAdapter 报错 "model not found"
- 确认 `models/clip_vision/` 中有 `CLIP-ViT-H-14...safetensors`
- 重启 ComfyUI 让 Manager 重新扫描

### 显存不够（极少见，48GB 通常足够）
```bash
python main.py --force-fp16 --normalvram
```

## 相关文档

- 资源清单总索引: [assets/specs/ui/INDEX.md](../../assets/specs/ui/INDEX.md)
- LoRA 推荐: [civitai_loras.md](civitai_loras.md)
- ComfyUI 官方: https://github.com/comfyanonymous/ComfyUI
- ComfyUI-Manager: https://github.com/ltdrdata/ComfyUI-Manager

---

**版本**: v1.0  
**适配硬件**: Apple M4 Pro 48GB / macOS  
**ComfyUI 版本**: v0.18.0+
