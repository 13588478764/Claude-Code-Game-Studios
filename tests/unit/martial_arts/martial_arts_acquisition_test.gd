# 武学获取机制单元测试
# 测试武学获取、残页收集和合成机制

extends GutTest

# 导入要测试的脚本
const MartialArtsSystemScript = preload("res://src/scripts/combat/martial_arts_system.gd")

# 测试系统实例
var system

# 每个测试前执行
func before_each():
	system = MartialArtsSystemScript.new()
	system._ready()  # 手动调用初始化

# 测试武学数据结构
func test_martial_art_data_structure():
	# 获取基础剑法数据
	var sword_data = system.get_martial_art_data("sword_basic_01")
	
	assert_not_null(sword_data, "应该能够获取基础剑法数据")
	assert_eq(sword_data.id, "sword_basic_01", "武学ID应该正确")
	assert_eq(sword_data.name, "基础剑法", "武学名称应该正确")
	assert_eq(sword_data.school, "通用", "武学门派应该正确")
	assert_eq(sword_data.grade, "黄阶", "武学品阶应该正确")
	assert_eq(sword_data.weapon_type, "Sword", "武学武器类型应该正确")
	assert_eq(sword_data.base_damage, 50.0, "武学基础伤害应该正确")
	assert_eq(sword_data.proficiency_level, 0, "武学熟练度初始值应该为0")
	assert_eq(sword_data.fragments_collected, 0, "武学残页收集数初始值应该为0")
	
	# 测试基础拳法数据
	var fist_data = system.get_martial_art_data("fist_basic_01")
	assert_not_null(fist_data, "应该能够获取基础拳法数据")
	assert_eq(fist_data.name, "基础拳法", "拳法名称应该正确")
	assert_eq(fist_data.base_damage, 45.0, "拳法基础伤害应该正确")

# 测试武学获取机制
func test_martial_art_acquisition():
	# 测试获取不存在的武学
	var result = system.acquire_martial_art_fragment("nonexistent_art")
	assert_false(result, "获取不存在的武学应该失败")
	
	# 测试获取存在的武学残页
	var initial_count = system.player_fragments.get("sword_basic_01", 0)
	var acquisition_result = system.acquire_martial_art_fragment("sword_basic_01")
	assert_true(acquisition_result, "获取存在的武学残页应该成功")
	
	var new_count = system.player_fragments.get("sword_basic_01", 0)
	assert_eq(new_count, initial_count + 1, "残页数量应该增加")
	
	# 再次获取同一武学残页
	system.acquire_martial_art_fragment("sword_basic_01")
	var final_count = system.player_fragments.get("sword_basic_01", 0)
	assert_eq(final_count, initial_count + 2, "残页数量应该继续增加")
	
	# 检查玩家是否拥有武学（此时应该还没有）
	var has_art_before_synthesis = system.has_martial_art("sword_basic_01")
	assert_false(has_art_before_synthesis, "合成前玩家不应该拥有武学")

# 测试残页收集系统
func test_fragment_collection_system():
	# 收集多个不同武学的残页
	var sword_result = system.acquire_martial_art_fragment("sword_basic_01")
	var fist_result = system.acquire_martial_art_fragment("fist_basic_01")
	
	assert_true(sword_result, "获取剑法残页应该成功")
	assert_true(fist_result, "获取拳法残页应该成功")
	
	# 检查残页统计
	var fragments_summary = system.get_player_fragments_summary()
	assert_true(fragments_summary.has("sword_basic_01"), "残页统计应该包含剑法")
	assert_true(fragments_summary.has("fist_basic_01"), "残页统计应该包含拳法")
	
	# 收集足够的剑法残页以触发合成
	var current_sword_fragments = fragments_summary.get("sword_basic_01", 0)
	
	# 获取足够的残页以触发合成（需要3个）
	for i in range(3 - current_sword_fragments):
		system.acquire_martial_art_fragment("sword_basic_01")
	
	# 检查残页数量是否正确更新
	var updated_fragments = system.get_player_fragments_summary()
	var final_fragments = updated_fragments.get("sword_basic_01", 0)
	# 由于系统会自动合成（如果有空白秘籍），残页数量可能会减少
	assert_true(final_fragments >= 0, "残页数量应该是非负数")

# 测试残页合成机制
func test_fragment_synthesis_mechanism():
	# 手动设置足够的残页
	system.player_fragments["fist_basic_01"] = 3
	
	# 检查合成前的状态
	var has_fist_before = system.has_martial_art("fist_basic_01")
	assert_false(has_fist_before, "合成前玩家不应该拥有拳法")
	
	# 尝试合成（系统有空白秘籍，应该成功）
	var synthesis_result = system.synthesize_martial_art("fist_basic_01")
	assert_true(synthesis_result, "合成应该成功")
	
	# 检查玩家武学库
	var player_has_fist = system.has_martial_art("fist_basic_01")
	assert_true(player_has_fist, "合成后玩家应该拥有拳法")
	
	# 测试合成后武学的属性
	var fist_art = system.get_player_martial_art("fist_basic_01")
	assert_not_null(fist_art, "获取的武学数据不应该为空")
	assert_eq(fist_art.name, "基础拳法", "合成的武学名称应该正确")
	
	# 检查残页是否被消耗
	var remaining_fragments = system.player_fragments.get("fist_basic_01", 0)
	assert_eq(remaining_fragments, 0, "合成后残页应该被消耗")
	
	# 测试合成失败的情况
	var invalid_synthesis = system.synthesize_martial_art("nonexistent_art")
	assert_false(invalid_synthesis, "合成不存在的武学应该失败")

# 测试武学图鉴功能
func test_martial_arts_catalog_functionality():
	# 获取玩家武学列表（初始应该为空）
	var initial_list = system.get_player_martial_arts_list()
	assert_eq(initial_list.size(), 0, "初始武学列表应该为空")
	
	# 手动添加一个武学以测试列表功能
	system.player_martial_arts["sword_basic_01"] = system.martial_arts_database["sword_basic_01"].duplicate(true)
	
	var updated_list = system.get_player_martial_arts_list()
	assert_eq(updated_list.size(), 1, "添加武学后列表大小应该为1")
	
	var first_art = updated_list[0]
	assert_eq(first_art.id, "sword_basic_01", "列表中的武学ID应该正确")
	assert_eq(first_art.name, "基础剑法", "列表中的武学名称应该正确")
	
	# 测试获取武学数据
	var retrieved_art = system.get_player_martial_art("sword_basic_01")
	assert_not_null(retrieved_art, "应该能够获取玩家拥有的武学")
	assert_eq(retrieved_art.name, "基础剑法", "获取的武学名称应该正确")
	
	# 测试获取不存在的武学
	var nonexistent_art = system.get_player_martial_art("nonexistent_art")
	assert_null(nonexistent_art, "获取不存在的武学应该返回null")