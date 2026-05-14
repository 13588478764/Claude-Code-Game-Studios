## NPC数据验证测试
## 验证 npcs.json 的 schema 合法性和数据完整性
extends GutTest

const NPC_DATA_PATH: String = "res://src/data/npcs.json"
const ITEMS_DATA_PATH: String = "res://src/data/items.json"

var _npc_data: Dictionary = {}
var _items_data: Dictionary = {}

func before_all() -> void:
	# 加载NPC数据
	if FileAccess.file_exists(NPC_DATA_PATH):
		var file := FileAccess.open(NPC_DATA_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			_npc_data = parsed

	# 加载物品数据
	if FileAccess.file_exists(ITEMS_DATA_PATH):
		var file := FileAccess.open(ITEMS_DATA_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary:
			_items_data = parsed

func test_npc_file_exists() -> void:
	assert_true(FileAccess.file_exists(NPC_DATA_PATH), "npcs.json 应存在")

func test_at_least_5_npcs() -> void:
	assert_true(_npc_data.size() >= 5, "至少5个NPC定义，实际: %d" % _npc_data.size())

func test_npc_ids_unique() -> void:
	var ids: Array = _npc_data.keys()
	var unique_ids: Dictionary = {}
	for id in ids:
		assert_false(unique_ids.has(id), "NPC ID重复: %s" % id)
		unique_ids[id] = true

func test_all_npcs_have_required_fields() -> void:
	var required_fields := ["id", "name", "alignment", "gift_preferences"]
	for npc_id in _npc_data:
		var npc: Dictionary = _npc_data[npc_id]
		for field in required_fields:
			assert_true(npc.has(field), "NPC %s 缺少字段: %s" % [npc_id, field])

func test_npc_id_matches_key() -> void:
	for npc_id in _npc_data:
		var npc: Dictionary = _npc_data[npc_id]
		assert_eq(npc.get("id", ""), npc_id, "NPC key与id不匹配: %s" % npc_id)

func test_alignment_values_valid() -> void:
	var valid_alignments := ["righteous", "evil", "neutral"]
	for npc_id in _npc_data:
		var alignment: String = _npc_data[npc_id].get("alignment", "")
		assert_has(valid_alignments, alignment, "NPC %s 无效立场: %s" % [npc_id, alignment])

func test_gift_preferences_structure() -> void:
	for npc_id in _npc_data:
		var prefs: Dictionary = _npc_data[npc_id].get("gift_preferences", {})
		assert_true(prefs.has("loves"), "NPC %s gift_preferences缺少loves" % npc_id)
		assert_true(prefs.has("likes"), "NPC %s gift_preferences缺少likes" % npc_id)
		assert_true(prefs.has("dislikes"), "NPC %s gift_preferences缺少dislikes" % npc_id)
		assert_true(prefs["loves"] is Array, "NPC %s loves应为数组" % npc_id)
		assert_true(prefs["likes"] is Array, "NPC %s likes应为数组" % npc_id)
		assert_true(prefs["dislikes"] is Array, "NPC %s dislikes应为数组" % npc_id)

func test_gift_item_ids_exist_in_items_json() -> void:
	if _items_data.is_empty():
		pass_test("items.json 未加载，跳过交叉验证")
		return

	for npc_id in _npc_data:
		var prefs: Dictionary = _npc_data[npc_id].get("gift_preferences", {})
		for category in ["loves", "likes", "dislikes"]:
			var items: Array = prefs.get(category, [])
			for item_id in items:
				assert_true(_items_data.has(item_id),
					"NPC %s 的 %s 引用不存在的物品: %s" % [npc_id, category, item_id])
