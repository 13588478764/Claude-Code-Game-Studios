#!/usr/bin/env python3
# =============================================================================
# 第四批 ComfyUI 工作流生成器
# 产出 3 个 workflow: 12 立绘(主角+队友) + 16 敌人立绘 + 15 背景
#
# 用法:
#   cd tools/comfyui
#   python3 generate_fourth_batch_workflows.py
#
# 产出 (写入 workflows/):
#   18_portraits_allies_batch_flux.json   (12 主角+队友立绘, ~91 节点)
#   19_portraits_enemies_batch_flux.json  (16 敌人立绘, ~119 节点)
#   20_backgrounds_batch_flux.json        (15 场景背景, ~112 节点)
#
# 来源 spec:
#   assets/specs/ui/06-portraits-protagonist-allies.md  (12 项)
#   assets/specs/ui/07-portraits-enemies.md             (16 项)
#   assets/specs/ui/08-backgrounds.md                   (15 项)
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_batch_workflow import build_workflow, save


# =============================================================================
# 提示词模板
# =============================================================================

# 立绘: 人物角色, 半身构图, 白底 (BRIA 抠图)
PROMPT_TEMPLATE_PORTRAIT = (
    "A high-quality Chinese cultivation wuxia RPG character portrait, half-body composition "
    "with traditional Chinese gongbi (meticulous brushwork) and ink wash style. "
    "Subject: {subject}. "
    "The character occupies about 80 percent of the canvas, centered. Pure clean solid white "
    "background for easy background removal. Traditional Chinese ink wash painting style combined "
    "with rich gongbi coloring. {palette} color palette. "
    "No modern elements, no western fantasy, no anime style, no text, no watermarks, "
    "no duplicate characters, no full body (half-body only from waist up). "
    "Highest quality concept art, detailed face and clothing, cinematic lighting. "
    "References:Erta (Three Kingdoms TCG),Erta wuxia portraits, Legend of Sword and Fairy, "
    "Black Myth Wukong character concept art."
)

# 背景: 全屏宋代山水画风格, 不需要透明背景
PROMPT_TEMPLATE_BACKGROUND = (
    "A full-screen game background in the style of Song Dynasty landscape painting (shanshui), "
    "widescreen 16:9 composition. Subject: {subject}. "
    "Traditional Chinese ink wash painting style with rich atmosphere. {palette} color palette. "
    "Designed as a game UI background with appropriate negative space for UI overlay. "
    "No modern elements, no western fantasy, no text, no watermarks, no characters or people. "
    "Highest quality landscape concept art, atmospheric depth, layered composition "
    "(foreground, midground, background). "
    "References: Fan Kuan, Ma Yuan, Fu Baoshi landscape paintings, "
    "Legend of Sword and Fairy backgrounds, Genshin Impact environment art."
)


def portrait(name: str, subject: str, palette: str, color: str) -> dict:
    """组装一个立绘 icon dict。"""
    return {
        "name": name,
        "color": color,
        "prompt": PROMPT_TEMPLATE_PORTRAIT.format(subject=subject, palette=palette),
    }


def background(name: str, subject: str, palette: str, color: str) -> dict:
    """组装一个背景 dict。"""
    return {
        "name": name,
        "color": color,
        "prompt": PROMPT_TEMPLATE_BACKGROUND.format(subject=subject, palette=palette),
    }


# =============================================================================
# W18 — 主角 + 队友立绘 12 项
# =============================================================================

PORTRAITS_ALLIES = [
    portrait("portrait_protagonist_male",
             "A young male cultivator around 20 years old, long hair tied in a high ponytail "
             "with a cyan jade hairpin, wearing a cyan Taoist robe with cream-white inner layer, "
             "a dark silk sash at the waist with jade pendant, holding a cyan-bladed sword in "
             "right hand behind back, sharp yet scholarly features, calm confident expression",
             "cyan green, cream white, dark ink black, jade highlight",
             "#2E8B57"),
    portrait("portrait_protagonist_female",
             "A young female cultivator around 20 years old, long hair partially pinned up "
             "with a cyan jade hairpin flowing over shoulders, wearing a light cyan Taoist robe "
             "with cream-white inner layer, a dark silk sash with jade pendant, left hand resting "
             "on sword hilt at waist, delicate features with cool composed expression",
             "cyan green, cream white, dark ink black, jade highlight",
             "#2E8B57"),
    portrait("portrait_yunzhonghe",
             "An elderly male cultivator around 60 years old, crane-white hair and long chest-"
             "length beard, white jade hairpin, wearing a teal-green long robe with jade-white "
             "inner layer, waist adorned with jade pendant and antique bronze gourd, holding "
             "a white jade horsetail whisk, benevolent immortal-sage appearance with cinnabar "
             "mole between eyebrows, wise warm smile",
             "teal green, jade white, antique bronze, cinnabar red dot",
             "#3CB371"),
    portrait("portrait_liuruyan",
             "A young female sword cultivator around 22, long hair in high bun with silver "
             "hairpin and one loose strand at temple, wearing white robe with red trim sword-"
             "wielding martial outfit, crimson sash with jade pendant, a silver-sheathed longsword "
             "strapped on back, sharp cold beautiful features, distant aloof expression",
             "pure white, crimson red trim, silver steel, ice-cold palette",
             "#DC143C"),
    portrait("portrait_xiaohanye",
             "A young male cultivator around 25, long black hair partially loose, wearing "
             "ink-black long robe with deep crimson inner lining, gold subtle patterns on hem, "
             "holding a pitch-black demonic blade with red blood-vein patterns, handsome "
             "sharp features with purple-tinted eyes, sinister smirk expression",
             "ink black, deep crimson, gold accent, purple eye highlight",
             "#4B0082"),
    portrait("portrait_murongxue",
             "A young female cultivator around 23, silver-white long hair to waist with blue "
             "jade ornament, snow-white skin, wearing white and ice-blue layered gauze dress "
             "with light blue cloak, blue crystal necklace, ice-sculpted beautiful features "
             "with pale blue eyes, elegant distant expression with a hint of melancholy",
             "ice blue, silver white, crystal highlight, cold palette",
             "#4682B4"),
    portrait("portrait_tiewushuang",
             "A young burly male around 20, short black hair with headband, wearing brown "
             "martial robe with cream inner layer, thick hemp sash with gourd wine flask, "
             "carrying a massive iron staff on shoulder, broad stocky build, honest simple "
             "features with thick eyebrows, cheerful hearty laugh expression",
             "warm brown, cream white, iron gray, earthy tones",
             "#8B4513"),
    portrait("portrait_shenqingluo",
             "A young female healer cultivator around 18, black hair simply tied up with bangs, "
             "wearing light green medical cultivator robe with white inner layer, herb pouch "
             "and jade gourd at waist, sweet delicate features with gentle curved smile, "
             "holding a luminous green spirit herb in both hands",
             "soft green, white, jade green herb glow, gentle palette",
             "#90EE90"),
    portrait("portrait_chutiannan",
             "A young male wanderer-poet around 27, long hair loosely tied back, wearing "
             "cream-white scholar robe with light cyan sash, wine gourd over shoulder, "
             "antique sword hung diagonally at waist, handsome weathered features with "
             "carefree tipsy expression, holding a scroll in one hand and wine cup in other",
             "cream white, light cyan, wine-amber, carefree palette",
             "#F5F5DC"),
    portrait("portrait_xuanjizi",
             "An elderly male diviner around 70, white sparse hair and long beard, wearing "
             "Taoist priest cap, deep purple robe embroidered with gold bagua trigram patterns, "
             "holding tortoise shell and divination sticks, gaunt immortal features with "
             "enigmatic squinting smile",
             "deep purple, gold trigram, bone white, mystic palette",
             "#4B0082"),
    portrait("portrait_guchangge",
             "A young female around 24, black long hair with one red-dyed streak, wearing "
             "tattered black-red martial robe, a red scar on shoulder, iron chain at waist "
             "with crescent moon blade, cold beautiful sharp features with determined fierce "
             "eyes showing inner struggle",
             "black, deep red, iron chain gray, conflicted palette",
             "#8B0000"),
    portrait("portrait_lingxi",
             "A young spirit-form girl around 16, fluffy silver-white hair with faint white "
             "fox ears on top, wearing white and pale-red trimmed short hanfu skirt, a fluffy "
             "white fox tail at waist, amber-gold eyes, sprite-like playful features with "
             "mischievous cute expression, cupping cheeks with both hands",
             "silver white, pale red trim, amber gold eyes, ethereal palette",
             "#FFD700"),
]

# =============================================================================
# W19 — 敌人立绘 16 项
# =============================================================================

PORTRAITS_ENEMIES = [
    portrait("enemy_bandit_minion",
             "A middle-aged male mountain bandit around 35, messy black hair with cloth "
             "headband, wearing torn brown leather armor with dark rough pants, hemp rope "
             "and short knife at waist, brutal scarred face with knife scar over left eye, "
             "fierce snarling expression, holding a large cleaver axe in attack pose",
             "dull brown, rough leather, bloodstain red, bandit palette",
             "#8B4513"),
    portrait("enemy_evil_disciple",
             "A young male evil cultivator around 25, black hair half covering face, wearing "
             "black-red evil sect robe with skull embroidery, blood-red bells at waist, holding "
             "a bloodstained crescent moon blade, pale sinister face with dark red eyes, "
             "eerie cold smirk expression, surrounded by dark purple qi",
             "black, crimson red, skull bone white, evil purple qi",
             "#601020"),
    portrait("enemy_fire_wolf",
             "A medium-sized spirit beast fire wolf, entire body covered in blazing red fur "
             "like dancing flames, sharp fangs bared, golden-red eyes, fire pattern markings "
             "along spine, four paws treading on flowing fire, low crouching howl pose",
             "blazing red, golden fire, dark amber, fierce palette",
             "#FF4500"),
    portrait("enemy_water_serpent",
             "A large cyan-blue water serpent coiled above water ripples, scales gleaming "
             "with blue-green luster, serpent head bearing two short horns, forked tongue "
             "flickering, ethereal blue eyes, surrounded by water mist and droplets",
             "cyan blue, aqua green shimmer, deep blue eyes, water palette",
             "#4682B4"),
    portrait("enemy_mountain_ogre",
             "A hulking mountain ogre about 2 meters tall, skin in ochre-yellow color with "
             "rock-crack texture patterns, wearing rough hemp loincloth, carrying a massive "
             "stone club on shoulder, grotesque face with protruding tusks, brutish expression, "
             "Eastern yokai style not Western orc",
             "ochre yellow, stone gray, hemp brown, earth monster palette",
             "#8B6914"),
    portrait("enemy_ghost_cultivator",
             "A semi-transparent ghost cultivator apparition, wearing tattered white burial "
             "shroud, disheveled long hair covering face revealing only one pale half-face, "
             "ghostly green eyes, hands with pale white claws, surrounded by black-purple "
             "ghost qi, background of faint tombstone silhouettes",
             "translucent white, ghostly green, black-purple qi, spectral palette",
             "#006400"),
    portrait("enemy_fox_spirit",
             "A young female fox spirit cultivator around 25, flowing crimson-red long hair, "
             "crimson fox ears atop head, nine red-orange fox tails swaying behind, wearing "
             "red-black short martial dress, copper bells at waist, bewitching seductive face "
             "with amber-gold eyes, holding a red feather fan",
             "crimson red, amber gold, fox fire orange, seductive palette",
             "#FF6347"),
    portrait("enemy_puppet_cultivator",
             "A wooden puppet cultivator with stiff mechanical posture, entire body made of "
             "antique bronze-colored wood, joints connected by gold wire, face is a white "
             "porcelain mask with Taoist rune patterns, a dark puppet core embedded in chest, "
             "holding metallic mechanical claws",
             "antique bronze wood, gold wire, white porcelain, mechanical palette",
             "#B8860B"),
    portrait("enemy_evil_elder",
             "An evil sect elder around 50, gray-white hair in topknot crown, wearing deep "
             "purple robe embroidered with gold skull patterns, blood-colored bone bead string "
             "at waist, deeply wrinkled sinister face with dark purple eyes, cruel arrogant "
             "expression, holding bloodstained blood-jade walking staff",
             "deep purple, gold skull, blood jade red, dark authority palette",
             "#4B0082"),
    portrait("enemy_thunder_beast_king",
             "A massive spirit beast thunder eagle with 5-meter wingspan, golden-yellow "
             "feathers with purple-black lightning streak patterns, enormous sharp talons, "
             "golden beak, piercing golden eyes flashing with lightning, background of "
             "purple storm clouds crackling with electricity",
             "golden yellow, purple-black lightning, storm gray, thunder palette",
             "#DAA520"),
    portrait("enemy_elemental_guardian",
             "A five-element guardian humanoid construct made of interweaving elemental "
             "energies — left arm is a golden metal sword, right arm is green vine tendrils, "
             "shoulders are water waves, chest is flame core, feet rooted in earth — "
             "face has no features only a glowing taiji-eye, five elements swirling around",
             "gold metal, green wood, blue water, red fire, brown earth",
             "#FFD700"),
    portrait("enemy_boss_xuesha_patriarch",
             "Blood Shadow Patriarch boss, around 100 years old but middle-aged appearance, "
             "blood-red long hair like flames, wearing blood-red robe embroidered with gold "
             "skulls with flowing hem, ink-black demon-patterned sash, pale skin with blood "
             "vein marks, blood-red eyes radiating murderous light, coalescing a massive "
             "blood-colored battle axe behind him, background of blood qi vortex and floating "
             "skulls, overwhelming terrifying aura",
             "blood red, gold skull accent, ink black, pale death white",
             "#8B0000"),
    portrait("enemy_boss_beast_king",
             "Myriad Beast King boss in half-human half-beast form, upper body is a powerful "
             "male around 30 with beast-king crown and black flowing hair, lower body transforms "
             "into a massive golden lion-tiger beast body with four claws, nine different beast "
             "tails (tiger/wolf/fox/serpent etc.) behind, holding nine-segment beast-king bone "
             "staff, golden-red eyes radiating overwhelming dominance",
             "royal gold, beast fur tawny, crimson, bone white staff",
             "#DAA520"),
    portrait("enemy_boss_demon_god",
             "Ancient Demon God boss with massive 4-meter body, ink-black skin inscribed with "
             "ancient rune patterns, three heads and six arms — central head is human wearing "
             "gold mask, left head is dragon, right head is tiger — six arms each holding "
             "different ancient divine weapons (sword/halberd/hammer/bow/shield/bell), golden "
             "radiant halo behind, overwhelming cosmic presence",
             "ink black rune skin, gold mask, divine weapon metallic, cosmic palette",
             "#191970"),
    portrait("enemy_boss_heart_demon",
             "Heart Demon Self boss, identical appearance to protagonist but corrupted — "
             "original cyan robe turned black-red, original calm expression turned cold manic, "
             "blood-red eyes weeping black demon qi tears, holding a blood-colored mirror sword, "
             "entire body emanating purple-black heart demon aura, background of shattered "
             "mirror fragments and black-red vortex",
             "corrupted black-red, blood mirror, purple-black qi, mirror fragments",
             "#4B0082"),
    portrait("enemy_boss_tianjie_zhenjun",
             "Heavenly Tribulation Lord final boss, transcendent divine yet stern figure, "
             "gold-purple hair flowing to ankles, wearing nine-colored aurora Taoist robe "
             "with sun-moon-stars patterns, holding purple-gold thunder whip, face like "
             "sculpted celestial being, eyes transformed into sun-moon dual wheels, "
             "nine layers of golden-purple thunder clouds swirling behind, "
             "gold-purple lightning wrapping entire body",
             "gold-purple, aurora nine-color, divine white, thunder blue-white",
             "#9400D3"),
]

# =============================================================================
# W20 — 场景背景 15 项
# =============================================================================

BACKGROUNDS = [
    background("bg_main_menu",
               "Distant immortal mountain peaks emerging from a sea of clouds, a wooden "
               "pavilion floating in mid-air in midground, an ancient twisted pine tree in "
               "foreground right with branches extending into frame. Large negative space on "
               "left side for game logo and menu buttons. Ethereal misty atmosphere",
               "pale cyan-green, cream white, light ink wash, ethereal",
               "#2E8B57"),
    background("bg_loading",
               "Distant faint ink mountain silhouettes wrapped in clouds, a tiny pavilion on "
               "a small ridge in midground, foreground is empty space with a few drifting bamboo "
               "leaves. Large negative space at bottom for loading bar. Serene minimalist",
               "cream white, pale ink, faint cyan, minimalist zen",
               "#F5F5DC"),
    background("bg_settings",
               "Extremely faint and subtle ink mountain landscape watermark serving as panel "
               "backdrop texture. Very low opacity, almost pure pale gray with barely visible "
               "mountain outlines. UI-friendly low contrast",
               "pale gray, subtle ink outlines, near-white, understated",
               "#DCDCDC"),
    background("bg_pause",
               "A semi-transparent dark overlay background with a faint centered taiji yin-yang "
               "symbol watermark in the middle, subtle ink wash clouds barely visible. Dark "
               "contemplative mood",
               "dark ink semi-transparent, subtle taiji symbol, muted gray",
               "#333333"),
    background("bg_save_load",
               "Distant misty mountain range, midground features an unrolled ancient bamboo "
               "scroll floating among mountains, foreground negative space for save slot list. "
               "Warm antique paper tones",
               "warm cream-yellow, pale ink mountains, bamboo scroll brown, antique",
               "#DEB887"),
    background("bg_sect_hall",
               "Interior of a grand cultivation sect main hall, ornate gold-painted carved "
               "ceiling beams, central floor with bagua eight-trigram formation tiles, taiji "
               "scroll hanging on back wall, dragon relief pillars on both sides, light beams "
               "streaming through lattice windows. Solemn majestic interior",
               "deep crimson red, gold lacquer, ink black, solemn warm",
               "#B22222"),
    background("bg_mystic_forest",
               "Ancient mysterious mountain forest, distant cloud-wrapped peaks, midground "
               "ancient pines and bamboo grove flanking a stone stairway path leading up, "
               "foreground moss-covered boulders. Mystical ethereal forest atmosphere",
               "deep green, ink black, cream mist, forest mystical",
               "#228B22"),
    background("bg_town_street",
               "Traditional Chinese town bustling street scene, distant city tower with "
               "flying eaves, midground wooden shops lining both sides hung with red lanterns "
               "and wine banners, foreground cobblestone road with blurred pedestrian "
               "silhouettes. Warm lively street atmosphere",
               "warm amber-yellow, ink black, lantern red, market warmth",
               "#DAA520"),
    background("bg_ancient_tomb",
               "Deep ancient tomb interior, distant stone sarcophagus and burial treasures "
               "in shadow, midground stone walls carved with ancient rune inscriptions, "
               "foreground cobwebs and dark shadows on floor, single shaft of light from "
               "ceiling crack. Eerie mysterious underground",
               "ink black, dark purple, dim amber light shaft, tomb palette",
               "#2F2F2F"),
    background("bg_immortal_palace",
               "Immortal celestial palace interior space, distant jade palaces floating in "
               "cloud sea, midground white jade staircase and lotus pond, foreground immortal "
               "cranes and spirit herbs. Divine transcendent atmosphere",
               "pale cyan, white jade, pale gold, divine ethereal",
               "#E0FFFF"),
    background("bg_evil_camp",
               "Evil cultivation sect stronghold, distant blood-red mountain silhouettes under "
               "ominous sky, midground a dark altar shrouded in black demonic qi with blood-"
               "stained bone banners, foreground shattered puppet remains and dark bloodstains. "
               "Sinister malevolent atmosphere",
               "blood red, ink black, dark purple, sinister evil",
               "#4B0000"),
    background("bg_battle_plains",
               "Open plains battle scene, distant faint ink mountains with drifting clouds, "
               "midground a few lone trees and rolling grass slopes, foreground open negative "
               "space for battle UI character positioning. Expansive atmospheric",
               "pale yellow-green, faint cyan, cream white, open expansive",
               "#BDB76B"),
    background("bg_battle_mountaintop",
               "Perilous mountaintop platform battle scene, distant churning cloud sea with "
               "sunset glow, midground cliff edge with weathered stone pillars, foreground "
               "flat platform open space. Majestic dramatic sunset lighting",
               "sunset orange-red, gold yellow, purple clouds, dramatic majesty",
               "#FF8C00"),
    background("bg_boss_xuesha",
               "Blood Shadow Patriarch's cave lair boss arena, distant flowing blood-red "
               "magma river, midground stone walls hung with bone remains and blood-colored "
               "magic circle floor tiles, foreground rolling blood mist. Overwhelming sinister "
               "boss arena atmosphere",
               "blood red, ink black, dark purple, lava amber, boss dread",
               "#8B0000"),
    background("bg_boss_tianjie",
               "Final boss arena heavenly tribulation platform, distant nine layers of "
               "gold-purple thunder cloud vortex filling the sky, midground a massive taiji "
               "bagua celestial altar platform, foreground gold-purple lightning strikes on "
               "ground. Cosmic overwhelming divine judgment atmosphere",
               "gold-purple, thunder blue-white, ink black sky, cosmic judgment",
               "#9400D3"),
]


# =============================================================================
# 生成 workflows
# =============================================================================

def main():
    os.makedirs("workflows", exist_ok=True)

    # W18: 主角 + 队友立绘
    wf18 = build_workflow(
        icons=PORTRAITS_ALLIES,
        master_dir="portraits_allies_1024",
        final_dir="portraits_allies_512",
        final_size=512,
        title="W18 — 主角 + 队友立绘 (第四批)",
        note_body=(
            "第四批 AI 资源 — 主角 + 队友立绘\n\n"
            "总数: 12 张\n"
            "输出: 1024×1024 master + 512×512 最终\n"
            "目标目录: assets/ui/_masters/portraits_allies_1024/\n"
            "         assets/portraits/protagonist/ + assets/portraits/allies/\n\n"
            "FLUX dev + BRIA 抠图, 共享种子 88888888\n"
            "提示词来源: assets/specs/ui/06-portraits-protagonist-allies.md"
        ),
    )
    save(wf18, "workflows/18_portraits_allies_batch_flux.json")
    print(f"✓ W18: 12 主角+队友立绘 → workflows/18_portraits_allies_batch_flux.json")

    # W19: 敌人立绘
    wf19 = build_workflow(
        icons=PORTRAITS_ENEMIES,
        master_dir="portraits_enemies_1024",
        final_dir="portraits_enemies_512",
        final_size=512,
        title="W19 — 敌人立绘 (第四批)",
        note_body=(
            "第四批 AI 资源 — 敌人立绘\n\n"
            "总数: 16 张\n"
            "输出: 1024×1024 master + 512×512 最终\n"
            "目标目录: assets/ui/_masters/portraits_enemies_1024/\n"
            "         assets/portraits/enemies/\n\n"
            "FLUX dev + BRIA 抠图, 共享种子 88888888\n"
            "提示词来源: assets/specs/ui/07-portraits-enemies.md"
        ),
    )
    save(wf19, "workflows/19_portraits_enemies_batch_flux.json")
    print(f"✓ W19: 16 敌人立绘 → workflows/19_portraits_enemies_batch_flux.json")

    # W20: 场景背景
    wf20 = build_workflow(
        icons=BACKGROUNDS,
        master_dir="backgrounds_1024",
        final_dir="backgrounds_final",
        final_size=1024,
        title="W20 — 场景背景 (第四批)",
        note_body=(
            "第四批 AI 资源 — 场景/菜单/战斗背景\n\n"
            "总数: 15 张\n"
            "输出: 1024×1024 master (后续手动放大至 1920×1080)\n"
            "目标目录: assets/ui/_masters/backgrounds_1024/\n"
            "         assets/backgrounds/\n\n"
            "FLUX dev + BRIA 抠图 (背景类可忽略 BRIA 产出，直接用 VAEDecode)\n"
            "共享种子 88888888\n"
            "提示词来源: assets/specs/ui/08-backgrounds.md\n\n"
            "注意: 背景不需要透明，最终使用的是 VAEDecode 后的完整图片 (非 BRIA 版)"
        ),
    )
    save(wf20, "workflows/20_backgrounds_batch_flux.json")
    print(f"✓ W20: 15 场景背景 → workflows/20_backgrounds_batch_flux.json")

    print(f"\n共 43 张, 预计挂机 2-3 小时完成")


if __name__ == "__main__":
    main()
