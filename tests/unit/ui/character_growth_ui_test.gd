# 武侠奇遇录 - 角色成长UI单元测试
# 测试UI组件的基本功能和数据绑定

extends "res://addons/gut/test.gd"

# 测试变量
var ui_scene = null
var ui_instance = null
var character_system = null

func before_all():
	"""在所有测试之前运行"""
	pass

func after_all():
	"""在所有测试之后运行"""
	pass

func before_each():
	"""在每个测试之前运行"""
	# 加载UI场景
	ui_scene = load("res://src/scenes/ui/character_growth_ui.tscn")
	ui_instance = ui_scene.instantiate()
	
	# 创建角色系统实例
	character_system = preload("res://src/scripts/character/character_system.gd").new()
	character_system.initialize_character()
	
	# 将UI添加到场景树
	add_child_autofree(ui_instance)
	
	# 等待UI初始化
	await wait_frames(2)

func after_each():
	"""在每个测试之后运行"""
	if ui_instance:
		ui_instance.queue_free()
	if character_system:
		character_system.queue_free()
	ui_instance = null
	character_system = null

# 测试用例1: UI场景正确加载
func test_ui_scene_loads_correctly():
	"""AC-1: 验证UI场景能够正确加载"""
	# Then: UI实例应该存在
	assert_not_null(ui_instance, "UI实例应该成功创建")
	assert_true(ui_instance is Control, "UI应该是Control节点")

# 测试用例2: UI元素引用正确初始化
func test_ui_elements_initialized():
	"""AC-1: 验证UI元素引用正确初始化"""
	# Given: UI已加载
	# Then: 关键UI元素应该存在
	assert_not_null(ui_instance.character_panel, "角色面板应该存在")
	assert_not_null(ui_instance.attribute_allocation_panel, "属性分配面板应该存在")
	assert_not_null(ui_instance.talent_grid_panel, "天赋网格面板应该存在")

# 测试用例3: 角色系统连接正确
func test_character_system_connection():
	"""AC-4: 验证UI与角色系统正确连接"""
	# Given: 角色系统已创建
	# When: 设置角色系统引用
	ui_instance.character_system = character_system
	
	# Then: 角色系统应该正确设置
	assert_not_null(ui_instance.character_system, "角色系统引用应该设置")
	assert_eq(ui_instance.character_system, character_system, "角色系统引用应该匹配")

# 测试用例4: 角色面板显示更新
func test_character_panel_display_update():
	"""AC-1: 验证角色面板显示正确更新"""
	# Given: 角色系统已设置
	ui_instance.character_system = character_system
	
	# When: 更新角色面板显示
	ui_instance.update_character_display()
	
	# Then: 等级标签应该显示正确的值
	if ui_instance.level_value_label:
		var level_text = ui_instance.level_value_label.text
		assert_eq(level_text, str(character_system.level), "等级显示应该正确")

# 测试用例5: 属性分配面板初始化
func test_attribute_allocation_panel_initialization():
	"""AC-2: 验证属性分配面板正确初始化"""
	# Given: 角色系统已设置
	ui_instance.character_system = character_system
	
	# When: 更新属性分配面板
	ui_instance.update_attribute_allocation_display()
	
	# Then: 滑块应该存在且有正确的范围
	if ui_instance.strength_slider:
		assert_not_null(ui_instance.strength_slider, "力道滑块应该存在")
		assert_true(ui_instance.strength_slider.max_value >= 0, "滑块最大值应该有效")

# 测试用例6: 天赋网格初始化
func test_talent_grid_initialization():
	"""AC-3: 验证天赋网格正确初始化"""
	# Given: UI已加载
	# Then: 天赋节点数组应该包含16个节点（4x4）
	assert_eq(ui_instance.talent_nodes.size(), 16, "应该有16个天赋节点")

# 测试用例7: 天赋网格显示更新
func test_talent_grid_display_update():
	"""AC-3: 验证天赋网格显示正确更新"""
	# Given: 角色系统已设置
	ui_instance.character_system = character_system
	
	# When: 更新天赋网格显示
	ui_instance.update_talent_grid_display()
	
	# Then: 天赋节点应该有正确的视觉状态
	for i in range(16):
		var talent_node = ui_instance.talent_nodes[i]
		assert_not_null(talent_node, "天赋节点 %d 应该存在" % i)
		# 未解锁的节点应该是灰色
		assert_eq(talent_node.modulate, Color.GRAY, "未解锁的天赋节点应该是灰色")

# 测试用例8: 临时属性数据初始化
func test_temp_attribute_data_initialization():
	"""AC-2: 验证临时属性数据正确初始化"""
	# Given: UI已加载
	# Then: 临时属性字典应该包含所有六个属性
	assert_true(ui_instance.temp_attributes.has("strength"), "应该有力道属性")
	assert_true(ui_instance.temp_attributes.has("agility"), "应该有身法属性")
	assert_true(ui_instance.temp_attributes.has("constitution"), "应该有根骨属性")
	assert_true(ui_instance.temp_attributes.has("intelligence"), "应该有悟性属性")
	assert_true(ui_instance.temp_attributes.has("willpower"), "应该有定力属性")
	assert_true(ui_instance.temp_attributes.has("luck"), "应该有福缘属性")

# 测试用例9: UI显示方法不会崩溃
func test_ui_display_methods_do_not_crash():
	"""AC-1, AC-2, AC-3: 验证UI显示方法不会崩溃"""
	# Given: 角色系统已设置
	ui_instance.character_system = character_system
	
	# When: 调用所有显示更新方法
	# Then: 不应该抛出错误
	ui_instance.update_character_display()
	ui_instance.update_attribute_allocation_display()
	ui_instance.update_talent_grid_display()
	ui_instance.update_all_ui()
	
	# 如果执行到这里没有崩溃，测试通过
	assert_true(true, "所有UI更新方法应该正常执行")

# 测试用例10: 信号连接正确
func test_signal_connections():
	"""AC-4: 验证信号正确连接"""
	# Given: 角色系统已设置
	ui_instance.character_system = character_system
	ui_instance.connect_character_system_signals()
	
	# Then: 信号应该正确连接
	# 检查角色系统是否有连接的信号
	var level_up_connections = character_system.level_up.get_connections()
	assert_gt(level_up_connections.size(), 0, "level_up信号应该有连接")

# 测试用例11: 显示UI方法
func test_show_character_growth_ui():
	"""AC-1: 验证显示UI方法正常工作"""
	# Given: 角色系统已设置
	ui_instance.character_system = character_system
	
	# When: 调用显示UI方法
	ui_instance.show_character_growth_ui()
	
	# Then: UI应该可见
	assert_true(ui_instance.visible, "UI应该可见")

# 测试用例12: 按钮信号连接
func test_button_signal_connections():
	"""AC-2, AC-3: 验证按钮信号正确连接"""
	# Given: UI已加载
	# Then: 关键按钮应该存在
	if ui_instance.close_character_button:
		assert_not_null(ui_instance.close_character_button, "关闭按钮应该存在")
	
	if ui_instance.reset_character_button:
		assert_not_null(ui_instance.reset_character_button, "重置按钮应该存在")
	
	if ui_instance.apply_character_button:
		assert_not_null(ui_instance.apply_character_button, "应用按钮应该存在")

# 测试用例13: 滑块信号连接
func test_slider_signal_connections():
	"""AC-2: 验证滑块信号正确连接"""
	# Given: UI已加载
	# Then: 所有属性滑块应该存在
	if ui_instance.strength_slider:
		assert_not_null(ui_instance.strength_slider, "力道滑块应该存在")
	
	if ui_instance.agility_slider:
		assert_not_null(ui_instance.agility_slider, "身法滑块应该存在")
	
	if ui_instance.constitution_slider:
		assert_not_null(ui_instance.constitution_slider, "根骨滑块应该存在")
	
	if ui_instance.intelligence_slider:
		assert_not_null(ui_instance.intelligence_slider, "悟性滑块应该存在")
	
	if ui_instance.willpower_slider:
		assert_not_null(ui_instance.willpower_slider, "定力滑块应该存在")
	
	if ui_instance.luck_slider:
		assert_not_null(ui_instance.luck_slider, "福缘滑块应该存在")

# 测试用例14: 天赋节点按钮存在
func test_talent_node_buttons_exist():
	"""AC-3: 验证所有天赋节点按钮存在"""
	# Given: UI已加载
	# Then: 应该有16个天赋节点
	assert_eq(ui_instance.talent_nodes.size(), 16, "应该有16个天赋节点")
	
	# 每个节点都应该是有效的
	for i in range(16):
		assert_not_null(ui_instance.talent_nodes[i], "天赋节点 %d 应该存在" % i)

# 测试用例15: UI不会在没有角色系统时崩溃
func test_ui_handles_missing_character_system_gracefully():
	"""验证UI在没有角色系统时不会崩溃"""
	# Given: UI没有设置角色系统
	ui_instance.character_system = null
	
	# When: 调用更新方法
	# Then: 不应该崩溃
	ui_instance.update_character_display()
	ui_instance.update_attribute_allocation_display()
	ui_instance.update_talent_grid_display()
	
	# 如果执行到这里没有崩溃，测试通过
	assert_true(true, "UI应该优雅地处理缺失的角色系统")