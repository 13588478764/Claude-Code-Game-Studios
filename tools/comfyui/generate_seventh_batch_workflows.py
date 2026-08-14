#!/usr/bin/env python3
# =============================================================================
# 第七批 ComfyUI 工作流生成器
# 产出 3 个 workflow:
#   W25: 区域背景时段变体 (8张 = 4区域 × 黄昏/夜晚)
#   W26: NPC 表情变体 (12张 = 6NPC × 开心/生气)
#   W27: 境界突破插图 (10张 = 10境界)
#
# 合计 30 张
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from generate_batch_workflow import build_workflow, save

# =============================================================================
# W25: 区域背景时段变体
# 每个区域已有白天版，补黄昏和夜晚
# =============================================================================

PROMPT_BG_VARIANT = (
    "wide panoramic landscape scene, {desc}, "
    "Song Dynasty Chinese landscape painting style, shanshui ink wash, "
    "no characters no people, cinematic composition, "
    "cultivation immortal xianxia world, no text no watermark, high quality, 8k"
)

REGION_BG_VARIANTS = [
    # 青云镇
    {"name": "bg_town_street_dusk", "prompt": PROMPT_BG_VARIANT.format(
        desc="ancient Chinese town street at dusk, golden sunset light, long shadows, lanterns starting to glow, warm orange atmosphere"
    ), "color": "#e8a040"},
    {"name": "bg_town_street_night", "prompt": PROMPT_BG_VARIANT.format(
        desc="ancient Chinese town street at night, red lanterns illuminating the path, moonlight, quiet atmosphere, stars above"
    ), "color": "#1a1a40"},
    # 黑风寨
    {"name": "bg_evil_camp_dusk", "prompt": PROMPT_BG_VARIANT.format(
        desc="dark bandit fortress at dusk, blood red sky, crows flying, ominous silhouette of watchtowers"
    ), "color": "#8b2020"},
    {"name": "bg_evil_camp_night", "prompt": PROMPT_BG_VARIANT.format(
        desc="dark bandit fortress at night, burning torches, dark clouds covering moon, sinister atmosphere"
    ), "color": "#2a1a1a"},
    # 青云山
    {"name": "bg_sect_hall_dusk", "prompt": PROMPT_BG_VARIANT.format(
        desc="mountain sect temple hall at dusk, golden clouds, incense smoke rising, peaceful sunset glow on stone steps"
    ), "color": "#d4a060"},
    {"name": "bg_sect_hall_night", "prompt": PROMPT_BG_VARIANT.format(
        desc="mountain sect temple hall at night, moonlit couryard, meditation candles flickering, stars and spiritual energy"
    ), "color": "#1a2040"},
    # 江南水乡
    {"name": "bg_mystic_forest_dusk", "prompt": PROMPT_BG_VARIANT.format(
        desc="misty bamboo forest and waterway at dusk, golden light filtering through leaves, reflections on still water"
    ), "color": "#b08040"},
    {"name": "bg_mystic_forest_night", "prompt": PROMPT_BG_VARIANT.format(
        desc="misty bamboo forest at night, fireflies glowing, moonlight creating silver patterns on water, magical atmosphere"
    ), "color": "#0a2a20"},
]

# =============================================================================
# W26: NPC 表情变体 (6主要NPC × 开心/生气)
# =============================================================================

PROMPT_NPC_EMOTION = (
    "half-body portrait of {desc}, {emotion_desc}, "
    "traditional Chinese ink wash painting style, gongbi technique, "
    "cultivation immortal xianxia aesthetic, "
    "plain background, centered composition, high quality, 8k"
)

NPC_BASE = [
    ("yunzhonghe", "a young male sword cultivator with long black hair tied in a topknot, green robes, sword on back"),
    ("liuruyan", "a graceful young woman with flowing hair, elegant pink and white hanfu, gentle features"),
    ("xuanjizhenren", "an elderly Taoist master with long white beard, green robes, jade staff"),
    ("xiaohanye", "a cold young man with sharp features, dark robes with red patterns, dual daggers"),
    ("xuewuhen", "a sinister man with pale skin, blood red robes, scar across face"),
    ("murongxue", "a beautiful woman with snow white hair, ice blue hanfu, aloof expression"),
]

EMOTIONS = [
    ("happy", "smiling warmly, eyes sparkling with joy, relaxed posture"),
    ("angry", "frowning intensely, clenched jaw, fierce eyes, tense stance"),
]

NPC_EMOTION_VARIANTS = []
for npc_id, npc_desc in NPC_BASE:
    for emotion_id, emotion_desc in EMOTIONS:
        NPC_EMOTION_VARIANTS.append({
            "name": f"portrait_{npc_id}_{emotion_id}",
            "prompt": PROMPT_NPC_EMOTION.format(desc=npc_desc, emotion_desc=emotion_desc),
            "color": "#6080a0",
        })

# =============================================================================
# W27: 境界突破插图 (10境界)
# =============================================================================

PROMPT_BREAKTHROUGH = (
    "spectacular cultivation breakthrough scene, {desc}, "
    "dramatic spiritual energy explosion, chinese fantasy xianxia art style, "
    "glowing aura surrounding a meditating cultivator silhouette, "
    "cinematic lighting, epic scale, no text, high quality, 8k"
)

REALMS = [
    ("lianqi", "初入修真, 灵气入体", "faint wisps of spiritual energy entering body, dawn light, simple meditation room"),
    ("zhuji", "筑基期", "foundation forming, earth energy rising from ground, stone pillars cracking, amber glow"),
    ("jindan", "金丹期", "golden core forming in dantian, blinding golden sphere of light, floating rocks"),
    ("yuanying", "元婴期", "nascent soul emerging, ghostly inner self projection, purple and blue energy vortex"),
    ("huashen", "化神期", "divine transformation, body dissolving into pure energy, celestial phenomenon in sky"),
    ("fanxu", "返虚期", "returning to void, reality bending, space distortion around cultivator, cosmic backdrop"),
    ("hedao", "合道期", "merging with the Dao, yin-yang symbol manifesting, heaven and earth converging"),
    ("dasheng", "大乘期", "great vehicle attainment, buddha-like golden aura, lotus flowers blooming in void"),
    ("dujie", "渡劫期", "heavenly tribulation, massive lightning bolts from dark clouds, cultivator standing firm"),
    ("zhenxian", "真仙", "true immortal ascension, breaking through sky barrier, divine light pillar reaching heaven"),
]

BREAKTHROUGH_SCENES = []
for realm_id, realm_name, desc in REALMS:
    BREAKTHROUGH_SCENES.append({
        "name": f"breakthrough_{realm_id}",
        "prompt": PROMPT_BREAKTHROUGH.format(desc=desc),
        "color": "#ffd700",
    })


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    # W25: 区域背景变体
    wf25 = build_workflow(
        icons=REGION_BG_VARIANTS,
        master_dir="region_bg_variants_1024",
        final_dir="region_bg_variants_final",
        final_size=1024,
        title="W25 · 区域背景时段变体 (8张)",
        note_body=f"4区域 × 黄昏/夜晚 = 8张\n宋代山水风格\n共 {len(REGION_BG_VARIANTS)} 张",
    )
    path25 = os.path.join(out_dir, "25_region_bg_variants_batch_flux.json")
    save(wf25, path25)
    print(f"✓ W25 区域背景变体 ({len(REGION_BG_VARIANTS)} 张) → {path25}")

    # W26: NPC 表情变体
    wf26 = build_workflow(
        icons=NPC_EMOTION_VARIANTS,
        master_dir="npc_emotions_1024",
        final_dir="npc_emotions_512",
        final_size=512,
        title="W26 · NPC 表情变体 (12张)",
        note_body=f"6NPC × 开心/生气 = 12张\n风格与主立绘一致\n共 {len(NPC_EMOTION_VARIANTS)} 张",
    )
    path26 = os.path.join(out_dir, "26_npc_emotions_batch_flux.json")
    save(wf26, path26)
    print(f"✓ W26 NPC 表情变体 ({len(NPC_EMOTION_VARIANTS)} 张) → {path26}")

    # W27: 境界突破插图
    wf27 = build_workflow(
        icons=BREAKTHROUGH_SCENES,
        master_dir="breakthrough_1024",
        final_dir="breakthrough_512",
        final_size=512,
        title="W27 · 境界突破插图 (10张)",
        note_body=f"10境界各1张突破场景\n修真能量爆发 + 修炼者剪影\n共 {len(BREAKTHROUGH_SCENES)} 张",
    )
    path27 = os.path.join(out_dir, "27_breakthrough_scenes_batch_flux.json")
    save(wf27, path27)
    print(f"✓ W27 境界突破插图 ({len(BREAKTHROUGH_SCENES)} 张) → {path27}")

    total = len(REGION_BG_VARIANTS) + len(NPC_EMOTION_VARIANTS) + len(BREAKTHROUGH_SCENES)
    print(f"\n总计: {total} 张")
    print("在 ComfyUI 中依次加载 W25 / W26 / W27 执行")


if __name__ == "__main__":
    main()
