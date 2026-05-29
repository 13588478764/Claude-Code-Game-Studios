#!/usr/bin/env python3
# =============================================================================
# 第六批 ComfyUI 工作流生成器
# 产出 1 个 workflow: 3 种横向按钮纹理 (各 2 个变体 = 6 张)
#
# 用法:
#   cd tools/comfyui
#   python3 generate_sixth_batch_workflows.py
#
# 产出 (写入 workflows/):
#   23_button_textures_batch_flux.json  (6 张按钮纹理, 1024×1024 → 裁剪为 512×128)
#
# 注意: ComfyUI 固定 1024×1024 出图, 提示词要求内容集中在画面中央横带
#       回流后需运行 crop_buttons.sh 裁剪为 512×128
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from generate_batch_workflow import build_workflow, save

PROMPT_TEMPLATE_BUTTON = (
    "a horizontal decorative banner, Chinese wuxia style, "
    "{desc}, "
    "content concentrated in a narrow horizontal strip at center, "
    "ornamental border pattern, gold and dark accents, "
    "transparent or plain dark background above and below the strip, "
    "high quality, 8k, no text"
)

BUTTON_TEXTURES = [
    {
        "name": "btn_main_menu_a",
        "prompt": PROMPT_TEMPLATE_BUTTON.format(
            desc="elaborate scroll banner with cloud motifs and jade ornaments, warm gold tones"
        ),
        "color": "#daa520",
    },
    {
        "name": "btn_main_menu_b",
        "prompt": PROMPT_TEMPLATE_BUTTON.format(
            desc="elegant silk ribbon banner with dragon watermark pattern, imperial gold border"
        ),
        "color": "#b8860b",
    },
    {
        "name": "btn_standard_a",
        "prompt": PROMPT_TEMPLATE_BUTTON.format(
            desc="simple wooden plaque with subtle carved patterns, dark wood with gold inlay"
        ),
        "color": "#8b7355",
    },
    {
        "name": "btn_standard_b",
        "prompt": PROMPT_TEMPLATE_BUTTON.format(
            desc="bamboo strip tablet with ink wash decorative edges, natural bamboo texture"
        ),
        "color": "#6b8e23",
    },
    {
        "name": "btn_close_a",
        "prompt": PROMPT_TEMPLATE_BUTTON.format(
            desc="small circular seal stamp with X mark, red seal ink on dark background"
        ),
        "color": "#8b0000",
    },
    {
        "name": "btn_close_b",
        "prompt": PROMPT_TEMPLATE_BUTTON.format(
            desc="small stone button with crescent moon carving, gray jade material"
        ),
        "color": "#708090",
    },
]


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    wf23 = build_workflow(
        icons=BUTTON_TEXTURES,
        master_dir="button_textures_1024",
        final_dir="button_textures_512",
        final_size=512,
        title="W23 · 横向按钮纹理 (6张)",
        note_body=(
            "第六批 — 横向按钮纹理\n"
            "出图 1024×1024, 提示词要求内容集中在中央横带\n"
            "回流后需运行 crop_buttons.sh 裁剪中心横条为 512×128\n\n"
            f"共 {len(BUTTON_TEXTURES)} 张"
        ),
    )
    path23 = os.path.join(out_dir, "23_button_textures_batch_flux.json")
    save(wf23, path23)
    print(f"✓ W23 横向按钮纹理 ({len(BUTTON_TEXTURES)} 张) → {path23}")
    print("\n出图后需裁剪: bash tools/comfyui/crop_buttons.sh --commit")


if __name__ == "__main__":
    main()
