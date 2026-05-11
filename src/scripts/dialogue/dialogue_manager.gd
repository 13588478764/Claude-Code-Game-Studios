## 对话管理器
## 管理对话树的加载、执行和状态
extends Node

## 信号
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal node_displayed(node: DialogueData.DialogueNode)
signal choice_selected(choice: DialogueData.Choice)
signal dialogue_error(error_message: String)

## 对话-战斗联动信号
signal combat_trigger_requested(encounter_id: String, config: Dictionary, callback_node: String)

## 对话树数据库 {dialogue_id: DialogueTree}
var _dialogue_trees: Dictionary = {}

## 当前对话状态
var _current_dialogue: DialogueData.DialogueTree = null
var _current_node: DialogueData.DialogueNode = null
var _dialogue_history: Array[String] = []  # 节点ID历史

## 对话循环检测
var _visited_nodes: Dictionary = {}  # {dialogue_id: {node_id: visit_count}}
const MAX_VISITS_PER_NODE: int = 3
const MAX_TOTAL_NODES: int = 100

## 对话队列（用于NPC主动触发）
var _dialogue_queue: Array[Dictionary] = []

## 是否正在对话中
var _is_in_dialogue: bool = false

## 关系管理器引用
var _relationship_manager: RelationshipManager = null

## 对话-战斗桥接器引用
var _dialogue_combat_bridge = null

func _ready() -> void:
	# 尝试获取关系管理器
	if has_node("/root/RelationshipManager"):
		_relationship_manager = get_node("/root/RelationshipManager")
	
	# 尝试获取对话-战斗桥接器
	if has_node("/root/DialogueCombatBridge"):
		_dialogue_combat_bridge = get_node("/root/DialogueCombatBridge")
	
	# 自动加载data/dialogues目录下所有对话JSON文件
	_load_all_dialogues()

## 自动加载所有对话JSON文件（包括子目录）
func _load_all_dialogues() -> void:
	var loaded_count := _load_dialogues_recursive("res://data/dialogues/")
	print("[DialogueManager] Auto-loaded %d dialogue files from res://data/dialogues/" % loaded_count)

## 递归加载对话文件
func _load_dialogues_recursive(dir_path: String) -> int:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		print("[DialogueManager] No dialogues directory found: %s, skipping auto-load" % dir_path)
		return 0
	
	var sub_dirs: Array[String] = []
	var loaded_count := 0
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			sub_dirs.append(dir_path + file_name + "/")
		elif file_name.ends_with(".json"):
			var file_path := dir_path + file_name
			if load_dialogue_from_json(file_path):
				loaded_count += 1
			else:
				push_warning("[DialogueManager] Failed to load dialogue: %s" % file_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# 递归加载子目录
	for sub_dir in sub_dirs:
		loaded_count += _load_dialogues_recursive(sub_dir)
	
	return loaded_count

## 注册对话树
func register_dialogue_tree(tree: DialogueData.DialogueTree) -> bool:
	if tree.id.is_empty():
		push_error("对话树ID不能为空")
		return false
	
	if not tree.validate():
		push_error("对话树 %s 验证失败" % tree.id)
		return false
	
	_dialogue_trees[tree.id] = tree
	print("[对话系统] 注册对话树: %s" % tree.id)
	return true

## 从JSON加载对话树
func load_dialogue_from_json(json_path: String) -> bool:
	if not FileAccess.file_exists(json_path):
		push_error("对话文件不存在: %s" % json_path)
		return false
	
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("无法打开对话文件: %s" % json_path)
		return false
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_text)
	
	if parse_result != OK:
		push_error("JSON解析失败: %s" % json_path)
		return false
	
	var data: Dictionary = json.data
	var tree := _parse_dialogue_tree(data)
	
	if tree == null:
		return false
	
	return register_dialogue_tree(tree)

## 解析对话树数据
func _parse_dialogue_tree(data: Dictionary) -> DialogueData.DialogueTree:
	var tree := DialogueData.DialogueTree.new(
		data.get("id", ""),
		data.get("title", "")
	)
	
	tree.description = data.get("description", "")
	tree.start_node = data.get("start_node", "")
	tree.metadata = data.get("metadata", {})
	
	# 解析节点
	var nodes_data: Array = data.get("nodes", [])
	for node_data in nodes_data:
		var node := _parse_dialogue_node(node_data)
		if node != null:
			tree.add_node(node)
	
	return tree

## 解析对话节点
func _parse_dialogue_node(data: Dictionary) -> DialogueData.DialogueNode:
	var node := DialogueData.DialogueNode.new(
		data.get("id", ""),
		data.get("speaker", ""),
		data.get("text", "")
	)
	
	var next_val: Variant = data.get("next_node", "")
	node.next_node = next_val if next_val != null else ""
	node.audio_cue = data.get("audio_cue", "")
	node.emotion = data.get("emotion", "neutral")
	node.priority = data.get("priority", 1)
	node.timeout = data.get("timeout", 0)
	
	# 解析条件
	var conditions_data: Array = data.get("conditions", [])
	for cond_data in conditions_data:
		var condition := _parse_condition(cond_data)
		if condition != null:
			node.conditions.append(condition)
	
	# 解析效果
	var effects_data: Array = data.get("effects", [])
	for effect_data in effects_data:
		var effect := _parse_effect(effect_data)
		if effect != null:
			node.effects.append(effect)
	
	# 解析选择
	var choices_data: Array = data.get("choices", [])
	for choice_data in choices_data:
		var choice := _parse_choice(choice_data)
		if choice != null:
			node.choices.append(choice)
	
	return node

## 解析选择
func _parse_choice(data: Dictionary) -> DialogueData.Choice:
	var choice := DialogueData.Choice.new(
		data.get("id", ""),
		data.get("text", ""),
		data.get("next_node", "")
	)
	
	choice.icon = data.get("icon", "")
	choice.dao_heart_hint = data.get("dao_heart_hint", 0)
	
	# 解析条件
	var conditions_data: Array = data.get("conditions", [])
	for cond_data in conditions_data:
		var condition := _parse_condition(cond_data)
		if condition != null:
			choice.conditions.append(condition)
	
	# 解析效果
	var effects_data: Array = data.get("effects", [])
	for effect_data in effects_data:
		var effect := _parse_effect(effect_data)
		if effect != null:
			choice.effects.append(effect)
	
	return choice

## 解析条件
func _parse_condition(data: Dictionary) -> DialogueData.Condition:
	var type_str: String = data.get("type", "custom")
	var condition: DialogueData.Condition = null
	
	# 统一格式：支持设计文档中的别名
	match type_str:
		# 关系值条件（支持 relationship 和 relationship_check）
		"relationship", "relationship_check":
			condition = DialogueData.RelationshipCondition.new(
				data.get("target", ""),
				data.get("value", 0),
				data.get("operator", ">=")
			)
		# 道心值条件（支持 dao_heart 和 dao_heart_check）
		"dao_heart", "dao_heart_check":
			condition = DialogueData.DaoHeartCondition.new(
				data.get("value", 0),
				data.get("operator", ">=")
			)
		"realm_level":
			condition = DialogueData.RealmLevelCondition.new(
				data.get("value", 1)
			)
		"quest_status":
			condition = DialogueData.QuestStatusCondition.new(
				data.get("target", ""),
				data.get("value", "completed")
			)
		"item_owned":
			condition = DialogueData.ItemOwnedCondition.new(
				data.get("target", ""),
				data.get("value", 1)
			)
		"flag":
			condition = DialogueData.FlagCondition.new(
				data.get("target", ""),
				data.get("value", true)
			)
		_:
			condition = DialogueData.Condition.new()
	
	return condition

## 解析效果
func _parse_effect(data: Dictionary) -> DialogueData.Effect:
	var type_str: String = data.get("type", "custom")
	var effect: DialogueData.Effect = null
	
	# 统一格式：同时支持旧格式和设计文档中的新格式
	match type_str:
		# 关系值变化（支持 modify_relationship 和 relationship_change）
		"modify_relationship", "relationship_change":
			effect = DialogueData.ModifyRelationshipEffect.new(
				data.get("target", ""),
				data.get("value", 0),
				data.get("reason", "")
			)
		# 道心值变化（支持 modify_dao_heart 和 dao_heart_change）
		"modify_dao_heart", "dao_heart_change":
			effect = DialogueData.ModifyDaoHeartEffect.new(
				data.get("value", 0),
				data.get("reason", "")
			)
		# 解锁任务（支持 unlock_quest 和 quest_trigger）
		"unlock_quest", "quest_trigger":
			effect = DialogueData.UnlockQuestEffect.new(
				data.get("target", "")
			)
		# 给予物品（支持 give_item 和 item_give）
		"give_item", "item_give":
			effect = DialogueData.GiveItemEffect.new(
				data.get("target", ""),
				data.get("value", 1)
			)
		"give_exp":
			effect = DialogueData.GiveExpEffect.new(
				data.get("value", 0)
			)
		# 设置标志位
		"set_flag":
			effect = DialogueData.SetFlagEffect.new(
				data.get("target", ""),
				data.get("value", true)
			)
		# 声望变化（新增）
		"reputation_change":
			effect = DialogueData.ChangeReputationEffect.new(
				data.get("target", ""),
				data.get("value", 0)
			)
		# 给予技能（新增）
		"skill_give":
			effect = DialogueData.GiveSkillEffect.new(
				data.get("target", ""),
				data.get("value", 1)
			)
		# 消耗物品/灵气（新增）
		"item_cost", "spirit_cost":
			effect = DialogueData.ConsumeItemEffect.new(
				data.get("target", ""),
				data.get("value", 1)
			)
		# 时间消耗（新增）
		"time_cost":
			effect = DialogueData.ConsumeTimeEffect.new(
				data.get("value", 0)
			)
		# 体力消耗（新增）
		"strength_cost":
			effect = DialogueData.ConsumeStrengthEffect.new(
				data.get("value", 0)
			)
		# 地图标记（新增）
		"map_mark":
			effect = DialogueData.MapMarkEffect.new(
				data.get("target", ""),
				true
			)
		# 商店打开（新增）
		"shop_open":
			effect = DialogueData.OpenShopEffect.new(
				data.get("target", "")
			)
		# 功法解锁（新增）
		"martial_art_unlock", "quest_complete":
			effect = DialogueData.UnlockQuestEffect.new(
				data.get("target", "")
			)
		# 被动技能给予
		"passive_give":
			effect = DialogueData.GiveSkillEffect.new(
				data.get("target", ""),
				1
			)
		# 触发战斗（对话-战斗联动）
		"trigger_combat":
			effect = DialogueData.TriggerCombatEffect.new(
				data.get("target", ""),
				data.get("config", {}),
				data.get("callback_node", "")
			)
		_:
			effect = DialogueData.Effect.new()
	
	return effect

## 开始对话（通过对话ID）
func start_dialogue(dialogue_id: String) -> bool:
	if _is_in_dialogue:
		push_warning("已经在对话中，无法开始新对话")
		return false
	
	if not _dialogue_trees.has(dialogue_id):
		push_error("对话树不存在: %s" % dialogue_id)
		dialogue_error.emit("对话树不存在: %s" % dialogue_id)
		return false
	
	_current_dialogue = _dialogue_trees[dialogue_id]
	_current_node = _current_dialogue.get_start_node()
	
	if _current_node == null:
		push_error("对话树 %s 没有起始节点" % dialogue_id)
		dialogue_error.emit("对话树没有起始节点")
		return false
	
	# 重置状态
	_dialogue_history.clear()
	_visited_nodes[dialogue_id] = {}
	_is_in_dialogue = true
	
	# 发送信号
	dialogue_started.emit(dialogue_id)
	
	# 显示第一个节点
	_display_current_node()
	
	return true

## 检查对话树是否存在
func has_dialogue(dialogue_id: String) -> bool:
	return _dialogue_trees.has(dialogue_id)

## 是否正在对话中
func is_in_dialogue() -> bool:
	return _is_in_dialogue

## 获取当前对话ID
func get_current_dialogue_id() -> String:
	if _current_dialogue == null:
		return ""
	return _current_dialogue.id

## 通过NPC ID触发对应对话（用于NPC交互触发）
func start_dialogue_with_npc(npc_id: String) -> bool:
	# 遍历所有已加载的对话，查找与NPC匹配的对话树
	for dialogue_id in _dialogue_trees:
		var tree: DialogueData.DialogueTree = _dialogue_trees[dialogue_id]
		if tree.metadata.has("npc_id") and tree.metadata.npc_id == npc_id:
			return start_dialogue(dialogue_id)
	
	push_warning("没有找到NPC %s 的对话树" % npc_id)
	return false

## 显示当前节点
func _display_current_node() -> void:
	if _current_node == null:
		return
	
	# 检查循环
	if _check_loop(_current_dialogue.id, _current_node.id):
		push_error("检测到对话循环，强制结束对话")
		dialogue_error.emit("检测到对话循环")
		end_dialogue()
		return
	
	# 检查条件
	if not _current_node.check_conditions():
		# 条件不满足，跳到下一个节点
		if not _current_node.next_node.is_empty():
			_goto_node(_current_node.next_node)
		else:
			end_dialogue()
		return
	
	# 记录历史
	_dialogue_history.append(_current_node.id)
	
	# 执行节点效果
	_current_node.execute_effects()
	
	# 发送信号
	node_displayed.emit(_current_node)
	
	# 如果没有选择，自动继续
	if _current_node.choices.is_empty():
		if not _current_node.next_node.is_empty():
			# 延迟跳转，给UI时间显示
			var scene_tree := get_tree()
			if scene_tree != null:
				await scene_tree.create_timer(0.5).timeout
				_goto_node(_current_node.next_node)
		else:
			end_dialogue()

## 选择选项
func select_choice(choice_index: int) -> void:
	if not _is_in_dialogue or _current_node == null:
		return
	
	var available_choices := _current_node.get_available_choices()
	
	if choice_index < 0 or choice_index >= available_choices.size():
		push_error("无效的选择索引: %d" % choice_index)
		return
	
	var choice := available_choices[choice_index]
	
	# 执行选择效果
	choice.execute_effects()
	
	# 发送信号
	choice_selected.emit(choice)
	
	# 跳转到下一个节点
	if not choice.next_node.is_empty():
		_goto_node(choice.next_node)
	else:
		end_dialogue()

## 跳转到指定节点
func _goto_node(node_id: String) -> void:
	if node_id == "END":
		end_dialogue()
		return
	
	if _current_dialogue == null:
		return
	
	var next_node := _current_dialogue.get_node(node_id)
	
	if next_node == null:
		push_error("节点不存在: %s" % node_id)
		dialogue_error.emit("节点不存在: %s" % node_id)
		end_dialogue()
		return
	
	_current_node = next_node
	_display_current_node()

## 结束对话
func end_dialogue() -> void:
	if not _is_in_dialogue:
		return
	
	var dialogue_id := _current_dialogue.id if _current_dialogue != null else ""
	
	_current_dialogue = null
	_current_node = null
	_is_in_dialogue = false
	
	# 清理访问记录
	if not dialogue_id.is_empty() and _visited_nodes.has(dialogue_id):
		_visited_nodes.erase(dialogue_id)
	
	dialogue_ended.emit(dialogue_id)

## 检查对话循环
func _check_loop(dialogue_id: String, node_id: String) -> bool:
	if not _visited_nodes.has(dialogue_id):
		_visited_nodes[dialogue_id] = {}
	
	var dialogue_visits: Dictionary = _visited_nodes[dialogue_id]
	
	# 检查总节点数
	if dialogue_visits.size() >= MAX_TOTAL_NODES:
		return true
	
	# 检查单节点访问次数
	if not dialogue_visits.has(node_id):
		dialogue_visits[node_id] = 0
	
	dialogue_visits[node_id] += 1
	
	return dialogue_visits[node_id] > MAX_VISITS_PER_NODE

## 获取当前节点
func get_current_node() -> DialogueData.DialogueNode:
	return _current_node

## 获取可用选择
func get_available_choices() -> Array[DialogueData.Choice]:
	if _current_node == null:
		return []
	return _current_node.get_available_choices()

## 获取对话历史
func get_dialogue_history() -> Array[String]:
	return _dialogue_history.duplicate()

## 添加对话到队列
func queue_dialogue(dialogue_id: String, priority: int = 1) -> void:
	_dialogue_queue.append({
		"dialogue_id": dialogue_id,
		"priority": priority
	})
	
	# 按优先级排序
	_dialogue_queue.sort_custom(func(a, b): return a["priority"] > b["priority"])

## 处理对话队列
func process_dialogue_queue() -> void:
	if _is_in_dialogue or _dialogue_queue.is_empty():
		return
	
	var next_dialogue: Dictionary = _dialogue_queue.pop_front()
	start_dialogue(next_dialogue["dialogue_id"])

## 清空对话队列
func clear_dialogue_queue() -> void:
	_dialogue_queue.clear()

## 保存数据
func save_data() -> Dictionary:
	return {
		"dialogue_history": _dialogue_history,
		"current_dialogue_id": _current_dialogue.id if _current_dialogue != null else "",
		"current_node_id": _current_node.id if _current_node != null else "",
		"is_in_dialogue": _is_in_dialogue
	}

## 加载数据
func load_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	_dialogue_history = data.get("dialogue_history", [])
	_is_in_dialogue = data.get("is_in_dialogue", false)
	
	# 如果保存时在对话中，恢复对话状态
	if _is_in_dialogue:
		var dialogue_id: String = data.get("current_dialogue_id", "")
		var node_id: String = data.get("current_node_id", "")
		
		if not dialogue_id.is_empty() and _dialogue_trees.has(dialogue_id):
			_current_dialogue = _dialogue_trees[dialogue_id]
			if not node_id.is_empty():
				_current_node = _current_dialogue.get_node(node_id)
