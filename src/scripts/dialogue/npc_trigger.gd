## NPC对话触发器
## 附加到NPC场景节点上，用于触发对话
extends Area2D

## NPC唯一标识
@export var npc_id: String = ""

## 关联的对话树ID
@export var dialogue_tree_id: String = ""

## 触发方式
enum TriggerType {
	INTERACT,  ## 玩家按下交互键
	AUTO,      ## 玩家进入范围自动触发
}

@export var trigger_type: TriggerType = TriggerType.INTERACT

## 交互提示文本
@export var interact_hint: String = "按[F]对话"

## 是否可重复触发
@export var repeatable: bool = true

## 触发条件（可选）
@export var condition_quest_id: String = ""
@export var condition_required_quest_state: String = "completed"

## 对话管理器引用
var _dialogue_manager: Node = null

## 玩家是否InRange
var _player_in_range: bool = false

## UI提示标签
var _hint_label: Label = null

func _ready() -> void:
	# 获取DialogueManager
	_dialogue_manager = get_node_or_null("/root/DialogueManager")
	
	# 创建交互提示标签
	_create_hint_label()
	
	# 连接信号
	if trigger_type == TriggerType.INTERACT:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	elif trigger_type == TriggerType.AUTO:
		body_entered.connect(_on_body_entered_auto)
	
	# 加载对话树（如果尚未加载）
	if _dialogue_manager != null and not dialogue_tree_id.is_empty():
		# 对话应该已经在游戏启动时由DialogueLoader加载
		pass

## 创建交互提示标签
func _create_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.text = interact_hint
	_hint_label.visible = false
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", Color.WHITE)
	_hint_label.add_theme_font_size_override("font_size", 16)
	add_child(_hint_label)

## 更新提示标签位置
func _process(_delta: float) -> void:
	if _hint_label != null and _player_in_range:
		var npc_pos := global_position
		_hint_label.global_position = Vector2(
			npc_pos.x - _hint_label.size.x / 2,
			npc_pos.y - 40
		)

## 玩家进入范围（交互模式）
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_range = true
		_hint_label.visible = true

## 玩家离开范围
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_range = false
		_hint_label.visible = false

## 玩家进入范围（自动触发模式）
func _on_body_entered_auto(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_trigger_dialogue()

## 处理玩家输入
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		if _player_in_range and trigger_type == TriggerType.INTERACT:
			_trigger_dialogue()
			get_viewport().set_input_as_handled()

## 触发对话
func _trigger_dialogue() -> void:
	if _dialogue_manager == null:
		push_error("[NPC触发器] DialogueManager未找到")
		return
	
	if dialogue_tree_id.is_empty():
		push_warning("[NPC触发器] NPC %s 没有设置对话树ID" % npc_id)
		return
	
	# 检查触发条件
	if not _check_conditions():
		return
	
	# 触发对话
	_dialogue_manager.start_dialogue(dialogue_tree_id)

## 检查触发条件
func _check_conditions() -> bool:
	# 检查任务条件
	if not condition_quest_id.is_empty():
		var quest_system = get_node_or_null("/root/QuestSystem")
		if quest_system != null:
			var quest_state = quest_system.get_quest_state(condition_quest_id)
			if quest_state != condition_required_quest_state:
				return false
	
	return true

## 外部调用：强制触发对话
func force_trigger() -> void:
	_trigger_dialogue()
