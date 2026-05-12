## BattleResultPanel
## 战斗结算面板
##
## MVP 战斗结算界面：显示胜负、经验、银两、等级变化。

extends CanvasLayer

# ============================================================================
# 节点引用
# ============================================================================

@onready var result_label: Label = $PanelContainer/VBox/ResultLabel
@onready var exp_label: Label = $PanelContainer/VBox/RewardBox/ExpLabel
@onready var silver_label: Label = $PanelContainer/VBox/RewardBox/SilverLabel
@onready var level_label: Label = $PanelContainer/VBox/RewardBox/LevelLabel
@onready var continue_button: Button = $PanelContainer/VBox/ContinueButton

var _game_loop: Node = null

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	layer = 150
	call_deferred("_initialize")


func _initialize() -> void:
	_game_loop = get_node_or_null("/root/GameLoopManager")
	if _game_loop == null:
		push_warning("[BattleResultPanel] GameLoopManager 未找到")
		return

	continue_button.pressed.connect(_on_continue_pressed)
	_game_loop.game_state_changed.connect(_on_game_state_changed)
	_game_loop.combat_result_ready.connect(_on_combat_result_ready)


func _on_combat_result_ready(reward_data: Dictionary) -> void:
	show_result(reward_data)

# ============================================================================
# 公共 API
# ============================================================================

func show_result(reward_data: Dictionary) -> void:
	var victory: bool = reward_data.get("victory", false)

	if victory:
		result_label.text = "⚔️ 战斗胜利！"
		result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	else:
		result_label.text = "💀 战斗失败..."
		result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	exp_label.text = "获得经验: %d" % reward_data.get("exp", 0)
	silver_label.text = "获得银两: %d" % reward_data.get("silver", 0)

	if reward_data.get("level_up", false):
		level_label.text = "🎉 升级！当前等级: %d" % reward_data.get("new_level", 1)
		level_label.show()
	else:
		level_label.text = ""
		level_label.hide()

	show()

# ============================================================================
# 事件处理
# ============================================================================

func _on_continue_pressed() -> void:
	if _game_loop:
		_game_loop.return_to_exploration()


func _on_game_state_changed(new_state: int) -> void:
	# 3 = COMBAT_RESULT
	if new_state != 3:
		hide()
