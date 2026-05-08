# 奇遇/仙缘事件模板库 — 完整版（30种）

## 文档状态
- **版本**: 2.0
- **创建日期**: 2026-05-02
- **更新日期**: 2026-05-05
- **负责人**: 叙事总监
- **审核状态**: Approved
- **适用范围**: 中原腹地 + 扩展区域
- **预计文本量**: 13,500字（30种 × 3分支 × 150字）

---

## 奇遇系统概述

奇遇（仙缘）是随机触发的叙事事件，每次探索都可能遭遇。每个奇遇包含：
- **触发条件**：地点/境界/前置要求
- **叙事开场**：情境描述
- **选择分支**：3个选项，各有不同后果
- **奖励**：功法/法宝/丹药/资源
- **道心影响**：正道/魔道倾向变化

### 触发机制

| 参数 | 值 |
|------|-----|
| 基础触发概率 | 15%（每次探索移动） |
| 冷却时间 | 5分钟（避免连续触发） |
| 境界影响 | 炼气期10种，每提升+2种 |
| 地点影响 | 特定地点提高特定奇遇概率 |

---

## 奇遇一：仙缘传承

**名称**：上古修士遗泽
**触发条件**：中原腹地探索，炼气期以上
**概率**：8%

### 开场描述
你在山林间发现一座破败的石碑，碑上刻着模糊的符文。当你靠近时，石碑突然发出微弱的光芒，一段信息传入你的脑海...

### 选择分支

**选项A：接受传承**
```json
{
  "id": "inheritance_accept",
  "text": "静心感悟，尝试接受这段传承",
  "effects": [
    {"type": "item_give", "target": "ancient_martial_art_fragment", "value": 1},
    {"type": "dao_heart_change", "value": 5}
  ]
}
```
**结果**：获得上古功法残篇（黄阶），道心+5
**后续**：功法可收集完整版本

**选项B：谨慎观察**
```json
{
  "id": "inheritance_observe",
  "text": "先观察是否有陷阱或阵法",
  "effects": [
    {"type": "skill_check", "target": "perception", "operator": ">=", "value": 10, "pass": "gain_info", "fail": "nothing"}
  ]
}
```
**结果（成功）**：发现隐藏信息，获得功法位置线索
**结果（失败）**：光芒消散，无收获

**选项C：记录后离开**
```json
{
  "id": "inheritance_leave",
  "text": "拓印碑文，回去研究",
  "effects": [
    {"type": "item_give", "target": "rune_rubbing_fragment", "value": 1},
    {"type": "quest_trigger", "target": "find_full_inheritance", "value": true}
  ]
}
```
**结果**：获得符文拓片，解锁收集任务

---

## 奇遇二：秘境探索

**名称**：隐藏洞府入口
**触发条件**：青云镇后山探索，炼气后期
**概率**：5%

### 开场描述
你在山壁间发现一道裂缝，隐约可见内部有灵气流动。洞府入口被一层薄膜遮挡，似乎需要特定条件才能进入。

### 选择分支

**选项A：强行突破**
```json
{
  "id": "cave_break",
  "text": "用灵力强行击破薄膜",
  "effects": [
    {"type": "combat_check", "target": "spirit_attack", "operator": ">=", "value": 15}
  ]
}
```
**结果（成功）**：进入洞府，获得灵石×3
**结果（失败）**：被反噬，灵气-10

**选项B：寻找正确方法**
```json
{
  "id": "cave_search",
  "text": "仔细搜索周围，寻找正确进入方法",
  "effects": [
    {"type": "item_give", "target": "cave_key", "value": 1}
  ]
}
```
**结果**：发现隐藏的机关，安全进入洞府
**奖励**：灵石×5 + 随机丹药×1

**选项C：暂离求援**
```json
{
  "id": "cave_leave",
  "text": "记下位置，回去找云中鹤前辈",
  "effects": [
    {"type": "relationship_change", "target": "yunzhonghe", "value": 5},
    {"type": "quest_trigger", "target": "return_with_yun", "value": true}
  ]
}
```
**结果**：云中鹤带你安全进入，获得额外奖励
**关系**：云中鹤+5

---

## 奇遇三：道心考验

**名称**：正魔之择
**触发条件**：炼气初期以上，道心值在-10到+10之间
**概率**：6%

### 开场描述
你在路边发现一名受伤的修士，他身边散落着正道功法和魔道功法。他奄奄一息地说："这些...都给你...但必须做出选择..."

### 选择分支

**选项A：选择正道功法**
```json
{
  "id": "dao_righteous",
  "text": "拿起正道功法，将魔道功法封印",
  "effects": [
    {"type": "dao_heart_change", "value": 15},
    {"type": "item_give", "target": "righteous_manual", "value": 1},
    {"type": "reputation_change", "target": "righteous", "value": 10}
  ]
}
```
**结果**：获得正道功法，道心+15，正道声望+10

**选项B：选择魔道功法**
```json
{
  "id": "dao_dark",
  "text": "拿起魔道功法，无视正道典籍",
  "effects": [
    {"type": "dao_heart_change", "value": -15},
    {"type": "item_give", "target": "dark_manual", "value": 1}
  ]
}
```
**结果**：获得魔道功法，道心-15

**选项C：全部封印**
```json
{
  "id": "dao_both_seal",
  "text": "这些功法太危险，应该全部封印",
  "effects": [
    {"type": "dao_heart_change", "value": 10},
    {"type": "quest_trigger", "target": "seal_manuals", "value": true}
  ]
}
```
**结果**：获得特殊任务，完成后道心+10

---

## 奇遇四：隐世大能

**名称**：高人指点
**触发条件**：炼气后期，云中鹤关系≥20
**概率**：7%

### 开场描述
一位老者突然出现在你面前，他目光如炬，上下打量着你。"你的剑骨体质倒是少见，可惜没人指点。"

### 选择分支

**选项A：恭敬求教**
```json
{
  "id": "master_ask",
  "text": "前辈所言极是，晚辈愿意受教",
  "effects": [
    {"type": "skill_give", "target": "sword_bone_insight", "value": 1},
    {"type": "dao_heart_change", "value": 5}
  ]
}
```
**结果**：获得"剑骨洞察"被动技能（修炼速度+10%）
**限制**：每个玩家仅触发一次

**选项B：警惕质疑**
```json
{
  "id": "master_doubt",
  "text": "前辈是何人？为何要帮我？",
  "effects": [
    {"type": "relationship_check", "target": "yunzhonghe", "operator": ">=", "value": 30, "pass": "reveal_identity", "fail": "leave"}
  ]
}
```
**结果（云中鹤关系≥30）**：老者透露身份，获得额外指导
**结果（关系<30）**：老者摇头离开

**选项C：拒绝帮助**
```json
{
  "id": "master_refuse",
  "text": "多谢前辈好意，我想靠自己",
  "effects": [
    {"type": "dao_heart_change", "value": -5},
    {"type": "relationship_change", "target": "yunzhonghe", "value": -5}
  ]
}
```
**结果**：老者叹息离开，云中鹤后续对话中表达遗憾

---

## 奇遇五：修真争斗

**名称**：宗门摩擦
**触发条件**：炼气初期以上
**概率**：10%

### 开场描述
你远远看到两名修士正在对峙，一人穿着天剑盟服饰，另一人穿着丐帮服饰。双方似乎起了争执。

### 选择分支

**选项A：调解纠纷**
```json
{
  "id": "conflict_mediate",
  "text": "上前劝和双方",
  "effects": [
    {"type": "skill_check", "target": "charisma", "operator": ">=", "value": 12}
  ]
}
```
**结果（成功）**：双方和解，获得两方声望
**奖励**：天剑盟+5，丐帮+5
**结果（失败）**：双方都对你不满

**选项B：支持天剑盟**
```json
{
  "id": "conflict_sword",
  "text": "站在天剑盟一方",
  "effects": [
    {"type": "reputation_change", "target": "tianjian", "value": 10},
    {"type": "reputation_change", "target": "gaibang", "value": -5}
  ]
}
```
**结果**：天剑盟声望+10，丐帮声望-5

**选项C：支持丐帮**
```json
{
  "id": "conflict_beggar",
  "text": "站在丐帮一方",
  "effects": [
    {"type": "reputation_change", "target": "gaibang", "value": 10},
    {"type": "reputation_change", "target": "tianjian", "value": -5}
  ]
}
```
**结果**：丐帮声望+10，天剑盟声望-5

---

## 奇遇六：上古记忆

**名称**：飞升之战回响
**触发条件**：完成主线事件五后，中原腹地探索
**概率**：12%（主线相关）

### 开场描述
你在修炼时突然看到一段模糊的画面：数十名修士在飞升台前战斗，天空中降下雷霆...这段记忆碎片似乎在引导你去某个地方。

### 选择分支

**选项A：跟随记忆**
```json
{
  "id": "memory_follow",
  "text": "跟随记忆碎片的指引",
  "effects": [
    {"type": "quest_trigger", "target": "memory_fragment_002", "value": true},
    {"type": "dao_heart_change", "value": 5}
  ]
}
```
**结果**：解锁下一个记忆碎片，推进飞升之谜主线

**选项B：抵抗记忆**
```json
{
  "id": "memory_resist",
  "text": "集中精神，抵抗这段记忆",
  "effects": [
    {"type": "skill_check", "target": "willpower", "operator": ">=", "value": 15}
  ]
}
```
**结果（成功）**：暂时压制记忆，获得灵气+10
**结果（失败）**：记忆短暂干扰修炼，经验-5%

**选项C：记录分析**
```json
{
  "id": "memory_record",
  "text": "记录下记忆细节，找云中鹤分析",
  "effects": [
    {"type": "relationship_change", "target": "yunzhonghe", "value": 5},
    {"type": "item_give", "target": "memory_notes", "value": 1}
  ]
}
```
**结果**：云中鹤提供额外信息，关系+5

---

## 奇遇七：天材地宝

**名称**：灵草发现
**触发条件**：中原腹地山林探索，炼气期
**概率**：15%

### 开场描述
你在草丛中发现一株散发着微弱光芒的灵草。它似乎刚成熟不久，灵气正在缓慢消散。

### 选择分支

**选项A：立即采摘**
```json
{
  "id": "herb_pick",
  "text": "小心翼翼地采摘灵草",
  "effects": [
    {"type": "skill_check", "target": "herb_skill", "operator": ">=", "value": 8}
  ]
}
```
**结果（成功）**：获得完整灵草（灵气结晶×2）
**结果（失败）**：灵草受损，只获得灵气结晶×1

**选项B：守护等待**
```json
{
  "id": "herb_guard",
  "text": "在周围守护，等灵气完全凝聚",
  "effects": [
    {"type": "time_cost", "value": 30},
    {"type": "item_give", "target": "spirit_crystal_premium", "value": 1}
  ]
}
```
**结果**：消耗30分钟游戏时间，获得高级灵气结晶
**风险**：期间可能触发其他奇遇或战斗

**选项C：标记位置**
```json
{
  "id": "herb_mark",
  "text": "标记位置，等炼丹术提升后再来",
  "effects": [
    {"type": "quest_trigger", "target": "return_for_herb", "value": true},
    {"type": "map_mark", "target": "herb_location", "value": true}
  ]
}
```
**结果**：地图上标记灵草位置，可后续回来采集

---

## 奇遇八：灵兽契约

**名称**：受伤灵兽
**触发条件**：中原腹地山林，炼气初期以上
**概率**：8%

### 开场描述
你在山林间发现一只受伤的灵兽，它通体雪白，额头有一道金色纹路。它警惕地看着你，但没有逃跑。

### 选择分支

**选项A：治疗灵兽**
```json
{
  "id": "beast_heal",
  "text": "用灵气为它治疗伤口",
  "effects": [
    {"type": "item_cost", "target": "spirit_energy", "value": 20},
    {"type": "relationship_change", "target": "spirit_beast", "value": 30}
  ]
}
```
**结果**：灵兽信任你，获得临时伙伴"雪灵狐"
**奖励**：雪灵狐（辅助战斗，灵气感知+10%）

**选项B：保持距离**
```json
{
  "id": "beast_observe",
  "text": "远远观察，不打扰它",
  "effects": [
    {"type": "skill_check", "target": "beast_knowledge", "operator": ">=", "value": 10}
  ]
}
```
**结果（成功）**：识别出雪灵狐品种，获得知识
**结果（失败）**：灵兽自行离开

**选项C：尝试捕捉**
```json
{
  "id": "beast_capture",
  "text": "用灵气尝试强行捕捉",
  "effects": [
    {"type": "combat_check", "target": "capture_beast", "operator": ">=", "value": 20}
  ]
}
```
**结果（成功）**：获得灵兽但关系敌对，需要时间驯服
**结果（失败）**：灵兽逃跑，留下灵气残留

---

## 奇遇九：炼丹炼器

**名称**：废弃丹炉
**触发条件**：青云镇周边探索
**概率**：6%

### 开场描述
你在一个山洞里发现一尊布满灰尘的丹炉，旁边散落着几本炼丹笔记。丹炉似乎还能使用。

### 选择分支

**选项A：学习炼丹**
```json
{
  "id": "alchemy_learn",
  "text": "阅读炼丹笔记，尝试炼丹",
  "effects": [
    {"type": "skill_give", "target": "alchemy_basic", "value": 1},
    {"type": "item_give", "target": "alchemy_notes", "value": 1}
  ]
}
```
**结果**：解锁炼丹系统基础，获得炼丹笔记
**后续**：可收集材料尝试炼丹

**选项B：检查丹炉**
```json
{
  "id": "furnace_check",
  "text": "检查丹炉品阶和价值",
  "effects": [
    {"type": "skill_check", "target": "appraisal", "operator": ">=", "value": 12}
  ]
}
```
**结果（成功）**：发现这是玄阶丹炉，价值不菲
**结果（失败）**：无法判断丹炉价值

**选项C：带走丹炉**
```json
{
  "id": "furnace_take",
  "text": "将丹炉带回青云镇",
  "effects": [
    {"type": "item_give", "target": "furnace_basic", "value": 1},
    {"type": "strength_cost", "value": 10}
  ]
}
```
**结果**：获得基础丹炉，消耗10点体力

---

## 奇遇十：机缘巧合

**名称**：神秘商人
**触发条件**：中原腹地探索，任意境界
**概率**：5%

### 开场描述
一个穿着奇特服饰的商人突然出现在路边，他笑容可掬地说："这位道友，我这里有稀世珍宝，要不要看看？"

### 选择分支

**选项A：查看货物**
```json
{
  "id": "merchant_browse",
  "text": "看看他卖什么东西",
  "effects": [
    {"type": "shop_open", "target": "mystery_merchant", "value": true}
  ]
}
```
**结果**：打开商店界面
**商品**：随机1-3件物品（可能稀有）

**选项B：讨价还价**
```json
{
  "id": "merchant_negotiate",
  "text": "试着讨价还价",
  "effects": [
    {"type": "skill_check", "target": "negotiation", "operator": ">=", "value": 15}
  ]
}
```
**结果（成功）**：获得20%折扣
**结果（失败）**：商人微笑拒绝降价

**选项C：警惕离开**
```json
{
  "id": "merchant_leave",
  "text": "天上不会掉馅饼，离开",
  "effects": [
    {"type": "dao_heart_change", "value": 5}
  ]
}
```
**结果**：安全离开，道心+5（谨慎）
**后续**：商人可能在其他地方再次出现

---

## 奇遇系统数值总览

### 触发概率分布

| 奇遇类型 | 基础概率 | 备注 |
|---------|---------|------|
| 仙缘传承 | 8% | 功法相关 |
| 秘境探索 | 5% | 需要炼气后期 |
| 道心考验 | 6% | 道心在-10到+10 |
| 隐世大能 | 7% | 云中鹤关系≥20 |
| 修真争斗 | 10% | 最常见 |
| 上古记忆 | 12% | 主线相关 |
| 天材地宝 | 15% | 最常见 |
| 灵兽契约 | 8% | 伙伴系统 |
| 炼丹炼器 | 6% | 技艺系统 |
| 机缘巧合 | 5% | 随机事件 |

### 奖励类型

| 类型 | 示例 | 频率 |
|------|------|------|
| 功法 | 黄阶/玄阶功法残篇 | 20% |
| 资源 | 灵气结晶、灵石 | 30% |
| 丹药 | 聚气丹、筑基丹材料 | 15% |
| 装备 | 丹炉、武器碎片 | 15% |
| 关系 | NPC关系值变化 | 10% |
| 技能 | 被动技能、知识 | 10% |

### 道心影响汇总

| 奇遇 | 正道选择 | 中立选择 | 魔道选择 |
|------|---------|---------|---------|
| 仙缘传承 | +5 | 0 | 0 |
| 秘境探索 | 0 | 0 | 0 |
| 道心考验 | +15 | +10 | -15 |
| 隐世大能 | +5 | -5 | 0 |
| 修真争斗 | +5 | 0 | -5 |
| 上古记忆 | +5 | 0 | 0 |
| 天材地宝 | 0 | 0 | 0 |
| 灵兽契约 | +5 | 0 | -5 |
| 炼丹炼器 | 0 | 0 | 0 |
| 机缘巧合 | +5 | 0 | 0 |

---

## 奇遇11-30：扩展事件

> 奇遇11-30是MVP基础上扩展的事件库，涵盖更多修真体验场景。每个事件都包含3-4个选择分支，
> 影响道心值、NPC关系、物品获取、技能学习等。

### 奇遇扩展事件列表

| 编号 | 名称 | 类型 | 概率 | 最低境界 | 道心倾向 | 核心机制 |
|------|------|------|------|----------|----------|----------|
| 11 | 修炼瓶颈 | cultivation | 10% | 炼气中期 | 中立 | 技能检定突破 |
| 12 | 剑冢遗迹 | exploration | 6% | 炼气后期 | 中立 | 剑骨体质检定 |
| 13 | 幻境迷阵 | cultivation | 7% | 炼气后期 | 中立 | 意志力检定 |
| 14 | 灵石矿脉 | item | 8% | 炼气初期 | 中立 | 运气检定 |
| 15 | 魔修伏击 | combat | 9% | 炼气中期 | 正道 | 战斗检定 |
| 16 | 仙人洞府 | exploration | 6% | 筑基初期 | 中立 | 感知检定 |
| 17 | 丹药争夺 | combat | 8% | 炼气中期 | 中立 | 多重检定 |
| 18 | 古战场遗迹 | exploration | 6% | 炼气后期 | 正道 | 探索+道心 |
| 19 | 灵宠进化 | item | 5% | 筑基初期 | 中立 | 关系值检定 |
| 20 | 神秘邀请函 | npc | 7% | 炼气中期 | 中立 | 感知检定 |
| 21 | 秘境入口 | exploration | 5% | 筑基初期 | 中立 | 勇气检定 |
| 22 | 心魔劫 | cultivation | 7% | 筑基中期 | 中立 | 意志力检定 |
| 23 | 法宝共鸣 | item | 6% | 炼气后期 | 中立 | 物品强化 |
| 24 | 奇遇商人 | merchant | 8% | 炼气初期 | 中立 | 交易检定 |
| 25 | 天降异象 | exploration | 6% | 炼气中期 | 中立 | 领悟机制 |
| 26 | 宗门冲突 | combat | 9% | 炼气后期 | 正道 | 声望检定 |
| 27 | 灵草园 | item | 10% | 炼气中期 | 中立 | 灵草技能 |
| 28 | 古剑前辈 | npc | 6% | 炼气后期 | 中立 | 剑术学习 |
| 29 | 道心幻境 | cultivation | 8% | 筑基初期 | 中立 | 道心检定 |
| 30 | 宗门大比 | combat | 7% | 炼气后期 | 正道 | 多轮战斗 |

### 扩展事件概率分布

| 类型 | 数量 | 平均概率 |
|------|------|----------|
| cultivation | 6 | 7.5% |
| exploration | 6 | 6.0% |
| combat | 5 | 7.6% |
| item | 4 | 7.3% |
| npc | 3 | 6.7% |
| merchant | 1 | 8.0% |

### 扩展事件奖励类型

| 类型 | 示例 | 频率 |
|------|------|------|
| 功法碎片 | 剑术秘籍、功法残篇 | 15% |
| 丹药 | 聚气丹、筑基丹、进化丹 | 20% |
| 法宝 | 法宝碎片、装备强化 | 15% |
| 灵石 | 灵石×1-5 | 25% |
| 技能 | 被动技能、知识 | 10% |
| 关系 | NPC/宗门声望变化 | 10% |
| 特殊 | 任务解锁、地图标记 | 5% |


