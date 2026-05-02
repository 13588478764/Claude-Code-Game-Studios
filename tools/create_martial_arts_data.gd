@tool
extends EditorScript

## 功法数据创建工具
## 在编辑器中运行此脚本来创建初始功法数据

const OUTPUT_DIR = "res://data/martial_arts/"

func _run():
	print("=== 开始创建功法数据 ===")
	
	# 确保输出目录存在
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	
	# 创建各门派的代表功法
	create_generic_martial_arts()   # 通用功法（新手）
	create_tianjian_martial_arts()  # 天剑盟
	create_shaolin_martial_arts()   # 少林寺
	create_wudang_martial_arts()    # 武当派
	create_gaibang_martial_arts()   # 丐帮
	
	print("=== 功法数据创建完成！===")
	print("共创建了 13 个功法数据文件")
	print("位置: " + OUTPUT_DIR)

## 创建通用功法（新手功法）
func create_generic_martial_arts():
	print("\n创建通用功法...")
	
	# 基础剑法（黄阶）
	var basic_sword = MartialArtData.new()
	basic_sword.id = "generic_basic_sword"
	basic_sword.name = "基础剑法"
	basic_sword.description = "最基础的剑法，适合初学者修炼。"
	basic_sword.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic_sword.weapon_type = MartialArtData.WeaponType.SWORD
	basic_sword.school = MartialArtData.SchoolType.GENERIC
	basic_sword.grade = MartialArtData.GradeType.COMMON
	basic_sword.unlock_level = 1
	basic_sword.damage_base = 50.0
	basic_sword.damage_scale = 1.0
	basic_sword.hit_count = 1
	basic_sword.element_type = "无"
	basic_sword.cost_stamina = 10.0
	basic_sword.cost_mana = 10.0
	basic_sword.cooldown = 3.0
	basic_sword.startup_frames = 0.2
	basic_sword.active_frames = 0.5
	basic_sword.recovery_frames = 0.3
	basic_sword.total_duration = 1.0
	basic_sword.can_cancel_from_frame = 0.6
	basic_sword.combo_chain = ["generic_basic_sword"]
	ResourceSaver.save(basic_sword, OUTPUT_DIR + "generic_basic_sword.tres")
	print("  ✓ 基础剑法")
	
	# 基础拳法（黄阶）
	var basic_fist = MartialArtData.new()
	basic_fist.id = "generic_basic_fist"
	basic_fist.name = "基础拳法"
	basic_fist.description = "最基础的拳法，适合初学者修炼。"
	basic_fist.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic_fist.weapon_type = MartialArtData.WeaponType.FIST
	basic_fist.school = MartialArtData.SchoolType.GENERIC
	basic_fist.grade = MartialArtData.GradeType.COMMON
	basic_fist.unlock_level = 1
	basic_fist.damage_base = 45.0
	basic_fist.damage_scale = 1.0
	basic_fist.hit_count = 2
	basic_fist.element_type = "无"
	basic_fist.cost_stamina = 8.0
	basic_fist.cost_mana = 8.0
	basic_fist.cooldown = 2.5
	basic_fist.startup_frames = 0.15
	basic_fist.active_frames = 0.4
	basic_fist.recovery_frames = 0.25
	basic_fist.total_duration = 0.8
	basic_fist.can_cancel_from_frame = 0.5
	basic_fist.combo_chain = ["generic_basic_fist"]
	ResourceSaver.save(basic_fist, OUTPUT_DIR + "generic_basic_fist.tres")
	print("  ✓ 基础拳法")
	
	# 轻功（黄阶）
	var qinggong = MartialArtData.new()
	qinggong.id = "generic_qinggong"
	qinggong.name = "轻功"
	qinggong.description = "基础轻功，可以快速移动。"
	qinggong.martial_art_type = MartialArtData.MartialArtType.MOVEMENT
	qinggong.weapon_type = MartialArtData.WeaponType.NONE
	qinggong.school = MartialArtData.SchoolType.GENERIC
	qinggong.grade = MartialArtData.GradeType.COMMON
	qinggong.unlock_level = 5
	qinggong.damage_base = 0.0
	qinggong.damage_scale = 0.0
	qinggong.hit_count = 0
	qinggong.element_type = "无"
	qinggong.cost_stamina = 15.0
	qinggong.cost_mana = 5.0
	qinggong.cooldown = 3.0
	qinggong.startup_frames = 0.1
	qinggong.active_frames = 1.0
	qinggong.recovery_frames = 0.1
	qinggong.total_duration = 1.2
	qinggong.can_cancel_from_frame = -1.0
	ResourceSaver.save(qinggong, OUTPUT_DIR + "generic_qinggong.tres")
	print("  ✓ 轻功")

## 创建天剑盟功法（剑修）
func create_tianjian_martial_arts():
	print("\n创建天剑盟功法...")
	
	# 御剑术（玄阶）
	var yujian = MartialArtData.new()
	yujian.id = "tianjian_yujian"
	yujian.name = "御剑术"
	yujian.description = "天剑盟基础剑法，以内力御剑，剑气纵横。筑基期修士可修炼。"
	yujian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	yujian.weapon_type = MartialArtData.WeaponType.SWORD
	yujian.school = MartialArtData.SchoolType.GENERIC
	yujian.grade = MartialArtData.GradeType.RARE
	yujian.unlock_level = 23
	yujian.damage_base = 120.0
	yujian.damage_scale = 1.5
	yujian.hit_count = 3
	yujian.element_type = "金"
	yujian.cost_stamina = 20.0
	yujian.cost_mana = 30.0
	yujian.cooldown = 5.0
	yujian.startup_frames = 0.3
	yujian.active_frames = 0.8
	yujian.recovery_frames = 0.4
	yujian.total_duration = 1.5
	yujian.can_cancel_from_frame = 1.0
	yujian.combo_chain = ["tianjian_jianguang"]
	ResourceSaver.save(yujian, OUTPUT_DIR + "tianjian_yujian.tres")
	print("  ✓ 御剑术")
	
	# 剑气纵横（玄阶上品）
	var jianguang = MartialArtData.new()
	jianguang.id = "tianjian_jianguang"
	jianguang.name = "剑气纵横"
	jianguang.description = "凝聚剑气，纵横四方。可作为御剑术的连招。"
	jianguang.martial_art_type = MartialArtData.MartialArtType.ATTACK
	jianguang.weapon_type = MartialArtData.WeaponType.SWORD
	jianguang.school = MartialArtData.SchoolType.GENERIC
	jianguang.grade = MartialArtData.GradeType.RARE
	jianguang.unlock_level = 30
	jianguang.damage_base = 180.0
	jianguang.damage_scale = 2.0
	jianguang.hit_count = 5
	jianguang.element_type = "金"
	jianguang.cost_stamina = 30.0
	jianguang.cost_mana = 50.0
	jianguang.cooldown = 8.0
	jianguang.startup_frames = 0.4
	jianguang.active_frames = 1.2
	jianguang.recovery_frames = 0.6
	jianguang.total_duration = 2.2
	jianguang.can_cancel_from_frame = -1.0
	ResourceSaver.save(jianguang, OUTPUT_DIR + "tianjian_jianguang.tres")
	print("  ✓ 剑气纵横")
	
	# 天剑九式（地阶上品）
	var tianjian_nine = MartialArtData.new()
	tianjian_nine.id = "tianjian_nine_forms"
	tianjian_nine.name = "天剑九式"
	tianjian_nine.description = "天剑盟不传之秘，共九式剑法，每一式都蕴含天地剑意。金丹期修士可修炼。"
	tianjian_nine.martial_art_type = MartialArtData.MartialArtType.ATTACK
	tianjian_nine.weapon_type = MartialArtData.WeaponType.SWORD
	tianjian_nine.school = MartialArtData.SchoolType.GENERIC
	tianjian_nine.grade = MartialArtData.GradeType.EPIC
	tianjian_nine.unlock_level = 45
	tianjian_nine.damage_base = 350.0
	tianjian_nine.damage_scale = 3.0
	tianjian_nine.hit_count = 9
	tianjian_nine.element_type = "金"
	tianjian_nine.cost_stamina = 50.0
	tianjian_nine.cost_mana = 100.0
	tianjian_nine.cooldown = 15.0
	tianjian_nine.startup_frames = 0.6
	tianjian_nine.active_frames = 2.5
	tianjian_nine.recovery_frames = 1.0
	tianjian_nine.total_duration = 4.1
	tianjian_nine.can_cancel_from_frame = -1.0
	ResourceSaver.save(tianjian_nine, OUTPUT_DIR + "tianjian_nine_forms.tres")
	print("  ✓ 天剑九式")

## 创建少林寺功法（体修）
func create_shaolin_martial_arts():
	print("\n创建少林寺功法...")
	
	# 金刚不坏体（地阶）
	var jingang = MartialArtData.new()
	jingang.id = "shaolin_jingang"
	jingang.name = "金刚不坏体"
	jingang.description = "少林七十二绝技之一，修炼至大成可刀枪不入。"
	jingang.martial_art_type = MartialArtData.MartialArtType.DEFENSE
	jingang.weapon_type = MartialArtData.WeaponType.NONE
	jingang.school = MartialArtData.SchoolType.SHAOLIN
	jingang.grade = MartialArtData.GradeType.EPIC
	jingang.unlock_level = 45
	jingang.damage_base = 0.0
	jingang.damage_scale = 0.0
	jingang.hit_count = 0
	jingang.element_type = "无"
	jingang.cost_stamina = 30.0
	jingang.cost_mana = 60.0
	jingang.cooldown = 20.0
	jingang.startup_frames = 0.3
	jingang.active_frames = 10.0
	jingang.recovery_frames = 0.2
	jingang.total_duration = 10.5
	jingang.can_cancel_from_frame = -1.0
	ResourceSaver.save(jingang, OUTPUT_DIR + "shaolin_jingang.tres")
	print("  ✓ 金刚不坏体")
	
	# 易筋经（天阶下品）
	var yijin = MartialArtData.new()
	yijin.id = "shaolin_yijin"
	yijin.name = "易筋经"
	yijin.description = "少林镇寺之宝，佛门至高心法，可改易筋骨，脱胎换骨。元婴期修士可修炼。"
	yijin.martial_art_type = MartialArtData.MartialArtType.BUFF
	yijin.weapon_type = MartialArtData.WeaponType.NONE
	yijin.school = MartialArtData.SchoolType.SHAOLIN
	yijin.grade = MartialArtData.GradeType.LEGENDARY
	yijin.unlock_level = 67
	yijin.damage_base = 0.0
	yijin.damage_scale = 0.0
	yijin.hit_count = 0
	yijin.element_type = "无"
	yijin.cost_stamina = 50.0
	yijin.cost_mana = 150.0
	yijin.cooldown = 60.0
	yijin.startup_frames = 1.0
	yijin.active_frames = 30.0
	yijin.recovery_frames = 1.0
	yijin.total_duration = 32.0
	yijin.can_cancel_from_frame = -1.0
	ResourceSaver.save(yijin, OUTPUT_DIR + "shaolin_yijin.tres")
	print("  ✓ 易筋经")

## 创建武当派功法（道修）
func create_wudang_martial_arts():
	print("\n创建武当派功法...")
	
	# 两仪剑法（地阶）
	var liangyi = MartialArtData.new()
	liangyi.id = "wudang_liangyi"
	liangyi.name = "两仪剑法"
	liangyi.description = "武当派剑法，阴阳相济，刚柔并济。"
	liangyi.martial_art_type = MartialArtData.MartialArtType.ATTACK
	liangyi.weapon_type = MartialArtData.WeaponType.SWORD
	liangyi.school = MartialArtData.SchoolType.WUDANG
	liangyi.grade = MartialArtData.GradeType.EPIC
	liangyi.unlock_level = 48
	liangyi.damage_base = 280.0
	liangyi.damage_scale = 2.3
	liangyi.hit_count = 6
	liangyi.element_type = "无"
	liangyi.cost_stamina = 35.0
	liangyi.cost_mana = 70.0
	liangyi.cooldown = 10.0
	liangyi.startup_frames = 0.5
	liangyi.active_frames = 1.8
	liangyi.recovery_frames = 0.7
	liangyi.total_duration = 3.0
	liangyi.can_cancel_from_frame = -1.0
	ResourceSaver.save(liangyi, OUTPUT_DIR + "wudang_liangyi.tres")
	print("  ✓ 两仪剑法")
	
	# 太极玄功（天阶中品）
	var taiji = MartialArtData.new()
	taiji.id = "wudang_taiji"
	taiji.name = "太极玄功"
	taiji.description = "武当派至高心法，阴阳调和，道法自然。化神期修士可修炼。"
	taiji.martial_art_type = MartialArtData.MartialArtType.BUFF
	taiji.weapon_type = MartialArtData.WeaponType.NONE
	taiji.school = MartialArtData.SchoolType.WUDANG
	taiji.grade = MartialArtData.GradeType.LEGENDARY
	taiji.unlock_level = 89
	taiji.damage_base = 0.0
	taiji.damage_scale = 0.0
	taiji.hit_count = 0
	taiji.element_type = "无"
	taiji.cost_stamina = 60.0
	taiji.cost_mana = 200.0
	taiji.cooldown = 90.0
	taiji.startup_frames = 1.5
	taiji.active_frames = 60.0
	taiji.recovery_frames = 1.5
	taiji.total_duration = 63.0
	taiji.can_cancel_from_frame = -1.0
	ResourceSaver.save(taiji, OUTPUT_DIR + "wudang_taiji.tres")
	print("  ✓ 太极玄功")

## 创建丐帮功法（掌法）
func create_gaibang_martial_arts():
	print("\n创建丐帮功法...")
	
	# 打狗棒法（玄阶）
	var dagou = MartialArtData.new()
	dagou.id = "gaibang_dagou"
	dagou.name = "打狗棒法"
	dagou.description = "丐帮帮主代代相传的棍法，共三十六路，变化莫测。"
	dagou.martial_art_type = MartialArtData.MartialArtType.ATTACK
	dagou.weapon_type = MartialArtData.WeaponType.STAFF
	dagou.school = MartialArtData.SchoolType.GENERIC
	dagou.grade = MartialArtData.GradeType.RARE
	dagou.unlock_level = 28
	dagou.damage_base = 150.0
	dagou.damage_scale = 1.6
	dagou.hit_count = 4
	dagou.element_type = "无"
	dagou.cost_stamina = 25.0
	dagou.cost_mana = 35.0
	dagou.cooldown = 7.0
	dagou.startup_frames = 0.4
	dagou.active_frames = 1.0
	dagou.recovery_frames = 0.5
	dagou.total_duration = 1.9
	dagou.can_cancel_from_frame = -1.0
	ResourceSaver.save(dagou, OUTPUT_DIR + "gaibang_dagou.tres")
	print("  ✓ 打狗棒法")
	
	# 降龙十八掌（地阶上品）
	var xianglong = MartialArtData.new()
	xianglong.id = "gaibang_xianglong"
	xianglong.name = "降龙十八掌"
	xianglong.description = "丐帮至高掌法，刚猛无俦，天下第一掌法。"
	xianglong.martial_art_type = MartialArtData.MartialArtType.ATTACK
	xianglong.weapon_type = MartialArtData.WeaponType.FIST
	xianglong.school = MartialArtData.SchoolType.GENERIC
	xianglong.grade = MartialArtData.GradeType.EPIC
	xianglong.unlock_level = 52
	xianglong.damage_base = 400.0
	xianglong.damage_scale = 3.5
	xianglong.hit_count = 18
	xianglong.element_type = "无"
	xianglong.cost_stamina = 60.0
	xianglong.cost_mana = 120.0
	xianglong.cooldown = 18.0
	xianglong.startup_frames = 0.8
	xianglong.active_frames = 3.0
	xianglong.recovery_frames = 1.2
	xianglong.total_duration = 5.0
	xianglong.can_cancel_from_frame = -1.0
	ResourceSaver.save(xianglong, OUTPUT_DIR + "gaibang_xianglong.tres")
	print("  ✓ 降龙十八掌")