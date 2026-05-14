## test_martial_arts_system.gd
## 武学系统单元测试 (martial-arts-002/003)
## 验证武学获取、熟练度、装备、组合执行等功能

extends GutTest

var ma_system: Node

func before_each():
	var script = load("res://src/scripts/combat/martial_arts_system.gd")
	ma_system = script.new()
	add_child_autofree(ma_system)

func after_each():
	ma_system = null

## 测试：系统初始化
func test_system_init():
	assert_ne(ma_system, null, "武学系统应该成功创建")

## 测试：基础武学数据加载
func test_basic_martial_arts_loaded():
	assert_gt(ma_system.martial_arts_database.size(), 0, "应该有至少1个基础武学")
	assert_true(ma_system.martial_arts_database.has("sword_basic_01"), "应该有基础剑法")
	assert_true(ma_system.martial_arts_database.has("fist_basic_01"), "应该有基础拳法")

## 测试：获取武学数据
func test_get_martial_art_data():
	var data = ma_system.get_martial_art_data("sword_basic_01")
	assert_ne(data, null, "基础剑法数据应该存在")
	assert_eq(data.name, "基础剑法", "名称应该正确")

## 测试：获取不存在的武学数据
func test_get_nonexistent_martial_art_data():
	var data = ma_system.get_martial_art_data("nonexistent")
	assert_eq(data, null, "不存在的武学应该返回null")

## 测试：检查玩家武学 - 初始无武学
func test_player_has_no_martial_arts_initially():
	assert_false(ma_system.has_martial_art("sword_basic_01"), "初始时玩家不应拥有武学")

## 测试：获取玩家武学 - 不存在
func test_get_player_nonexistent_martial_art():
	var data = ma_system.get_player_martial_art("sword_basic_01")
	assert_eq(data, null, "不存在的玩家武学应该返回null")

## 测试：武学信息数据结构
func test_martial_art_info_structure():
	var info = MartialArtsSystem.MartialArtInfo.new(
		"test_ma", "测试武学", "描述", "华山", "黄阶", "Sword",
		100.0, 1.0, 2, "金", 0.5, 0.3, 0.8, 1.6, 10.0, 15.0, 2.0, 5
	)
	assert_eq(info.id, "test_ma", "ID应该正确")
	assert_eq(info.proficiency_level, 0, "初始熟练度应该为0")
	assert_eq(info.fragments_collected, 0, "初始残页应该为0")

## 测试：武学信息复制
func test_martial_art_info_duplicate():
	var original = MartialArtsSystem.MartialArtInfo.new(
		"dup_ma", "复制武学", "描述", "少林", "玄阶", "Fist",
		80.0, 1.2, 1, "无", 0.4, 0.2, 0.6, 1.2, 8.0, 12.0, 1.5, 3
	)
	original.proficiency_level = 5
	
	var copy = original.duplicate()
	
	assert_eq(copy.id, original.id, "复制的ID应该相同")
	assert_eq(copy.proficiency_level, original.proficiency_level, "复制的熟练度应该相同")
	assert_eq(copy.base_damage, original.base_damage, "复制的伤害应该相同")

## 测试：获取武学残页
func test_acquire_fragment():
	var result = ma_system.acquire_martial_art_fragment("sword_basic_01")
	assert_true(result, "获取残页应该成功")
	assert_eq(ma_system.player_fragments["sword_basic_01"], 1, "残页数量应该为1")

## 测试：获取不存在的武学残页
func test_acquire_nonexistent_fragment():
	var result = ma_system.acquire_martial_art_fragment("nonexistent_ma")
	assert_false(result, "不存在的武学残页获取应该失败")

## 测试：残页累积
func test_fragment_accumulation():
	ma_system.acquire_martial_art_fragment("sword_basic_01")
	ma_system.acquire_martial_art_fragment("sword_basic_01")
	
	assert_eq(ma_system.player_fragments["sword_basic_01"], 2, "残页数量应该为2")

## 测试：获取玩家武学列表
func test_get_player_martial_arts_list():
	var list = ma_system.get_player_martial_arts_list()
	assert_eq(list.size(), 0, "初始时玩家武学列表应该为空")

## 测试：获取残页统计
func test_get_player_fragments_summary():
	ma_system.acquire_martial_art_fragment("sword_basic_01")
	
	var summary = ma_system.get_player_fragments_summary()
	assert_true(summary.has("sword_basic_01"), "统计应该包含残页")
	assert_eq(summary["sword_basic_01"], 1, "残页数量应该为1")

## 测试：检查武学装备条件 - 等级不足
func test_can_equip_level_insufficient():
	# 首先添加武学到玩家武学
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	var result = ma_system.can_equip_martial_art("sword_basic_01", 0, "Sword")
	assert_false(result, "等级不足应该无法装备")

## 测试：检查武学装备条件 - 等级满足
func test_can_equip_level_sufficient():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	var result = ma_system.can_equip_martial_art("sword_basic_01", 5, "Sword")
	assert_true(result, "等级满足应该可以装备")

## 测试：装备武学到有效槽位
func test_equip_martial_art_valid_slot():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	watch_signals(ma_system)
	var result = ma_system.equip_martial_art("sword_basic_01", 0)
	assert_true(result, "装备应该成功")
	assert_signal_emitted(ma_system, "martial_art_equipped", "应该触发装备信号")

## 测试：装备武学到无效槽位
func test_equip_martial_art_invalid_slot():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	var result = ma_system.equip_martial_art("sword_basic_01", 5)
	assert_false(result, "无效槽位应该装备失败")

## 测试：装备未拥有的武学
func test_equip_unowned_martial_art():
	var result = ma_system.equip_martial_art("nonexistent", 0)
	assert_false(result, "未拥有的武学应该装备失败")

## 测试：获取装备的武学
func test_get_equipped_martial_art():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	ma_system.equip_martial_art("sword_basic_01", 0)
	
	var equipped = ma_system.get_equipped_martial_art(0)
	assert_ne(equipped, null, "槽位0应该有装备")
	assert_eq(equipped.name, "基础剑法", "装备的应该是基础剑法")

## 测试：获取空槽位的武学
func test_get_equipped_empty_slot():
	var equipped = ma_system.get_equipped_martial_art(2)
	assert_eq(equipped, null, "空槽位应该返回null")

## 测试：获取无效槽位的武学
func test_get_equipped_invalid_slot():
	var equipped = ma_system.get_equipped_martial_art(-1)
	assert_eq(equipped, null, "无效槽位应该返回null")

## 测试：熟练度增加
func test_increase_proficiency():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	watch_signals(ma_system)
	var gain = ma_system.increase_proficiency("sword_basic_01", 10, 0.0, 1.0)
	
	assert_gt(gain, 0.0, "熟练度增加应该大于0")
	assert_signal_emitted(ma_system, "martial_art_proficiency_changed", "应该触发熟练度变化信号")

## 测试：熟练度增加 - 未拥有的武学
func test_increase_proficiency_unowned():
	var gain = ma_system.increase_proficiency("nonexistent", 10, 0.0, 1.0)
	assert_eq(gain, 0.0, "未拥有的武学熟练度增加应该为0")

## 测试：熟练度上限
func test_proficiency_cap():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	# 多次增加熟练度直到超过上限
	for i in range(20):
		ma_system.increase_proficiency("sword_basic_01", 10, 0.0, 1.0)
	
	assert_lte(sword_data.proficiency_level, 15, "熟练度不应超过上限15")

## 测试：熟练度幸运加成
func test_proficiency_luck_bonus():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	var gain_no_luck = ma_system.increase_proficiency("sword_basic_01", 10, 0.0, 1.0)
	sword_data.proficiency_level = 0
	
	var gain_with_luck = ma_system.increase_proficiency("sword_basic_01", 10, 0.5, 1.0)
	
	assert_gt(gain_with_luck, gain_no_luck, "幸运加成应该增加熟练度获取")

## 测试：武学组合执行 - 成功
func test_execute_combo_success():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	var fist_data = ma_system.martial_arts_database["fist_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	ma_system.player_martial_arts["fist_basic_01"] = fist_data
	
	var combo_seq = ["sword_basic_01", "fist_basic_01"]
	var result = ma_system.execute_combo(combo_seq)
	
	assert_true(result.success, "组合执行应该成功")
	assert_gt(result.damage_multiplier, 1.0, "伤害倍率应该大于1.0")
	assert_ne(result.combo_name, "", "组合名称应该不为空")

## 测试：武学组合执行 - 少于2个武学
func test_execute_combo_too_few():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	
	var combo_seq = ["sword_basic_01"]
	var result = ma_system.execute_combo(combo_seq)
	
	assert_false(result.success, "单个武学组合应该失败")

## 测试：武学组合执行 - 缺少武学
func test_execute_combo_missing_martial_art():
	var combo_seq = ["sword_basic_01", "nonexistent"]
	var result = ma_system.execute_combo(combo_seq)
	
	assert_false(result.success, "缺少的武学应该导致组合失败")

## 测试：伤害计算
func test_calculate_damage():
	var sword_data = ma_system.martial_arts_database["sword_basic_01"].duplicate()
	ma_system.player_martial_arts["sword_basic_01"] = sword_data
	sword_data.proficiency_level = 5
	
	var base_stats = {"strength": 10}
	var damage = ma_system.calculate_damage("sword_basic_01", base_stats)
	
	assert_gt(damage, 0.0, "伤害应该大于0")

## 测试：伤害计算 - 未拥有的武学
func test_calculate_damage_unowned():
	var damage = ma_system.calculate_damage("nonexistent", {})
	assert_eq(damage, 0.0, "未拥有的武学伤害应该为0")

## 测试：4个装备槽位初始化
func test_four_equipment_slots():
	assert_eq(ma_system.equipped_martial_arts.size(), 4, "应该有4个装备槽位")

## 测试：常量值
func test_constants():
	assert_eq(MartialArtsSystem.FRAGMENT_NEEDED_FOR_SYNTHESIS, 3, "合成所需残页数应该为3")
	assert_eq(MartialArtsSystem.MAX_EQUIPPED_MARTIAL_ARTS, 4, "最大装备数应该为4")
	assert_eq(MartialArtsSystem.MAX_PROFICIENCY_LEVEL, 10, "最大熟练度等级应该为10")
