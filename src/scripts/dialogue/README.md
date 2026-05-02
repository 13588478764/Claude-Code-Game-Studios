# 对话系统和角色关系系统使用指南

## 概述

本文档介绍如何使用对话系统（Dialogue System）和角色关系系统（Relationship System）。这两个系统紧密集成，共同实现了《武侠奇遇录》的核心社交机制。

## 系统架构

### 角色关系系统

**核心文件**：
- `src/scripts/relationship/relationship_data.gd` - 数据结构定义
- `src/scripts/relationship/relationship_manager.gd` - 关系管理器

**主要功能**：
- 管理玩家与NPC的关系值（-100到+100）
- 管理玩家的道心值（-100到+100）
- 自动计算关系等级和道心等级
- 提供商店折扣、NPC态度修正等游戏机制
- 支持时间衰减和历史记录

### 对话系统

**核心文件**：
- `src/scripts/dialogue/dialogue_data.gd` - 对话数据结构
- `src/scripts/dialogue/dialogue_manager.gd` - 对话管理器

**主要功能**：
- 加载和管理对话树
- 处理对话分支和条件判断
- 执行对话效果（修改关系值、道心值等）
- 对话循环检测
- 对话队列管理

## 快速开始

### 1. 初始化系统

```gdscript
# 在游戏主场景中添加为自动加载（AutoLoad）
# 或者手动创建实例

# 创建关系管理器
var relationship_manager = RelationshipManager.new()
add_child(relationship_manager)

# 创建对话管理器
var dialogue_manager = DialogueManager.new()
add_child(dialogue_manager)
```

### 2. 使用关系系统

```gdscript
# 修改关系值
relationship_manager.modify_relationship("yunzhonghe", 10, "帮助完成任务")

# 获取关系值
var rel_value = relationship_manager.get_relationship_value("yunzhonghe")
print("与云中鹤的关系值: ", rel_value)

# 获取关系等级
var rel_level = relationship_manager.get_relationship_level("yunzhonghe")
print("关系等级: ", RelationshipData.NPCRelationship.get_level_name(rel_level))

# 修改道心值
relationship_manager.modify_dao_heart(5, "正义行为")

# 获取商店折扣
var discount = relationship_manager.get_shop_discount("merchant_npc")
print("折扣率: ", discount * 100, "%")
```

### 3. 使用对话系统

```gdscript
# 加载对话树
dialogue_manager.load_dialogue_from_json("res://data/dialogues/example_dialogue.json")

# 监听对话事件
dialogue_manager.dialogue_started.connect(_on_dialogue_started)
dialogue_manager.node_displayed.connect(_on_node_displayed)
dialogue_manager.choice_selected.connect(_on_choice_selected)
dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

# 开始对话
dialogue_manager.start_dialogue("yunzhonghe_first_meeting")

# 选择选项（在UI中调用）
func _on_choice_button_pressed(choice_index: int):
    dialogue_manager.select_choice(choice_index)

# 事件处理
func _on_node_displayed(node: DialogueData.DialogueNode):
    # 更新UI显示对话文本
    dialogue_label.text = node.text
    
    # 显示选择按钮
    var choices = dialogue_manager.get_available_choices()
    for i in choices.size():
        choice_buttons[i].text = choices[i].text
        choice_buttons[i].visible = true

func _on_dialogue_ended(dialogue_id: String):
    # 隐藏对话UI
    dialogue_panel.visible = false
```

## 创建对话数据

### JSON格式

对话数据使用JSON格式存储在 `data/dialogues/` 目录下。

**基本结构**：

```json
{
  "id": "dialogue_id",
  "title": "对话标题",
  "description": "对话描述",
  "start_node": "第一个节点ID",
  "nodes": [
    {
      "id": "node_1",
      "speaker": "npc_id",
      "text": "对话文本",
      "emotion": "neutral",
      "choices": [
        {
          "id": "choice_1",
          "text": "选择文本",
          "dao_heart_hint": 5,
          "effects": [
            {
              "type": "modify_relationship",
              "target": "npc_id",
              "value": 10,
              "reason": "原因"
            }
          ],
          "next_node": "node_2"
        }
      ]
    }
  ]
}
```

### 条件类型

支持的条件类型：
- `relationship` - 关系值条件
- `dao_heart` - 道心值条件
- `realm_level` - 境界等级条件
- `quest_status` - 任务状态条件
- `item_owned` - 物品持有条件
- `flag` - 标志位条件

**示例**：

```json
{
  "type": "relationship",
  "target": "yunzhonghe",
  "value": 50,
  "operator": ">="
}
```

### 效果类型

支持的效果类型：
- `modify_relationship` - 修改关系值
- `modify_dao_heart` - 修改道心值
- `unlock_quest` - 解锁任务
- `give_item` - 给予物品
- `give_exp` - 给予经验
- `set_flag` - 设置标志位

**示例**：

```json
{
  "type": "modify_relationship",
  "target": "yunzhonghe",
  "value": 10,
  "reason": "帮助完成任务"
}
```

## 代码方式创建对话

除了JSON，也可以用代码创建对话树：

```gdscript
# 创建对话树
var tree = DialogueData.DialogueTree.new("test_dialogue", "测试对话")
tree.start_node = "greeting"

# 创建节点
var greeting = DialogueData.DialogueNode.new("greeting", "npc_test", "你好！")

# 创建选择
var choice1 = DialogueData.Choice.new("choice_1", "你好", "response")
choice1.effects.append(
    DialogueData.ModifyRelationshipEffect.new("npc_test", 5, "友好回应")
)

greeting.choices.append(choice1)
tree.add_node(greeting)

# 注册对话树
dialogue_manager.register_dialogue_tree(tree)
```

## 关系等级说明

### 关系等级

| 等级 | 关系值范围 | 名称 | 解锁内容 |
|------|-----------|------|----------|
| -3 | -100到-50 | 仇敌 | 无 |
| -2 | -49到-10 | 冷淡 | 无 |
| -1 | -9到+9 | 中立 | 基础对话、基础交易 |
| 0 | +10到+49 | 友好 | 额外对话、商店折扣10% |
| 1 | +50到+79 | 亲密 | 支线任务、背景故事、特殊训练、商店折扣20% |
| 2 | +80到+100 | 挚友/恋人 | 专属剧情、技能传授、恋爱线、商店折扣30% |

### 道心等级

| 等级 | 道心值范围 | 名称 | 影响 |
|------|-----------|------|------|
| -2 | -100到-60 | 魔道宗师 | 只能修炼魔道功法，正道NPC敌视 |
| -1 | -59到-30 | 魔道倾向 | 魔道功法加成，正道NPC冷淡 |
| 0 | -29到+29 | 中立 | 可修炼所有功法 |
| 1 | +30到+59 | 正道倾向 | 正道功法加成，正道NPC友好 |
| 2 | +60到+100 | 正道宗师 | 只能修炼正道功法，魔道NPC敌视 |

## 信号说明

### 关系系统信号

```gdscript
# 关系值改变
relationship_changed(npc_id: String, old_value: int, new_value: int)

# 关系等级改变
relationship_level_changed(npc_id: String, old_level, new_level)

# 道心值改变
dao_heart_changed(old_value: int, new_value: int)

# 道心等级改变
dao_heart_level_changed(old_level, new_level)

# 道心极端转换
dao_heart_extreme_change()
```

### 对话系统信号

```gdscript
# 对话开始
dialogue_started(dialogue_id: String)

# 对话结束
dialogue_ended(dialogue_id: String)

# 节点显示
node_displayed(node: DialogueData.DialogueNode)

# 选择被选中
choice_selected(choice: DialogueData.Choice)

# 对话错误
dialogue_error(error_message: String)
```

## 保存和加载

两个系统都支持保存和加载：

```gdscript
# 保存
var save_data = {
    "relationship": relationship_manager.save_data(),
    "dialogue": dialogue_manager.save_data()
}

# 加载
relationship_manager.load_data(save_data["relationship"])
dialogue_manager.load_data(save_data["dialogue"])
```

## 测试

运行单元测试：

```bash
# 测试关系系统
godot --headless -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_relationship_system.gd

# 测试对话系统
godot --headless -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_dialogue_system.gd
```

## 最佳实践

1. **关系值变化要有理由**：每次修改关系值时都提供清晰的原因字符串
2. **使用信号响应变化**：监听关系等级变化信号来触发UI更新和内容解锁
3. **验证对话树**：在注册前确保对话树通过验证
4. **避免对话循环**：系统会自动检测，但设计时应避免无意义的循环
5. **合理设置条件**：确保对话选项的条件合理，避免所有选项都不可用的情况
6. **测试多种路径**：对话树应该测试所有可能的分支路径

## 示例项目

参考 `data/dialogues/example_dialogue.json` 查看完整的对话示例。

## 故障排除

### 对话无法开始

- 检查对话树ID是否正确
- 确认对话树已注册
- 验证start_node是否存在

### 关系值不变化

- 确认RelationshipManager已正确初始化
- 检查是否使用了正确的NPC ID
- 验证global_multiplier是否为0

### 对话循环错误

- 检查对话树中是否有无限循环
- 确认next_node指向正确的节点或"END"

## 更多信息

- 查看GDD文档：`design/gdd/dialogue-system.md`
- 查看GDD文档：`design/gdd/character-relationship-system.md`
- 查看测试文件了解更多用法示例