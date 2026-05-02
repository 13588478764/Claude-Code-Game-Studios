# 对话系统 (Dialogue System)

> **Status**: In Design
> **Author**: 系统设计师 + AI助手
> **Last Updated**: 2026-05-02
> **Implements Pillar**: 自由探索与发现、仙缘驱动的成长
> **Creative Director Review (CD-GDD-ALIGN)**: Pending

## Overview

对话系统是《武侠奇遇录》的核心叙事机制，负责处理玩家与NPC之间的所有交互对话。该系统通过分支对话树、条件判断和效果触发，让玩家的每个选择都能影响角色关系、道心倾向和剧情走向。

**技术层面**：对话系统基于树状数据结构，每个对话节点包含文本、选择分支、触发条件和后续效果。系统从对话数据库读取结构化的对话内容，通过对话树管理系统处理分支逻辑，并通过对话效果系统将玩家选择转化为游戏状态变化（关系值、道心值、任务触发等）。

**玩家体验层面**：玩家通过对话与修真世界中的各路修士交流，每个选择都体现角色性格和修真道路的抉择。正道选择可能获得名门正派的好感，魔道选择则可能开启禁忌功法的传承。对话不仅推动剧情，更是塑造玩家独特修真之路的关键机制。

**修真特色**：对话系统深度整合修真世界观，NPC会根据玩家的境界、道心值和关系等级提供不同的对话内容。高境界修士可能传授绝世功法，而道心偏魔的玩家则会解锁魔道NPC的隐藏剧情。系统支持100+种仙缘事件的叙事变体，确保每次游玩都有新的发现。

## Player Fantasy

**核心幻想：成为修真世界的社交大师，用言语和智慧影响江湖格局**

当玩家与NPC对话时，他们不仅仅是在阅读文字——他们在做出关键的人生抉择。每一次对话都是一次道心的考验，每一个选择都可能改变命运的轨迹。

**玩家应该感受到**：

1. **选择的分量**：当面对云中鹤的剑道传承邀请时，玩家知道接受意味着踏上正道之路，拒绝则可能错失绝世剑法。这不是简单的"是/否"，而是"我要成为什么样的修士"。

2. **关系的真实**：通过数十次对话积累的好感，让柳如烟从陌生人变成挚友甚至恋人。玩家能感受到关系的逐步加深，每次见面都有新的话题，每个选择都让关系更进一步或疏远一分。

3. **道路的分歧**：正道NPC会因玩家的魔道倾向而冷淡，魔道NPC则会因玩家的正义之举而敌视。玩家的每个选择都在塑造自己的修真之路，没有"正确答案"，只有"我的选择"。

4. **发现的惊喜**：当玩家在某个不起眼的山洞遇到隐世高人，通过巧妙的对话选择获得上古传承时，那种"我发现了别人不知道的秘密"的成就感是无可替代的。

**参考体验**：
- 《巫师3》中与叶奈法、特莉丝的关系选择——每个选择都有分量
- 《质量效应》中的道德选择系统——正邪分明但不简单
- 《极乐迪斯科》中的对话技能检定——对话本身就是gameplay

**反面案例**（我们要避免的）：
- ❌ 对话只是"按A继续"的文字墙
- ❌ 选择没有真实后果，只是"换个说法"
- ❌ NPC像机器人一样重复相同的台词

## Detailed Design

### Core Rules

#### 1. 对话触发规则

**触发方式**：
1. **玩家主动触发**：玩家走近NPC并按交互键（E键）
2. **NPC主动触发**：当满足特定条件时，NPC主动找玩家对话（关系事件、任务触发）
3. **剧情自动触发**：主线剧情节点自动播放对话

**触发条件检查**：
- 每个对话节点可设置多个触发条件（Condition数组）
- 条件类型包括：境界等级、关系值、道心值、任务状态、物品持有、时间/地点
- 所有条件必须同时满足（AND逻辑）才能触发对话
- 如果条件不满足，显示默认对话或跳过该节点

#### 2. 对话节点结构

每个对话节点（DialogueNode）包含以下核心元素：

```gdscript
class DialogueNode:
    var id: String              # 唯一标识符，格式：SCENE_NPC_NUMBER
    var speaker: String         # 说话者ID（NPC或玩家）
    var text: String            # 对话文本（支持{变量}占位符）
    var choices: Array[Choice]  # 玩家选择项（可选，空数组表示自动继续）
    var conditions: Array[Condition]  # 显示条件
    var effects: Array[Effect]  # 对话后自动触发的效果
    var next_node: String       # 下一个节点ID（无选择时使用）
    var audio_cue: String       # 语音文件路径（可选）
    var emotion: String         # 角色情绪标签（影响头像表情）
    var priority: int           # 对话优先级（1-5，5最高，用于队列排序）
    var timeout: int            # 选择超时时间（秒，0表示无超时，仅特定节点使用）
```

**对话循环检测算法**：

为防止对话树形成无限循环，系统使用访问集合（visited set）追踪已访问节点：

```gdscript
class DialogueTreeManager:
    var visited_nodes: Dictionary = {}  # {dialogue_id: {node_id: visit_count}}
    const MAX_VISITS_PER_NODE = 3       # 单个节点最多访问3次（允许合法循环如返回主菜单）
    const MAX_TOTAL_NODES = 100         # 单次对话最多访问100个节点
    
    func check_loop(dialogue_id: String, node_id: String) -> bool:
        # 初始化对话访问记录
        if not visited_nodes.has(dialogue_id):
            visited_nodes[dialogue_id] = {}
        
        var dialogue_visits = visited_nodes[dialogue_id]
        
        # 检查总节点数
        if dialogue_visits.size() >= MAX_TOTAL_NODES:
            push_error("对话循环检测：访问节点数超过%d，强制结束" % MAX_TOTAL_NODES)
            return true  # 检测到循环
        
        # 检查单节点访问次数
        if not dialogue_visits.has(node_id):
            dialogue_visits[node_id] = 0
        
        dialogue_visits[node_id] += 1
        
        if dialogue_visits[node_id] > MAX_VISITS_PER_NODE:
            push_error("对话循环检测：节点%s访问次数超过%d次" % [node_id, MAX_VISITS_PER_NODE])
            return true  # 检测到循环
        
        return false  # 未检测到循环
    
    func reset_visited_nodes(dialogue_id: String):
        if visited_nodes.has(dialogue_id):
            visited_nodes.erase(dialogue_id)
```

**循环检测规则**：
1. 单个节点最多访问3次（允许"返回主菜单"等合法循环）
2. 单次对话最多访问100个不同节点
3. 检测到循环时立即结束对话并记录错误日志
4. 对话结束后清空访问记录

#### 3. 玩家选择规则

**选择显示**：
- 每个对话节点最多显示4个选择项
- 选择项按定义顺序从上到下显示
- 不满足条件的选择项显示为灰色且不可选
- 如果所有选择都不可用，自动跳转到next_node

**选择结构**：
```gdscript
class Choice:
    var id: String              # 选择ID
    var text: String            # 选择文本（最多60字符）
    var conditions: Array[Condition]  # 显示条件
    var effects: Array[Effect]  # 选择后效果
    var next_node: String       # 跳转节点ID
    var icon: String            # 选择图标（可选，如正道/魔道标记）
```

**选择后处理**：
1. 执行选择的所有效果（Effect数组）
2. 跳转到next_node指定的对话节点
3. 如果next_node为空或"END"，结束对话

#### 4. 条件判断规则

**条件类型**：
```gdscript
class Condition:
    var type: String      # 条件类型
    var target: String    # 目标对象
    var operator: String  # 比较运算符：>=, <=, ==, !=, >, <
    var value: Variant    # 比较值
```

**支持的条件类型**：
- `realm_level`: 玩家境界等级（1-90，对应炼气初期到化神后期）
- `relationship`: 与特定NPC的关系值（-100到+100）
- `dao_heart`: 玩家道心值（-100到+100）
- `quest_status`: 任务状态（not_started, active, completed, failed）
- `item_count`: 物品数量
- `flag`: 全局标志位（true/false）
- `time`: 游戏内时间或现实时间
- `location`: 玩家当前位置

**条件示例**：
```json
{
  "type": "realm_level",
  "target": "player",
  "operator": ">=",
  "value": 23
}
// 玩家境界达到筑基初期（Lv23）才能看到此选择
```

**境界威压机制**（Realm Pressure）：

修真世界观中,境界差距会产生威压效果,影响对话选择的风险和后果,但**不会完全禁用选择**,以保持"选择的分量"这一核心幻想。

**威压规则**：
1. **境界差距计算**：`realm_gap = npc_realm_level - player_realm_level`
2. **威压阈值**：境界差距 > 30级时触发威压效果
3. **威压效果**（不禁用选择,而是增加风险）：
   - **高风险选择**：质疑、反驳、谈判等选择仍然可用,但会显示警告标记(⚠️)和风险提示
   - **负面后果加重**：选择这些高风险选项会导致更严重的关系值下降(双倍惩罚)
   - **谎言识破率提升**：高境界NPC更容易看穿玩家的谎言选择(见下方谎言识破机制)
   - **态度影响**：NPC对低境界玩家的态度更加傲慢或轻视(对话文本变化)
   - **低境界专属选择**：提供"恭敬请教"、"拜师学艺"等低境界专属选择,让玩家有更合适的选项

**威压条件类型**：
```gdscript
// 新增条件类型 - 用于显示低境界专属选择
{
  "type": "realm_gap",
  "target": "npc_id",
  "operator": ">",
  "value": 30
}
// 当境界差距 > 30级时显示此选择(如"恭敬请教")
```

**高风险选择标记**：
```gdscript
class Choice:
    # ... 现有字段 ...
    var is_high_risk: bool = false      # 是否为高风险选择(境界差距大时)
    var risk_multiplier: float = 2.0    # 风险倍率(关系值惩罚翻倍)
```

**谎言识破机制**（确定性设计 + UI透明度）：

为避免save-scumming并保持"选择的分量"幻想,谎言识破机制采用**确定性阈值**而非随机概率:

```gdscript
func check_lie_detection(choice: Choice, npc: NPC) -> bool:
    # 仅对标记为"谎言"的选择进行检测
    if not choice.is_lie:
        return false
    
    var realm_gap = npc.realm_level - player.realm_level
    var deception_skill = player.deception_skill
    
    # 确定性判定：境界差距 - 欺诈技能 > 阈值则必定识破
    var detection_threshold = 50  # 基础阈值
    var detection_score = realm_gap - deception_skill
    
    # 确定性规则（无随机性）：
    # - 境界差距 > 50级 且 欺诈技能 < 10: 必定识破
    # - 境界差距 ≤ 30级: 必定不识破
    # - 中间区域: 根据detection_score确定性判定
    
    if realm_gap <= 30:
        return false  # 境界差距小,必定不识破
    elif detection_score >= detection_threshold:
        return true   # 差距过大,必定识破
    else:
        return false  # 玩家欺诈技能足够高,成功欺骗
    
# 谎言被识破的后果
func on_lie_detected(npc: NPC):
    # 大幅降低关系值
    modify_relationship(npc.id, -30)
    # 触发特殊对话分支
    jump_to_node("LIE_DETECTED_BRANCH")

# UI显示：在选择项上明确标注风险
func get_lie_detection_warning(choice: Choice, npc: NPC) -> String:
    if not choice.is_lie:
        return ""
    
    var realm_gap = npc.realm_level - player.realm_level
    var deception_skill = player.deception_skill
    var detection_score = realm_gap - deception_skill
    
    if realm_gap <= 30:
        return "✓ 境界相近,不会被识破"
    elif detection_score >= 50:
        return "⚠️ 警告：境界差距过大,此谎言必定被识破！"
    else:
        return "✓ 欺诈技能足够,可以成功欺骗"
```

**确定性规则表**：

| 境界差距 | 欺诈技能 | 结果 | UI提示 |
|---------|---------|------|--------|
| ≤ 30级 | 任意 | 必定不识破 | ✓ 境界相近,不会被识破 |
| 31-50级 | ≥ (差距-50) | 必定不识破 | ✓ 欺诈技能足够,可以成功欺骗 |
| 31-50级 | < (差距-50) | 必定识破 | ⚠️ 警告：境界差距过大,此谎言必定被识破！ |
| > 50级 | < 10 | 必定识破 | ⚠️ 警告：境界差距过大,此谎言必定被识破！ |
| > 50级 | ≥ 10 | 根据公式 | 根据detection_score判定 |

**设计优势**：
1. **完全确定性**：相同条件下结果永远相同,避免save-scumming
2. **UI透明度**：玩家在选择前就知道后果,符合"选择的分量"
3. **技能价值**：欺诈技能有明确的作用（降低识破风险）
4. **平衡性**：境界差距小时可以安全撒谎,差距大时需要高技能

**选择数据结构扩展**：
```gdscript
class Choice:
    # ... 现有字段 ...
    var is_lie: bool = false           # 是否为谎言选择
    var is_high_risk: bool = false     # 是否为高风险选择(境界差距大时显示警告)
    var risk_multiplier: float = 2.0   # 风险倍率(用于计算惩罚)
    var low_realm_only: bool = false   # 是否为低境界专属选择
```

**实现示例**：
```json
{
  "id": "choice_challenge",
  "text": "⚠️ 前辈此言差矣，晚辈不敢苟同",
  "icon": "challenge",
  "is_high_risk": true,
  "risk_multiplier": 2.0,
  "conditions": [],
  "effects": [
    {"type": "relationship_change", "target": "yunzhonghe", "value": -10}
  ],
  "next_node": "NODE_CHALLENGE",
  "risk_warning": "境界差距过大,此选择可能导致严重后果"
},
{
  "id": "choice_respectful",
  "text": "晚辈受教,还请前辈不吝赐教",
  "icon": "cultivation",
  "low_realm_only": true,
  "conditions": [
    {
      "type": "realm_gap",
      "target": "yunzhonghe",
      "operator": ">",
      "value": 30
    }
  ],
  "effects": [
    {"type": "relationship_change", "target": "yunzhonghe", "value": 5}
  ],
  "next_node": "NODE_TEACHING"
}
```

#### 5. 效果执行规则

**效果类型**：
```gdscript
class Effect:
    var type: String      # 效果类型
    var target: String    # 目标对象
    var value: Variant    # 效果值
    var delay: float      # 延迟执行时间（秒）
```

**支持的效果类型**：
- `relationship_change`: 改变关系值（±5到±20，受max_relationship_delta限制）
- `dao_heart_change`: 改变道心值（±5到±20，受max_dao_heart_delta限制）
- `quest_trigger`: 触发任务（任务ID）
- `quest_complete`: 完成任务（任务ID）
- `item_give`: 给予物品（物品ID和数量）
- `item_remove`: 移除物品（物品ID和数量）
- `flag_set`: 设置全局标志位（标志名和值）
- `skill_unlock`: 解锁技能（技能ID）
- `battle_trigger`: 触发战斗（敌人ID）
- `teleport`: 传送玩家（位置坐标）
- `cutscene_play`: 播放过场动画（动画ID）

**效果执行顺序**：
1. 按Effect数组顺序依次执行
2. 如果设置了delay，等待指定时间后执行
3. 所有效果执行完毕后，才跳转到下一个节点

**效果值范围限制**：
- 关系值变化：单次效果的value必须在±5到±max_relationship_delta范围内（默认±20）
- 道心值变化：单次效果的value必须在±5到±max_dao_heart_delta范围内（默认±20）
- 超出范围的值会被自动截断到安全范围
- 最终值会被clamp到[-100, 100]范围内

**对话事务机制**（Transaction Pattern）：

为确保对话中途退出时的数据一致性，系统使用事务模式管理效果执行：

```gdscript
class DialogueTransaction:
    var transaction_id: String      # 事务ID
    var dialogue_id: String         # 对话ID
    var executed_effects: Array     # 已执行的效果列表
    var rollback_data: Dictionary   # 回滚数据（效果执行前的状态）
    var status: String              # 事务状态：PENDING, COMMITTED, ROLLED_BACK
    
    func begin_transaction():
        # 开始新事务，保存当前游戏状态
        rollback_data = {
            "relationships": {},  # 保存所有相关NPC的关系值
            "dao_heart": player.dao_heart,
            "inventory": player.inventory.duplicate(),
            "flags": global_flags.duplicate()
        }
        status = "PENDING"
    
    func execute_effect(effect: Effect):
        # 执行效果并记录
        executed_effects.append(effect)
        # 实际执行效果的代码...
    
    func commit():
        # 提交事务，清空回滚数据
        status = "COMMITTED"
        rollback_data.clear()
    
    func rollback():
        # 回滚所有已执行的效果
        status = "ROLLED_BACK"
        # 恢复关系值
        for npc_id in rollback_data.relationships:
            relationship_system.set_relationship(npc_id, rollback_data.relationships[npc_id])
        # 恢复道心值
        player.dao_heart = rollback_data.dao_heart
        # 恢复物品（移除新增的，归还移除的）
        player.inventory = rollback_data.inventory.duplicate()
        # 恢复标志位
        global_flags = rollback_data.flags.duplicate()
```

**事务处理规则**：
1. 对话开始时创建新事务（begin_transaction）
2. 每个效果执行前保存当前状态到rollback_data
3. 对话正常结束时提交事务（commit）
4. 对话中途退出时回滚事务（rollback）
5. 已触发的任务和战斗不会回滚（这些是不可逆操作）
6. 过场动画和传送不会回滚（这些是场景级操作）

#### 6. 对话类型规则

**主线对话**（type: "main"）：
- 推动主线剧情，不可跳过
- 通常包含重要选择，影响剧情走向
- 完成后设置剧情进度标志

**支线对话**（type: "side"）：
- 提供额外信息和任务
- 可重复触发（根据条件）
- 完成后可能解锁新的对话选项

**闲聊对话**（type: "idle"）：
- 增加世界真实感
- 无gameplay影响，可随时跳过
- 根据玩家进度和关系值动态变化

**战斗对话**（type: "battle"）：
- Boss战和关键战斗的台词
- 在战斗特定阶段触发
- 可能触发战斗事件（召唤援军、阶段转换）

#### 7. 对话重复处理规则

为避免NPC像机器人一样重复相同台词,系统提供多层次的对话变体机制:

**对话完成状态追踪**：

```gdscript
class DialogueCompletionTracker:
    var completed_dialogues: Dictionary = {}  # {dialogue_id: completion_count}
    
    func mark_dialogue_completed(dialogue_id: String):
        if not completed_dialogues.has(dialogue_id):
            completed_dialogues[dialogue_id] = 0
        completed_dialogues[dialogue_id] += 1
    
    func get_completion_count(dialogue_id: String) -> int:
        return completed_dialogues.get(dialogue_id, 0)
    
    func has_completed(dialogue_id: String) -> bool:
        return completed_dialogues.has(dialogue_id)
```

**对话变体选择策略**：

1. **首次对话**（completion_count == 0）：
   - 播放完整的介绍性对话
   - 包含详细的背景信息和角色介绍
   - 示例：云中鹤首次见面的完整剑道传承邀请

2. **重复对话**（completion_count > 0）：
   - 自动选择简化版本的对话变体
   - 跳过已知信息,直接进入核心选择
   - 示例：云中鹤再次见面时直接问"考虑好了吗?"

3. **对话变体数据结构**：

```gdscript
class DialogueData:
    var dialogue_id: String
    var type: String
    var priority: int
    var is_repeatable: bool = false          # 是否可重复触发
    var repeat_variant_id: String = ""       # 重复时使用的变体对话ID
    var max_repeat_count: int = -1           # 最大重复次数(-1表示无限)
    var nodes: Array[DialogueNode]
```

**对话变体示例**：

```json
{
  "dialogue_id": "yunzhonghe_first_meeting_001",
  "type": "side",
  "priority": 3,
  "is_repeatable": true,
  "repeat_variant_id": "yunzhonghe_repeat_meeting_001",
  "max_repeat_count": 5,
  "nodes": [...]
}
```

**重复对话触发逻辑**：

```gdscript
func load_dialogue(dialogue_id: String) -> DialogueData:
    var completion_count = completion_tracker.get_completion_count(dialogue_id)
    
    # 加载原始对话数据
    var dialogue_data = dialogue_database.load_dialogue(dialogue_id)
    
    # 检查是否已完成且有重复变体
    if completion_count > 0 and dialogue_data.is_repeatable:
        # 检查是否超过最大重复次数
        if dialogue_data.max_repeat_count > 0 and completion_count >= dialogue_data.max_repeat_count:
            # 超过最大次数,使用默认闲聊对话
            return dialogue_database.load_dialogue("default_idle_dialogue")
        
        # 使用重复变体
        if dialogue_data.repeat_variant_id != "":
            return dialogue_database.load_dialogue(dialogue_data.repeat_variant_id)
    
    return dialogue_data
```

**对话重复规则**：

1. **主线对话**（type: "main"）：
   - 默认不可重复（is_repeatable = false）
   - 完成后标记为已完成,不再触发
   - 如需回顾,玩家可通过对话历史查看

2. **支线对话**（type: "side"）：
   - 可设置为可重复（is_repeatable = true）
   - 必须提供repeat_variant_id指向简化版本
   - 建议max_repeat_count设为3-5次

3. **闲聊对话**（type: "idle"）：
   - 默认可重复（is_repeatable = true）
   - 应提供多个变体（至少3个）轮换使用
   - 无最大重复次数限制

4. **战斗对话**（type: "battle"）：
   - 默认不可重复（is_repeatable = false）
   - 每次战斗使用不同的台词变体

**对话变体轮换机制**（用于闲聊对话）：

```gdscript
class IdleDialogueRotator:
    var variant_pool: Array[String] = []     # 变体对话ID池
    var last_used_index: int = -1            # 上次使用的索引
    
    func get_next_variant() -> String:
        if variant_pool.is_empty():
            return ""
        
        # 轮换选择,避免连续重复
        last_used_index = (last_used_index + 1) % variant_pool.size()
        return variant_pool[last_used_index]
```

**设计目标**：
- ✅ 避免NPC重复相同台词（通过变体系统）
- ✅ 保持对话的新鲜感（轮换机制）
- ✅ 尊重玩家时间（重复对话自动简化）
- ✅ 支持剧情回顾（通过对话历史）


#### 8. 对话技能检定机制（Phase 2功能 - MVP阶段不实现）

> **⚠️ 重要**: 此功能标记为**Phase 2扩展功能**,**不在MVP范围内**。MVP阶段专注于核心对话流程(节点、选择、条件、效果)。技能检定系统将在MVP完成后作为独立功能添加。

受《极乐迪斯科》启发,对话技能检定为对话增加了策略性和不确定性,让对话本身成为gameplay。此功能与核心对话系统职责边界清晰,可独立开发和测试。

**技能检定类型**：

| 技能 | 属性基础 | 用途 | 示例 |
|------|----------|------|------|
| **说服** | 魅力 | 说服NPC改变想法 | 说服商人降价、劝说敌人投降 |
| **欺诈** | 智慧 | 成功撒谎或隐瞒真相 | 伪装身份、隐瞒动机 |
| **威吓** | 力量 | 通过威胁达成目的 | 逼问情报、恐吓敌人 |
| **洞察** | 感知 | 看穿NPC的谎言或意图 | 识破伪装、察觉陷阱 |
| **学识** | 智慧 | 展示知识获得尊重 | 引经据典、解答难题 |
| **魅惑** | 魅力 | 通过魅力获得好感 | 调情、博取同情 |

**成功率计算公式**：

```
base_chance = (player_attribute / 100) * 0.5  # 属性贡献50%
skill_bonus = player_skill_level * 0.05       # 技能等级贡献
difficulty_modifier = -difficulty * 0.1       # 难度惩罚
npc_resistance = -npc_personality_trait * 0.1 # NPC性格抗性

success_chance = clamp(base_chance + skill_bonus + difficulty_modifier + npc_resistance, 0.05, 0.95)
```

**变量说明**：
- `player_attribute`: 玩家相关属性值（0-100）
- `player_skill_level`: 技能等级（0-10）
- `difficulty`: 检定难度（1-5，1=简单，5=极难）
- `npc_personality_trait`: NPC性格特质（0-10，影响抗性）
- `success_chance`: 最终成功率（5%-95%）

**检定数据结构**：

```gdscript
class SkillCheck:
    var skill_type: String      # 技能类型（persuade, deceive, intimidate等）
    var difficulty: int         # 难度（1-5）
    var success_node: String    # 成功跳转节点
    var failure_node: String    # 失败跳转节点
    var show_odds: bool = true  # 是否显示成功率

class Choice:
    # ... 现有字段 ...
    var skill_check: SkillCheck = null  # 技能检定（可选）
```

**UI显示**：
- 需要技能检定的选择显示骰子图标🎲
- 悬停时显示成功率（如"成功率：65%"）
- 可在设置中关闭成功率显示（增加不确定性）

**实现示例**：

```json
{
  "id": "choice_persuade",
  "text": "【说服】前辈何不放下屠刀，立地成佛？",
  "icon": "skill_check",
  "skill_check": {
    "skill_type": "persuade",
    "difficulty": 4,
    "success_node": "NODE_PERSUADE_SUCCESS",
    "failure_node": "NODE_PERSUADE_FAILURE",
    "show_odds": true
  },
  "conditions": [
    {
      "type": "dao_heart",
      "target": "player",
      "operator": ">=",
      "value": 30
    }
  ]
}
```

**检定执行流程**：

```gdscript
func execute_skill_check(choice: Choice, npc: NPC) -> bool:
    var check = choice.skill_check
    
    # 计算成功率
    var player_attr = get_attribute_for_skill(check.skill_type)
    var skill_level = player.get_skill_level(check.skill_type)
    var npc_resistance = npc.get_resistance(check.skill_type)
    
    var base_chance = (player_attr / 100.0) * 0.5
    var skill_bonus = skill_level * 0.05
    var difficulty_mod = -check.difficulty * 0.1
    var resistance_mod = -npc_resistance * 0.1
    
    var success_chance = clamp(
        base_chance + skill_bonus + difficulty_mod + resistance_mod,
        0.05, 0.95
    )
    
    # 执行检定
    var roll = randf()
    var success = roll < success_chance
    
    # 记录检定结果
    log_skill_check(check.skill_type, success_chance, roll, success)
    
    # 跳转到对应节点
    if success:
        jump_to_node(check.success_node)
    else:
        jump_to_node(check.failure_node)
    
    return success
```

**Phase 2实现建议**：
- 技能检定为**可选功能**,不是所有对话都需要
- 主要用于关键剧情分支和高风险选择
- 失败不应导致游戏无法继续,而是提供替代路径
- 成功率应在20%-80%之间,避免过于确定或不确定
- **MVP替代方案**: 使用确定性条件判断(如属性值阈值)代替随机检定

**MVP阶段的简化实现**:
```gdscript
# MVP: 使用确定性属性检查代替技能检定
class Choice:
    var attribute_requirement: Dictionary = {}  # {"charisma": 50} 表示需要魅力≥50
    
# 示例: 说服选择需要高魅力
{
  "id": "choice_persuade",
  "text": "【说服】前辈何不放下屠刀，立地成佛？",
  "icon": "persuade",
  "conditions": [
    {
      "type": "attribute",
      "target": "charisma",
      "operator": ">=",
      "value": 50
    }
  ],
  "next_node": "NODE_PERSUADE_SUCCESS"
}
```

### States and Transitions

对话系统的状态机：

| 状态 | 描述 | 可转换到 |
|------|------|----------|
| **IDLE** | 无对话进行中 | TRIGGERED |
| **TRIGGERED** | 对话被触发，准备加载 | LOADING |
| **LOADING** | 加载对话数据 | DISPLAYING, ERROR |
| **DISPLAYING** | 显示对话文本 | WAITING_CHOICE, PROCESSING, ENDED |
| **WAITING_CHOICE** | 等待玩家选择 | PROCESSING |
| **PROCESSING** | 处理选择效果 | DISPLAYING, ENDED |
| **ENDED** | 对话结束 | IDLE |
| **ERROR** | 加载或处理错误 | IDLE |

**状态转换规则**：
- `IDLE → TRIGGERED`: 玩家按交互键或满足自动触发条件
- `TRIGGERED → LOADING`: 开始加载对话数据
- `LOADING → DISPLAYING`: 数据加载成功，显示第一个节点
- `LOADING → ERROR`: 数据加载失败（文件不存在、格式错误）
- `DISPLAYING → WAITING_CHOICE`: 节点有选择项，等待玩家选择
- `DISPLAYING → PROCESSING`: 节点无选择项，自动执行效果
- `DISPLAYING → ENDED`: 节点是结束节点（next_node为"END"）
- `WAITING_CHOICE → PROCESSING`: 玩家做出选择
- `PROCESSING → DISPLAYING`: 效果执行完毕，跳转到下一个节点
- `PROCESSING → ENDED`: 效果执行完毕，对话结束
- `ENDED → IDLE`: 对话UI关闭，返回游戏
- `ERROR → IDLE`: 显示错误信息后返回

### Interactions with Other Systems

#### 1. 对话数据库（上游依赖）
- **接口**：`load_dialogue(dialogue_id: String) -> DialogueData`
- **数据流向**：对话数据库 → 对话系统
- **职责边界**：数据库负责存储和提供数据，对话系统负责解析和执行

#### 2. 角色关系数据库（上游依赖）
- **接口**：`get_relationship(npc_id: String) -> int`
- **接口**：`get_dao_heart() -> int`
- **数据流向**：关系数据库 → 对话系统（读取）
- **职责边界**：数据库提供当前关系值，对话系统用于条件判断

#### 3. 角色关系系统（双向依赖）
- **接口**：`modify_relationship(npc_id: String, delta: int)`
- **接口**：`modify_dao_heart(delta: int)`
- **数据流向**：对话系统 → 关系系统（写入）
- **职责边界**：对话系统触发关系变化，关系系统负责计算和存储

#### 4. 对话树管理系统（下游被依赖）
- **接口**：`evaluate_conditions(conditions: Array) -> bool`
- **接口**：`get_next_node(current_node: DialogueNode, choice_id: String) -> String`
- **数据流向**：对话系统 → 树管理系统
- **职责边界**：对话系统提供节点和选择，树管理系统负责分支逻辑

#### 5. 对话效果系统（下游被依赖）
- **接口**：`execute_effects(effects: Array)`
- **数据流向**：对话系统 → 效果系统
- **职责边界**：对话系统提供效果列表，效果系统负责执行

#### 6. 对话UI（下游被依赖）
- **接口**：`show_dialogue(speaker: String, text: String, choices: Array)`
- **接口**：`hide_dialogue()`
- **数据流向**：对话系统 → UI系统
- **职责边界**：对话系统提供显示内容，UI负责渲染和交互

#### 7. 任务系统（双向依赖）
- **接口**：`trigger_quest(quest_id: String)`
- **接口**：`complete_quest(quest_id: String)`
- **接口**：`get_quest_status(quest_id: String) -> String`
- **数据流向**：双向（对话触发任务，任务状态影响对话）
- **职责边界**：对话系统触发任务事件，任务系统管理任务状态

#### 8. 战斗系统（单向依赖）
- **接口**：`trigger_battle(enemy_id: String, battle_config: Dictionary)`
- **数据流向**：对话系统 → 战斗系统
- **职责边界**：对话系统触发战斗，战斗系统负责战斗逻辑

## Formulas

对话系统主要处理逻辑和数据流，不涉及复杂的数学计算。以下是系统中使用的简单计算规则：

### 关系值变化计算

```
final_relationship = clamp(current_relationship + delta, -100, 100)
```

**变量**：
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| current_relationship | CR | int | -100 to 100 | 当前关系值 |
| delta | Δ | int | ±5 to ±20 | 关系值变化量（受max_relationship_delta限制） |
| final_relationship | FR | int | -100 to 100 | 最终关系值 |

**输出范围**：-100 到 +100，超出范围时自动截断

**示例**：
- 当前关系值 = 45，选择效果 = +15 → 最终关系值 = 60
- 当前关系值 = 95，选择效果 = +10 → 最终关系值 = 100（截断）
- 当前关系值 = -80，选择效果 = -25 → 最终关系值 = -100（截断）

### 道心值变化计算

```
final_dao_heart = clamp(current_dao_heart + delta, -100, 100)
```

**变量**：
| 变量 | 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|------|
| current_dao_heart | DH | int | -100 to 100 | 当前道心值 |
| delta | Δ | int | ±5 to ±20 | 道心值变化量（受max_dao_heart_delta限制） |
| final_dao_heart | FDH | int | -100 to 100 | 最终道心值 |

**输出范围**：-100（纯魔道）到 +100（纯正道）

**示例**：
- 当前道心 = 20，正义选择 = +10 → 最终道心 = 30
- 当前道心 = -50，邪恶选择 = -15 → 最终道心 = -65

### 条件评估优先级

当多个条件同时存在时，按以下优先级评估（从高到低）：
1. `flag`（全局标志位）- 最高优先级
2. `quest_status`（任务状态）
3. `realm_level`（境界等级）
4. `relationship`（关系值）
5. `dao_heart`（道心值）
6. `item_count`（物品数量）
7. `location`（位置）
8. `time`（时间）- 最低优先级

## Edge Cases

### 1. 对话数据加载失败
**条件**：对话文件不存在、JSON格式错误、必需字段缺失
**处理**：
- 显示错误提示："对话数据加载失败，请联系开发者"
- 记录错误日志，包含dialogue_id和错误原因
- 返回IDLE状态，不阻塞游戏进程
- 开发模式下显示详细错误信息

### 2. 所有选择项都不可用
**条件**：对话节点有选择项，但所有选择的条件都不满足
**处理**：
- 自动跳转到next_node（如果定义）
- 如果next_node未定义或为空，结束对话
- 记录警告日志："所有选择不可用，dialogue_id: XXX"

### 3. 循环引用检测
**条件**：对话节点A → B → C → A，形成循环
**处理**：
- 维护已访问节点栈（最多100个节点）
- 检测到重复访问同一节点时，强制结束对话
- 记录错误日志："检测到对话循环，dialogue_id: XXX"
- 开发模式下显示警告弹窗

### 4. 效果执行失败
**条件**：效果目标不存在（如任务ID无效、物品ID无效）
**处理**：
- 跳过该效果，继续执行后续效果
- 记录警告日志："效果执行失败，type: XXX, target: XXX"
- 不中断对话流程
- 开发模式下在UI上显示警告标记

### 5. 关系值/道心值超出范围
**条件**：计算后的值 < -100 或 > 100
**处理**：
- 使用clamp函数截断到[-100, 100]范围
- 记录信息日志："关系值已截断，NPC: XXX, 原始值: XXX, 截断后: XXX"
- 正常继续对话

### 6. NPC不存在或已死亡
**条件**：尝试与已死亡或不存在的NPC对话
**处理**：
- 检查NPC状态，如果is_dead = true，显示默认消息："此人已不在人世"
- 如果NPC完全不存在，记录错误并返回IDLE
- 不触发对话系统

### 7. 玩家在对话中途离开
**条件**：玩家在WAITING_CHOICE状态下按ESC或走远
**处理**：
- 触发事务回滚（rollback），撤销所有已执行的效果
- 保存对话进度（dialogue_id + node_id + 已做出的选择）
- 标记对话为"中断"状态
- 下次触发同一对话时，询问是否从上次中断处继续
- 如果玩家选择"继续"，从中断节点开始，跳过已执行的效果
- 如果玩家选择"重新开始"，从第一个节点开始，创建新事务

**中途保存的数据结构**：
```gdscript
class DialogueSaveState:
    var dialogue_id: String         # 对话ID
    var current_node_id: String     # 当前节点ID
    var visited_nodes: Array        # 已访问的节点列表
    var made_choices: Dictionary    # 已做出的选择 {node_id: choice_id}
    var transaction_status: String  # 事务状态（ROLLED_BACK表示已回滚）
    var save_timestamp: int         # 保存时间戳
```

### 8. 同时触发多个对话
**条件**：多个NPC同时满足主动触发条件
**处理**：
- 维护对话队列，按**优先级**和**触发时间**排序
- 排序规则：优先级高的在前，优先级相同时按触发时间排序（先触发的在前）
- 一次只处理一个对话，其他对话进入等待队列
- 当前对话结束后，自动触发队列中的下一个对话
- 队列最大长度为dialogue_queue_max（默认5），超出时丢弃**优先级最低且最早**的对话

**对话优先级定义**：
| 优先级 | 数值 | 描述 | 示例 |
|--------|------|------|------|
| 紧急 | 5 | 必须立即处理的对话 | 主线剧情关键节点、Boss战前对话 |
| 重要 | 4 | 高优先级对话 | 主线任务触发、重要NPC的关系事件 |
| 普通 | 3 | 默认优先级 | 支线任务、一般NPC对话 |
| 次要 | 2 | 低优先级对话 | 闲聊对话、环境NPC |
| 可选 | 1 | 最低优先级 | 重复对话、提示性对话 |

**队列排序算法**：
```gdscript
func sort_dialogue_queue(queue: Array) -> Array:
    queue.sort_custom(func(a, b):
        # 优先级高的在前
        if a.priority != b.priority:
            return a.priority > b.priority
        # 优先级相同时，触发时间早的在前
        return a.trigger_time < b.trigger_time
    )
    return queue

func enqueue_dialogue(dialogue_data: Dictionary):
    dialogue_queue.append(dialogue_data)
    dialogue_queue = sort_dialogue_queue(dialogue_queue)
    
    # 超出队列长度时，移除优先级最低且最早的对话
    if dialogue_queue.size() > dialogue_queue_max:
        var lowest_priority = dialogue_queue[-1].priority
        var to_remove = dialogue_queue[-1]
        for dialogue in dialogue_queue:
            if dialogue.priority < lowest_priority or \
               (dialogue.priority == lowest_priority and dialogue.trigger_time < to_remove.trigger_time):
                to_remove = dialogue
        dialogue_queue.erase(to_remove)
        push_warning("对话队列已满，丢弃对话：%s（优先级：%d）" % [to_remove.dialogue_id, to_remove.priority])
```

### 9. 对话文本过长
**条件**：对话文本超过UI显示区域（>200字符）
**处理**：
- 自动分页显示，每页最多200字符
- 显示"继续"按钮，玩家点击后显示下一页
- 记录警告日志："对话文本过长，建议拆分节点"

### 10. 占位符变量未定义
**条件**：对话文本包含{player_name}，但变量未定义
**处理**：
- 使用默认值替换（如{player_name} → "少侠"）
- 记录警告日志："占位符变量未定义，variable: XXX"
- 正常显示对话

## Dependencies

### 上游依赖（Hard Dependencies）

#### 1. 对话数据库
- **类型**：数据层，基础设施
- **接口**：`load_dialogue(dialogue_id: String) -> DialogueData`
- **依赖原因**：对话系统必须从数据库读取对话内容
- **失败影响**：无法加载对话数据，对话系统无法工作
- **数据格式**：JSON格式的对话树结构（详见下方"对话数据格式规范"）

**对话数据格式规范**：

对话数据使用JSON格式存储，每个对话文件代表一个完整的对话树。文件命名规范：`dialogue_[场景]_[NPC]_[编号].json`

**JSON Schema示例**：
```json
{
  "dialogue_id": "yunzhonghe_first_meeting_001",
  "type": "main",
  "priority": 5,
  "nodes": [
    {
      "id": "START",
      "speaker": "yunzhonghe",
      "text": "少侠骨骼清奇，是块练剑的好材料。",
      "emotion": "pleased",
      "audio_cue": "audio/dialogue/yunzhonghe_001.ogg",
      "timeout": 0,
      "conditions": [],
      "effects": [],
      "choices": [
        {
          "id": "choice_accept",
          "text": "多谢前辈指点，晚辈愿意学习剑道",
          "icon": "righteous",
          "conditions": [],
          "effects": [
            {"type": "relationship_change", "target": "yunzhonghe", "value": 10},
            {"type": "dao_heart_change", "target": "player", "value": 5}
          ],
          "next_node": "NODE_002"
        },
        {
          "id": "choice_decline",
          "text": "晚辈对剑道兴趣不大，还请前辈见谅",
          "icon": "neutral",
          "conditions": [],
          "effects": [
            {"type": "relationship_change", "target": "yunzhonghe", "value": -5}
          ],
          "next_node": "NODE_003"
        }
      ],
      "next_node": null
    }
  ]
}
```

**必需字段**：
- `dialogue_id` (String): 唯一标识符
- `type` (String): 对话类型 ("main" | "side" | "idle" | "battle")
- `nodes` (Array): 对话节点数组

**可选字段**：
- `priority` (int): 对话优先级（1-5，默认3）

**节点必需字段**：
- `id` (String): 节点ID
- `speaker` (String): 说话者ID
- `text` (String): 对话文本
- `choices` (Array): 选择项数组（可为空）
- `next_node` (String | null): 下一节点ID

**节点可选字段**：
- `emotion` (String): 情绪标签
- `audio_cue` (String): 语音文件路径
- `conditions` (Array): 显示条件
- `effects` (Array): 自动效果
- `timeout` (int): 选择超时时间（秒，0表示无超时）

#### 2. 角色关系数据库
- **类型**：数据层，基础设施
- **接口**：`get_relationship(npc_id: String) -> int`, `get_dao_heart() -> int`
- **依赖原因**：对话系统需要读取关系值和道心值用于条件判断
- **失败影响**：无法评估条件，所有条件判断失败
- **数据格式**：键值对存储，NPC ID → 关系值

### 下游被依赖（Soft Dependencies）

#### 3. 对话树管理系统
- **类型**：逻辑层，子系统
- **接口**：`evaluate_conditions()`, `get_next_node()`
- **依赖原因**：处理对话分支逻辑
- **失败影响**：无法处理复杂分支，但简单对话仍可工作

#### 4. 对话效果系统
- **类型**：逻辑层，子系统
- **接口**：`execute_effects(effects: Array)`
- **依赖原因**：执行对话后的游戏状态变化
- **失败影响**：对话选择无实际效果，但对话流程正常

#### 5. 对话UI
- **类型**：表现层，UI系统
- **接口**：`show_dialogue()`, `hide_dialogue()`
- **依赖原因**：显示对话内容和选择项
- **失败影响**：无法显示对话，系统完全不可用

### 双向依赖

#### 6. 角色关系系统
- **类型**：游戏机制层
- **接口**：`modify_relationship()`, `modify_dao_heart()`
- **依赖原因**：对话系统读取关系值（条件判断），写入关系值（效果执行）
- **失败影响**：关系值无法更新，玩家选择无长期影响

#### 7. 任务系统
- **类型**：游戏机制层
- **接口**：`trigger_quest()`, `get_quest_status()`
- **依赖原因**：对话触发任务，任务状态影响对话
- **失败影响**：无法通过对话触发任务，任务相关对话无法显示

### 单向依赖（对话系统依赖其他系统）

#### 8. 战斗系统
- **类型**：游戏机制层
- **接口**：`trigger_battle(enemy_id: String)`
- **依赖原因**：某些对话选择会触发战斗
- **失败影响**：无法通过对话触发战斗，但对话流程正常

#### 9. 世界状态持久化
- **类型**：技术层，基础设施
- **接口**：`save_dialogue_state()`, `load_dialogue_state()`
- **依赖原因**：保存对话进度和历史记录
- **失败影响**：对话进度无法保存，重复对话可能出现

### 对话历史记录系统设计（MVP: 仅会话历史）

> **⚠️ MVP范围**: MVP阶段仅实现**会话历史**（内存中的临时记录）。**永久日志**（磁盘存储）标记为**Phase 2功能**,在MVP完成后添加。

对话历史记录系统在MVP阶段采用简化设计,专注于核心功能:
- **会话历史**: 内存中保存最近100条对话,支持Tab键快速查看和关键词搜索
- **永久日志**: Phase 2功能,用于回顾完整游戏历程（详见下方Phase 2设计）

#### 会话历史（Session History）

**用途**：快速查看近期对话，按Tab键即可访问  
**存储位置**：内存（游戏运行时）  
**容量限制**：dialogue_history_max条（默认100条）  
**数据结构**：

```gdscript
class DialogueHistoryEntry:
    var timestamp: int              # 对话时间戳（游戏内时间）
    var dialogue_id: String         # 对话ID
    var speaker: String             # 说话者ID
    var text: String                # 对话文本
    var choice_made: String         # 玩家做出的选择（如果有）
    var is_important: bool          # 是否为重要对话
    var effects_summary: String     # 效果摘要（如"+10 好感度"）

class SessionHistoryManager:
    var history: Array[DialogueHistoryEntry] = []
    var max_size: int = 100
    
    func add_entry(entry: DialogueHistoryEntry):
        # 如果是重要对话，标记为优先保留
        if entry.is_important:
            entry.priority = true
        
        history.append(entry)
        
        # 超出容量时，移除最早的非重要对话
        if history.size() > max_size:
            remove_oldest_non_important()
    
    func remove_oldest_non_important():
        # 找到最早的非重要对话并移除
        for i in range(history.size()):
            if not history[i].is_important:
                history.remove_at(i)
                return
        # 如果全是重要对话，移除最早的
        history.remove_at(0)
    
    func get_recent_history(count: int = 20) -> Array:
        # 返回最近N条对话
        var start_index = max(0, history.size() - count)
        return history.slice(start_index, history.size())
    
    func search_history(keyword: String) -> Array:
        # 搜索包含关键词的对话
        var results = []
        for entry in history:
            if keyword in entry.text or keyword in entry.speaker:
                results.append(entry)
        return results
```

**重要对话自动标记规则**：
- 对话类型为"main"（主线对话）
- 选择包含关系值变化 ≥ 10 或 ≤ -10
- 选择包含道心值变化 ≥ 10 或 ≤ -10
- 选择触发任务或完成任务
- 选择触发战斗
- 对话包含关键剧情标志位设置

#### 永久日志（Permanent Log - Phase 2功能）

> **⚠️ Phase 2功能**: 此部分在MVP阶段不实现。以下设计供Phase 2参考。

**用途**：完整记录所有对话，用于回顾游戏历程  
**存储位置**：磁盘（user://dialogue_logs/）  
**容量限制**：无限制  
**文件格式**：JSON Lines（每行一个JSON对象）  
**数据结构**：

```gdscript
class PermanentLogEntry:
    var timestamp: int              # 对话时间戳（游戏内时间）
    var real_timestamp: int         # 真实时间戳（用于排序）
    var dialogue_id: String         # 对话ID
    var dialogue_type: String       # 对话类型（main/side/idle/battle）
    var speaker: String             # 说话者ID
    var text: String                # 对话文本
    var choice_made: String         # 玩家做出的选择（如果有）
    var effects: Array              # 执行的效果列表
    var player_state: Dictionary    # 玩家状态快照（境界、道心、关系值）

class PermanentLogManager:
    var log_file_path: String = "user://dialogue_logs/dialogue_log.jsonl"
    var current_session_logs: Array = []
    
    func add_entry(entry: PermanentLogEntry):
        # 添加到当前会话日志
        current_session_logs.append(entry)
        
        # 每10条对话或对话结束时写入磁盘
        if current_session_logs.size() >= 10:
            flush_to_disk()
    
    func flush_to_disk():
        # 将当前会话日志追加到文件
        var file = FileAccess.open(log_file_path, FileAccess.READ_WRITE)
        file.seek_end()
        
        for entry in current_session_logs:
            var json_line = JSON.stringify(entry.to_dict())
            file.store_line(json_line)
        
        file.close()
        current_session_logs.clear()
    
    func load_logs_by_date_range(start_time: int, end_time: int) -> Array:
        # 加载指定时间范围的日志
        var file = FileAccess.open(log_file_path, FileAccess.READ)
        var results = []
        
        while not file.eof_reached():
            var line = file.get_line()
            if line.is_empty():
                continue
            
            var entry = JSON.parse_string(line)
            if entry.timestamp >= start_time and entry.timestamp <= end_time:
                results.append(entry)
        
        file.close()
        return results
    
    func search_logs(keyword: String, limit: int = 100) -> Array:
        # 搜索日志（限制返回数量以避免性能问题）
        var file = FileAccess.open(log_file_path, FileAccess.READ)
        var results = []
        
        while not file.eof_reached() and results.size() < limit:
            var line = file.get_line()
            if line.is_empty():
                continue
            
            var entry = JSON.parse_string(line)
            if keyword in entry.text or keyword in entry.speaker:
                results.append(entry)
        
        file.close()
        return results
```

**日志文件管理**：
- 文件路径：`user://dialogue_logs/dialogue_log.jsonl`
- 文件格式：JSON Lines（每行一个JSON对象，便于追加和搜索）
- 文件大小：无限制，但建议每个存档周期（如每章节）创建新文件
- 文件命名：`dialogue_log_chapter_01.jsonl`, `dialogue_log_chapter_02.jsonl`

#### 历史记录UI集成

**会话历史面板**（Tab键打开 - MVP功能）：
- 显示最近100条对话（可滚动）
- 重要对话用金色星标标记
- 支持关键词搜索（实时过滤）
- 点击对话可查看详细信息（效果、玩家状态）

**永久日志查看器**（Phase 2功能 - MVP不实现）：
- 按章节/日期浏览完整对话历史
- 支持高级搜索（NPC名称、对话类型、时间范围）
- 导出功能（导出为文本文件）
- 统计功能（对话总数、各NPC对话次数、选择倾向分析）

#### 性能优化

**会话历史**：
- 内存占用：约100条 × 500字节 = 50KB（可忽略）
- 查询性能：O(n)线性搜索，n=100，性能无问题

**永久日志**：
- 磁盘占用：约1000条对话 × 1KB = 1MB（完整游戏约10-20MB）
- 写入性能：批量写入（每10条），避免频繁I/O
- 读取性能：按需加载，使用流式读取避免一次性加载全部日志
- 搜索优化：限制搜索结果数量（默认100条），避免遍历整个文件

## Tuning Knobs

以下参数可由设计师调整，无需修改代码：

### 1. 对话显示速度
- **参数名**：`text_display_speed`
- **类型**：float
- **默认值**：0.05（每个字符显示间隔，秒）
- **安全范围**：0.01 - 0.2
- **影响**：文字逐字显示的速度
- **极端行为**：
  - 过低（<0.01）：文字几乎瞬间显示，失去打字机效果
  - 过高（>0.2）：文字显示过慢，玩家体验差

### 2. 选择超时时间（全局默认，不推荐使用）
- **参数名**：`choice_timeout`
- **类型**：int
- **默认值**：0（无超时）
- **安全范围**：0 - 60（秒）
- **影响**：玩家必须在指定时间内做出选择，否则自动选择默认项
- **设计建议**：**默认关闭**（设为0），仅在特定场景使用per-node的timeout字段
- **适用场景**：战斗对话、紧急抉择、限时事件
- **极端行为**：
  - 0：无超时，玩家可以无限等待（推荐默认值）
  - >60：超时时间过长，失去紧迫感
- **注意**：全局超时可能破坏"选择的分量"体验，优先使用DialogueNode.timeout字段为特定节点设置超时

### 3. 对话历史记录数量（会话历史）
- **参数名**：`dialogue_history_max`
- **类型**：int
- **默认值**：100
- **安全范围**：50 - 200
- **影响**：保存在内存中的会话历史记录数量（用于Tab键快速查看）
- **设计说明**：此参数仅控制**会话历史**（内存中的临时记录），不影响**永久日志**（磁盘存储）
- **极端行为**：
  - 过低（<50）：无法回顾足够的近期对话
  - 过高（>200）：占用过多内存，影响性能

### 3.1. 对话永久日志设置（Phase 2功能）
- **参数名**：`dialogue_permanent_log_enabled`
- **类型**：bool
- **默认值**：false（MVP阶段禁用）
- **影响**：是否启用永久对话日志（保存到磁盘）
- **说明**：**Phase 2功能**。永久日志无数量限制，记录所有对话，用于回顾完整游戏历程。MVP阶段此功能禁用。

### 3.2. 重要对话自动标记
- **参数名**：`auto_mark_important_dialogues`
- **类型**：bool
- **默认值**：true
- **影响**：是否自动将主线对话和关键选择标记为重要
- **说明**：重要对话在会话历史中优先保留，不会被新对话挤出

### 4. 关系值变化倍率
- **参数名**：`relationship_change_multiplier`
- **类型**：float
- **默认值**：1.0
- **安全范围**：0.5 - 2.0
- **影响**：所有关系值变化的全局倍率
- **极端行为**：
  - 过低（<0.5）：关系值增长过慢，玩家难以建立关系
  - 过高（>2.0）：关系值增长过快，失去成就感

### 5. 道心值变化倍率
- **参数名**：`dao_heart_change_multiplier`
- **类型**：float
- **默认值**：1.0
- **安全范围**：0.5 - 2.0
- **影响**：所有道心值变化的全局倍率
- **极端行为**：
  - 过低（<0.5）：道心值变化过慢，玩家难以转变阵营
  - 过高（>2.0）：道心值变化过快，玩家容易误入极端

### 6. 自动继续延迟
- **参数名**：`auto_continue_delay`
- **类型**：float
- **默认值**：1.5（秒）
- **安全范围**：0.5 - 5.0
- **影响**：无选择项的对话节点自动跳转到下一节点的延迟
- **极端行为**：
  - 过低（<0.5）：玩家来不及阅读对话
  - 过高（>5.0）：对话节奏过慢，玩家体验差

### 7. 对话跳过速度
- **参数名**：`skip_speed_multiplier`
- **类型**：float
- **默认值**：5.0
- **安全范围**：2.0 - 10.0
- **影响**：玩家按住跳过键时的文字显示速度倍率
- **极端行为**：
  - 过低（<2.0）：跳过速度过慢，玩家不耐烦
  - 过高（>10.0）：跳过速度过快，玩家可能错过重要信息

### 8. 选择项最大数量
- **参数名**：`max_choices_per_node`
- **类型**：int
- **默认值**：4
- **安全范围**：2 - 6
- **影响**：每个对话节点最多显示的选择项数量
- **极端行为**：
  - 过低（<2）：选择过少，失去分支感
  - 过高（>6）：选择过多，UI拥挤，玩家选择困难

### 9. 对话文本最大长度
- **参数名**：`max_text_length`
- **类型**：int
- **默认值**：200（字符）
- **安全范围**：100 - 500
- **影响**：单个对话节点的文本最大长度
- **极端行为**：
  - 过低（<100）：对话过于简短，无法表达复杂内容
  - 过高（>500）：对话过长，玩家阅读疲劳

### 10. 对话队列最大长度
- **参数名**：`dialogue_queue_max`
- **类型**：int
- **默认值**：5
- **安全范围**：1 - 10
- **影响**：同时触发的对话最大排队数量
- **极端行为**：
  - 过低（<1）：无法排队，对话可能丢失
  - 过高（>10）：队列过长，玩家被连续对话轰炸

### 11. 关系值单次变化上限
- **参数名**：`max_relationship_delta`
- **类型**：int
- **默认值**：20
- **安全范围**：10 - 50
- **影响**：单次对话选择可以改变的关系值上限
- **极端行为**：
  - 过低（<10）：关系值变化过慢，玩家难以建立深厚关系
  - 过高（>50）：关系值变化过快，失去渐进感

### 12. 道心值单次变化上限
- **参数名**：`max_dao_heart_delta`
- **类型**：int
- **默认值**：20
- **安全范围**：10 - 50
- **影响**：单次对话选择可以改变的道心值上限
- **极端行为**：
  - 过低（<10）：道心值变化过慢，玩家难以转变阵营
  - 过高（>50）：道心值变化过快，玩家容易误入极端

## Visual/Audio Requirements

### 视觉需求

#### 1. 对话框UI
- **样式**：中国古典风格，半透明背景，水墨画边框
- **布局**：屏幕下方1/3区域，不遮挡重要游戏画面
- **动画**：淡入淡出效果（0.3秒），打字机效果显示文字
- **头像**：NPC头像显示在左侧，玩家头像显示在右侧（如果是玩家说话）
- **表情系统**：根据emotion标签切换头像表情（喜、怒、哀、乐、惊、疑、思）

#### 2. 选择项UI
- **样式**：列表形式，每个选择项有独立背景
- **高亮**：鼠标悬停或键盘选中时高亮显示
- **图标系统**：根据选择类型显示对应图标（详见下方"选择项图标系统"）
- **禁用状态**：不满足条件的选择显示为灰色，带锁图标
- **提示**：悬停在禁用选择上时，显示不满足的条件（如"需要境界：筑基初期"）

**选择项图标系统**：

为提升对话选择的可读性和沉浸感,系统支持多种图标类型,帮助玩家快速识别选择的性质和后果。

| 图标类型 | 图标符号 | 用途 | 示例选择 |
|---------|---------|------|---------|
| **正道** | ⚔️ 剑 | 正义、光明、正道选择 | "行侠仗义，除暴安良" |
| **魔道** | 🔥 魔焰 | 邪恶、黑暗、魔道选择 | "杀人夺宝，快意恩仇" |
| **中立** | 无图标 | 中立、普通选择 | "告辞离去" |
| **战斗** | ⚡ 闪电 | 触发战斗或冲突 | "拔剑相向" |
| **交易** | 💰 金币 | 涉及金钱、物品交易 | "购买丹药" |
| **调查** | 🔍 放大镜 | 调查、探索、获取信息 | "询问详情" |
| **情感** | ❤️ 心形 | 情感、关系相关选择 | "表达爱意" |
| **技能检定** | 🎲 骰子 | 需要技能检定的选择 | "【说服】劝说投降" |
| **挑战** | ⚠️ 警告 | 挑战、质疑、冒险选择 | "质疑前辈" |
| **欺骗** | 🎭 面具 | 谎言、欺骗、伪装 | "编造理由" |
| **威胁** | 💀 骷髅 | 威胁、恐吓 | "威胁交出宝物" |
| **学识** | 📚 书籍 | 展示知识、引经据典 | "引用古籍" |
| **修炼** | 🧘 打坐 | 修炼、突破、境界相关 | "请求指点修炼" |
| **传承** | 📜 卷轴 | 功法传承、秘籍 | "接受传承" |
| **禁用** | 🔒 锁 | 不满足条件的选择 | 灰色显示 |

**图标设计规范**：

1. **视觉风格**：
   - 采用中国古典风格的图标设计
   - 使用水墨画风格的线条和色彩
   - 图标大小：24x24像素（1x）、48x48像素（2x）
   - 支持SVG矢量格式以适应不同分辨率

2. **颜色编码**：
   - 正道图标：金色/白色（#FFD700 / #FFFFFF）
   - 魔道图标：暗红色/黑色（#8B0000 / #000000）
   - 中立图标：灰色（#808080）
   - 技能检定图标：蓝色（#4169E1）
   - 禁用图标：深灰色（#404040）

3. **动画效果**：
   - 悬停时图标轻微放大（1.1倍）
   - 选中时图标发光效果
   - 禁用图标无动画效果

4. **组合使用**：
   - 一个选择可以同时显示多个图标（如"正道+战斗"）
   - 主图标显示在左侧，次要图标显示在右侧
   - 最多显示2个图标，避免UI拥挤

**实现示例**：

```json
{
  "id": "choice_righteous_battle",
  "text": "为民除害，与恶徒决一死战！",
  "icon": "righteous",
  "secondary_icon": "battle",
  "effects": [
    {"type": "dao_heart_change", "target": "player", "value": 10},
    {"type": "battle_trigger", "target": "bandit_leader"}
  ]
}
```

**图标资源路径**：
- 正道：`assets/ui/icons/choice_righteous.svg`
- 魔道：`assets/ui/icons/choice_demonic.svg`
- 战斗：`assets/ui/icons/choice_battle.svg`
- 交易：`assets/ui/icons/choice_trade.svg`
- 调查：`assets/ui/icons/choice_investigate.svg`
- 情感：`assets/ui/icons/choice_emotion.svg`
- 技能检定：`assets/ui/icons/choice_skill_check.svg`
- 挑战：`assets/ui/icons/choice_challenge.svg`
- 欺骗：`assets/ui/icons/choice_deceive.svg`
- 威胁：`assets/ui/icons/choice_threaten.svg`
- 学识：`assets/ui/icons/choice_knowledge.svg`
- 修炼：`assets/ui/icons/choice_cultivation.svg`
- 传承：`assets/ui/icons/choice_legacy.svg`
- 禁用：`assets/ui/icons/choice_locked.svg`

#### 3. 对话历史UI
- **触发**：按Tab键打开对话历史面板
- **显示**：滚动列表，显示最近100条对话
- **格式**：NPC名称 + 对话内容，玩家选择用不同颜色标记
- **搜索**：支持关键词搜索历史对话

#### 4. 视觉反馈
- **关系值变化**：选择后显示浮动文字"+10 好感度"或"-5 好感度"
- **道心值变化**：选择后显示浮动文字"+10 正道"或"-10 魔道"
- **重要选择**：关键选择项用金色边框标记
- **新对话提示**：NPC头顶显示"！"图标，表示有新对话

### 音频需求

#### 1. 对话音效
- **文字显示音效**：打字机效果配合轻微的"沙沙"声
- **选择确认音效**：玩家选择时播放"确认"音效
- **对话开始/结束音效**：对话框打开/关闭时的音效

#### 2. 语音（可选）
- **核心NPC语音**：7个核心NPC的关键对话配音
- **语音格式**：OGG格式，采样率44.1kHz
- **语音触发**：自动播放，可跳过
- **字幕同步**：语音播放时文字同步显示

#### 3. 背景音乐
- **对话BGM**：对话时降低背景音乐音量至50%
- **情绪音乐**：重要剧情对话时切换到对应情绪的BGM
- **音乐淡入淡出**：对话开始/结束时音乐平滑过渡

## UI Requirements

### 对话UI布局

```
┌─────────────────────────────────────────────────────────────┐
│                     游戏画面区域                              │
│                                                               │
│                                                               │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│ ┌─────┐                                                      │
│ │ NPC │  云中鹤：                                            │
│ │头像 │  "少侠骨骼清奇，是块练剑的好材料。"                  │
│ └─────┘                                                      │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ [剑] 多谢前辈指点，晚辈愿意学习剑道                   │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ 晚辈对剑道兴趣不大，还请前辈见谅                      │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │ [锁] 晚辈想学习魔道功法（需要：道心值 < -30）        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  [Tab: 对话历史] [Space: 继续] [ESC: 退出]                   │
└─────────────────────────────────────────────────────────────┘
```

### UI交互规范

#### 1. 输入控制
- **键盘**：
  - 上/下方向键：选择选项
  - Enter/Space：确认选择
  - ESC：退出对话
  - Tab：打开对话历史
  - Ctrl：按住快速跳过文字显示
- **鼠标**：
  - 点击选择项：选择并确认
  - 点击对话框外：退出对话（可配置）
  - 滚轮：滚动对话历史

#### 2. 响应式设计
- **最小分辨率**：1280x720
- **推荐分辨率**：1920x1080
- **UI缩放**：根据分辨率自动缩放，保持比例
- **字体大小**：可在设置中调整（小/中/大）

#### 3. 无障碍支持
- **高对比度模式**：提供高对比度UI主题
- **字体大小调整**：支持放大字体
- **色盲模式**：正道/魔道图标除颜色外还有形状区分
- **键盘导航**：完全支持键盘操作

### UI状态管理

#### 1. 对话进行中
- 游戏暂停（时间停止，但动画继续）
- 玩家无法移动或使用技能
- 对话UI获得焦点
- 背景音乐音量降低

#### 2. 对话历史查看
- 对话暂停
- 显示历史面板覆盖对话框
- 支持滚动和搜索
- 按Tab或ESC关闭历史面板

#### 3. 对话队列UI（多个对话同时触发时）

当多个对话同时触发并进入队列时,系统需要向玩家清晰展示队列状态,避免"对话轰炸"的负面体验。

**队列指示器设计**：

```
┌─────────────────────────────────────────────────────────────┐
│                     游戏画面区域                              │
│                                                               │
│  ┌──────────────────────────────────────┐  ← 队列指示器      │
│  │ 📋 待处理对话 (3)                    │                    │
│  │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │                    │
│  │ 1. [紧急] 云中鹤 - 剑道传承          │                    │
│  │ 2. [重要] 柳如烟 - 关系事件          │                    │
│  │ 3. [普通] 村民甲 - 支线任务          │                    │
│  └──────────────────────────────────────┘                    │
├─────────────────────────────────────────────────────────────┤
│ ┌─────┐                                                      │
│ │ NPC │  云中鹤：                                            │
│ │头像 │  "少侠骨骼清奇，是块练剑的好材料。"                  │
│ └─────┘                                                      │
│                                                               │
│  [当前对话 1/3] [跳过队列: Shift+ESC]                        │
└─────────────────────────────────────────────────────────────┘
```

**队列指示器规则**：

1. **显示时机**：
   - 当对话队列中有2个或更多对话时显示
   - 位于屏幕右上角,半透明背景
   - 不遮挡重要游戏画面

2. **显示内容**：
   - 队列总数（如"待处理对话 (3)"）
   - 每个对话的优先级标签（紧急/重要/普通/次要/可选）
   - 每个对话的NPC名称和简短描述
   - 当前对话在队列中的位置（如"当前对话 1/3"）

3. **优先级颜色编码**：
   - 紧急（优先级5）：红色 (#FF0000)
   - 重要（优先级4）：橙色 (#FFA500)
   - 普通（优先级3）：黄色 (#FFD700)
   - 次要（优先级2）：灰色 (#808080)
   - 可选（优先级1）：浅灰色 (#C0C0C0)

4. **交互功能**：
   - 点击队列中的对话可查看详细信息（但不能跳过当前对话）
   - 按Shift+ESC可跳过整个队列（需要确认）
   - 悬停在队列项上显示完整对话描述

**队列跳过确认对话框**：

```
┌─────────────────────────────────────────┐
│  ⚠️  跳过对话队列                       │
│                                         │
│  您确定要跳过以下3个对话吗？            │
│                                         │
│  • [紧急] 云中鹤 - 剑道传承             │
│  • [重要] 柳如烟 - 关系事件             │
│  • [普通] 村民甲 - 支线任务             │
│                                         │
│  警告：跳过的对话可能无法再次触发！     │
│                                         │
│  [取消]  [仅跳过当前]  [跳过全部]      │
└─────────────────────────────────────────┘
```

**队列跳过规则**：

1. **仅跳过当前**：
   - 跳过当前对话,自动开始下一个对话
   - 被跳过的对话标记为"已跳过",不会再次触发
   - 适用于玩家想快速处理队列的情况

2. **跳过全部**：
   - 跳过队列中的所有对话
   - 所有对话标记为"已跳过"
   - 需要二次确认（防止误操作）

3. **不可跳过的对话**：
   - 主线对话（type: "main"）不能被跳过
   - 优先级为5（紧急）的对话不能被跳过
   - 这些对话在队列中显示🔒图标

**队列进度指示**：

在对话框底部显示当前进度：
```
[当前对话 1/3] [下一个: 柳如烟 - 关系事件] [跳过队列: Shift+ESC]
```

**设计目标**：
- ✅ 让玩家清楚知道还有多少对话要处理
- ✅ 提供跳过选项,尊重玩家时间
- ✅ 通过优先级颜色编码帮助玩家判断重要性
- ✅ 防止误操作（二次确认）
- ✅ 保护关键对话不被跳过

#### 4. 对话结束
- 对话UI淡出
- 游戏恢复正常
- 背景音乐音量恢复
- 玩家重新获得控制权

## Acceptance Criteria

### 核心功能验收

#### AC-1: 对话触发
**GIVEN** 玩家靠近NPC（距离<2米），**WHEN** 玩家按E键，**THEN** 对话系统启动，显示对话UI，加载对话数据

#### AC-2: 对话节点显示
**GIVEN** 对话数据加载成功，**WHEN** 对话开始，**THEN** 显示第一个对话节点的文本，NPC头像，打字机效果

#### AC-3: 选择项显示
**GIVEN** 对话节点有选择项，**WHEN** 文字显示完毕，**THEN** 显示所有满足条件的选择项，不满足条件的选择显示为灰色

#### AC-4: 选择确认
**GIVEN** 玩家选择了一个选项，**WHEN** 玩家按Enter或点击，**THEN** 执行选择的所有效果，跳转到下一个节点

#### AC-5: 关系值变化
**GIVEN** 选择包含relationship_change效果，**WHEN** 选择确认，**THEN** 关系值正确更新，显示浮动文字反馈，值被截断到[-100, 100]

#### AC-6: 道心值变化
**GIVEN** 选择包含dao_heart_change效果，**WHEN** 选择确认，**THEN** 道心值正确更新，显示浮动文字反馈，值被截断到[-100, 100]

#### AC-7: 条件判断
**GIVEN** 对话节点有条件，**WHEN** 评估条件，**THEN** 所有条件必须同时满足才显示节点/选择，不满足时跳过或显示为灰色

#### AC-8: 任务触发
**GIVEN** 选择包含quest_trigger效果，**WHEN** 选择确认，**THEN** 任务系统收到触发信号，任务正确启动

#### AC-9: 对话结束
**GIVEN** 对话节点的next_node为"END"，**WHEN** 节点显示完毕，**THEN** 对话UI关闭，游戏恢复正常，玩家重新获得控制权

#### AC-10: 对话历史
**GIVEN** 对话进行中，**WHEN** 玩家按Tab键，**THEN** 显示对话历史面板，包含最近100条对话，支持滚动

### 边缘情况验收

#### AC-11: 数据加载失败
**GIVEN** 对话文件不存在，**WHEN** 尝试加载对话，**THEN** 显示错误提示，记录错误日志，返回IDLE状态，不阻塞游戏

#### AC-12: 所有选择不可用
**GIVEN** 对话节点有选择但所有条件都不满足，**WHEN** 显示选择，**THEN** 自动跳转到next_node或结束对话，记录警告日志

#### AC-13: 循环引用检测
**GIVEN** 对话节点形成循环（A→B→C→A），**WHEN** 访问超过100个节点，**THEN** 强制结束对话，记录错误日志

#### AC-14: 效果执行失败
**GIVEN** 效果目标不存在（如无效任务ID），**WHEN** 执行效果，**THEN** 跳过该效果，继续执行后续效果，记录警告日志，不中断对话

#### AC-15: 对话中途退出
**GIVEN** 玩家在WAITING_CHOICE状态，**WHEN** 玩家按ESC或走远，**THEN** 保存对话进度，下次触发时询问是否继续

### 性能验收

#### AC-16: 对话加载性能
**GIVEN** 对话数据文件<100KB，**WHEN** 加载对话，**THEN** 加载时间<100ms

#### AC-17: UI响应性能
**GIVEN** 玩家选择一个选项，**WHEN** 点击或按Enter，**THEN** UI响应时间<50ms

#### AC-18: 内存占用
**GIVEN** 对话系统运行中，**WHEN** 监控内存，**THEN** 对话系统内存占用<10MB（不含语音文件）

### 集成验收

#### AC-19: 与关系系统集成
**GIVEN** 对话修改关系值，**WHEN** 对话结束，**THEN** 关系系统正确更新关系值，下次对话时条件判断使用新值

#### AC-20: 与任务系统集成
**GIVEN** 对话触发任务，**WHEN** 对话结束，**THEN** 任务系统正确启动任务，任务UI显示新任务

#### AC-21: 与战斗系统集成
**GIVEN** 对话触发战斗，**WHEN** 对话结束，**THEN** 战斗系统正确启动，对话UI关闭，战斗UI显示

#### AC-22: 与存档系统集成
**GIVEN** 对话进行中，**WHEN** 玩家保存游戏，**THEN** 对话进度正确保存，加载存档后可继续对话

### 用户体验验收

#### AC-23: 文字显示速度
**GIVEN** 对话文本显示，**WHEN** 观察显示速度，**THEN** 文字以可读速度显示（默认0.05秒/字符），可按Ctrl跳过

#### AC-24: 选择项可读性
**GIVEN** 对话有4个选择项，**WHEN** 显示选择，**THEN** 所有选择项完整显示，无文字截断，UI不拥挤

#### AC-25: 视觉反馈
**GIVEN** 玩家做出选择，**WHEN** 选择确认，**THEN** 显示关系值/道心值变化的浮动文字，持续2秒后淡出

### 对话重复验收

#### AC-26: 首次对话完整显示
**GIVEN** 玩家首次触发某个对话（completion_count == 0），**WHEN** 对话开始，**THEN** 显示完整的介绍性对话，包含详细背景信息和角色介绍

#### AC-27: 重复对话自动简化
**GIVEN** 玩家再次触发已完成的对话（completion_count > 0）且对话设置为可重复（is_repeatable = true），**WHEN** 对话开始，**THEN** 自动加载repeat_variant_id指定的简化版本对话，跳过已知信息

#### AC-28: 超过最大重复次数
**GIVEN** 玩家触发对话的次数已达到max_repeat_count，**WHEN** 再次尝试触发该对话，**THEN** 加载默认闲聊对话（default_idle_dialogue），不再显示原对话

#### AC-29: 主线对话不可重复
**GIVEN** 对话类型为"main"（主线对话）且已完成，**WHEN** 玩家尝试再次触发，**THEN** 对话不触发，NPC显示默认消息或无反应

#### AC-30: 闲聊对话变体轮换
**GIVEN** 闲聊对话配置了多个变体（variant_pool包含3个以上变体ID），**WHEN** 玩家连续多次触发该闲聊对话，**THEN** 系统按顺序轮换显示不同变体，避免连续重复相同内容

#### AC-31: 对话完成状态追踪
**GIVEN** 玩家完成一个对话，**WHEN** 对话结束，**THEN** 系统正确记录completion_count +1，下次触发时能正确读取完成次数

#### AC-32: 对话变体数据完整性
**GIVEN** 对话设置为可重复（is_repeatable = true），**WHEN** 系统加载对话数据，**THEN** 验证repeat_variant_id指向的对话文件存在且格式正确，如果不存在则记录错误日志并使用原对话

### 对话队列验收

#### AC-33: 对话队列排序
**GIVEN** 3个对话同时触发（优先级分别为5、3、4），**WHEN** 对话进入队列，**THEN** 队列按优先级排序为[5, 4, 3]，优先级高的在前

#### AC-34: 对话队列UI显示
**GIVEN** 对话队列中有2个或更多对话，**WHEN** 当前对话进行中，**THEN** 屏幕右上角显示队列指示器，包含队列总数、每个对话的优先级标签和NPC名称

#### AC-35: 对话队列自动处理
**GIVEN** 对话队列中有3个对话，**WHEN** 当前对话结束，**THEN** 自动开始队列中的下一个对话，无需玩家手动触发

#### AC-36: 对话队列超出限制
**GIVEN** 对话队列已满（达到dialogue_queue_max = 5），**WHEN** 第6个对话尝试加入队列，**THEN** 移除优先级最低且最早的对话，记录警告日志，新对话成功加入

#### AC-37: 跳过对话队列
**GIVEN** 对话队列中有3个对话，**WHEN** 玩家按Shift+ESC并确认"跳过全部"，**THEN** 所有对话标记为"已跳过"，对话UI关闭，游戏恢复正常

#### AC-38: 主线对话不可跳过
**GIVEN** 对话队列中包含主线对话（type: "main"）或紧急对话（priority = 5），**WHEN** 玩家尝试跳过队列，**THEN** 这些对话在队列中显示🔒图标，跳过操作不影响它们，它们仍会正常触发

## Open Questions

### 1. 语音系统优先级
**问题**：是否在MVP阶段实现语音系统？
**影响**：语音需要额外的录音、剪辑和集成工作
**建议**：MVP阶段跳过语音，完整版本再添加
**决策者**：制作人
**目标解决日期**：2026-05-10

### 2. 对话跳过机制
**问题**：是否允许玩家跳过已看过的对话？
**影响**：需要记录对话历史，增加存档大小
**建议**：允许跳过，但重要选择不可跳过
**决策者**：游戏设计师
**目标解决日期**：2026-05-15

### 3. 多语言支持
**问题**：MVP阶段是否支持英文本地化？
**影响**：需要翻译所有对话文本，增加工作量
**建议**：MVP仅中文，完整版本添加英文
**决策者**：制作人
**目标解决日期**：2026-05-10

### 4. 对话分支复杂度
**问题**：单个对话树最多允许多少个节点？
**影响**：影响对话编辑器设计和性能
**建议**：限制为100个节点，超过则拆分为多个对话
**决策者**：技术总监
**目标解决日期**：2026-05-20

### 5. NPC主动对话频率
**问题**：NPC主动找玩家对话的频率如何控制？
**影响**：过于频繁会打断玩家，过少会错过内容
**建议**：每个NPC每游戏日最多主动触发1次
**决策者**：游戏设计师
**目标解决日期**：2026-05-25