## 战斗操作面板
## 显示战斗状态（HP条、战斗日志）和玩家操作按钮（攻击/防御/技能/逃跑）
## 当轮到玩家行动时显示操作按钮，其余时间仅显示状态

extends CanvasLayer

signal combat_panel_closed

@onready var _battle_bg: TextureRect = $Root/BattleBG
@onready var _player_sprite: TextureRect = $Root/PlayerSprite
@onready var _enemy_sprite: TextureRect = $Root/EnemySprite
@onready var _title_label: Label = $Root/TopBar/TopHBox/PlayerInfo/TitleLabel
@onready var _player_hp_bar: ProgressBar = $Root/TopBar/TopHBox/PlayerInfo/PlayerHPBar
@onready var _player_hp_label: Label = $Root/TopBar/TopHBox/PlayerInfo/PlayerHPLabel
@onready var _player_mp_bar: ProgressBar = $Root/TopBar/TopHBox/PlayerInfo/PlayerMPBar
@onready var _player_mp_label: Label = $Root/TopBar/TopHBox/PlayerInfo/PlayerMPLabel
@onready var _enemy_hp_bar: ProgressBar = $Root/TopBar/TopHBox/EnemyInfo/EnemyHPBar
@onready var _enemy_hp_label: Label = $Root/TopBar/TopHBox/EnemyInfo/EnemyHPLabel
@onready var _enemy_name_label: Label = $Root/TopBar/TopHBox/EnemyInfo/EnemyNameLabel
@onready var _log_label: RichTextLabel = $Root/BottomPanel/BottomVBox/LogLabel
@onready var _action_box: HBoxContainer = $Root/BottomPanel/BottomVBox/ActionBox
@onready var _attack_btn: Button = $Root/BottomPanel/BottomVBox/ActionBox/AttackButton
@onready var _defend_btn: Button = $Root/BottomPanel/BottomVBox/ActionBox/DefendButton
@onready var _skill_btn: Button = $Root/BottomPanel/BottomVBox/ActionBox/SkillButton
@onready var _item_btn: Button = $Root/BottomPanel/BottomVBox/ActionBox/ItemButton
@onready var _flee_btn: Button = $Root/BottomPanel/BottomVBox/ActionBox/FleeButton
@onready var _wait_label: Label = $Root/BottomPanel/BottomVBox/WaitLabel

var _combat_system: Node = null
var _game_loop: Node = null
var _game_events: Node = null
var _martial_arts_system: Node = null

## 连携按钮 (运行时创建, 满槽时显示)
var _link_btn: Button = null

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
	if has_node("/root/SafeAreaManager"):
		get_node("/root/SafeAreaManager").apply_to_control($Root)
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
	_item_btn.pressed.connect(_on_item_pressed)
	_flee_btn.pressed.connect(_on_flee_pressed)

	# 创建连携按钮
	_link_btn = Button.new()
	_link_btn.text = "连携!"
	_link_btn.custom_minimum_size = Vector2(100, 44)
	_link_btn.visible = false
	_link_btn.pressed.connect(_on_link_pressed)
	_link_btn.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	_action_box.add_child(_link_btn)

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
	_load_battle_visuals()
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
		_show_turn_banner("你的回合", Color(0.2, 0.8, 1.0))
		_update_link_button()

		if _game_loop and _game_loop._auto_battle_timer:
			_game_loop._auto_battle_timer.stop()
	else:
		_set_actions_visible(false)
		_wait_label.text = "敌人行动中..."
		_wait_label.visible = true
		_show_turn_banner("敌方回合", Color(1.0, 0.4, 0.3))


func _on_action_executed(result: Dictionary) -> void:
	_refresh_hp_display()

	var action_type: String = result.get("type", "")
	match action_type:
		"attack":
			var dmg: int = result.get("damage_dealt", 0)
			if _player_turn:
				_add_log_line("你发起攻击，造成 %d 点伤害" % dmg)
				_play_attack_anim(_player_sprite, _enemy_sprite)
				_spawn_damage_number(_enemy_sprite, dmg, false)
			else:
				_add_log_line("敌人攻击你，造成 %d 点伤害" % dmg)
				_play_attack_anim(_enemy_sprite, _player_sprite)
				_spawn_damage_number(_player_sprite, dmg, false)
		"defend":
			var stance_pct: int = result.get("stance_reduction_pct", 0)
			if _player_turn:
				_add_log_line("你进入防御姿态 (减伤 %d%%)" % stance_pct)
				_play_defend_anim(_player_sprite)
			else:
				_add_log_line("敌人进入防御姿态 (减伤 %d%%)" % stance_pct)
				_play_defend_anim(_enemy_sprite)
		"skill":
			var skill_name: String = result.get("skill_name", "未知技能")
			var skill_dmg: int = result.get("damage_dealt", 0)
			var is_critical: bool = result.get("is_critical", false)
			if _player_turn:
				_add_log_line("你使用了 [%s]，造成 %d 点伤害" % [skill_name, skill_dmg])
				_play_attack_anim(_player_sprite, _enemy_sprite)
				_spawn_damage_number(_enemy_sprite, skill_dmg, is_critical)
			else:
				_add_log_line("敌人使用了 [%s]，造成 %d 点伤害" % [skill_name, skill_dmg])
				_play_attack_anim(_enemy_sprite, _player_sprite)
				_spawn_damage_number(_player_sprite, skill_dmg, is_critical)
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


## 物品按钮 — 打开物品选择列表
func _on_item_pressed() -> void:
	if not _player_turn or _combat_system == null:
		return
	_populate_item_list()
	_action_box.visible = false
	_wait_label.visible = false
	_skill_list_box.visible = false


## 物品选择列表容器 (运行时创建)
var _item_list_box: VBoxContainer = null


func _create_item_list_ui() -> void:
	_item_list_box = VBoxContainer.new()
	_item_list_box.name = "ItemListBox"
	_item_list_box.visible = false
	_item_list_box.set("theme_override_constants/separation", 6)
	var bottom_vbox: VBoxContainer = $Root/BottomPanel/BottomVBox
	bottom_vbox.add_child(_item_list_box)


## 战斗可用消耗品
const BATTLE_CONSUMABLES: Array = [
	{"id": "health_pill", "name": "回春丹", "effect": "恢复30%HP", "type": "heal_hp", "value": 0.3},
	{"id": "qi_gathering_pill", "name": "聚气丹", "effect": "恢复30%内力", "type": "heal_mp", "value": 0.3},
]


func _populate_item_list() -> void:
	if _item_list_box == null:
		_create_item_list_ui()

	for child in _item_list_box.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "— 选择物品 (不消耗回合) —"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_item_list_box.add_child(title)

	var inv: Node = get_node_or_null("/root/InventorySystem")
	var has_items := false

	if inv:
		for item in BATTLE_CONSUMABLES:
			var item_id: String = item.id
			if not inv.has_item(item_id):
				continue
			has_items = true
			var btn := Button.new()
			btn.text = "%s (%s)" % [item.name, item.effect]
			btn.custom_minimum_size = Vector2(200, 36)
			btn.pressed.connect(_on_use_battle_item.bind(item))
			_item_list_box.add_child(btn)

	if not has_items:
		var empty := Label.new()
		empty.text = "没有可用的消耗品"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_item_list_box.add_child(empty)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(80, 36)
	back_btn.pressed.connect(_on_item_back_pressed)
	_item_list_box.add_child(back_btn)

	_item_list_box.visible = true


func _on_use_battle_item(item: Dictionary) -> void:
	var inv: Node = get_node_or_null("/root/InventorySystem")
	if inv == null or not inv.has_item(item.id):
		return

	inv.use_item(item.id)
	var player_unit: Variant = _combat_system.battle_units[0] if not _combat_system.battle_units.is_empty() else null
	if player_unit == null:
		return

	match item.type:
		"heal_hp":
			var heal: int = int(player_unit.max_hp * item.value)
			player_unit.current_hp = min(player_unit.max_hp, player_unit.current_hp + heal)
			_add_log_line("[color=green]使用%s，恢复 %d HP[/color]" % [item.name, heal])
		"heal_mp":
			var heal: int = int(player_unit.max_internal_energy * item.value)
			player_unit.current_internal_energy = min(player_unit.max_internal_energy, player_unit.current_internal_energy + heal)
			_add_log_line("[color=cyan]使用%s，恢复 %d 内力[/color]" % [item.name, heal])

	_refresh_hp_display()
	# 使用物品不消耗回合，返回操作按钮
	_item_list_box.visible = false
	_action_box.visible = true


func _on_item_back_pressed() -> void:
	_item_list_box.visible = false
	_action_box.visible = true


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
	var bottom_vbox: VBoxContainer = $Root/BottomPanel/BottomVBox
	bottom_vbox.add_child(_skill_list_box)
	bottom_vbox.move_child(_skill_list_box, _action_box.get_index() + 1)


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
			var ma: Variant = _martial_arts_system.equipped_martial_arts[i]
			if ma == null:
				continue
			skills_found = true

			var player_unit: Variant = _combat_system.battle_units[0] if not _combat_system.battle_units.is_empty() else null
			var has_energy := true
			if player_unit:
				has_energy = player_unit.current_internal_energy >= int(ma.cost_mana)

			var btn := Button.new()
			var grade_str: String = ma.grade if ma.grade else ""
			var elem_str: String = (" " + ma.element_type) if (ma.element_type and ma.element_type != "无") else ""
			btn.text = "%s [%s%s] (内力:%d 威力:%d)" % [ma.name, grade_str, elem_str, int(ma.cost_mana), int(ma.base_damage)]
			btn.custom_minimum_size = Vector2(200, 40)
			btn.disabled = not has_energy
			if not has_energy:
				btn.tooltip_text = "内力不足"
				btn.add_theme_color_override("font_disabled_color", Color(1.0, 0.3, 0.3, 0.6))

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

	var units: Array = _combat_system.battle_units
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

	var units: Array = _combat_system.battle_units
	var half: int = ceili(units.size() / 2.0)

	# 玩家 HP + 内力
	if units.size() > 0:
		var player_unit: Variant = units[0]
		_player_hp_bar.max_value = player_unit.max_hp
		_player_hp_bar.value = player_unit.current_hp
		_player_hp_label.text = "%d / %d" % [player_unit.current_hp, player_unit.max_hp]

		_player_mp_bar.max_value = player_unit.max_internal_energy
		_player_mp_bar.value = player_unit.current_internal_energy
		_player_mp_label.text = "内力  %d / %d" % [player_unit.current_internal_energy, player_unit.max_internal_energy]

	# 敌人 HP
	if units.size() > half:
		var enemy_unit: Variant = units[half]
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


## 区域 → 战斗背景映射
const BATTLE_BG_MAP: Dictionary = {
	"start_village": "bg_battle_village",
	"bandit_fortress": "bg_battle_fortress",
	"jiangnan_water": "bg_battle_watertown",
	"qingyun_mountain": "bg_battle_mountain",
	"ancient_tomb": "bg_battle_tomb",
	"demon_domain": "bg_battle_demon",
	"immortal_palace": "bg_battle_immortal",
	"heavenly_peak": "bg_battle_heavenly",
	"void_realm": "bg_battle_void",
}

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

	var fallback: String = WEAPON_TYPE_ICON.get(weapon_type, "")
	if not fallback.is_empty() and ResourceLoader.exists(fallback):
		return load(fallback) as Texture2D

	return null


## 加载战斗场景视觉元素（背景 + 双方立绘）
func _load_battle_visuals() -> void:
	# 背景: 按区域选择对应战斗背景
	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	if game_loop and _battle_bg:
		var region_id: String = game_loop.current_region.get("id", "")
		var bg_name: String = BATTLE_BG_MAP.get(region_id, "bg_battle_plains")
		var bg_path := "res://assets/ui/backgrounds/%s.png" % bg_name
		if ResourceLoader.exists(bg_path):
			_battle_bg.texture = load(bg_path) as Texture2D

	# 玩家立绘
	if _player_sprite:
		var player_path := "res://assets/ui/portraits/portrait_protagonist_male.png"
		if ResourceLoader.exists(player_path):
			_player_sprite.texture = load(player_path) as Texture2D

	# 敌人立绘
	if _enemy_sprite and _combat_system and not _combat_system.battle_units.is_empty():
		var half: int = ceili(_combat_system.battle_units.size() / 2.0)
		if _combat_system.battle_units.size() > half:
			var enemy_unit: Variant = _combat_system.battle_units[half]
			var enemy_id := ""
			if enemy_unit.unit_node is Dictionary:
				enemy_id = str(enemy_unit.unit_node.get("id", ""))
			if not enemy_id.is_empty():
				var enemy_path := "res://assets/ui/enemy_portraits/%s.png" % enemy_id
				if ResourceLoader.exists(enemy_path):
					_enemy_sprite.texture = load(enemy_path) as Texture2D


## 攻击动画: 攻击方前冲 → 目标闪烁+抖动 → 弹回
func _play_attack_anim(attacker: TextureRect, target: TextureRect) -> void:
	if attacker == null or target == null:
		return
	var orig_x := attacker.position.x
	var direction := 1.0 if attacker == _player_sprite else -1.0
	var tween := create_tween()
	tween.tween_property(attacker, "position:x", orig_x + 80.0 * direction, 0.12)
	tween.tween_callback(_flash_sprite.bind(target))
	tween.tween_callback(_shake_sprite.bind(target))
	tween.tween_property(attacker, "position:x", orig_x, 0.12)


## 防御动画: 闪烁蓝色
func _play_defend_anim(defender: TextureRect) -> void:
	if defender == null:
		return
	var tween := create_tween()
	tween.tween_property(defender, "modulate", Color(0.5, 0.5, 1.0, 1.0), 0.1)
	tween.tween_property(defender, "modulate", Color.WHITE, 0.15)


## 被击闪烁
func _flash_sprite(sprite: TextureRect) -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 0.5, 0.5, 1.0), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


## 受击抖动
func _shake_sprite(sprite: TextureRect) -> void:
	if sprite == null:
		return
	var orig_pos := sprite.position
	var tween := create_tween()
	tween.tween_property(sprite, "position", orig_pos + Vector2(12, -6), 0.03)
	tween.tween_property(sprite, "position", orig_pos + Vector2(-10, 4), 0.03)
	tween.tween_property(sprite, "position", orig_pos + Vector2(6, -3), 0.03)
	tween.tween_property(sprite, "position", orig_pos, 0.04)


## 伤害数字飞出
## 预留: 未来用 AnimatedSprite2D 替换为序列帧打击特效时,
## 在此函数中同步播放技能对应的 SpriteFrames
func _spawn_damage_number(target: TextureRect, damage: int, is_critical: bool) -> void:
	if target == null or damage <= 0:
		return

	var label := Label.new()
	label.text = str(damage)
	if is_critical:
		label.text = str(damage) + " 暴击!"
		label.add_theme_font_size_override("font_size", 36)
		label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	else:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))

	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var root: Control = $Root
	root.add_child(label)

	var start_pos := target.position + target.size * 0.5 + Vector2(0, -30)
	label.position = start_pos
	label.z_index = 100

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", start_pos.y - 80.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## 回合提示横幅
func _show_turn_banner(text: String, color: Color) -> void:
	var banner := Label.new()
	banner.text = text
	banner.add_theme_font_size_override("font_size", 42)
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	banner.add_theme_constant_override("shadow_offset_x", 3)
	banner.add_theme_constant_override("shadow_offset_y", 3)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var root: Control = $Root
	root.add_child(banner)
	banner.anchors_preset = Control.PRESET_CENTER
	banner.position = root.size * 0.5 - Vector2(150, 30)
	banner.z_index = 200

	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(1.5, 1.5)
	banner.pivot_offset = Vector2(150, 30)

	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(banner, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.6)
	tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(banner.queue_free)


## 连携槽检查 — 满槽时显示按钮
func _update_link_button() -> void:
	if _link_btn == null or _combat_system == null:
		return
	if _combat_system.battle_units.is_empty():
		_link_btn.visible = false
		return
	var player_unit: Variant = _combat_system.battle_units[0]
	var link_gauge: int = player_unit.link_gauge if player_unit.get("link_gauge") != null else 0
	var max_link: int = _combat_system.max_link_gauge if _combat_system.get("max_link_gauge") != null else 100
	_link_btn.visible = link_gauge >= max_link
	if _link_btn.visible:
		_link_btn.text = "连携! (%d/%d)" % [link_gauge, max_link]


## 连携按钮点击 — 释放连携技 (全体伤害 ×2)
func _on_link_pressed() -> void:
	if not _player_turn or _combat_system == null:
		return

	var target_idx := _find_enemy_target()
	if target_idx < 0:
		return

	_set_actions_visible(false)
	_link_btn.visible = false

	# 连携技: 全力一击, 消耗满连携槽
	var player_unit: Variant = _combat_system.battle_units[0]
	if player_unit.get("link_gauge") != null:
		player_unit.link_gauge = 0

	_combat_system.execute_action({
		"type": "use_skill",
		"name": "连携·合击",
		"target_index": target_idx,
		"power": 200,
		"internal_energy_cost": 0.0,
		"tags": [],
		"damage_multiplier_override": 2.0,
	})

	_add_log_line("[color=gold]✨ 连携技·合击！伤害翻倍！[/color]")
	_play_attack_anim(_player_sprite, _enemy_sprite)
	_player_turn = false
	_schedule_next_auto_turn()
