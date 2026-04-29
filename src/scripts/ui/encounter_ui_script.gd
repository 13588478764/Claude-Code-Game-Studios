## EncounterUiScript
## 武侠奇遇录 - 奇遇事件UI脚本
负责管理奇遇事件UI的显示和交互，包括动态事件卡片、入场动画、福缘状态可视化和选项按钮
##
## 主要功能：
## - 待补充

extends Node

class_name EncounterUiScript

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# UI元素引用
@onready var encounter_card = $EncounterCard
@onready var background = $EncounterCard/Background
@onready var encounter_title = $EncounterCard/EncounterTitle
@onready var encounter_description = $EncounterCard/EncounterDescription
@onready var lucky_star_icon = $EncounterCard/LuckyStarIcon
@onready var option_buttons = $EncounterCard/OptionButtons
@onready var accept_button = $EncounterCard/OptionButtons/AcceptButton
@onready var decline_button = $EncounterCard/OptionButtons/DeclineButton
@onready var try_button = $EncounterCard/OptionButtons/TryButton
@onready var animation_player = $AnimationPlayer

# 数据引用
var character_system = null
var encounter_data = {}
var encounter_type = ""

func _ready():
	# 初始化UI
	initialize_ui()
	
	# 连接信号
	connect_signals()

func initialize_ui():
	"""初始化UI元素"""
	# 隐藏UI直到需要显示
	hide()
	
	# 设置默认按钮文本
	accept_button.text = "接受"
	decline_button.text = "拒绝"
	try_button.text = "尝试"

func connect_signals():
	"""连接UI信号"""
	# 连接按钮信号
	accept_button.pressed.connect(_on_accept_button_pressed)
	decline_button.pressed.connect(_on_decline_button_pressed)
	try_button.pressed.connect(_on_try_button_pressed)

func show_encounter(encounter_info):
	"""显示奇遇事件UI
	
	Args:
	    encounter_info: 包含奇遇信息的字典，包括：
	        - type: 奇遇类型
	        - title: 奇遇标题
	        - description: 奇遇描述
	        - options: 可选项列表
	"""
	encounter_data = encounter_info
	encounter_type = encounter_info.get("type", "unknown")
	
	# 更新UI元素
	update_encounter_display()
	
	# 显示UI
	show()
	
	# 播放入场动画
	play_entry_animation()

func update_encounter_display():
	"""更新奇遇显示内容"""
	# 更新标题
	if encounter_data.has("title"):
		encounter_title.text = encounter_data["title"]
	else:
		encounter_title.text = "奇遇事件"
	
	# 更新描述
	if encounter_data.has("description"):
		encounter_description.text = encounter_data["description"]
	else:
		encounter_description.text = "这里显示奇遇事件的详细描述。根据奇遇类型，背景和描述会有所不同。"
	
	# 根据奇遇类型更新背景
	update_background_by_type()
	
	# 更新福缘状态可视化
	update_lucky_status_visualization()
	
	# 更新选项按钮
	update_option_buttons()

func update_background_by_type():
	"""根据奇遇类型更新背景"""
	match encounter_type:
		"wise_master_guidance":  # 高人指点
			background.texture = load("res://src/assets/ui/encounter_background_wise_master.png")
		"secret_realm_discovery":  # 秘境发现
			background.texture = load("res://src/assets/ui/encounter_background_secret_realm.png")
		"heavenly_treasure":  # 天材地宝
			background.texture = load("res://src/assets/ui/encounter_background_heavenly_treasure.png")
		"lost_martial_scroll":  # 失传秘籍
			background.texture = load("res://src/assets/ui/encounter_background_lost_scroll.png")
		"jianghu_rumor":  # 江湖传闻
			background.texture = load("res://src/assets/ui/encounter_background_jianghu.png")
		_:
			# 默认背景
			background.texture = load("res://src/assets/ui/encounter_background.png")

func update_lucky_status_visualization():
	"""更新福缘状态可视化"""
	# 获取角色系统引用
	if character_system == null:
		character_system = get_node_or_null("/root/CharacterSystem")
	
	if character_system:
		# 如果角色福缘大于60，显示"吉星高照"图标
		if character_system.attributes.luck > 60:
			lucky_star_icon.visible = true
			lucky_star_icon.modulate = Color.YELLOW
		else:
			lucky_star_icon.visible = false
	else:
		# 如果无法获取角色系统，隐藏图标
		lucky_star_icon.visible = false

func update_option_buttons():
	"""更新选项按钮"""
	# 根据奇遇类型和数据更新按钮
	if encounter_data.has("options"):
		var options = encounter_data["options"]
		
		# 显示所有按钮
		accept_button.visible = true
		decline_button.visible = true
		try_button.visible = true
		
		# 根据选项更新按钮文本
		if options.size() >= 1:
			accept_button.text = options[0]
		if options.size() >= 2:
			decline_button.text = options[1]
		if options.size() >= 3:
			try_button.text = options[2]
	else:
		# 默认选项
		accept_button.text = "接受"
		decline_button.text = "拒绝"
		try_button.text = "尝试"

func play_entry_animation():
	"""播放入场动画"""
	# 重置初始状态
	encounter_card.scale = Vector2(0.8, 0.8)
	encounter_card.modulate = Color(1, 1, 1, 0)
	
	# 播放缩放淡入动画
	if animation_player.has_animation("entry_animation"):
		animation_player.play("entry_animation")
	else:
		# 如果没有预设动画，使用Tween创建动画
		var tween = create_tween()
		tween.set_parallel(true)
		
		# 缩放动画
		tween.tween_property(encounter_card, "scale", Vector2(1.0, 1.0), 0.5)
		# 淡入动画
		tween.tween_property(encounter_card, "modulate:a", 1.0, 0.5)

func _on_accept_button_pressed():
	"""接受按钮回调"""
	emit_signal("encounter_option_selected", "accept")
	hide()

func _on_decline_button_pressed():
	"""拒绝按钮回调"""
	emit_signal("encounter_option_selected", "decline")
	hide()

func _on_try_button_pressed():
	"""尝试按钮回调"""
	emit_signal("encounter_option_selected", "try")
	hide()

func _process(delta):
	"""每帧处理函数"""
	# 更新福缘状态可视化（如果角色系统可用）
	if character_system:
		update_lucky_status_visualization()

# 自定义信号
signal encounter_option_selected(option: String)