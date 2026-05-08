## NPC交互触发器
## 挂载到NPC场景上，处理玩家与NPC的对话触发
##
## 使用方式：
## 1. 将脚本添加到NPC场景（Character2D或Area2D）
## 2. 设置npc_id（与对话JSON中的speaker ID一致）
## 3. 设置dialogue_id（要触发的对话树ID）
## 4. 玩家按交互键（E键）时自动触发对话
extends Node2D
class_name NPCInteractionTrigger

## NPC唯一标识（对应对话JSON中的speaker ID）
@export var npc_id: String = ""

## 要触发的对话树ID
@export var dialogue_id: String = ""

## 交互提示文本
@export var interaction_prompt: String = "按 [E] 对话"

## 交互范围半径（像素）
@export var interaction_range: float = 64.0

## 交互区域（Area2D）
var _interaction_area: Area2D = null

## 提示标签
var _prompt_label: Label = null

## 玩家是否在范围内
var _player_in_range: bool = false

## 对话管理器引用
var _dialogue_manager: Node = null


func _ready() -> void:
	# 获取对话管理器
	_dialogue_manager = get_node_or_null("/root/DialogueManager")
	if _dialogue_manager == null:
		push_warning("[NPCInteractionTrigger] DialogueManager not found")
	
	# 创建交互区域
	_create_interaction_area()
	
	# 创建交互提示
	_create_prompt_label()
	
	# 初始化状态
	_prompt_label.visible = false


## 创建交互Area2D
func _create_interaction_area() -> void:
	_interaction_area = Area2D.new()
	_interaction_area.name = "InteractionArea"
	_interaction_area.monitorable = true
	_interaction_area.monitoring = true
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 1  # 玩家层
	
	# 创建碰撞形状
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	var shape := CircleShape2D.new()
	shape.radius = interaction_range
	collision_shape.shape = shape
	
	_interaction_area.add_child(collision_shape)
	add_child(_interaction_area)
	
	# 连接信号
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)


## 创建交互提示标签
func _create_prompt_label() -> void:
	_prompt_label = Label.new()
	_prompt_label.name = "InteractionPrompt"
	_prompt_label.text = interaction_prompt
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_prompt_label.custom_minimum_size = Vector2(120, 30)
	
	# 定位到NPC头顶
	_prompt_label.position = Vector2(-60, -80)
	
	add_child(_prompt_label)


## 玩家进入交互范围
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_range = true
		_prompt_label.visible = true


## 玩家离开交互范围
func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player_in_range = false
		_prompt_label.visible = false


## 处理玩家输入
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if _player_in_range and not _is_dialogue_active():
			_trigger_interaction()


## 触发交互（对话或自定义逻辑）
func _trigger_interaction() -> void:
	# 优先使用对话ID触发对话
	if not dialogue_id.is_empty() and _dialogue_manager != null:
		if _dialogue_manager.has_dialogue(dialogue_id):
			_dialogue_manager.start_dialogue(dialogue_id)
			_prompt_label.visible = false
			return
		else:
			push_warning("[NPCInteractionTrigger] Dialogue not found: %s" % dialogue_id)
	
	# 如果没有对话ID，尝试通过NPC ID查找
	if not npc_id.is_empty() and _dialogue_manager != null:
		if _dialogue_manager.start_dialogue_with_npc(npc_id):
			_prompt_label.visible = false
			return
	
	# 都没有的话，发出自定义信号
	interaction_triggered.emit(npc_id)


## 检查对话是否正在进行中
func _is_dialogue_active() -> bool:
	if _dialogue_manager == null:
		return false
	return _dialogue_manager.is_in_dialogue()


## 玩家与NPC交互后发出的信号
signal interaction_triggered(npc_id: String)


## 获取交互提示是否可见
func is_prompt_visible() -> bool:
	return _prompt_label.visible


## 设置交互提示文本
func set_prompt_text(text: String) -> void:
	interaction_prompt = text
	if _prompt_label != null:
		_prompt_label.text = text


## 设置对话ID（运行时动态设置）
func set_dialogue_id(new_id: String) -> void:
	dialogue_id = new_id
