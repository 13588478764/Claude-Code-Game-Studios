## test_martial_arts_combo_system.gd
## 武学连招系统单元测试
## 验证协同效果检测、内力回流、连携槽管理、连招状态追踪等功能

extends GutTest

var combo_system: MartialArtsComboSystem

func before_each():
	combo_system = MartialArtsComboSystem.new()
	add_child_autofree(combo_system)

func after_each():
	combo_system = null

## 测试：连招系统初始化
func test_combo_system_init():
	assert_ne(combo_system, null, "连招系统应该成功创建")
	assert_eq(combo_system.combo_state.current_tags, [], "初始current_tags应该为空")
	assert_eq(combo_system.combo_state.last_applied_tags, [], "初始last_applied_tags应该为空")
	assert_eq(combo_system.combo_state.link_gauge, 0, "初始连携槽应该为0")
	assert_eq(combo_system.combo_state.combo_timer, 0.0, "初始计时器应该为0")

## 测试：连携槽上限常量
func test_max_link_gauge_constant():
	assert_eq(combo_system.MAX_LINK_GAUGE, 100, "最大连携槽应该为100")
	assert_eq(combo_system.COMBO_WINDOW_TIME, 3.0, "连招窗口应该为3秒")
	assert_eq(combo_system.LINK_GAUGE_THRESHOLD, 30, "连携触发阈值应该为30")

## 测试：协同效果表存在
func test_synergy_table_exists():
	assert_gt(combo_system.synergy_table.size(), 0, "协同效果表应该有数据")
	assert_true(combo_system.synergy_table.has("破防_刚"), "应该有破防_刚协同")
	assert_true(combo_system.synergy_table.has("湿_雷"), "应该有湿_雷协同")
	assert_true(combo_system.synergy_table.has("浮空_坠击"), "应该有浮空_坠击协同")
	assert_true(combo_system.synergy_table.has("燃烧_水"), "应该有燃烧_水协同")

## 测试：连招等级系数
func test_combo_tier_multipliers():
	assert_eq(combo_system.combo_tier_multipliers["basic"], 1.0, "普通连招倍率应该为1.0")
	assert_eq(combo_system.combo_tier_multipliers["advanced"], 1.5, "高阶连招倍率应该为1.5")
	assert_eq(combo_system.combo_tier_multipliers["ultimate"], 2.0, "终极连招倍率应该为2.0")

## 测试：检查协同效果 - 找到协同
func test_check_synergy_found():
	# 设置上次标签
	combo_system.combo_state.last_applied_tags = ["破防"]
	
	var result = combo_system.check_synergy(["刚"])
	
	assert_true(result.found, "应该找到协同效果")
	assert_eq(result.name, "粉碎打击", "协同名称应该是粉碎打击")
	assert_eq(result.multiplier, 2.0, "伤害倍率应该为2.0")
	assert_eq(result.tier, "ultimate", "连招等级应该为ultimate")

## 测试：检查协同效果 - 未找到协同
func test_check_synergy_not_found():
	combo_system.combo_state.last_applied_tags = ["普通标签"]
	
	var result = combo_system.check_synergy(["无关标签"])
	
	assert_false(result.found, "不应该找到协同效果")
	assert_eq(result.multiplier, 1.0, "伤害倍率应该为1.0")

## 测试：检查协同效果 - 反向匹配
func test_check_synergy_reverse_match():
	# 协同表中有"湿_雷"，测试以"雷"+"湿"反向匹配
	combo_system.combo_state.last_applied_tags = ["雷"]
	
	var result = combo_system.check_synergy(["湿"])
	
	assert_true(result.found, "应该反向匹配到协同效果")
	assert_eq(result.name, "感电爆发", "协同名称应该正确")

## 测试：计算连招等级 - ultimate
func test_calculate_combo_tier_ultimate():
	var tier = combo_system.calculate_combo_tier("破防_刚")
	assert_eq(tier, "ultimate", "damage_multiplier>=2.0应该为ultimate")

## 测试：计算连招等级 - advanced
func test_calculate_combo_tier_advanced():
	# 注意：之前用 "浮空_坠击" 不对，它的 damage_multiplier=2.5，会判为 ultimate（>=2.0）。
	# 改用 "湿_雷"（multiplier=1.8）才正好落在 advanced 区间（1.6 <= x < 2.0）。
	var tier = combo_system.calculate_combo_tier("湿_雷")
	assert_eq(tier, "advanced", "damage_multiplier>=1.6应该为advanced")

## 测试：计算连招等级 - basic
func test_calculate_combo_tier_basic():
	var tier = combo_system.calculate_combo_tier("燃烧_水")
	assert_eq(tier, "advanced", "damage_multiplier=1.6应该为advanced")

## 测试：计算连携槽增加 - basic
func test_link_gauge_basic():
	var increase = combo_system.calculate_link_gauge_increase("basic")
	assert_eq(increase, 20, "基础连携槽增加应该为20")

## 测试：计算连携槽增加 - advanced
func test_link_gauge_advanced():
	var increase = combo_system.calculate_link_gauge_increase("advanced")
	assert_eq(increase, 30, "高阶连携槽增加应该为30 (20*1.5)")

## 测试：计算连携槽增加 - ultimate
func test_link_gauge_ultimate():
	var increase = combo_system.calculate_link_gauge_increase("ultimate")
	assert_eq(increase, 40, "终极连携槽增加应该为40 (20*2.0)")

## 测试：连携槽可用性检查
func test_is_link_available():
	combo_system.combo_state.link_gauge = 29
	assert_false(combo_system.is_link_available(), "29点连携槽不应该可用")
	
	combo_system.combo_state.link_gauge = 30
	assert_true(combo_system.is_link_available(), "30点连携槽应该可用")
	
	combo_system.combo_state.link_gauge = 50
	assert_true(combo_system.is_link_available(), "50点连携槽应该可用")

## 测试：消耗连携槽 - 成功
func test_consume_link_gauge_success():
	combo_system.combo_state.link_gauge = 50
	
	var result = combo_system.consume_link_gauge(20)
	
	assert_true(result, "消耗应该成功")
	assert_eq(combo_system.combo_state.link_gauge, 30, "连携槽应该减少20")

## 测试：消耗连携槽 - 不足
func test_consume_link_gauge_insufficient():
	combo_system.combo_state.link_gauge = 10
	
	var result = combo_system.consume_link_gauge(20)
	
	assert_false(result, "连携槽不足应该消耗失败")
	assert_eq(combo_system.combo_state.link_gauge, 10, "连携槽不应该改变")

## 测试：更新连招状态
func test_update_combo_state():
	combo_system.combo_state.current_tags = ["旧标签"]
	
	combo_system.update_combo_state(["新标签1", "新标签2"])
	
	assert_eq(combo_system.combo_state.last_applied_tags, ["旧标签"], "last_applied_tags应该更新为旧标签")
	assert_eq(combo_system.combo_state.current_tags, ["新标签1", "新标签2"], "current_tags应该更新为新标签")
	assert_eq(combo_system.combo_state.combo_timer, combo_system.COMBO_WINDOW_TIME, "计时器应该重置为窗口时间")
	assert_eq(combo_system.combo_state.current_combo_chain.size(), 1, "连招链应该新增一条记录")

## 测试：连招链长度限制
func test_combo_chain_length_limit():
	# 添加5条记录
	for i in range(5):
		combo_system.update_combo_state(["标签%d" % i])
	
	assert_eq(combo_system.combo_state.current_combo_chain.size(), 5, "连招链应该为5条")
	
	# 再添加1条
	combo_system.update_combo_state(["标签6"])
	
	assert_eq(combo_system.combo_state.current_combo_chain.size(), 5, "连招链不应超过5条 (最大限制)")

## 测试：重置连招状态
func test_reset_combo_state():
	combo_system.combo_state.current_tags = ["标签"]
	combo_system.combo_state.last_applied_tags = ["上次的"]
	combo_system.combo_state.last_status_effects = ["效果"]
	combo_system.combo_state.combo_timer = 2.0
	combo_system.combo_state.current_combo_chain = [{"tags": ["x"]}]
	
	combo_system.reset_combo_state()
	
	assert_eq(combo_system.combo_state.current_tags.size(), 0, "current_tags应该被清空")
	assert_eq(combo_system.combo_state.last_applied_tags.size(), 0, "last_applied_tags应该被清空")
	assert_eq(combo_system.combo_state.combo_timer, 0.0, "计时器应该重置为0")
	assert_eq(combo_system.combo_state.current_combo_chain.size(), 0, "连招链应该被清空")

## 测试：获取当前连招状态
func test_get_current_combo_state():
	combo_system.combo_state.current_tags = ["标签A"]
	combo_system.combo_state.last_applied_tags = ["标签B"]
	combo_system.combo_state.link_gauge = 50
	combo_system.combo_state.current_combo_chain = [{"tags": ["x"]}, {"tags": ["y"]}]
	
	var state = combo_system.get_current_combo_state()
	
	assert_eq(state.current_tags, ["标签A"], "current_tags应该正确")
	assert_eq(state.last_applied_tags, ["标签B"], "last_applied_tags应该正确")
	assert_eq(state.link_gauge, 50, "link_gauge应该正确")
	assert_eq(state.max_link_gauge, 100, "max_link_gauge应该为100")
	assert_eq(state.combo_chain_length, 2, "连招链长度应该为2")

## 测试：处理技能释放 - 无协同
func test_process_skill_usage_no_synergy():
	var skill_data = {"tags": [], "internal_energy_cost": 20.0}
	combo_system.combo_state.last_applied_tags = []
	
	var result = combo_system.process_skill_usage(skill_data)
	
	assert_false(result.synergy_triggered, "不应该触发协同")
	assert_eq(result.damage_multiplier, 1.0, "伤害倍率应该为1.0")
	assert_gt(result.link_gauge_change, 0, "连携槽应该增加")

## 测试：处理技能释放 - 触发协同
func test_process_skill_usage_with_synergy():
	var skill_data = {"tags": ["刚"], "internal_energy_cost": 20.0}
	combo_system.combo_state.last_applied_tags = ["破防"]
	
	var result = combo_system.process_skill_usage(skill_data)
	
	assert_true(result.synergy_triggered, "应该触发协同")
	assert_eq(result.synergy_name, "粉碎打击", "协同名称应该正确")
	assert_eq(result.damage_multiplier, 2.0, "伤害倍率应该为2.0")
	assert_true(result.internal_energy_refund > 0, "内力回流应该大于0")

## 测试：可用协同效果查询
func test_get_available_synergies():
	combo_system.combo_state.last_applied_tags = ["破防"]
	
	var available = combo_system.get_available_synergies(["刚"])
	
	assert_gt(available.size(), 0, "应该至少有一个可用协同")
	assert_eq(available[0].name, "粉碎打击", "协同名称应该正确")
	assert_eq(available[0].damage_multiplier, 2.0, "伤害倍率应该正确")

## 测试：连招计时器超时重置
func test_combo_timer_timeout():
	combo_system.combo_state.last_applied_tags = ["测试标签"]
	combo_system.combo_state.combo_timer = 0.5
	
	# 模拟超过窗口时间的流逝
	combo_system._process(0.6)
	
	assert_eq(combo_system.combo_state.combo_timer, 0.0, "计时器应该归零")
	assert_eq(combo_system.combo_state.last_applied_tags.size(), 0, "上次标签应该被清空")

## 测试：连携槽上限封顶
func test_link_gauge_cap():
	combo_system.combo_state.link_gauge = 90
	
	# 触发一次连携增加40点
	var result = combo_system.calculate_link_gauge_increase("ultimate")
	combo_system.combo_state.link_gauge = clamp(combo_system.combo_state.link_gauge + result, 0, combo_system.MAX_LINK_GAUGE)
	
	assert_eq(combo_system.combo_state.link_gauge, 100, "连携槽应该封顶在100")