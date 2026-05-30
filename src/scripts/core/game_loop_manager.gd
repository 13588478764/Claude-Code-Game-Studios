## GameLoopManager
## 游戏核心循环管理器（胶水层）
##
## 串联各独立子系统，驱动 MVP 游戏循环：
## 探索 → 遭遇/战斗 → 奖励 → 成长 → 探索
##
## 不修改子系统内部逻辑，仅通过信号和公共 API 对接。

extends Node

# ============================================================================
# 游戏状态
# ============================================================================

enum GameState {
	MENU,
	EXPLORING,
	IN_COMBAT,
	COMBAT_RESULT,
}

# ============================================================================
# 区域定义
# ============================================================================

const REGIONS: Array[Dictionary] = [
	{"id": "start_village", "name": "新手村·青石镇", "level": 1, "region_id": 0, "encounter_rate": 0.4, "bg": "bg_town_street"},
	{"id": "bandit_fortress", "name": "黑风寨", "level": 5, "region_id": 1, "encounter_rate": 0.6, "bg": "bg_evil_camp"},
	{"id": "jiangnan_water", "name": "江南水乡", "level": 8, "region_id": 2, "encounter_rate": 0.35, "bg": "bg_mystic_forest"},
	{"id": "qingyun_mountain", "name": "青云山", "level": 10, "region_id": 3, "encounter_rate": 0.5, "bg": "bg_sect_hall"},
	{"id": "ancient_tomb", "name": "上古墓穴", "level": 20, "region_id": 4, "encounter_rate": 0.7, "bg": "bg_ancient_tomb"},
	{"id": "demon_domain", "name": "万魔域", "level": 35, "region_id": 5, "encounter_rate": 0.8, "bg": "bg_evil_camp"},
	{"id": "immortal_palace", "name": "仙人遗府", "level": 50, "region_id": 6, "encounter_rate": 0.6, "bg": "bg_immortal_palace"},
	{"id": "heavenly_peak", "name": "天剑峰", "level": 65, "region_id": 7, "encounter_rate": 0.5, "bg": "bg_sect_hall"},
	{"id": "void_realm", "name": "虚空裂境", "level": 80, "region_id": 8, "encounter_rate": 0.9, "bg": "bg_ancient_tomb"},
]

# 敌人模板：按区域定义基础数据
const ENEMY_TEMPLATES: Dictionary = {
	"start_village": [
		{"id": "enemy_fire_wolf", "name": "野狼", "base_hp": 60, "base_attack": 8, "speed": 8, "type": 0},
		{"id": "enemy_bandit_minion", "name": "山贼喽啰", "base_hp": 80, "base_attack": 10, "speed": 7, "type": 0},
	],
	"bandit_fortress": [
		{"id": "enemy_evil_disciple", "name": "黑风寨匪徒", "base_hp": 120, "base_attack": 18, "speed": 9, "type": 1},
		{"id": "enemy_evil_elder", "name": "黑风寨头目", "base_hp": 200, "base_attack": 25, "speed": 6, "type": 2},
	],
	"qingyun_mountain": [
		{"id": "enemy_thunder_beast_king", "name": "妖兽", "base_hp": 150, "base_attack": 22, "speed": 12, "type": 1},
		{"id": "enemy_elemental_guardian", "name": "护山灵兽", "base_hp": 250, "base_attack": 30, "speed": 8, "type": 2},
	],
	"jiangnan_water": [
		{"id": "enemy_water_serpent", "name": "水贼", "base_hp": 100, "base_attack": 15, "speed": 10, "type": 0},
		{"id": "enemy_ghost_cultivator", "name": "邪修弟子", "base_hp": 180, "base_attack": 20, "speed": 11, "type": 1},
	],
	"ancient_tomb": [
		{"id": "enemy_puppet_cultivator", "name": "傀儡修士", "base_hp": 300, "base_attack": 35, "speed": 8, "type": 1},
		{"id": "enemy_ghost_cultivator", "name": "怨灵", "base_hp": 250, "base_attack": 40, "speed": 12, "type": 1},
	],
	"demon_domain": [
		{"id": "enemy_evil_elder", "name": "魔道长老", "base_hp": 500, "base_attack": 55, "speed": 10, "type": 2},
		{"id": "enemy_fox_spirit", "name": "妖狐", "base_hp": 400, "base_attack": 45, "speed": 14, "type": 1},
	],
	"immortal_palace": [
		{"id": "enemy_elemental_guardian", "name": "仙府守卫", "base_hp": 800, "base_attack": 70, "speed": 9, "type": 2},
		{"id": "enemy_puppet_cultivator", "name": "上古傀儡", "base_hp": 650, "base_attack": 60, "speed": 7, "type": 1},
	],
	"heavenly_peak": [
		{"id": "enemy_boss_tianjie_zhenjun", "name": "天劫真君", "base_hp": 1200, "base_attack": 90, "speed": 11, "type": 2},
		{"id": "enemy_thunder_beast_king", "name": "雷兽王", "base_hp": 1000, "base_attack": 80, "speed": 13, "type": 2},
	],
	"void_realm": [
		{"id": "enemy_boss_demon_god", "name": "魔神残影", "base_hp": 2000, "base_attack": 120, "speed": 12, "type": 2},
		{"id": "enemy_boss_heart_demon", "name": "心魔化身", "base_hp": 1500, "base_attack": 100, "speed": 15, "type": 2},
	],
}

# 奖励配置
const BASE_EXP_PER_ENEMY: int = 50
const BASE_SILVER_PER_ENEMY: int = 20
const REGION_REWARD_MULTIPLIER: Array[float] = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]

## 战斗掉落物品表（按区域, 含装备和武学残页）
const BATTLE_DROP_TABLE: Dictionary = {
	"start_village": [
		{"item_id": "health_pill", "name": "回春丹", "chance": 0.3, "count": 1},
		{"item_id": "common_sword", "name": "普通铁剑", "chance": 0.05, "count": 1},
	],
	"bandit_fortress": [
		{"item_id": "health_pill", "name": "回春丹", "chance": 0.25, "count": 1},
		{"item_id": "spirit_stone_small", "name": "小灵石", "chance": 0.15, "count": 1},
		{"item_id": "common_helmet", "name": "布帽", "chance": 0.08, "count": 1},
		{"item_id": "body_cloth_robe", "name": "布衣", "chance": 0.08, "count": 1},
		{"item_id": "feet_straw_sandals", "name": "草鞋", "chance": 0.1, "count": 1},
	],
	"jiangnan_water": [
		{"item_id": "health_pill", "name": "回春丹", "chance": 0.25, "count": 1},
		{"item_id": "spirit_stone_small", "name": "小灵石", "chance": 0.2, "count": 1},
		{"item_id": "common_ring", "name": "铜戒", "chance": 0.08, "count": 1},
	],
	"qingyun_mountain": [
		{"item_id": "spirit_stone_small", "name": "小灵石", "chance": 0.3, "count": 2},
		{"item_id": "health_pill", "name": "回春丹", "chance": 0.2, "count": 2},
		{"item_id": "rare_sword", "name": "精钢剑", "chance": 0.06, "count": 1},
		{"item_id": "body_iron_armor", "name": "铁甲", "chance": 0.06, "count": 1},
		{"item_id": "feet_cloud_boots", "name": "踏云靴", "chance": 0.06, "count": 1},
		{"item_id": "neck_jade_pendant", "name": "翡翠坠", "chance": 0.07, "count": 1},
		{"item_id": "ancient_sword_technique_fragment", "name": "古剑术残篇", "chance": 0.1, "count": 1},
	],
	"ancient_tomb": [
		{"item_id": "health_pill", "name": "回春丹", "chance": 0.2, "count": 2},
		{"item_id": "rare_helmet", "name": "铁盔", "chance": 0.1, "count": 1},
		{"item_id": "rare_ring", "name": "银戒", "chance": 0.08, "count": 1},
		{"item_id": "hands_iron_gauntlets", "name": "铁护手", "chance": 0.08, "count": 1},
		{"item_id": "offhand_iron_shield", "name": "铁盾", "chance": 0.07, "count": 1},
		{"item_id": "ancient_martial_art_fragment", "name": "上古武学残卷", "chance": 0.12, "count": 1},
	],
	"demon_domain": [
		{"item_id": "health_pill", "name": "回春丹", "chance": 0.15, "count": 3},
		{"item_id": "epic_sword", "name": "青冥剑", "chance": 0.04, "count": 1},
		{"item_id": "epic_helmet", "name": "龙鳞盔", "chance": 0.04, "count": 1},
		{"item_id": "body_cloud_robe", "name": "流云袍", "chance": 0.05, "count": 1},
		{"item_id": "hands_dragon_gloves", "name": "龙爪手套", "chance": 0.05, "count": 1},
		{"item_id": "feet_lingbo_boots", "name": "凌波微步靴", "chance": 0.04, "count": 1},
		{"item_id": "neck_spirit_necklace", "name": "灵气项链", "chance": 0.05, "count": 1},
		{"item_id": "offhand_xuanwu_shield", "name": "玄武盾", "chance": 0.04, "count": 1},
		{"item_id": "ancient_martial_art_fragment", "name": "上古武学残卷", "chance": 0.15, "count": 1},
	],
	"immortal_palace": [
		{"item_id": "epic_ring", "name": "火焰戒指", "chance": 0.06, "count": 1},
		{"item_id": "epic_sword", "name": "青冥剑", "chance": 0.05, "count": 1},
		{"item_id": "body_celestial_armor", "name": "天蚕宝甲", "chance": 0.03, "count": 1},
		{"item_id": "feet_wind_treader", "name": "御风靴", "chance": 0.03, "count": 1},
		{"item_id": "hands_void_gauntlets", "name": "虚空护手", "chance": 0.03, "count": 1},
		{"item_id": "ancient_technique_scroll", "name": "上古功法卷轴", "chance": 0.1, "count": 1},
		{"item_id": "breakthrough_pill", "name": "筑基丹", "chance": 0.08, "count": 1},
	],
	"heavenly_peak": [
		{"item_id": "legendary_sword", "name": "轩辕剑", "chance": 0.02, "count": 1},
		{"item_id": "legendary_helmet", "name": "九天玄女冠", "chance": 0.02, "count": 1},
		{"item_id": "offhand_divine_mirror", "name": "照妖镜", "chance": 0.02, "count": 1},
		{"item_id": "neck_dragon_pendant", "name": "龙骨吊坠", "chance": 0.02, "count": 1},
		{"item_id": "ancient_technique_complete", "name": "完整上古功法", "chance": 0.05, "count": 1},
		{"item_id": "wash_marrow_pill", "name": "洗髓丹", "chance": 0.06, "count": 1},
	],
	"void_realm": [
		{"item_id": "legendary_sword", "name": "轩辕剑", "chance": 0.04, "count": 1},
		{"item_id": "legendary_ring", "name": "五行轮回戒", "chance": 0.03, "count": 1},
		{"item_id": "body_celestial_armor", "name": "天蚕宝甲", "chance": 0.04, "count": 1},
		{"item_id": "hands_void_gauntlets", "name": "虚空护手", "chance": 0.04, "count": 1},
		{"item_id": "feet_wind_treader", "name": "御风靴", "chance": 0.04, "count": 1},
		{"item_id": "ancient_technique_complete", "name": "完整上古功法", "chance": 0.08, "count": 1},
		{"item_id": "wash_marrow_pill", "name": "洗髓丹", "chance": 0.1, "count": 1},
	],
}

# 非战斗奇遇配置
const ENCOUNTER_BASE_PROB: float = 0.08
const ENCOUNTER_PROB_CAP: float = 0.20

# ============================================================================
# 信号定义
# ============================================================================

signal game_state_changed(new_state: GameState)
signal battle_log_updated(message: String)
signal exploration_result(result_text: String)
signal combat_result_ready(reward_data: Dictionary)

# ============================================================================
# 成员变量
# ============================================================================

var current_state: GameState = GameState.MENU
var current_region: Dictionary = {}
var _combat_system: Node = null
var _character_system: Node = null
var _currency_manager: Node = null
var _game_events: Node = null
var _enemy_generator = null
var _encounter_data_loader: Node = null
var _dialogue_manager: Node = null

## 当前战斗的敌人数量（用于奖励计算）
var _current_battle_enemy_count: int = 0

## 自动战斗定时器
var _auto_battle_timer: Timer = null

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	_game_events = get_node_or_null("/root/GameEvents")
	_character_system = get_node_or_null("/root/CharacterSystem")
	_combat_system = get_node_or_null("/root/CombatSystem")
	_currency_manager = get_node_or_null("/root/CurrencyManager")

	_encounter_data_loader = get_node_or_null("/root/EncounterDataLoader")
	_dialogue_manager = get_node_or_null("/root/DialogueManager")

	# 创建 EnemyGenerator 实例
	var EnemyGeneratorScript = load("res://src/scripts/enemy_scaling/enemy_generator.gd")
	if EnemyGeneratorScript:
		_enemy_generator = EnemyGeneratorScript.new()

	# 创建自动战斗定时器
	_auto_battle_timer = Timer.new()
	_auto_battle_timer.wait_time = 0.5
	_auto_battle_timer.one_shot = true
	_auto_battle_timer.timeout.connect(_on_auto_battle_tick)
	add_child(_auto_battle_timer)

	_connect_signals()

	# 默认选中第一个区域
	current_region = REGIONS[0]

	print("[GameLoopManager] 初始化完成")


func _connect_signals() -> void:
	if _game_events == null:
		push_warning("[GameLoopManager] GameEvents 未找到")
		return

	_game_events.combat_ended.connect(_on_combat_ended)
	_game_events.combat_started.connect(_on_combat_started)

# ============================================================================
# 公共 API
# ============================================================================

## 进入探索状态
func enter_exploration() -> void:
	_set_state(GameState.EXPLORING)


## 选择区域
func select_region(region_index: int) -> void:
	if region_index < 0 or region_index >= REGIONS.size():
		return
	current_region = REGIONS[region_index]
	print("[GameLoopManager] 切换区域: %s" % current_region.name)
	_auto_save()


## 执行一次探索行动
func do_explore_action() -> Dictionary:
	if current_state != GameState.EXPLORING:
		return {"type": "error", "message": "当前不在探索状态"}

	# 判定是否触发战斗
	var roll := randf()
	if roll < current_region.encounter_rate:
		_start_random_battle()
		return {"type": "combat", "message": "遭遇敌人！"}

	# 未触发战斗，检查非战斗奇遇
	var encounter_result := _check_non_combat_encounter()
	if encounter_result.get("triggered", false):
		return encounter_result

	# 普通探索奖励 (随区域等级缩放)
	var region_level: int = current_region.get("level", 1)
	var explore_exp := randi_range(5, 15) * region_level
	if _character_system:
		_character_system.add_experience(explore_exp)

	var result_text := "探索了%s，获得 %d 经验。" % [current_region.name, explore_exp]
	exploration_result.emit(result_text)
	return {"type": "explore", "message": result_text, "exp": explore_exp}


## 获取角色状态摘要
func get_player_summary() -> Dictionary:
	if _character_system == null:
		return {}

	var silver := 0
	if _currency_manager and _currency_manager.has_method("get_currency_amount"):
		silver = _currency_manager.get_currency_amount(0)  # SILVER = 0

	return {
		"level": _character_system.level,
		"exp": _character_system.experience,
		"exp_next": _character_system.get_exp_required_for_level(_character_system.level + 1) if _character_system.has_method("get_exp_required_for_level") else 100,
		"realm": _character_system.REALMS[_character_system.realm_index]["name"] if _character_system.realm_index < _character_system.REALMS.size() else "未知",
		"hp": _character_system.attributes.constitution * 10,
		"silver": silver,
	}


## 从结算回到探索
func return_to_exploration() -> void:
	_set_state(GameState.EXPLORING)
	_auto_save()


func _auto_save() -> void:
	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys and save_sys.has_method("save_to_slot"):
		save_sys.save_to_slot(1)

# ============================================================================
# 非战斗奇遇
# ============================================================================

## 检查非战斗奇遇触发（概率公式：基础概率 * (1 + 福缘加成系数), 100 点后软上限递减, 总上限20%）
## 福缘加成系数真值: CharacterSystem.get_luck_bonus_coefficient (对齐 character-progression-system.md L146-L152)
func _check_non_combat_encounter() -> Dictionary:
	var luck_stat := 0.0
	if _character_system and _character_system.attributes:
		luck_stat = _character_system.attributes.luck

	var prob := ENCOUNTER_BASE_PROB * (1.0 + CharacterSystem.get_luck_bonus_coefficient(luck_stat))
	prob = minf(prob, ENCOUNTER_PROB_CAP)

	var roll := randf()
	print("[GameLoopManager] 奇遇检定: roll=%.3f, 阈值=%.3f, %s" % [roll, prob, "通过！" if roll <= prob else "未触发"])
	if roll > prob:
		return {"triggered": false}
	# 优先使用 EncounterDataLoader 的30个数据驱动奇遇
	if _encounter_data_loader and _encounter_data_loader.get_encounter_count() > 0:
		var region_id: String = current_region.get("id", "")
		var encounter_meta: Dictionary = _encounter_data_loader.select_random_encounter(region_id)

		if not encounter_meta.is_empty():
			var enc_id: String = encounter_meta.id
			_encounter_data_loader.mark_triggered(enc_id)

			# 通过 DialogueManager 启动奇遇对话树（奖励由对话 effects 自动处理）
			if _dialogue_manager and _dialogue_manager.has_dialogue(enc_id):
				_dialogue_manager.start_dialogue(enc_id)

			var result_text := "✨ 仙缘奇遇 — %s！" % encounter_meta.title
			exploration_result.emit(result_text)

			# 记录奇遇历史
			var record_mgr = get_node_or_null("/root/EncounterRecordManager")
			if record_mgr and record_mgr.has_method("mark_encounter_completed"):
				record_mgr.mark_encounter_completed(enc_id)

			return {
				"triggered": true,
				"type": "dialogue_encounter",
				"encounter_type": encounter_meta.type,
				"dialogue_id": enc_id,
				"message": result_text,
			}

	# 降级：如果 EncounterDataLoader 不可用，给予基础经验奖励
	var fallback_exp := randi_range(30, 80)
	if _character_system:
		_character_system.add_experience(fallback_exp)
	var fallback_text := "✨ 仙缘奇遇 — 江湖传闻！获得 %d 经验。" % fallback_exp
	exploration_result.emit(fallback_text)
	return {
		"triggered": true,
		"type": "encounter",
		"encounter_type": "fallback",
		"message": fallback_text,
	}

# ============================================================================
# 战斗流程
# ============================================================================

func _start_random_battle() -> void:
	if _combat_system == null:
		push_warning("[GameLoopManager] CombatSystem 未找到，跳过战斗")
		return

	# 选择敌人模板
	var templates: Array = ENEMY_TEMPLATES.get(current_region.id, ENEMY_TEMPLATES["start_village"])
	var template: Dictionary = templates[randi() % templates.size()]

	# 构建玩家战斗数据
	var player_data := _build_player_battle_data()

	# 构建敌人战斗数据
	var enemy_data := _build_enemy_battle_data(template)

	_current_battle_enemy_count = 1

	battle_log_updated.emit("⚔️ 遭遇 %s！战斗开始！" % template.name)

	# 启动战斗（前半是玩家，后半是敌人）
	_combat_system.start_battle([player_data, enemy_data])


func _build_player_battle_data() -> Dictionary:
	if _character_system == null:
		return {"name": "玩家", "hp": 100, "max_hp": 100, "speed": 10, "attributes": {}}

	# 使用 get_final_attributes (含境界+天赋+装备加成)
	var final_attrs = _character_system.get_final_attributes()
	var combat_stats: Dictionary = _character_system.get_combat_stats()

	var max_hp: int = combat_stats.get("max_health", final_attrs.constitution * 10)
	var max_energy: int = combat_stats.get("internal_energy_max", final_attrs.intelligence * 5)
	var total_attrs: Dictionary = {
		"force": final_attrs.strength,
		"strength": final_attrs.strength,
		"agility": final_attrs.agility,
		"constitution": final_attrs.constitution,
		"intelligence": final_attrs.intelligence,
		"willpower": final_attrs.willpower,
		"luck": final_attrs.luck,
		"critical_rate": combat_stats.get("critical_rate", 0.05),
		"critical_damage": 50.0,
		"physical_attack": combat_stats.get("physical_attack", final_attrs.strength * 2),
		"defense": combat_stats.get("defense", final_attrs.constitution),
		"evasion": combat_stats.get("evasion", 0.0),
	}
	return {
		"name": "玩家",
		"hp": max_hp,
		"max_hp": max_hp,
		"speed": final_attrs.agility,
		"internal_energy": max_energy,
		"max_internal_energy": max_energy,
		"stance": 100,
		"combo_value": 0,
		"link_gauge": 0,
		"attributes": total_attrs,
		"is_player": true,
	}


func _build_enemy_battle_data(template: Dictionary) -> Dictionary:
	var player_level: int = 1
	if _character_system:
		player_level = _character_system.level

	# 用 EnemyGenerator 缩放（如果可用）
	if _enemy_generator:
		var scaled = _enemy_generator.generate_enemy_instance(
			template, player_level, current_region.region_id, template.type
		)
		return {
			"id": template.get("id", ""),
			"name": template.name,
			"hp": int(scaled.final_hp),
			"max_hp": int(scaled.final_hp),
			"speed": template.speed,
			"internal_energy": 30,
			"max_internal_energy": 50,
			"stance": 100,
			"combo_value": 0,
			"link_gauge": 0,
			"attributes": {"force": int(scaled.final_attack / 2)},
			"is_player": false,
		}

	# 降级：直接使用模板数据
	return {
		"id": template.get("id", ""),
		"name": template.name,
		"hp": template.base_hp,
		"max_hp": template.base_hp,
		"speed": template.speed,
		"internal_energy": 30,
		"max_internal_energy": 50,
		"stance": 100,
		"combo_value": 0,
		"link_gauge": 0,
		"attributes": {"force": template.base_attack / 2},
		"is_player": false,
	}

# ============================================================================
# 自动战斗
# ============================================================================

func _on_combat_started() -> void:
	_set_state(GameState.IN_COMBAT)
	# 延迟启动自动战斗，等待 CombatManager 完成初始化
	_auto_battle_timer.start()


func _on_auto_battle_tick() -> void:
	if current_state != GameState.IN_COMBAT:
		return
	if _combat_system == null:
		return

	# 玩家回合由 CombatActionPanel 处理，不自动行动
	var current_unit = _combat_system.current_turn_unit
	if current_unit != null:
		var idx: int = _combat_system.battle_units.find(current_unit)
		var half: int = ceili(_combat_system.battle_units.size() / 2.0)
		if idx >= 0 and idx < half:
			return
	else:
		return

	if _combat_system.battle_state == 0:  # IDLE
		return

	# 如果战斗已经结束，不再执行
	if _combat_system.is_battle_over():
		return

	# 自动选择攻击目标：找到第一个存活的对手
	var target_index := _find_attack_target(current_unit)
	if target_index >= 0:
		var action_data := {
			"type": "attack",
			"target_index": target_index,
		}
		_combat_system.execute_action(action_data)
		var target_name: String = ""
		if target_index < _combat_system.battle_units.size():
			var target = _combat_system.battle_units[target_index]
			if target.unit_node is Dictionary:
				target_name = target.unit_node.get("name", "目标")

		battle_log_updated.emit("回合行动完成")
	else:
		# 没有可攻击目标，结束战斗
		_combat_system.end_battle()
		return

	# 继续下一个自动回合
	if not _combat_system.is_battle_over():
		_auto_battle_timer.start()


func _find_attack_target(current_unit) -> int:
	var current_index: int = _combat_system.battle_units.find(current_unit)
	var half: int = ceili(_combat_system.battle_units.size() / 2.0)
	var is_player_unit: bool = current_index < half

	# 玩家单位攻击敌人（后半），敌人攻击玩家（前半）
	for i in range(_combat_system.battle_units.size()):
		var unit = _combat_system.battle_units[i]
		if unit.current_hp <= 0:
			continue
		if is_player_unit and i >= half:
			return i
		if not is_player_unit and i < half:
			return i

	return -1

# ============================================================================
# 战斗结算
# ============================================================================

func _on_combat_ended(victory: bool, result: Dictionary) -> void:
	_auto_battle_timer.stop()

	if current_state != GameState.IN_COMBAT:
		return

	var fled: bool = result.get("fled", false)
	var reward_data := {}
	if victory and not fled:
		reward_data = _calculate_rewards()
		reward_data["used_martial_arts"] = result.get("used_martial_arts", [])
		_distribute_rewards(reward_data)
	else:
		# 失败惩罚: 扣除 10% 银两
		var penalty_silver: int = 0
		if _currency_manager and not fled:
			var current_silver: int = _currency_manager.get_currency_amount(0)
			penalty_silver = int(current_silver * 0.1)
			if penalty_silver > 0:
				_currency_manager.deduct_currency(0, penalty_silver)
		reward_data = {"victory": false, "exp": 0, "silver": -penalty_silver}

	reward_data["victory"] = victory
	reward_data["fled"] = fled
	reward_data["battle_log"] = result.get("battle_log", [])

	_set_state(GameState.COMBAT_RESULT)

	var end_msg: String
	if fled:
		end_msg = "战斗结束！成功逃跑，未获得奖励。"
	elif victory:
		end_msg = "战斗结束！胜利！"
	else:
		end_msg = "战斗结束！失败..."

	combat_result_ready.emit(reward_data)
	battle_log_updated.emit(end_msg)


func _calculate_rewards() -> Dictionary:
	var region_mult: float = 1.0
	if current_region.region_id < REGION_REWARD_MULTIPLIER.size():
		region_mult = REGION_REWARD_MULTIPLIER[current_region.region_id]

	# 战斗经验随区域等级缩放: base * 区域等级 * 区域系数
	var region_level: int = current_region.get("level", 1)
	var exp_reward := int(BASE_EXP_PER_ENEMY * region_level * region_mult * _current_battle_enemy_count)
	var silver_reward := int(BASE_SILVER_PER_ENEMY * region_level * region_mult * _current_battle_enemy_count)

	# 物品掉落计算
	var drops: Array = []
	var drop_table: Array = BATTLE_DROP_TABLE.get(current_region.id, [])
	for entry in drop_table:
		if randf() < entry.chance:
			drops.append({"item_id": entry.item_id, "name": entry.name, "count": entry.count})

	return {
		"exp": exp_reward,
		"silver": silver_reward,
		"region": current_region.name,
		"drops": drops,
	}


func _distribute_rewards(rewards: Dictionary) -> void:
	if _character_system and rewards.get("exp", 0) > 0:
		var old_level: int = _character_system.level
		_character_system.add_experience(rewards["exp"])
		rewards["level_up"] = _character_system.level > old_level
		rewards["new_level"] = _character_system.level

	if _currency_manager and rewards.get("silver", 0) > 0:
		_currency_manager.add_currency(0, rewards["silver"])  # CurrencyType.SILVER = 0

	# 物品掉落发放
	var inv = get_node_or_null("/root/InventorySystem")
	var drops: Array = rewards.get("drops", [])
	if inv and not drops.is_empty():
		for drop in drops:
			inv.add_item(drop.item_id, drop.count)

	# 武学熟练度提升（战斗中使用过的武学各获得 1 点熟练度）
	var used_arts: Array = rewards.get("used_martial_arts", [])
	var martial = get_node_or_null("/root/MartialArtsSystem")
	if martial and not used_arts.is_empty():
		for ma_id in used_arts:
			martial.increase_proficiency(ma_id, 1)
		rewards["proficiency_ups"] = used_arts.size()

	print("[GameLoopManager] 奖励分发: 经验 %d, 银两 %d, 掉落 %d 种, 武学熟练 %d 种" % [rewards.get("exp", 0), rewards.get("silver", 0), drops.size(), used_arts.size()])

# ============================================================================
# 状态管理
# ============================================================================

## 返回主菜单，重置所有状态
func return_to_menu() -> void:
	_auto_battle_timer.stop()
	_set_state(GameState.MENU)
	print("[GameLoopManager] 已返回主菜单")


func _set_state(new_state: GameState) -> void:
	var old := current_state
	current_state = new_state
	game_state_changed.emit(new_state)
	print("[GameLoopManager] 状态: %s → %s" % [GameState.keys()[old], GameState.keys()[new_state]])
