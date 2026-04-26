# 武侠奇遇录 - 属性点分配系统测试脚本
# 用于验证属性点分配功能是否正常工作

extends Node2D

var result_label = null
var verification_label = null
var test_allocation_button = null
var test_reset_button = null

func _ready():
	print("属性点分配系统测试脚本初始化完成")
	
	# 获取UI元素引用
	result_label = get_node("ResultLabel")
	verification_label = get_node("VerificationLabel")
	test_allocation_button = get_node("TestAllocationButton")
	test_reset_button = get_node("TestResetButton")
	
	# 连接按钮信号
	test_allocation_button.pressed.connect(_on_test_allocation_pressed)
	test_reset_button.pressed.connect(_on_test_reset_pressed)
	
	# 显示初始状态
	if result_label != null:
		result_label.text = "测试环境准备就绪\n- 点击'测试分配属性点'按钮开始测试\n- 点击'测试重置属性'按钮测试重置功能"

func _on_test_allocation_pressed():
	"""测试属性点分配功能"""
	print("=== 开始测试属性点分配功能 ===")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		print("❌ 无法访问角色系统")
		if result_label != null:
			result_label.text = "❌ 无法访问角色系统"
		return
	
	# 记录初始状态
	var initial_attributes = character_system.attributes.get_total()
	var initial_available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
	
	print("初始属性: %s" % str(initial_attributes))
	print("可用属性点: %d" % initial_available_points)
	
	if result_label != null:
		result_label.text = "初始状态:\n力道=%d, 身法=%d, 根骨=%d, 悟性=%d, 定力=%d, 福缘=%d\n可用属性点: %d" % [
			initial_attributes["strength"], 
			initial_attributes["agility"], 
			initial_attributes["constitution"], 
			initial_attributes["intelligence"], 
			initial_attributes["willpower"], 
			initial_attributes["luck"],
			initial_available_points
		]
	
	# 测试分配属性点（分配2点到力道）
	if initial_available_points >= 2:
		var allocation_success = character_system.allocate_attribute_points("strength", 2)
		if allocation_success:
			# 检查属性是否正确增加
			var new_attributes = character_system.attributes.get_total()
			var new_available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
			
			print("分配后属性: %s" % str(new_attributes))
			print("分配后可用属性点: %d" % new_available_points)
			
			if new_attributes["strength"] == initial_attributes["strength"] + 2:
				print("✅ 属性点分配成功！力道从 %d 增加到 %d" % [initial_attributes["strength"], new_attributes["strength"]])
				if result_label != null:
					result_label.text += "\n\n✅ 分配成功！\n力道从 %d 增加到 %d\n剩余可用点数: %d" % [
						initial_attributes["strength"], 
						new_attributes["strength"], 
						new_available_points
					]
				
				# 验证战斗属性是否相应更新
				var combat_stats = character_system.get_combat_stats()
				var expected_attack = new_attributes["strength"] * 2
				if combat_stats["physical_attack"] == expected_attack:
					print("✅ 战斗属性正确更新！物理攻击力: %d" % combat_stats["physical_attack"])
					if result_label != null:
						result_label.text += "\n✅ 战斗属性正确更新！物理攻击力: %d" % combat_stats["physical_attack"]
				else:
					print("❌ 战斗属性未正确更新！期望: %d, 实际: %d" % [expected_attack, combat_stats["physical_attack"]])
					if result_label != null:
						result_label.text += "\n❌ 战斗属性未正确更新！期望: %d, 实际: %d" % [expected_attack, combat_stats["physical_attack"]]
			else:
				print("❌ 属性点分配失败！力道未正确增加")
				if result_label != null:
					result_label.text += "\n❌ 属性点分配失败！"
		else:
			print("❌ allocate_attribute_points函数返回false")
			if result_label != null:
				result_label.text += "\n❌ 分配失败！allocate_attribute_points返回false"
	else:
		print("❌ 可用属性点不足，无法进行测试")
		if result_label != null:
			result_label.text += "\n❌ 可用属性点不足，无法进行测试"
	
	# 更新验证状态
	if verification_label != null:
		verification_label.text = "验证状态: 属性分配测试完成"

func _on_test_reset_pressed():
	"""测试属性重置功能"""
	print("=== 开始测试属性重置功能 ===")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		print("❌ 无法访问角色系统")
		if result_label != null:
			result_label.text = "❌ 无法访问角色系统"
		return
	
	# 检查是否有免费重置次数（通常境界突破后会获得）
	var initial_reset_count = character_system.free_reset_count
	print("初始免费重置次数: %d" % initial_reset_count)
	
	# 如果没有免费重置次数，先进行一次境界突破以获得重置次数
	if initial_reset_count <= 0:
		# 模拟境界突破（仅用于测试）
		character_system.free_reset_count = 1
		print("为测试目的，临时设置免费重置次数为1")
	
	if character_system.free_reset_count > 0:
		# 记录当前属性
		var current_attributes = character_system.attributes.get_total()
		var current_allocated_points = character_system.allocated_attribute_points
		
		print("重置前属性: %s" % str(current_attributes))
		print("已分配属性点: %d" % current_allocated_points)
		
		# 尝试重置属性
		var reset_success = character_system.reset_attributes()
		if reset_success:
			var reset_attributes = character_system.attributes.get_total()
			var reset_allocated_points = character_system.allocated_attribute_points
			
			print("重置后属性: %s" % str(reset_attributes))
			print("重置后已分配点数: %d" % reset_allocated_points)
			
			# 检查是否重置到基础值
			if reset_attributes["strength"] == 10 and reset_allocated_points == 0:
				print("✅ 属性重置成功！")
				if result_label != null:
					result_label.text = "✅ 属性重置成功！\n属性已重置为基础值(10)，已分配点数归零"
			else:
				print("❌ 属性重置失败！")
				if result_label != null:
					result_label.text = "❌ 属性重置失败！\n期望: 力道=10, 已分配点数=0\n实际: 力道=%d, 已分配点数=%d" % [
						reset_attributes["strength"], 
						reset_allocated_points
					]
		else:
			print("❌ 重置失败！")
			if result_label != null:
				result_label.text = "❌ 重置失败！reset_attributes函数返回false"
	else:
		print("❌ 没有免费重置次数，无法测试重置功能")
		if result_label != null:
			result_label.text = "❌ 没有免费重置次数，无法测试重置功能\n（境界突破后会获得免费重置次数）"
	
	# 更新验证状态
	if verification_label != null:
		verification_label.text = "验证状态: 属性重置测试完成"

func _on_test_full_workflow_pressed():
	"""测试完整的工作流程"""
	print("=== 开始测试完整工作流程 ===")
	
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		print("❌ 无法访问角色系统")
		return
	
	# 1. 检查初始状态
	var initial_attributes = character_system.attributes.get_total()
	var initial_available_points = character_system.total_attribute_points - character_system.allocated_attribute_points
	
	print("1. 初始状态检查完成")
	
	# 2. 分配一些属性点
	if initial_available_points > 0:
		character_system.allocate_attribute_points("strength", min(2, initial_available_points))
		var after_allocation = character_system.attributes.get_total()
		var after_allocation_available = character_system.total_attribute_points - character_system.allocated_attribute_points
		
		print("2. 属性分配完成，力道从 %d 变为 %d" % [initial_attributes["strength"], after_allocation["strength"]])
	
	# 3. 模拟境界突破以获得重置机会
	character_system.free_reset_count = 1
	var reset_success = character_system.reset_attributes()
	
	if reset_success:
		var after_reset = character_system.attributes.get_total()
		var after_reset_allocated = character_system.allocated_attribute_points
		
		if after_reset["strength"] == 10 and after_reset_allocated == 0:
			print("3. ✅ 完整工作流程测试成功！")
			if result_label != null:
				result_label.text = "✅ 完整工作流程测试成功！\n分配 -> 重置 流程正常工作"
			if verification_label != null:
				verification_label.text = "验证状态: 完整工作流程测试成功"
		else:
			print("3. ❌ 完整工作流程测试失败！")
			if result_label != null:
				result_label.text = "❌ 完整工作流程测试失败！"
	else:
		print("3. ❌ 重置失败，工作流程测试不完整")
		if result_label != null:
			result_label.text = "❌ 重置失败，工作流程测试不完整"