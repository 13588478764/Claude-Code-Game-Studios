extends Node

## 功法数据库验证脚本
## 运行此脚本来验证功法数据是否正确加载

# 预加载必要的类
const MartialArtData = preload("res://src/scripts/data/martial_art_data.gd")
const MartialArtDatabase = preload("res://src/scripts/data/martial_art_database.gd")

func _ready():
	print("\n" + "=".repeat(60))
	print("功法数据库验证测试")
	print("=".repeat(60) + "\n")
	
	# 创建数据库实例
	var database = MartialArtDatabase.new()
	add_child(database)
	
	# 等待一帧让数据库加载
	await get_tree().process_frame
	
	# 运行验证测试
	run_verification_tests(database)
	
	# 退出
	get_tree().quit()

func run_verification_tests(database: MartialArtDatabase):
	var passed = 0
	var failed = 0
	
	# 测试1: 数据库是否加载
	print("【测试1】数据库加载状态")
	if database.is_loaded():
		print("  ✅ 数据库已成功加载")
		passed += 1
	else:
		print("  ❌ 数据库加载失败")
		failed += 1
	
	# 测试2: 功法数量
	print("\n【测试2】功法数量验证")
	var all_ids = database.get_all_martial_art_ids()
	print("  加载的功法数量: %d" % all_ids.size())
	if all_ids.size() == 13:
		print("  ✅ 功法数量正确（13个）")
		passed += 1
	else:
		print("  ❌ 功法数量不正确，期望13个，实际%d个" % all_ids.size())
		failed += 1
	
	# 测试3: 列出所有功法
	print("\n【测试3】功法列表")
	for id in all_ids:
		var art = database.get_martial_art(id)
		if art:
			print("  ✓ %s - %s (%s)" % [id, art.name, art.get_grade_string()])
	
	# 测试4: 验证关键功法
	print("\n【测试4】关键功法验证")
	var key_arts = [
		"generic_basic_sword",
		"tianjian_yujian",
		"shaolin_yijin",
		"wudang_taiji",
		"gaibang_xianglong"
	]
	
	for art_id in key_arts:
		if database.has_martial_art(art_id):
			var art = database.get_martial_art(art_id)
			print("  ✅ %s - %s" % [art_id, art.name])
			passed += 1
		else:
			print("  ❌ 缺少功法: %s" % art_id)
			failed += 1
	
	# 测试5: 数据有效性
	print("\n【测试5】数据有效性验证")
	var all_arts = database.get_all_martial_arts()
	var valid_count = 0
	for art in all_arts:
		if art.validate():
			valid_count += 1
	
	if valid_count == all_arts.size():
		print("  ✅ 所有功法数据有效 (%d/%d)" % [valid_count, all_arts.size()])
		passed += 1
	else:
		print("  ❌ 部分功法数据无效 (%d/%d)" % [valid_count, all_arts.size()])
		failed += 1
	
	# 测试6: 按品阶分类
	print("\n【测试6】品阶分类统计")
	var grade_stats = {
		MartialArtData.GradeType.COMMON: 0,
		MartialArtData.GradeType.RARE: 0,
		MartialArtData.GradeType.EPIC: 0,
		MartialArtData.GradeType.LEGENDARY: 0
	}
	
	for art in all_arts:
		grade_stats[art.grade] += 1
	
	print("  黄阶（COMMON）: %d" % grade_stats[MartialArtData.GradeType.COMMON])
	print("  玄阶（RARE）: %d" % grade_stats[MartialArtData.GradeType.RARE])
	print("  地阶（EPIC）: %d" % grade_stats[MartialArtData.GradeType.EPIC])
	print("  天阶（LEGENDARY）: %d" % grade_stats[MartialArtData.GradeType.LEGENDARY])
	
	if grade_stats[MartialArtData.GradeType.COMMON] == 3 and \
	   grade_stats[MartialArtData.GradeType.RARE] == 4 and \
	   grade_stats[MartialArtData.GradeType.EPIC] == 3 and \
	   grade_stats[MartialArtData.GradeType.LEGENDARY] == 3:
		print("  ✅ 品阶分布正确")
		passed += 1
	else:
		print("  ⚠️  品阶分布与预期不同")
	
	# 测试7: 按类型分类
	print("\n【测试7】类型分类统计")
	var type_stats = {
		MartialArtData.MartialArtType.ATTACK: 0,
		MartialArtData.MartialArtType.DEFENSE: 0,
		MartialArtData.MartialArtType.MOVEMENT: 0,
		MartialArtData.MartialArtType.BUFF: 0,
		MartialArtData.MartialArtType.DEBUFF: 0
	}
	
	for art in all_arts:
		type_stats[art.martial_art_type] += 1
	
	print("  攻击型（ATTACK）: %d" % type_stats[MartialArtData.MartialArtType.ATTACK])
	print("  防御型（DEFENSE）: %d" % type_stats[MartialArtData.MartialArtType.DEFENSE])
	print("  移动型（MOVEMENT）: %d" % type_stats[MartialArtData.MartialArtType.MOVEMENT])
	print("  增益型（BUFF）: %d" % type_stats[MartialArtData.MartialArtType.BUFF])
	print("  减益型（DEBUFF）: %d" % type_stats[MartialArtData.MartialArtType.DEBUFF])
	
	# 测试8: 连招系统
	print("\n【测试8】连招系统验证")
	var yujian = database.get_martial_art("tianjian_yujian")
	if yujian and yujian.combo_chain.size() > 0:
		print("  ✅ 御剑术有连招: %s" % str(yujian.combo_chain))
		passed += 1
	else:
		print("  ❌ 御剑术连招配置错误")
		failed += 1
	
	# 测试9: 数据库统计
	print("\n【测试9】数据库统计信息")
	database.print_statistics()
	
	# 测试10: 查询功能
	print("\n【测试10】查询功能测试")
	var level_1_arts = database.get_martial_arts_by_unlock_level(1)
	print("  等级1可解锁功法: %d个" % level_1_arts.size())
	
	var sword_arts = database.get_martial_arts_by_weapon(MartialArtData.WeaponType.SWORD)
	print("  剑类功法: %d个" % sword_arts.size())
	
	var shaolin_arts = database.get_martial_arts_by_school(MartialArtData.SchoolType.SHAOLIN)
	print("  少林功法: %d个" % shaolin_arts.size())
	
	if level_1_arts.size() > 0 and sword_arts.size() > 0:
		print("  ✅ 查询功能正常")
		passed += 1
	else:
		print("  ❌ 查询功能异常")
		failed += 1
	
	# 显示详细功法信息示例
	print("\n【功法详情示例】")
	var example_art = database.get_martial_art("tianjian_nine_forms")
	if example_art:
		print("  功法名称: %s" % example_art.name)
		print("  功法ID: %s" % example_art.id)
		print("  品阶: %s" % example_art.get_grade_string())
		print("  类型: %s" % example_art.get_martial_art_type_string())
		print("  武器: %s" % example_art.get_weapon_type_string())
		print("  门派: %s" % example_art.get_school_string())
		print("  解锁等级: %d" % example_art.unlock_level)
		print("  基础伤害: %.1f" % example_art.damage_base)
		print("  攻击段数: %d" % example_art.hit_count)
		print("  元素类型: %s" % example_art.element_type)
		print("  内力消耗: %.1f" % example_art.cost_mana)
		print("  体力消耗: %.1f" % example_art.cost_stamina)
		print("  冷却时间: %.1fs" % example_art.cooldown)
		print("  描述: %s" % example_art.description)
	
	# 总结
	print("\n" + "=".repeat(60))
	print("测试总结")
	print("=".repeat(60))
	print("通过: %d" % passed)
	print("失败: %d" % failed)
	print("总计: %d" % (passed + failed))
	
	if failed == 0:
		print("\n🎉 所有测试通过！功法数据库工作正常！")
	else:
		print("\n⚠️  有 %d 个测试失败，请检查！" % failed)
	
	print("=".repeat(60) + "\n")