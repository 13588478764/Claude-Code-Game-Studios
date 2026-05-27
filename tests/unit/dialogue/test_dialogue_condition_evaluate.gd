# 对话条件判定 - 单元测试 (polish-fixlist #7)
#
# 验证 DialogueData 4 个条件子类的 evaluate() 不再无条件 return true:
# - FlagCondition: 本地 static Dictionary, 可完整测试
# - RealmLevelCondition: 无 CharacterSystem Autoload 时返回 false
# - QuestStatusCondition: 无 QuestSystem Autoload 时返回 false
# - ItemOwnedCondition: 无 InventorySystem Autoload 时返回 false

extends GutTest


# ============================================================================
# FlagCondition (完整覆盖 — 不依赖 Autoload)
# ============================================================================

func before_each():
	DialogueData._game_flags.clear()


func test_flag_condition_unset_flag_expects_true_returns_false():
	var cond = DialogueData.FlagCondition.new("quest_accepted", true)
	assert_false(cond.evaluate(), "未设置的 flag 期望 true 时应返回 false")


func test_flag_condition_set_flag_expects_true_returns_true():
	DialogueData.set_flag("quest_accepted", true)
	var cond = DialogueData.FlagCondition.new("quest_accepted", true)
	assert_true(cond.evaluate(), "已设置 flag=true 期望 true 时应返回 true")


func test_flag_condition_set_flag_expects_false_returns_false():
	DialogueData.set_flag("quest_accepted", true)
	var cond = DialogueData.FlagCondition.new("quest_accepted", false)
	assert_false(cond.evaluate(), "flag=true 但期望 false 时应返回 false")


func test_flag_condition_unset_flag_expects_false_returns_true():
	var cond = DialogueData.FlagCondition.new("never_set", false)
	assert_true(cond.evaluate(), "未设置的 flag (默认 false) 期望 false 时应返回 true")


func test_set_flag_effect_writes_flag():
	var effect = DialogueData.SetFlagEffect.new("branch_chosen", true)
	effect.execute()
	assert_true(DialogueData.get_flag("branch_chosen"), "SetFlagEffect 应写入 flag")


func test_flag_condition_after_effect_roundtrip():
	var effect = DialogueData.SetFlagEffect.new("met_npc", true)
	effect.execute()
	var cond = DialogueData.FlagCondition.new("met_npc", true)
	assert_true(cond.evaluate(), "Effect 写入后 Condition 应能读到")


# ============================================================================
# RealmLevelCondition (无 Autoload → 安全返回 false)
# ============================================================================

func test_realm_condition_no_autoload_returns_false():
	var cond = DialogueData.RealmLevelCondition.new(3)
	assert_false(cond.evaluate(), "无 CharacterSystem Autoload 时应返回 false (不再 return true)")


# ============================================================================
# QuestStatusCondition (无 Autoload → 安全返回 false)
# ============================================================================

func test_quest_condition_no_autoload_returns_false():
	var cond = DialogueData.QuestStatusCondition.new("main_quest_01", "completed")
	assert_false(cond.evaluate(), "无 QuestSystem Autoload 时应返回 false")


# ============================================================================
# ItemOwnedCondition (无 Autoload → 安全返回 false)
# ============================================================================

func test_item_condition_no_autoload_returns_false():
	var cond = DialogueData.ItemOwnedCondition.new("healing_pill", 1)
	assert_false(cond.evaluate(), "无 InventorySystem Autoload 时应返回 false")
