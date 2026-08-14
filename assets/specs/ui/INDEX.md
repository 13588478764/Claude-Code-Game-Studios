# UI 资源生成清单 — 总索引

> 本目录是《武侠奇遇录》(修真武侠 RPG) UI 视觉资源的**生成需求清单**。
> 用于交付给 AI 绘图工具（Midjourney/Stable Diffusion/通义万相/即梦/StarryAI 等）或外包美术。
> 提示词均为**工具无关**的通用中文描述，可按各工具习惯自行调整。

## 目录索引

| # | 文件 | 类别 | 预估数量 | 优先级 |
|---|------|------|---------|--------|
| 01 | [01-icons-realm.md](01-icons-realm.md) | 境界图标 | 9 主图标 + 9 升级特效 | P0 |
| 02 | [02-icons-elements-status.md](02-icons-elements-status.md) | 五行 / 战斗状态图标 | ~25 | P0 |
| 03 | [03-icons-buff-debuff.md](03-icons-buff-debuff.md) | 增益 / 减益状态图标 | ~36 | P1 |
| 04 | [04-icons-skills-talents.md](04-icons-skills-talents.md) | 武学 / 天赋图标 | ~32 | P1 |
| 05 | [05-icons-system-quest.md](05-icons-system-quest.md) | 系统 / 任务图标 | ~22 | P1 |
| 06 | [06-portraits-protagonist-allies.md](06-portraits-protagonist-allies.md) | 主角 / 队友立绘 | ~12 | P0 |
| 07 | [07-portraits-enemies.md](07-portraits-enemies.md) | 敌人 / Boss 立绘 | ~18 | P1 |
| 08 | [08-backgrounds.md](08-backgrounds.md) | 场景 / 菜单背景 | ~15 | P0 |
| 09 | [09-frames-decoration.md](09-frames-decoration.md) | 边框 / 装饰元素 | ~16 | P2 |
| 10 | [10-items.md](10-items.md) | 物品 / 装备图标 | ~70 | P1 |
| 11 | [11-portraits-act1-expansion.md](11-portraits-act1-expansion.md) | Act 1 区域扩展（NPC/敌人立绘 + 补丁 + VFX） | 10 + 12 + 2 + 20 | P0 |

**总计**: 约 294 项资源条目

## 优先级说明

- **P0** — 启动 Alpha 必备：首屏即可见，缺失会阻塞 Demo 演示
- **P1** — Beta 必备：核心玩法循环涉及，缺失会破坏游戏体验
- **P2** — Release 前补齐：装饰性、可用占位符替代

## 全局艺术风格规范

### 风格基调

- **核心风格**: 水墨修真风（中国水墨写意 + 东方仙侠玄幻）
- **构图原则**: 留白、虚实相生、线条刚柔并济
- **画面氛围**: 古韵、空灵、玄妙、磅礴或静谧（视题材而定）
- **参考作品**:
  - 影视：《卧虎藏龙》《英雄》《刺客聂隐娘》《长安三万里》
  - 游戏：《黑神话：悟空》《古剑奇谭》《剑网3》
  - 绘画：宋代山水（范宽、马远）、近代水墨（傅抱石、李可染）
  - 动画：《大鱼海棠》《白蛇：缘起》

### 色彩规范（核心调色板）

| 用途 | 颜色 | HEX | 备注 |
|------|------|-----|------|
| 主色 — 仙气青绿 | 青绿 | `#2E8B57` | 灵气、生机、正道 |
| 强调 — 墨黑 | 墨黑 | `#000000` | 描边、阴影、邪魅 |
| 警示 — 朱砂深红 | 深红 | `#DC143C` | 危险、敌对、煞气 |
| 高贵 — 鎏金 | 金色 | `#FFD700` | 尊贵、奖励、突破特效 |
| 底色 — 米白宣纸 | 米白 | `#F5F5DC` | 背景、留白、纸质感 |

辅助色（视具体类别使用）:

- 五行金 `#E6BE8A` (古铜) / 木 `#3CB371` (松针绿) / 水 `#4682B4` (青黛蓝) / 火 `#FF4500` (赤焰) / 土 `#8B4513` (赭石黄)
- 邪道紫 `#4B0082` / 神秘蓝 `#191970` / 血煞红 `#8B0000`

### 字体规范（如需绘制文字）

- **标题**: 方正清刻本悦宋 / 思源宋体 Bold
- **正文**: 思源宋体 Regular
- **数值**: 思源宋体 Medium
- 图标内一般**不嵌入文字**，文字由代码层叠加

## 命名规范

### 文件命名

- 全部使用 `snake_case`（小写下划线）
- 模式：`[类别]_[名称]_[变体].png`
- 示例：
  - `realm_icon_lianqi_early.png`
  - `element_icon_fire_active.png`
  - `buff_icon_qi_regen.png`
  - `portrait_yunzhonghe_default.png`
  - `bg_main_menu.png`

### 路径约定

| 类别 | 输出目录 |
|------|---------|
| 境界图标 | `assets/ui/realm_icons/` |
| 五行 / 状态图标 | `assets/ui/element_icons/` , `assets/ui/status_icons/` |
| Buff/Debuff | `assets/ui/buff_icons/` |
| 武学 / 天赋 | `assets/ui/skill_icons/` , `assets/ui/talent_icons/` |
| 系统 / 任务 | `assets/ui/system_icons/` |
| 立绘 | `assets/portraits/protagonist/`, `assets/portraits/allies/`, `assets/portraits/enemies/` |
| 背景 | `assets/backgrounds/` |
| 边框 / 装饰 | `assets/ui/frames/`, `assets/ui/decorations/` |
| 物品 | `assets/ui/item_icons/` |

## 输出格式规范

| 资源类型 | 推荐尺寸 | 格式 | 透明背景 | 备注 |
|---------|---------|------|---------|------|
| 小图标（buff/状态） | 64×64px | PNG-32 | 是 | 实际渲染 32×32，2x 备份 |
| 中图标（武学/物品） | 128×128px | PNG-32 | 是 | 实际渲染 64×64，2x 备份 |
| 大图标（境界/系统） | 256×256px | PNG-32 | 是 | 视场景缩放 |
| 角色立绘（半身） | 800×1200px | PNG-32 | 是 | 对话框使用 |
| 角色立绘（全身） | 1200×2000px | PNG-32 | 是 | 角色面板使用 |
| 场景背景 | 1920×1080px (16:9) | JPG / PNG | 否 | 含 4K 备份 3840×2160 |
| 边框 / 装饰 | 9-Slice 适配 | PNG-32 | 是 | 标注九宫格切片点 |

## 提示词通用模板

每条资源条目包含以下字段：

```
### [资源序号]. [中文名称] ([英文蛇形名])

- **文件名**: `xxx_xxx.png`
- **尺寸**: WxH px
- **路径**: `assets/.../`
- **格式**: PNG-32 透明背景
- **优先级**: P0 / P1 / P2
- **引用文档**: design/ux/xxx.md, design/art/xxx.md
- **状态变体**: 默认 / 激活 / 禁用 (列出所有变体)

**生成提示词**:
> [完整中文 prompt，可直接喂给 AI 绘图工具]

**关键词**:
- 风格: 水墨写意, 工笔重彩...
- 元素: 灵气球, 道纹, 卷云纹...
- 氛围: 空灵, 玄妙, 庄严...

**避免（负面提示）**:
- 现代元素（手机、汽车、机械等）
- 西方魔幻风格（精灵、矮人、龙堡）
- 卡通低龄化、Q 版（除非明确指定）
- 文字水印、签名
- 失真、扭曲、多余手指
```

## 通用负面提示词（所有资源默认排除）

```
现代元素, 现代服装, 西方魔幻, 西方城堡, 精灵种族, 矮人种族, 兽人种族,
科幻元素, 机甲, 武器枪械, 卡通低龄, Q版萌系（除非指定）, 美式漫画风,
日系萌系（除非指定）, 文字水印, 签名, logo, 手机APP界面, 现代UI按钮,
低分辨率, 模糊, 失真, 多余手指, 比例错误, 解剖错误, 重复脸部
```

## 通用正向风格补强（适合大部分条目）

```
中国水墨画风格, 工笔与写意结合, 仙侠玄幻氛围, 留白构图, 笔触苍劲,
古典韵味, 道教元素, 卷云纹饰, 灵气流动, 高细节, 4K 画质, 概念艺术,
中国传统色彩, 宣纸质感
```

## 引用设计文档

本清单基于以下已完成的设计文档生成：

- [design/art/art-bible.md](../../../design/art/art-bible.md) — 美术圣经
- [design/art/character-visual-profiles.md](../../../design/art/character-visual-profiles.md) — 角色视觉档案
- [design/ux/main-menu.md](../../../design/ux/main-menu.md) — 主菜单 UX
- [design/ux/hud.md](../../../design/ux/hud.md) — HUD 设计
- [design/ux/character-panel.md](../../../design/ux/character-panel.md) — 角色面板
- [design/ux/inventory-panel.md](../../../design/ux/inventory-panel.md) — 背包面板
- [design/ux/encounter-ui.md](../../../design/ux/encounter-ui.md) — 仙缘 UI
- [design/gdd/cultivation-system.md](../../../design/gdd/cultivation-system.md) — 修炼系统
- [design/gdd/combat-system.md](../../../design/gdd/combat-system.md) — 战斗系统
- [design/gdd/five-elements-system.md](../../../design/gdd/five-elements-system.md) — 五行系统

## 验收流程

1. 美术按本清单生成资源 → 提交到 `assets/raw/ui/[batch-id]/`
2. Art Director 评审风格一致性 → 通过后转入正式目录
3. UI 程序集成到 `Theme` 资源 → 替换占位符
4. QA 在游戏内截图验证 → 留档至 `production/qa/evidence/ui-assets/`

---

**清单版本**: v1.0  
**生成日期**: 2026-05-23  
**维护者**: Art Director + UX Designer
