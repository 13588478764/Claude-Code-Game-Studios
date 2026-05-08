# 第一幕：青云镇危机 — 主线剧本

## 文档状态
- **版本**: 1.0
- **创建日期**: 2026-05-02
- **负责人**: 叙事总监
- **审核状态**: Draft
- **对应游戏时长**: 0-10小时
- **境界进展**: 凡人 → 炼气初期 → 炼气后期

---

## 概述

青云镇危机是第一幕的核心故事弧，讲述玩家从凡人成长为修真者，并解决青云镇魔修威胁的完整叙事体验。本故事独立完整，同时为飞升之谜埋下伏笔。

**关键事件流程**：
1. 开场：初入修真界（0-1小时）
2. 启蒙：拜师云中鹤（1-3小时）
3. 危机：魔修现身（3-5小时）
4. 高潮：血祭阵决战（5-7小时）
5. 转折：上古遗迹（7-8小时）
6. 结局：青云镇重生（8-10小时）

---

## 事件一：开场 — 初入修真界

**游戏时长**：0-1小时
**场景**：青云镇
**玩家状态**：凡人
**目标**：引入世界观，触发修真天赋，建立初始动机

### 1.1 开场过场

**场景描述**：
清晨的青云镇，炊烟袅袅。玩家角色（可自定义姓名）在镇上的家中醒来。今天是青云镇一年一度的春集市。

**环境叙事点**：
- 桌上的旧剑（父亲遗物，后续伏笔）
- 墙上的九州地图（未解锁区域标注"未知之地"）
- 窗外的叫卖声

### 1.2 集市探索

**可交互NPC**：

**NPC: 王铁匠**
```json
{
  "dialogue_id": "MARKET_WANG_001",
  "speaker": "wang_tiejiang",
  "text": "哟，{player_name}，今天起得早啊！来瞧瞧我新打的菜刀？",
  "choices": [
    {
      "id": "chat",
      "text": "王叔，最近镇上有什么新鲜事吗？",
      "effects": [
        {"type": "quest_trigger", "target": "rumor_mill", "value": true}
      ],
      "next_node": "MARKET_WANG_002"
    },
    {
      "id": "buy",
      "text": "看看就好，我先去转转",
      "effects": [],
      "next_node": "MARKET_FREE"
    }
  ]
}
```

**NPC: 李婆婆**
```json
{
  "dialogue_id": "MARKET_LI_001",
  "speaker": "li_popo",
  "text": "小{name}啊，最近夜里老听见山上有奇怪的声音，你可别往那边跑。",
  "choices": [
    {
      "id": "concerned",
      "text": "李婆婆，是什么样的声音？",
      "effects": [
        {"type": "quest_trigger", "target": "mountain_rumor", "value": true}
      ],
      "next_node": "MARKET_LI_002"
    },
    {
      "id": "dismiss",
      "text": "婆婆多虑了，可能是野兽",
      "effects": [],
      "next_node": "MARKET_FREE"
    }
  ]
}
```

### 1.3 异象触发

**触发条件**：探索集市后5分钟
**事件**：天空突然出现诡异的紫色光芒，持续3秒后消失。镇民议论纷纷。

**过场对话**：
```
旁白：天空中出现了一道紫色的光芒，转瞬即逝。
      但你知道，那绝不是普通的自然现象。
      腰间父亲的旧剑似乎微微震动了一下...
```

**选择点**：
- 调查光芒方向（北方山林）→ 推进主线
- 先回镇上问问其他人 → 获得额外信息

### 1.4 事件结算

**如果选择调查**：
- 进入事件二：启蒙
- 在山林边缘遇到云中鹤

**如果选择回镇**：
- 可与3个NPC对话获得额外线索
- 最终仍需前往山林（夜里镇上出现异常）

---

## 事件二：启蒙 — 拜师云中鹤

**游戏时长**：1-3小时
**场景**：青云镇北方山林
**玩家状态**：凡人 → 炼气初期
**目标**：认识修真世界，获得第一本功法，开始修炼

### 2.1 初遇云中鹤

**场景描述**：
山林边缘，一名白衣中年男子正在观察地面的灵力痕迹。他手持长剑，气质洒脱。

```json
{
  "dialogue_id": "MEET_YUN_001",
  "speaker": "yunzhonghe",
  "text": "嗯？这灵气波动...不对，一个凡人怎么会有这种体质？",
  "next_node": "MEET_YUN_002"
}
```

```json
{
  "dialogue_id": "MEET_YUN_002",
  "speaker": "yunzhonghe",
  "text": "年轻人，你叫什么名字？可曾接触过修炼？",
  "choices": [
    {
      "id": "curious",
      "text": "晚辈{name}，从未修炼过。前辈，刚才天上的紫光是？",
      "effects": [
        {"type": "relationship_change", "target": "yunzhonghe", "value": 5}
      ],
      "next_node": "MEET_YUN_003A"
    },
    {
      "id": "defensive",
      "text": "你是谁？为什么跟踪我？",
      "effects": [
        {"type": "relationship_change", "target": "yunzhonghe", "value": 0}
      ],
      "next_node": "MEET_YUN_003B"
    }
  ]
}
```

### 2.2 修真启蒙对话

```json
{
  "dialogue_id": "INTRO_CULTIVATION_001",
  "speaker": "yunzhonghe",
  "text": "这世界远比你想象的广阔。九州修真界，九大区域，无数修士在追求长生大道。而刚才那道紫光...是灵气暴走的迹象。",
  "next_node": "INTRO_CULTIVATION_002"
}
```

```json
{
  "dialogue_id": "INTRO_CULTIVATION_002",
  "speaker": "yunzhonghe",
  "text": "你身上有罕见的'剑骨'体质，是万中无一的修炼天才。可惜生在这灵气稀薄的中原腹地，否则早被大宗门抢着收了。",
  "choices": [
    {
      "id": "accept_fate",
      "text": "前辈的意思是...我可以修炼？",
      "effects": [
        {"type": "relationship_change", "target": "yunzhonghe", "value": 5},
        {"type": "quest_trigger", "target": "first_cultivation", "value": true}
      ],
      "next_node": "INTRO_CULTIVATION_003A"
    },
    {
      "id": "hesitate",
      "text": "修炼太危险了，我只是个普通人",
      "effects": [
        {"type": "relationship_change", "target": "yunzhonghe", "value": -5}
      ],
      "next_node": "INTRO_CULTIVATION_003B"
    }
  ]
}
```

### 2.3 传授功法

**选择A（愿意修炼）**：
```
云中鹤："好！有胆识。这本《基础剑诀》你先练着，我观察几日便知你是否真的合适。"
获得物品：基础剑诀（黄阶上品功法）
解锁系统：修炼教程
```

**选择B（犹豫）**：
```
云中鹤："也罢，修炼一事确实不能强求。但这灵气异动绝非小事...这样吧，你拿着这本册子，若改变主意了再找我。"
获得物品：基础剑诀（黄阶上品功法）
云中鹤关系值：-5
```

### 2.4 修炼教程

**游戏机制**：
1. 吸收灵气（点击灵气点）
2. 引导灵气运行（QTE小游戏）
3. 突破至炼气初期
4. 基础战斗教学

**突破后对话**：
```json
{
  "dialogue_id": "BREAKTHROUGH_001",
  "speaker": "yunzhonghe",
  "text": "不错，三天便到了炼气初期，比我预期的还快。但你记住，修炼之路漫长，切不可急躁。",
  "next_node": "BREAKTHROUGH_002"
}
```

```json
{
  "dialogue_id": "BREAKTHROUGH_002",
  "speaker": "yunzhonghe",
  "text": "这种灵气波动...似曾相识。三百年前飞升之战后，就再没见过这种波动。罢了，现在不是想这些的时候。",
  "effects": [
    {"type": "quest_trigger", "target": "foreshadowing_001", "value": true}
  ]
}
```

### 2.5 事件结算

**玩家状态变更**：
- 境界：凡人 → 炼气初期（Lv1）
- 获得：基础剑诀
- 云中鹤关系：+10（选择A）或 +0（选择B）
- 解锁：修炼系统、战斗系统

**推进至事件三**：
- 回到青云镇，发现异常情况加剧

---

## 事件三：危机 — 魔修现身

**游戏时长**：3-5小时
**场景**：青云镇 → 镇外血祭阵外围
**玩家状态**：炼气初期
**目标**：发现魔修阴谋，组建调查小队，收集线索

### 3.1 镇内异变

**场景描述**：
回到青云镇，发现数名村民失踪，镇上人心惶惶。铁匠铺前聚集了讨论的镇民。

**关键NPC**：
- 村长：发布寻人任务
- 铁无双（丐帮弟子）：路过调查

### 3.2 结识铁无双

```json
{
  "dialogue_id": "MEET_TIE_001",
  "speaker": "tiewushuang",
  "text": "这位小兄弟，看你面相不凡啊。我是丐帮铁无双，路过此地，听闻镇上出了怪事。",
  "choices": [
    {
      "id": "ally",
      "text": "我是云中鹤前辈的弟子，正想调查此事",
      "effects": [
        {"type": "relationship_change", "target": "tiewushuang", "value": 10},
        {"type": "quest_trigger", "target": "investigate_team", "value": true}
      ],
      "next_node": "MEET_TIE_002A"
    },
    {
      "id": "solo",
      "text": "此事重大，我先自己探查一番",
      "effects": [
        {"type": "relationship_change", "target": "tiewushuang", "value": 0}
      ],
      "next_node": "MEET_TIE_002B"
    }
  ]
}
```

### 3.3 线索收集

**三个调查点**：

1. **失踪村民最后出现地点**（后山小路）
   - 发现紫色灵气残留
   - 获得线索：地面有血迹

2. **镇外废弃庙宇**
   - 发现血祭阵图纸碎片
   - 需要炼气初期灵气感知能力解锁

3. **山中樵夫家**
   - 樵夫声称看到黑衣人
   - 获得线索：黑衣人往北面山谷去了

### 3.4 选择点：是否求援

**云中鹤提示**：
```
云中鹤："此事涉及筑基期魔修，单凭我们恐怕力有不逮。是否向少林或武当求援？"
```

**选择A：求援正道**
```json
{
  "dialogue_id": "CHOICE_HELP_001",
  "speaker": "yunzhonghe",
  "text": "我这就传书少林寺。不过正道救援需要时间，魔修可能趁机逃脱。",
  "effects": [
    {"type": "dao_heart_change", "target": "dao_heart", "value": 10},
    {"type": "quest_trigger", "target": "sect_backup", "value": true}
  ]
}
```

**选择B：自行解决**
```json
{
  "dialogue_id": "CHOICE_SOLO_001",
  "speaker": "yunzhonghe",
  "text": "有胆识。但魔修实力不容小觑，需从长计议。",
  "effects": [
    {"type": "dao_heart_change", "target": "dao_heart", "value": 0}
  ]
}
```

### 3.5 事件结算

**线索汇总**：
- 魔修在山谷建立血祭阵
- 目的：吸收凡人精血突破境界
- 预计三日内完成仪式

**队伍组建**：
- 云中鹤（元婴期，但旧伤未愈）
- 铁无双（筑基后期体修）
- 玩家（炼气初期）
- [可选] 正道援军（如果选择求援）

**推进至事件四**：
- 准备突袭血祭阵

---

## 事件四：高潮 — 血祭阵决战

**游戏时长**：5-7小时
**场景**：山谷血祭阵
**玩家状态**：炼气初期 → 炼气中期
**目标**：击败筑基期魔修，解救被困村民

### 4.1 突袭准备

**场景描述**：
山谷中紫气弥漫，一座血色法阵正在运转。阵眼处一名黑衣修士正在吸收灵气，旁边铁笼关着失踪的村民。

### 4.2 Boss战前对话

```json
{
  "dialogue_id": "BOSS_PRE_001",
  "speaker": "mob_xiushi",
  "text": "哈哈哈，来得正好！老夫的血祭阵正缺几滴修士精血！你们一个都别想走！",
  "next_node": "BOSS_PRE_002"
}
```

```json
{
  "dialogue_id": "BOSS_PRE_002",
  "speaker": "yunzhonghe",
  "text": "血炼之术，果然是你。{player_name}，护好村民，我来缠住他！",
  "effects": [
    {"type": "quest_trigger", "target": "boss_battle_001", "value": true}
  ]
}
```

### 4.3 Boss战机制

**战斗阶段**：
1. **阶段一**：云中鹤吸引Boss注意，玩家清理小怪（血祭阵守卫）
2. **阶段二**：破坏血祭阵阵眼（需要灵气攻击）
3. **阶段三**：Boss暴怒，云中鹤受伤，玩家独自对战

**战斗胜利条件**：
- 击败Boss或击退
- 解救所有村民

**战斗中云中鹤展现元婴期实力**，但受旧伤影响无法发挥全力。

### 4.4 战后处置选择

```json
{
  "dialogue_id": "BOSS_POST_001",
  "speaker": "mob_xiushi",
  "text": "咳...你们...别得意。他...不会放过你们的...",
  "choices": [
    {
      "id": "kill",
      "text": "邪修当诛，留你不得！",
      "effects": [
        {"type": "dao_heart_change", "target": "dao_heart", "value": -5},
        {"type": "item_give", "target": "blood_refinement_manual", "value": 1}
      ],
      "next_node": "BOSS_POST_KILL"
    },
    {
      "id": "capture",
      "text": "将你交给正道审判",
      "effects": [
        {"type": "dao_heart_change", "target": "dao_heart", "value": 10},
        {"type": "reputation_change", "target": "righteous", "value": 20}
      ],
      "next_node": "BOSS_POST_CAPTURE"
    },
    {
      "id": "release",
      "text": "饶你一命，但需答应我一件事",
      "effects": [
        {"type": "dao_heart_change", "target": "dao_heart", "value": 0}
      ],
      "next_node": "BOSS_POST_RELEASE",
      "condition": {"type": "relationship_check", "target": "yunzhonghe", "operator": ">=", "value": 20}
    }
  ]
}
```

### 4.5 事件结算

**奖励**：
- 玩家经验值 → 炼气中期
- 根据选择获得不同奖励
- 村民获救，青云镇声望+50

**推进至事件五**：
- 血祭阵被破坏后，地下露出上古遗迹入口

---

## 事件五：转折 — 上古遗迹

**游戏时长**：7-8小时
**场景**：血祭阵下方上古遗迹
**玩家状态**：炼气中期
**目标**：发现飞升之战秘密，触发核心谜团伏笔

### 5.1 遗迹入口

**场景描述**：
血祭阵被破坏后，地面裂开，露出一座古老的石门。门上刻着繁复的符文，散发着微弱的光芒。

```json
{
  "dialogue_id": "RUIN_ENTRY_001",
  "speaker": "yunzhonghe",
  "text": "这个符文...是300年前的封印。没想到这里竟藏着上古遗迹。{player_name}，跟紧我。",
  "next_node": "RUIN_ENTRY_002"
}
```

### 5.2 遗迹探索

**遗迹结构**：
1. **前厅**：破损的雕像、壁画
2. **通道**：触发机关，需要解谜
3. **主室**：记忆水晶台

**环境叙事点**：
- 壁画描绘了上古修士飞升的场景
- 地面上有大战留下的剑痕
- 角落里散落着破碎的法宝

### 5.3 记忆水晶

```json
{
  "dialogue_id": "MEMORY_CRYSTAL_001",
  "speaker": "system",
  "text": "你触碰了记忆水晶，一股庞大的信息涌入脑海...",
  "next_node": "MEMORY_CRYSTAL_002"
}
```

**过场动画：飞升之战记忆碎片**
```
画面1：数十名化神期修士在飞升台前集结
画面2：天空中降下雷霆，封印阵法启动
画面3：一名神秘黑衣人主持封印仪式
画面4：飞升通道缓缓关闭，修士们绝望呼喊
画面5：碎片结束，只留下一个模糊的符文印记
```

### 5.4 云中鹤的反应

```json
{
  "dialogue_id": "YUN_REACTION_001",
  "speaker": "yunzhonghe",
  "text": "果然...是那个封印。三百年了，这个符文我从未忘记。",
  "next_node": "YUN_REACTION_002"
}
```

```json
{
  "dialogue_id": "YUN_REACTION_002",
  "speaker": "yunzhonghe",
  "text": "{player_name}，看来你与那场战争有缘。但现在还不是告诉你一切的时候。记住，飞升之路并未断绝，只是被人刻意封锁。",
  "effects": [
    {"type": "quest_trigger", "target": "ascension_mystery", "value": true},
    {"type": "dao_heart_change", "target": "dao_heart", "value": 5}
  ]
}
```

### 5.5 遗迹奖励

**获得物品**：
- 基础剑诀进阶版（玄阶下品）
- 上古符文拓片（关键道具）
- 灵气结晶×5（修炼资源）

**解锁系统**：
- 主线任务：飞升之谜
- 收集任务：上古符文

**推进至事件六**：
- 离开遗迹，回到青云镇

---

## 事件六：结局 — 青云镇重生

**游戏时长**：8-10小时
**场景**：青云镇
**玩家状态**：炼气中期 → 炼气后期
**目标**：完成青云镇危机故事弧，展示结局分支，展望九州

### 6.1 凯旋归来

**场景描述**：
回到青云镇，村民们夹道欢迎。镇长亲自出迎，感谢玩家和团队的贡献。

```json
{
  "dialogue_id": "VICTORY_001",
  "speaker": "town_leader",
  "text": "{player_name}，你是青云镇的大英雄！若不是你，我们全镇都要遭殃。",
  "next_node": "VICTORY_002"
}
```

### 6.2 伙伴告别

**铁无双对话**：
```json
{
  "dialogue_id": "TIE_FAREWELL_001",
  "speaker": "tiewushuang",
  "text": "兄弟，这一战痛快！我铁无双认你这个兄弟了！以后有事，到丐帮分舵找我！",
  "effects": [
    {"type": "relationship_change", "target": "tiewushuang", "value": 30}
  ]
}
```

**云中鹤对话**：
```json
{
  "dialogue_id": "YUN_FAREWELL_001",
  "speaker": "yunzhonghe",
  "text": "你进步神速，基础我已没什么可教的了。但记住，修炼之路，道心比天赋更重要。",
  "next_node": "YUN_FAREWELL_002"
}
```

```json
{
  "dialogue_id": "YUN_FAREWELL_002",
  "speaker": "yunzhonghe",
  "text": "我的时间不多了...但在离开之前，有些话必须告诉你。你的体质非同寻常，或许...你就是那个人。",
  "effects": [
    {"type": "quest_trigger", "target": "yunzhonghe_mystery", "value": true}
  ]
}
```

### 6.3 结局分支

**根据玩家之前的选择，触发不同结局路线**：

#### 正道路线
```
条件：道心值 > 20 且 选择求援正道或上交魔修

云中鹤："你的道心坚定，正道才是你的归宿。带着这封推荐信，去少林或武当吧。"

获得：少林/武当推荐信
解锁：正道宗门任务线
```

#### 中立路线
```
条件：道心值 -20 到 20

云中鹤："你不愿被任何束缚，也罢。这枚青霜剑碎片是上古遗物，或许你能修复它。"

获得：青霜剑碎片（可修复武器）
解锁：自由探索路线
```

#### 魔道路线
```
条件：道心值 < -20 且 选择击杀魔修或放走

云中鹤："你选择了力量的代价。这本事血炼秘籍，希望你能驾驭它。"

获得：血炼秘籍（魔道功法）
解锁：魔道势力接触事件
```

### 6.4 境界突破

**突破至炼气后期**：
- 通过遗迹探索获得灵气
- 完成突破任务（QTE）
- 玩家境界：炼气中期 → 炼气后期（Lv22）

### 6.5 结束过场

**旁白**：
```
"青云镇的危机终于结束了。
但你知道，这只是一个开始。

九州修真界，八大区域仍在远方等待。
飞升之谜的真相，隐藏在历史深处。
而你，将踏上属于自己的修真之路。"
```

**UI展示**：
- 九州地图出现，标注其他8个区域（灰色，未解锁）
- 每个区域显示简短描述（远方传闻系统）
- 当前区域：中原腹地（已解锁）
- 境界上限：炼气后期

### 6.6 MVP结束语

```
"青云镇的危机只是开始。更大的秘密，隐藏在九州修真界的深处..."
```

**第一幕完成标志**：
- 玩家境界：炼气后期（Lv22）
- 获得：主线任务"飞升之谜"
- 解锁：奇遇系统
- 解锁：角色关系系统

---

## 附录：关键数据追踪

### 本幕重要变量

| 变量名 | 类型 | 说明 | 初始值 |
|--------|------|------|--------|
| `dao_heart` | int | 道心值（-100到100） | 0 |
| `yunzhonghe_relation` | int | 云中鹤关系值 | 0 |
| `tiewushuang_relation` | int | 铁无双关系值 | 0 |
| `player_realm` | int | 玩家境界 | 0（凡人） |
| `ascension_mystery_unlocked` | bool | 飞升之谜解锁 | false |
| `ending_route` | string | 结局路线 | "neutral" |

### 关键物品追踪

| 物品ID | 名称 | 获取条件 | 用途 |
|--------|------|----------|------|
| `basic_sword_manual` | 基础剑诀 | 事件二 | 初始功法 |
| `blood_refinement_manual` | 血炼秘籍 | 事件四选择击杀 | 魔道功法 |
| `green_frost_shard` | 青霜剑碎片 | 事件六中立路线 | 可修复武器 |
| `sect_recommendation` | 宗门推荐信 | 事件六正道路线 | 解锁宗门 |
| `ancient_rune_rubbing` | 上古符文拓片 | 事件五 | 收集任务 |

### 本幕解锁系统

- 修炼系统
- 战斗系统
- 奇遇系统
- 角色关系系统
- 主线任务系统

