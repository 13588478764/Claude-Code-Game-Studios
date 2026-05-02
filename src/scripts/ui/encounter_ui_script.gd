extends Control
class_name EncounterUiScript
## EncounterUiScript - 奇遇事件UI脚本
##
## 负责管理奇遇事件卡片的显示和交互
## 包括动态背景、入场动画和选项按钮

# 节点引用
@onready var encounter_card: Panel = $CenterContainer/EncounterCard
@onready var title_label: Label = $CenterContainer/EncounterCard/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: Label = $CenterContainer/EncounterCard/MarginContainer/VBoxContainer/DescriptionLabel
@onready var lucky_star_icon: Panel = $CenterContainer/EncounterCard/LuckyStarIcon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var background_texture: ColorRect = $CenterContainer/EncounterCard/BackgroundTexture

# 信号
signal encounter_accepted
signal encounter_declined
signal encounter_tried

# 系统引用
var character_system: CharacterSystem = null
var encounter_integration: EncounterIntegration = null

# 当前奇遇数据
var current_encounter_data: Dictionary = {}

# 奇遇类型到中文名称的映射
const ENCOUNTER_TYPE_NAMES = {
	"wise_master_guidance": "高人指点",
	"secret_realm_discovery": "秘境发现",
	"heavenly_treasure": "天材地宝",
	"lost_martial_scroll": "失传秘籍",
	"jianghu_rumor": "江湖传闻"
}

# 奇遇类型到描述的映射
const ENCOUNTER_DESCRIPTIONS = {
	"wise_master_guidance": "你在竹林中遇到了一位白发老者，他似乎看出了你的修炼天赋。\n\n老者微笑道：'小友骨骼清奇，是个修炼的好苗子。老夫这里有一本心法，不知你可愿意学习？'",
	"secret_realm_discovery": "你在山洞深处发现了一处隐秘的修炼场所，灵气浓郁，似乎是前人留下的秘境。\n\n在此修炼必能事半功倍！",
	"heavenly_treasure": "你在集市中偶然发现了一株罕见的灵药，散发着淡淡的光芒。\n\n摊主似乎不识货，正在低价出售。",
	"lost_martial_scroll": "你在古籍中发现了一本失传已久的武学秘籍，上面记载着精妙的招式。\n\n若能参悟，必能大幅提升武学造诣！",
	"jianghu_rumor": "你听闻江湖中流传着一个关于绝世高手的传说，或许能从中获得启发。\n\n这些传闻往往蕴含着深刻的武学智慧。"
}

# 奇遇类型到背景类型的映射
const ENCOUNTER_BACKGROUNDS = {
	"wise_master_guidance": "bamboo",
	"secret_realm_discovery": "cave",
	"heavenly_treasure": "market",
	"lost_martial_scroll": "bamboo",
	"jianghu_rumor": "market"
}

func _ready() -> void:
	print("[EncounterUI] Initialized")
	hide()
	
	# 获取系统引用
	character_system = get_node_or_null("/root/CharacterSystem")
	encounter_integration = get_node_or_null("/root/EncounterIntegration")
	
	if not character_system:
		push_warning("[EncounterUI] CharacterSystem not found!")
	
	if encounter_integration:
		# 初始化EncounterIntegration（重要！）
		print("[EncounterUI] Initializing EncounterIntegration...")
		encounter_integration.initialize(character_system, null, null)
		
		# 连接奇遇系统信号
		encounter_integration.encounter_triggered.connect(_on_encounter_triggered)
		encounter_integration.encounter_reward_granted.connect(_on_reward_granted)
		print("[EncounterUI] EncounterIntegration initialized and signals connected")
	else:
		push_warning("[EncounterUI] EncounterIntegration not found!")
	
	# 自动测试：延迟0.5秒后显示测试奇遇（仅用于测试场景）
	# 注意：在实际游戏中，奇遇应该由EncounterTriggerManager触发
	# 如果不需要自动测试，可以注释掉以下代码
	# await get_tree().create_timer(0.5).timeout
	# _show_test_encounter()

# ============================================================================
# 测试辅助方法（仅用于开发和测试）
# ============================================================================

func _show_test_encounter() -> void:
	"""显示测试奇遇事件（仅用于测试场景）"""
	var test_data = {
		"title": "高人指点",
		"description": "你在竹林中遇到了一位白发老者，他似乎看出了你的修炼天赋。\n\n老者微笑道：'小友骨骼清奇，是个修炼的好苗子。老夫这里有一本心法，不知你可愿意学习？'",
		"type": "bamboo",
		"player_luck": 75,
		"encounter_type": "wise_master_guidance",
		"encounter_id": "test_encounter_001"
	}
	show_encounter(test_data)

func show_encounter(encounter_data: Dictionary) -> void:
	"""显示奇遇事件"""
	# 保存当前奇遇数据（重要！）
	current_encounter_data = encounter_data
	
	# 设置标题和描述
	if title_label:
		title_label.text = encounter_data.get("title", "奇遇事件")
	if description_label:
		description_label.text = encounter_data.get("description", "")
	
	# 根据奇遇类型设置背景颜色
	if background_texture:
		var encounter_type = encounter_data.get("type", "default")
		match encounter_type:
			"cave":
				background_texture.color = Color(0.2, 0.2, 0.3, 1.0)  # 山洞 - 深蓝
			"bamboo":
				background_texture.color = Color(0.2, 0.3, 0.2, 1.0)  # 竹林 - 深绿
			"market":
				background_texture.color = Color(0.3, 0.2, 0.2, 1.0)  # 集市 - 深红
			_:
				background_texture.color = Color(0.2, 0.2, 0.2, 1.0)  # 默认 - 深灰
	
	# 显示福缘图标（如果福缘>60）
	var player_luck = encounter_data.get("player_luck", 0)
	if lucky_star_icon:
		lucky_star_icon.visible = player_luck > 60
	
	# 设置初始状态（确保动画从正确的起始点开始）
	if encounter_card:
		encounter_card.scale = Vector2(0.8, 0.8)
		encounter_card.modulate = Color(1, 1, 1, 0)
	
	# 显示UI
	show()
	
	# 等待一帧确保节点完全准备好
	await get_tree().process_frame
	
	# 播放入场动画
	if animation_player:
		print("[EncounterUI] Playing entrance animation")
		if animation_player.has_animation("entrance"):
			animation_player.play("entrance")
		else:
			print("[EncounterUI] Warning: 'entrance' animation not found")
			# 如果动画不存在，手动设置为可见状态
			if encounter_card:
				encounter_card.scale = Vector2(1, 1)
				encounter_card.modulate = Color(1, 1, 1, 1)

func hide_encounter() -> void:
	"""隐藏奇遇事件"""
	hide()

func _on_accept_button_pressed() -> void:
	"""接受按钮点击"""
	print("[EncounterUI] Accept button pressed")
	
	# 发放奇遇奖励
	if encounter_integration and current_encounter_data.has("encounter_type"):
		encounter_integration.grant_encounter_rewards(
			current_encounter_data["encounter_type"],
			current_encounter_data
		)
	
	encounter_accepted.emit()
	hide_encounter()

func _on_decline_button_pressed() -> void:
	"""拒绝按钮点击"""
	print("[EncounterUI] Decline button pressed")
	encounter_declined.emit()
	hide_encounter()

func _on_try_button_pressed() -> void:
	"""尝试按钮点击"""
	print("[EncounterUI] Try button pressed")
	
	# 尝试选项：50%概率获得奖励
	if randf() < 0.5:
		print("[EncounterUI] Try succeeded!")
		if encounter_integration and current_encounter_data.has("encounter_type"):
			encounter_integration.grant_encounter_rewards(
				current_encounter_data["encounter_type"],
				current_encounter_data
			)
	else:
		print("[EncounterUI] Try failed!")
	
	encounter_tried.emit()
	hide_encounter()

# ============================================================================
# 信号处理函数
# ============================================================================

func _on_encounter_triggered(encounter_type: String, encounter_id: String, probability: float) -> void:
	"""奇遇触发事件"""
	print("[EncounterUI] Encounter triggered: %s (ID: %s, Probability: %.2f%%)" % [encounter_type, encounter_id, probability * 100])
	
	# 构建奇遇数据
	var encounter_data = {
		"title": ENCOUNTER_TYPE_NAMES.get(encounter_type, "奇遇事件"),
		"description": ENCOUNTER_DESCRIPTIONS.get(encounter_type, "你遇到了一个奇遇事件..."),
		"type": ENCOUNTER_BACKGROUNDS.get(encounter_type, "default"),
		"player_luck": character_system.attributes.luck if character_system else 0,
		"encounter_type": encounter_type,
		"encounter_id": encounter_id
	}
	
	# 保存当前奇遇数据
	current_encounter_data = encounter_data
	
	# 显示奇遇UI
	show_encounter(encounter_data)

func _on_reward_granted(reward_type: String, amount: int) -> void:
	"""奖励发放事件"""
	print("[EncounterUI] Reward granted: %s x%d" % [reward_type, amount])
	
	# 显示奖励通知（通过GameEvents发送系统通知）
	var reward_text = ""
	match reward_type:
		"attribute_points":
			reward_text = "获得 %d 点属性点！" % amount
		"experience":
			reward_text = "获得 %d 点经验值！" % amount
		"item":
			reward_text = "获得物品奖励！"
		"martial_proficiency":
			reward_text = "武学熟练度提升 %d 点！" % amount
		"talent_points":
			reward_text = "获得 %d 点天赋点！" % amount
	
	# 发送系统通知（使用正确的信号名称）
	if GameEvents:
		GameEvents.system_notification.emit(reward_text, "success", 3.0)

# ============================================================================
# 公共方法 - 用于外部触发奇遇
# ============================================================================

func trigger_random_encounter() -> void:
	"""触发随机奇遇（用于测试）"""
	if not encounter_integration:
		push_warning("[EncounterUI] EncounterIntegration not found!")
		return
	
	# 生成随机奇遇ID
	var encounter_id = "random_encounter_%d" % randi()
	
	# 触发奇遇（基础概率3%）
	var result = encounter_integration.trigger_encounter_with_integration(0.03, encounter_id)
	
	if result["triggered"]:
		print("[EncounterUI] Random encounter triggered successfully!")
	else:
		print("[EncounterUI] Random encounter failed to trigger (probability: %.2f%%)" % (result["probability"] * 100))

func trigger_guaranteed_encounter(encounter_type: String = "") -> void:
	"""触发保证成功的奇遇（用于测试）"""
	if not encounter_integration:
		push_warning("[EncounterUI] EncounterIntegration not found!")
		return
	
	# 如果没有指定类型，随机选择一个
	if encounter_type.is_empty():
		encounter_type = encounter_integration.determine_encounter_type()
	
	# 生成奇遇ID
	var encounter_id = "guaranteed_encounter_%s_%d" % [encounter_type, randi()]
	
	# 构建奇遇数据并直接显示
	var encounter_data = {
		"title": ENCOUNTER_TYPE_NAMES.get(encounter_type, "奇遇事件"),
		"description": ENCOUNTER_DESCRIPTIONS.get(encounter_type, "你遇到了一个奇遇事件..."),
		"type": ENCOUNTER_BACKGROUNDS.get(encounter_type, "default"),
		"player_luck": character_system.attributes.luck if character_system else 0,
		"encounter_type": encounter_type,
		"encounter_id": encounter_id
	}
	
	current_encounter_data = encounter_data
	show_encounter(encounter_data)