#!/usr/bin/env python3
# =============================================================================
# 第五批 ComfyUI 工作流生成器
# 产出 2 个 workflow: 13 次要NPC立绘 + 15 奇遇插图
#
# 用法:
#   cd tools/comfyui
#   python3 generate_fifth_batch_workflows.py
#
# 产出 (写入 workflows/):
#   21_npc_secondary_batch_flux.json   (13 次要NPC立绘, 512×512)
#   22_encounter_scenes_batch_flux.json (15 奇遇场景插图, 512×512)
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from generate_batch_workflow import build_workflow, save

# =============================================================================
# 提示词模板
# =============================================================================

PROMPT_TEMPLATE_NPC = (
    "half-body portrait of {desc}, "
    "traditional Chinese ink wash painting style, gongbi technique, "
    "cultivation immortal xianxia aesthetic, "
    "plain background, centered composition, "
    "detailed face and clothing, high quality, 8k"
)

PROMPT_TEMPLATE_ENCOUNTER = (
    "atmospheric scene of {desc}, "
    "Song Dynasty Chinese landscape painting style, "
    "shanshui ink wash technique, misty mountains, "
    "dramatic lighting, cinematic composition, "
    "cultivation immortal xianxia world, "
    "no text no watermark, high quality, 8k"
)

# =============================================================================
# W21: 次要NPC立绘 (对话中出现但没有立绘的角色)
# =============================================================================

NPC_SECONDARY = [
    {
        "name": "portrait_village_head",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="an elderly Chinese village chief, gray beard, wise eyes, wearing simple brown robes, wooden staff"
        ),
        "color": "#6b8e6b",
    },
    {
        "name": "portrait_wang_tiejiang",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a muscular Chinese blacksmith, soot-stained face, leather apron, strong arms, holding a hammer"
        ),
        "color": "#8b6914",
    },
    {
        "name": "portrait_li_popo",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a kind old Chinese grandmother, silver hair in a bun, gentle smile, wearing traditional hanfu, holding medicine pouch"
        ),
        "color": "#cd8c95",
    },
    {
        "name": "portrait_woodcutter",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a rugged Chinese woodcutter, weathered face, straw hat, carrying an axe over shoulder, simple linen clothes"
        ),
        "color": "#8b7355",
    },
    {
        "name": "portrait_demonic_leader",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a sinister demonic cult leader, pale skin, red eyes, dark flowing robes with crimson patterns, menacing aura"
        ),
        "color": "#8b0000",
    },
    {
        "name": "portrait_ancient_spirit",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a translucent ancient spirit, ethereal glow, long white hair floating, ancient cultivator robes, wisdom in eyes"
        ),
        "color": "#b0c4de",
    },
    {
        "name": "portrait_tianjian_messenger",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a stern sword sect messenger, sharp features, wearing white and gold robes, sword emblem on chest"
        ),
        "color": "#daa520",
    },
    {
        "name": "portrait_tianjian_outsider",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a mysterious outsider cultivator, travel-worn clothes, hood partially covering face, dual swords on back"
        ),
        "color": "#696969",
    },
    {
        "name": "portrait_town_leader",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a dignified small town mayor, middle-aged, neat beard, silk robes with jade ornaments, official hat"
        ),
        "color": "#4682b4",
    },
    {
        "name": "portrait_mob_xiushi",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a common low-rank cultivator, young face, basic blue robes, small sword at waist, eager expression"
        ),
        "color": "#5f9ea0",
    },
    {
        "name": "portrait_villager_a",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a young Chinese farmer, tanned skin, straw hat, carrying a hoe, simple cotton clothes, honest face"
        ),
        "color": "#9acd32",
    },
    {
        "name": "portrait_villager_b",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a middle-aged Chinese merchant woman, kind face, hair in a practical bun, colorful market clothes"
        ),
        "color": "#db7093",
    },
    {
        "name": "portrait_wandering_elder",
        "prompt": PROMPT_TEMPLATE_NPC.format(
            desc="a wandering Taoist elder, long white beard, bamboo hat, tattered cloud-patterned robes, carrying a gourd"
        ),
        "color": "#708090",
    },
]

# =============================================================================
# W22: 奇遇场景插图 (选 15 个最有画面感的奇遇)
# =============================================================================

ENCOUNTER_SCENES = [
    {
        "name": "encounter_ancient_stele",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a glowing ancient stone stele covered in mysterious runes in a misty forest, golden light emanating from carved symbols"
        ),
        "color": "#daa520",
    },
    {
        "name": "encounter_hidden_cave",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a hidden cave entrance behind a waterfall in mountains, glowing crystals inside, mysterious mist flowing out"
        ),
        "color": "#4169e1",
    },
    {
        "name": "encounter_dao_trial",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a spiritual trial ground floating in clouds, ancient stone platforms connected by light bridges, celestial energy"
        ),
        "color": "#9370db",
    },
    {
        "name": "encounter_hermit_hut",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a secluded hermit's bamboo hut on a misty mountain peak, herb garden, meditation circle, crane nearby"
        ),
        "color": "#2e8b57",
    },
    {
        "name": "encounter_cultivation_clash",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="two cultivators clashing with sword qi and palm energy in a bamboo forest, energy shockwaves"
        ),
        "color": "#dc143c",
    },
    {
        "name": "encounter_spirit_herb",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a rare glowing spirit herb growing on a cliff edge, surrounded by spiritual butterflies and mist"
        ),
        "color": "#00fa9a",
    },
    {
        "name": "encounter_spirit_beast",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a majestic spirit beast (white tiger with blue stripes) resting in a moonlit clearing, ethereal glow"
        ),
        "color": "#87ceeb",
    },
    {
        "name": "encounter_alchemy_furnace",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="an ancient alchemy furnace emitting colorful smoke in an underground chamber, pill ingredients floating"
        ),
        "color": "#ff6347",
    },
    {
        "name": "encounter_mystery_merchant",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a mysterious merchant's stall at a misty crossroad, exotic treasures displayed, lanterns glowing"
        ),
        "color": "#ffd700",
    },
    {
        "name": "encounter_sword_tomb",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="an ancient sword tomb with hundreds of swords embedded in stone, central sword glowing with power"
        ),
        "color": "#c0c0c0",
    },
    {
        "name": "encounter_illusion_maze",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a mystical illusion maze made of shifting fog and mirror-like surfaces, distorted reflections"
        ),
        "color": "#da70d6",
    },
    {
        "name": "encounter_spirit_vein",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="an underground spirit stone vein, crystalline walls glowing blue and white, energy streams flowing"
        ),
        "color": "#00bfff",
    },
    {
        "name": "encounter_demon_ambush",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a dark forest clearing where demonic cultivators emerge from shadows, red evil qi rising from ground"
        ),
        "color": "#8b0000",
    },
    {
        "name": "encounter_immortal_cave",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a grand immortal's cave dwelling inside a mountain, jade pillars, flowing water, spiritual formation circles"
        ),
        "color": "#20b2aa",
    },
    {
        "name": "encounter_heavenly_phenomenon",
        "prompt": PROMPT_TEMPLATE_ENCOUNTER.format(
            desc="a spectacular heavenly phenomenon in the sky, swirling spiritual clouds forming a vortex, lightning and aurora"
        ),
        "color": "#9932cc",
    },
]


# =============================================================================
# 生成
# =============================================================================

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    # W21: 次要NPC立绘 512×512
    wf21 = build_workflow(
        icons=NPC_SECONDARY,
        master_dir="npc_secondary_1024",
        final_dir="npc_secondary_512",
        final_size=512,
        title="W21 · 次要NPC立绘 (13张)",
        note_body=(
            "第五批 — 次要NPC半身立绘\n"
            "对话中出现但无立绘的角色: 村长/铁匠/李婆婆/樵夫/魔道首领 等\n"
            "风格: 工笔 + 水墨半身像, 与第四批主角立绘一致\n"
            "输出: 1024 母版 + 512 游戏用\n\n"
            f"共 {len(NPC_SECONDARY)} 张"
        ),
    )
    path21 = os.path.join(out_dir, "21_npc_secondary_batch_flux.json")
    save(wf21, path21)
    print(f"✓ W21 次要NPC立绘 ({len(NPC_SECONDARY)} 张) → {path21}")

    # W22: 奇遇场景插图 512×512
    wf22 = build_workflow(
        icons=ENCOUNTER_SCENES,
        master_dir="encounter_scenes_1024",
        final_dir="encounter_scenes_512",
        final_size=512,
        title="W22 · 奇遇场景插图 (15张)",
        note_body=(
            "第五批 — 奇遇事件场景插图\n"
            "30 条奇遇中选 15 个最有画面感的: 石碑/洞窟/剑冢/幻阵 等\n"
            "风格: 宋代山水 + 水墨, 与背景图一致\n"
            "输出: 1024 母版 + 512 游戏用\n\n"
            f"共 {len(ENCOUNTER_SCENES)} 张"
        ),
    )
    path22 = os.path.join(out_dir, "22_encounter_scenes_batch_flux.json")
    save(wf22, path22)
    print(f"✓ W22 奇遇场景插图 ({len(ENCOUNTER_SCENES)} 张) → {path22}")

    print(f"\n总计: {len(NPC_SECONDARY) + len(ENCOUNTER_SCENES)} 张")
    print("下一步: 在 ComfyUI 中依次加载 W21 / W22 执行")


if __name__ == "__main__":
    main()
