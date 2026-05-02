extends SceneTree

## 功法数据库测试脚本
## 验证所有功法数据是否正确加载和分类

func _init():
	print("=== 功法数据库测试 ===\n")
	
	# 创建数据库实例
	var database = MartialArtDatabase.new()
	database._ready()  # 手动调用初始化
	
	# 运行测试
	test_database_loading(database)
	test_school_classification(database)
	test_grade_classification(database)
	test_element_types(database)
	test_specific_martial_arts(database)
	
	print("\n=== 测试完成 ===")
	quit()

## 测试数据库加载
func test_database_loading(database: MartialArtDatabase):
	print("【测试1】数据库加载")
	
	var total_count = database.get_all_martial_arts().size()
	print("  ✓ 总功法数量: %d" % total_count)
	
	if total_count == 48:
		print("  ✓ 功法数量正确（预期48个）")
	else:
		print("  ✗ 功法数量错误（预期48个，实际%d个）" % total_count)
	
	print()

## 测试门派分类
func test_school_classification(database: MartialArtDatabase):
	print("【测试2】门派分类")
	
	var schools = {
		MartialArtData.SchoolType.GENERIC: "通用",
		MartialArtData.SchoolType.TIANJIAN: "天剑盟",
		MartialArtData.SchoolType.MOJIAO: "魔教",
		MartialArtData.SchoolType.SHAOLIN: "少林寺",
		MartialArtData.SchoolType.WUDANG: "武当派",
		MartialArtData.SchoolType.GAIBANG: "丐帮",
		MartialArtData.SchoolType.TANGMEN: "唐门",
		MartialArtData.SchoolType.MINGJIAO: "明教",
		MartialArtData.SchoolType.WUDU: "五毒教",
		MartialArtData.SchoolType.XIAOYAO: "逍遥派"
	}
	
	for school_type in schools:
		var school_name = schools[school_type]
		var martial_arts = database.get_martial_arts_by_school(school_type)
		var expected_count = 3 if school_type == MartialArtData.SchoolType.GENERIC else 5
		
		if martial_arts.size() == expected_count:
			print("  ✓ %s: %d个功法" % [school_name, martial_arts.size()])
		else:
			print("  ✗ %s: %d个功法（预期%d个）" % [school_name, martial_arts.size(), expected_count])
	
	print()

## 测试品阶分类
func test_grade_classification(database: MartialArtDatabase):
	print("【测试3】品阶分类")
	
	var grades = {
		MartialArtData.GradeType.COMMON: "黄阶",
		MartialArtData.GradeType.RARE: "玄阶",
		MartialArtData.GradeType.EPIC: "地阶",
		MartialArtData.GradeType.LEGENDARY: "天阶"
	}
	
	for grade_type in grades:
		var grade_name = grades[grade_type]
		var martial_arts = database.get_martial_arts_by_grade(grade_type)
		print("  ✓ %s: %d个功法" % [grade_name, martial_arts.size()])
	
	print()

## 测试元素属性
func test_element_types(database: MartialArtDatabase):
	print("【测试4】元素属性统计")
	
	var element_count = {}
	var all_martial_arts = database.get_all_martial_arts()
	
	for martial_art in all_martial_arts:
		var element = martial_art.element_type
		if not element_count.has(element):
			element_count[element] = 0
		element_count[element] += 1
	
	for element in element_count:
		print("  ✓ %s属性: %d个功法" % [element, element_count[element]])
	
	print()

## 测试特定功法
func test_specific_martial_arts(database: MartialArtDatabase):
	print("【测试5】特定功法验证")
	
	# 测试天剑盟的万剑归宗
	var wanjian = database.get_martial_art("tianjian_wanjian")
	if wanjian:
		print("  ✓ 万剑归宗")
		print("    - 名称: %s" % wanjian.name)
		print("    - 门派: %s" % wanjian.get_school_string())
		print("    - 品阶: %s" % wanjian.get_grade_string())
		print("    - 元素: %s" % wanjian.element_type)
		print("    - 解锁等级: %d" % wanjian.unlock_level)
		print("    - 伤害: %.0f (x%.1f)" % [wanjian.damage_base, wanjian.damage_scale])
	else:
		print("  ✗ 找不到万剑归宗")
	
	print()
	
	# 测试魔教的天魔解体
	var jieti = database.get_martial_art("mojiao_jie_ti")
	if jieti:
		print("  ✓ 天魔解体")
		print("    - 名称: %s" % jieti.name)
		print("    - 门派: %s" % jieti.get_school_string())
		print("    - 品阶: %s" % jieti.get_grade_string())
		print("    - 元素: %s" % jieti.element_type)
		print("    - 类型: %s" % jieti.get_type_string())
	else:
		print("  ✗ 找不到天魔解体")
	
	print()
	
	# 测试逍遥派的北冥神功
	var beiming = database.get_martial_art("xiaoyao_beiming")
	if beiming:
		print("  ✓ 北冥神功")
		print("    - 名称: %s" % beiming.name)
		print("    - 门派: %s" % beiming.get_school_string())
		print("    - 品阶: %s" % beiming.get_grade_string())
		print("    - 元素: %s" % beiming.element_type)
		print("    - 解锁等级: %d" % beiming.unlock_level)
	else:
		print("  ✗ 找不到北冥神功")
	
	print()
	
	# 测试唐门的暴雨梨花针
	var lihua = database.get_martial_art("tangmen_lihua")
	if lihua:
		print("  ✓ 暴雨梨花针")
		print("    - 名称: %s" % lihua.name)
		print("    - 门派: %s" % lihua.get_school_string())
		print("    - 元素: %s" % lihua.element_type)
		print("    - 连击数: %d" % lihua.hit_count)
	else:
		print("  ✗ 找不到暴雨梨花针")