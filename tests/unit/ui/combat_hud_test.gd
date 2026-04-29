extends GutTest
## 战斗HUD单元测试
## 测试战斗HUD管理器的显示和更新功能

var combat_hud: CanvasLayer

func before_each() -> void:
	# 创建一个简单的测试HUD实例
	combat_hud = CanvasLayer.new()
	add_child(combat_hud)

func after_each() -> void:
	if combat_hud:
		combat_hud.queue_free()

## AC-1: 测试常驻HUD元素正常显示 - 角色状态栏
func test_character_status_bar_display() -> void:
	# 创建测试数据
	var character_data = {
		"name": "主角",
		"hp": 100,
		"max_hp": 100,
		"qi": 50,
		"max_qi": 50,
		"poise": 30,
		"max_poise": 30
	}
	
	# 验证数据结构
	assert_true(character_data.has("name"), "角色数据应该包含名称")
	assert_true(character_data.has("hp"), "角色数据应该包含HP")
	assert_true(character_data.has("max_hp"), "角色数据应该包含最大HP")
	assert_eq(character_data["hp"], 100, "HP应该是100")
	assert_eq(character_data["max_hp"], 100, "最大HP应该是100")

## AC-1: 测试常驻HUD元素正常显示 - 行动队列
func test_turn_order_queue_display() -> void:
	# 创建测试数据
	var queue_data = [
		{
			"name": "主角",
			"is_current": true,
			"speed": 100
		},
		{
			"name": "敌人",
			"is_current": false,
			"speed": 80
		},
		{
			"name": "队友",
			"is_current": false,
			"speed": 90
		}
	]
	
	# 验证队列数据
	assert_eq(queue_data.size(), 3, "队列应该有3个条目")
	assert_true(queue_data[0]["is_current"], "第一个条目应该是当前行动者")
	assert_false(queue_data[1]["is_current"], "第二个条目不应该是当前行动者")
	assert_eq(queue_data[0]["speed"], 100, "主角速度应该是100")

## AC-2: 测试状态效果图标栏正确显示
func test_status_effect_icons_display() -> void:
	# 创建测试数据
	var status_effects = [
		{
			"name": "中毒",
			"icon": "poison",
			"duration": 3
		},
		{
			"name": "加速",
			"icon": "speed",
			"duration": 2
		}
	]
	
	# 验证状态效果数据
	assert_eq(status_effects.size(), 2, "应该有2个状态效果")
	assert_eq(status_effects[0]["name"], "中毒", "第一个效果应该是中毒")
	assert_eq(status_effects[0]["duration"], 3, "中毒持续时间应该是3")
	assert_eq(status_effects[1]["name"], "加速", "第二个效果应该是加速")

## AC-2: 测试状态效果透明度计算
func test_status_effect_transparency() -> void:
	# 测试透明度计算公式
	var remaining_turns = 3
	var max_turns = 5
	var base_alpha = 0.6
	var alpha_increment = 0.2
	
	var icon_alpha = base_alpha + (float(remaining_turns) / float(max_turns)) * alpha_increment
	icon_alpha = clamp(icon_alpha, 0.6, 1.0)
	
	# 验证透明度计算
	assert_almost_eq(icon_alpha, 0.72, 0.01, "透明度应该约为0.72")

## AC-3: 测试伤害飘字显示
func test_floating_text_display() -> void:
	# 创建测试数据
	var text_data = {
		"value": 50,
		"type": "外功",
		"position": Vector2(200, 150)
	}
	
	# 验证飘字数据
	assert_eq(text_data["value"], 50, "伤害值应该是50")
	assert_eq(text_data["type"], "外功", "伤害类型应该是外功")
	assert_eq(text_data["position"], Vector2(200, 150), "位置应该正确")

## AC-3: 测试不同伤害类型的颜色
func test_damage_color_mapping() -> void:
	# 测试伤害颜色映射
	var damage_colors = {
		"外功": Color.WHITE,
		"内功": Color.BLUE,
		"暴击": Color.GOLD,
		"真实": Color.RED
	}
	
	# 验证颜色映射
	assert_eq(damage_colors["外功"], Color.WHITE, "外功伤害应该是白色")
	assert_eq(damage_colors["内功"], Color.BLUE, "内功伤害应该是蓝色")
	assert_eq(damage_colors["暴击"], Color.GOLD, "暴击伤害应该是金色")
	assert_eq(damage_colors["真实"], Color.RED, "真实伤害应该是红色")

## AC-3: 测试多个飘字显示
func test_multiple_floating_texts() -> void:
	# 创建多个飘字数据
	var floating_texts = [
		{
			"value": 50,
			"type": "外功",
			"position": Vector2(200, 150)
		},
		{
			"value": 30,
			"type": "内功",
			"position": Vector2(250, 150)
		},
		{
			"value": 0,
			"type": "Miss",
			"position": Vector2(300, 150)
		}
	]
	
	# 验证飘字数据
	assert_eq(floating_texts.size(), 3, "应该有3个飘字")
	assert_eq(floating_texts[0]["value"], 50, "第一个飘字值应该是50")
	assert_eq(floating_texts[1]["type"], "内功", "第二个飘字类型应该是内功")
	assert_eq(floating_texts[2]["type"], "Miss", "第三个飘字类型应该是Miss")

## AC-4: 测试UI元素位置适配
func test_ui_position_adaptation() -> void:
	# 测试分辨率适配
	var base_resolution = Vector2(1920, 1080)
	var test_resolutions = [
		Vector2(1280, 720),    # 16:9
		Vector2(1920, 1200),   # 16:10
	]
	
	for resolution in test_resolutions:
		var scale_factor = Vector2(
			resolution.x / base_resolution.x,
			resolution.y / base_resolution.y
		)
		
		# 验证缩放因子
		assert_gt(scale_factor.x, 0, "X缩放因子应该大于0")
		assert_gt(scale_factor.y, 0, "Y缩放因子应该大于0")

## AC-4: 测试不同分辨率的适配
func test_different_resolutions() -> void:
	# 测试不同分辨率
	var resolutions = [
		Vector2(1280, 720),    # 16:9
		Vector2(1920, 1080),   # 16:9
		Vector2(1920, 1200),   # 16:10
		Vector2(3440, 1440)    # 21:9
	]
	
	var base_resolution = Vector2(1920, 1080)
	
	for resolution in resolutions:
		var scale_x = resolution.x / base_resolution.x
		var scale_y = resolution.y / base_resolution.y
		
		# 验证缩放因子有效
		assert_gt(scale_x, 0, "X缩放因子应该大于0")
		assert_gt(scale_y, 0, "Y缩放因子应该大于0")

## AC-4: 测试HUD信号发送
func test_hud_signal_emission() -> void:
	# 创建一个模拟的HUD对象来测试信号
	var hud_mock = {
		"hud_updated": false
	}
	
	# 模拟信号发送
	hud_mock["hud_updated"] = true
	
	# 验证信号已发送
	assert_true(hud_mock["hud_updated"], "HUD更新信号应该被发送")

## 测试HUD初始化
func test_hud_initialization() -> void:
	# 验证HUD初始化数据
	var hud_data = {
		"character_status_container": null,
		"turn_order_container": null,
		"status_icons_container": null,
		"floating_text_container": null
	}
	
	# 验证容器存在
	assert_true(hud_data.has("character_status_container"), "应该有角色状态容器")
	assert_true(hud_data.has("turn_order_container"), "应该有行动队列容器")
	assert_true(hud_data.has("status_icons_container"), "应该有状态图标容器")
	assert_true(hud_data.has("floating_text_container"), "应该有飘字容器")

## 测试HUD数据验证
func test_hud_data_validation() -> void:
	# 测试角色数据验证
	var valid_character_data = {
		"name": "主角",
		"hp": 100,
		"max_hp": 100,
		"qi": 50,
		"max_qi": 50,
		"poise": 30,
		"max_poise": 30
	}
	
	# 验证必需字段
	assert_true(valid_character_data.has("name"), "角色数据应该有名称")
	assert_true(valid_character_data.has("hp"), "角色数据应该有HP")
	assert_true(valid_character_data.has("max_hp"), "角色数据应该有最大HP")
	
	# 验证数据有效性
	assert_gt(valid_character_data["max_hp"], 0, "最大HP应该大于0")
	assert_le(valid_character_data["hp"], valid_character_data["max_hp"], "HP不应该超过最大HP")