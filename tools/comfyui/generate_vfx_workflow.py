#!/usr/bin/env python3
"""
W36: 战斗特效纹理批量生成
生成 20 张 VFX 纹理（武器特效 4 + 元素特效 12 + 通用 4）
输出 256×256 透明底 PNG，供 CombatVFXManager 使用
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_batch_workflow import build_workflow, save

# 提示词模板 — 特效纹理（透明底、发光、能量感）
PROMPT_VFX = (
    "single game visual effect texture, {desc}, "
    "glowing energy effect, transparent black background, "
    "2D game VFX sprite, centered composition, "
    "high contrast, vibrant colors, no text, 8k quality"
)

# ============================================================================
# 武器类特效纹理（4 张）
# ============================================================================
WEAPON_VFX = [
    {
        "name": "vfx_slash_arc",
        "prompt": PROMPT_VFX.format(
            desc="white crescent sword slash arc trail, sharp curved blade energy, "
                 "luminous white-blue sweep motion, horizontal slash mark"
        ),
        "color": "#e0e0ff",
    },
    {
        "name": "vfx_fist_wave",
        "prompt": PROMPT_VFX.format(
            desc="circular shockwave fist impact ring, expanding concentric force waves, "
                 "golden-white energy burst, martial arts qi punch explosion"
        ),
        "color": "#ffe0a0",
    },
    {
        "name": "vfx_palm_wind",
        "prompt": PROMPT_VFX.format(
            desc="spiraling wind palm energy vortex, swirling cyan qi force, "
                 "ethereal palm strike wind gust, flowing energy streams"
        ),
        "color": "#a0ffe0",
    },
    {
        "name": "vfx_staff_impact",
        "prompt": PROMPT_VFX.format(
            desc="ground impact shockwave from staff strike, radial crack pattern, "
                 "upward debris and dust explosion, brown-golden earth force"
        ),
        "color": "#c0a060",
    },
]

# ============================================================================
# 元素特效纹理（12 张）
# ============================================================================
ELEMENT_VFX = [
    {
        "name": "vfx_fire_burst",
        "prompt": PROMPT_VFX.format(
            desc="fierce fire explosion burst, orange-red flames erupting outward, "
                 "intense heat glow, martial arts fire technique"
        ),
        "color": "#ff4400",
    },
    {
        "name": "vfx_ice_crystal",
        "prompt": PROMPT_VFX.format(
            desc="shattering ice crystal formation, blue-white frozen shards exploding, "
                 "frost mist particles, freezing cold energy"
        ),
        "color": "#40a0ff",
    },
    {
        "name": "vfx_lightning_bolt",
        "prompt": PROMPT_VFX.format(
            desc="crackling lightning bolt strike, branching purple-white electric arcs, "
                 "thunder energy discharge, electrifying sparks"
        ),
        "color": "#a060ff",
    },
    {
        "name": "vfx_poison_cloud",
        "prompt": PROMPT_VFX.format(
            desc="toxic poison cloud spreading, sickly green miasma with bubbles, "
                 "venomous gas particles, dark green toxic mist"
        ),
        "color": "#40cc40",
    },
    {
        "name": "vfx_metal_glint",
        "prompt": PROMPT_VFX.format(
            desc="sharp metallic golden sword qi blade, gleaming gold metal energy lines, "
                 "shining golden light rays, metal element cultivation power"
        ),
        "color": "#ffd040",
    },
    {
        "name": "vfx_dark_vortex",
        "prompt": PROMPT_VFX.format(
            desc="dark purple shadow vortex swirl, sinister demonic energy spiral, "
                 "dark cultivation technique, black-purple malevolent force"
        ),
        "color": "#6020a0",
    },
    {
        "name": "vfx_light_burst",
        "prompt": PROMPT_VFX.format(
            desc="radiant holy light burst, white-golden divine rays expanding outward, "
                 "buddhist cultivation golden light, sacred illumination"
        ),
        "color": "#ffffcc",
    },
    {
        "name": "vfx_water_splash",
        "prompt": PROMPT_VFX.format(
            desc="water splash wave impact, blue water droplets and spray, "
                 "flowing aqua energy streams, water element cultivation"
        ),
        "color": "#2060ff",
    },
    {
        "name": "vfx_wood_thorns",
        "prompt": PROMPT_VFX.format(
            desc="green vine thorns erupting from ground, living wood tendrils, "
                 "nature energy growth burst, wood element cultivation"
        ),
        "color": "#40a020",
    },
    {
        "name": "vfx_earth_crack",
        "prompt": PROMPT_VFX.format(
            desc="earth crack ground rupture, brown rocky fragments flying upward, "
                 "stone debris explosion, earth element cultivation power"
        ),
        "color": "#a07030",
    },
    {
        "name": "vfx_wind_spiral",
        "prompt": PROMPT_VFX.format(
            desc="swirling wind tornado spiral, cyan-white air current vortex, "
                 "graceful wind blades cutting, wind element cultivation"
        ),
        "color": "#80e0d0",
    },
    {
        "name": "vfx_energy_default",
        "prompt": PROMPT_VFX.format(
            desc="generic white qi energy burst, neutral cultivation power explosion, "
                 "white-blue spiritual energy radiating outward"
        ),
        "color": "#d0d0ff",
    },
]

# ============================================================================
# 通用纹理（4 张）
# ============================================================================
COMMON_VFX = [
    {
        "name": "vfx_hit_spark",
        "prompt": PROMPT_VFX.format(
            desc="impact hit spark explosion, white-yellow sharp spark particles, "
                 "collision flash effect, quick burst of light"
        ),
        "color": "#ffff80",
    },
    {
        "name": "vfx_critical_flash",
        "prompt": PROMPT_VFX.format(
            desc="critical strike star flash, bright white starburst with red edges, "
                 "intense power flash effect, radial light explosion"
        ),
        "color": "#ff8080",
    },
    {
        "name": "vfx_particle_dot",
        "prompt": PROMPT_VFX.format(
            desc="single soft glowing energy orb, smooth gradient circle, "
                 "white-center to transparent-edge, simple particle dot"
        ),
        "color": "#ffffff",
    },
    {
        "name": "vfx_glow_ring",
        "prompt": PROMPT_VFX.format(
            desc="expanding circular glow ring, thin luminous halo circle, "
                 "white energy ring expanding outward, ripple effect"
        ),
        "color": "#e0e0ff",
    },
]

ALL_VFX = WEAPON_VFX + ELEMENT_VFX + COMMON_VFX


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(here, "workflows")
    os.makedirs(out_dir, exist_ok=True)

    note_body = (
        "■ 工作流: W36 战斗特效纹理批量生成 (FLUX)\n"
        "   一次 Queue Prompt 出全部 %d 张\n"
        "   预计耗时 %d-120 分钟 (M4 Pro)\n\n"
        "■ 纹理分类:\n"
        "   武器特效 (4张): 剑气/拳波/掌风/棍击\n"
        "   元素特效 (12张): 火/冰/雷/毒/金/暗/光/水/木/土/风/通用\n"
        "   通用特效 (4张): 受击火花/暴击闪光/粒子圆点/光环\n\n"
        "■ 输出:\n"
        "   output/vfx_textures_1024/[name].png  (1024 母版)\n"
        "   output/vfx_textures_256/[name].png   (256 游戏用)\n\n"
        "■ 回流命令:\n"
        "   mkdir -p assets/ui/vfx/{weapon,element,common}\n"
        "   cp output/vfx_textures_256/vfx_slash_arc.png assets/ui/vfx/weapon/\n"
        "   cp output/vfx_textures_256/vfx_fist_wave.png assets/ui/vfx/weapon/\n"
        "   cp output/vfx_textures_256/vfx_palm_wind.png assets/ui/vfx/weapon/\n"
        "   cp output/vfx_textures_256/vfx_staff_impact.png assets/ui/vfx/weapon/\n"
        "   cp output/vfx_textures_256/vfx_fire_burst.png assets/ui/vfx/element/\n"
        "   (以此类推)\n\n"
        "■ 或使用 import_ai_assets.sh 自动回流"
    ) % (len(ALL_VFX), len(ALL_VFX) * 5)

    wf = build_workflow(
        icons=ALL_VFX,
        master_dir="vfx_textures_1024",
        final_dir="vfx_textures_256",
        final_size=256,
        title="W36 战斗特效纹理批量生成 (共%d张)" % len(ALL_VFX),
        note_body=note_body,
    )
    save(wf, os.path.join(out_dir, "36_vfx_textures_flux.json"))
    print("W36 工作流已生成: workflows/36_vfx_textures_flux.json (%d 张纹理)" % len(ALL_VFX))


if __name__ == "__main__":
    main()
