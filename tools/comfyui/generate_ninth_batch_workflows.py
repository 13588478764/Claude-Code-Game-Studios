#!/usr/bin/env python3
# =============================================================================
# 第九批 ComfyUI 工作流生成器
# W31: 9张功法/卷轴图标 (替换 item_scroll 占位)
# W32: 10张新区域时段变体 (5区域 × 黄昏/夜晚)
#
# 合计 19 张
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from generate_batch_workflow import build_workflow, save

# =============================================================================
# W31: 功法/卷轴图标 (9张)
# =============================================================================

PROMPT_SCROLL = (
    "single {desc}, "
    "centered on plain dark background, Chinese wuxia cultivation style, "
    "detailed item icon, game UI asset, no text, high quality, 8k"
)

SCROLL_ICONS = [
    {"name": "item_martial_fragment", "prompt": PROMPT_SCROLL.format(
        desc="torn ancient bamboo scroll fragment with faded ink characters, martial arts manual piece"
    ), "color": "#8b7355"},
    {"name": "item_technique_scroll", "prompt": PROMPT_SCROLL.format(
        desc="rolled silk scroll with golden seal, cultivation technique manual, glowing runes"
    ), "color": "#daa520"},
    {"name": "item_xuan_technique", "prompt": PROMPT_SCROLL.format(
        desc="dark mysterious scroll wrapped in black silk, ancient xuan technique, purple energy wisps"
    ), "color": "#4a0080"},
    {"name": "item_righteous_technique", "prompt": PROMPT_SCROLL.format(
        desc="white jade scroll with golden text, righteous path cultivation technique, holy glow"
    ), "color": "#ffd700"},
    {"name": "item_demonic_technique", "prompt": PROMPT_SCROLL.format(
        desc="blood red scroll with black chains, demonic cultivation technique, dark red aura"
    ), "color": "#8b0000"},
    {"name": "item_taixu_sword", "prompt": PROMPT_SCROLL.format(
        desc="blue sword manual scroll with silver sword diagram, taixu sword technique"
    ), "color": "#4682b4"},
    {"name": "item_sword_fragment", "prompt": PROMPT_SCROLL.format(
        desc="torn yellow parchment with sword stance diagrams, ancient sword technique fragment"
    ), "color": "#b8860b"},
    {"name": "item_sword_manual_gift", "prompt": PROMPT_SCROLL.format(
        desc="thin bamboo strip book with sword forms, handwritten sword manual pages"
    ), "color": "#6b8e23"},
    {"name": "item_calligraphy_gift", "prompt": PROMPT_SCROLL.format(
        desc="elegant calligraphy scroll with brush painting of mountains, artistic gift"
    ), "color": "#2f4f4f"},
]

# =============================================================================
# W32: 新区域时段变体 (10张 = 5区域 × 黄昏/夜晚)
# =============================================================================

PROMPT_BG_VAR = (
    "wide panoramic landscape scene, {desc}, "
    "Song Dynasty Chinese landscape painting style, shanshui ink wash, "
    "no characters no people, cinematic composition, "
    "cultivation immortal xianxia world, no text no watermark, high quality, 8k"
)

NEW_REGION_TIME_VARIANTS = [
    # 古墓
    {"name": "bg_ancient_tomb_dusk", "prompt": PROMPT_BG_VAR.format(
        desc="ancient tomb entrance at dusk, last rays of sunlight illuminating stone steps, bats emerging"
    ), "color": "#8b6914"},
    {"name": "bg_ancient_tomb_night", "prompt": PROMPT_BG_VAR.format(
        desc="ancient tomb at night, ghostly green glow from within, full moon above, eerie mist"
    ), "color": "#1a2a1a"},
    # 魔域
    {"name": "bg_demon_domain_dusk", "prompt": PROMPT_BG_VAR.format(
        desc="demonic wasteland at dusk, blood red sunset, dark energy pillars silhouetted against sky"
    ), "color": "#8b2020"},
    {"name": "bg_demon_domain_night", "prompt": PROMPT_BG_VAR.format(
        desc="demonic wasteland at night, crimson moon, burning black flames, demonic runes glowing on ground"
    ), "color": "#2a0a0a"},
    # 天剑峰
    {"name": "bg_heavenly_peak_dusk", "prompt": PROMPT_BG_VAR.format(
        desc="mountain sword sect at dusk, golden clouds, sword pillars casting long shadows, serene"
    ), "color": "#d4a060"},
    {"name": "bg_heavenly_peak_night", "prompt": PROMPT_BG_VAR.format(
        desc="mountain sword sect at night, starry sky, sword qi aurora in sky, meditation lanterns"
    ), "color": "#0a1a3a"},
    # 虚空裂境
    {"name": "bg_void_realm_dusk", "prompt": PROMPT_BG_VAR.format(
        desc="void dimension with orange-purple spatial rifts, floating islands in twilight, ethereal"
    ), "color": "#6a3a8a"},
    {"name": "bg_void_realm_night", "prompt": PROMPT_BG_VAR.format(
        desc="void dimension at night, deep space visible, purple nebula, floating crystals glowing faintly"
    ), "color": "#0a0a2a"},
    # 江南水乡
    {"name": "bg_jiangnan_water_dusk", "prompt": PROMPT_BG_VAR.format(
        desc="jiangnan water town at dusk, golden reflections on canal, lanterns beginning to glow, warm"
    ), "color": "#e8a040"},
    {"name": "bg_jiangnan_water_night", "prompt": PROMPT_BG_VAR.format(
        desc="jiangnan water town at night, red lanterns reflecting on water, moonlit bridges, fireflies"
    ), "color": "#1a1a30"},
]


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    wf31 = build_workflow(
        icons=SCROLL_ICONS, master_dir="scroll_icons_1024", final_dir="scroll_icons_128",
        final_size=128, title="W31 · 功法卷轴图标 (9张)",
        note_body=f"替换 item_scroll 占位的9个功法/卷轴物品\n共 {len(SCROLL_ICONS)} 张",
    )
    save(wf31, os.path.join(out_dir, "31_scroll_icons_batch_flux.json"))
    print(f"✓ W31 功法卷轴图标 ({len(SCROLL_ICONS)} 张)")

    wf32 = build_workflow(
        icons=NEW_REGION_TIME_VARIANTS, master_dir="new_region_time_1024", final_dir="new_region_time_final",
        final_size=1024, title="W32 · 新区域时段变体 (10张)",
        note_body=f"5新区域 × 黄昏/夜晚\n共 {len(NEW_REGION_TIME_VARIANTS)} 张",
    )
    save(wf32, os.path.join(out_dir, "32_new_region_time_batch_flux.json"))
    print(f"✓ W32 新区域时段变体 ({len(NEW_REGION_TIME_VARIANTS)} 张)")

    total = len(SCROLL_ICONS) + len(NEW_REGION_TIME_VARIANTS)
    print(f"\n总计: {total} 张")
    print("在 ComfyUI 中依次加载 W31 / W32 执行")


if __name__ == "__main__":
    main()
