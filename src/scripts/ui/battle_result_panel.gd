## BattleResultPanel
## 战斗结算面板 — 全屏展示胜负、经验、银两、掉落
##
## 动画架构预留:
##   战斗动画系统计划使用 AnimatedSprite2D + SpriteFrames 实现每个技能的序列帧动画。
##   本面板在 show_result() 中预留了 _play_result_animation() 调用点,
##   未来可在此处播放胜利/失败的全屏特效序列帧。

extends CanvasLayer

@onready var result_label: Label = $Root/VBox/ResultLabel
@onready var exp_label: Label = $Root/VBox/RewardBox/ExpLabel
@onready var silver_label: Label = $Root/VBox/RewardBox/SilverLabel
@onready var level_label: Label = $Root/VBox/RewardBox/LevelLabel
@onready var drops_label: Label = $Root/VBox/RewardBox/DropsLabel
@onready var region_label: Label = $Root/VBox/RewardBox/RegionLabel
@onready var continue_button: Button = $Root/VBox/ContinueButton

var _game_loop: Node = null


func _ready() -> void:
	layer = 150
	if has_node("/root/SafeAreaManager"):
		get_node("/root/SafeAreaManager").apply_to_control($Root)
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


func show_result(reward_data: Dictionary) -> void:
	var victory: bool = reward_data.get("victory", false)

	if victory:
		result_label.text = "战斗胜利！"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	else:
		result_label.text = "战斗失败..."
		result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	if reward_data.get("fled", false):
		exp_label.text = "逃跑成功，未获得奖励"
		silver_label.hide()
	else:
		exp_label.text = "获得经验: %d" % reward_data.get("exp", 0)
		silver_label.text = "获得银两: %d" % reward_data.get("silver", 0)
		silver_label.show()

	if reward_data.get("level_up", false):
		level_label.text = "升级！当前等级: %d" % reward_data.get("new_level", 1)
		level_label.show()
	else:
		level_label.hide()

	var drops: Array = reward_data.get("drops", [])
	if not drops.is_empty():
		var drop_texts: PackedStringArray = []
		for drop in drops:
			drop_texts.append("%s x%d" % [drop.get("name", "未知物品"), drop.get("count", 1)])
		drops_label.text = "掉落: %s" % ", ".join(drop_texts)
		drops_label.show()
	else:
		drops_label.hide()

	var region_name: String = reward_data.get("region", "")
	if region_name != "":
		region_label.text = "战斗区域: %s" % region_name
		region_label.show()
	else:
		region_label.hide()

	show()
	_play_result_entrance(victory)


## 结算面板入场动画
func _play_result_entrance(victory: bool) -> void:
	var vbox: VBoxContainer = $Root/VBox
	vbox.modulate = Color(1, 1, 1, 0)
	vbox.scale = Vector2(0.8, 0.8)
	vbox.pivot_offset = vbox.size / 2.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(vbox, "scale", Vector2.ONE, 0.4)
	tween.parallel().tween_property(vbox, "modulate:a", 1.0, 0.3)

	if victory:
		# 胜利闪金光
		tween.tween_property(result_label, "modulate", Color(2.0, 1.8, 1.0, 1.0), 0.15)
		tween.tween_property(result_label, "modulate", Color.WHITE, 0.2)

	# 预留: 未来在此处调用序列帧胜利/失败特效
	# _play_result_sprite_animation(victory)


## 预留: 序列帧动画播放接口
## 未来每个技能使用 AnimatedSprite2D + SpriteFrames 资源:
##   res://assets/vfx/skills/{skill_id}/frames.tres
## 战斗结算特效:
##   res://assets/vfx/battle_result/victory.tres
##   res://assets/vfx/battle_result/defeat.tres
#func _play_result_sprite_animation(victory: bool) -> void:
#	var anim_sprite := AnimatedSprite2D.new()
#	var frames_path := "res://assets/vfx/battle_result/%s.tres" % ("victory" if victory else "defeat")
#	if ResourceLoader.exists(frames_path):
#		anim_sprite.sprite_frames = load(frames_path)
#		anim_sprite.position = Vector2(get_viewport().get_visible_rect().size / 2.0)
#		$Root.add_child(anim_sprite)
#		anim_sprite.play("default")
#		anim_sprite.animation_finished.connect(anim_sprite.queue_free)


func _on_continue_pressed() -> void:
	if _game_loop:
		_game_loop.return_to_exploration()


func _on_game_state_changed(new_state: int) -> void:
	if new_state != 3:  # COMBAT_RESULT
		hide()
