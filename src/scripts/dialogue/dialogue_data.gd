## 对话数据结构
## 定义对话节点、选择、条件和效果的数据结构
extends RefCounted
class_name DialogueData

## 对话节点
class DialogueNode:
	var id: String = ""  # 唯一标识符，格式：SCENE_NPC_NUMBER
	var speaker: String = ""  # 说话者ID（NPC或"player"）
	var text: String = ""  # 对话文本（支持{变量}占位符）
	var choices: Array[Choice] = []  # 玩家选择项
	var conditions: Array[Condition] = []  # 显示条件
	var effects: Array[Effect] = []  # 对话后自动触发的效果
	var next_node: String = ""  # 下一个节点ID（无选择时使用）
	var audio_cue: String = ""  # 语音文件路径（可选）
	var emotion: String = "neutral"  # 角色情绪标签
	var priority: int = 1  # 对话优先级（1-5，5最高）
	var timeout: int = 0  # 选择超时时间（秒，0表示无超时）
	
	func _init(node_id: String = "", speaker_id: String = "", dialogue_text: String = "") -> void:
		id = node_id
		speaker = speaker_id
		text = dialogue_text
	
	## 检查是否满足所有条件
	func check_conditions() -> bool:
		for condition in conditions:
			if not condition.evaluate():
				return false
		return true
	
	## 获取可用的选择项
	func get_available_choices() -> Array[Choice]:
		var available: Array[Choice] = []
		for choice in choices:
			if choice.check_conditions():
				available.append(choice)
		return available
	
	## 执行节点效果
	func execute_effects() -> void:
		for effect in effects:
			effect.execute()

## 玩家选择
class Choice:
	var id: String = ""  # 选择ID
	var text: String = ""  # 选择文本（最多60字符）
	var conditions: Array[Condition] = []  # 显示条件
	var effects: Array[Effect] = []  # 选择后效果
	var next_node: String = ""  # 跳转节点ID
	var icon: String = ""  # 选择图标（可选）
	var dao_heart_hint: int = 0  # 道心值提示（正数=正道，负数=魔道）
	
	func _init(choice_id: String = "", choice_text: String = "", next_id: String = "") -> void:
		id = choice_id
		text = choice_text
		next_node = next_id
	
	## 检查是否满足所有条件
	func check_conditions() -> bool:
		for condition in conditions:
			if not condition.evaluate():
				return false
		return true
	
	## 执行选择效果
	func execute_effects() -> void:
		for effect in effects:
			effect.execute()

## 条件基类
class Condition:
	enum ConditionType {
		REALM_LEVEL,        # 境界等级
		RELATIONSHIP,       # 关系值
		DAO_HEART,          # 道心值
		QUEST_STATUS,       # 任务状态
		ITEM_OWNED,         # 物品持有
		TIME,               # 时间条件
		LOCATION,           # 地点条件
		FLAG,               # 标志位
		ATTRIBUTE,          # 属性值
		CUSTOM              # 自定义条件
	}
	
	var type: ConditionType = ConditionType.CUSTOM
	var operator: String = "=="  # ==, !=, >, <, >=, <=, contains
	var target: String = ""  # 目标ID（NPC、任务、物品等）
	var value: Variant = null  # 比较值
	
	func _init(cond_type: ConditionType = ConditionType.CUSTOM) -> void:
		type = cond_type
	
	## 评估条件（需要子类实现）
	func evaluate() -> bool:
		return true

## 境界等级条件
class RealmLevelCondition extends Condition:
	func _init(min_level: int = 1) -> void:
		super._init(ConditionType.REALM_LEVEL)
		value = min_level
	
	func evaluate() -> bool:
		# 这里需要访问玩家的境界等级
		# 暂时返回true，实际实现需要连接到角色系统
		return true

## 关系值条件
class RelationshipCondition extends Condition:
	func _init(npc_id: String = "", min_value: int = 0, op: String = ">=") -> void:
		super._init(ConditionType.RELATIONSHIP)
		target = npc_id
		value = min_value
		operator = op

	func evaluate() -> bool:
		var rel_manager = DialogueData._get_relationship_manager()
		if rel_manager == null:
			return false

		var current_value: int = rel_manager.get_relationship_value(target)
		return DialogueData._compare(current_value, operator, value)

## 道心值条件
class DaoHeartCondition extends Condition:
	func _init(min_value: int = 0, op: String = ">=") -> void:
		super._init(ConditionType.DAO_HEART)
		value = min_value
		operator = op

	func evaluate() -> bool:
		var rel_manager = DialogueData._get_relationship_manager()
		if rel_manager == null:
			return false

		var current_value: int = rel_manager.get_dao_heart_value()
		return DialogueData._compare(current_value, operator, value)

## 任务状态条件
class QuestStatusCondition extends Condition:
	func _init(quest_id: String = "", status: String = "completed") -> void:
		super._init(ConditionType.QUEST_STATUS)
		target = quest_id
		value = status
	
	func evaluate() -> bool:
		# 需要访问任务管理器
		# 暂时返回true
		return true

## 物品持有条件
class ItemOwnedCondition extends Condition:
	func _init(item_id: String = "", min_count: int = 1) -> void:
		super._init(ConditionType.ITEM_OWNED)
		target = item_id
		value = min_count
	
	func evaluate() -> bool:
		# 需要访问物品管理器
		# 暂时返回true
		return true

## 标志位条件
class FlagCondition extends Condition:
	func _init(flag_name: String = "", flag_value: bool = true) -> void:
		super._init(ConditionType.FLAG)
		target = flag_name
		value = flag_value
	
	func evaluate() -> bool:
		# 需要访问游戏状态管理器
		# 暂时返回true
		return true

## 效果基类
class Effect:
	enum EffectType {
		MODIFY_RELATIONSHIP,  # 修改关系值
		MODIFY_DAO_HEART,     # 修改道心值
		UNLOCK_QUEST,         # 解锁任务
		GIVE_ITEM,            # 给予物品
		GIVE_EXP,             # 给予经验
		SET_FLAG,             # 设置标志位
		TRIGGER_EVENT,        # 触发事件
		CUSTOM                # 自定义效果
	}
	
	var type: EffectType = EffectType.CUSTOM
	var target: String = ""  # 目标ID
	var value: Variant = null  # 效果值
	var reason: String = ""  # 原因描述
	
	func _init(effect_type: EffectType = EffectType.CUSTOM) -> void:
		type = effect_type
	
	## 执行效果（需要子类实现）
	func execute() -> void:
		pass

## 修改关系值效果
class ModifyRelationshipEffect extends Effect:
	func _init(npc_id: String = "", delta: int = 0, cause: String = "") -> void:
		super._init(EffectType.MODIFY_RELATIONSHIP)
		target = npc_id
		value = delta
		reason = cause

	func execute() -> void:
		var rel_manager = DialogueData._get_relationship_manager()
		if rel_manager == null:
			return
		rel_manager.modify_relationship(target, int(value), reason)

## 修改道心值效果
class ModifyDaoHeartEffect extends Effect:
	func _init(delta: int = 0, cause: String = "") -> void:
		super._init(EffectType.MODIFY_DAO_HEART)
		value = delta
		reason = cause

	func execute() -> void:
		var rel_manager = DialogueData._get_relationship_manager()
		if rel_manager == null:
			return
		rel_manager.modify_dao_heart(int(value), reason)

## 解锁任务效果
class UnlockQuestEffect extends Effect:
	func _init(quest_id: String = "") -> void:
		super._init(EffectType.UNLOCK_QUEST)
		target = quest_id
	
	func execute() -> void:
		# 需要访问任务管理器
		print("[对话效果] 解锁任务: %s" % target)

## 给予物品效果
class GiveItemEffect extends Effect:
	func _init(item_id: String = "", count: int = 1) -> void:
		super._init(EffectType.GIVE_ITEM)
		target = item_id
		value = count

	func execute() -> void:
		var inv = Engine.get_main_loop().root.get_node_or_null("InventorySystem")
		if inv and inv.has_method("add_item"):
			inv.add_item(target, int(value))
		print("[对话效果] 给予物品: %s x%d" % [target, value])

## 给予经验效果
class GiveExpEffect extends Effect:
	func _init(exp_amount: int = 0) -> void:
		super._init(EffectType.GIVE_EXP)
		value = exp_amount

	func execute() -> void:
		var char_sys = Engine.get_main_loop().root.get_node_or_null("CharacterSystem")
		if char_sys and char_sys.has_method("add_experience"):
			char_sys.add_experience(int(value))
		print("[对话效果] 给予经验: %d" % value)

## 设置标志位效果
class SetFlagEffect extends Effect:
	func _init(flag_name: String = "", flag_value: bool = true) -> void:
		super._init(EffectType.SET_FLAG)
		target = flag_name
		value = flag_value
	
	func execute() -> void:
		# 需要访问游戏状态管理器
		print("[对话效果] 设置标志位: %s = %s" % [target, value])

## 声望变化效果（新增）
class ChangeReputationEffect extends Effect:
	func _init(faction_id: String = "", delta: int = 0, cause: String = "") -> void:
		super._init(EffectType.CUSTOM)
		target = faction_id
		value = delta
		reason = cause
	
	func execute() -> void:
		print("[对话效果] 声望变化: %s %+d (%s)" % [target, value, reason])

## 给予技能效果（新增）
class GiveSkillEffect extends Effect:
	func _init(skill_id: String = "", skill_level: int = 1) -> void:
		super._init(EffectType.CUSTOM)
		target = skill_id
		value = skill_level
	
	func execute() -> void:
		print("[对话效果] 获得技能: %s (等级%d)" % [target, value])

## 消耗物品效果（新增）
class ConsumeItemEffect extends Effect:
	func _init(item_id: String = "", count: int = 1) -> void:
		super._init(EffectType.CUSTOM)
		target = item_id
		value = count
	
	func execute() -> void:
		print("[对话效果] 消耗物品: %s x%d" % [target, value])

## 时间消耗效果（新增）
class ConsumeTimeEffect extends Effect:
	func _init(minutes: int = 0) -> void:
		super._init(EffectType.CUSTOM)
		value = minutes
	
	func execute() -> void:
		print("[对话效果] 时间流逝: %d分钟" % value)

## 体力消耗效果（新增）
class ConsumeStrengthEffect extends Effect:
	func _init(amount: int = 0) -> void:
		super._init(EffectType.CUSTOM)
		value = amount
	
	func execute() -> void:
		print("[对话效果] 体力消耗: %d" % value)

## 地图标记效果（新增）
class MapMarkEffect extends Effect:
	func _init(mark_id: String = "", mark_value: bool = true) -> void:
		super._init(EffectType.CUSTOM)
		target = mark_id
		value = mark_value
	
	func execute() -> void:
		print("[对话效果] 地图标记: %s = %s" % [target, value])

## 打开商店效果（新增）
class OpenShopEffect extends Effect:
	func _init(shop_id: String = "") -> void:
		super._init(EffectType.CUSTOM)
		target = shop_id
	
	func execute() -> void:
		print("[对话效果] 打开商店: %s" % target)

## 触发战斗效果（对话-战斗联动）
class TriggerCombatEffect extends Effect:
	var encounter_config: Dictionary = {}
	var callback_node: String = ""
	
	func _init(encounter_id: String = "", config: Dictionary = {}, cb: String = "") -> void:
		super._init(EffectType.CUSTOM)
		target = encounter_id
		encounter_config = config
		callback_node = cb
	
	func execute() -> void:
		print("[对话效果] 触发战斗: %s" % target)
		# 通过DialogueManager的信号总线转发战斗触发请求
		var dialogue_mgr = Engine.get_main_loop().get_root().get_node("DialogueManager")
		if dialogue_mgr != null and dialogue_mgr.has_signal("combat_trigger_requested"):
			dialogue_mgr.combat_trigger_requested.emit(target, encounter_config, callback_node)

## 对话树数据
class DialogueTree:
	var id: String = ""  # 对话树ID
	var title: String = ""  # 对话树标题
	var description: String = ""  # 描述
	var start_node: String = ""  # 起始节点ID
	var nodes: Dictionary = {}  # {node_id: DialogueNode}
	var metadata: Dictionary = {}  # 元数据
	
	func _init(tree_id: String = "", tree_title: String = "") -> void:
		id = tree_id
		title = tree_title
	
	## 添加节点
	func add_node(node: DialogueNode) -> void:
		nodes[node.id] = node
	
	## 获取节点
	func get_node(node_id: String) -> DialogueNode:
		return nodes.get(node_id, null)
	
	## 获取起始节点
	func get_start_node() -> DialogueNode:
		return get_node(start_node)
	
	## 验证对话树完整性
	func validate() -> bool:
		if start_node.is_empty():
			push_error("对话树 %s 缺少起始节点" % id)
			return false
		
		if not nodes.has(start_node):
			push_error("对话树 %s 的起始节点 %s 不存在" % [id, start_node])
			return false
		
		# 检查所有节点的next_node是否存在
		for node_id in nodes.keys():
			var node: DialogueNode = nodes[node_id]
			
			# 检查next_node（处理null值）
			var next: String = node.next_node if node.next_node != null else ""
			if not next.is_empty() and next != "END":
				if not nodes.has(next):
					push_error("节点 %s 的next_node %s 不存在" % [node_id, next])
					return false
			
			# 检查选择的next_node
			for choice in node.choices:
				var choice_next: String = choice.next_node if choice.next_node != null else ""
				if not choice_next.is_empty() and choice_next != "END":
					if not nodes.has(choice_next):
						push_error("节点 %s 的选择 %s 的next_node %s 不存在" % [node_id, choice.id, choice_next])
						return false
		
		return true

## 通过SceneTree根节点访问Autoload单例
static func _get_scene_root() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop == null:
		return null
	return main_loop.root

static func _get_relationship_manager():
	var root := _get_scene_root()
	if root == null:
		return null
	return root.get_node_or_null("RelationshipManager")

## 比较运算辅助函数
static func _compare(current: int, op: String, target_val: Variant) -> bool:
	var tv: int = int(target_val)
	match op:
		"==":
			return current == tv
		"!=":
			return current != tv
		">":
			return current > tv
		"<":
			return current < tv
		">=":
			return current >= tv
		"<=":
			return current <= tv
		_:
			return false
