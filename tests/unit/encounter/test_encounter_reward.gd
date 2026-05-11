## 奇遇奖励系统单元测试
## 验证奇遇奖励类型、奖励发放机制、福缘影响和奖励冲突处理
extends GutTest

var _EncounterRewardManagerScript = load("res://src/scripts/encounter/encounter_reward_manager.gd")  # 用脚本资源代替 autoload 实例，避免污染单例

var reward_manager

func before_each():
	reward_manager = _EncounterRewardManagerScript.new()
	add_child_autofree(reward_manager)

func after_each():
	pass

## 测试江湖传闻奖励类型正确
func test_jianghu_rumor_reward_types():
	var rewards = reward_manager.distribute_reward("JiangHuRumor", 0.0)
	assert_true(rewards.size() > 0, "江湖传闻应至少返回一种奖励")
	for reward in rewards:
		assert_true(reward.has("type"), "每个奖励应有type字段")

## 测试天材地宝奖励类型正确
func test_tiancai_dibao_reward_types():
	var rewards = reward_manager.distribute_reward("TianCaiDiBao", 0.0)
	assert_true(rewards.size() > 0, "天材地宝应至少返回一种奖励")
	var has_pill = false
	for reward in rewards:
		if reward.type in ["breakthrough_pill", "reset_pill", "rare_materials"]:
			has_pill = true
	assert_true(has_pill, "天材地宝应包含丹药或稀有材料")

## 测试高人指点奖励类型正确
func test_gaoren_zhidian_reward_types():
	var rewards = reward_manager.distribute_reward("GaoRenZhiDian", 0.0)
	assert_true(rewards.size() > 0, "高人指点应至少返回一种奖励")
	var has_attr_or_talent = false
	for reward in rewards:
		if reward.type in ["attribute_point", "talent_point", "martial_art_exp"]:
			has_attr_or_talent = true
	assert_true(has_attr_or_talent, "高人指点应包含属性点、天赋点或武学经验")

## 测试失传秘籍奖励类型正确
func test_shichuan_miji_reward_types():
	var rewards = reward_manager.distribute_reward("ShiChuanMiJi", 0.0)
	assert_true(rewards.size() > 0, "失传秘籍应至少返回一种奖励")
	var has_martial_or_exp = false
	for reward in rewards:
		if reward.type in ["martial_art_fragment", "full_martial_art", "exp"]:
			has_martial_or_exp = true
	assert_true(has_martial_or_exp, "失传秘籍应包含武学残页或经验值")

## 测试秘境挑战奖励类型正确
func test_mijing_challenge_reward_types():
	var rewards = reward_manager.distribute_reward("MiJingChallenge", 0.0)
	assert_true(rewards.size() > 0, "秘境挑战应至少返回一种奖励")
	var has_equipment_or_exp = false
	for reward in rewards:
		if reward.type in ["purple_equipment", "exp", "legendary_fragment"]:
			has_equipment_or_exp = true
	assert_true(has_equipment_or_exp, "秘境挑战应包含紫色装备或经验值")

## 测试未知奇遇类型返回空奖励
func test_unknown_encounter_type_returns_empty():
	var rewards = reward_manager.distribute_reward("UnknownType", 0.0)
	assert_true(rewards.size() == 0, "未知奇遇类型应返回空奖励")

## 测试高福缘可能触发双倍银两奖励
func test_high_luck_can_double_silver():
	var silver_doubled = false
	for i in range(100):
		var rewards = reward_manager.generate_reward_package("JiangHuRumor", 150.0)
		for reward in rewards:
			if reward.type == "silver" and reward.amount > 500:
				silver_doubled = true
				break
		if silver_doubled:
			break
	assert_true(silver_doubled, "高福缘(150)在多次尝试中应至少有一次双倍银两")

## 测试奖励数量在配置范围内
func test_reward_amounts_within_config_range():
	var rewards = reward_manager.distribute_reward("JiangHuRumor", 0.0)
	for reward in rewards:
		if reward.type == "silver":
			assert_true(reward.amount >= 200 and reward.amount <= 500, "银两奖励应在200-500范围内")

## 测试奖励冲突处理返回处理后的奖励
func test_reward_conflict_handling_returns_processed_rewards():
	var rewards = [{"type": "material", "amount": 5}]
	var processed = reward_manager.handle_reward_conflicts(rewards)
	assert_true(processed.size() > 0, "冲突处理后应返回至少一个奖励")
	assert_true(processed[0].has("type"), "处理后的奖励应有type字段")

## 测试可堆叠物品类型判断正确
func test_stackable_item_type_detection():
	assert_true(reward_manager.is_stackable_item("silver"), "银两应为可堆叠物品")
	assert_true(reward_manager.is_stackable_item("material"), "材料应为可堆叠物品")
	assert_false(reward_manager.is_stackable_item("purple_equipment"), "紫色装备应为不可堆叠物品")

## 测试替代奖励转换返回银两
func test_alternative_reward_conversion():
	var original = {"type": "purple_equipment", "amount": 1}
	var alternative = reward_manager.convert_to_alternative_reward(original)
	assert_eq(alternative.type, "silver", "替代奖励应为银两")
	assert_eq(alternative.amount, 10, "替代奖励数量应为原数量x10")
