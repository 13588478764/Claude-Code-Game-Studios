#!/usr/bin/env python3
# =============================================================================
# 批量 ComfyUI 工作流生成器
#
# 输入: icon 配置（名称 + FLUX 提示词 + 分组色）
# 输出: 标准化 ComfyUI workflow JSON
#
# 结构 = 7 共享节点（UNET/DualCLIP/VAE/EmptyLatent/负面 CLIP/BRIA/Note）
#       + 每张图 7 节点链（CLIPText→KSampler→VAEDecode→BRIA→Save1024→Scale→SaveFinal）
#
# 用法（作为模块）:
#   from generate_batch_workflow import build_workflow, save
#   wf = build_workflow(icons=[...], master_dir="wuxia_combat_1024",
#                       final_dir="wuxia_combat_128", final_size=128, ...)
#   save(wf, "workflows/06_combat_states_batch_flux.json")
# =============================================================================

import json
import os
import sys


SHARED_SEED = 88888888
LATENT_SIZE = 1024


def build_workflow(
    icons,
    master_dir: str,
    final_dir: str,
    final_size: int,
    title: str,
    note_body: str,
):
    """构建完整 ComfyUI workflow dict。

    icons: List[Dict{name, prompt, color}]，每张图一项
        name  = 不含扩展名的文件名（如 "status_icon_down"）
        prompt = 完整 FLUX 提示词字符串
        color = 分组色 hex（如 "#4080a0"）
    master_dir/final_dir = ComfyUI output 子目录名
    final_size = 缩放后的边长（128 / 64）
    """
    n = len(icons)

    # ===== 链接 ID 池 =====
    # 共享: 1-10 model, 11-(11+n) clip, ..., 计算如下
    # model: 1 .. n
    # clip:  n+1 .. n+1+n  (n 个正面 + 1 个负面 = n+1 条)
    # vae:   后续 n 条
    # latent: 后续 n 条
    # neg cond: 后续 n 条
    # bria model: 后续 n 条
    # per-chain internal: 后续 6n 条

    id_model = list(range(1, n + 1))
    id_clip = list(range(n + 1, n + 1 + n + 1))  # n positives + 1 negative
    id_vae = list(range(id_clip[-1] + 1, id_clip[-1] + 1 + n))
    id_latent = list(range(id_vae[-1] + 1, id_vae[-1] + 1 + n))
    id_neg = list(range(id_latent[-1] + 1, id_latent[-1] + 1 + n))
    id_bria = list(range(id_neg[-1] + 1, id_neg[-1] + 1 + n))

    # ===== 共享节点 =====
    nodes = []

    nodes.append({
        "id": 1,
        "type": "UNETLoader",
        "pos": [50, 50],
        "size": [350, 90],
        "flags": {},
        "order": 0,
        "mode": 0,
        "inputs": [],
        "outputs": [
            {"name": "MODEL", "type": "MODEL", "links": id_model, "slot_index": 0}
        ],
        "properties": {"Node name for S&R": "UNETLoader"},
        "widgets_values": ["flux1-dev.safetensors", "default"],
    })

    nodes.append({
        "id": 2,
        "type": "DualCLIPLoader",
        "pos": [50, 170],
        "size": [350, 130],
        "flags": {},
        "order": 1,
        "mode": 0,
        "inputs": [],
        "outputs": [
            {"name": "CLIP", "type": "CLIP", "links": id_clip, "slot_index": 0}
        ],
        "properties": {"Node name for S&R": "DualCLIPLoader"},
        "widgets_values": [
            "t5xxl_fp16.safetensors",
            "clip_l.safetensors",
            "flux",
            "default",
        ],
    })

    nodes.append({
        "id": 3,
        "type": "VAELoader",
        "pos": [50, 330],
        "size": [350, 60],
        "flags": {},
        "order": 2,
        "mode": 0,
        "inputs": [],
        "outputs": [
            {"name": "VAE", "type": "VAE", "links": id_vae, "slot_index": 0}
        ],
        "properties": {"Node name for S&R": "VAELoader"},
        "widgets_values": ["ae.safetensors"],
    })

    nodes.append({
        "id": 4,
        "type": "EmptyLatentImage",
        "pos": [50, 420],
        "size": [350, 110],
        "flags": {},
        "order": 3,
        "mode": 0,
        "inputs": [],
        "outputs": [
            {"name": "LATENT", "type": "LATENT", "links": id_latent, "slot_index": 0}
        ],
        "title": f"{LATENT_SIZE}x{LATENT_SIZE} (共享 Latent)",
        "properties": {"Node name for S&R": "EmptyLatentImage"},
        "widgets_values": [LATENT_SIZE, LATENT_SIZE, 1],
    })

    # 负面提示 CLIP (FLUX 空字符串)
    nodes.append({
        "id": 5,
        "type": "CLIPTextEncode",
        "pos": [50, 560],
        "size": [350, 100],
        "flags": {},
        "order": 4,
        "mode": 0,
        "inputs": [
            {"name": "clip", "type": "CLIP", "link": id_clip[-1]}
        ],
        "outputs": [
            {"name": "CONDITIONING", "type": "CONDITIONING", "links": id_neg, "slot_index": 0}
        ],
        "title": "共享负面提示词 (FLUX 留空)",
        "properties": {"Node name for S&R": "CLIPTextEncode"},
        "widgets_values": [""],
        "color": "#322",
        "bgcolor": "#533",
    })

    nodes.append({
        "id": 6,
        "type": "BRIA_RMBG_ModelLoader_Zho",
        "pos": [50, 700],
        "size": [350, 60],
        "flags": {},
        "order": 5,
        "mode": 0,
        "inputs": [],
        "outputs": [
            {"name": "MODEL", "type": "BRMODEL", "links": id_bria, "slot_index": 0}
        ],
        "title": "BRIA 抠图模型 (共享)",
        "properties": {"Node name for S&R": "BRIA_RMBG_ModelLoader_Zho"},
        "widgets_values": [],
    })

    nodes.append({
        "id": 7,
        "type": "Note",
        "pos": [50, 800],
        "size": [350, 1000],
        "flags": {},
        "order": 6,
        "mode": 0,
        "title": title,
        "properties": {},
        "widgets_values": [note_body],
        "color": "#432",
        "bgcolor": "#653",
    })

    # ===== 每张图链 =====
    next_link_id = id_bria[-1] + 1
    groups = [
        {
            "title": "共享模型 + Latent + 负面 + BRIA",
            "bounding": [40, 30, 380, 760],
            "color": "#3f789e",
            "font_size": 24,
            "flags": {},
        },
        {
            "title": "说明 Note",
            "bounding": [40, 790, 380, 1020],
            "color": "#a04060",
            "font_size": 24,
            "flags": {},
        },
    ]
    links = []

    # 共享链接收集
    for i in range(n):
        nid_ksampler = (i + 1) * 10 + 1
        links.append([id_model[i], 1, 0, nid_ksampler, 0, "MODEL"])
    for i in range(n):
        nid_text = (i + 1) * 10
        links.append([id_clip[i], 2, 0, nid_text, 0, "CLIP"])
    # 最后一条 clip → 负面节点 5
    links.append([id_clip[-1], 2, 0, 5, 0, "CLIP"])
    for i in range(n):
        nid_vae = (i + 1) * 10 + 2
        links.append([id_vae[i], 3, 0, nid_vae, 1, "VAE"])
    for i in range(n):
        nid_ksampler = (i + 1) * 10 + 1
        links.append([id_latent[i], 4, 0, nid_ksampler, 3, "LATENT"])
    for i in range(n):
        nid_ksampler = (i + 1) * 10 + 1
        links.append([id_neg[i], 5, 0, nid_ksampler, 2, "CONDITIONING"])
    for i in range(n):
        nid_bria = (i + 1) * 10 + 3
        links.append([id_bria[i], 6, 0, nid_bria, 0, "BRMODEL"])

    for i, icon in enumerate(icons):
        base = (i + 1) * 10
        row_y = 50 + i * 490
        order_offset = 7 + i * 7

        # 链内 6 条链接 ID
        l_text_to_sampler = next_link_id
        l_sampler_to_decode = next_link_id + 1
        l_decode_to_bria = next_link_id + 2
        l_bria_to_save1024 = next_link_id + 3
        l_bria_to_scale = next_link_id + 4
        l_scale_to_savefinal = next_link_id + 5
        next_link_id += 6

        clip_text_id = base
        ksampler_id = base + 1
        vaedecode_id = base + 2
        bria_id = base + 3
        save1024_id = base + 4
        scale_id = base + 5
        savefinal_id = base + 6

        chain_color = icon.get("color", "#608090")

        # 1. 正面提示词
        nodes.append({
            "id": clip_text_id,
            "type": "CLIPTextEncode",
            "pos": [450, row_y],
            "size": [600, 320],
            "flags": {},
            "order": order_offset,
            "mode": 0,
            "inputs": [{"name": "clip", "type": "CLIP", "link": id_clip[i]}],
            "outputs": [
                {"name": "CONDITIONING", "type": "CONDITIONING",
                 "links": [l_text_to_sampler], "slot_index": 0}
            ],
            "title": f"{i + 1}. {icon['name']} - 正面",
            "properties": {"Node name for S&R": "CLIPTextEncode"},
            "widgets_values": [icon["prompt"]],
            "color": "#223",
            "bgcolor": "#335",
        })

        # 2. KSampler
        nodes.append({
            "id": ksampler_id,
            "type": "KSampler",
            "pos": [1080, row_y],
            "size": [320, 460],
            "flags": {},
            "order": order_offset + 1,
            "mode": 0,
            "inputs": [
                {"name": "model", "type": "MODEL", "link": id_model[i]},
                {"name": "positive", "type": "CONDITIONING", "link": l_text_to_sampler},
                {"name": "negative", "type": "CONDITIONING", "link": id_neg[i]},
                {"name": "latent_image", "type": "LATENT", "link": id_latent[i]},
            ],
            "outputs": [
                {"name": "LATENT", "type": "LATENT",
                 "links": [l_sampler_to_decode], "slot_index": 0}
            ],
            "title": f"{i + 1}. {icon['name']} - KSampler",
            "properties": {"Node name for S&R": "KSampler"},
            "widgets_values": [SHARED_SEED, "fixed", 25, 1.0, "euler", "simple", 1.0],
        })

        # 3. VAEDecode
        nodes.append({
            "id": vaedecode_id,
            "type": "VAEDecode",
            "pos": [1430, row_y],
            "size": [220, 60],
            "flags": {},
            "order": order_offset + 2,
            "mode": 0,
            "inputs": [
                {"name": "samples", "type": "LATENT", "link": l_sampler_to_decode},
                {"name": "vae", "type": "VAE", "link": id_vae[i]},
            ],
            "outputs": [
                {"name": "IMAGE", "type": "IMAGE",
                 "links": [l_decode_to_bria], "slot_index": 0}
            ],
            "properties": {"Node name for S&R": "VAEDecode"},
        })

        # 4. BRIA 抠图
        nodes.append({
            "id": bria_id,
            "type": "BRIA_RMBG_Zho",
            "pos": [1680, row_y],
            "size": [320, 100],
            "flags": {},
            "order": order_offset + 3,
            "mode": 0,
            "inputs": [
                {"name": "rmbgmodel", "type": "BRMODEL", "link": id_bria[i]},
                {"name": "image", "type": "IMAGE", "link": l_decode_to_bria},
            ],
            "outputs": [
                {"name": "IMAGE", "type": "IMAGE",
                 "links": [l_bria_to_save1024, l_bria_to_scale], "slot_index": 0},
                {"name": "MASK", "type": "MASK", "links": [], "slot_index": 1},
            ],
            "title": f"{i + 1}. {icon['name']} - BRIA 抠图",
            "properties": {"Node name for S&R": "BRIA_RMBG_Zho"},
        })

        # 5. SaveImage 1024 母版
        nodes.append({
            "id": save1024_id,
            "type": "SaveImage",
            "pos": [2030, row_y],
            "size": [380, 240],
            "flags": {},
            "order": order_offset + 4,
            "mode": 0,
            "inputs": [{"name": "images", "type": "IMAGE", "link": l_bria_to_save1024}],
            "outputs": [],
            "title": f"{i + 1}. {icon['name']} - 1024 母版",
            "properties": {},
            "widgets_values": [f"{master_dir}/{icon['name']}"],
        })

        # 6. ImageScale
        nodes.append({
            "id": scale_id,
            "type": "ImageScale",
            "pos": [2440, row_y],
            "size": [320, 130],
            "flags": {},
            "order": order_offset + 5,
            "mode": 0,
            "inputs": [{"name": "image", "type": "IMAGE", "link": l_bria_to_scale}],
            "outputs": [
                {"name": "IMAGE", "type": "IMAGE",
                 "links": [l_scale_to_savefinal], "slot_index": 0}
            ],
            "title": f"{i + 1}. {icon['name']} - 缩放 {final_size}",
            "properties": {"Node name for S&R": "ImageScale"},
            "widgets_values": ["lanczos", final_size, final_size, "disabled"],
        })

        # 7. SaveImage final
        nodes.append({
            "id": savefinal_id,
            "type": "SaveImage",
            "pos": [2790, row_y],
            "size": [380, 240],
            "flags": {},
            "order": order_offset + 6,
            "mode": 0,
            "inputs": [{"name": "images", "type": "IMAGE", "link": l_scale_to_savefinal}],
            "outputs": [],
            "title": f"{i + 1}. {icon['name']} - {final_size} 游戏图标",
            "properties": {},
            "widgets_values": [f"{final_dir}/{icon['name']}"],
        })

        # 链内 6 条链接
        links.extend([
            [l_text_to_sampler, clip_text_id, 0, ksampler_id, 1, "CONDITIONING"],
            [l_sampler_to_decode, ksampler_id, 0, vaedecode_id, 0, "LATENT"],
            [l_decode_to_bria, vaedecode_id, 0, bria_id, 1, "IMAGE"],
            [l_bria_to_save1024, bria_id, 0, save1024_id, 0, "IMAGE"],
            [l_bria_to_scale, bria_id, 0, scale_id, 0, "IMAGE"],
            [l_scale_to_savefinal, scale_id, 0, savefinal_id, 0, "IMAGE"],
        ])

        # 分组
        groups.append({
            "title": f"{i + 1}. {icon['name']} 链",
            "bounding": [440, row_y - 20, 2750, 490],
            "color": chain_color,
            "font_size": 24,
            "flags": {},
        })

    last_node_id = n * 10 + 6
    last_link_id = next_link_id - 1

    return {
        "last_node_id": last_node_id,
        "last_link_id": last_link_id,
        "nodes": nodes,
        "links": links,
        "groups": groups,
        "config": {},
        "extra": {},
        "version": 0.4,
    }


def save(workflow, out_path: str):
    """保存为格式化 JSON。"""
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(workflow, f, ensure_ascii=False, indent=2)
    print(f"✓ 已写入 {out_path}", file=sys.stderr)


# =============================================================================
# 三个具体工作流入口
# =============================================================================

PROMPT_TEMPLATE_COMBAT = (
    "A minimalist game UI icon for a cultivation wuxia RPG, centered composition. "
    "Subject: {subject}. "
    "The subject occupies about 70 percent of the canvas in the center, with generous empty space around. "
    "Behind the subject is a complete unbroken single closed circular gold ring border drawn as a full "
    "360 degree circle, uniform thin line weight all the way around, completely symmetric, no decoration "
    "on the ring itself. Pure clean solid white background, no other elements. Flat vector illustration "
    "style, painted with traditional Chinese ink wash brushstrokes but extremely simplified for icon use. "
    "{palette} color palette only. "
    "No realistic human portraits, only stylized silhouettes if any, no facial features, no complex "
    "patterns, no maze patterns, no ornate frames, no text, no multiple subjects, no snowflakes, no frost "
    "decoration, no leaves on border, no debris on border, no asymmetric elements, no broken ring. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 48x48 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)

PROMPT_TEMPLATE_BUFF = (
    "A minimalist game UI icon for a cultivation wuxia RPG, centered composition. "
    "Subject: {subject}. "
    "The subject occupies about 70 percent of the canvas in the center, with generous empty space around. "
    "Behind the subject is a complete unbroken single closed circular jade pendant border drawn as a full "
    "360 degree circle, uniform thin line weight all the way around in soft cream-jade tone, completely "
    "symmetric, no decoration on the ring itself. Pure clean solid white background, no other elements. "
    "Flat vector illustration style, painted with traditional Chinese ink wash brushstrokes but extremely "
    "simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, only stylized silhouettes if any, no facial features, no complex "
    "patterns, no maze patterns, no ornate frames, no text, no multiple subjects, no snowflakes, no frost "
    "decoration, no leaves on border, no debris on border, no asymmetric elements, no broken ring. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 32x32 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)

PROMPT_TEMPLATE_DEBUFF = (
    "A minimalist game UI icon for a cultivation wuxia RPG, centered composition. "
    "Subject: {subject}. "
    "The subject occupies about 70 percent of the canvas in the center, with generous empty space around. "
    "Behind the subject is a single closed rhomboid diamond-shaped broken jade fragment border standing on "
    "its point, with subtle hairline cracks running across the frame edges, uniform thin line weight, "
    "completely symmetric along its vertical axis, in cool muted dark gray tone. Pure clean solid white "
    "background, no other elements. Flat vector illustration style, painted with traditional Chinese ink "
    "wash brushstrokes but extremely simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, only stylized silhouettes if any, no facial features, no complex "
    "patterns, no maze patterns, no ornate frames, no text, no multiple subjects, no snowflakes, no frost "
    "decoration, no leaves on border, no debris on border, no asymmetric elements outside the frame. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 32x32 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)


def expand(template: str, subject: str, palette: str) -> str:
    return template.format(subject=subject, palette=palette)


# ===== 天赋: 圆角方形外框 =====
PROMPT_TEMPLATE_TALENT = (
    "A minimalist game UI talent icon for a cultivation wuxia RPG, centered composition. "
    "Subject: {subject}. "
    "The subject occupies about 70 percent of the canvas in the center, with generous empty space around. "
    "Behind the subject is a complete unbroken single closed rounded square border drawn as a uniform "
    "thin gold line, the square has gently rounded corners, perfectly symmetric on both axes, no "
    "decoration on the border itself. Pure clean solid white background, no other elements. "
    "Flat vector illustration style, painted with traditional Chinese ink wash brushstrokes but extremely "
    "simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, only stylized silhouettes if any, no facial features, no complex "
    "patterns, no maze patterns, no ornate frames, no text, no chinese characters, no multiple subjects, "
    "no snowflakes on border, no debris on border, no asymmetric elements, no broken frame. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 64x64 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)

# ===== 武学: 方形构图无外框 =====
PROMPT_TEMPLATE_MARTIAL = (
    "A minimalist game UI martial arts skill icon for a cultivation wuxia RPG, centered square composition. "
    "Subject: {subject}. "
    "The subject occupies about 80 percent of the canvas in the center with bold confident presence, "
    "with minimal empty space, filling the square frame naturally without any outer border or ring. "
    "Pure clean solid white background, no other elements. "
    "Flat vector illustration style, painted with traditional Chinese ink wash brushstrokes but extremely "
    "simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, only stylized silhouettes if any, no facial features, no complex "
    "patterns, no maze patterns, no ornate frames, no text, no chinese characters, no multiple "
    "duplicates, no asymmetric debris. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 64x64 pixels. "
    "Balanced confident composition. Highest quality concept art for game UI."
)

# ===== 系统功能: 扁平方形 =====
PROMPT_TEMPLATE_SYSTEM_FLAT = (
    "A minimalist flat game UI system icon for a cultivation wuxia RPG, centered square composition. "
    "Subject: {subject}. "
    "The subject occupies about 75 percent of the canvas in the center with strong clear silhouette, "
    "drawn with crisp uniform ink black outlines and flat fills, completely flat vector style with no "
    "shading or gradients. Pure clean solid white background, no outer frame or border. "
    "{palette} color palette only. "
    "No realistic human portraits, only stylized silhouettes if any, no facial features, no complex "
    "patterns, no maze patterns, no text, no chinese characters, no multiple subjects, no debris, "
    "no asymmetric elements. "
    "Single focal point. Designed to be readable when scaled down to 48x48 pixels. "
    "Symmetric balanced silhouette. Highest quality minimalist UI icon."
)

# ===== 任务标识: 菱形构图 =====
PROMPT_TEMPLATE_QUEST_DIAMOND = (
    "A minimalist game UI quest marker icon for a cultivation wuxia RPG, centered composition. "
    "Subject: {subject}. "
    "The subject occupies about 65 percent of the canvas in the center, framed inside a single closed "
    "rhombus diamond shape standing on its point, the diamond drawn as a uniform thin gold line, "
    "perfectly symmetric along both the vertical and horizontal axes, no decoration on the diamond "
    "frame itself. Pure clean solid white background, no other elements. "
    "Flat vector illustration style, simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, no facial features, no complex patterns, no maze patterns, no text, "
    "no chinese characters, no multiple subjects, no debris, no asymmetric elements outside the diamond. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 48x48 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)

# ===== 地图标记: 圆形构图 =====
PROMPT_TEMPLATE_MAP_CIRCLE = (
    "A minimalist game UI map marker icon for a cultivation wuxia RPG, centered composition. "
    "Subject: {subject}. "
    "The subject occupies about 70 percent of the canvas in the center, framed inside a single closed "
    "circular border drawn as a full 360 degree circle, uniform thin line weight, completely symmetric, "
    "no decoration on the circle itself. Pure clean solid white background, no other elements. "
    "Flat vector illustration style, simplified for icon use. {palette} color palette only. "
    "No realistic human portraits, no facial features, no complex patterns, no maze patterns, no text, "
    "no chinese characters, no multiple subjects, no debris, no asymmetric elements outside the circle. "
    "Single focal point on the central subject. Designed to be readable when scaled down to 48x48 pixels. "
    "Symmetric and balanced composition. Highest quality concept art for game UI."
)


# ===== 5 个战斗状态 =====
COMBAT_ICONS = [
    {
        "name": "status_icon_down",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_COMBAT,
            "a single stylized humanoid silhouette kneeling forward in a collapsed exhausted posture, "
            "the head bowed low and shoulders sagging downward, with thin wisps of dark ink smoke "
            "spiraling gently downward around the figure suggesting drained vital energy, the silhouette "
            "completely featureless and abstract in solid shape only",
            "muted dark gray and dim crimson outline accent",
        ),
    },
    {
        "name": "status_icon_break",
        "color": "#a04020",
        "prompt": expand(
            PROMPT_TEMPLATE_COMBAT,
            "a single stylized shattered circular spiritual energy barrier exploding outward, with broken "
            "angular fragments flying outward symmetrically in a starburst pattern around a small empty "
            "center, suggesting collapsed defense at the moment of guard break",
            "warm gold red and bright golden crack",
        ),
    },
    {
        "name": "status_icon_link",
        "color": "#8090c0",
        "prompt": expand(
            PROMPT_TEMPLATE_COMBAT,
            "two interlinked golden energy chains weaving into a perfect infinity loop symbol in the "
            "center, with a small bright glowing spiritual energy bead at the crossing intersection point, "
            "suggesting a special battle link binding two combatants",
            "bright gold and luminous spiritual blue",
        ),
    },
    {
        "name": "status_icon_execute",
        "color": "#c08040",
        "prompt": expand(
            PROMPT_TEMPLATE_COMBAT,
            "a single stylized golden longsword plunging straight down vertically in the center of the "
            "frame, with a single small dark red blood droplet near the blade tip, and a faint radiating "
            "starburst of golden light behind suggesting a finishing executioner's strike",
            "gold white and dark crimson",
        ),
    },
    {
        "name": "status_icon_parry",
        "color": "#d0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_COMBAT,
            "two stylized crossed sword blades meeting at the exact center forming a perfect X shape, "
            "with a small cluster of bright spark fragments scattered outward at the impact point in the "
            "middle, suggesting a perfectly timed parry",
            "gold white and warm orange yellow spark",
        ),
    },
]


# ===== 18 个 Buff =====
BUFF_ICONS = [
    {
        "name": "buff_icon_atk_up",
        "color": "#a04040",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single stylized golden short sword pointing upward at a slight angle with a faint warm "
            "flame glow surrounding the blade, suggesting boosted attack power",
            "warm crimson red and bright gold flame",
        ),
    },
    {
        "name": "buff_icon_crit_up",
        "color": "#c04040",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single bright crimson red gemstone in the center with a four pointed star burst exploding "
            "outward from inside the gem, suggesting critical strike chance",
            "deep crimson red and pale gold sparkle",
        ),
    },
    {
        "name": "buff_icon_atk_speed_up",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "three diagonal streaking light trails forming the after image silhouettes of a sword swing, "
            "the trails flowing from upper left to lower right with sharp pointed tips suggesting "
            "increased attack speed",
            "gold and pale white light streak",
        ),
    },
    {
        "name": "buff_icon_lethal",
        "color": "#c06020",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single stylized longsword standing upright vertically in the center, the blade engulfed "
            "in golden red flames licking upward, with a soft golden radiance halo behind, suggesting a "
            "guaranteed lethal blow",
            "molten gold red and bright golden halo",
        ),
    },
    {
        "name": "buff_icon_def_up",
        "color": "#6080c0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single stylized pale blue spiritual energy shield in the center with a simplified eight "
            "trigram bagua pattern carved on its surface, the shield facing the viewer suggesting "
            "boosted defense",
            "soft cyan blue and pale silver",
        ),
    },
    {
        "name": "buff_icon_qi_shield",
        "color": "#40a0c0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single semi transparent pale cyan spiritual energy sphere barrier in the center with "
            "faint flowing rune symbols drifting across its surface, suggesting a qi protective shield",
            "translucent cyan green and pale white inner glow",
        ),
    },
    {
        "name": "buff_icon_res_up",
        "color": "#a08060",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single sturdy ancient Chinese bronze cauldron tripod standing solidly in the center, its "
            "body carved with simplified daoist trigram symbols, suggesting elemental resistance",
            "antique bronze and yellow gold dao pattern",
        ),
    },
    {
        "name": "buff_icon_invincible",
        "color": "#d0c060",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single golden five pointed star shaped invincible shield in the center, with star rays "
            "radiating outward in symmetrical pattern, suggesting invulnerability",
            "brilliant gold and pale white radiance",
        ),
    },
    {
        "name": "buff_icon_hp_regen",
        "color": "#40a060",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single emerald green heart shaped spiritual herb leaf in the center, with a small clear "
            "droplet of life essence dripping from the leaf tip, with a soft pale green glow behind, "
            "suggesting health regeneration",
            "vivid emerald green and pale jade glow",
        ),
    },
    {
        "name": "buff_icon_qi_regen",
        "color": "#40a0a0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single floating pale cyan spiritual energy bead suspended in the center, with a daoist "
            "swirl pattern spiraling upward beneath it suggesting qi recovery flowing into the body",
            "soft cyan green and pale white spiral",
        ),
    },
    {
        "name": "buff_icon_meditation",
        "color": "#6090a0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single small humanoid silhouette sitting cross legged in lotus meditation posture in the "
            "center, with a single thin wisp of cyan smoke rising from the crown of the head and curling "
            "into a small daoist symbol above, suggesting accelerated meditation",
            "soft slate blue and pale cyan wisp",
        ),
    },
    {
        "name": "buff_icon_luck_up",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single ancient Chinese golden round coin tied with a red silk ribbon knot through the "
            "central square hole, the ribbon forming a simple decorative knot, suggesting good fortune",
            "rich gold and bright crimson red ribbon",
        ),
    },
    {
        "name": "buff_icon_move_speed_up",
        "color": "#9080c0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single stylized pale violet feathered wing in the center with the feather tips trailing "
            "soft streaking light residue suggesting swift movement",
            "lavender violet and pale silver streak",
        ),
    },
    {
        "name": "buff_icon_perception_up",
        "color": "#a060a0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single open third eye in the center with a violet iris, surrounded by a thin ring of "
            "small golden daoist rune symbols circling the eye, suggesting heightened spiritual "
            "perception",
            "deep violet purple and bright gold rune",
        ),
    },
    {
        "name": "buff_icon_stealth",
        "color": "#a0a0b0",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single semi transparent humanoid silhouette in the center already fading away into thin "
            "air, the lower half nearly invisible and the upper half a faint outline, suggesting "
            "stealth invisibility",
            "pale dusty gray violet and translucent white",
        ),
    },
    {
        "name": "buff_icon_inner_flow",
        "color": "#a06040",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single swirling taiji yin yang pattern in the center with bright golden red qi and "
            "translucent cyan green qi flowing in a circulating loop along the spiral, suggesting "
            "inner energy circulation",
            "warm golden red and soft cyan green",
        ),
    },
    {
        "name": "buff_icon_elements_balance",
        "color": "#80a040",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "five tiny stylized symbols of metal wood water fire and earth arranged in a perfect circle "
            "around a small central taiji symbol, all icons floating in symmetric balance suggesting "
            "five element harmony",
            "balanced multi color metal silver wood green water blue fire red earth yellow",
        ),
    },
    {
        "name": "buff_icon_epiphany",
        "color": "#c0a080",
        "prompt": expand(
            PROMPT_TEMPLATE_BUFF,
            "a single lotus bud blooming at the top of its stem in the center, releasing a single bright "
            "golden light burst from its open petals, with a small wisdom pearl floating inside the "
            "light, suggesting a moment of enlightenment",
            "pale lotus white and bright golden enlightenment glow",
        ),
    },
]


# ===== 18 个 Debuff =====
DEBUFF_ICONS = [
    {
        "name": "debuff_icon_stun",
        "color": "#604080",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single small humanoid head silhouette in the center with three tiny purple star symbols "
            "rotating in a circle around the head, suggesting stunned disorientation",
            "dark violet purple and dim black",
        ),
    },
    {
        "name": "debuff_icon_frozen",
        "color": "#8090c0",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single small humanoid silhouette in the center fully encased in a translucent pale blue "
            "ice crystal block, with fine hairline cracks visible across the ice surface, suggesting a "
            "frozen state",
            "cold pale icy blue and translucent white frost",
        ),
    },
    {
        "name": "debuff_icon_slow",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a pair of heavy lead gray iron chains wrapping around two stylized feet in the lower "
            "center of the frame, the chain links sagging heavily downward suggesting impeded movement",
            "lead gray and dim dark iron",
        ),
    },
    {
        "name": "debuff_icon_silence",
        "color": "#a04060",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single small mouth in the center sealed shut by a red rectangular paper talisman strip "
            "stretched horizontally across it, the talisman decorated with simple golden seal scroll "
            "ornament, suggesting forced silence",
            "deep crimson talisman red and bright gold seal",
        ),
    },
    {
        "name": "debuff_icon_disarm",
        "color": "#806040",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single broken sword snapped clean across the middle in the center, the hilt falling "
            "downward at an angle and the broken blade tip flying upward, suggesting forced disarming",
            "dull steel gray and dim dark red",
        ),
    },
    {
        "name": "debuff_icon_bleed",
        "color": "#a02020",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "three vivid bright crimson red blood droplets falling vertically in the center of the "
            "frame, with a soft pale ink wash bleeding outward behind them, suggesting continuous "
            "bleeding damage",
            "bright crimson blood red and faint ink wash gray",
        ),
    },
    {
        "name": "debuff_icon_poison",
        "color": "#608040",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single small stylized skull in the center colored sickly purplish green, with thin "
            "wisps of toxic vapor rising from its eye sockets and crown, suggesting poison",
            "sickly purplish green and dim toxic violet",
        ),
    },
    {
        "name": "debuff_icon_burn",
        "color": "#c06020",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single small humanoid silhouette in the center fully wrapped in a coiling cluster of "
            "bright orange red flames, the flame tongues curling upward and around the figure, "
            "suggesting burning damage",
            "intense orange red and bright golden flame",
        ),
    },
    {
        "name": "debuff_icon_heart_demon",
        "color": "#602020",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single dark black heart in the center bound tightly by a coiling crimson red chain, "
            "with fine cracks running across the heart surface seeping thin tendrils of black smoke, "
            "suggesting inner demon corruption",
            "dark obsidian black and bright crimson chain",
        ),
    },
    {
        "name": "debuff_icon_atk_down",
        "color": "#606080",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single short sword in the center tilted downward at a steep angle with the blade dull "
            "and lusterless, no light reflecting off the surface, suggesting weakened attack power",
            "dull cold gray steel and dim ash",
        ),
    },
    {
        "name": "debuff_icon_def_down",
        "color": "#606080",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single round shield in the center already shattered with deep cracks radiating across "
            "its surface in a spider web pattern, the gray metal looking weakened, suggesting weakened "
            "defense",
            "dull gray steel and dim crack outline",
        ),
    },
    {
        "name": "debuff_icon_speed_down",
        "color": "#606080",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single drooping bird wing in the center with the feathers wilted and falling away "
            "downward, several loose feathers drifting toward the lower edge, suggesting reduced "
            "movement speed",
            "muted gray brown and dim ash feather",
        ),
    },
    {
        "name": "debuff_icon_qi_disorder",
        "color": "#806080",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single distorted broken taiji yin yang pattern in the center with the black and white "
            "fish halves twisted and misaligned, torn apart along the central s curve, suggesting "
            "chaotic qi flow",
            "muted black and pale grayed out white",
        ),
    },
    {
        "name": "debuff_icon_qi_deviation",
        "color": "#802040",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single small humanoid silhouette sitting cross legged in lotus meditation in the center, "
            "with thick black demonic smoke rising from the crown of the head and bright red crack "
            "lines running across the body, suggesting qi deviation cultivation backlash",
            "deep demonic black and ominous crimson red crack",
        ),
    },
    {
        "name": "debuff_icon_qi_drained",
        "color": "#808080",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single shriveled dried out spiritual energy bead in the center, its surface covered in "
            "deep cracks and its color drained to dull gray, suggesting exhausted qi reserves",
            "dim withered gray and dusty brown crack",
        ),
    },
    {
        "name": "debuff_icon_elements_unbalanced",
        "color": "#806060",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "five small symbols of metal wood water fire and earth in the center scattered chaotically "
            "out of alignment, drifting apart from each other in disorder, all desaturated in color, "
            "suggesting five element imbalance",
            "muted desaturated multi color and dim gray wash",
        ),
    },
    {
        "name": "debuff_icon_faith_shaken",
        "color": "#604060",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single round jade dao heart pendant in the center carved with a small taiji symbol, the "
            "pendant deeply fractured with spider web cracks spreading from the center outward, "
            "suggesting shaken faith in the dao",
            "pale cracked jade green and dim crack line",
        ),
    },
    {
        "name": "debuff_icon_karma_backlash",
        "color": "#a02020",
        "prompt": expand(
            PROMPT_TEMPLATE_DEBUFF,
            "a single inverted upside down karma wheel in the center burning with deep crimson red "
            "karmic fire along its rim, the wheel spokes twisted, suggesting karmic retribution "
            "backlash",
            "ominous crimson karmic flame and dim charcoal black wheel",
        ),
    },
]


# ===== 16 个天赋 (圆角方形外框) =====
TALENT_ICONS = [
    {
        "name": "talent_icon_sharp_edge",
        "color": "#a04040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single jade green sword half drawn from its sheath in the center, the exposed blade tip "
            "shimmering with pale gold luster against a faint warm red inner glow",
            "cool jade green steel and pale gold gleam with faint warm red glow",
        ),
    },
    {
        "name": "talent_icon_lethal_strike",
        "color": "#c06040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single diagonal lightning fast crimson gold sword slash cutting across the center from "
            "upper right to lower left, leaving a streaking residual afterimage",
            "bright crimson gold flash and warm gold streak",
        ),
    },
    {
        "name": "talent_icon_five_element_sword",
        "color": "#a08040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "five colored sword light beams converging into a single central upright longsword in the "
            "center, the beams in gold silver for metal, green for wood, blue for water, red for fire, "
            "yellow for earth, fusing at the blade",
            "balanced multi color gold silver green blue red yellow elemental",
        ),
    },
    {
        "name": "talent_icon_soul_render",
        "color": "#602040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single black red longsword in the center slicing through a thin wispy ghostly soul "
            "silhouette, with a faint dark purple swirl background behind the figure",
            "deep obsidian black red and pale ghostly white wisp",
        ),
    },
    {
        "name": "talent_icon_jade_body",
        "color": "#40a080",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single warm jade green oval pendant in the center carved with a simplified eight trigram "
            "bagua pattern on its face, surrounded by a soft cyan halo",
            "warm jade green and soft cyan halo",
        ),
    },
    {
        "name": "talent_icon_qi_barrier",
        "color": "#4080c0",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single pale cyan blue vertical spiritual energy wall in the center with flowing rune "
            "symbols drifting across its surface",
            "pale cyan blue and soft luminous white rune",
        ),
    },
    {
        "name": "talent_icon_elements_harmony",
        "color": "#80a040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "five tiny element symbols of metal wood water fire and earth arranged in a perfect circle "
            "around a central taiji yin yang ring, in symmetric balance",
            "balanced multi color metal silver wood green water blue fire red earth yellow",
        ),
    },
    {
        "name": "talent_icon_immortal_body",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single golden buddhist arhat figure sitting in lotus meditation in the center, with a "
            "circular golden radiance halo behind the head and shoulders",
            "brilliant gold and warm orange buddha glow",
        ),
    },
    {
        "name": "talent_icon_inner_circulation",
        "color": "#a06040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single swirling taiji circulation pattern in the center with warm red qi and cool cyan "
            "qi flowing in a spiraling loop along the central s curve",
            "warm red and soft cyan green spiral",
        ),
    },
    {
        "name": "talent_icon_healing_hand",
        "color": "#40a060",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single open hand palm up cradling a vibrant emerald green spirit herb pearl in its "
            "center, the hand emitting a soft jade green glow",
            "vivid emerald green and pale jade glow",
        ),
    },
    {
        "name": "talent_icon_perception_expand",
        "color": "#a060a0",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single open third eye in the center with a violet iris, surrounded by a thin ring of "
            "small golden daoist rune symbols circling it",
            "deep violet purple and bright gold rune",
        ),
    },
    {
        "name": "talent_icon_divination",
        "color": "#a08040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single unrolled bamboo divination scroll in the center with simplified tortoise shell "
            "geometric patterns and trigram hexagram symbols drawn on it",
            "warm parchment yellow and dim ink black symbol",
        ),
    },
    {
        "name": "talent_icon_great_fortune",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single golden round ancient Chinese coin in the center with a square hole in the middle, "
            "a bright red silk cord threaded through the hole forming a simple decorative knot",
            "rich gold and bright crimson red ribbon",
        ),
    },
    {
        "name": "talent_icon_epiphany_seeker",
        "color": "#c0a080",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single blooming lotus flower in the center releasing a glowing wisdom pearl from its "
            "open petals, with a soft golden enlightenment glow rising upward",
            "pale lotus white and bright golden enlightenment glow",
        ),
    },
    {
        "name": "talent_icon_firm_heart",
        "color": "#a08060",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single translucent crystal heart in the center containing a small stable taiji yin yang "
            "symbol inside, with warm golden radiance rays behind",
            "clear crystal white and warm gold radiance",
        ),
    },
    {
        "name": "talent_icon_longevity",
        "color": "#80a0a0",
        "prompt": expand(
            PROMPT_TEMPLATE_TALENT,
            "a single graceful flying crane silhouette circling above an ancient pine tree branch with "
            "a full round moon in the background sky",
            "misty silver white and pale pine green",
        ),
    },
]


# ===== 16 个武学 (方形构图无外框) =====
MARTIAL_ARTS_ICONS = [
    {
        "name": "skill_icon_sword_control",
        "color": "#8090c0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single flying sword hovering horizontally above swirling cloud wisps in the center, with "
            "a faint daoist seal rune pattern glowing beneath the sword",
            "silver white and pale jade cyan",
        ),
    },
    {
        "name": "skill_icon_myriad_swords",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "hundreds of stylized flying swords converging into a single spiral vortex of sword light "
            "in the center, the swords spiraling inward in a tight whirlwind formation",
            "silver white and bright gold",
        ),
    },
    {
        "name": "skill_icon_cold_light_sword",
        "color": "#40a0a0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single sweeping horizontal jade green sword arc in the center leaving a long streaking "
            "afterimage trailing behind, with faded ink wash mountain silhouettes in the deep background",
            "cool jade green and dim ink wash gray",
        ),
    },
    {
        "name": "skill_icon_thousand_mountain_snow",
        "color": "#8090c0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a snow covered mountain range silhouette being cleaved through the middle by a single "
            "vertical sword qi line, with delicate snowflakes scattering in the air around",
            "cold pale icy blue and crisp white",
        ),
    },
    {
        "name": "skill_icon_luohan_fist",
        "color": "#c08040",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single golden buddhist arhat figure throwing a powerful forward punch in the center, "
            "with a bright burst of golden buddha light radiating around the fist",
            "brilliant gold and warm buddha orange",
        ),
    },
    {
        "name": "skill_icon_fire_palm",
        "color": "#c04040",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single open hand in the center projecting a burst of crimson red flame outward from "
            "the palm, with a small bagua li trigram symbol etched on the palm center",
            "intense crimson red and bright golden flame",
        ),
    },
    {
        "name": "skill_icon_water_qi",
        "color": "#4080a0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single open hand palm up in the center with a water droplet forming above the palm and "
            "rippling outward in concentric circular waves",
            "deep teal blue and pale cyan ripple",
        ),
    },
    {
        "name": "skill_icon_tiangang_qi",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single straight vertical golden pillar of light rising up into the heavens in the "
            "center, with a big dipper seven star constellation pattern arranged along its length",
            "brilliant gold and pale starlight white",
        ),
    },
    {
        "name": "skill_icon_lingbo_steps",
        "color": "#9080c0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single graceful flowing humanoid silhouette stepping forward in the center, leaving "
            "three trailing afterimages behind in pale violet streaking light",
            "lavender violet and pale silver streak",
        ),
    },
    {
        "name": "skill_icon_wind_riding",
        "color": "#80a0c0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single humanoid silhouette standing balanced on swirling wind clouds in the center, "
            "with flowing silk robes and ribbons trailing behind in the wind",
            "soft cyan blue and pale white wind streak",
        ),
    },
    {
        "name": "skill_icon_five_dun",
        "color": "#80a040",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single humanoid silhouette in the center surrounded by five swirling streams of "
            "elemental light circling around the body, in gold for metal, green for wood, blue for "
            "water, red for fire, yellow for earth",
            "balanced multi color elemental five color",
        ),
    },
    {
        "name": "skill_icon_bone_melt_palm",
        "color": "#806080",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single soft flowing hand in the center palm forward, with grayish white poisonous "
            "vapor wisps leaking out from the palm center and drifting upward",
            "dim grayish violet and pale toxic white vapor",
        ),
    },
    {
        "name": "skill_icon_taiji_method",
        "color": "#404060",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single perfect yin yang taiji symbol in the center with the black and white fish halves "
            "flowing in motion, surrounded by a thin ring of simplified daoist rune symbols",
            "deep ink black and pure white",
        ),
    },
    {
        "name": "skill_icon_yuanying_method",
        "color": "#8060a0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single humanoid silhouette sitting in lotus meditation in the center, with a glowing "
            "round violet purple dan pearl illuminated at the lower abdomen area",
            "deep violet purple and pale luminous gold",
        ),
    },
    {
        "name": "skill_icon_zhoutian_dao",
        "color": "#404080",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a celestial orbit diagram in the center with sun moon and several stars circling a "
            "central daoist rune symbol in concentric orbital paths",
            "deep midnight indigo and brilliant gold celestial",
        ),
    },
    {
        "name": "skill_icon_ascension",
        "color": "#a060a0",
        "prompt": expand(
            PROMPT_TEMPLATE_MARTIAL,
            "a single immortal silhouette ascending upward facing crackling violet golden heaven "
            "lightning bolts above, with a sea of clouds and rosy auroral glow in the background",
            "brilliant violet gold and rosy auroral pink",
        ),
    },
]


# ===== 13 个系统功能 (扁平方形) =====
# 注: 与 SYSTEM_QUEST_MAP_ICONS 拆分自原 SYSTEM_ICONS_GROUP, 避免单工作流节点数超 150
SYSTEM_FUNC_ICONS = [
    # ---- 5.1 系统功能 (扁平方形, 13张) ----
    {
        "name": "system_icon_inventory",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single ancient style cloth pouch (gourd shaped qiankun bag) in the center, with a "
            "bright red silk cord knot tying its mouth shut",
            "ink black and cream white with red cord accent",
        ),
    },
    {
        "name": "system_icon_character",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single human figure silhouette in the center sitting cross legged in lotus meditation, "
            "simple and clean outline",
            "ink black and cream white",
        ),
    },
    {
        "name": "system_icon_cultivation",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single perfect yin yang taiji symbol in the center with a thin ring of simplified "
            "daoist rune symbols around it",
            "ink black and cream white",
        ),
    },
    {
        "name": "system_icon_skills",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "two stylized crossed swords forming an X in the center with the hilts pointing downward "
            "and blades pointing upward",
            "ink black and cream white",
        ),
    },
    {
        "name": "system_icon_map",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single unrolled ancient map scroll in the center with simplified mountain peaks and a "
            "winding river marking drawn on it",
            "ink black and cream white with pale gold accent",
        ),
    },
    {
        "name": "system_icon_quest",
        "color": "#806040",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single partially unrolled bamboo slip scroll in the center with a few simplified "
            "abstract character marks (geometric strokes) on it, not actual chinese writing",
            "ink black and cream white with pale yellow accent",
        ),
    },
    {
        "name": "system_icon_relations",
        "color": "#a08060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "three small human silhouettes in the center connected by thin pale gold lines forming a "
            "triangular network",
            "ink black and cream white with pale gold line",
        ),
    },
    {
        "name": "system_icon_sect",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single ancient style sect gate paifang archway in the center with a small daoist bagua "
            "pattern decoration on top",
            "ink black and cream white",
        ),
    },
    {
        "name": "system_icon_settings",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single simplified gear shape in the center with a small daoist bagua pattern at its "
            "center hub",
            "ink black and cream white",
        ),
    },
    {
        "name": "system_icon_save",
        "color": "#a04040",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single rolled up scroll in the center tied with a crimson red cord, with a small "
            "daoist seal rune pattern visible on the scroll",
            "ink black and cream white with crimson red cord accent",
        ),
    },
    {
        "name": "system_icon_help",
        "color": "#a08040",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single ancient style hanging paper lantern in the center with a simple decorative "
            "ornament pattern on its paper face, glowing softly from within",
            "ink black and cream white with warm yellow lantern glow",
        ),
    },
    {
        "name": "system_icon_exit",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "a single half opened ancient style sect gate in the center with thin wisps of cloud "
            "drifting outward through the opening",
            "ink black and cream white",
        ),
    },
    {
        "name": "system_icon_pause",
        "color": "#806040",
        "prompt": expand(
            PROMPT_TEMPLATE_SYSTEM_FLAT,
            "two vertical antique bronze pillars standing parallel in the center, evenly spaced in "
            "the classic pause symbol arrangement",
            "ink black and antique bronze",
        ),
    },
]


# ===== 10 个任务标识 + 地图图例 (4 菱形 + 6 圆形) =====
SYSTEM_QUEST_MAP_ICONS = [
    # ---- 5.2 任务标识 (菱形, 4张) ----
    {
        "name": "quest_icon_main",
        "color": "#d0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_QUEST_DIAMOND,
            "a single golden exclamation mark stylized as a daoist rune symbol in the center, with a "
            "pulsing golden halo around it",
            "brilliant gold and warm radiant gold halo",
        ),
    },
    {
        "name": "quest_icon_side",
        "color": "#a0a0c0",
        "prompt": expand(
            PROMPT_TEMPLATE_QUEST_DIAMOND,
            "a single silver white question mark stylized as a daoist rune symbol in the center, with "
            "a soft pale cyan halo around it",
            "silver white and soft pale cyan halo",
        ),
    },
    {
        "name": "quest_icon_encounter",
        "color": "#a060c0",
        "prompt": expand(
            PROMPT_TEMPLATE_QUEST_DIAMOND,
            "a single blooming violet purple cloud pattern flower in the center with bright golden "
            "light glowing at the stamens",
            "deep violet purple and bright gold stamen",
        ),
    },
    {
        "name": "quest_icon_complete",
        "color": "#d0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_QUEST_DIAMOND,
            "a single golden checkmark tick stylized as a daoist rune symbol in the center, with "
            "golden radiant rays bursting outward behind it",
            "brilliant gold and pale gold radiance",
        ),
    },
    # ---- 5.3 地图标记 (圆形, 6张) ----
    {
        "name": "map_icon_current",
        "color": "#c04040",
        "prompt": expand(
            PROMPT_TEMPLATE_MAP_CIRCLE,
            "a single bright red location pin teardrop shape in the center fused with a small daoist "
            "seal rune pattern on its face, the pin tip pointing downward",
            "cinnabar red and warm gold edge",
        ),
    },
    {
        "name": "map_icon_town",
        "color": "#606060",
        "prompt": expand(
            PROMPT_TEMPLATE_MAP_CIRCLE,
            "a single simplified ancient style chinese city tower silhouette outline in the center "
            "with a tiered pagoda roof",
            "ink black and cream white",
        ),
    },
    {
        "name": "map_icon_sect",
        "color": "#a08040",
        "prompt": expand(
            PROMPT_TEMPLATE_MAP_CIRCLE,
            "a single ancient sect gate paifang archway silhouette in the center with simple "
            "decorative crossbeam",
            "ink black and pale gold",
        ),
    },
    {
        "name": "map_icon_dungeon",
        "color": "#604080",
        "prompt": expand(
            PROMPT_TEMPLATE_MAP_CIRCLE,
            "a single dark mountain cave entrance silhouette in the center shrouded in swirling "
            "violet mist and cloud wisps drifting from the opening",
            "ink black and pale violet cyan",
        ),
    },
    {
        "name": "map_icon_enemy",
        "color": "#a02020",
        "prompt": expand(
            PROMPT_TEMPLATE_MAP_CIRCLE,
            "two stylized crossed crimson red longswords forming an X in the center with the hilts "
            "downward and blades upward",
            "ink black and bright crimson red",
        ),
    },
    {
        "name": "map_icon_merchant",
        "color": "#c0a040",
        "prompt": expand(
            PROMPT_TEMPLATE_MAP_CIRCLE,
            "a single rich gold chinese round coin with a square hole in the middle in the center, "
            "its surface flat and clean",
            "rich gold and dim ink black",
        ),
    },
]


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out_dir = os.path.join(here, "workflows")

    # ===== 06 战斗状态 =====
    combat_note = (
        "■ 工作流: 战斗状态图标批量生成 (FLUX)\n"
        "   一次 Queue Prompt 出全部 5 张\n"
        "   预计耗时 25-30 分钟 (M4 Pro)\n\n"
        "■ 战斗状态:\n"
        "   1. Down 力竭倒地 (status_icon_down)\n"
        "   2. Break 架势爆破 (status_icon_break)\n"
        "   3. Link 战斗链接 (status_icon_link)\n"
        "   4. Execute 处决 (status_icon_execute)\n"
        "   5. Parry 完美格挡 (status_icon_parry)\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent (相同噪声起点)\n"
        "   - 提示词模板统一,只换 SUBJECT + COLOR\n\n"
        "■ 输出 (每张 2 份):\n"
        "   output/wuxia_combat_1024/[name].png\n"
        "   output/wuxia_combat_128/[name].png\n\n"
        "■ 命名规范 (与代码对齐):\n"
        "   status_icon_[name].png\n"
        "   由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/status_icons/\n\n"
        "■ 单张重抽:\n"
        "   1. 找到该图标的 KSampler 节点\n"
        "   2. seed 改成别的数 (如 88888889)\n"
        "   3. control_after_generate 暂改 randomize\n"
        "   4. 单独 Queue Prompt 重抽\n"
        "   5. 满意后改回 fixed"
    )
    wf06 = build_workflow(
        icons=COMBAT_ICONS,
        master_dir="wuxia_combat_1024",
        final_dir="wuxia_combat_128",
        final_size=128,
        title="战斗状态批量出图说明 (共5张)",
        note_body=combat_note,
    )
    save(wf06, os.path.join(out_dir, "06_combat_states_batch_flux.json"))

    # ===== 07 Buff =====
    buff_note = (
        "■ 工作流: Buff 增益图标批量生成 (FLUX)\n"
        "   一次 Queue Prompt 出全部 18 张\n"
        "   预计耗时 95-110 分钟 (M4 Pro)\n\n"
        "■ Buff 序列 (圆形玉佩外框):\n"
        "   攻击系  1-4 atk_up/crit_up/atk_speed_up/lethal\n"
        "   防御系  5-8 def_up/qi_shield/res_up/invincible\n"
        "   增益系 9-12 hp_regen/qi_regen/meditation/luck_up\n"
        "   感知系 13-15 move_speed_up/perception_up/stealth\n"
        "   修真系 16-18 inner_flow/elements_balance/epiphany\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent 1024x1024\n"
        "   - 圆形玉佩外框统一\n\n"
        "■ 输出 (每张 2 份):\n"
        "   output/wuxia_buff_1024/[name].png   (1024 母版)\n"
        "   output/wuxia_buff_64/[name].png      (64 游戏图标)\n\n"
        "■ 命名规范 (与 status-effects-system 对齐):\n"
        "   buff_icon_[name].png\n"
        "   由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/buff_icons/\n\n"
        "■ 单张重抽:\n"
        "   1. 找到该图标的 KSampler 节点\n"
        "   2. seed 改成别的数 (如 88888889)\n"
        "   3. control_after_generate 暂改 randomize\n"
        "   4. 单独 Queue Prompt 重抽\n"
        "   5. 满意后改回 fixed\n\n"
        "■ 注意:\n"
        "   生成 1024 是为了保留高清母版便于未来重缩放\n"
        "   实际入游戏的是缩放后的 64x64 PNG"
    )
    wf07 = build_workflow(
        icons=BUFF_ICONS,
        master_dir="wuxia_buff_1024",
        final_dir="wuxia_buff_64",
        final_size=64,
        title="Buff 增益批量出图说明 (共18张)",
        note_body=buff_note,
    )
    save(wf07, os.path.join(out_dir, "07_buffs_batch_flux.json"))

    # ===== 08 Debuff =====
    debuff_note = (
        "■ 工作流: Debuff 减益图标批量生成 (FLUX)\n"
        "   一次 Queue Prompt 出全部 18 张\n"
        "   预计耗时 95-110 分钟 (M4 Pro)\n\n"
        "■ Debuff 序列 (棱形碎玉外框):\n"
        "   控制系  1-5 stun/frozen/slow/silence/disarm\n"
        "   持续伤害 6-9 bleed/poison/burn/heart_demon\n"
        "   削弱系 10-12 atk_down/def_down/speed_down\n"
        "   修真系 13-18 qi_disorder/qi_deviation/qi_drained/\n"
        "                  elements_unbalanced/faith_shaken/karma_backlash\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent 1024x1024\n"
        "   - 棱形碎玉外框统一,与 Buff 圆形玉佩盲识可分\n\n"
        "■ 输出 (每张 2 份):\n"
        "   output/wuxia_debuff_1024/[name].png  (1024 母版)\n"
        "   output/wuxia_debuff_64/[name].png    (64 游戏图标)\n\n"
        "■ 命名规范 (与 status-effects-system 对齐):\n"
        "   debuff_icon_[name].png\n"
        "   由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/buff_icons/ (与 Buff 同目录,文件名前缀区分)\n\n"
        "■ 单张重抽:\n"
        "   1. 找到该图标的 KSampler 节点\n"
        "   2. seed 改成别的数 (如 88888889)\n"
        "   3. control_after_generate 暂改 randomize\n"
        "   4. 单独 Queue Prompt 重抽\n"
        "   5. 满意后改回 fixed\n\n"
        "■ 注意:\n"
        "   FLUX 对棱形/菱形外框可能不如圆形稳定\n"
        "   若整批外框崩坏,把 Note 提示词模板中 rhomboid 改为\n"
        "   octagonal 或换回 circular 全部重抽"
    )
    wf08 = build_workflow(
        icons=DEBUFF_ICONS,
        master_dir="wuxia_debuff_1024",
        final_dir="wuxia_debuff_64",
        final_size=64,
        title="Debuff 减益批量出图说明 (共18张)",
        note_body=debuff_note,
    )
    save(wf08, os.path.join(out_dir, "08_debuffs_batch_flux.json"))

    # ===== 09 天赋 =====
    talent_note = (
        "■ 工作流: 天赋节点图标批量生成 (FLUX)\n"
        "   一次 Queue Prompt 出全部 16 张\n"
        "   预计耗时 85-100 分钟 (M4 Pro)\n\n"
        "■ 天赋序列 (圆角方形金边外框):\n"
        "   行1 攻势 1-4 sharp_edge/lethal_strike/\n"
        "                 five_element_sword/soul_render\n"
        "   行2 守护 5-8 jade_body/qi_barrier/\n"
        "                 elements_harmony/immortal_body\n"
        "   行3 辅助 9-12 inner_circulation/healing_hand/\n"
        "                  perception_expand/divination\n"
        "   行4 修身 13-16 great_fortune/epiphany_seeker/\n"
        "                   firm_heart/longevity\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent 1024x1024\n"
        "   - 圆角方形外框 (与 Buff 圆形/Debuff 棱形可盲识区分)\n\n"
        "■ 输出 (每张 2 份):\n"
        "   output/wuxia_talent_1024/[name].png  (1024 母版)\n"
        "   output/wuxia_talent_128/[name].png   (128 游戏图标)\n\n"
        "■ 命名规范 (与 talent-system 对齐):\n"
        "   talent_icon_[name].png\n"
        "   由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/talent_icons/\n\n"
        "■ 单张重抽:\n"
        "   1. 找到该图标的 KSampler 节点\n"
        "   2. seed 改成别的数 (如 88888889)\n"
        "   3. control_after_generate 暂改 randomize\n"
        "   4. 单独 Queue Prompt 重抽\n"
        "   5. 满意后改回 fixed\n\n"
        "■ 注意:\n"
        "   FLUX 对圆角方形外框较稳, 但若个别图崩坏可单抽\n"
        "   实际渲染 64x64, 1024 母版仅作备份"
    )
    wf09 = build_workflow(
        icons=TALENT_ICONS,
        master_dir="wuxia_talent_1024",
        final_dir="wuxia_talent_128",
        final_size=128,
        title="天赋节点批量出图说明 (共16张)",
        note_body=talent_note,
    )
    save(wf09, os.path.join(out_dir, "09_talents_batch_flux.json"))

    # ===== 10 武学 =====
    martial_note = (
        "■ 工作流: 武学技能图标批量生成 (FLUX)\n"
        "   一次 Queue Prompt 出全部 16 张\n"
        "   预计耗时 85-100 分钟 (M4 Pro)\n\n"
        "■ 武学序列 (方形构图无外框):\n"
        "   剑法 1-4 sword_control/myriad_swords/\n"
        "             cold_light_sword/thousand_mountain_snow\n"
        "   拳掌 5-8 luohan_fist/fire_palm/\n"
        "             water_qi/tiangang_qi\n"
        "   身法 9-12 lingbo_steps/wind_riding/\n"
        "              five_dun/bone_melt_palm\n"
        "   修真 13-16 taiji_method/yuanying_method/\n"
        "               zhoutian_dao/ascension\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent 1024x1024\n"
        "   - 方形构图无外框 (与天赋/Buff 系明显不同)\n\n"
        "■ 输出 (每张 2 份):\n"
        "   output/wuxia_skill_1024/[name].png   (1024 母版)\n"
        "   output/wuxia_skill_128/[name].png    (128 游戏图标)\n\n"
        "■ 命名规范 (与 martial-arts-system 对齐):\n"
        "   skill_icon_[name].png\n"
        "   由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/skill_icons/\n\n"
        "■ 单张重抽: 同前\n\n"
        "■ 注意:\n"
        "   武学没外框, FLUX 偶尔会自己加一圈, 若出现可单抽\n"
        "   提示词里已写 no outer border or ring 进行约束"
    )
    wf10 = build_workflow(
        icons=MARTIAL_ARTS_ICONS,
        master_dir="wuxia_skill_1024",
        final_dir="wuxia_skill_128",
        final_size=128,
        title="武学技能批量出图说明 (共16张)",
        note_body=martial_note,
    )
    save(wf10, os.path.join(out_dir, "10_martial_arts_batch_flux.json"))

    # ===== 11a 系统功能 (拆分自原 11, 避免节点数超 150) =====
    system_func_note = (
        "■ 工作流: 系统功能图标批量生成 (FLUX) - 拆分批 a\n"
        "   一次 Queue Prompt 出全部 13 张\n"
        "   预计耗时 65-80 分钟 (M4 Pro)\n\n"
        "■ 系统功能 (扁平方形 SYSTEM_FLAT, 13张):\n"
        "   inventory/character/cultivation/skills/map/\n"
        "   quest/relations/sect/settings/save/\n"
        "   help/exit/pause\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent 1024x1024\n"
        "   - 扁平方形无外框, 描边墨黑\n\n"
        "■ 输出 (每张 2 份):\n"
        "   output/wuxia_system_1024/system_icon_*.png  (1024 母版)\n"
        "   output/wuxia_system_96/system_icon_*.png    (96 游戏图标)\n\n"
        "■ 命名规范:\n"
        "   system_icon_[name].png\n"
        "   由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/system_icons/\n\n"
        "■ 单张重抽: 同前\n\n"
        "■ 注意:\n"
        "   - 与 11b (任务/地图) 共享输出目录, 文件前缀 system_ 区分\n"
        "   - 系统扁平图标尽量保持单色描边纯净, 避免渐变"
    )
    wf11a = build_workflow(
        icons=SYSTEM_FUNC_ICONS,
        master_dir="wuxia_system_1024",
        final_dir="wuxia_system_96",
        final_size=96,
        title="系统功能批量出图说明 - 拆分批 a (共13张)",
        note_body=system_func_note,
    )
    save(wf11a, os.path.join(out_dir, "11a_system_funcs_batch_flux.json"))

    # ===== 11b 任务/地图 (拆分自原 11) =====
    quest_map_note = (
        "■ 工作流: 任务标识 + 地图图例批量生成 (FLUX) - 拆分批 b\n"
        "   一次 Queue Prompt 出全部 10 张\n"
        "   预计耗时 55-65 分钟 (M4 Pro)\n\n"
        "■ 序列组成:\n"
        "   1-4 任务标识 (菱形 QUEST_DIAMOND)\n"
        "        main/side/encounter/complete\n"
        "   5-10 地图标记 (圆形 MAP_CIRCLE)\n"
        "         current/town/sect/dungeon/enemy/merchant\n\n"
        "■ 风格一致性:\n"
        "   - 共享 seed 88888888 (fixed)\n"
        "   - 共享 EmptyLatent 1024x1024\n"
        "   - 菱形/圆形两种外框, 与 11a 扁平方形盲识区分\n\n"
        "■ 输出 (每张 2 份, 与 11a 同目录):\n"
        "   output/wuxia_system_1024/quest_*|map_*.png  (1024 母版)\n"
        "   output/wuxia_system_96/quest_*|map_*.png    (96 游戏图标)\n\n"
        "■ 命名规范 (前缀区分子类):\n"
        "   quest_icon_*.png  → 任务标识\n"
        "   map_icon_*.png    → 地图标记\n"
        "   均由 import_ai_assets.sh 自动回流到\n"
        "   assets/ui/system_icons/\n\n"
        "■ 单张重抽: 同前\n\n"
        "■ 注意:\n"
        "   - 菱形/圆形外框是 FLUX 的弱项, 生成后逐张目检\n"
        "   - 若整批菱形崩坏, 把 PROMPT_TEMPLATE_QUEST_DIAMOND 中\n"
        "     rhombus 改为 octagon 或 square 重抽"
    )
    wf11b = build_workflow(
        icons=SYSTEM_QUEST_MAP_ICONS,
        master_dir="wuxia_system_1024",
        final_dir="wuxia_system_96",
        final_size=96,
        title="任务/地图批量出图说明 - 拆分批 b (共10张)",
        note_body=quest_map_note,
    )
    save(wf11b, os.path.join(out_dir, "11b_quest_map_batch_flux.json"))

    total = (
        len(COMBAT_ICONS) + len(BUFF_ICONS) + len(DEBUFF_ICONS)
        + len(TALENT_ICONS) + len(MARTIAL_ARTS_ICONS)
        + len(SYSTEM_FUNC_ICONS) + len(SYSTEM_QUEST_MAP_ICONS)
    )
    print(f"\n✓ 已生成 7 个工作流, 累计 {total} 张图")


if __name__ == "__main__":
    main()
