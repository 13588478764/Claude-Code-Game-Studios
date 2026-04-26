# 连携系统单元测试
# 验证连携槽、连击、连携攻击和连携条件判定等功能

extends Node

# 加载连携系统
var LinkSystem = load("res://src/scripts/combat/link_system.gd")

var link_system
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始连携系统单元测试...")
	
	# 运行所有测试
	test_link_gauge_system()
	test_combo_system()
	test_link_attack_implementation()
	test_link_condition_check()
	
	# 输出测试结果
	print("\n=== 连携系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试连携槽系统
func test_link_gauge_system():
	print("\n--- 测试连携槽系统 ---")
	
	link_system = LinkSystem.new()
	
	# 初始化测试角色
	var test_characters = [
		{"id": "player1", "is_player": true, "teammates": ["ally1"]},
		{"id": "ally1", "is_player": false, "teammates": ["player1"]},
		{"id": "enemy1", "is_player": false, "teammates": []}
	]
	
	link_system.initialize(test_characters)
	
	# 测试连携槽增加
	var result = link_system.on_attack_event("player1", "enemy1")
	if result.success:
		var player_info = link_system.get_character_link_info("player1")
		if player_info.link_gauge > 0:
			add_test_result("连携槽系统", true, "连携槽正常增加")
		else:
			add_test_result("连携槽系统", false, "连携槽未增加")
	else:
		add_test_result("连携槽系统", false, "攻击事件处理失败")
	
	# 测试连携槽共享机制
	var ally_info = link_system.get_character_link_info("ally1")
	if ally_info.link_gauge > 0:
		add_test_result("连携槽系统", true, "连携槽共享机制正常工作")
	else:
		add_test_result("连携槽系统", false, "连携槽共享机制未工作")

# 测试连击系统
func test_combo_system():
	print("\n--- 测试连击系统 ---")
	
	link_system = LinkSystem.new()
	
	# 初始化测试角色
	var test_characters = [
		{"id": "player1", "is_player": true, "teammates": []},
		{"id": "enemy1", "is_player": false, "teammates": []},
		{"id": "enemy2", "is_player": false, "teammates": []}
	]
	
	link_system.initialize(test_characters)
	
	# 测试连续攻击同一目标增加连击数
	link_system.on_attack_event("player1", "enemy1")
	var info1 = link_system.get_character_link_info("player1")
	var combo_before = info1.combo_count
	
	link_system.on_attack_event("player1", "enemy1")  # 同一目标
	var info2 = link_system.get_character_link_info("player1")
	var combo_after = info2.combo_count
	
	if combo_after > combo_before:
		add_test_result("连击系统", true, "连续攻击同一目标连击数增加")
	else:
		add_test_result("连击系统", false, "连续攻击同一目标连击数未增加")
	
	# 测试切换目标重置连击数
	link_system.on_attack_event("player1", "enemy2")  # 不同目标
	var info3 = link_system.get_character_link_info("player1")
	var combo_after_switch = info3.combo_count
	
	# 由于攻击了不同目标，连击数应该重置或保持较低值
	if combo_after_switch <= 1:  # 第一次攻击新目标
		add_test_result("连击系统", true, "切换目标连击数正确重置")
	else:
		add_test_result("连击系统", false, "切换目标连击数未正确重置")

# 测试连携攻击实现
func test_link_attack_implementation():
	print("\n--- 测试连携攻击实现 ---")
	
	link_system = LinkSystem.new()
	
	# 初始化测试角色
	var test_characters = [
		{"id": "player1", "is_player": true, "teammates": ["ally1"]},
		{"id": "ally1", "is_player": false, "teammates": ["player1"]},
		{"id": "enemy1", "is_player": false, "teammates": []}
	]
	
	link_system.initialize(test_characters)
	
	# 增加连携槽直到足够发动连携攻击
	for i in range(5):
		link_system.on_attack_event("player1", "enemy1")
	
	# 尝试发动追击
	var followup_result = link_system.execute_link_attack("player1", "enemy1", link_system.LinkAttackType.FOLLOW_UP)
	if followup_result.success:
		add_test_result("连携攻击实现", true, "追击功能正常工作")
	else:
		add_test_result("连携攻击实现", false, "追击功能未工作 - " + followup_result.message)
	
	# 尝试发动合体技
	var dualtech_result = link_system.execute_link_attack("player1", "enemy1", link_system.LinkAttackType.DUAL_TECH)
	if dualtech_result.success:
		add_test_result("连携攻击实现", true, "合体技功能正常工作")
	else:
		# 合体技可能因为连携槽不够而失败，这是正常的
		if "连携槽不足" in dualtech_result.message:
			# 再增加一些连携槽再试
			for i in range(10):
				link_system.on_attack_event("player1", "enemy1")
			dualtech_result = link_system.execute_link_attack("player1", "enemy1", link_system.LinkAttackType.DUAL_TECH)
			if dualtech_result.success:
				add_test_result("连携攻击实现", true, "合体技功能正常工作")
			else:
				add_test_result("连协攻击实现", false, "合体技功能未工作 - " + dualtech_result.message)
		else:
			add_test_result("连携攻击实现", false, "合体技功能未工作 - " + dualtech_result.message)

# 测试连携条件判定
func test_link_condition_check():
	print("\n--- 测试连携条件判定 ---")
	
	link_system = LinkSystem.new()
	
	# 初始化测试角色
	var test_characters = [
		{"id": "player1", "is_player": true, "teammates": ["ally1"]},
		{"id": "ally1", "is_player": false, "teammates": ["player1"]},
		{"id": "enemy1", "is_player": false, "teammates": []}
	]
	
	link_system.initialize(test_characters)
	
	# 测试连携槽不足时条件不满足
	var condition_check = link_system.check_link_condition("player1", link_system.LinkAttackType.DUAL_TECH)
	if not condition_check.can_execute:
		add_test_result("连携条件判定", true, "连携槽不足时条件正确判定为不满足")
	else:
		add_test_result("连携条件判定", false, "连携槽不足时条件错误判定为满足")
	
	# 增加连携槽后再测试
	for i in range(10):
		link_system.on_attack_event("player1", "enemy1")
	
	condition_check = link_system.check_link_condition("player1", link_system.LinkAttackType.FOLLOW_UP)
	if condition_check.can_execute:
		add_test_result("连携条件判定", true, "连携槽充足时条件正确判定为满足")
	else:
		add_test_result("连携条件判定", false, "连携槽充足时条件错误判定为不满足")

# 辅助函数：添加测试结果
func add_test_result(test_name: String, passed: bool, message: String):
	test_result.total += 1
	if passed:
		test_result.passed += 1
		print("✅ %s: %s" % [test_name, message])
	else:
		test_result.failed += 1
		print("❌ %s: %s" % [test_name, message])
	
	test_result.details.append("%s: %s" % [test_name, "通过" if passed else "失败 - " + message])