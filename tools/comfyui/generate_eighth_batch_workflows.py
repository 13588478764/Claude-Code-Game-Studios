#!/usr/bin/env python3
# =============================================================================
# 第八批 ComfyUI 工作流生成器
# W28: 5张新区域探索背景
# W29: 5张新区域战斗背景
# W30: 20张新装备图标 (副手/身体/手/脚/项链 × 4品阶)
#
# 合计 30 张
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from generate_batch_workflow import build_workflow, save

# =============================================================================
# W28: 新区域探索背景 (5张)
# =============================================================================

PROMPT_BG = (
    "wide panoramic landscape, {desc}, "
    "Song Dynasty Chinese shanshui ink wash painting style, "
    "misty atmosphere, no characters, cinematic composition, "
    "cultivation immortal xianxia world, no text, high quality, 8k"
)

NEW_REGION_BGS = [
    {"name": "bg_ancient_tomb", "prompt": PROMPT_BG.format(
        desc="ancient underground tomb with stone corridors, glowing runes on walls, eerie green mist, scattered bones and jade artifacts"
    ), "color": "#2a3a2a"},
    {"name": "bg_demon_domain", "prompt": PROMPT_BG.format(
        desc="demonic wasteland with twisted black trees, blood red sky, dark energy pillars, ruined demonic temples"
    ), "color": "#4a1a1a"},
    {"name": "bg_heavenly_peak", "prompt": PROMPT_BG.format(
        desc="celestial mountain peak above clouds, sword-shaped stone pillars, golden sunlight, ancient sword sect temple"
    ), "color": "#6080b0"},
    {"name": "bg_void_realm", "prompt": PROMPT_BG.format(
        desc="fractured void dimension, floating rock islands, purple spatial rifts, stars visible through cracks in reality"
    ), "color": "#2a1a4a"},
    {"name": "bg_jiangnan_water", "prompt": PROMPT_BG.format(
        desc="jiangnan water town with stone bridges, willow trees, traditional boats, morning mist over calm canal"
    ), "color": "#4a7a6a"},
]

# =============================================================================
# W29: 新区域战斗背景 (5张)
# =============================================================================

PROMPT_BATTLE = (
    "wide battle arena scene, {desc}, "
    "dramatic lighting, wide open ground for combat, "
    "Song Dynasty Chinese landscape painting style, "
    "no characters, empty battlefield, cinematic, no text, high quality, 8k"
)

NEW_BATTLE_BGS = [
    {"name": "bg_battle_tomb", "prompt": PROMPT_BATTLE.format(
        desc="underground tomb chamber with crumbling pillars, green spirit flames on torches, stone sarcophagus in center"
    ), "color": "#2a3a2a"},
    {"name": "bg_battle_demon", "prompt": PROMPT_BATTLE.format(
        desc="demonic ritual arena with blood red ground, dark energy barriers, burning black flames around edges"
    ), "color": "#4a1a1a"},
    {"name": "bg_battle_immortal", "prompt": PROMPT_BATTLE.format(
        desc="immortal palace courtyard with jade floor, spirit formation circles glowing, celestial clouds above"
    ), "color": "#3a6a8a"},
    {"name": "bg_battle_heavenly", "prompt": PROMPT_BATTLE.format(
        desc="sword sect training platform on cliff edge, sword qi marks on stone floor, wind and clouds swirling"
    ), "color": "#6080b0"},
    {"name": "bg_battle_void", "prompt": PROMPT_BATTLE.format(
        desc="floating platform in void dimension, spatial cracks around edges, purple energy streams, stars below"
    ), "color": "#2a1a4a"},
]

# =============================================================================
# W30: 新装备图标 (20张 = 5槽位 × 4品阶)
# =============================================================================

PROMPT_ITEM = (
    "single {desc}, "
    "centered on plain dark background, Chinese wuxia cultivation style, "
    "detailed item icon, game UI asset, no text, high quality, 8k"
)

NEW_EQUIPMENT_ICONS = [
    # 副手
    {"name": "item_shield_wood", "prompt": PROMPT_ITEM.format(desc="wooden round shield with iron studs, simple design"), "color": "#8b7355"},
    {"name": "item_shield_iron", "prompt": PROMPT_ITEM.format(desc="iron kite shield with engraved dragon pattern"), "color": "#708090"},
    {"name": "item_shield_xuanwu", "prompt": PROMPT_ITEM.format(desc="ornate turtle shell shield glowing with water energy, xuanwu pattern"), "color": "#4682b4"},
    {"name": "item_mirror_divine", "prompt": PROMPT_ITEM.format(desc="ancient bronze mirror emitting golden light, bagua pattern on back"), "color": "#daa520"},
    # 身体
    {"name": "item_robe_cloth", "prompt": PROMPT_ITEM.format(desc="simple brown cloth robe, plain cultivator outfit"), "color": "#8b6914"},
    {"name": "item_armor_iron", "prompt": PROMPT_ITEM.format(desc="iron plate armor with leather straps, warrior style"), "color": "#708090"},
    {"name": "item_robe_cloud", "prompt": PROMPT_ITEM.format(desc="elegant flowing white robe with cloud patterns, blue accents"), "color": "#87ceeb"},
    {"name": "item_armor_celestial", "prompt": PROMPT_ITEM.format(desc="legendary golden silk armor with phoenix embroidery, glowing threads"), "color": "#ffd700"},
    # 手部
    {"name": "item_gloves_cloth", "prompt": PROMPT_ITEM.format(desc="simple cloth hand wraps, martial arts style"), "color": "#deb887"},
    {"name": "item_gauntlets_iron", "prompt": PROMPT_ITEM.format(desc="iron gauntlets with spiked knuckles"), "color": "#708090"},
    {"name": "item_gloves_dragon", "prompt": PROMPT_ITEM.format(desc="red dragon scale gloves with golden claws, fiery glow"), "color": "#dc143c"},
    {"name": "item_gauntlets_void", "prompt": PROMPT_ITEM.format(desc="purple void energy gauntlets, spatial cracks pattern, ethereal glow"), "color": "#9370db"},
    # 脚部
    {"name": "item_sandals_straw", "prompt": PROMPT_ITEM.format(desc="simple straw sandals, peasant footwear"), "color": "#deb887"},
    {"name": "item_boots_cloud", "prompt": PROMPT_ITEM.format(desc="blue leather boots with cloud embroidery, light step design"), "color": "#4682b4"},
    {"name": "item_boots_lingbo", "prompt": PROMPT_ITEM.format(desc="white jade boots with flowing water patterns, weightless design"), "color": "#e0ffff"},
    {"name": "item_boots_wind", "prompt": PROMPT_ITEM.format(desc="green wind treader boots with feather motifs, speed lines"), "color": "#32cd32"},
    # 项链
    {"name": "item_necklace_hemp", "prompt": PROMPT_ITEM.format(desc="simple hemp rope necklace with a small jade bead"), "color": "#deb887"},
    {"name": "item_pendant_jade", "prompt": PROMPT_ITEM.format(desc="carved jade pendant on silk cord, elegant green"), "color": "#00fa9a"},
    {"name": "item_necklace_spirit", "prompt": PROMPT_ITEM.format(desc="glowing spirit crystal necklace, multiple blue gems, silver chain"), "color": "#4169e1"},
    {"name": "item_pendant_dragon", "prompt": PROMPT_ITEM.format(desc="dragon bone pendant with embedded fire gem, golden chain, ancient runes"), "color": "#ff4500"},
]


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    # W28
    wf28 = build_workflow(
        icons=NEW_REGION_BGS, master_dir="new_region_bg_1024", final_dir="new_region_bg_final",
        final_size=1024, title="W28 · 新区域探索背景 (5张)",
        note_body=f"5个新区域: 古墓/魔域/天剑峰/虚空/江南\n共 {len(NEW_REGION_BGS)} 张",
    )
    save(wf28, os.path.join(out_dir, "28_new_region_bg_batch_flux.json"))
    print(f"✓ W28 新区域背景 ({len(NEW_REGION_BGS)} 张)")

    # W29
    wf29 = build_workflow(
        icons=NEW_BATTLE_BGS, master_dir="new_battle_bg_1024", final_dir="new_battle_bg_final",
        final_size=1024, title="W29 · 新区域战斗背景 (5张)",
        note_body=f"5个新区域战斗场景\n共 {len(NEW_BATTLE_BGS)} 张",
    )
    save(wf29, os.path.join(out_dir, "29_new_battle_bg_batch_flux.json"))
    print(f"✓ W29 新战斗背景 ({len(NEW_BATTLE_BGS)} 张)")

    # W30
    wf30 = build_workflow(
        icons=NEW_EQUIPMENT_ICONS, master_dir="new_equip_icons_1024", final_dir="new_equip_icons_128",
        final_size=128, title="W30 · 新装备图标 (20张)",
        note_body=f"5槽位 × 4品阶 = 20张装备图标\n共 {len(NEW_EQUIPMENT_ICONS)} 张",
    )
    save(wf30, os.path.join(out_dir, "30_new_equipment_icons_batch_flux.json"))
    print(f"✓ W30 新装备图标 ({len(NEW_EQUIPMENT_ICONS)} 张)")

    total = len(NEW_REGION_BGS) + len(NEW_BATTLE_BGS) + len(NEW_EQUIPMENT_ICONS)
    print(f"\n总计: {total} 张")
    print("在 ComfyUI 中依次加载 W28 / W29 / W30 执行")


if __name__ == "__main__":
    main()
