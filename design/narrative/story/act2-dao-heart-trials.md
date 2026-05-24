# 第二幕：道心试炼 — 主线剧本

## 文档状态
- **版本**: 1.0
- **创建日期**: 2026-05-22
- **负责人**: 叙事总监
- **审核状态**: Draft
- **对应游戏时长**: 10-30小时
- **境界进展**: 炼气后期 → 筑基初期 → 筑基中期 → 筑基后期

---

## 概述

第二幕"道心试炼"承接青云镇危机后的成长期。玩家不再是初入修真界的懵懂少年，而是被云中鹤带回宗门的入室弟子。然而平静只是表象——师父旧伤复发时日无多、宗门大比暗流涌动、魔教大举入侵、慕容雪记忆觉醒……每一桩事件都把玩家推向更大的真相：**三百年前的飞升真相，与今日的危局，是同一道封印的两面**。

本幕的核心母题是**"道心"**——玩家在十一个事件中不断被迫做出价值判断：救一人还是救苍生？守正还是从恶？传承还是自立？这些选择通过"道心系统"量化（正道+/魔道-），决定第三幕的可达结局。

**核心冲突结构**：

| 层级 | 冲突 | 出场角色 |
|------|------|----------|
| 外部 | 魔教组织化入侵九州正道 | 萧寒夜、血无痕、赵无极 |
| 内部 | 师门期望 vs 个人道心 | 云中鹤、玄机真人、柳如烟 |
| 神秘 | 三百年前的封印真相 | 慕容雪、玄机真人、血无痕 |
| 情感 | 三组羁绊：师徒/同道/宿敌 | 全员 |

**关键事件流程**：

1. 青云镇归来（10-12小时，云中鹤旧伤复发）
2. 宗门大比公告（12-13小时，天剑盟使者抵达）
3. 初次试炼（13-15小时，vs 赵无极）
4. 魔教入侵（15-17小时，黑袍首领追杀云中鹤）
5. 上古秘境（17-20小时，清虚真人传承）
6. 道心抉择（20-22小时，萧寒夜 vs 柳如烟）
7. 慕容雪记忆（22-24小时，揭露血无痕与背叛者）
8. 古战场遗迹（24-26小时，封印衰弱征兆）
9. 云中鹤牺牲（26-27小时，剑骨碎片传承）
10. 筑基突破（27-29小时，三种路径选择）
11. 九州之门（29-30小时，第二幕终章/三分支决定）

---

## 角色出场地图

| 事件 | 云中鹤 | 柳如烟 | 萧寒夜 | 慕容雪 | 铁无双 | 玄机真人 | 血无痕 |
|------|:------:|:------:|:------:|:------:|:------:|:--------:|:------:|
| E1 归来 | ★主 |   |   | ○ | ○ |   |   |
| E2 大比 | ★ | ★主 |   |   | ○ |   |   |
| E3 试炼 |   | ★ |   |   | ★主 |   |   |
| E4 入侵 | ★主 | ★ | ◇暗 |   | ★ |   |   |
| E5 秘境 |   |   |   | ★主 | ★ | ★ |   |
| E6 抉择 |   | ★ | ★主 | ○ |   |   |   |
| E7 记忆 |   |   | ◇暗 | ★主 |   | ★ | ◇暗 |
| E8 战场 | ○ | ★ | ◇暗 | ★ | ★ | ★主 |   |
| E9 牺牲 | ★主结 | ★ | ◇追 | ★ | ★ |   | ◇追 |
| E10 突破 |   | ○ | ○ | ○ | ○ | ★主 |   |
| E11 终章 |   | ★ | ★ | ★ | ★ | ★ | ★主 |

> 图例：★主=核心戏份 / ★=重要出场 / ○=配角出场 / ◇=暗线出现 / ◇暗=幕后操盘

---

## 事件一：青云镇归来

**游戏时长**：10-12小时
**场景**：青云镇 → 青云山道 → 玄霜宗山门
**玩家状态**：炼气后期
**目标**：从凡人世界向修真者世界过渡，建立师徒情感锚点，植入"师父时日无多"的紧迫感

### 1.1 离镇过场

**场景描述**：
青云镇外的官道，晨雾未散。三个月前的血祭阵之战已成传说，但玩家心里清楚——那不过是某个更大谜团的开端。云中鹤背着青霜剑站在道口，身形比记忆中更瘦了一些。铁无双扛着自己的酒葫芦凑过来，硬塞给玩家一个粗布包袱。

**环境叙事点**：
- 镇口的老槐树挂了一条新的红绸（镇民为玩家祈福）
- 王铁匠在炉边偷偷抹眼泪，假装在打铁
- 李婆婆站在远处不敢上前，手里攥着一双布鞋
- 桌上玩家家中的旧剑已经被云中鹤亲手用红布包好

**过场旁白**：
```
旁白：你回头望了一眼青云镇。
      三个月前你还是这里最普通的少年人。
      如今，你即将拜入修真宗门。
      父亲的旧剑在背上微微震动——它似乎也在告别。
```

### 1.2 铁无双送行

**NPC: 铁无双**
```json
{
  "dialogue_id": "ACT2_E1_IRON_001",
  "speaker": "tie_wushuang",
  "text": "兄弟！俺老铁送你到山下！这包袱里是俺娘炒的肉干，路上吃！",
  "choices": [
    {
      "id": "thanks_warm",
      "text": "铁哥，多谢。这份情我记下了。",
      "effects": [
        {"type": "relationship_change", "target": "tie_wushuang", "value": 5}
      ],
      "next_node": "ACT2_E1_IRON_002A"
    },
    {
      "id": "tease",
      "text": "你才学了半年丐帮武功就敢送我？小心被山贼劫了。",
      "effects": [
        {"type": "relationship_change", "target": "tie_wushuang", "value": 3}
      ],
      "next_node": "ACT2_E1_IRON_002B"
    },
    {
      "id": "polite_refuse",
      "text": "心意收下，包袱太重你自己留着。",
      "effects": [],
      "next_node": "ACT2_E1_IRON_002C"
    }
  ]
}
```

**NPC: 铁无双（继续）**
```json
{
  "dialogue_id": "ACT2_E1_IRON_002A",
  "speaker": "tie_wushuang",
  "text": "嘿！兄弟说啥呢，这都是应当的！老子已经决定了，俺也要修真！等俺练好了降龙掌，去玄霜宗找你！",
  "choices": [
    {
      "id": "encourage",
      "text": "等你来。我们山顶比剑。",
      "effects": [
        {"type": "relationship_change", "target": "tie_wushuang", "value": 5},
        {"type": "flag_set", "target": "tie_wushuang_join_promise", "value": true}
      ],
      "next_node": "ACT2_E1_YUN_001"
    }
  ]
}
```

**环境叙事点**：
- 铁无双递包袱时，右手虎口的茧子已经厚了一圈（练降龙掌的痕迹）
- 他偷偷在玩家肩上"哐"地捶了一拳——这是他唯一会的表达方式
- 转身走远时，肩膀其实在微微抖

### 1.3 师徒同行

**场景**：青云山道，山雾渐浓

**NPC: 云中鹤**
```json
{
  "dialogue_id": "ACT2_E1_YUN_001",
  "speaker": "yun_zhonghe",
  "text": "走得慢些。这山道，老夫走过五百年，每一块石头都认得。",
  "choices": [
    {
      "id": "concerned_health",
      "text": "师父，您的咳嗽比上个月更重了。",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 5}
      ],
      "next_node": "ACT2_E1_YUN_002A"
    },
    {
      "id": "ask_sect",
      "text": "玄霜宗是个什么样的地方？",
      "effects": [],
      "next_node": "ACT2_E1_YUN_002B"
    },
    {
      "id": "silent",
      "text": "（沉默走路）",
      "effects": [],
      "next_node": "ACT2_E1_YUN_002C"
    }
  ]
}
```

**NPC: 云中鹤（承接选项A）**
```json
{
  "dialogue_id": "ACT2_E1_YUN_002A",
  "speaker": "yun_zhonghe",
  "text": "（轻笑一声，又压回咳嗽）剑道如人生，重在一个'悟'字。生死也是。你不必为老夫担心。",
  "choices": [
    {
      "id": "press",
      "text": "师父，您是不是有事瞒着我？",
      "effects": [
        {"type": "flag_set", "target": "player_suspects_yun_health", "value": true}
      ],
      "next_node": "ACT2_E1_YUN_003"
    },
    {
      "id": "let_go",
      "text": "（点头不语，记在心里）",
      "effects": [],
      "next_node": "ACT2_E1_YUN_003"
    }
  ]
}
```

**NPC: 云中鹤（揭示伏笔）**
```json
{
  "dialogue_id": "ACT2_E1_YUN_003",
  "speaker": "yun_zhonghe",
  "text": "我们到宗门后，你会见到一个人。她叫慕容雪。若有一天，她想起一些不该想起的事情……记得保护她。",
  "choices": [
    {
      "id": "ask_who",
      "text": "她是谁？为什么要保护她？",
      "effects": [],
      "next_node": "ACT2_E1_YUN_004"
    },
    {
      "id": "promise",
      "text": "我答应师父。",
      "effects": [
        {"type": "flag_set", "target": "promise_protect_murongxue", "value": true},
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 8}
      ],
      "next_node": "ACT2_E1_YUN_004"
    }
  ]
}
```

**环境叙事点**：
- 云中鹤走在前面，右肩明显比左肩低半寸——那是三百年前血无痕留下的剑伤
- 每咳一次，他会用宽袖遮住嘴，再慢慢放下时，袖口内侧有淡淡的暗红
- 青霜剑的剑穗松开了一根丝（剑都在感应主人的虚弱）

### 1.4 玄霜宗山门

**场景描述**：
山道尽头，云海之上，悬浮着一座古朴的山门。"玄霜宗"三字以青冰雕刻，千年不化。门前两位执事弟子见到云中鹤，齐齐躬身。

**过场旁白**：
```
旁白：你抬头看着"玄霜宗"三个字，
      心里第一次涌起一种叫"归属"的东西。
      也许，这里就是你新的家了。
      但你不知道——
      这个"家"，未来会让你做出一些
      你这辈子都不愿做的选择。
```

### 1.5 事件结算

**奖励**：
- 经验：1500
- 灵石：500
- 物品：铁无双肉干（恢复消耗品）×5、玄霜宗内门弟子腰牌
- 关系：云中鹤+8、铁无双+5~10

**状态变更**：
- 玩家正式成为玄霜宗内门弟子
- 标志：`promise_protect_murongxue`（若选择）
- 标志：`player_suspects_yun_health`（若追问）
- 解锁场景：玄霜宗主峰、弟子洞府、藏经阁

**下一事件**：宗门大比公告

---

## 事件二：宗门大比公告

**游戏时长**：12-13小时
**场景**：玄霜宗议事大殿 → 弟子洞府
**玩家状态**：炼气后期
**目标**：引入柳如烟，铺垫宗门派系，建立大比目标

### 2.1 大殿集会

**场景描述**：
玄霜宗议事大殿。所有内门弟子被召集。掌门玄霜真人（云中鹤的师弟）端坐主位，左侧站着一位陌生剑修——身着雪白剑袍，发束红丝带，腰悬"白虹"古剑。她还未出声，殿中已无人敢直视。

**环境叙事点**：
- 白衣女子站姿如剑，剑袍下摆纹丝不动
- 她左手始终虚扣在剑柄上，右手垂在身侧反复捻一根细丝——那是从"白虹"剑穗上扯下的
- 殿内冰柱在她经过时微微起霜（剑心体质的真气外溢）

### 2.2 柳如烟登场

**过场对话**：
```
玄霜真人："此乃天剑盟少主，柳如烟道友。
          百年一度的九州正道大比将于一月后开启。
          柳道友亲临，是为遴选我宗代表。"

柳如烟（声音清亮如玉相击）：
          "小女柳如烟，奉家父之命，叨扰玄霜宗。
          大比之意，不在胜负，在于让九州正道看见——
          年轻一辈中，还有谁愿意举起剑。"
```

**NPC: 柳如烟（初次接触）**
```json
{
  "dialogue_id": "ACT2_E2_LIU_001",
  "speaker": "liu_ruyan",
  "text": "（目光扫过殿中弟子，落在你身上停留半息）这位道友，可愿参加大比？",
  "choices": [
    {
      "id": "accept_eager",
      "text": "愿意。请柳道友指教。",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 5},
        {"type": "flag_set", "target": "joined_grand_tournament", "value": true}
      ],
      "next_node": "ACT2_E2_LIU_002A"
    },
    {
      "id": "accept_humble",
      "text": "小道修为浅薄，唯尽力一试。",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 8},
        {"type": "flag_set", "target": "joined_grand_tournament", "value": true}
      ],
      "next_node": "ACT2_E2_LIU_002B"
    },
    {
      "id": "ask_purpose",
      "text": "大比的真正目的，是什么？",
      "effects": [
        {"type": "flag_set", "target": "player_questions_authority", "value": true}
      ],
      "next_node": "ACT2_E2_LIU_002C"
    }
  ]
}
```

**NPC: 柳如烟（回应"质问目的"）**
```json
{
  "dialogue_id": "ACT2_E2_LIU_002C",
  "speaker": "liu_ruyan",
  "text": "（捻剑穗的手指停了一停，目光重新打量你）……好问题。古人云'兵者，国之大事'。大比，便是修真界的'兵'。至于真正目的——道友若赢到决赛，自然会有人告诉你。",
  "choices": [
    {
      "id": "accept_challenge",
      "text": "那我便赢到决赛。",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 10},
        {"type": "flag_set", "target": "joined_grand_tournament", "value": true}
      ],
      "next_node": "ACT2_E2_LIU_003"
    }
  ]
}
```

**环境叙事点**：
- 柳如烟在听到玩家追问目的时，捻剑穗的动作停了——这是她紧张的暗号
- 她身后的执事弟子皱了眉，但她抬手轻轻一摆，制止了对方上前
- 玄霜真人和云中鹤交换了一个眼神（他们知道大比另有内情）

### 2.3 散会后的提点

**NPC: 云中鹤（私下叮嘱）**
```json
{
  "dialogue_id": "ACT2_E2_YUN_001",
  "speaker": "yun_zhonghe",
  "text": "（咳了一声）大比之事，老夫不拦你。但你要记住——这世上的'正道'二字，有时比'魔道'更难懂。",
  "choices": [
    {
      "id": "ask_meaning",
      "text": "师父此话何意？",
      "effects": [],
      "next_node": "ACT2_E2_YUN_002"
    },
    {
      "id": "nod",
      "text": "弟子记下了。",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 3}
      ],
      "next_node": "ACT2_E2_YUN_002"
    }
  ]
}
```

**NPC: 云中鹤（继续）**
```json
{
  "dialogue_id": "ACT2_E2_YUN_002",
  "speaker": "yun_zhonghe",
  "text": "三百年前，飞升之战。老夫亲眼见过——同样的剑，可以救人，也可以杀人。区别只在持剑者那一念之间。你的'一念'，自己要守好。",
  "choices": [
    {
      "id": "solemn",
      "text": "（默默点头，将这话记在心底）",
      "effects": [
        {"type": "dao_heart_change", "value": 0, "note": "未做选择，但建立伏笔"}
      ],
      "next_node": "ACT2_E2_END"
    }
  ]
}
```

### 2.4 事件结算

**奖励**：
- 经验：1000
- 物品：玄霜宗大比令牌、修炼资源包（中阶灵石×30）
- 关系：柳如烟+5~13、云中鹤+3
- 解锁：大比训练场、对练系统

**状态变更**：
- 标志：`joined_grand_tournament`
- 标志（条件）：`player_questions_authority`
- 解锁支线：柳如烟个人剧情线（"白虹剑的来历"）

**下一事件**：初次试炼

---

## 事件三：初次试炼 — 三策克赵无极

**游戏时长**：13-15小时
**场景**：玄霜宗大比演武场
**玩家状态**：炼气后期 → 接近筑基瓶颈
**目标**：第一场实战，引入战术选择系统，塑造铁无双的护道情谊

### 3.1 抽签对阵

**场景描述**：
玄霜宗演武场，巨大的青冰擂台浮于湖面。玩家抽到的对手是赵无极——玄霜宗外门第一人，三十岁出头，炼气巅峰，以"无极掌"闻名。他对玩家这种"凭师恩走捷径的小辈"早有不满。

**NPC: 赵无极（挑衅）**
```json
{
  "dialogue_id": "ACT2_E3_ZHAO_001",
  "speaker": "zhao_wuji",
  "text": "云老前辈的关门弟子？呵。修真界讲究的是真本事，不是会拜个好师父。小子，让我看看你有几两重。",
  "choices": [
    {
      "id": "ignore",
      "text": "（不回应，抽剑入场）",
      "effects": [
        {"type": "dao_heart_change", "value": 1}
      ],
      "next_node": "ACT2_E3_STRATEGY"
    },
    {
      "id": "retort_sharp",
      "text": "你师父若教得好，也不会让你三十岁还在外门。",
      "effects": [
        {"type": "relationship_change", "target": "zhao_wuji", "value": -10}
      ],
      "next_node": "ACT2_E3_STRATEGY"
    },
    {
      "id": "respect",
      "text": "前辈说得是。请赐教。",
      "effects": [
        {"type": "dao_heart_change", "value": 2},
        {"type": "relationship_change", "target": "zhao_wuji", "value": 3}
      ],
      "next_node": "ACT2_E3_STRATEGY"
    }
  ]
}
```

### 3.2 三策选择（核心战术节点）

**铁无双在台下大喊**：
```
铁无双（攥着栏杆，几乎要跳上去）：
       "兄弟！稳住！这家伙下盘虚！打他左膝！打他左膝！"
```

**选择点**：
```json
{
  "dialogue_id": "ACT2_E3_STRATEGY",
  "speaker": "system",
  "text": "你该如何应对赵无极？",
  "choices": [
    {
      "id": "strategy_attack",
      "text": "策略一：以攻代守，主动逼近近战",
      "effects": [
        {"type": "combat_modifier", "target": "attack_bonus", "value": 20},
        {"type": "combat_modifier", "target": "defense_penalty", "value": -10}
      ],
      "next_node": "ACT2_E3_BATTLE_A"
    },
    {
      "id": "strategy_defense",
      "text": "策略二：以守为攻，待其破绽",
      "effects": [
        {"type": "combat_modifier", "target": "defense_bonus", "value": 25},
        {"type": "combat_modifier", "target": "counter_window", "value": 1}
      ],
      "next_node": "ACT2_E3_BATTLE_B"
    },
    {
      "id": "strategy_iron_advice",
      "text": "策略三：听铁哥的，打他左膝（需关系≥10）",
      "effects": [
        {"type": "combat_modifier", "target": "critical_hit_chance", "value": 50},
        {"type": "relationship_change", "target": "tie_wushuang", "value": 10},
        {"type": "flag_set", "target": "trust_iron_advice", "value": true}
      ],
      "requirements": {"relationship": {"tie_wushuang": 10}},
      "next_node": "ACT2_E3_BATTLE_C"
    }
  ]
}
```

### 3.3 战斗结算（以策略三为示例）

**过场描述**：
玩家依铁无双所言，假意正面突进，临到三步距离突然侧身一剑斜劈赵无极左膝——果然命中。赵无极半跪在地，无极掌的第七式直接断了。

**NPC: 赵无极（败北）**
```json
{
  "dialogue_id": "ACT2_E3_ZHAO_002",
  "speaker": "zhao_wuji",
  "text": "（喘息）……你怎么知道我左膝……",
  "choices": [
    {
      "id": "honest",
      "text": "我朋友看出来的。是他的功劳。",
      "effects": [
        {"type": "dao_heart_change", "value": 3},
        {"type": "relationship_change", "target": "tie_wushuang", "value": 5}
      ],
      "next_node": "ACT2_E3_END_HONOR"
    },
    {
      "id": "claim_alone",
      "text": "你自己功夫不到家。",
      "effects": [
        {"type": "dao_heart_change", "value": -2},
        {"type": "relationship_change", "target": "tie_wushuang", "value": -5}
      ],
      "next_node": "ACT2_E3_END_PRIDE"
    },
    {
      "id": "extend_hand",
      "text": "（伸手扶他）下次切磋，请前辈再赐教。",
      "effects": [
        {"type": "dao_heart_change", "value": 5},
        {"type": "relationship_change", "target": "zhao_wuji", "value": 15}
      ],
      "next_node": "ACT2_E3_END_HONOR"
    }
  ]
}
```

### 3.4 铁无双的拥抱

**场景描述**：
台下铁无双红着眼眶冲上来，二话不说"哐"地把玩家抱起来转了一圈。

**NPC: 铁无双**
```json
{
  "dialogue_id": "ACT2_E3_IRON_001",
  "speaker": "tie_wushuang",
  "text": "兄弟！赢了！俺就说兄弟你最稳！老子今晚请你喝酒！花雕、绍兴、二锅头，随你挑！",
  "choices": [
    {
      "id": "accept",
      "text": "走！老子今天醉给你看。",
      "effects": [
        {"type": "relationship_change", "target": "tie_wushuang", "value": 5},
        {"type": "flag_set", "target": "drank_with_iron", "value": true}
      ],
      "next_node": "ACT2_E3_END"
    },
    {
      "id": "thanks_only",
      "text": "今晚不能喝。我得去藏经阁看资料。",
      "effects": [
        {"type": "relationship_change", "target": "tie_wushuang", "value": -2}
      ],
      "next_node": "ACT2_E3_END"
    }
  ]
}
```

### 3.5 事件结算

**奖励**：
- 经验：2500（策略三+500额外）
- 灵石：800
- 物品：玄霜宗大比初赛令、赵无极赠送的"无极拳谱残页"（若选"伸手扶他"）
- 关系：铁无双+15~25、赵无极+0~18
- 道心：+0~+8

**状态变更**：
- 战术系统解锁：可在重大战斗前选择策略
- 标志：`tournament_round_1_win`
- 标志（条件）：`trust_iron_advice`、`drank_with_iron`

**下一事件**：魔教入侵

---

## 事件四：魔教入侵

**游戏时长**：15-17小时
**场景**：玄霜宗山门 → 师父洞府 → 山门外大战
**玩家状态**：炼气后期（瓶颈期）
**目标**：第一次正面见识魔教组织化作战，引入萧寒夜的暗线，强化云中鹤危机

### 4.1 警报响起

**场景描述**：
深夜。玄霜宗山门的青冰示警阵猛然亮起血红色——这是宗门数百年第一次启动最高警戒。玩家从洞府冲出，看见漫山遍野的黑袍人影，如墨汁泼上雪地。

**环境叙事点**：
- 黑袍人结成"九宫八卦阵"，进退有度——这不是散兵游勇，是受过严训的精锐
- 阵中央悬浮一面血色旗帜：上书"血"字（血无痕的标志）
- 山门顶端，玄霜真人持剑而立，身边只有寥寥几位长老（魔教选了大比期间发动）

**过场旁白**：
```
旁白：你这才明白柳如烟为何要急着选大比代表。
      因为正道，早已不是铁板一块。
      因为魔教，正在重新组织。
      因为有人，要把三百年前的火，重新点起来。
```

### 4.2 师父洞府

**NPC: 云中鹤（受伤）**
```json
{
  "dialogue_id": "ACT2_E4_YUN_001",
  "speaker": "yun_zhonghe",
  "text": "（咳出一口血，强撑站立）……来了。比我想的早。你快走，去后山，带上慕容雪。",
  "choices": [
    {
      "id": "refuse_leave",
      "text": "师父！我不走，我陪您！",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 10},
        {"type": "dao_heart_change", "value": 3}
      ],
      "next_node": "ACT2_E4_YUN_002A"
    },
    {
      "id": "ask_who",
      "text": "他们的首领是谁？为什么找您？",
      "effects": [],
      "next_node": "ACT2_E4_YUN_002B"
    },
    {
      "id": "obey",
      "text": "弟子遵命，立刻去找慕容师妹。",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 5}
      ],
      "next_node": "ACT2_E4_YUN_002C"
    }
  ]
}
```

**NPC: 云中鹤（回应"询问首领"）**
```json
{
  "dialogue_id": "ACT2_E4_YUN_002B",
  "speaker": "yun_zhonghe",
  "text": "（瞳孔骤缩，又压下）……是一个我以为已经死了三百年的人。如果你今晚见到一柄黑色长剑，剑身上刻'无痕'二字——掉头就跑。听见没有？",
  "choices": [
    {
      "id": "promise",
      "text": "弟子听见了。",
      "effects": [
        {"type": "flag_set", "target": "knows_xuewuhen_name", "value": true}
      ],
      "next_node": "ACT2_E4_BATTLE"
    }
  ]
}
```

### 4.3 山门大战

**场景描述**：
玩家冲出洞府时，遇到铁无双正在断后。柳如烟从天而降，白虹剑出鞘，一剑斩落三个黑袍——但她也明显受了伤，左臂袖口已被血染透。

**NPC: 柳如烟（战中）**
```json
{
  "dialogue_id": "ACT2_E4_LIU_001",
  "speaker": "liu_ruyan",
  "text": "（喘息）他们的目标是云中鹤前辈！我护你过去！",
  "choices": [
    {
      "id": "fight_together",
      "text": "好！并肩破阵！",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 10},
        {"type": "combat_modifier", "target": "team_buff", "value": 30}
      ],
      "next_node": "ACT2_E4_BATTLE"
    },
    {
      "id": "send_her_back",
      "text": "你伤了，回去！我自己去！",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 5},
        {"type": "dao_heart_change", "value": 2}
      ],
      "next_node": "ACT2_E4_BATTLE"
    }
  ]
}
```

### 4.4 黑袍首领惊鸿一瞥

**过场描述**：
就在玩家与柳如烟杀到师父洞府时，一道黑影从屋顶倒掠而过——身高近六尺，黑色魔袍下摆翻飞，左眼角一道淡淡的疤痕在月光下闪了一下。他怀里夹着一个昏迷的女子（慕容雪）。

**NPC: 萧寒夜（暗线第一次出场）**
```json
{
  "dialogue_id": "ACT2_E4_XIAO_001",
  "speaker": "xiao_hanye",
  "text": "（看了你一眼，嘴角微扬，笑容却不达眼底）下次，道友。",
  "choices": [
    {
      "id": "shout_after",
      "text": "放下她！",
      "effects": [
        {"type": "flag_set", "target": "saw_xiao_hanye", "value": true}
      ],
      "next_node": "ACT2_E4_XIAO_002"
    },
    {
      "id": "chase",
      "text": "（不答话，直接追）",
      "effects": [
        {"type": "flag_set", "target": "saw_xiao_hanye", "value": true},
        {"type": "combat_event", "target": "chase_xiao", "value": "fail"}
      ],
      "next_node": "ACT2_E4_XIAO_002"
    }
  ]
}
```

**NPC: 萧寒夜（回应）**
```json
{
  "dialogue_id": "ACT2_E4_XIAO_002",
  "speaker": "xiao_hanye",
  "text": "（一闪身已在十丈外）她不属于这里。也不属于你们。等你想通了，自然会来找我。",
  "choices": [
    {
      "id": "swear",
      "text": "（默默记下他的容貌）",
      "effects": [
        {"type": "flag_set", "target": "remember_xiao_face", "value": true}
      ],
      "next_node": "ACT2_E4_END"
    }
  ]
}
```

**环境叙事点**：
- 萧寒夜怀里的慕容雪手指松开了——掉下一块雪莲玉佩，正落在玩家脚边
- 玉佩的封印纹路微微发亮（她记忆正在松动）
- 萧寒夜的眼神在玉佩落地的瞬间，闪过一丝玩家没看懂的复杂情绪——是怜悯？还是熟悉？

### 4.5 事件结算

**奖励**：
- 经验：3500
- 物品：雪莲玉佩（关键剧情道具）、玄霜宗护宗令、柳如烟赠送的疗伤丹×3
- 关系：云中鹤+10~15、柳如烟+10~15、铁无双+5（断后情谊）
- 道心：+0~+5

**状态变更**：
- 关键标志：`saw_xiao_hanye`、`remember_xiao_face`、`knows_xuewuhen_name`
- 道具：雪莲玉佩进入剧情槽（Act 2 Event 7触发）
- 玄霜宗损失：三位长老阵亡，外门弟子伤亡过半

**下一事件**：上古秘境

---

## 事件五：上古秘境 — 清虚真人传承

**游戏时长**：17-20小时
**场景**：玄霜宗后山禁地 → 上古秘境
**玩家状态**：炼气巅峰（即将筑基）
**目标**：引入慕容雪正式戏份、玄机真人首次出场、提供筑基期资源、第一次接触飞升真相

### 5.1 后山禁地

**场景描述**：
魔教退去后第三日，玄机真人（化神后期道修，玄霜宗辈分最高的太上长老）从闭关中破关而出，召集玩家、慕容雪、铁无双前往后山禁地。

**NPC: 玄机真人（初次出场）**
```json
{
  "dialogue_id": "ACT2_E5_XUAN_001",
  "speaker": "xuan_ji_zhenren",
  "text": "（温润一笑，目光却深不见底）老道闭关百年，今日方知世事如棋。诸位道友，可愿随老道走一趟上古秘境？",
  "choices": [
    {
      "id": "ask_purpose",
      "text": "前辈，秘境之中有何机缘？",
      "effects": [],
      "next_node": "ACT2_E5_XUAN_002A"
    },
    {
      "id": "agree",
      "text": "晚辈愿往。",
      "effects": [
        {"type": "relationship_change", "target": "xuan_ji_zhenren", "value": 5}
      ],
      "next_node": "ACT2_E5_XUAN_002B"
    },
    {
      "id": "hesitate",
      "text": "前辈，慕容师妹刚遇袭，是否应该让她休息？",
      "effects": [
        {"type": "dao_heart_change", "value": 3},
        {"type": "relationship_change", "target": "murong_xue", "value": 8}
      ],
      "next_node": "ACT2_E5_XUAN_002C"
    }
  ]
}
```

**NPC: 玄机真人（答非所问）**
```json
{
  "dialogue_id": "ACT2_E5_XUAN_002A",
  "speaker": "xuan_ji_zhenren",
  "text": "机缘？或许有。或许只是一些……该被想起的东西。或许，老道也只是想再看一眼三百年前的旧地。",
  "choices": [
    {
      "id": "press_xuewuhen",
      "text": "三百年前？前辈认识血无痕？",
      "effects": [
        {"type": "flag_set", "target": "xuan_ji_knows_xuewuhen", "value": true}
      ],
      "next_node": "ACT2_E5_XUAN_003"
    },
    {
      "id": "drop_subject",
      "text": "（不再追问）",
      "effects": [],
      "next_node": "ACT2_E5_XUAN_003"
    }
  ]
}
```

### 5.2 慕容雪的不安

**场景描述**：
进入秘境前，慕容雪一直沉默。她比平日更安静，目光始终落在玩家腰间的雪莲玉佩上。

**NPC: 慕容雪**
```json
{
  "dialogue_id": "ACT2_E5_MUR_001",
  "speaker": "murong_xue",
  "text": "（清冷的声音，比平日更轻）……道友。这个秘境，我好像，在哪里见过。",
  "choices": [
    {
      "id": "ask_dream",
      "text": "你梦见过？",
      "effects": [
        {"type": "relationship_change", "target": "murong_xue", "value": 5}
      ],
      "next_node": "ACT2_E5_MUR_002A"
    },
    {
      "id": "comfort",
      "text": "（轻声）若你害怕，我陪你回去。",
      "effects": [
        {"type": "relationship_change", "target": "murong_xue", "value": 10},
        {"type": "dao_heart_change", "value": 3}
      ],
      "next_node": "ACT2_E5_MUR_002B"
    },
    {
      "id": "give_jade",
      "text": "（把雪莲玉佩还给她）这个，本来就是你的。",
      "effects": [
        {"type": "relationship_change", "target": "murong_xue", "value": 15},
        {"type": "flag_set", "target": "returned_jade_to_murongxue", "value": true}
      ],
      "next_node": "ACT2_E5_MUR_002C"
    }
  ]
}
```

**NPC: 慕容雪（接受玉佩）**
```json
{
  "dialogue_id": "ACT2_E5_MUR_002C",
  "speaker": "murong_xue",
  "text": "（接过玉佩的瞬间，瞳孔微缩，喃喃古语）……'雪莲十二瓣，逍遥一脉传'……我，为什么会知道这句话？",
  "choices": [
    {
      "id": "support",
      "text": "（不问，只把手放在她肩上）",
      "effects": [
        {"type": "relationship_change", "target": "murong_xue", "value": 10},
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E5_ENTER"
    }
  ]
}
```

### 5.3 秘境核心 — 清虚传承

**场景描述**：
秘境深处，一座青玉石台。石台中央悬浮着一卷金光闪闪的玉简。玄机真人解释，这是上古散修"清虚真人"留下的传承，分三条路径——

**选择点：三种传承路径**
```json
{
  "dialogue_id": "ACT2_E5_INHERITANCE",
  "speaker": "xuan_ji_zhenren",
  "text": "传承分三路：'剑诀'重攻、'符箓'重控、'丹道'重养。诸位道友，按机缘自取。",
  "choices": [
    {
      "id": "path_sword",
      "text": "剑诀（攻击型）— 我要正面破敌",
      "effects": [
        {"type": "skill_unlock", "target": "qingxu_sword_art", "value": true},
        {"type": "stat_boost", "target": "attack", "value": 30}
      ],
      "next_node": "ACT2_E5_PATH_END"
    },
    {
      "id": "path_talisman",
      "text": "符箓（控制型）— 我要以智胜力",
      "effects": [
        {"type": "skill_unlock", "target": "qingxu_talisman_art", "value": true},
        {"type": "stat_boost", "target": "control", "value": 30}
      ],
      "next_node": "ACT2_E5_PATH_END"
    },
    {
      "id": "path_alchemy",
      "text": "丹道（辅助型）— 我要保护同伴",
      "effects": [
        {"type": "skill_unlock", "target": "qingxu_alchemy_art", "value": true},
        {"type": "stat_boost", "target": "support", "value": 30},
        {"type": "dao_heart_change", "value": 3}
      ],
      "next_node": "ACT2_E5_PATH_END"
    }
  ]
}
```

### 5.4 玉简的隐藏文字

**过场描述**：
玩家激活玉简时，金光散去，露出底下一行用血写就的小字——只有"道心通透"者能看见。

**NPC: 清虚真人遗念（特殊触发：道心≥10或选择path_alchemy）**
```json
{
  "dialogue_id": "ACT2_E5_QINGXU_001",
  "speaker": "qingxu_zhenren",
  "text": "（虚影浮现，声音苍老）后世来者……若你见到此言，三百年前的封印必将解开。请告诉慕容雪：当年是我对不起她……血无痕的心结，在'万剑冢'。",
  "choices": [
    {
      "id": "ask_who_qingxu",
      "text": "前辈您是？",
      "effects": [
        {"type": "flag_set", "target": "qingxu_real_name_revealed", "value": false}
      ],
      "next_node": "ACT2_E5_QINGXU_002"
    },
    {
      "id": "promise_relay",
      "text": "晚辈记下了。",
      "effects": [
        {"type": "flag_set", "target": "qingxu_message_received", "value": true},
        {"type": "flag_set", "target": "knows_wanjianzhong", "value": true}
      ],
      "next_node": "ACT2_E5_QINGXU_002"
    }
  ]
}
```

**NPC: 清虚真人遗念（继续）**
```json
{
  "dialogue_id": "ACT2_E5_QINGXU_002",
  "speaker": "qingxu_zhenren",
  "text": "我是逍遥派最后一位长老。慕容雪曾是我的掌门师姐。后辈，封印之事，不是简单的'正'与'魔'……（虚影散去）",
  "choices": [
    {
      "id": "silent_oath",
      "text": "（默默立誓，要查明真相）",
      "effects": [
        {"type": "dao_heart_change", "value": 5},
        {"type": "flag_set", "target": "swore_to_seek_truth", "value": true}
      ],
      "next_node": "ACT2_E5_END"
    }
  ]
}
```

### 5.5 事件结算

**奖励**：
- 经验：4500
- 灵石：1500
- 物品：清虚传承玉简、上古灵药×3
- 关系：慕容雪+10~25、玄机真人+5~10、铁无双+5
- 道心：+0~+13
- 技能：从三派传承中选择一路

**状态变更**：
- 关键标志：`returned_jade_to_murongxue`、`swore_to_seek_truth`、`knows_wanjianzhong`
- 解锁：万剑冢区域（Act 2 Event 8前置）
- 慕容雪记忆松动度：30%

**下一事件**：道心抉择

---

## 事件六：道心抉择 — 萧寒夜 vs 柳如烟

**游戏时长**：20-22小时
**场景**：青云山外冷月崖
**玩家状态**：筑基瓶颈
**目标**：第一次面对"正道vs魔道"的真正分歧，触发道心系统核心机制，建立Act 3分支锚点

### 6.1 萧寒夜的邀请

**场景描述**：
深夜。玩家收到一封无署名信，信上仅一句话："冷月崖。子时。来与不来，皆是你的道。" 信纸是黑色，字是银色——这是萧寒夜的笔迹。

**抵达后场景**：
冷月崖位于青云山北侧，悬崖外是无尽云海。萧寒夜独自坐在崖边，身边没有任何随从。他没有回头，但显然知道玩家来了。

**NPC: 萧寒夜（首次正面对话）**
```json
{
  "dialogue_id": "ACT2_E6_XIAO_001",
  "speaker": "xiao_hanye",
  "text": "（依旧没有回头，声音平静）道友能来，证明你的'道'，不只听你师父的。坐。",
  "choices": [
    {
      "id": "sit",
      "text": "（坐在他旁边三步外）你想说什么？",
      "effects": [],
      "next_node": "ACT2_E6_XIAO_002"
    },
    {
      "id": "draw_sword",
      "text": "（拔剑指向他）说，慕容师妹在哪？",
      "effects": [
        {"type": "relationship_change", "target": "xiao_hanye", "value": -5}
      ],
      "next_node": "ACT2_E6_XIAO_002"
    },
    {
      "id": "stand_silent",
      "text": "（站在远处，不坐不语）",
      "effects": [],
      "next_node": "ACT2_E6_XIAO_002"
    }
  ]
}
```

**NPC: 萧寒夜（讲述自己的故事）**
```json
{
  "dialogue_id": "ACT2_E6_XIAO_002",
  "speaker": "xiao_hanye",
  "text": "（终于回头，左眼角的疤在月光下泛白）我十岁那年，亲眼看着所谓'正道'屠了我全家三十七口。罪名？'通魔'。可笑的是，我家从未与任何魔修来往。",
  "choices": [
    {
      "id": "ask_why",
      "text": "（沉默听完）那他们为什么屠你家？",
      "effects": [
        {"type": "relationship_change", "target": "xiao_hanye", "value": 5}
      ],
      "next_node": "ACT2_E6_XIAO_003"
    },
    {
      "id": "dismiss",
      "text": "（冷声）那是你的故事，不是我的道。",
      "effects": [
        {"type": "relationship_change", "target": "xiao_hanye", "value": -5},
        {"type": "dao_heart_change", "value": -2}
      ],
      "next_node": "ACT2_E6_XIAO_003"
    }
  ]
}
```

**NPC: 萧寒夜（继续）**
```json
{
  "dialogue_id": "ACT2_E6_XIAO_003",
  "speaker": "xiao_hanye",
  "text": "因为我家有一卷祖传剑诀，名为'万剑归一'。'正道'某位大人想要。我家不给。三日后，全家就成了'魔'。弱者，没有选择的权利。强者，定义什么叫'正'。",
  "choices": [
    {
      "id": "ask_join",
      "text": "你今晚找我，是要我加入你？",
      "effects": [],
      "next_node": "ACT2_E6_XIAO_004"
    },
    {
      "id": "reject_logic",
      "text": "即便'正道'有错，也不能让你屠戮无辜。",
      "effects": [
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E6_XIAO_004"
    }
  ]
}
```

**NPC: 萧寒夜（亮出条件）**
```json
{
  "dialogue_id": "ACT2_E6_XIAO_004",
  "speaker": "xiao_hanye",
  "text": "（站起身，目光直视）我不要你信我。我只要你做一件事——明日大比，柳如烟会代表正道挑你。她会赢。然后你师父会被血无痕找上门。你救得了一个，救不了两个。跟我走，慕容雪会回来。你师父，能多活十年。",
  "choices": [
    {
      "id": "ask_proof",
      "text": "你凭什么让我信你？",
      "effects": [],
      "next_node": "ACT2_E6_XIAO_005"
    },
    {
      "id": "refuse_outright",
      "text": "我不会背叛师父和柳道友。",
      "effects": [
        {"type": "dao_heart_change", "value": 10},
        {"type": "flag_set", "target": "rejected_xiao_directly", "value": true}
      ],
      "next_node": "ACT2_E6_LIU_INTERRUPT"
    }
  ]
}
```

### 6.2 柳如烟的出现（关键剧情转折）

**场景描述**：
不论玩家选择何种回应，柳如烟从崖外突然飞身而至——她跟踪了玩家。白虹剑出鞘，剑尖直指萧寒夜。

**NPC: 柳如烟（怒）**
```json
{
  "dialogue_id": "ACT2_E6_LIU_001",
  "speaker": "liu_ruyan",
  "text": "（声音清亮但带寒意）正道当兴，邪魔退散！萧寒夜，你竟敢动我玄霜宗友的心智！让开！",
  "choices": [
    {
      "id": "block_liu",
      "text": "（侧身挡在二人之间）等等，听我说。",
      "effects": [
        {"type": "flag_set", "target": "stood_between_them", "value": true}
      ],
      "next_node": "ACT2_E6_BLOCK"
    },
    {
      "id": "join_liu",
      "text": "（与柳道友并肩）正道与你不共戴天！",
      "effects": [
        {"type": "dao_heart_change", "value": 15},
        {"type": "relationship_change", "target": "liu_ruyan", "value": 20},
        {"type": "relationship_change", "target": "xiao_hanye", "value": -15},
        {"type": "flag_set", "target": "chose_zhengdao_at_cliff", "value": true}
      ],
      "next_node": "ACT2_E6_FIGHT"
    },
    {
      "id": "join_xiao",
      "text": "（站到萧寒夜一侧）柳道友，且听他把话说完。",
      "effects": [
        {"type": "dao_heart_change", "value": -15},
        {"type": "relationship_change", "target": "liu_ruyan", "value": -20},
        {"type": "relationship_change", "target": "xiao_hanye", "value": 20},
        {"type": "flag_set", "target": "chose_modao_at_cliff", "value": true}
      ],
      "next_node": "ACT2_E6_FIGHT"
    }
  ]
}
```

### 6.3 萧寒夜与柳如烟的对峙细节

**环境叙事点**：
- 柳如烟的剑尖在颤抖——不是恐惧，是愤怒。她捏剑穗的手指因用力而发白
- 萧寒夜的左手垂在身侧，但右手始终没有靠近剑柄——他从一开始就没打算动手
- 月光下，两人脚下三步距离的雪地，分别向各自方向结了一层薄霜（剑心与魔意的对冲）
- **关键细节**：当萧寒夜看向柳如烟时，他左眼角的疤微微一抽——这是他唯一一次失控（他对她有某种复杂情感）

**NPC: 萧寒夜（对柳如烟）**
```json
{
  "dialogue_id": "ACT2_E6_XIAO_LIU_001",
  "speaker": "xiao_hanye",
  "text": "（看着柳如烟，声音突然低了三度）……柳家小姐，三年前你父亲在落雁峰，杀了我的两个师弟。我没找你报仇，是因为我知道——你不知情。",
  "choices": [
    {
      "id": "shocked",
      "text": "（震惊，看向柳如烟）",
      "effects": [
        {"type": "flag_set", "target": "knows_liu_father_killing", "value": true}
      ],
      "next_node": "ACT2_E6_LIU_RESPONSE"
    }
  ]
}
```

**NPC: 柳如烟（动摇）**
```json
{
  "dialogue_id": "ACT2_E6_LIU_RESPONSE",
  "speaker": "liu_ruyan",
  "text": "（剑尖第一次松懈，目光闪烁）……我父亲……不会杀无辜的人。你在污蔑……",
  "choices": [
    {
      "id": "comfort_liu",
      "text": "（轻声）柳道友，先听他说完。",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 10},
        {"type": "dao_heart_change", "value": 3}
      ],
      "next_node": "ACT2_E6_END_NEUTRAL"
    }
  ]
}
```

### 6.4 三种结局走向

**结局A：偏正道**（chose_zhengdao_at_cliff = true）
- 萧寒夜消失于云海，丢下一句："你迟早会看见我说的'正道'是什么。"
- 柳如烟受伤未愈，玩家护送她回宗门，二人情谊大增

**结局B：偏魔道**（chose_modao_at_cliff = true）
- 萧寒夜带玩家短暂离开。萧寒夜表示三月后大比决赛见
- 柳如烟视玩家为半个叛徒，关系骤降但未彻底破裂
- 解锁支线："魔教内幕"

**结局C：中立**（stood_between_them = true）
- 双方暂时收手，各自离去
- 萧寒夜临走说："道友，你比我想的复杂。我喜欢复杂的人。"
- 柳如烟离去前说："今夜之事，我当作没有发生。但下次……请你站稳立场。"
- 解锁支线："道心试炼"

### 6.5 事件结算

**奖励**：
- 经验：5000
- 物品：根据选择给予不同道具（正道：玄铁剑符 / 魔道：血玉令牌 / 中立：太极道纹）
- 关系：剧烈波动（柳/萧 ±20）
- 道心：±15（决定Act 3核心走向）

**状态变更**：
- **三大锚点标志**：`chose_zhengdao_at_cliff`、`chose_modao_at_cliff`、`stood_between_them`（互斥）
- 标志：`knows_liu_father_killing`、`rejected_xiao_directly`（条件）
- Act 3分支线索建立

**下一事件**：慕容雪记忆

---

## 事件七：慕容雪记忆觉醒

**游戏时长**：22-24小时
**场景**：慕容雪洞府 → 古庙遗迹（梦境/记忆）
**玩家状态**：筑基初期（突破后/突破前）
**目标**：揭示血无痕真实身份与背叛者线索，深化飞升真相

### 7.1 慕容雪的呼救

**场景描述**：
凌晨，玩家被慕容雪洞府方向的灵气暴动惊醒。冲入洞府时，看见慕容雪坐在蒲团上浑身发抖，手中紧握雪莲玉佩，玉佩的封印纹路正在崩裂。

**NPC: 慕容雪（记忆涌入中）**
```json
{
  "dialogue_id": "ACT2_E7_MUR_001",
  "speaker": "murong_xue",
  "text": "（瞳孔涣散，喃喃古语）……'子时三刻，星陨之时，封印已动'……我……我看见了……血……还有他……",
  "choices": [
    {
      "id": "hold_her",
      "text": "（紧紧抱住她，输入真元稳定心神）",
      "effects": [
        {"type": "relationship_change", "target": "murong_xue", "value": 20},
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E7_MEMORY_DIVE"
    },
    {
      "id": "destroy_jade",
      "text": "（伸手去夺玉佩）这玉佩在伤她！",
      "effects": [
        {"type": "flag_set", "target": "tried_destroy_jade", "value": true},
        {"type": "relationship_change", "target": "murong_xue", "value": -5}
      ],
      "next_node": "ACT2_E7_FAIL_BLOCK"
    },
    {
      "id": "call_xuanji",
      "text": "（不动声色，去叫玄机真人）",
      "effects": [
        {"type": "flag_set", "target": "called_xuanji_for_help", "value": true}
      ],
      "next_node": "ACT2_E7_XUANJI_ARRIVE"
    }
  ]
}
```

### 7.2 记忆潜入（梦境场景）

**场景描述**：
玩家选择"紧紧抱住"后，他的真元与慕容雪共鸣，意识被卷入她的前世记忆——

**画面**：
古庙之内，三百年前。一位白衣女子（前世慕容雪/逍遥派掌门），与一位青衣男子（年轻的血无痕）并肩而立。两人手中各持一枚玉简，正在共同布置一个巨大的星阵。

**前世对话片段**：
```
青衣男子（血无痕）："师姐，封印一旦布下，我们就再也回不去九州了。"
白衣女子（前世慕容雪）："为了天下苍生，这是必要的代价。"
青衣男子："可是飞升之路……明明就在那扇门后……"
白衣女子："那不是飞升之路。那是大劫之门。师弟，听我一次。"
```

**画面切换**：
星阵布成的瞬间，一位身披黑甲的修士从暗处冲出，长剑直刺白衣女子背心——是逍遥派的另一位长老（背叛者）。血无痕来不及救援，只来得及挡下第二剑。白衣女子在血泊中嘱托——

```
白衣女子（虚弱）："师弟……封印不能停……
                 你……是唯一守得住的人了……
                 这个仇……不要报……
                 不要让天下苍生……再受一次劫……"
血无痕（崩溃）："师姐！我答应你封印！但这个仇……我一定要报！"
```

**关键揭示**：
- **背叛者**：逍遥派"墨长老"，与天剑盟现任盟主（柳如烟的父亲）的祖父，是结义兄弟
- **血无痕真相**：他不是"魔头"，他是当年封印的守护者。三百年来杀人，是为了找出当年陷害师姐的"墨"家血脉
- **慕容雪转世原因**：她是前世自己投胎转世，封印的"备用钥匙"

### 7.3 醒后对话

**NPC: 慕容雪（醒来）**
```json
{
  "dialogue_id": "ACT2_E7_MUR_AWAKE",
  "speaker": "murong_xue",
  "text": "（眼神比平日更冷静，却带着前所未有的疲惫）……我都想起来了。道友，对不起，让你见到那些。",
  "choices": [
    {
      "id": "ask_truth",
      "text": "血无痕，并不是真正的反派？",
      "effects": [
        {"type": "flag_set", "target": "knows_xuewuhen_truth", "value": true}
      ],
      "next_node": "ACT2_E7_MUR_002A"
    },
    {
      "id": "protect_her",
      "text": "无论你前世是谁，今生我都护你。",
      "effects": [
        {"type": "relationship_change", "target": "murong_xue", "value": 25},
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E7_MUR_002B"
    },
    {
      "id": "ask_liu",
      "text": "柳如烟……她父亲，与背叛者有关？",
      "effects": [
        {"type": "flag_set", "target": "knows_liu_family_secret", "value": true}
      ],
      "next_node": "ACT2_E7_MUR_002C"
    }
  ]
}
```

**NPC: 慕容雪（揭示完整真相）**
```json
{
  "dialogue_id": "ACT2_E7_MUR_002C",
  "speaker": "murong_xue",
  "text": "（沉默良久）柳家与墨家，三百年来一直是结义之盟。如烟未必知情。但她父亲——天剑盟主柳擎天，他知道。他的家族秘籍中，藏着当年偷走的逍遥派心法。",
  "choices": [
    {
      "id": "promise_silence",
      "text": "我不会告诉如烟。让她父亲自己面对。",
      "effects": [
        {"type": "dao_heart_change", "value": 3},
        {"type": "flag_set", "target": "kept_liu_secret", "value": true}
      ],
      "next_node": "ACT2_E7_END"
    },
    {
      "id": "tell_liu",
      "text": "如烟有权知道真相。我会告诉她。",
      "effects": [
        {"type": "dao_heart_change", "value": -2},
        {"type": "flag_set", "target": "will_tell_liu_truth", "value": true}
      ],
      "next_node": "ACT2_E7_END"
    }
  ]
}
```

### 7.4 事件结算

**奖励**：
- 经验：4000
- 物品：慕容雪的雪莲玉佩复刻品（佩戴+灵识10%）
- 关系：慕容雪+25~50
- 道心：±5

**状态变更**：
- 重大真相标志：`knows_xuewuhen_truth`、`knows_liu_family_secret`
- 道德分支标志：`kept_liu_secret` / `will_tell_liu_truth`
- 慕容雪记忆觉醒度：100%
- 解锁支线："墨家血脉的现今下落"

**下一事件**：古战场遗迹

---

## 事件八：古战场遗迹

**游戏时长**：24-26小时
**场景**：万剑冢（三百年前飞升之战的核心战场）
**玩家状态**：筑基中期
**目标**：实地确认封印衰弱的征兆，引入玄机真人的真相曝光，触发云中鹤决定牺牲

### 8.1 抵达万剑冢

**场景描述**：
万剑冢位于九州最北的荒原。地表插满锈剑——传说这里曾有十万剑修陨落。空气中弥漫着浓烈的死气与剑意。玩家、柳如烟、慕容雪、铁无双、玄机真人、（远处暗中追来的）萧寒夜，几方人马同时抵达。

**环境叙事点**：
- 锈剑插得最密的地方，地面有一圈直径百丈的焦黑——这是当年封印的核心点
- 焦黑圈内，有八根青铜柱（封印支柱），其中三根已经断裂
- 慕容雪一踏入焦黑圈，雪莲玉佩立即剧烈震动
- 萧寒夜的身影在远处山脊上一闪——他没有靠近，只是远远看着

### 8.2 封印崩坏的征兆

**NPC: 玄机真人（震惊）**
```json
{
  "dialogue_id": "ACT2_E8_XUAN_001",
  "speaker": "xuan_ji_zhenren",
  "text": "（罕见地皱起眉）……八柱崩三。或许……不，必然。封印只剩五十年。",
  "choices": [
    {
      "id": "ask_consequence",
      "text": "前辈，封印一旦崩塌，会发生什么？",
      "effects": [],
      "next_node": "ACT2_E8_XUAN_002"
    },
    {
      "id": "ask_repair",
      "text": "有办法重新加固吗？",
      "effects": [],
      "next_node": "ACT2_E8_XUAN_003"
    }
  ]
}
```

**NPC: 玄机真人（揭示）**
```json
{
  "dialogue_id": "ACT2_E8_XUAN_002",
  "speaker": "xuan_ji_zhenren",
  "text": "封印之内，是上古一头'劫龙'——不是寻常妖兽，是上古十二劫的具现。它若出世，九州生灵涂炭。所谓'飞升之门'，其实就是封它的牢笼。",
  "choices": [
    {
      "id": "shock",
      "text": "（震惊）那……三百年前所谓的'飞升之战'……",
      "effects": [],
      "next_node": "ACT2_E8_XUAN_004"
    }
  ]
}
```

**NPC: 玄机真人（更深层真相）**
```json
{
  "dialogue_id": "ACT2_E8_XUAN_004",
  "speaker": "xuan_ji_zhenren",
  "text": "（叹息）三百年前，逍遥派一脉为了封印劫龙，付出了全派血祭的代价。然而正道历史，把这场壮举写成了'逍遥派妄图通敌飞升、被天剑盟击溃'……老道当年是亲历者之一。这桩谎言，我背了三百年。",
  "choices": [
    {
      "id": "ask_why_lie",
      "text": "为何要篡改历史？",
      "effects": [
        {"type": "flag_set", "target": "knows_history_lie", "value": true}
      ],
      "next_node": "ACT2_E8_XUAN_005"
    },
    {
      "id": "promise_witness",
      "text": "前辈，我会为逍遥派正名。",
      "effects": [
        {"type": "dao_heart_change", "value": 10},
        {"type": "flag_set", "target": "swore_to_rectify_history", "value": true}
      ],
      "next_node": "ACT2_E8_XUAN_005"
    }
  ]
}
```

**NPC: 玄机真人（最痛的真相）**
```json
{
  "dialogue_id": "ACT2_E8_XUAN_005",
  "speaker": "xuan_ji_zhenren",
  "text": "因为篡改史书的，就是天剑盟与玄霜宗的祖辈。逍遥派绝传，那卷封印心法落到了'墨'家手里。三百年的'正道盟主之位'，就是这么换来的。",
  "choices": [
    {
      "id": "silent_rage",
      "text": "（默默握紧拳头）",
      "effects": [
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E8_LIU_REACT"
    }
  ]
}
```

### 8.3 柳如烟的崩溃

**场景描述**：
柳如烟一直在旁倾听。她的脸色在玄机真人讲到"天剑盟祖辈"时，已经白如纸。

**NPC: 柳如烟（崩溃）**
```json
{
  "dialogue_id": "ACT2_E8_LIU_REACT",
  "speaker": "liu_ruyan",
  "text": "（剑穗从她手中滑落）不可能……我父亲……天剑盟……不可能……",
  "choices": [
    {
      "id": "comfort_liu_strong",
      "text": "（走过去，握住她颤抖的手）如烟，错的不是你。",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 30},
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E8_LIU_RESPONSE_A"
    },
    {
      "id": "tell_truth_hard",
      "text": "（沉重）如烟，事实就是事实。你应该面对。",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": 10},
        {"type": "dao_heart_change", "value": 3}
      ],
      "next_node": "ACT2_E8_LIU_RESPONSE_B"
    },
    {
      "id": "stay_silent",
      "text": "（保持距离，不发言）",
      "effects": [
        {"type": "relationship_change", "target": "liu_ruyan", "value": -5}
      ],
      "next_node": "ACT2_E8_LIU_RESPONSE_C"
    }
  ]
}
```

**NPC: 柳如烟（被支持后的觉醒）**
```json
{
  "dialogue_id": "ACT2_E8_LIU_RESPONSE_A",
  "speaker": "liu_ruyan",
  "text": "（深吸一口气，重新捡起剑穗）……谢你。古人云'子不教，父之过'。但若子已成人，便该走自己的路。这一次大比，我会代表自己，而不是天剑盟。",
  "choices": [
    {
      "id": "respect",
      "text": "（郑重一礼）柳道友。",
      "effects": [
        {"type": "flag_set", "target": "liu_becomes_independent", "value": true}
      ],
      "next_node": "ACT2_E8_END"
    }
  ]
}
```

### 8.4 远处的萧寒夜

**画面切换**：
山脊之上，萧寒夜远远看着这一幕。他身边没有人。月光下，他左眼角的疤再次抽动了一下——这次不是恨意，是一种更复杂的东西。他转身离去，留下一句无人听见的话：

```
萧寒夜（自语）："柳如烟……
                若你能脱离那个泥潭，
                我们才有可能……
                算了。"
```

### 8.5 事件结算

**奖励**：
- 经验：5500
- 物品：万剑冢锈剑碎片（炼器材料）×3、玄机真人传授"封印推演术"
- 关系：柳如烟+10~35、玄机真人+10、慕容雪+5
- 道心：+3~+13

**状态变更**：
- 关键标志：`knows_history_lie`、`liu_becomes_independent`、`swore_to_rectify_history`
- 五十年倒计时启动（剧情时钟）
- 解锁萧寒夜与柳如烟的"宿敌情结"支线

**下一事件**：云中鹤牺牲

---

## 事件九：云中鹤之死 — 剑骨传承

**游戏时长**：26-27小时
**场景**：玄霜宗云中鹤洞府 → 山门外决战之地
**玩家状态**：筑基中期
**目标**：师徒情感最高潮，云中鹤完成传承牺牲，引入血无痕正面接触（仍未完全揭露身份）

### 9.1 师父托付

**场景描述**：
万剑冢归来后第三日深夜。玩家被云中鹤召至洞府。云中鹤已经不能站立，盘膝坐在蒲团上，青霜剑横在膝上。他屏退所有人，只留玩家一人。

**NPC: 云中鹤（最后一课）**
```json
{
  "dialogue_id": "ACT2_E9_YUN_001",
  "speaker": "yun_zhonghe",
  "text": "（咳出一大口血，强笑）老夫……还有一件事，要交给你。坐近些。",
  "choices": [
    {
      "id": "kneel_close",
      "text": "（跪坐到师父面前，握住他的手）师父……",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 15}
      ],
      "next_node": "ACT2_E9_YUN_002"
    },
    {
      "id": "tearful",
      "text": "（眼眶发热）师父，您不要走。",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 20}
      ],
      "next_node": "ACT2_E9_YUN_002"
    }
  ]
}
```

**NPC: 云中鹤（传承剑骨）**
```json
{
  "dialogue_id": "ACT2_E9_YUN_002",
  "speaker": "yun_zhonghe",
  "text": "（从胸口取出一枚青色骨片，仅有指节大小）这是老夫的'剑骨'。修剑者一生唯有一枚，凝聚毕生剑意。今日传你。",
  "choices": [
    {
      "id": "refuse",
      "text": "师父，弟子不能受！这会折您寿元！",
      "effects": [
        {"type": "dao_heart_change", "value": 5},
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 10}
      ],
      "next_node": "ACT2_E9_YUN_003"
    },
    {
      "id": "kneel_accept",
      "text": "（双手接过，叩首三次）弟子……定不负师恩。",
      "effects": [
        {"type": "relationship_change", "target": "yun_zhonghe", "value": 20},
        {"type": "dao_heart_change", "value": 3}
      ],
      "next_node": "ACT2_E9_YUN_003"
    }
  ]
}
```

**NPC: 云中鹤（最后的嘱托）**
```json
{
  "dialogue_id": "ACT2_E9_YUN_003",
  "speaker": "yun_zhonghe",
  "text": "（轻笑，又压住咳嗽）老夫此身，本就是借天地多活的两百年。剑骨入你，老夫的剑意，便由你延续。记住——剑道如人生，重在一个'悟'字。生死，也是。",
  "choices": [
    {
      "id": "ask_xuewuhen_real",
      "text": "师父，关于血无痕……他是不是逍遥派的人？",
      "effects": [
        {"type": "flag_set", "target": "asked_yun_about_xuewuhen", "value": true}
      ],
      "next_node": "ACT2_E9_YUN_004"
    },
    {
      "id": "promise_truth",
      "text": "弟子定会查清飞升之谜的真相。",
      "effects": [
        {"type": "dao_heart_change", "value": 5},
        {"type": "flag_set", "target": "promise_to_yun_truth", "value": true}
      ],
      "next_node": "ACT2_E9_YUN_004"
    }
  ]
}
```

**NPC: 云中鹤（最后的话）**
```json
{
  "dialogue_id": "ACT2_E9_YUN_004",
  "speaker": "yun_zhonghe",
  "text": "（瞳孔渐散）……血无痕……不是你想的那样……他和老夫……年轻时是朋友……小心慕容雪……她的力量……飞升之谜……就……交给你了……",
  "choices": [
    {
      "id": "weep",
      "text": "（紧紧抱住师父的肩膀，无声落泪）",
      "effects": [
        {"type": "dao_heart_change", "value": 5}
      ],
      "next_node": "ACT2_E9_BATTLE_PREP"
    }
  ]
}
```

**关键暗示**：
- 云中鹤说"血无痕和老夫年轻时是朋友"——这是巨大伏笔。云中鹤其实是当年逍遥派的"外援"剑修，与血无痕共同布阵
- "小心慕容雪"——不是不让玩家保护她，而是警示她的力量觉醒后可能失控
- 云中鹤的死，是他主动选择——他知道魔修今夜会再袭，他要用剑骨传承换玩家未来的力量

### 9.2 山门外决战

**场景描述**：
就在云中鹤断气的瞬间，宗门示警阵再次响起——血无痕亲至。他独自一人立于山门之外，手中黑剑"无痕"出鞘三寸。玄霜宗主峰震动，玄机真人、柳如烟、铁无双、慕容雪同时冲出。

**NPC: 血无痕（首次正面登场）**
```json
{
  "dialogue_id": "ACT2_E9_XW_001",
  "speaker": "xue_wuhen",
  "text": "（声音如冰泉滴入空谷）本座今日前来，只取一物——云中鹤的剑骨。诸位让开，本座不愿多杀。",
  "choices": [
    {
      "id": "refuse_proud",
      "text": "（横剑挡在身前）剑骨在我体内。要拿，从我尸体上拿。",
      "effects": [
        {"type": "dao_heart_change", "value": 10},
        {"type": "flag_set", "target": "stood_against_xuewuhen", "value": true}
      ],
      "next_node": "ACT2_E9_XW_002A"
    },
    {
      "id": "ask_why",
      "text": "为何要剑骨？你与师父是什么关系？",
      "effects": [],
      "next_node": "ACT2_E9_XW_002B"
    }
  ]
}
```

**NPC: 血无痕（短暂的人性流露）**
```json
{
  "dialogue_id": "ACT2_E9_XW_002B",
  "speaker": "xue_wuhen",
  "text": "（瞳孔微缩，声音骤冷）……云中鹤死了？什么时候？",
  "choices": [
    {
      "id": "tell_him",
      "text": "（直视）一炷香之前。他临终之言，是说你不是我想的那样。",
      "effects": [
        {"type": "flag_set", "target": "told_xw_yun_dead", "value": true}
      ],
      "next_node": "ACT2_E9_XW_003"
    }
  ]
}
```

**NPC: 血无痕（罕见的失态）**
```json
{
  "dialogue_id": "ACT2_E9_XW_003",
  "speaker": "xue_wuhen",
  "text": "（黑剑慢慢归鞘，沉默良久）……今夜，本座不来了。告诉云道兄……来生……（话未说完，已化作一道黑影远去）",
  "choices": [
    {
      "id": "watch",
      "text": "（沉默目送，记住他的剑意）",
      "effects": [
        {"type": "flag_set", "target": "witnessed_xw_humanity", "value": true},
        {"type": "dao_heart_change", "value": 0, "note": "中性观察"}
      ],
      "next_node": "ACT2_E9_END"
    }
  ]
}
```

### 9.3 师徒情谊的延伸

**场景描述**：
血无痕离去后，玄机真人走到玩家身边，看着玩家手中的青霜剑——这是云中鹤的剑，从今日起属于玩家。

**NPC: 玄机真人**
```json
{
  "dialogue_id": "ACT2_E9_XUAN_001",
  "speaker": "xuan_ji_zhenren",
  "text": "（轻叹）云道友走了。或许，他也走得安心。剑骨入你，便是他在世的延续。三日后，给他立个衣冠冢吧。",
  "choices": [
    {
      "id": "vow",
      "text": "（握紧青霜剑）弟子明白。",
      "effects": [
        {"type": "item_give", "target": "qingshuang_sword", "value": 1},
        {"type": "skill_unlock", "target": "yun_legacy_sword_art", "value": true}
      ],
      "next_node": "ACT2_E9_FINAL"
    }
  ]
}
```

### 9.4 事件结算

**奖励**：
- 经验：6000
- 物品：青霜剑（云中鹤遗物，传家剑）、剑骨碎片（永久属性+15%）
- 关系：所有同伴+10（共同悼念）
- 道心：+15~+25
- 技能：云中鹤遗传剑诀"鹤舞九霄"（被动+主动各一）

**状态变更**：
- 师承传承完成
- 标志：`yun_zhonghe_dead`、`stood_against_xuewuhen`、`witnessed_xw_humanity`
- 解锁主线："寻找血无痕的真相"
- 五十年倒计时进入下一阶段

**下一事件**：筑基突破

---

## 事件十：筑基突破 — 三种道路

**游戏时长**：27-29小时
**场景**：玄霜宗闭关洞府 / 万剑冢 / 冷月崖（三选一）
**玩家状态**：筑基中期 → 筑基后期
**目标**：通过筑基突破方式，强化玩家的"道"的选择，将道心系统具象化

### 10.1 突破前的咨询

**场景描述**：
云中鹤剑骨入体后，玩家修为暴涨，但需要一个稳定的环境完成筑基中后期的关键突破。玄机真人提供三个建议——

**NPC: 玄机真人**
```json
{
  "dialogue_id": "ACT2_E10_XUAN_001",
  "speaker": "xuan_ji_zhenren",
  "text": "突破之地，决定道之根本。或在洞府静修，或往万剑冢吸收锈剑剑意，或上冷月崖直面孤独。三条路，无对错，唯有'你的道'。",
  "choices": [
    {
      "id": "path_safe",
      "text": "洞府闭关（稳健）",
      "effects": [
        {"type": "stat_boost", "target": "defense", "value": 25},
        {"type": "stat_boost", "target": "hp", "value": 200},
        {"type": "flag_set", "target": "breakthrough_safe", "value": true}
      ],
      "next_node": "ACT2_E10_SAFE"
    },
    {
      "id": "path_sword",
      "text": "万剑冢吸收剑意（激进）",
      "effects": [
        {"type": "stat_boost", "target": "attack", "value": 40},
        {"type": "stat_boost", "target": "critical", "value": 15},
        {"type": "flag_set", "target": "breakthrough_aggressive", "value": true}
      ],
      "next_node": "ACT2_E10_SWORD"
    },
    {
      "id": "path_solitude",
      "text": "冷月崖直面孤独（道心）",
      "effects": [
        {"type": "stat_boost", "target": "spirit", "value": 35},
        {"type": "dao_heart_change", "value": 10},
        {"type": "flag_set", "target": "breakthrough_dao", "value": true},
        {"type": "skill_unlock", "target": "dao_heart_jutsu", "value": true}
      ],
      "next_node": "ACT2_E10_SOLITUDE"
    }
  ]
}
```

### 10.2 选择"冷月崖直面孤独"的特殊事件

**场景描述**：
玩家上冷月崖打坐三日。第三日子时，萧寒夜再次出现（他的洞察力让他知道玩家在这里）。

**NPC: 萧寒夜（再次现身）**
```json
{
  "dialogue_id": "ACT2_E10_XIAO_001",
  "speaker": "xiao_hanye",
  "text": "（站在三步外，不打扰）你师父死了。你师妹的真相也知道了。柳如烟跟你父辈反目了。道友，你的道，还守得住吗？",
  "choices": [
    {
      "id": "answer_strong",
      "text": "正因这一切，我才更知道自己要走什么路。",
      "effects": [
        {"type": "dao_heart_change", "value": 10}
      ],
      "next_node": "ACT2_E10_XIAO_002"
    },
    {
      "id": "answer_dark",
      "text": "（沉默）有时候，我也开始怀疑'正道'二字。",
      "effects": [
        {"type": "dao_heart_change", "value": -5},
        {"type": "relationship_change", "target": "xiao_hanye", "value": 10}
      ],
      "next_node": "ACT2_E10_XIAO_003"
    },
    {
      "id": "answer_independent",
      "text": "我不再属于哪一道。我只走我自己看见的道。",
      "effects": [
        {"type": "dao_heart_change", "value": 5},
        {"type": "flag_set", "target": "declared_independent_dao", "value": true}
      ],
      "next_node": "ACT2_E10_XIAO_004"
    }
  ]
}
```

### 10.3 突破时刻

**所有路径共通**：
玩家在选定地点完成筑基中期→后期的关键飞跃。雷云聚顶，三道天劫降下，被玩家以选定的"道"逐一化解。

**过场旁白**：
```
旁白：天雷散去时，你睁开眼。
      世界比以往任何时候都清晰。
      你能感到剑骨在体内嗡鸣，
      能感到云中鹤的剑意已与你一体。
      你已不是那个青云镇的少年。
      你是——一个真正的筑基修士。
      但更重要的是——
      你终于知道，自己要去哪里。
```

### 10.4 事件结算

**奖励**：
- 经验：8000
- 修为：筑基中期 → 筑基后期
- 属性：根据三选一获得对应大幅加成
- 道心：+0~+15

**状态变更**：
- 关键路径标志：三个breakthrough_*互斥
- 标志（条件）：`declared_independent_dao`
- 战斗系统：解锁"剑骨爆发"必杀技

**下一事件**：第二幕终章——九州之门

---

## 事件十一：第二幕终章 — 九州之门

**游戏时长**：29-30小时
**场景**：玄霜宗议事大殿 → 九州之门（万剑冢深处）
**玩家状态**：筑基后期
**目标**：第二幕收束，正式分出三条主线分支（正道/魔道/独立），为Act 3奠基

### 11.1 三方齐聚

**场景描述**：
筑基突破后第七日。玄霜宗议事大殿。玄机真人召集所有人，宣布万剑冢的封印已经只剩五十年——他们必须立即进入"九州之门"（封印中心），亲眼确认劫龙的状态。

**核心冲突**：
- **柳如烟**（已脱离天剑盟独立行动）：主张正道集结，共破劫龙
- **萧寒夜**（突然现身议事殿，无人能阻）：主张让真相曝光，让"虚伪的正道"自食恶果
- **玄机真人**：主张三方暂时合作，进入九州之门
- **慕容雪**：作为前世逍遥派的"钥匙"，她必须亲自去
- **铁无双**：永远跟着玩家

### 11.2 萧寒夜的入场

**NPC: 萧寒夜（直入议事殿）**
```json
{
  "dialogue_id": "ACT2_E11_XIAO_001",
  "speaker": "xiao_hanye",
  "text": "（推门而入，不躬不礼）诸位道友，本座今日是来邀请——而不是请求——的。九州之门，本座也要去。",
  "choices": [
    {
      "id": "accept_alliance",
      "text": "（点头）今日危局，确需放下成见。",
      "effects": [
        {"type": "dao_heart_change", "value": 0},
        {"type": "relationship_change", "target": "xiao_hanye", "value": 10}
      ],
      "next_node": "ACT2_E11_LIU_REACT"
    },
    {
      "id": "reject_pride",
      "text": "（拔剑）魔修岂能与正道同行？",
      "effects": [
        {"type": "dao_heart_change", "value": 5},
        {"type": "relationship_change", "target": "xiao_hanye", "value": -10}
      ],
      "next_node": "ACT2_E11_TENSION"
    },
    {
      "id": "ask_terms",
      "text": "你的条件是什么？",
      "effects": [],
      "next_node": "ACT2_E11_XIAO_002"
    }
  ]
}
```

### 11.3 玄机真人的最后决断

**NPC: 玄机真人（罕见严肃）**
```json
{
  "dialogue_id": "ACT2_E11_XUAN_FINAL",
  "speaker": "xuan_ji_zhenren",
  "text": "（站起身，目光扫过众人）老道决定——九州之门，三方同行。但'三方'是何意？由这位道友决定。",
  "choices": [
    {
      "id": "final_zhengdao",
      "text": "正道为主：柳如烟为先锋，萧寒夜为协助",
      "effects": [
        {"type": "dao_heart_change", "value": 20},
        {"type": "flag_set", "target": "act2_end_zhengdao", "value": true},
        {"type": "relationship_change", "target": "liu_ruyan", "value": 30},
        {"type": "relationship_change", "target": "xiao_hanye", "value": -5}
      ],
      "next_node": "ACT2_E11_END_A"
    },
    {
      "id": "final_modao",
      "text": "重新审视正道：萧寒夜为主导，柳如烟独立配合",
      "effects": [
        {"type": "dao_heart_change", "value": -20},
        {"type": "flag_set", "target": "act2_end_modao", "value": true},
        {"type": "relationship_change", "target": "xiao_hanye", "value": 30},
        {"type": "relationship_change", "target": "liu_ruyan", "value": -10}
      ],
      "next_node": "ACT2_E11_END_B"
    },
    {
      "id": "final_independent",
      "text": "独立第三路：我自行率队，柳萧为后援",
      "effects": [
        {"type": "dao_heart_change", "value": 0},
        {"type": "flag_set", "target": "act2_end_independent", "value": true},
        {"type": "relationship_change", "target": "liu_ruyan", "value": 15},
        {"type": "relationship_change", "target": "xiao_hanye", "value": 15},
        {"type": "skill_unlock", "target": "independent_dao_path", "value": true}
      ],
      "next_node": "ACT2_E11_END_C"
    }
  ]
}
```

### 11.4 三种Act 2收束

**结局A：正道主导**
- 柳如烟与玩家肩并肩走在最前，白虹剑出鞘三寸
- 萧寒夜默默跟在最后，眼神难辨
- 慕容雪小声对玩家说："道友，我前世也曾这样并肩走过。要记得——并肩，未必同心。"
- 铁无双：兄弟，老子永远在你身后！

**结局B：魔道主导（重新审视）**
- 萧寒夜走在最前，目光沉静
- 柳如烟独自一人远远跟着，剑穗紧握
- 玄机真人对玩家说："你选的是更难的一条路。不是因为你倒向了魔，而是因为你不再相信任何'既定的正'。"
- 慕容雪眼神复杂——她看见了血无痕年轻时的影子

**结局C：独立第三路**
- 玩家走在最前，云中鹤的剑骨在体内嗡鸣
- 柳如烟与萧寒夜各走一侧，互相不言
- 慕容雪走在玩家身后半步：道友，你走的是逍遥派当年想走的路。
- 铁无双（拍肩）：兄弟，你这条路，老子不懂。但俺跟着。

### 11.5 第二幕尾声

**最终过场旁白**：
```
旁白：你站在九州之门前。
      门后，是三百年前的真相。
      是劫龙的低吼。
      是飞升的终极秘密。
      是你将要成为的——那个人。
      
      你深吸一口气。
      推开了门。
      
      （第二幕完）
```

### 11.6 事件结算

**奖励**：
- 经验：10000（Act 2总收束奖励）
- 物品：根据三选一获得对应主线钥匙（正道令/魔道令/独立令）
- 关系：剧烈变动
- 道心：±20

**状态变更**：
- **Act 3核心分支锚点**：`act2_end_zhengdao` / `act2_end_modao` / `act2_end_independent`（互斥）
- 解锁第三幕：飞升真相
- 永久标志：本次选择决定Act 3可达结局（6+ 多结局）

---

## 第二幕收束

### Act 2 核心数据汇总

| 指标 | 数值 |
|------|------|
| 总事件数 | 11 |
| 总选择点 | ~50 |
| 道心变动范围 | -57 ~ +118 |
| 关键标志总数 | 32 |
| 解锁支线 | 6 |
| Act 3分支锚点 | 3 |

### 关键伏笔清单（Act 2 → Act 3）

1. **血无痕的真实身份**：逍遥派前任掌门师弟，三百年来守护封印
2. **慕容雪的转世真相**：前世逍遥派掌门，封印备用钥匙
3. **天剑盟柳家的祖辈罪行**：与背叛者墨家结盟篡改史书
4. **云中鹤的过往**：年轻时是逍遥派外援，与血无痕是朋友
5. **劫龙封印**：五十年倒计时，三柱已断
6. **萧寒夜的真正身份**：尚未完全揭露，疑点重重（暗示是某正道大族遗孤）
7. **柳如烟的剑心体质**：在Act 3中将与劫龙产生特殊共鸣
8. **铁无双的隐藏身世**：尚未揭露（伏笔到Act 3）

---

## 角色弧线小结

### 玩家角色
- **境界**：炼气后期 → 筑基后期
- **关键成长点**：从被动跟随师父，到主动选择道路，到独立面对真相
- **道心轨迹**：根据玩家选择，可走向正道/魔道/独立三条主线

### 云中鹤（完结）
- 第二幕最大牺牲者
- 完成"传承"母题：旧时代的剑修，把希望交给了下一代
- 死亡前完成对玩家的"剑骨传承"与"真相提示"

### 柳如烟（重大成长）
- 从"天剑盟少主"到"独立剑修"
- 完成"觉醒"弧线：发现父辈的罪行后，没有崩溃，而是选择走自己的路
- 与玩家关系：从盟友到挚友/恋人/宿敌（取决于选择）

### 萧寒夜（深度铺垫）
- 从"魔教反派"到"复杂的复仇者"
- 真实背景部分揭露（10岁灭门，但更深的真相留到Act 3）
- 与柳如烟的"宿敌+知音"关系成型

### 慕容雪（完成觉醒）
- 从"沉默师妹"到"前世逍遥派掌门转世"
- 雪莲玉佩封印彻底解除
- 在Act 3将成为关键决策者

### 铁无双（情感支柱）
- 永远的兄弟
- 在Act 3将揭露真实身世（暗示是某皇族血脉）
- 第二幕中是玩家最稳定的情感锚点

### 玄机真人（揭露真相者）
- 从神秘智者到三百年罪人之一
- 主动揭露天剑盟与玄霜宗祖辈的罪行
- 在Act 3将面临"自首还是赎罪"的终极选择

### 血无痕（重新定义）
- 从"魔头"到"逍遥派最后的守护者"
- 第二幕末段首次正面接触，展现人性
- 在Act 3将与玩家完成最终对话

---

## 与gameplay系统的接口

### 1. 战斗系统
- E3引入"战术选择"系统（攻击/防御/盟友建议）
- E9云中鹤剑骨传承后，玩家获得"剑骨爆发"必杀技
- E10筑基突破后，三种属性侧重分化

### 2. 对话系统
- 全部11个事件均使用JSON对话树（已存在）
- 选择影响道心、关系、关键标志

### 3. 道心系统
- E6（±15）、E11（±20）是两大锚点事件
- 范围：-100 ~ +100
- 三条主线分支门槛：+20（正道）/ -20（魔道）/ -19 ~ +19（独立）

### 4. 关系系统
- 7个核心角色，每人有独立关系数值
- 关系达到一定阈值解锁专属支线

### 5. 装备/物品系统
- 关键道具：青霜剑（E9获得）、剑骨碎片（E9获得）、雪莲玉佩复刻（E7获得）
- 主线钥匙：E11根据三选一获得对应令牌

### 6. 修炼系统
- E10提供三种突破路径
- 剑骨碎片永久属性+15%

---

## 写作意图

第二幕的核心写作目标是让玩家从"看故事的人"变成"故事的一部分"。Act 1让玩家"认识"修真界，Act 2让玩家"质疑"修真界。

通过云中鹤的死亡、玄机真人的真相曝光、柳如烟的家族崩塌、慕容雪的前世觉醒，玩家被迫面对一个核心命题：**"正道"二字，从来不是天生的。它是被人定义的。而你，要不要接受这个被人定义的"正"？**

每个角色都被设计成有"两面性"——
- 云中鹤的"师父"身份背后，是他对三百年前真相的隐瞒
- 柳如烟的"正道少主"光环背后，是她父辈的罪行
- 萧寒夜的"魔修"标签背后，是他被诬陷的家族
- 慕容雪的"沉默师妹"外表背后，是前世的悲壮
- 玄机真人的"智者"面容背后，是三百年的愧疚
- 血无痕的"反派"形象背后，是逍遥派最后的守护者

唯有铁无双是真正"清澈"的——这是设计上的留白，让玩家在所有人都"有秘密"的时候，至少有一个真正纯粹的伙伴。

第三幕，将把这一切谎言、真相、爱恨、宿命，推向最终的清算。
