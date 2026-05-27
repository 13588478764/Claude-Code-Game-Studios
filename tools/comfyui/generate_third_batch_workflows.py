#!/usr/bin/env python3
# =============================================================================
# 第三批 ComfyUI 工作流生成器
# 产出 6 个 workflow: 65 物品 (5 类 15+12+15+15+8) + 17 UI 边框 (P0+P1)
#
# 用法:
#   cd tools/comfyui
#   python3 generate_third_batch_workflows.py
#
# 产出 (写入 workflows/):
#   12_items_weapons_batch_flux.json     (15 武器, ~120 节点)
#   13_items_armor_batch_flux.json       (12 防具, ~98 节点)
#   14_items_consumable_batch_flux.json  (15 丹药消耗, ~120 节点)
#   15_items_material_batch_flux.json    (15 材料, ~120 节点)
#   16_items_quest_batch_flux.json       (8 任务道具, ~63 节点)
#   17_ui_frames_batch_flux.json         (17 UI 边框 P0+P1, ~126 节点)
#
# 来源 spec:
#   assets/specs/ui/10-items.md  (65 项)
#   assets/specs/ui/09-frames-decoration.md  (21 项, 仅 P0+P1=18, 去 transition_ink 因尺寸特殊)
# =============================================================================

import os
import sys

# 引入同目录的 build_workflow / save
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from generate_batch_workflow import build_workflow, save


# =============================================================================
# 提示词模板
# =============================================================================

# 物品: 方形构图, 无外框, 主体悬浮于灵气云气之上 (与 10-items.md 通用模板对齐)
PROMPT_TEMPLATE_ITEM = (
    "A minimalist game UI item icon for a cultivation wuxia RPG, centered square composition. "
    "Subject: {subject}. "
    "The subject occupies about 70 percent of the canvas in the center, hovering above a very faint "
    "wisp of spiritual qi mist. Pure clean solid white background, no outer border, no frame, no "
    "decoration around the subject. Flat vector illustration style, painted with traditional Chinese "
    "ink wash brushstrokes but extremely simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, no facial features, no text, no chinese characters, no multiple "
    "duplicate subjects, no debris, no asymmetric stray marks. "
    "Single focal point on the central item. Designed to be readable when scaled down to 64x64 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)

# UI 边框/装饰: 完全不同 — 中心通常透明, 主体即装饰本身, 适合 9-slice
PROMPT_TEMPLATE_FRAME = (
    "A minimalist Chinese cultivation RPG UI ornament, centered composition designed for 9-slice "
    "tiling. Subject: {subject}. The decoration itself is the focal point, the inner area is empty "
    "and meant to hold runtime content. Pure clean solid white background, decoration drawn with "
    "uniform thin ink black outline and a subtle gold inner stroke, traditional Chinese ornamental "
    "motifs (cloud spirals, key fret patterns, bagua glyphs, bamboo nodes) used sparingly. "
    "{palette} color palette only. No realistic human portraits, no facial features, no text, no "
    "chinese characters, no asymmetric stray marks, no broken segments. Symmetric and balanced "
    "composition optimized for 9-slice tiling. Highest quality UI ornament."
)


def item(name: str, subject: str, palette: str, color: str) -> dict:
    """组装一个物品 icon dict (使用 PROMPT_TEMPLATE_ITEM)。"""
    return {
        "name": name,
        "color": color,
        "prompt": PROMPT_TEMPLATE_ITEM.format(subject=subject, palette=palette),
    }


def frame(name: str, subject: str, palette: str, color: str) -> dict:
    """组装一个 UI 边框 icon dict (使用 PROMPT_TEMPLATE_FRAME)。"""
    return {
        "name": name,
        "color": color,
        "prompt": PROMPT_TEMPLATE_FRAME.format(subject=subject, palette=palette),
    }


# =============================================================================
# W12 — 武器 15 项
# =============================================================================

WEAPONS = [
    item("item_sword_iron",
         "a single plain iron longsword laid diagonally across the frame, the blade in dull gray "
         "iron tone with a faint forged texture, the hilt wrapped with simple red cloth wrap, no "
         "decoration anywhere",
         "muted gray iron and dim crimson hilt wrap",
         "#808080"),
    item("item_sword_qingfeng",
         "a single slender green-tinted longsword laid diagonally, the blade glowing with a faint "
         "pale cyan luster, the hilt wrapped with blue cloth and adorned with a small jade bead pommel",
         "pale cyan green and soft blue with jade highlight",
         "#60a090"),
    item("item_sword_xuantie",
         "a single heavy thick black-iron longsword laid diagonally, the blade broad and serrated "
         "with a menacing edge, the hilt wrapped with black cloth and bound with iron rings",
         "deep black iron and matte gunmetal gray",
         "#404040"),
    item("item_sword_zidian",
         "a single ornate purple-gold longsword laid diagonally, the blade etched with flowing "
         "violet lightning runes, the hilt a gold-purple gradient wrapped around a single glowing "
         "purple gemstone pommel",
         "vivid violet and royal gold with electric purple glow",
         "#9040c0"),
    item("item_sword_taiji",
         "a single pure white jade longsword laid diagonally, the blade carved with flowing yin-yang "
         "taiji patterns, the hilt of white jade sculpted into a nine-petal lotus, the entire sword "
         "radiating a soft holy white glow",
         "pristine white jade and pale gold with celestial radiance",
         "#e0e0d0"),
    item("item_saber_wanyue",
         "a single crescent-moon-shaped curved saber laid diagonally, the blade silvery sharp and "
         "polished, the hilt wrapped with black cloth and fitted with a bronze guard",
         "silver white and dark bronze with black wrap",
         "#a0a0a0"),
    item("item_saber_xuesha",
         "a single pitch-black curved demon saber laid diagonally, the blade seeping with crimson "
         "blood-like patterns, the hilt in black and red with a skull motif at the pommel, oozing "
         "sinister aura",
         "deep black and dark crimson with bone white skull accent",
         "#601020"),
    item("item_spear_yinlong",
         "a single tall silver spear standing diagonally, the spearhead a silvery dragon head "
         "sculpture, the shaft wrapped with alternating white and red cloth bindings",
         "polished silver white and accent crimson red",
         "#c0c0c0"),
    item("item_staff_xuantie",
         "a single thick heavy black iron staff laid diagonally, the shaft solid pitch black with "
         "iron rings capping both ends",
         "deep black iron with dull gray ring highlights",
         "#303030"),
    item("item_flying_sword",
         "a single miniature sword floating in mid-air horizontally, surrounded by swirling pale "
         "cyan spiritual qi and faint taoist talisman glyphs, exuding immortal aura",
         "pale cyan spiritual blue and luminous white with gold rune highlights",
         "#80c0d0"),
    item("item_artifact_fuchen",
         "a single white jade taoist whisk standing vertically, the handle carved jade with taoist "
         "patterns, the long flowing tassels of silvery silk threads cascading down",
         "pure white jade and silver silk with subtle pale highlights",
         "#d0d0c8"),
    item("item_artifact_bagua_mirror",
         "a single circular ancient bronze mirror floating, the front face engraved with the eight "
         "trigrams bagua pattern, the back glowing with golden taoist runes, emitting a soft warm "
         "halo",
         "antique bronze and warm gold with mellow halo glow",
         "#b08840"),
    item("item_talisman",
         "a single yellow paper talisman laid face-up, the paper inscribed with bold vermilion "
         "cinnabar taoist runes and seal marks, the paper edges slightly curled",
         "warm yellow paper and vivid vermilion cinnabar red",
         "#d0a040"),
    item("item_artifact_guqin",
         "a single seven-stringed guqin zither laid horizontally, the body of dark brown lacquered "
         "wood with visible wood grain, seven silk strings stretched clearly across, a crescent "
         "moon carved into the body",
         "deep brown lacquered wood and pale silk string highlights",
         "#604030"),
    item("item_artifact_yudi",
         "a single white jade flute standing vertically, the jade body translucent and creamy, "
         "carved with delicate bamboo leaf patterns, a red silk tassel hanging from the bottom",
         "creamy white jade and gentle red silk tassel",
         "#e0d8c0"),
]


# =============================================================================
# W13 — 防具 12 项
# =============================================================================

ARMOR = [
    item("item_robe_cloth",
         "a single gray-brown coarse cloth robe laid flat open, the fabric plain and undecorated, "
         "simple humble cut",
         "muted gray brown and warm beige",
         "#806858"),
    item("item_robe_qingyun",
         "a single green taoist robe laid flat open, the cuffs and hem embroidered with golden "
         "scrolling cloud patterns, a sash belt with a jade pendant ornament",
         "soft cyan green and warm gold with jade green highlight",
         "#508060"),
    item("item_armor_xuanwu",
         "a single heavy black-tortoise themed plate armor laid flat open, the chest plate engraved "
         "with turtle shell patterns, shoulder guards wrapped with serpent motifs, ink black with "
         "silver edging",
         "deep ink black and cool silver edging",
         "#404858"),
    item("item_robe_zifu",
         "a single purple immortal robe laid flat open, the entire garment embroidered with golden "
         "eight-trigram cloud patterns, sleeves and hem flowing elegantly",
         "rich royal purple and luminous gold embroidery",
         "#805090"),
    item("item_hat_taoist",
         "a single antique bronze taoist scholar hat standing upright, the cap engraved with a "
         "simplified taiji pattern, with black silk ribbons hanging down",
         "antique bronze and dark silk black",
         "#a08050"),
    item("item_helm_zijin",
         "a single ornate purple-gold ceremonial crown standing upright, the crown peak carved "
         "with golden dragon motifs, paired with flowing purple silk tassels",
         "deep purple and royal gold with violet silk tassels",
         "#a06080"),
    item("item_boots_cloth",
         "a single pair of plain coarse cloth shoes placed side by side, gray brown in color, with "
         "thick sturdy soles",
         "muted gray brown and dark earth tone",
         "#706050"),
    item("item_boots_lingbo",
         "a single pair of cyan immortal boots placed side by side, the cuffs embroidered with "
         "cloud patterns, the uppers soft and graceful",
         "soft cyan blue and pale silver embroidery",
         "#6090a0"),
    item("item_gauntlet",
         "a single pair of antique bronze wrist gauntlets placed side by side, engraved with "
         "golden taoist rune patterns",
         "antique bronze and warm gold rune highlights",
         "#a07840"),
    item("item_jade_pendant",
         "a single cyan-green jade pendant hanging vertically, the jade carved with a taiji "
         "yin-yang pattern, with a red silk tassel hanging from the bottom",
         "translucent jade green and warm red silk",
         "#60a070"),
    item("item_spirit_ring",
         "a single antique bronze ring floating, the band carved with taoist rune patterns, set "
         "with a single glowing purple spirit gemstone in the center",
         "antique bronze and luminous violet gem",
         "#9060a0"),
    item("item_necklace_xianhe",
         "a single golden chain necklace hanging vertically, the pendant a stylized golden crane "
         "in flight with outstretched wings",
         "luminous gold and pale yellow highlight",
         "#d0a050"),
]


# =============================================================================
# W14 — 丹药消耗 15 项
# =============================================================================

CONSUMABLES = [
    item("item_pill_ningqi",
         "a single pale cyan-tinted pill floating above a wisp of pale cyan qi mist, the pill "
         "surface smooth with a faint inner luster",
         "pale cyan and soft silver mist",
         "#80b8c0"),
    item("item_pill_zhuji",
         "a single pale yellow pill floating above a wisp of golden qi mist, the pill surface "
         "etched with a faint golden spiral pattern",
         "warm pale yellow and bright gold",
         "#d0b060"),
    item("item_pill_jindan",
         "a single rich golden pill floating above a swirling gold-and-red fire cloud, the pill "
         "surface carved with a yin-yang taiji pattern",
         "rich gold and warm crimson fire",
         "#e0a040"),
    item("item_pill_dahuan",
         "a single deep crimson pill floating above red flames, with nine golden spirit runes "
         "spiraling around the pill",
         "vivid crimson red and brilliant gold rune",
         "#c04030"),
    item("item_pill_dujie",
         "a single regal purple-gold pill floating above a roiling purple thunder cloud, the pill "
         "wreathed with dragon-and-phoenix patterns, radiating dazzling divine light",
         "deep violet and royal gold with electric purple aura",
         "#a050b0"),
    item("item_herb_lingzhi",
         "a single ancient lingzhi mushroom with a deep red cap that has a faint golden luster, "
         "the stem clearly veined in white",
         "deep red and warm gold with pale stem white",
         "#a04040"),
    item("item_herb_renshen",
         "a single millennial ginseng root in human form, with delicate hair-like rootlets, the "
         "main body a pale yellow with a faint glow",
         "soft pale yellow and warm beige",
         "#d0c080"),
    item("item_herb_xuelian",
         "a single fully bloomed snow lotus flower with layered crystalline white petals and a "
         "glowing golden center",
         "pristine snow white and luminous gold center",
         "#e8e8f0"),
    item("item_herb_wuxing",
         "a single small five-leaf herb plant where each of the five leaves is a different color "
         "representing the five elements (gold, green wood, blue water, red fire, brown earth), "
         "symbolizing five-element balance",
         "balanced five-element palette gold green blue red brown",
         "#80a080"),
    item("item_food_baozi",
         "a single steaming hot bun, the surface emitting faint wisps of spiritual qi mist",
         "warm cream white and soft beige with gentle mist",
         "#e0d0a0"),
    item("item_food_wine",
         "a single antique gourd-shaped wine flask hanging, the gourd painted green and tied with "
         "a red cord, emitting faint wine vapor",
         "deep green gourd and warm crimson cord",
         "#609060"),
    item("item_food_xiantao",
         "a single ripe crimson immortal peach floating, the surface marked with golden flowing "
         "patterns, the leaves a vivid jade green",
         "vivid crimson red and rich jade green leaf",
         "#d04050"),
    item("item_potion_hp",
         "a single small jade bottle containing red liquid, the cork stopper visible at the top, "
         "the bottle body wrapped with a red cord",
         "vivid crimson liquid and pale jade glass with red cord",
         "#c04040"),
    item("item_potion_qi",
         "a single small jade bottle containing cyan liquid, the cork stopper visible at the top, "
         "the bottle body wrapped with a cyan cord",
         "luminous cyan liquid and pale jade glass with cyan cord",
         "#40a0c0"),
    item("item_pill_jiedu",
         "a single white pill floating, the pill surface marked with a small green antidote rune "
         "seal",
         "pristine white pill and vivid jade green rune",
         "#a0c080"),
]


# =============================================================================
# W15 — 材料 15 项
# =============================================================================

MATERIALS = [
    item("item_spirit_stone_low",
         "a single pale cyan multi-faceted spirit stone crystal, the surface with a faint inner "
         "luster",
         "pale cyan and soft silver glint",
         "#90b0c0"),
    item("item_spirit_stone_mid",
         "a single deep cyan-blue multi-faceted spirit stone crystal, with visible flowing inner "
         "spirit energy",
         "rich cyan blue and luminous inner glow",
         "#5080b0"),
    item("item_spirit_stone_high",
         "a single regal violet multi-faceted spirit stone crystal, emitting a strong purple-gold "
         "halo",
         "deep violet and royal gold halo",
         "#8050a0"),
    item("item_ore_xuantie",
         "a single chunk of pitch-black ore, the surface marked with silvery metallic veins and "
         "cracks",
         "deep ink black and cool silver vein",
         "#404048"),
    item("item_ore_ningyue",
         "a single chunk of silvery-white ore, the surface emitting a cold moonlight-white halo",
         "polished silver white and cool pale moonlight",
         "#b0b0c0"),
    item("item_beast_core",
         "a single deep crimson demonic beast inner core orb, the interior swirling with purple-"
         "black demonic miasma",
         "deep crimson and shadowy violet-black demonic mist",
         "#702040"),
    item("item_pelt_fire_wolf",
         "a single piece of crimson fire-wolf fur laid flat, the fur strands shimmering as if "
         "flames are dancing through them",
         "vivid flame crimson and warm gold flicker",
         "#c04030"),
    item("item_dragon_scale",
         "a single thick golden dragon scale, heavy with luster, with intricate scale-edge "
         "patterns",
         "luminous gold and warm bronze edge",
         "#d0a040"),
    item("item_phoenix_feather",
         "a single crimson phoenix feather, the feather tip wreathed in a golden flame halo",
         "vivid crimson and brilliant gold flame",
         "#d04030"),
    item("item_scroll",
         "a single ancient bamboo-strip scroll standing upright, tied with a red silk cord",
         "warm bamboo yellow and rich crimson cord",
         "#b09040"),
    item("item_ancient_book",
         "a single yellowed ancient tome laid flat, the dark brown leather cover stamped with "
         "golden taoist runes",
         "rich dark brown and luminous gold rune",
         "#604030"),
    item("item_key",
         "a single antique bronze key laid horizontally, the key head carved with ornamental "
         "patterns",
         "antique bronze and warm gold accent",
         "#a07840"),
    item("item_letter",
         "a single folded letter, bound with a red silk ribbon and sealed with a wax stamp",
         "warm parchment beige and vivid red ribbon",
         "#d0b890"),
    item("item_storage_bag",
         "a single cyan qiankun storage pouch, the mouth tied with a red cord, surrounded by a "
         "faint aura of spiritual qi mist",
         "soft cyan green and warm crimson cord with pale spirit halo",
         "#508070"),
    item("item_gold_pouch",
         "a single brown coin pouch with a few golden bronze coins spilling out of the open top",
         "warm brown leather and bright gold coins",
         "#806040"),
]


# =============================================================================
# W16 — 任务道具 8 项
# =============================================================================

QUEST_ITEMS = [
    item("item_quest_xuantian_token",
         "a single dark purple-black token, the front face carved with mystical xuan symbol "
         "ornamental motifs (NOT actual characters), the back with golden eight-trigram patterns",
         "deep violet-black and luminous gold motif",
         "#503060"),
    item("item_quest_xianyuan_jade",
         "a single crystalline jade slip floating, the surface flowing with glowing taoist rune "
         "patterns",
         "translucent jade green and luminous gold rune",
         "#80c0a0"),
    item("item_quest_master_token",
         "a single circular jade pendant, the front face engraved with a stylized ink-wash sect "
         "emblem, a cyan silk cord tied at the bottom",
         "translucent jade green and dark cyan silk cord",
         "#70b090"),
    item("item_quest_ancient_map",
         "a single unrolled aged yellow map, depicting mountains and rivers with red path markings",
         "warm aged parchment and vivid crimson route mark",
         "#c0a060"),
    item("item_quest_bloodline_jade",
         "a single deep blood-red crystalline jade, the interior with flowing dragon and phoenix "
         "bloodline vein patterns",
         "vivid blood red and warm crimson vein",
         "#a02040"),
    item("item_quest_antidote",
         "a single small porcelain bottle containing jade-green antidote liquid, with a small cork "
         "stopper at the top",
         "luminous jade green liquid and pristine porcelain white",
         "#60a060"),
    item("item_quest_enemy_portrait",
         "a single unrolled portrait scroll, depicting a vague obscured human face silhouette",
         "warm aged parchment and muted ink gray figure",
         "#a09070"),
    item("item_quest_mystery_token",
         "a single pitch-black token emitting a faint purple glow, the surface marked with unknown "
         "ancient rune patterns",
         "deep ink black and luminous violet glow",
         "#403060"),
]


# =============================================================================
# W17 — UI 边框/装饰 17 项 (P0+P1, 去 transition_ink 因尺寸 1920 特殊)
# =============================================================================

UI_FRAMES = [
    frame("frame_dialogue",
          "a rectangular dialog box border with simplified scrolling cloud patterns and key fret "
          "ornaments at the four corners and along the four edges, ink black outline with a faint "
          "gold inner stroke, the inner center area a translucent cream off-white ready for "
          "9-slice tiling",
          "ink black outline gold inner stroke and translucent cream off-white center",
          "#80604c"),
    frame("frame_character_panel",
          "a large rectangular vertical character panel border with golden bagua trigram ornaments "
          "at the four corners, bamboo node and taoist rune patterns along the four edges, ink "
          "black outer outline with a fine gold inner stroke, the inner center a translucent dark "
          "tone ready to display attribute data",
          "ink black outline luminous gold detail and translucent dark interior",
          "#604030"),
    frame("frame_item_tooltip",
          "a small compact rectangular tooltip border with simplified scroll-grass ornaments at "
          "the four corners, fine ink black outline, the inner center a translucent dark cream "
          "off-white",
          "ink black fine outline and translucent dark cream interior",
          "#806050"),
    frame("frame_quest_scroll",
          "a bamboo-strip scroll-shaped border with golden scroll rod ends at the left and right, "
          "the middle section a yellowed bamboo-strip texture, designed for vertical tiling "
          "expansion",
          "warm aged bamboo yellow and luminous gold rod ends",
          "#c0a050"),
    frame("frame_rarity_common",
          "a rounded square rarity item border, gray ink outline with no halo, completely "
          "symmetrical, used as the common rarity tier frame",
          "neutral gray outline and pure clean white interior",
          "#a0a0a0"),
    frame("frame_rarity_fine",
          "a rounded square rarity item border, pale blue outline with a soft pale blue halo "
          "around the edge, used as the fine rarity tier frame",
          "soft pale blue outline and gentle blue halo",
          "#6090c0"),
    frame("frame_rarity_epic",
          "a rounded square rarity item border, deep purple outline with a violet glowing halo "
          "around the edge, used as the epic rarity tier frame",
          "deep violet outline and luminous purple halo",
          "#8060c0"),
    frame("frame_rarity_legendary",
          "a rounded square rarity item border, rich gold outline with a warm gold glowing halo "
          "around the edge, used as the legendary rarity tier frame",
          "luminous gold outline and warm radiant halo",
          "#d0a040"),
    frame("frame_rarity_immortal",
          "a rounded square rarity item border, gold-red outline with a dual red-and-gold "
          "pulsating halo, with subtle bagua dots at the four corners, exuding a radiant divine "
          "feel, used as the immortal rarity tier frame",
          "fiery gold red outline and dual red-gold halo",
          "#d05040"),
    frame("button_standard",
          "a rounded rectangular button, ink black outer outline with a fine gold inner stroke, "
          "the center a deep cream off-white ready for overlay text, simple and ancient feel",
          "ink black outline gold accent and cream off-white center",
          "#806848"),
    frame("button_main_menu",
          "a large elongated rectangular menu button with rounded corners, the left and right "
          "ends decorated with simplified scrolling cloud ornaments, ink black outer outline with "
          "a fine gold inner stroke, the center a cream-to-dark gradient ready for centered 16-24 "
          "pixel title text",
          "ink black outline gold accent and cream center gradient",
          "#806040"),
    frame("button_close",
          "a small circular close button with a stylized brush-stroke X mark at the center, an "
          "outer fine gold rim, exquisite and compact",
          "ink black stroke and luminous gold rim",
          "#603030"),
    frame("scrollbar_handle",
          "a vertical elongated oval scrollbar handle, gold outline filled with a cream off-white "
          "center, simple and unobtrusive, ready for vertical tiling",
          "luminous gold outline and gentle cream interior",
          "#a08050"),
    frame("progress_bar_bg",
          "a horizontal rectangular progress bar background slot, ink black outer outline, the "
          "inner area a translucent deep cream off-white, ready for 9-slice horizontal tiling",
          "ink black outline and translucent deep cream interior",
          "#604030"),
    frame("progress_bar_fill",
          "a horizontal rectangular progress bar fill layer, a flat tintable surface (neutral "
          "light gray base) with a subtle flowing spiritual qi sheen across, ready for 9-slice "
          "horizontal tiling and runtime color tinting",
          "neutral light gray base and very faint pale highlight",
          "#a0a0a0"),
    frame("divider_horizontal",
          "a horizontal divider ornament, with simplified scrolling cloud ends on both left and "
          "right sides, a single fine ink black horizontal line passing through a small golden "
          "bead in the center",
          "ink black line and luminous gold bead with subtle cloud ends",
          "#806050"),
    frame("title_banner",
          "a horizontal title banner ornament, with simplified scrolling cloud tail ornaments at "
          "the left and right ends, the middle a long horizontal rectangle in deep red and black "
          "with a gold edging, ready to overlay a white title text in the center",
          "deep crimson red ink black and luminous gold edging",
          "#a04040"),
]


# =============================================================================
# 入口
# =============================================================================

def main():
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "workflows")
    os.makedirs(out_dir, exist_ok=True)

    batches = [
        # (icons, master_dir, final_dir, final_size, title, note, file_name)
        (WEAPONS, "wuxia_item_1024", "wuxia_item_128", 128,
         "12 武器 (15 项 / ~120 节点)",
         "65 项物品第三批 W1/6 — 武器:剑/刀/枪/棍/法器/灵符/琴笛\n"
         "对齐 assets/specs/ui/10-items.md 一、武器类 (Weapons) 15 项\n"
         "共享种子 88888888 / FLUX dev / 25 步 / 欧拉 simple\n"
         "BRIA 抠图 → 1024 母版 → ImageScale lanczos → 128 游戏图标",
         "12_items_weapons_batch_flux.json"),

        (ARMOR, "wuxia_item_1024", "wuxia_item_128", 128,
         "13 防具 (12 项 / ~98 节点)",
         "65 项物品第三批 W2/6 — 防具:长袍/铠甲/头部/鞋/护腕/配饰\n"
         "对齐 assets/specs/ui/10-items.md 二、防具类 (Armor) 12 项",
         "13_items_armor_batch_flux.json"),

        (CONSUMABLES, "wuxia_item_1024", "wuxia_item_128", 128,
         "14 丹药消耗 (15 项 / ~120 节点)",
         "65 项物品第三批 W3/6 — 丹药/灵药/食物/药水\n"
         "对齐 assets/specs/ui/10-items.md 三、丹药/消耗品 (Pills/Consumables) 15 项",
         "14_items_consumable_batch_flux.json"),

        (MATERIALS, "wuxia_item_1024", "wuxia_item_128", 128,
         "15 材料 (15 项 / ~120 节点)",
         "65 项物品第三批 W4/6 — 矿石/灵石/妖兽材料/工具杂物\n"
         "对齐 assets/specs/ui/10-items.md 四、材料/杂物 (Materials) 15 项",
         "15_items_material_batch_flux.json"),

        (QUEST_ITEMS, "wuxia_item_1024", "wuxia_item_128", 128,
         "16 任务道具 (8 项 / ~63 节点)",
         "65 项物品第三批 W5/6 — 剧情专属物品\n"
         "对齐 assets/specs/ui/10-items.md 五、任务道具 (Quest Items) 8 项\n"
         "注: 任务道具命名带 quest_ 前缀",
         "16_items_quest_batch_flux.json"),

        (UI_FRAMES, "wuxia_frame_1024", "wuxia_frame_256", 256,
         "17 UI 边框装饰 (17 项 P0+P1 / ~126 节点)",
         "UI 边框装饰第三批 W6/6 — 面板边框/稀有度边框/按钮/装饰\n"
         "对齐 assets/specs/ui/09-frames-decoration.md P0+P1 (去 transition_ink 因尺寸 1920 特殊)\n"
         "注: 边框采用 256 最终尺寸 (与 9-slice 切片需求一致),\n"
         "    P2 三项 (corner_ornament/chapter_scroll/exp_fx) 推后到 Beta 单独跑",
         "17_ui_frames_batch_flux.json"),
    ]

    for icons, master_dir, final_dir, final_size, title, note, fname in batches:
        wf = build_workflow(
            icons=icons,
            master_dir=master_dir,
            final_dir=final_dir,
            final_size=final_size,
            title=title,
            note_body=note,
        )
        save(wf, os.path.join(out_dir, fname))
        print(f"  {fname}: {len(icons)} 项 → ~{7 + 7 * len(icons)} 节点", file=sys.stderr)

    print(f"\n✓ 6 个工作流已生成 (共 {sum(len(b[0]) for b in batches)} 张图)", file=sys.stderr)


if __name__ == "__main__":
    main()
