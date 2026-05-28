## 战斗操作面板
## 显示战斗状态（HP条、战斗日志）和玩家操作按钮（攻击/防御/技能/逃跑）
## 当轮到玩家行动时显示操作按钮，其余时间仅显示状态

extends CanvasLayer

signal combat_panel_closed

@onready var _panel: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var _player_hp_bar: ProgressBar = $PanelContainer/VBox/StatusBox/PlayerHPBar
@onready var _player_hp_label: Label = $PanelContainer/VBox/StatusBox/PlayerHPLabel
@onready var _player_mp_bar: ProgressBar = $PanelContainer/VBox/StatusBox/PlayerMPBar
@onready var _player_mp_label: Label = $PanelContainer/VBox/StatusBox/PlayerMPLabel
@onready var _enemy_hp_bar: ProgressBar = $PanelContainer/VBox/StatusBox/EnemyHPBar
@onready var _enemy_hp_label: Label = $PanelContainer/VBox/StatusBox/EnemyHPLabel
@onready var _enemy_name_label: Label = $PanelContainer/VBox/StatusBox/EnemyNameLabel
@onready var _log_label: RichTextLabel = $PanelContainer/VBox/LogBox/LogLabel
@onready var _action_box: HBoxContainer = $PanelContainer/VBox/ActionBox
@onready var _attack_btn: Button = $PanelContainer/VBox/ActionBox/AttackButton
@onready var _defend_btn: Button = $PanelContainer/VBox/ActionBox/DefendButton
@onready var _skill_btn: Button = $PanelContainer/VBox/ActionBox/SkillButton
@onready var _flee_btn: Button = $PanelContainer/VBox/ActionBox/FleeButton
@onready var _wait_label: Label = $PanelContainer/VBox/WaitLabel

var _combat_system: Node = null
var _game_loop: Node = null
var _game_events: Node = null
var _martial_arts_system: Node = null

## 技能选择列表容器（运行时创建）
var _skill_list_box: VBoxContainer = null

## 是否轮到玩家行动
var _player_turn: bool = false

## 战斗日志内容
var _log_lines: PackedStringArray = []
const MAX_LOG_LINES: int = 8


func _ready() -> void:
	layer = 120
	visible = false
	call_deferred("_initialize")


func _initialize() -> void:
	_combat_system = get_node_or_null("/root/CombatSystem")
	_game_loop = get_node_or_null("/root/GameLoopManager")
	_game_events = get_node_or_null("/root/GameEvents")
	_martial_arts_system = get_node_or_null("/root/MartialArtsSystem")
	_create_skill_list_ui()

	if _game_events:
		_game_events.combat_started.connect(_on_combat_started)
		_game_events.combat_ended.connect(_on_combat_ended)

	if _combat_system:
		_combat_system.turn_started.connect(_on_turn_started)
		_combat_system.action_executed.connect(_on_action_executed)
		_combat_system.unit_hp_changed.connect(_on_unit_hp_changed)
		_combat_system.unit_resource_changed.connect(_on_unit_resource_changed)

	if _game_loop:
		_game_loop.battle_log_updated.connect(_on_battle_log_updated)

	_attack_btn.pressed.connect(_on_attack_pressed)
	_defend_btn.pressed.connect(_on_defend_pressed)
	_skill_btn.pressed.connect(_on_skill_pressed)
	_flee_btn.pressed.connect(_on_flee_pressed)

	_set_actions_visible(false)


func _on_combat_started() -> void:
	visible = true
	_log_lines.clear()
	_update_log()
	_set_actions_visible(false)
	if _skill_list_box:
		_skill_list_box.visible = false
	_wait_label.text = "战斗开始..."
	_wait_label.visible = true
	_refresh_hp_display()


func _on_combat_ended(_victory: bool, _result: Dictionary) -> void:
	_set_actions_visible(false)
	if _skill_list_box:
		_skill_list_box.visible = false
	_wait_label.text = ""
	_wait_label.visible = false
	visible = false
	combat_panel_closed.emit()


func _on_turn_started(unit) -> void:
	if unit == null:
		return

	_refresh_hp_display()

	var is_player := _is_player_unit(unit)
	_player_turn = is_player

	if is_player:
		if _skill_list_box:
			_skill_list_box.visible = false
		_set_actions_visible(true)
		_wait_label.visible = false
		_attack_btn.grab_focus()
		_add_log_line("— 轮到你行动 —")

		# 阻止 GameLoopManager 的自动战斗
		if _game_loop and _game_loop._auto_battle_timer:
			_game_loop._auto_battle_timer.stop()
	else:
		_set_actions_visible(false)
		_wait_label.text = "敌人行动中..."
		_wait_label.visible = true


func _on_action_executed(result: Dictionary) -> void:
	_refresh_hp_display()

	var action_type: String = result.get("type", "")
	match action_type:
		"attack":
			var dmg: int = result.get("damage_dealt", 0)
			var hp_left: int = result.get("target_hp_left", 0)
			if _player_turn:
				_add_log_line("你发起攻击，造成 %d 点伤害" % dmg)
			else:
				_add_log_line("敌人攻击你，造成 %d 点伤害" % dmg)
		"defend":
			var stance_pct: int = result.get("stance_reduction_pct", 0)
			if _player_turn:
				_add_log_line("你进入防御姿态 (减伤 %d%%)" % stance_pct)
			else:
				_add_log_line("敌人进入防御姿态 (减伤 %d%%)" % stance_pct)
		"skill":
			var skill_name: String = result.get("skill_name", "未知技能")
			var skill_dmg: int = result.get("damage_dealt", 0)
			if _player_turn:
				_add_log_line("你使用了 [%s]，造成 %d 点伤害" % [skill_name, skill_dmg])
			else:
				_add_log_line("敌人使用了 [%s]，造成 %d 点伤害" % [skill_name, skill_dmg])
			var synergy_name: String = result.get("synergy_name", "")
			if synergy_name != "":
				var multiplier: float = result.get("damage_multiplier", 1.0)
				_add_log_line("✨ 协同效果 [%s]！伤害 x%.1f" % [synergy_name, multiplier])


func _on_unit_hp_changed(_unit, _old_hp: int, _new_hp: int) -> void:
	_refresh_hp_display()


func _on_unit_resource_changed(unit, resource_type: String, old_value: int, new_value: int) -> void:
	if resource_type != "internal_energy":
		return
	if not _is_player_unit(unit):
		return
	_player_mp_bar.max_value = unit.max_internal_energy
	_player_mp_bar.value = unit.current_internal_energy
	_player_mp_label.text = "内力  %d / %d" % [unit.current_internal_energy, unit.max_internal_energy]
	var delta: int = new_value - old_value
	if delta > 0:
		_add_log_line("内力回复 +%d" % delta)


func _on_battle_log_updated(message: String) -> void:
	_add_log_line(message)


## 攻击按钮
func _on_attack_pressed() -> void:
	if not _player_turn or _combat_system == null:
		return

	var target_idx := _find_enemy_target()
	if target_idx < 0:
		return

	_set_actions_visible(false)

	_combat_system.execute_action({
		"type": "attack",
		"target_index": target_idx,
	})

	_player_turn = false
	_schedule_next_auto_turn()


## 防御按钮
func _on_defend_pressed() -> void:
	if not _player_turn or _combat_system == null:
		return

	_set_actions_visible(false)

	_combat_system.execute_action({
		"type": "defend",
	})

	_player_turn = false
	_schedule_next_auto_turn()


## 技能按钮 — 打开已装备武学列表
func _on_skill_pressed() -> void:
	if not _player_turn or _combat_system == null:
		return

	_populate_skill_list()
	_action_box.visible = false
	_wait_label.visible = false
	_skill_list_box.visible = true


## 创建技能选择列表 UI（运行时）
func _create_skill_list_ui() -> void:
	_skill_list_box = VBoxContainer.new()
	_skill_list_box.name = "SkillListBox"
	_skill_list_box.visible = false
	_skill_list_box.set("theme_override_constants/separation", 6)
	var vbox = $PanelContainer/VBox
	vbox.add_child(_skill_list_box)
	vbox.move_child(_skill_list_box, _action_box.get_index() + 1)


## 填充技能列表（从 MartialArtsSystem 读取已装备武学）
func _populate_skill_list() -> void:
	for child in _skill_list_box.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "— 选择武学技能 —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skill_list_box.add_child(title)

	var skills_found := false
	if _martial_arts_system:
		for i in range(_martial_arts_system.equipped_martial_arts.size()):
			var ma = _martial_arts_system.equipped_martial_arts[i]
			if ma == null:
				continue
			skills_found = true

			var player_unit = _combat_system.battle_units[0] if not _combat_system.battle_units.is_empty() else null
			var has_energy := true
			if player_unit:
				has_energy = player_unit.current_internal_energy >= int(ma.cost_mana)

			var btn := Button.new()
			var grade_str: String = ma.grade if ma.grade else ""
			var elem_str: String = (" " + ma.element_type) if (ma.element_type and ma.element_type != "无") else ""
			btn.text = "%s [%s%s] (内力:%d 威力:%d)" % [ma.name, grade_str, elem_str, int(ma.cost_mana), int(ma.base_damage)]
			btn.custom_minimum_size = Vector2(200, 36)
			btn.disabled = not has_energy
			if not has_energy:
				btn.tooltip_text = "内力不足"

			# 加载武学技能图标（优先按 id，回退按 weapon_type）
			var skill_icon := _load_skill_icon(ma.id, ma.weapon_type)
			if skill_icon:
				btn.icon = skill_icon

			var skill_data := {
				"type": "use_skill",
				"name": ma.name,
				"cost": int(ma.cost_mana),
				"power": int(ma.base_damage),
				"martial_art_id": ma.id,
				"tags": [ma.element_type] if ma.element_type and ma.element_type != "无" else [],
				"internal_energy_cost": float(ma.cost_mana),
			}
			btn.pressed.connect(_on_skill_selected.bind(skill_data))
			_skill_list_box.add_child(btn)

	if not skills_found:
		var empty_label := Label.new()
		empty_label.text = "没有已装备的武学技能"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_skill_list_box.add_child(empty_label)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(80, 36)
	back_btn.pressed.connect(_on_skill_back_pressed)
	_skill_list_box.add_child(back_btn)


## 选择一个武学技能后执行
func _on_skill_selected(skill_data: Dictionary) -> void:
	var target_idx := _find_enemy_target()
	if target_idx < 0:
		_add_log_line("没有可攻击的目标")
		_on_skill_back_pressed()
		return

	skill_data["target_index"] = target_idx
	_skill_list_box.visible = false
	_set_actions_visible(false)

	_combat_system.execute_action(skill_data)

	_player_turn = false
	_schedule_next_auto_turn()


## 从技能列表返回操作按钮
func _on_skill_back_pressed() -> void:
	_skill_list_box.visible = false
	_action_box.visible = true


## 逃跑按钮
func _on_flee_pressed() -> void:
	if not _player_turn or _combat_system == null:
		return

	# 50% 概率逃跑成功
	_player_turn = false
	_set_actions_visible(false)

	if randf() < 0.5:
		_add_log_line("逃跑成功！未获得奖励。")
		_combat_system.end_battle(true)
	else:
		_add_log_line("逃跑失败！浪费了一回合。")
		_combat_system.end_current_turn()
		_schedule_next_auto_turn()


## 在玩家行动后恢复自动战斗计时器（处理敌人回合）
func _schedule_next_auto_turn() -> void:
	if _game_loop and _game_loop._auto_battle_timer:
		if _combat_system and not _combat_system.is_battle_over():
			_game_loop._auto_battle_timer.start()


## 查找第一个存活的敌方单位索引
func _find_enemy_target() -> int:
	if _combat_system == null:
		return -1

	var units = _combat_system.battle_units
	var half: int = ceili(units.size() / 2.0)

	for i in range(half, units.size()):
		if units[i].current_hp > 0:
			return i

	return -1


## 判断是否为玩家单位
func _is_player_unit(unit) -> bool:
	if _combat_system == null:
		return false

	var idx: int = _combat_system.battle_units.find(unit)
	var half: int = ceili(_combat_system.battle_units.size() / 2.0)
	return idx >= 0 and idx < half


## 刷新 HP 显示
func _refresh_hp_display() -> void:
	if _combat_system == null or _combat_system.battle_units.is_empty():
		return

	var units = _combat_system.battle_units
	var half: int = ceili(units.size() / 2.0)

	# 玩家 HP + 内力
	if units.size() > 0:
		var player_unit = units[0]
		_player_hp_bar.max_value = player_unit.max_hp
		_player_hp_bar.value = player_unit.current_hp
		_player_hp_label.text = "%d / %d" % [player_unit.current_hp, player_unit.max_hp]

		_player_mp_bar.max_value = player_unit.max_internal_energy
		_player_mp_bar.value = player_unit.current_internal_energy
		_player_mp_label.text = "内力  %d / %d" % [player_unit.current_internal_energy, player_unit.max_internal_energy]

	# 敌人 HP
	if units.size() > half:
		var enemy_unit = units[half]
		_enemy_hp_bar.max_value = enemy_unit.max_hp
		_enemy_hp_bar.value = enemy_unit.current_hp
		_enemy_hp_label.text = "%d / %d" % [enemy_unit.current_hp, enemy_unit.max_hp]

		var enemy_name := "敌人"
		if enemy_unit.unit_node is Dictionary:
			enemy_name = enemy_unit.unit_node.get("name", "敌人")
		_enemy_name_label.text = enemy_name
		_title_label.text = "⚔️ 战斗 — %s" % enemy_name


## 设置操作按钮是否可见
func _set_actions_visible(show_actions: bool) -> void:
	_action_box.visible = show_actions
	if not show_actions:
		_wait_label.visible = true


## 添加战斗日志
func _add_log_line(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > MAX_LOG_LINES:
		_log_lines.remove_at(0)
	_update_log()


## 更新日志显示
func _update_log() -> void:
	if _log_label:
		_log_label.text = "\n".join(_log_lines)


## 武器类型 → 默认技能图标映射
const WEAPON_TYPE_ICON: Dictionary = {
	"Sword": "res://assets/ui/skill_icons/skill_icon_cold_light_sword.png",
	"Fist": "res://assets/ui/skill_icons/skill_icon_luohan_fist.png",
	"Palm": "res://assets/ui/skill_icons/skill_icon_fire_palm.png",
}


## 加载武学图标：优先按 ID 查找，回退按 weapon_type
func _load_skill_icon(martial_art_id: String, weapon_type: String) -> Texture2D:
	var path := "res://assets/ui/skill_icons/skill_icon_%s.png" % martial_art_id
	if ResourceLoader.exists(path):
		return load(path) as Texture2D

	var fallback := WEAPON_TYPE_ICON.get(weapon_type, "")
	if not fallback.is_empty() and ResourceLoader.exists(fallback):
		return load(fallback) as Texture2D

	return null
