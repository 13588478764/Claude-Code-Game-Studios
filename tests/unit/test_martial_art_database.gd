extends GutTest

## 功法数据库单元测试
## 测试功法数据的加载、查询和验证功能

var database: MartialArtDatabase

func before_each():
	# 创建数据库实例
	database = MartialArtDatabase.new()
	add_child_autofree(database)
	# 等待数据库加载完成
	await get_tree().process_frame

func after_each():
	database = null

## 测试：数据库是否成功加载
func test_database_loads_successfully():
	assert_true(database.is_loaded(), "数据库应该成功加载")
	assert_gt(database.get_all_martial_art_ids().size(), 0, "应该至少加载了一些功法")

## 测试：验证加载的功法数量
func test_correct_number_of_martial_arts_loaded():
	var all_ids = database.get_all_martial_art_ids()
	assert_eq(all_ids.size(), 13, "应该加载了13个功法")

## 测试：验证通用功法加载
func test_generic_martial_arts_loaded():
	assert_true(database.has_martial_art("generic_basic_sword"), "应该有基础剑法")
	assert_true(database.has_martial_art("generic_basic_fist"), "应该有基础拳法")
	assert_true(database.has_martial_art("generic_qinggong"), "应该有轻功")

## 测试：验证天剑盟功法加载
func test_tianjian_martial_arts_loaded():
	assert_true(database.has_martial_art("tianjian_yujian"), "应该有御剑术")
	assert_true(database.has_martial_art("tianjian_jianguang"), "应该有剑气纵横")
	assert_true(database.has_martial_art("tianjian_nine_forms"), "应该有天剑九式")

## 测试：验证少林寺功法加载
func test_shaolin_martial_arts_loaded():
	assert_true(database.has_martial_art("shaolin_jingang"), "应该有金刚不坏体")
	assert_true(database.has_martial_art("shaolin_yijin"), "应该有易筋经")

## 测试：验证武当派功法加载
func test_wudang_martial_arts_loaded():
	assert_true(database.has_martial_art("wudang_liangyi"), "应该有两仪剑法")
	assert_true(database.has_martial_art("wudang_taiji"), "应该有太极玄功")

## 测试：验证丐帮功法加载
func test_gaibang_martial_arts_loaded():
	assert_true(database.has_martial_art("gaibang_dagou"), "应该有打狗棒法")
	assert_true(database.has_martial_art("gaibang_xianglong"), "应该有降龙十八掌")

## 测试：获取功法数据
func test_get_martial_art_data():
	var basic_sword = database.get_martial_art("generic_basic_sword")
	assert_not_null(basic_sword, "应该能获取基础剑法数据")
	assert_eq(basic_sword.name, "基础剑法", "功法名称应该正确")
	assert_eq(basic_sword.id, "generic_basic_sword", "功法ID应该正确")

## 测试：验证功法属性
func test_martial_art_properties():
	var basic_sword = database.get_martial_art("generic_basic_sword")
	assert_eq(basic_sword.unlock_level, 1, "基础剑法解锁等级应该是1")
	assert_eq(basic_sword.grade, MartialArtData.GradeType.COMMON, "基础剑法品阶应该是COMMON")
	assert_eq(basic_sword.martial_art_type, MartialArtData.MartialArtType.ATTACK, "基础剑法类型应该是ATTACK")
	assert_eq(basic_sword.weapon_type, MartialArtData.WeaponType.SWORD, "基础剑法武器类型应该是SWORD")

## 测试：按类型查询功法
func test_query_by_type():
	var attack_arts = database.get_martial_arts_by_type(MartialArtData.MartialArtType.ATTACK)
	assert_gt(attack_arts.size(), 0, "应该有攻击型功法")
	
	var movement_arts = database.get_martial_arts_by_type(MartialArtData.MartialArtType.MOVEMENT)
	assert_eq(movement_arts.size(), 1, "应该有1个移动型功法")
	assert_eq(movement_arts[0].id, "generic_qinggong", "移动型功法应该是轻功")

## 测试：按品阶查询功法
func test_query_by_grade():
	var common_arts = database.get_martial_arts_by_grade(MartialArtData.GradeType.COMMON)
	assert_eq(common_arts.size(), 3, "应该有3个普通品阶功法")
	
	var legendary_arts = database.get_martial_arts_by_grade(MartialArtData.GradeType.LEGENDARY)
	assert_eq(legendary_arts.size(), 3, "应该有3个传说品阶功法")

## 测试：按门派查询功法
func test_query_by_school():
	var shaolin_arts = database.get_martial_arts_by_school(MartialArtData.SchoolType.SHAOLIN)
	assert_eq(shaolin_arts.size(), 2, "少林寺应该有2个功法")
	
	var wudang_arts = database.get_martial_arts_by_school(MartialArtData.SchoolType.WUDANG)
	assert_eq(wudang_arts.size(), 2, "武当派应该有2个功法")

## 测试：按武器类型查询功法
func test_query_by_weapon():
	var sword_arts = database.get_martial_arts_by_weapon(MartialArtData.WeaponType.SWORD)
	assert_gt(sword_arts.size(), 0, "应该有剑类功法")
	
	var fist_arts = database.get_martial_arts_by_weapon(MartialArtData.WeaponType.FIST)
	assert_gt(fist_arts.size(), 0, "应该有拳掌类功法")

## 测试：按解锁等级查询功法
func test_query_by_unlock_level():
	var level_1_arts = database.get_martial_arts_by_unlock_level(1)
	assert_eq(level_1_arts.size(), 2, "等级1应该能解锁2个功法")
	
	var level_50_arts = database.get_martial_arts_by_unlock_level(50)
	assert_gt(level_50_arts.size(), 5, "等级50应该能解锁多个功法")

## 测试：多条件查询
func test_multi_condition_query():
	var filters = {
		"type": MartialArtData.MartialArtType.ATTACK,
		"grade": MartialArtData.GradeType.COMMON,
		"weapon": MartialArtData.WeaponType.SWORD
	}
	var results = database.query_martial_arts(filters)
	assert_eq(results.size(), 1, "应该只有1个符合条件的功法")
	assert_eq(results[0].id, "generic_basic_sword", "应该是基础剑法")

## 测试：验证功法数据有效性
func test_martial_art_data_validation():
	var all_arts = database.get_all_martial_arts()
	for art in all_arts:
		assert_true(art.validate(), "功法 %s 数据应该有效" % art.name)

## 测试：验证连招链
func test_combo_chain():
	var yujian = database.get_martial_art("tianjian_yujian")
	assert_not_null(yujian, "应该能获取御剑术")
	assert_gt(yujian.combo_chain.size(), 0, "御剑术应该有连招")
	assert_true(yujian.combo_chain.has("tianjian_jianguang"), "御剑术应该能连接剑气纵横")

## 测试：数据库统计信息
func test_database_statistics():
	var stats = database.get_statistics()
	assert_eq(stats["total_count"], 13, "总功法数应该是13")
	assert_true(stats["is_loaded"], "数据库应该已加载")
	assert_eq(stats["load_errors"], 0, "不应该有加载错误")

## 测试：验证高级功法属性
func test_advanced_martial_art_properties():
	var tianjian_nine = database.get_martial_art("tianjian_nine_forms")
	assert_not_null(tianjian_nine, "应该能获取天剑九式")
	assert_eq(tianjian_nine.unlock_level, 45, "天剑九式解锁等级应该是45")
	assert_eq(tianjian_nine.grade, MartialArtData.GradeType.EPIC, "天剑九式品阶应该是EPIC")
	assert_eq(tianjian_nine.hit_count, 9, "天剑九式应该有9段攻击")
	assert_eq(tianjian_nine.element_type, "金", "天剑九式元素类型应该是金")

## 测试：验证防御型功法
func test_defense_martial_art():
	var jingang = database.get_martial_art("shaolin_jingang")
	assert_not_null(jingang, "应该能获取金刚不坏体")
	assert_eq(jingang.martial_art_type, MartialArtData.MartialArtType.DEFENSE, "金刚不坏体应该是防御型")
	assert_eq(jingang.damage_base, 0.0, "防御型功法基础伤害应该是0")

## 测试：验证增益型功法
func test_buff_martial_art():
	var yijin = database.get_martial_art("shaolin_yijin")
	assert_not_null(yijin, "应该能获取易筋经")
	assert_eq(yijin.martial_art_type, MartialArtData.MartialArtType.BUFF, "易筋经应该是增益型")
	assert_eq(yijin.grade, MartialArtData.GradeType.LEGENDARY, "易筋经应该是传说品阶")