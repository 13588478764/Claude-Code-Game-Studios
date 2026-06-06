## 存档系统
## 负责游戏进度的保存和加载
## Autoload 名称: SaveSystem

extends Node

signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_PATTERN: String = "save_slot_%d.json"
const MAX_SLOTS: int = 3
const LOG_PREFIX: String = "[SaveSystem]"

var _pending_exploration_state: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


## 保存到指定槽位
func save_to_slot(slot: int = 1) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		save_failed.emit(slot, "无效的存档槽位")
		return false

	var save_data: Dictionary = _collect_save_data()
	var character_node = get_node_or_null("/root/CharacterSystem")
	var game_loop_node = get_node_or_null("/root/GameLoopManager")
	save_data["metadata"] = {
		"slot": slot,
		"timestamp": Time.get_datetime_string_from_system(),
		"version": "0.3.0",
		"realm": character_node.get_current_realm()["name"] if character_node else "",
		"region": game_loop_node.current_region.get("name", "") if game_loop_node and game_loop_node.current_region.size() > 0 else "",
	}

	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % slot)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		var err = "无法写入存档文件"
		push_warning("%s %s" % [LOG_PREFIX, err])
		save_failed.emit(slot, err)
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	print("%s 保存成功 (槽位 %d)" % [LOG_PREFIX, slot])
	save_completed.emit(slot)
	return true


## 从指定槽位加载
func load_from_slot(slot: int = 1) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		load_failed.emit(slot, "无效的存档槽位")
		return false

	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % slot)
	if not FileAccess.file_exists(save_path):
		load_failed.emit(slot, "存档不存在")
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		load_failed.emit(slot, "无法读取存档文件")
		return false

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null or not (json is Dictionary):
		load_failed.emit(slot, "存档数据损坏")
		return false

	_restore_save_data(json)
	print("%s 加载成功 (槽位 %d)" % [LOG_PREFIX, slot])
	load_completed.emit(slot)
	return true


## 检查指定槽位是否有存档
func has_save(slot: int = 1) -> bool:
	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % slot)
	return FileAccess.file_exists(save_path)


## 获取存档信息（不加载全部数据）
func get_save_info(slot: int) -> Dictionary:
	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % slot)
	if not FileAccess.file_exists(save_path):
		return {}

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null or not (json is Dictionary):
		return {}

	return json.get("metadata", {})


## 删除指定槽位存档
func delete_save(slot: int) -> void:
	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % slot)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)


## 收集所有系统的数据
func _collect_save_data() -> Dictionary:
	var data: Dictionary = {}

	# 背包和装备
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		data["inventory"] = inv.inventory.duplicate()
		data["equipped_slots"] = inv.equipped_slots.duplicate()

	# 货币
	var currency = get_node_or_null("/root/CurrencyManager")
	if currency:
		data["currencies"] = {}
		for type_value in currency.CurrencyType.values():
			data["currencies"][str(type_value)] = currency.get_currency_amount(type_value)

	# 角色（完整状态）
	var character = get_node_or_null("/root/CharacterSystem")
	if character:
		var attrs: Dictionary = {}
		if character.attributes:
			attrs = character.attributes.get_total()
		data["character"] = {
			"level": character.level,
			"experience": character.experience,
			"realm_index": character.realm_index,
			"realm_bonus": character.realm_bonus,
			"total_attribute_points": character.total_attribute_points,
			"allocated_attribute_points": character.allocated_attribute_points,
			"total_talent_points": character.total_talent_points,
			"allocated_talent_points": character.allocated_talent_points,
			"free_reset_count": character.free_reset_count,
			"attributes": attrs,
		}

	# 当前区域
	var game_loop = get_node_or_null("/root/GameLoopManager")
	if game_loop and game_loop.current_region.size() > 0:
		data["current_region_id"] = game_loop.current_region.get("id", "start_village")

	# 武学系统
	var martial = get_node_or_null("/root/MartialArtsSystem")
	if martial:
		var player_arts: Dictionary = {}
		for art_id in martial.player_martial_arts:
			var art = martial.player_martial_arts[art_id]
			player_arts[art_id] = {
				"proficiency_level": art.proficiency_level,
				"fragments_collected": art.fragments_collected,
			}
		var equipped: Array = []
		for slot in martial.equipped_martial_arts:
			equipped.append(slot.id if slot != null else "")
		data["martial_arts"] = {
			"player_martial_arts": player_arts,
			"player_fragments": martial.player_fragments.duplicate(),
			"equipped_martial_arts": equipped,
		}

	# 奇遇触发记录
	var encounter_loader = get_node_or_null("/root/EncounterDataLoader")
	if encounter_loader and encounter_loader.has_method("save_data"):
		data["encounter_data"] = encounter_loader.save_data()

	# 角色关系系统
	var relationship = get_node_or_null("/root/RelationshipManager")
	if relationship:
		data["relationship"] = relationship.save_data()

	# 关系事件触发记录
	var rel_events = get_node_or_null("/root/RelationshipEventSystem")
	if rel_events and rel_events.has_method("save_data"):
		data["relationship_events"] = rel_events.save_data()

	# 主线进度 (ActManager)
	var act_mgr = get_node_or_null("/root/ActManager")
	if act_mgr and act_mgr.has_method("save_data"):
		data["act_manager"] = act_mgr.save_data()

	# 天赋网格
	var char_sys = get_node_or_null("/root/CharacterSystem")
	if char_sys and char_sys.talent_grid.size() > 0:
		var talent_save: Array = []
		for row in char_sys.talent_grid:
			var row_data: Array = []
			for cell in row:
				row_data.append({"unlocked": cell.get("unlocked", false), "effect": cell.get("effect", {})})
			talent_save.append(row_data)
		data["talent_grid"] = talent_save

	# 探索面板持久化状态（击杀计数/已完成支线/时段）
	var exploration_panels = get_tree().get_nodes_in_group("exploration_panel")
	if exploration_panels.size() == 0:
		for child in get_tree().root.get_children():
			if child.has_method("get_persistent_state"):
				exploration_panels.append(child)
				break
	if exploration_panels.size() > 0 and exploration_panels[0].has_method("get_persistent_state"):
		data["exploration_state"] = exploration_panels[0].get_persistent_state()

	return data


## 恢复存档数据到各系统
func _restore_save_data(data: Dictionary) -> void:
	# 背包
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.inventory.clear()
		if data.has("inventory"):
			for item_id in data.inventory:
				inv.inventory[item_id] = int(data.inventory[item_id])
		# 重置所有槽位再恢复
		for slot_id in inv.equipped_slots:
			inv.equipped_slots[slot_id] = ""
		if data.has("equipped_slots"):
			for slot_id in data.equipped_slots:
				if inv.equipped_slots.has(slot_id):
					inv.equipped_slots[slot_id] = data.equipped_slots[slot_id]

	# 货币
	var currency = get_node_or_null("/root/CurrencyManager")
	if currency and data.has("currencies"):
		for type_str in data.currencies:
			var type_val: int = int(type_str)
			var amount: int = int(data.currencies[type_str])
			currency.set_currency_amount(type_val, amount)

	# 角色（完整恢复）
	var character = get_node_or_null("/root/CharacterSystem")
	if character and data.has("character"):
		var c: Dictionary = data.character
		character.level = int(c.get("level", 1))
		character.experience = int(c.get("experience", 0))
		character.realm_index = int(c.get("realm_index", 0))
		character.realm_bonus = float(c.get("realm_bonus", 1.0))
		character.total_attribute_points = int(c.get("total_attribute_points", 0))
		character.allocated_attribute_points = int(c.get("allocated_attribute_points", 0))
		character.total_talent_points = int(c.get("total_talent_points", 0))
		character.allocated_talent_points = int(c.get("allocated_talent_points", 0))
		character.free_reset_count = int(c.get("free_reset_count", 0))
		if c.has("attributes") and character.attributes:
			var a: Dictionary = c.attributes
			character.attributes.strength = int(a.get("strength", 10))
			character.attributes.agility = int(a.get("agility", 10))
			character.attributes.constitution = int(a.get("constitution", 10))
			character.attributes.intelligence = int(a.get("intelligence", 10))
			character.attributes.willpower = int(a.get("willpower", 10))
			character.attributes.luck = int(a.get("luck", 10))

	# 当前区域
	var game_loop = get_node_or_null("/root/GameLoopManager")
	if game_loop and data.has("current_region_id"):
		var saved_region_id: String = data.current_region_id
		for i in range(game_loop.REGIONS.size()):
			if game_loop.REGIONS[i].id == saved_region_id:
				game_loop.current_region = game_loop.REGIONS[i]
				break

	# 武学系统
	var martial = get_node_or_null("/root/MartialArtsSystem")
	if martial and data.has("martial_arts"):
		var ma: Dictionary = data.martial_arts
		# 恢复已获取的武学
		martial.player_martial_arts.clear()
		if ma.has("player_martial_arts"):
			for art_id in ma.player_martial_arts:
				if martial.martial_arts_database.has(art_id):
					var art_copy = martial.martial_arts_database[art_id].duplicate()
					var saved_art: Dictionary = ma.player_martial_arts[art_id]
					art_copy.proficiency_level = int(saved_art.get("proficiency_level", 1))
					art_copy.fragments_collected = int(saved_art.get("fragments_collected", 0))
					martial.player_martial_arts[art_id] = art_copy
		# 恢复残页
		martial.player_fragments.clear()
		if ma.has("player_fragments"):
			for frag_id in ma.player_fragments:
				martial.player_fragments[frag_id] = int(ma.player_fragments[frag_id])
		# 恢复装备槽位
		if ma.has("equipped_martial_arts"):
			var equipped_ids: Array = ma.equipped_martial_arts
			for i in range(mini(equipped_ids.size(), martial.equipped_martial_arts.size())):
				var eid: String = str(equipped_ids[i])
				if eid.is_empty():
					martial.equipped_martial_arts[i] = null
				elif martial.player_martial_arts.has(eid):
					martial.equipped_martial_arts[i] = martial.player_martial_arts[eid]
				else:
					martial.equipped_martial_arts[i] = null

	# 奇遇触发记录
	var encounter_loader = get_node_or_null("/root/EncounterDataLoader")
	if encounter_loader and encounter_loader.has_method("load_data") and data.has("encounter_data"):
		encounter_loader.load_data(data.encounter_data)

	# 角色关系系统
	var relationship = get_node_or_null("/root/RelationshipManager")
	if relationship and data.has("relationship"):
		relationship.load_data(data.relationship)

	# 关系事件触发记录
	var rel_events = get_node_or_null("/root/RelationshipEventSystem")
	if rel_events and rel_events.has_method("load_data") and data.has("relationship_events"):
		rel_events.load_data(data.relationship_events)

	# 主线进度 (ActManager)
	var act_mgr = get_node_or_null("/root/ActManager")
	if act_mgr and act_mgr.has_method("load_data") and data.has("act_manager"):
		act_mgr.load_data(data.act_manager)

	# 天赋网格
	var char_sys = get_node_or_null("/root/CharacterSystem")
	if char_sys and data.has("talent_grid"):
		var saved_grid: Array = data.talent_grid
		for row_idx in range(mini(saved_grid.size(), char_sys.talent_grid.size())):
			var row: Array = saved_grid[row_idx]
			for col_idx in range(mini(row.size(), char_sys.talent_grid[row_idx].size())):
				char_sys.talent_grid[row_idx][col_idx]["unlocked"] = row[col_idx].get("unlocked", false)
				char_sys.talent_grid[row_idx][col_idx]["effect"] = row[col_idx].get("effect", {})

	# 探索面板持久化状态
	if data.has("exploration_state"):
		_pending_exploration_state = data.exploration_state
