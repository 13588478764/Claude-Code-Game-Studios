#!/usr/bin/env python3
# =============================================================================
# 第十批 ComfyUI 工作流生成器
# W33: 15张奇遇插图 (补齐16-30号奇遇)
# W34: 16张武学技能图标 (第一批, 少林/武当/丐帮/天剑)
# W35: 16张武学技能图标 (第二批, 逍遥/明教/魔教/唐门/五毒/通用)
#
# 合计 47 张
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from generate_batch_workflow import build_workflow, save

# =============================================================================
# W33: 奇遇插图补齐 (15张, 16-30号)
# =============================================================================

PROMPT_ENCOUNTER = (
    "atmospheric scene of {desc}, "
    "Song Dynasty Chinese landscape painting style, "
    "shanshui ink wash technique, misty mountains, "
    "dramatic lighting, cinematic composition, "
    "cultivation immortal xianxia world, no text no watermark, high quality, 8k"
)

ENCOUNTER_SCENES_2 = [
    {"name": "encounter_immortal_cave", "prompt": PROMPT_ENCOUNTER.format(
        desc="grand immortal's cave dwelling inside a mountain, jade pillars, flowing water, formation circles"
    ), "color": "#20b2aa"},
    {"name": "encounter_pill_competition", "prompt": PROMPT_ENCOUNTER.format(
        desc="outdoor alchemy competition with multiple furnaces billowing colorful smoke, crowd watching"
    ), "color": "#ff6347"},
    {"name": "encounter_ancient_battlefield", "prompt": PROMPT_ENCOUNTER.format(
        desc="ancient battlefield remnants, broken weapons stuck in ground, ghostly energy lingering, dramatic sky"
    ), "color": "#696969"},
    {"name": "encounter_spirit_pet", "prompt": PROMPT_ENCOUNTER.format(
        desc="a small spirit beast egg glowing in a nest made of spirit herbs, warm golden light"
    ), "color": "#ffd700"},
    {"name": "encounter_mysterious_invitation", "prompt": PROMPT_ENCOUNTER.format(
        desc="mysterious jade invitation card floating in air, golden text glowing, dark elegant background"
    ), "color": "#4169e1"},
    {"name": "encounter_secret_realm", "prompt": PROMPT_ENCOUNTER.format(
        desc="shimmering portal to a secret realm, swirling blue and purple energy vortex in forest clearing"
    ), "color": "#9370db"},
    {"name": "encounter_inner_demon", "prompt": PROMPT_ENCOUNTER.format(
        desc="cultivator facing dark shadow version of themselves, mirror dimension, cracking reality"
    ), "color": "#2f2f2f"},
    {"name": "encounter_treasure_resonance", "prompt": PROMPT_ENCOUNTER.format(
        desc="ancient treasure chest resonating with golden light, underground vault, treasure scattered"
    ), "color": "#daa520"},
    {"name": "encounter_lucky_merchant", "prompt": PROMPT_ENCOUNTER.format(
        desc="mysterious traveling merchant with exotic wares displayed on floating carpet, night market"
    ), "color": "#ff8c00"},
    {"name": "encounter_heavenly_phenomenon", "prompt": PROMPT_ENCOUNTER.format(
        desc="spectacular heavenly phenomenon, swirling spiritual clouds vortex, lightning and aurora in sky"
    ), "color": "#9932cc"},
    {"name": "encounter_cultivation_clash", "prompt": PROMPT_ENCOUNTER.format(
        desc="two cultivators clashing with energy beams in bamboo forest, shockwaves, dramatic"
    ), "color": "#dc143c"},
    {"name": "encounter_herb_garden", "prompt": PROMPT_ENCOUNTER.format(
        desc="hidden spirit herb garden with glowing plants, rainbow dew drops, butterfly spirits"
    ), "color": "#00fa9a"},
    {"name": "encounter_ancient_sword_master", "prompt": PROMPT_ENCOUNTER.format(
        desc="ghost of ancient sword master sitting on stone, hundreds of floating swords around him"
    ), "color": "#c0c0c0"},
    {"name": "encounter_dao_illusion", "prompt": PROMPT_ENCOUNTER.format(
        desc="surreal dao illusion realm, yin-yang symbol in sky, everything mirrored, philosophical"
    ), "color": "#da70d6"},
    {"name": "encounter_sect_tournament", "prompt": PROMPT_ENCOUNTER.format(
        desc="grand martial arts tournament arena, multiple fighting stages, banners of different sects"
    ), "color": "#b22222"},
]

# =============================================================================
# W34: 武学技能图标 第一批 (16张: 少林5 + 武当5 + 丐帮3 + 天剑3)
# =============================================================================

PROMPT_SKILL = (
    "single martial arts technique icon, {desc}, "
    "circular frame with energy glow, Chinese wuxia cultivation style, "
    "centered on dark background, game skill icon, no text, high quality, 8k"
)

SKILL_ICONS_1 = [
    # 少林
    {"name": "skill_icon_shaolin_dali", "prompt": PROMPT_SKILL.format(desc="golden palm strike with shockwave, massive force, monk style"), "color": "#daa520"},
    {"name": "skill_icon_shaolin_jingang", "prompt": PROMPT_SKILL.format(desc="golden body aura shield, diamond unbreakable defense, monk meditation"), "color": "#ffd700"},
    {"name": "skill_icon_shaolin_longzhao", "prompt": PROMPT_SKILL.format(desc="dragon claw grab attack, red and gold energy claws"), "color": "#dc143c"},
    {"name": "skill_icon_shaolin_luohan", "prompt": PROMPT_SKILL.format(desc="arhat fist combo, multiple golden fist afterimages"), "color": "#cd853f"},
    {"name": "skill_icon_shaolin_yijin", "prompt": PROMPT_SKILL.format(desc="body transformation technique, golden energy flowing through meridians"), "color": "#ff8c00"},
    # 武当
    {"name": "skill_icon_wudang_liangyi", "prompt": PROMPT_SKILL.format(desc="yin-yang dual sword technique, black and white intertwined blades"), "color": "#4682b4"},
    {"name": "skill_icon_wudang_taiji", "prompt": PROMPT_SKILL.format(desc="taiji circular energy, soft flowing water-like sword qi"), "color": "#87ceeb"},
    {"name": "skill_icon_wudang_taijiquan", "prompt": PROMPT_SKILL.format(desc="taijiquan palm push, circular force field, gentle but powerful"), "color": "#5f9ea0"},
    {"name": "skill_icon_wudang_zhenwu", "prompt": PROMPT_SKILL.format(desc="zhenwu seven-form sword, seven sword qi stars constellation"), "color": "#191970"},
    {"name": "skill_icon_wudang_basic", "prompt": PROMPT_SKILL.format(desc="basic wudang sword stance, single elegant sword, blue aura"), "color": "#4169e1"},
    # 丐帮
    {"name": "skill_icon_gaibang_dagou", "prompt": PROMPT_SKILL.format(desc="dog-beating staff technique, green bamboo staff swinging"), "color": "#6b8e23"},
    {"name": "skill_icon_gaibang_xianglong", "prompt": PROMPT_SKILL.format(desc="dragon-subduing palm, golden dragon energy palm strike, legendary"), "color": "#ffd700"},
    {"name": "skill_icon_gaibang_xiaoyaoyou", "prompt": PROMPT_SKILL.format(desc="carefree wandering step, wind and leaves swirling around feet"), "color": "#32cd32"},
    # 天剑
    {"name": "skill_icon_tianjian_wanjian", "prompt": PROMPT_SKILL.format(desc="ten thousand swords return, hundreds of flying swords converging"), "color": "#c0c0c0"},
    {"name": "skill_icon_tianjian_yujian", "prompt": PROMPT_SKILL.format(desc="sword control flight, single flying sword with rider silhouette, clouds"), "color": "#87ceeb"},
    {"name": "skill_icon_tianjian_jianguang", "prompt": PROMPT_SKILL.format(desc="sword light flash, single blinding beam of sword energy"), "color": "#f0f8ff"},
]

# =============================================================================
# W35: 武学技能图标 第二批 (16张: 逍遥4 + 明教4 + 魔教3 + 唐门3 + 五毒1 + 通用1)
# =============================================================================

SKILL_ICONS_2 = [
    # 逍遥
    {"name": "skill_icon_xiaoyao_beiming", "prompt": PROMPT_SKILL.format(desc="northern darkness divine art, absorbing blue energy vortex, dark power"), "color": "#000080"},
    {"name": "skill_icon_xiaoyao_lingbo", "prompt": PROMPT_SKILL.format(desc="lingbo microstep, ghostly footprint afterimages, water ripples"), "color": "#e0ffff"},
    {"name": "skill_icon_xiaoyao_tianshan", "prompt": PROMPT_SKILL.format(desc="tianshan plum blossom, ice crystals and pink petals falling"), "color": "#ffb6c1"},
    {"name": "skill_icon_xiaoyao_xiaowuxiang", "prompt": PROMPT_SKILL.format(desc="small formless art, transparent mimicry energy, shapeshifting aura"), "color": "#d3d3d3"},
    # 明教
    {"name": "skill_icon_mingjiao_fentian", "prompt": PROMPT_SKILL.format(desc="heaven-burning flame technique, massive fire tornado"), "color": "#ff4500"},
    {"name": "skill_icon_mingjiao_liehuo", "prompt": PROMPT_SKILL.format(desc="fierce fire palm, hands engulfed in red-orange flames"), "color": "#ff6347"},
    {"name": "skill_icon_mingjiao_qiankun", "prompt": PROMPT_SKILL.format(desc="heaven and earth great shift, reality bending spiral"), "color": "#9400d3"},
    {"name": "skill_icon_mingjiao_shenghuo", "prompt": PROMPT_SKILL.format(desc="sacred fire command, ring of holy fire, sun symbol"), "color": "#ff8c00"},
    # 魔教
    {"name": "skill_icon_mojiao_shihun", "prompt": PROMPT_SKILL.format(desc="soul-devouring technique, dark shadow consuming light"), "color": "#2f0f3f"},
    {"name": "skill_icon_mojiao_xuemo", "prompt": PROMPT_SKILL.format(desc="blood demon art, blood red energy tendrils, dark crimson"), "color": "#8b0000"},
    {"name": "skill_icon_mojiao_dafa", "prompt": PROMPT_SKILL.format(desc="great demonic art, black and purple vortex, corrupting power"), "color": "#4a0080"},
    # 唐门
    {"name": "skill_icon_tangmen_hansha", "prompt": PROMPT_SKILL.format(desc="cold kill hidden weapon, silver needles flying in pattern"), "color": "#c0c0c0"},
    {"name": "skill_icon_tangmen_kongque", "prompt": PROMPT_SKILL.format(desc="peacock plume weapon, fan of golden darts spreading"), "color": "#daa520"},
    {"name": "skill_icon_tangmen_lihua", "prompt": PROMPT_SKILL.format(desc="pear blossom rain needles, shower of thin needles, deadly rain"), "color": "#f5f5dc"},
    # 五毒
    {"name": "skill_icon_wudu_wangu", "prompt": PROMPT_SKILL.format(desc="ten thousand poison technique, green toxic mist, skull symbol"), "color": "#006400"},
    # 通用
    {"name": "skill_icon_generic_qinggong", "prompt": PROMPT_SKILL.format(desc="lightness technique, feather-like leap, wind beneath feet"), "color": "#add8e6"},
]


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    wf33 = build_workflow(
        icons=ENCOUNTER_SCENES_2, master_dir="encounter_scenes2_1024", final_dir="encounter_scenes2_512",
        final_size=512, title="W33 · 奇遇插图补齐 (15张)",
        note_body=f"补齐16-30号奇遇的场景插图\n共 {len(ENCOUNTER_SCENES_2)} 张",
    )
    save(wf33, os.path.join(out_dir, "33_encounter_scenes2_batch_flux.json"))
    print(f"✓ W33 奇遇插图 ({len(ENCOUNTER_SCENES_2)} 张)")

    wf34 = build_workflow(
        icons=SKILL_ICONS_1, master_dir="skill_icons2_1024", final_dir="skill_icons2_128",
        final_size=128, title="W34 · 武学图标第一批 (16张)",
        note_body=f"少林5+武当5+丐帮3+天剑3\n共 {len(SKILL_ICONS_1)} 张",
    )
    save(wf34, os.path.join(out_dir, "34_skill_icons_batch1_flux.json"))
    print(f"✓ W34 武学图标1 ({len(SKILL_ICONS_1)} 张)")

    wf35 = build_workflow(
        icons=SKILL_ICONS_2, master_dir="skill_icons3_1024", final_dir="skill_icons3_128",
        final_size=128, title="W35 · 武学图标第二批 (16张)",
        note_body=f"逍遥4+明教4+魔教3+唐门3+五毒1+通用1\n共 {len(SKILL_ICONS_2)} 张",
    )
    save(wf35, os.path.join(out_dir, "35_skill_icons_batch2_flux.json"))
    print(f"✓ W35 武学图标2 ({len(SKILL_ICONS_2)} 张)")

    total = len(ENCOUNTER_SCENES_2) + len(SKILL_ICONS_1) + len(SKILL_ICONS_2)
    print(f"\n总计: {total} 张")
    print("在 ComfyUI 中依次加载 W33 / W34 / W35 执行")


if __name__ == "__main__":
    main()
