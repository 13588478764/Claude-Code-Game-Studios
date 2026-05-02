extends GutTest

## Story 003: 队友状态显示 - 集成测试
## 测试PartyStatusDisplay和PartyMemberSlot的功能

var party_display: PartyStatusDisplay
var game_events: Node

func before_each() -> void:
	## 测试前准备
	game_events = get_tree().root.get_node_or_null("GameEvents")
	if game_events == null:
		game_events = Node.new()
		game_events.name = "GameEvents"
		get_tree().root.add_child(game_events)
	
	# 创建PartyStatusDisplay实例
	party_display = PartyStatusDisplay.new()
	party_display.name = "PartyStatusDisplay"
	add_child(party_display)
	await get_tree().process_frame

func after_each() -> void:
	## 测试后清理
	if party_display:
		party_display.queue_free()

# ============================================================================
# AC-1: 队友头像正确显示(60x60px)
# ============================================================================

func test_party_member_portrait_size() -> void:
	## AC-1: 验证队友头像尺寸为60x60px
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 100,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	assert_not_null(slot, "队友槽位应该被创建")
	
	var portrait = slot.get_node("HBoxContainer/Portrait")
	assert_eq(portrait.custom_minimum_size, Vector2(60, 60), "头像尺寸应该是60x60px")

func test_party_member_portrait_loaded() -> void:
	## AC-1: 验证队友头像能够加载
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 100,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var portrait = slot.get_node("HBoxContainer/Portrait")
	
	# 验证头像已加载(可能是默认占位符或实际图片)
	assert_not_null(portrait.texture, "头像纹理应该被加载")

# ============================================================================
# AC-2: 队友HP条正确显示当前值/最大值(240x16px)
# ============================================================================

func test_party_member_hp_bar_size() -> void:
	## AC-2: 验证HP条尺寸为240x16px
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 75,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var hp_bar = slot.get_node("HBoxContainer/InfoContainer/HPBar")
	
	assert_eq(hp_bar.custom_minimum_size, Vector2(240, 16), "HP条尺寸应该是240x16px")

func test_party_member_hp_display() -> void:
	## AC-2: 验证HP条显示正确的数值
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 75,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var hp_label = slot.get_node("HBoxContainer/InfoContainer/HPBar/HPLabel")
	
	assert_eq(hp_label.text, "75 / 100", "HP标签应该显示'75 / 100'")

# ============================================================================
# AC-3: 倒地状态有明显视觉标识
# ============================================================================

func test_downed_state_visual_indicator() -> void:
	## AC-3: 验证倒地状态显示灰色滤镜
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 0,
		"max_hp": 100,
		"is_downed": true
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var downed_overlay = slot.get_node("DownedOverlay")
	
	assert_true(downed_overlay.visible, "倒地时应该显示灰色滤镜")
	
	var hp_bar = slot.get_node("HBoxContainer/InfoContainer/HPBar")
	assert_false(hp_bar.visible, "倒地时应该隐藏HP条")

func test_revive_state_visual_indicator() -> void:
	## AC-3: 验证复活后隐藏灰色滤镜
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 50,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var downed_overlay = slot.get_node("DownedOverlay")
	
	assert_false(downed_overlay.visible, "复活时应该隐藏灰色滤镜")
	
	var hp_bar = slot.get_node("HBoxContainer/InfoContainer/HPBar")
	assert_true(hp_bar.visible, "复活时应该显示HP条")

# ============================================================================
# AC-4: 支持最多3名队友同时显示
# ============================================================================

func test_max_three_party_members_displayed() -> void:
	## AC-4: 验证最多显示3名队友
	for i in range(5):
		var member = {
			"id": "member_%03d" % i,
			"name": "队友%d" % i,
			"hp": 100,
			"max_hp": 100,
			"is_downed": false
		}
		party_display._party_members.append(member)
	
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var visible_slots = party_display._member_slots.size()
	assert_eq(visible_slots, 3, "应该最多显示3名队友")

# ============================================================================
# AC-5: 队友加入/离开时UI正确更新
# ============================================================================

func test_party_member_added_signal() -> void:
	## AC-5: 验证队友加入时UI更新
	assert_eq(party_display._party_members.size(), 0, "初始应该没有队友")
	
	party_display._on_party_member_added("member_001", "队友1")
	party_display._party_dirty = true
	await get_tree().process_frame
	
	assert_eq(party_display._party_members.size(), 1, "应该添加1名队友")
	assert_true("member_001" in party_display._member_slots, "队友槽位应该被创建")

func test_party_member_removed_signal() -> void:
	## AC-5: 验证队友离开时UI更新
	party_display._on_party_member_added("member_001", "队友1")
	party_display._party_dirty = true
	await get_tree().process_frame
	
	assert_eq(party_display._party_members.size(), 1, "应该有1名队友")
	
	party_display._on_party_member_removed("member_001")
	party_display._party_dirty = true
	await get_tree().process_frame
	
	assert_eq(party_display._party_members.size(), 0, "队友应该被移除")

# ============================================================================
# AC-6: 队友数量为0时PartyPanel不显示或显示空状态提示
# ============================================================================

func test_empty_state_displayed_when_no_members() -> void:
	## AC-6: 验证无队友时显示空状态提示
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var empty_label = party_display.party_slots_container.get_node_or_null("EmptyLabel")
	assert_not_null(empty_label, "应该显示空状态提示")
	assert_true(empty_label.visible, "空状态提示应该可见")

func test_empty_state_hidden_when_members_exist() -> void:
	## AC-6: 验证有队友时隐藏空状态提示
	party_display._on_party_member_added("member_001", "队友1")
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var empty_label = party_display.party_slots_container.get_node_or_null("EmptyLabel")
	assert_false(empty_label.visible, "有队友时应该隐藏空状态提示")

# ============================================================================
# AC-7: 队友数量超过3时只显示前3名
# ============================================================================

func test_only_first_three_members_displayed() -> void:
	## AC-7: 验证超过3名队友时只显示前3名
	for i in range(5):
		var member = {
			"id": "member_%03d" % i,
			"name": "队友%d" % i,
			"hp": 100,
			"max_hp": 100,
			"is_downed": false
		}
		party_display._party_members.append(member)
	
	party_display._party_dirty = true
	await get_tree().process_frame
	
	# 验证只有前3名队友的槽位被创建
	assert_true("member_000" in party_display._member_slots, "第1名队友应该显示")
	assert_true("member_001" in party_display._member_slots, "第2名队友应该显示")
	assert_true("member_002" in party_display._member_slots, "第3名队友应该显示")
	assert_false("member_003" in party_display._member_slots, "第4名队友不应该显示")
	assert_false("member_004" in party_display._member_slots, "第5名队友不应该显示")

# ============================================================================
# AC-10: 队友HP变化时条形图有0.1秒的平滑过渡动画
# ============================================================================

func test_hp_change_triggers_update() -> void:
	## AC-10: 验证HP变化时更新
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 100,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var hp_bar = slot.get_node("HBoxContainer/InfoContainer/HPBar")
	var initial_value = hp_bar.value
	
	# 触发HP变化
	party_display._on_party_member_hp_changed("member_001", 50, 100)
	await get_tree().process_frame
	
	# 验证HP标签已更新
	var hp_label = slot.get_node("HBoxContainer/InfoContainer/HPBar/HPLabel")
	assert_eq(hp_label.text, "50 / 100", "HP标签应该更新为'50 / 100'")

func test_hp_color_changes_based_on_percentage() -> void:
	## AC-10: 验证HP百分比改变颜色
	var member = {
		"id": "member_001",
		"name": "队友1",
		"hp": 100,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("member_001")
	var hp_bar = slot.get_node("HBoxContainer/InfoContainer/HPBar")
	
	# HP > 60% 应该是绿色
	assert_eq(hp_bar.modulate, Color.GREEN, "HP > 60%时应该是绿色")
	
	# HP 30-60% 应该是黄色
	party_display._on_party_member_hp_changed("member_001", 50, 100)
	await get_tree().process_frame
	assert_eq(hp_bar.modulate, Color.YELLOW, "HP 30-60%时应该是黄色")
	
	# HP < 30% 应该是红色
	party_display._on_party_member_hp_changed("member_001", 20, 100)
	await get_tree().process_frame
	assert_eq(hp_bar.modulate, Color.RED, "HP < 30%时应该是红色")

# ============================================================================
# AC-11: 所有队友头像资源存在于res://assets/ui/party_portraits/目录
# ============================================================================

func test_party_portraits_directory_exists() -> void:
	## AC-11: 验证party_portraits目录存在
	var dir = DirAccess.open("res://assets/ui/party_portraits")
	assert_not_null(dir, "party_portraits目录应该存在")

func test_default_portrait_created_when_missing() -> void:
	## AC-11: 验证缺失头像时创建默认占位符
	var member = {
		"id": "nonexistent_member",
		"name": "不存在的队友",
		"hp": 100,
		"max_hp": 100,
		"is_downed": false
	}
	
	party_display._party_members.append(member)
	party_display._party_dirty = true
	await get_tree().process_frame
	
	var slot = party_display._member_slots.get("nonexistent_member")
	var portrait = slot.get_node("HBoxContainer/Portrait")
	
	# 验证默认占位符已创建
	assert_not_null(portrait.texture, "应该创建默认占位符头像")