extends SceneTree

## 功法数据平衡扩展工具
## 为每个门派添加平衡的功法体系
## 
## 设计原则：
## 1. 每个门派至少有5个功法（1个基础 + 4个进阶）
## 2. 品阶分布：1个黄阶基础功法 + 2个玄阶 + 1个地阶 + 1个天阶
## 3. 类型多样：攻击、防御、辅助等类型平衡
## 4. 门派特色：每个门派有独特的元素和战斗风格

const OUTPUT_DIR = "res://data/martial_arts/"

func _init():
	print("=== 开始平衡功法数据扩展 ===")
	print("目标：为每个门派创建完整的功法体系\n")
	
	# 确保输出目录存在
	var dir_path = OUTPUT_DIR.replace("res://", "")
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	# 为每个门派创建完整的功法体系
	expand_tianjian_martial_arts()   # 天剑盟（剑修）- 补充到5个
	expand_shaolin_martial_arts()    # 少林寺（体修）- 补充到5个
	expand_wudang_martial_arts()     # 武当派（道修）- 补充到5个
	expand_gaibang_martial_arts()    # 丐帮（掌法）- 补充到5个
	expand_tangmen_martial_arts()    # 唐门（暗器）- 补充到5个
	expand_mingjiao_martial_arts()   # 明教（火系）- 补充到5个
	expand_wudu_martial_arts()       # 五毒教（毒系）- 补充到5个
	expand_xiaoyao_martial_arts()    # 逍遥派（辅助）- 补充到5个
	expand_emei_martial_arts()       # 峨眉派（治疗）- 补充到5个
	
	print("\n=== 功法数据平衡扩展完成！===")
	print("每个门派现在都有完整的功法体系")
	print("位置: " + OUTPUT_DIR)
	
	quit()

## 扩展天剑盟功法（剑修）- 目标：5个功法
## 已有：御剑术(玄)、剑气纵横(玄)、天剑九式(地)
## 新增：基础剑诀(黄)、万剑归宗(天)
func expand_tianjian_martial_arts():
	print("扩展天剑盟功法...")
	
	# 基础剑诀（黄阶）
	var basic = MartialArtData.new()
	basic.id = "tianjian_basic"
	basic.name = "天剑基础剑诀"
	basic.description = "天剑盟入门剑法，教导弟子如何以内力御剑。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.SWORD
	basic.school = MartialArtData.SchoolType.GENERIC
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 10
	basic.damage_base = 70.0
	basic.damage_scale = 1.1
	basic.hit_count = 2
	basic.element_type = "金"
	basic.cost_stamina = 12.0
	basic.cost_mana = 15.0
	basic.cooldown = 3.5
	basic.startup_frames = 0.25
	basic.active_frames = 0.6
	basic.recovery_frames = 0.35
	basic.total_duration = 1.2
	basic.can_cancel_from_frame = 0.7
	basic.combo_chain.append("tianjian_yujian")
	ResourceSaver.save(basic, OUTPUT_DIR + "tianjian_basic.tres")
	print("  ✓ 天剑基础剑诀 (黄阶)")
	
	# 万剑归宗（天阶）
	var wanjian = MartialArtData.new()
	wanjian.id = "tianjian_wanjian"
	wanjian.name = "万剑归宗"
	wanjian.description = "天剑盟至高剑法，召唤万剑齐发，威力无穷。大乘期修士可修炼。"
	wanjian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	wanjian.weapon_type = MartialArtData.WeaponType.SWORD
	wanjian.school = MartialArtData.SchoolType.GENERIC
	wanjian.grade = MartialArtData.GradeType.LEGENDARY
	wanjian.unlock_level = 99
	wanjian.damage_base = 800.0
	wanjian.damage_scale = 5.0
	wanjian.hit_count = 100
	wanjian.element_type = "金"
	wanjian.cost_stamina = 100.0
	wanjian.cost_mana = 300.0
	wanjian.cooldown = 120.0
	wanjian.startup_frames = 2.0
	wanjian.active_frames = 5.0
	wanjian.recovery_frames = 2.0
	wanjian.total_duration = 9.0
	wanjian.can_cancel_from_frame = -1.0
	ResourceSaver.save(wanjian, OUTPUT_DIR + "tianjian_wanjian.tres")
	print("  ✓ 万剑归宗 (天阶)")

## 扩展少林寺功法（体修）- 目标：5个功法
## 已有：金刚不坏体(地)、易筋经(天)
## 新增：罗汉拳(黄)、大力金刚掌(玄)、龙爪手(玄)
func expand_shaolin_martial_arts():
	print("\n扩展少林寺功法...")
	
	# 罗汉拳（黄阶）
	var luohan = MartialArtData.new()
	luohan.id = "shaolin_luohan"
	luohan.name = "罗汉拳"
	luohan.description = "少林基础拳法，刚猛有力，是少林弟子的入门功夫。"
	luohan.martial_art_type = MartialArtData.MartialArtType.ATTACK
	luohan.weapon_type = MartialArtData.WeaponType.FIST
	luohan.school = MartialArtData.SchoolType.SHAOLIN
	luohan.grade = MartialArtData.GradeType.COMMON
	luohan.unlock_level = 8
	luohan.damage_base = 60.0
	luohan.damage_scale = 1.0
	luohan.hit_count = 3
	luohan.element_type = "无"
	luohan.cost_stamina = 10.0
	luohan.cost_mana = 10.0
	luohan.cooldown = 3.0
	luohan.startup_frames = 0.2
	luohan.active_frames = 0.7
	luohan.recovery_frames = 0.3
	luohan.total_duration = 1.2
	luohan.can_cancel_from_frame = 0.8
	luohan.combo_chain.append("shaolin_dali")
	ResourceSaver.save(luohan, OUTPUT_DIR + "shaolin_luohan.tres")
	print("  ✓ 罗汉拳 (黄阶)")
	
	# 大力金刚掌（玄阶）
	var dali = MartialArtData.new()
	dali.id = "shaolin_dali"
	dali.name = "大力金刚掌"
	dali.description = "少林七十二绝技之一，掌力刚猛，可开山裂石。"
	dali.martial_art_type = MartialArtData.MartialArtType.ATTACK
	dali.weapon_type = MartialArtData.WeaponType.FIST
	dali.school = MartialArtData.SchoolType.SHAOLIN
	dali.grade = MartialArtData.GradeType.RARE
	dali.unlock_level = 33
	dali.damage_base = 160.0
	dali.damage_scale = 1.8
	dali.hit_count = 1
	dali.element_type = "无"
	dali.cost_stamina = 35.0
	dali.cost_mana = 40.0
	dali.cooldown = 8.0
	dali.startup_frames = 0.5
	dali.active_frames = 0.3
	dali.recovery_frames = 0.7
	dali.total_duration = 1.5
	dali.can_cancel_from_frame = -1.0
	ResourceSaver.save(dali, OUTPUT_DIR + "shaolin_dali.tres")
	print("  ✓ 大力金刚掌 (玄阶)")
	
	# 龙爪手（玄阶）
	var longzhao = MartialArtData.new()
	longzhao.id = "shaolin_longzhao"
	longzhao.name = "龙爪手"
	longzhao.description = "少林擒拿功夫，手如龙爪，可擒拿敌人。"
	longzhao.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	longzhao.weapon_type = MartialArtData.WeaponType.FIST
	longzhao.school = MartialArtData.SchoolType.SHAOLIN
	longzhao.grade = MartialArtData.GradeType.RARE
	longzhao.unlock_level = 29
	longzhao.damage_base = 100.0
	longzhao.damage_scale = 1.2
	longzhao.hit_count = 1
	longzhao.element_type = "无"
	longzhao.cost_stamina = 25.0
	longzhao.cost_mana = 35.0
	longzhao.cooldown = 12.0
	longzhao.startup_frames = 0.4
	longzhao.active_frames = 8.0
	longzhao.recovery_frames = 0.4
	longzhao.total_duration = 8.8
	longzhao.can_cancel_from_frame = -1.0
	ResourceSaver.save(longzhao, OUTPUT_DIR + "shaolin_longzhao.tres")
	print("  ✓ 龙爪手 (玄阶)")

## 扩展武当派功法（道修）- 目标：5个功法
## 已有：两仪剑法(地)、太极玄功(天)
## 新增：武当基础剑法(黄)、太极拳(玄)、真武七截阵(玄)
func expand_wudang_martial_arts():
	print("\n扩展武当派功法...")
	
	# 武当基础剑法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "wudang_basic"
	basic.name = "武当基础剑法"
	basic.description = "武当派入门剑法，讲究以柔克刚，四两拨千斤。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.SWORD
	basic.school = MartialArtData.SchoolType.WUDANG
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 9
	basic.damage_base = 65.0
	basic.damage_scale = 1.05
	basic.hit_count = 2
	basic.element_type = "无"
	basic.cost_stamina = 11.0
	basic.cost_mana = 14.0
	basic.cooldown = 3.2
	basic.startup_frames = 0.22
	basic.active_frames = 0.65
	basic.recovery_frames = 0.33
	basic.total_duration = 1.2
	basic.can_cancel_from_frame = 0.75
	basic.combo_chain.append("wudang_liangyi")
	ResourceSaver.save(basic, OUTPUT_DIR + "wudang_basic.tres")
	print("  ✓ 武当基础剑法 (黄阶)")
	
	# 太极拳（玄阶）
	var taijiquan = MartialArtData.new()
	taijiquan.id = "wudang_taijiquan"
	taijiquan.name = "太极拳"
	taijiquan.description = "武当派拳法，以柔克刚，绵里藏针。"
	taijiquan.martial_art_type = MartialArtData.MartialArtType.ATTACK
	taijiquan.weapon_type = MartialArtData.WeaponType.FIST
	taijiquan.school = MartialArtData.SchoolType.WUDANG
	taijiquan.grade = MartialArtData.GradeType.RARE
	taijiquan.unlock_level = 31
	taijiquan.damage_base = 140.0
	taijiquan.damage_scale = 1.6
	taijiquan.hit_count = 4
	taijiquan.element_type = "无"
	taijiquan.cost_stamina = 28.0
	taijiquan.cost_mana = 38.0
	taijiquan.cooldown = 7.0
	taijiquan.startup_frames = 0.35
	taijiquan.active_frames = 1.1
	taijiquan.recovery_frames = 0.55
	taijiquan.total_duration = 2.0
	taijiquan.can_cancel_from_frame = -1.0
	ResourceSaver.save(taijiquan, OUTPUT_DIR + "wudang_taijiquan.tres")
	print("  ✓ 太极拳 (玄阶)")
	
	# 真武七截阵（玄阶）
	var zhenwu = MartialArtData.new()
	zhenwu.id = "wudang_zhenwu"
	zhenwu.name = "真武七截阵"
	zhenwu.description = "武当派阵法，七人合力，威力倍增。可提升队友战力。"
	zhenwu.martial_art_type = MartialArtData.MartialArtType.BUFF
	zhenwu.weapon_type = MartialArtData.WeaponType.NONE
	zhenwu.school = MartialArtData.SchoolType.WUDANG
	zhenwu.grade = MartialArtData.GradeType.RARE
	zhenwu.unlock_level = 36
	zhenwu.damage_base = 0.0
	zhenwu.damage_scale = 0.0
	zhenwu.hit_count = 0
	zhenwu.element_type = "无"
	zhenwu.cost_stamina = 40.0
	zhenwu.cost_mana = 60.0
	zhenwu.cooldown = 40.0
	zhenwu.startup_frames = 1.0
	zhenwu.active_frames = 25.0
	zhenwu.recovery_frames = 1.0
	zhenwu.total_duration = 27.0
	zhenwu.can_cancel_from_frame = -1.0
	ResourceSaver.save(zhenwu, OUTPUT_DIR + "wudang_zhenwu.tres")
	print("  ✓ 真武七截阵 (玄阶)")

## 扩展丐帮功法（掌法）- 目标：5个功法
## 已有：打狗棒法(玄)、降龙十八掌(地)
## 新增：丐帮基础棍法(黄)、逍遥游掌(玄)、天下无狗(天)
func expand_gaibang_martial_arts():
	print("\n扩展丐帮功法...")
	
	# 丐帮基础棍法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "gaibang_basic"
	basic.name = "丐帮基础棍法"
	basic.description = "丐帮弟子入门棍法，简单实用。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.STAFF
	basic.school = MartialArtData.SchoolType.GENERIC
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 7
	basic.damage_base = 55.0
	basic.damage_scale = 0.95
	basic.hit_count = 2
	basic.element_type = "无"
	basic.cost_stamina = 9.0
	basic.cost_mana = 12.0
	basic.cooldown = 2.8
	basic.startup_frames = 0.18
	basic.active_frames = 0.55
	basic.recovery_frames = 0.27
	basic.total_duration = 1.0
	basic.can_cancel_from_frame = 0.65
	basic.combo_chain.append("gaibang_dagou")
	ResourceSaver.save(basic, OUTPUT_DIR + "gaibang_basic.tres")
	print("  ✓ 丐帮基础棍法 (黄阶)")
	
	# 逍遥游掌（玄阶）
	var xiaoyaoyou = MartialArtData.new()
	xiaoyaoyou.id = "gaibang_xiaoyaoyou"
	xiaoyaoyou.name = "逍遥游掌"
	xiaoyaoyou.description = "丐帮掌法，掌法飘逸，如行云流水。"
	xiaoyaoyou.martial_art_type = MartialArtData.MartialArtType.ATTACK
	xiaoyaoyou.weapon_type = MartialArtData.WeaponType.FIST
	xiaoyaoyou.school = MartialArtData.SchoolType.GENERIC
	xiaoyaoyou.grade = MartialArtData.GradeType.RARE
	xiaoyaoyou.unlock_level = 34
	xiaoyaoyou.damage_base = 145.0
	xiaoyaoyou.damage_scale = 1.65
	xiaoyaoyou.hit_count = 5
	xiaoyaoyou.element_type = "无"
	xiaoyaoyou.cost_stamina = 30.0
	xiaoyaoyou.cost_mana = 42.0
	xiaoyaoyou.cooldown = 7.5
	xiaoyaoyou.startup_frames = 0.38
	xiaoyaoyou.active_frames = 1.15
	xiaoyaoyou.recovery_frames = 0.57
	xiaoyaoyou.total_duration = 2.1
	xiaoyaoyou.can_cancel_from_frame = -1.0
	xiaoyaoyou.combo_chain.append("gaibang_xianglong")
	ResourceSaver.save(xiaoyaoyou, OUTPUT_DIR + "gaibang_xiaoyaoyou.tres")
	print("  ✓ 逍遥游掌 (玄阶)")
	
	# 天下无狗（天阶）
	var tianxia = MartialArtData.new()
	tianxia.id = "gaibang_tianxia"
	tianxia.name = "天下无狗"
	tianxia.description = "丐帮至高绝学，打狗棒法的终极奥义。渡劫期修士可修炼。"
	tianxia.martial_art_type = MartialArtData.MartialArtType.ATTACK
	tianxia.weapon_type = MartialArtData.WeaponType.STAFF
	tianxia.school = MartialArtData.SchoolType.GENERIC
	tianxia.grade = MartialArtData.GradeType.LEGENDARY
	tianxia.unlock_level = 98
	tianxia.damage_base = 750.0
	tianxia.damage_scale = 4.8
	tianxia.hit_count = 36
	tianxia.element_type = "无"
	tianxia.cost_stamina = 95.0
	tianxia.cost_mana = 280.0
	tianxia.cooldown = 110.0
	tianxia.startup_frames = 1.8
	tianxia.active_frames = 4.5
	tianxia.recovery_frames = 1.8
	tianxia.total_duration = 8.1
	tianxia.can_cancel_from_frame = -1.0
	ResourceSaver.save(tianxia, OUTPUT_DIR + "gaibang_tianxia.tres")
	print("  ✓ 天下无狗 (天阶)")

## 扩展唐门功法（暗器）- 目标：5个功法
## 已有：暴雨梨花针(玄)、孔雀翎(地)、七星海棠毒(玄)
## 新增：唐门基础暗器(黄)、含沙射影(天)
func expand_tangmen_martial_arts():
	print("\n扩展唐门功法...")
	
	# 唐门基础暗器（黄阶）
	var basic = MartialArtData.new()
	basic.id = "tangmen_basic"
	basic.name = "唐门基础暗器"
	basic.description = "唐门入门暗器手法，教导弟子如何使用飞针、飞刀等暗器。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.NONE
	basic.school = MartialArtData.SchoolType.GENERIC
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 11
	basic.damage_base = 58.0
	basic.damage_scale = 0.98
	basic.hit_count = 3
	basic.element_type = "金"
	basic.cost_stamina = 10.0
	basic.cost_mana = 13.0
	basic.cooldown = 3.0
	basic.startup_frames = 0.2
	basic.active_frames = 0.6
	basic.recovery_frames = 0.3
	basic.total_duration = 1.1
	basic.can_cancel_from_frame = 0.7
	basic.combo_chain.append("tangmen_lihua")
	ResourceSaver.save(basic, OUTPUT_DIR + "tangmen_basic.tres")
	print("  ✓ 唐门基础暗器 (黄阶)")
	
	# 含沙射影（天阶）
	var hansha = MartialArtData.new()
	hansha.id = "tangmen_hansha"
	hansha.name = "含沙射影"
	hansha.description = "唐门至高暗器绝学，无形无影，防不胜防。合道期修士可修炼。"
	hansha.martial_art_type = MartialArtData.MartialArtType.ATTACK
	hansha.weapon_type = MartialArtData.WeaponType.NONE
	hansha.school = MartialArtData.SchoolType.GENERIC
	hansha.grade = MartialArtData.GradeType.LEGENDARY
	hansha.unlock_level = 92
	hansha.damage_base = 700.0
	hansha.damage_scale = 4.5
	hansha.hit_count = 50
	hansha.element_type = "毒"
	hansha.cost_stamina = 90.0
	hansha.cost_mana = 260.0
	hansha.cooldown = 100.0
	hansha.startup_frames = 1.5
	hansha.active_frames = 4.0
	hansha.recovery_frames = 1.5
	hansha.total_duration = 7.0
	hansha.can_cancel_from_frame = -1.0
	ResourceSaver.save(hansha, OUTPUT_DIR + "tangmen_hansha.tres")
	print("  ✓ 含沙射影 (天阶)")

## 扩展明教功法（火系）- 目标：5个功法
## 已有：烈火刀法(玄)、乾坤大挪移(天)
## 新增：明教基础刀法(黄)、圣火令(玄)、焚天煮海(地)
func expand_mingjiao_martial_arts():
	print("\n扩展明教功法...")
	
	# 明教基础刀法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "mingjiao_basic"
	basic.name = "明教基础刀法"
	basic.description = "明教入门刀法，刀势刚猛，带有火焰之力。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.BLADE
	basic.school = MartialArtData.SchoolType.GENERIC
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 12
	basic.damage_base = 62.0
	basic.damage_scale = 1.02
	basic.hit_count = 2
	basic.element_type = "火"
	basic.cost_stamina = 11.0
	basic.cost_mana = 14.0
	basic.cooldown = 3.3
	basic.startup_frames = 0.23
	basic.active_frames = 0.62
	basic.recovery_frames = 0.35
	basic.total_duration = 1.2
	basic.can_cancel_from_frame = 0.72
	basic.combo_chain.append("mingjiao_liehuo")
	ResourceSaver.save(basic, OUTPUT_DIR + "mingjiao_basic.tres")
	print("  ✓ 明教基础刀法 (黄阶)")
	
	# 圣火令（玄阶）
	var shenghuo = MartialArtData.new()
	shenghuo.id = "mingjiao_shenghuo"
	shenghuo.name = "圣火令"
	shenghuo.description = "明教圣物，可发出圣火攻击敌人。"
	shenghuo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	shenghuo.weapon_type = MartialArtData.WeaponType.NONE
	shenghuo.school = MartialArtData.SchoolType.GENERIC
	shenghuo.grade = MartialArtData.GradeType.RARE
	shenghuo.unlock_level = 37
	shenghuo.damage_base = 155.0
	shenghuo.damage_scale = 1.75
	shenghuo.hit_count = 3
	shenghuo.element_type = "火"
	shenghuo.cost_stamina = 32.0
	shenghuo.cost_mana = 45.0
	shenghuo.cooldown = 8.5
	shenghuo.startup_frames = 0.42
	shenghuo.active_frames = 1.0
	shenghuo.recovery_frames = 0.58
	shenghuo.total_duration = 2.0
	shenghuo.can_cancel_from_frame = -1.0
	ResourceSaver.save(shenghuo, OUTPUT_DIR + "mingjiao_shenghuo.tres")
	print("  ✓ 圣火令 (玄阶)")
	
	# 焚天煮海（地阶）
	var fentian = MartialArtData.new()
	fentian.id = "mingjiao_fentian"
	fentian.name = "焚天煮海"
	fentian.description = "明教火系大招，召唤烈焰焚烧一切。"
	fentian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	fentian.weapon_type = MartialArtData.WeaponType.NONE
	fentian.school = MartialArtData.SchoolType.GENERIC
	fentian.grade = MartialArtData.GradeType.EPIC
	fentian.unlock_level = 58
	fentian.damage_base = 420.0
	fentian.damage_scale = 3.2
	fentian.hit_count = 10
	fentian.element_type = "火"
	fentian.cost_stamina = 65.0
	fentian.cost_mana = 130.0
	fentian.cooldown = 20.0
	fentian.startup_frames = 1.0
	fentian.active_frames = 3.0
	fentian.recovery_frames = 1.2
	fentian.total_duration = 5.2
	fentian.can_cancel_from_frame = -1.0
	ResourceSaver.save(fentian, OUTPUT_DIR + "mingjiao_fentian.tres")
	print("  ✓ 焚天煮海 (地阶)")

## 扩展五毒教功法（毒系）- 目标：5个功法
## 已有：五毒神掌(玄)、万蛊噬心(地)
## 新增：五毒基础掌法(黄)、蛇蝎美人(玄)、毒龙钻(天)
func expand_wudu_martial_arts():
	print("\n扩展五毒教功法...")
	
	# 五毒基础掌法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "wudu_basic"
	basic.name = "五毒基础掌法"
	basic.description = "五毒教入门掌法，掌力带有微毒。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.FIST
	basic.school = MartialArtData.SchoolType.GENERIC
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 13
	basic.damage_base = 56.0
	basic.damage_scale = 0.96
	basic.hit_count = 2
	basic.element_type = "毒"
	basic.cost_stamina = 10.0
	basic.cost_mana = 13.0
	basic.cooldown = 3.1
	basic.startup_frames = 0.21
	basic.active_frames = 0.58
	basic.recovery_frames = 0.31
	basic.total_duration = 1.1
	basic.can_cancel_from_frame = 0.68
	basic.combo_chain.append("wudu_shenzhang")
	ResourceSaver.save(basic, OUTPUT_DIR + "wudu_basic.tres")
	print("  ✓ 五毒基础掌法 (黄阶)")
	
	# 蛇蝎美人（玄阶）
	var shexie = MartialArtData.new()
	shexie.id = "wudu_shexie"
	shexie.name = "蛇蝎美人"
	shexie.description = "五毒教媚功，可魅惑敌人，使其失去战斗力。"
	shexie.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	shexie.weapon_type = MartialArtData.WeaponType.NONE
	shexie.school = MartialArtData.SchoolType.GENERIC
	shexie.grade = MartialArtData.GradeType.RARE
	shexie.unlock_level = 38
	shexie.damage_base = 60.0
	shexie.damage_scale = 0.6
	shexie.hit_count = 1
	shexie.element_type = "毒"
	shexie.cost_stamina = 20.0
	shexie.cost_mana = 55.0
	shexie.cooldown = 18.0
	shexie.startup_frames = 0.6
	shexie.active_frames = 15.0
	shexie.recovery_frames = 0.6
	shexie.total_duration = 16.2
	shexie.can_cancel_from_frame = -1.0
	ResourceSaver.save(shexie, OUTPUT_DIR + "wudu_shexie.tres")
	print("  ✓ 蛇蝎美人 (玄阶)")
	
	# 毒龙钻（天阶）
	var dulong = MartialArtData.new()
	dulong.id = "wudu_dulong"
	dulong.name = "毒龙钻"
	dulong.description = "五毒教至高绝学，凝聚万毒之力，化为毒龙攻击。大乘期修士可修炼。"
	dulong.martial_art_type = MartialArtData.MartialArtType.ATTACK
	dulong.weapon_type = MartialArtData.WeaponType.NONE
	dulong.school = MartialArtData.SchoolType.GENERIC
	dulong.grade = MartialArtData.GradeType.LEGENDARY
	dulong.unlock_level = 96
	dulong.damage_base = 720.0
	dulong.damage_scale = 4.6
	dulong.hit_count = 1
	dulong.element_type = "毒"
	dulong.cost_stamina = 92.0
	dulong.cost_mana = 270.0
	dulong.cooldown = 105.0
	dulong.startup_frames = 1.6
	dulong.active_frames = 2.0
	dulong.recovery_frames = 1.6
	dulong.total_duration = 5.2
	dulong.can_cancel_from_frame = -1.0
	ResourceSaver.save(dulong, OUTPUT_DIR + "wudu_dulong.tres")
	print("  ✓ 毒龙钻 (天阶)")

## 扩展逍遥派功法（辅助）- 目标：5个功法
## 已有：凌波微步(玄)、北冥神功(天)
## 新增：逍遥基础身法(黄)、小无相功(玄)、天山六阳掌(地)
func expand_xiaoyao_martial_arts():
	print("\n扩展逍遥派功法...")
	
	# 逍遥基础身法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "xiaoyao_basic"
	basic.name = "逍遥基础身法"
	basic.description = "逍遥派入门身法，身形飘逸，来去自如。"
	basic.martial_art_type = MartialArtData.MartialArtType.MOVEMENT
	basic.weapon_type = MartialArtData.WeaponType.NONE
	basic.school = MartialArtData.SchoolType.GENERIC
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 14
	basic.damage_base = 0.0
	basic.damage_scale = 0.0
	basic.hit_count = 0
	basic.element_type = "无"
	basic.cost_stamina = 18.0
	basic.cost_mana = 8.0
	basic.cooldown = 4.0
	basic.startup_frames = 0.12
	basic.active_frames = 1.2
	basic.recovery_frames = 0.12
	basic.total_duration = 1.44
	basic.can_cancel_from_frame = -1.0
	basic.combo_chain.append("xiaoyao_lingbo")
	ResourceSaver.save(basic, OUTPUT_DIR + "xiaoyao_basic.tres")
	print("  ✓ 逍遥基础身法 (黄阶)")
	
	# 小无相功（玄阶）
	var xiaowuxiang = MartialArtData.new()
	xiaowuxiang.id = "xiaoyao_xiaowuxiang"
	xiaowuxiang.name = "小无相功"
	xiaowuxiang.description = "逍遥派内功，可模仿他人武功。"
	xiaowuxiang.martial_art_type = MartialArtData.MartialArtType.BUFF
	xiaowuxiang.weapon_type = MartialArtData.WeaponType.NONE
	xiaowuxiang.school = MartialArtData.SchoolType.GENERIC
	xiaowuxiang.grade = MartialArtData.GradeType.RARE
	xiaowuxiang.unlock_level = 39
	xiaowuxiang.damage_base = 0.0
	xiaowuxiang.damage_scale = 0.0
	xiaowuxiang.hit_count = 0
	xiaowuxiang.element_type = "无"
	xiaowuxiang.cost_stamina = 35.0
	xiaowuxiang.cost_mana = 65.0
	xiaowuxiang.cooldown = 35.0
	xiaowuxiang.startup_frames = 0.9
	xiaowuxiang.active_frames = 20.0
	xiaowuxiang.recovery_frames = 0.9
	xiaowuxiang.total_duration = 21.8
	xiaowuxiang.can_cancel_from_frame = -1.0
	ResourceSaver.save(xiaowuxiang, OUTPUT_DIR + "xiaoyao_xiaowuxiang.tres")
	print("  ✓ 小无相功 (玄阶)")
	
	# 天山六阳掌（地阶）
	var tianshan = MartialArtData.new()
	tianshan.id = "xiaoyao_tianshan"
	tianshan.name = "天山六阳掌"
	tianshan.description = "逍遥派掌法，掌力至阳至刚，可破除阴寒之气。"
	tianshan.martial_art_type = MartialArtData.MartialArtType.ATTACK
	tianshan.weapon_type = MartialArtData.WeaponType.FIST
	tianshan.school = MartialArtData.SchoolType.GENERIC
	tianshan.grade = MartialArtData.GradeType.EPIC
	tianshan.unlock_level = 60
	tianshan.damage_base = 380.0
	tianshan.damage_scale = 3.0
	tianshan.hit_count = 6
	tianshan.element_type = "火"
	tianshan.cost_stamina = 60.0
	tianshan.cost_mana = 120.0
	tianshan.cooldown = 18.0
	tianshan.startup_frames = 0.9
	tianshan.active_frames = 2.5
	tianshan.recovery_frames = 1.1
	tianshan.total_duration = 4.5
	tianshan.can_cancel_from_frame = -1.0
	ResourceSaver.save(tianshan, OUTPUT_DIR + "xiaoyao_tianshan.tres")
	print("  ✓ 天山六阳掌 (地阶)")

## 扩展峨眉派功法（治疗）- 目标：5个功法
## 已有：峨眉剑法(玄)、九阳神功(天)
## 新增：峨眉基础剑法(黄)、回春咒(玄)、金顶绵掌(地)
func expand_emei_martial_arts():
	print("\n扩展峨眉派功法...")
	
	# 峨眉基础剑法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "emei_basic"
	basic.name = "峨眉基础剑法"
	basic.description = "峨眉派入门剑法，剑势轻柔，如春风拂面。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.SWORD
	basic.school = MartialArtData.SchoolType.EMEI
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 15
	basic.damage_base = 54.0
	basic.damage_scale = 0.94
	basic.hit_count = 2
	basic.element_type = "无"
	basic.cost_stamina = 9.0
	basic.cost_mana = 12.0
	basic.cooldown = 2.9
	basic.startup_frames = 0.19
	basic.active_frames = 0.56
	basic.recovery_frames = 0.29
	basic.total_duration = 1.04
	basic.can_cancel_from_frame = 0.66
	basic.combo_chain.append("emei_jianfa")
	ResourceSaver.save(basic, OUTPUT_DIR + "emei_basic.tres")
	print("  ✓ 峨眉基础剑法 (黄阶)")
	
	# 回春咒（玄阶）
	var huichun = MartialArtData.new()
	huichun.id = "emei_huichun"
	huichun.name = "回春咒"
	huichun.description = "峨眉派治疗术，可为自己或队友恢复生命。"
	huichun.martial_art_type = MartialArtData.MartialArtType.BUFF
	huichun.weapon_type = MartialArtData.WeaponType.NONE
	huichun.school = MartialArtData.SchoolType.EMEI
	huichun.grade = MartialArtData.GradeType.RARE
	huichun.unlock_level = 40
	huichun.damage_base = 0.0
	huichun.damage_scale = 0.0
	huichun.hit_count = 0
	huichun.element_type = "木"
	huichun.cost_stamina = 25.0
	huichun.cost_mana = 70.0
	huichun.cooldown = 25.0
	huichun.startup_frames = 0.8
	huichun.active_frames = 5.0
	huichun.recovery_frames = 0.8
	huichun.total_duration = 6.6
	huichun.can_cancel_from_frame = -1.0
	ResourceSaver.save(huichun, OUTPUT_DIR + "emei_huichun.tres")
	print("  ✓ 回春咒 (玄阶)")
	
	# 金顶绵掌（地阶）
	var jinding = MartialArtData.new()
	jinding.id = "emei_jinding"
	jinding.name = "金顶绵掌"
	jinding.description = "峨眉派掌法，掌力绵柔，却暗藏杀机。"
	jinding.martial_art_type = MartialArtData.MartialArtType.ATTACK
	jinding.weapon_type = MartialArtData.WeaponType.FIST
	jinding.school = MartialArtData.SchoolType.EMEI
	jinding.grade = MartialArtData.GradeType.EPIC
	jinding.unlock_level = 62
	jinding.damage_base = 360.0
	jinding.damage_scale = 2.9
	jinding.hit_count = 8
	jinding.element_type = "无"
	jinding.cost_stamina = 58.0
	jinding.cost_mana = 115.0
	jinding.cooldown = 17.0
	jinding.startup_frames = 0.85
	jinding.active_frames = 2.4
	jinding.recovery_frames = 1.05
	jinding.total_duration = 4.3
	jinding.can_cancel_from_frame = -1.0
	ResourceSaver.save(jinding, OUTPUT_DIR + "emei_jinding.tres")
	print("  ✓ 金顶绵掌 (地阶)")