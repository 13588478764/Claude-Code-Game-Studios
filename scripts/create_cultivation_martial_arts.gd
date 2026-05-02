extends SceneTree

## 修真功法数据生成工具
## 根据《武侠奇遇录》世界观设定创建功法
## 
## 设计原则：
## 1. 每个势力5个功法：1黄阶 + 2玄阶 + 1地阶 + 1天阶
## 2. 黄阶：Lv1-22（炼气期）
## 3. 玄阶：Lv23-44（筑基期）
## 4. 地阶：Lv45-66（金丹期）
## 5. 天阶：Lv67-99（元婴期-化神期）
## 6. 符合门派修真特色和元素属性

const OUTPUT_DIR = "res://data/martial_arts/"

func _init():
	print("=== 开始创建修真功法数据 ===")
	print("基于《武侠奇遇录》世界观设定\n")
	
	# 确保输出目录存在
	var dir_path = OUTPUT_DIR.replace("res://", "")
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	# 创建通用功法（新手功法）
	create_generic_martial_arts()
	
	# 创建九大势力功法
	create_tianjian_martial_arts()   # 天剑盟（剑修宗门）
	create_mojiao_martial_arts()     # 魔教（血炼宗门）
	create_shaolin_martial_arts()    # 少林寺（体修宗门）
	create_wudang_martial_arts()     # 武当派（阴阳修士）
	create_gaibang_martial_arts()    # 丐帮（散修联盟）
	create_tangmen_martial_arts()    # 唐门（机关炼器）
	create_mingjiao_martial_arts()   # 明教（火修宗门）
	create_wudu_martial_arts()       # 五毒教（毒修蛊修）
	create_xiaoyao_martial_arts()    # 逍遥派（全能修士）
	
	print("\n=== 功法数据创建完成！===")
	print("共创建了 48 个修真功法")
	print("位置: " + OUTPUT_DIR)
	
	quit()

## 创建通用功法（新手功法）- 3个
func create_generic_martial_arts():
	print("创建通用功法（新手功法）...")
	
	# 基础剑法（黄阶）
	var basic_sword = MartialArtData.new()
	basic_sword.id = "generic_basic_sword"
	basic_sword.name = "基础剑法"
	basic_sword.description = "最基础的剑法，适合炼气期修士入门修炼。以灵气御剑，剑随心动。"
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
	basic_sword.combo_chain.append("generic_basic_sword")
	ResourceSaver.save(basic_sword, OUTPUT_DIR + "generic_basic_sword.tres")
	print("  ✓ 基础剑法 (黄阶)")
	
	# 基础拳法（黄阶）
	var basic_fist = MartialArtData.new()
	basic_fist.id = "generic_basic_fist"
	basic_fist.name = "基础拳法"
	basic_fist.description = "最基础的拳法，适合炼气期修士修炼。以内力催动拳劲，刚猛有力。"
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
	basic_fist.combo_chain.append("generic_basic_fist")
	ResourceSaver.save(basic_fist, OUTPUT_DIR + "generic_basic_fist.tres")
	print("  ✓ 基础拳法 (黄阶)")
	
	# 轻功（黄阶）
	var qinggong = MartialArtData.new()
	qinggong.id = "generic_qinggong"
	qinggong.name = "轻功"
	qinggong.description = "基础身法，炼气期修士可修炼。以灵气托身，身轻如燕。"
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
	print("  ✓ 轻功 (黄阶)")

## 创建天剑盟功法（剑修宗门 - 金属性）- 5个
func create_tianjian_martial_arts():
	print("\n创建天剑盟功法（剑修宗门）...")
	
	# 1. 天剑入门剑诀（黄阶）
	var basic = MartialArtData.new()
	basic.id = "tianjian_basic"
	basic.name = "天剑入门剑诀"
	basic.description = "天剑盟入门剑法，炼气期修士可修炼。以金属性灵气御剑，剑气初显。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.SWORD
	basic.school = MartialArtData.SchoolType.TIANJIAN
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
	print("  ✓ 天剑入门剑诀 (黄阶)")
	
	# 2. 御剑术（玄阶）
	var yujian = MartialArtData.new()
	yujian.id = "tianjian_yujian"
	yujian.name = "御剑术"
	yujian.description = "天剑盟核心剑法，筑基期修士可修炼。以神识御剑，剑气纵横三尺。"
	yujian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	yujian.weapon_type = MartialArtData.WeaponType.SWORD
	yujian.school = MartialArtData.SchoolType.TIANJIAN
	yujian.grade = MartialArtData.GradeType.RARE
	yujian.unlock_level = 25
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
	yujian.combo_chain.append("tianjian_jianguang")
	ResourceSaver.save(yujian, OUTPUT_DIR + "tianjian_yujian.tres")
	print("  ✓ 御剑术 (玄阶)")
	
	# 3. 剑气纵横（玄阶上品）
	var jianguang = MartialArtData.new()
	jianguang.id = "tianjian_jianguang"
	jianguang.name = "剑气纵横"
	jianguang.description = "天剑盟高级剑法，筑基后期修士可修炼。凝聚剑气，纵横四方，剑气可达十丈。"
	jianguang.martial_art_type = MartialArtData.MartialArtType.ATTACK
	jianguang.weapon_type = MartialArtData.WeaponType.SWORD
	jianguang.school = MartialArtData.SchoolType.TIANJIAN
	jianguang.grade = MartialArtData.GradeType.RARE
	jianguang.unlock_level = 35
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
	print("  ✓ 剑气纵横 (玄阶)")
	
	# 4. 天剑九式（地阶上品）
	var nine_forms = MartialArtData.new()
	nine_forms.id = "tianjian_nine_forms"
	nine_forms.name = "天剑九式"
	nine_forms.description = "天剑盟不传之秘，金丹期修士可修炼。共九式剑法，每一式都蕴含天地剑意，剑气可破金丹。"
	nine_forms.martial_art_type = MartialArtData.MartialArtType.ATTACK
	nine_forms.weapon_type = MartialArtData.WeaponType.SWORD
	nine_forms.school = MartialArtData.SchoolType.TIANJIAN
	nine_forms.grade = MartialArtData.GradeType.EPIC
	nine_forms.unlock_level = 50
	nine_forms.damage_base = 350.0
	nine_forms.damage_scale = 3.0
	nine_forms.hit_count = 9
	nine_forms.element_type = "金"
	nine_forms.cost_stamina = 50.0
	nine_forms.cost_mana = 100.0
	nine_forms.cooldown = 15.0
	nine_forms.startup_frames = 0.6
	nine_forms.active_frames = 2.5
	nine_forms.recovery_frames = 1.0
	nine_forms.total_duration = 4.1
	nine_forms.can_cancel_from_frame = -1.0
	ResourceSaver.save(nine_forms, OUTPUT_DIR + "tianjian_nine_forms.tres")
	print("  ✓ 天剑九式 (地阶)")
	
	# 5. 万剑归宗（天阶上品）
	var wanjian = MartialArtData.new()
	wanjian.id = "tianjian_wanjian"
	wanjian.name = "万剑归宗"
	wanjian.description = "天剑盟至高剑法，元婴期以上修士可修炼。召唤万剑齐发，剑意通天，可斩元婴。需领悟剑道法则。"
	wanjian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	wanjian.weapon_type = MartialArtData.WeaponType.SWORD
	wanjian.school = MartialArtData.SchoolType.TIANJIAN
	wanjian.grade = MartialArtData.GradeType.LEGENDARY
	wanjian.unlock_level = 80
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

## 创建魔教功法（血炼宗门 - 煞气/暗属性）- 5个
func create_mojiao_martial_arts():
	print("\n创建魔教功法（血炼宗门）...")
	
	# 1. 血煞入门功（黄阶）
	var basic = MartialArtData.new()
	basic.id = "mojiao_basic"
	basic.name = "血煞入门功"
	basic.description = "魔教入门功法，炼气期修士可修炼。吸收煞气入体，以血炼体。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.FIST
	basic.school = MartialArtData.SchoolType.MOJIAO
	basic.grade = MartialArtData.GradeType.COMMON
	basic.unlock_level = 12
	basic.damage_base = 65.0
	basic.damage_scale = 1.05
	basic.hit_count = 2
	basic.element_type = "暗"
	basic.cost_stamina = 11.0
	basic.cost_mana = 14.0
	basic.cooldown = 3.2
	basic.startup_frames = 0.22
	basic.active_frames = 0.55
	basic.recovery_frames = 0.33
	basic.total_duration = 1.1
	basic.can_cancel_from_frame = 0.65
	basic.combo_chain.append("mojiao_xuemo")
	ResourceSaver.save(basic, OUTPUT_DIR + "mojiao_basic.tres")
	print("  ✓ 血煞入门功 (黄阶)")
	
	# 2. 血魔爪（玄阶）
	var xuemo = MartialArtData.new()
	xuemo.id = "mojiao_xuemo"
	xuemo.name = "血魔爪"
	xuemo.description = "魔教爪法，筑基期修士可修炼。以煞气凝聚血爪，可吸取敌人精血。"
	xuemo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	xuemo.weapon_type = MartialArtData.WeaponType.FIST
	xuemo.school = MartialArtData.SchoolType.MOJIAO
	xuemo.grade = MartialArtData.GradeType.RARE
	xuemo.unlock_level = 28
	xuemo.damage_base = 130.0
	xuemo.damage_scale = 1.6
	xuemo.hit_count = 3
	xuemo.element_type = "暗"
	xuemo.cost_stamina = 25.0
	xuemo.cost_mana = 35.0
	xuemo.cooldown = 6.0
	xuemo.startup_frames = 0.32
	xuemo.active_frames = 0.9
	xuemo.recovery_frames = 0.48
	xuemo.total_duration = 1.7
	xuemo.can_cancel_from_frame = -1.0
	ResourceSaver.save(xuemo, OUTPUT_DIR + "mojiao_xuemo.tres")
	print("  ✓ 血魔爪 (玄阶)")
	
	# 3. 噬魂诀（玄阶上品）
	var shihun = MartialArtData.new()
	shihun.id = "mojiao_shihun"
	shihun.name = "噬魂诀"
	shihun.description = "魔教禁术，筑基后期修士可修炼。以神识攻击敌人元神，可削弱敌人战力。"
	shihun.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	shihun.weapon_type = MartialArtData.WeaponType.NONE
	shihun.school = MartialArtData.SchoolType.MOJIAO
	shihun.grade = MartialArtData.GradeType.RARE
	shihun.unlock_level = 38
	shihun.damage_base = 90.0
	shihun.damage_scale = 1.0
	shihun.hit_count = 1
	shihun.element_type = "暗"
	shihun.cost_stamina = 20.0
	shihun.cost_mana = 60.0
	shihun.cooldown = 15.0
	shihun.startup_frames = 0.5
	shihun.active_frames = 10.0
	shihun.recovery_frames = 0.5
	shihun.total_duration = 11.0
	shihun.can_cancel_from_frame = -1.0
	ResourceSaver.save(shihun, OUTPUT_DIR + "mojiao_shihun.tres")
	print("  ✓ 噬魂诀 (玄阶)")
	
	# 4. 血魔大法（地阶中品）
	var dafa = MartialArtData.new()
	dafa.id = "mojiao_dafa"
	dafa.name = "血魔大法"
	dafa.description = "魔教镇教功法，金丹期修士可修炼。以血炼体，以煞养魂，可大幅提升战力。"
	dafa.martial_art_type = MartialArtData.MartialArtType.BUFF
	dafa.weapon_type = MartialArtData.WeaponType.NONE
	dafa.school = MartialArtData.SchoolType.MOJIAO
	dafa.grade = MartialArtData.GradeType.EPIC
	dafa.unlock_level = 55
	dafa.damage_base = 0.0
	dafa.damage_scale = 0.0
	dafa.hit_count = 0
	dafa.element_type = "暗"
	dafa.cost_stamina = 40.0
	dafa.cost_mana = 120.0
	dafa.cooldown = 60.0
	dafa.startup_frames = 1.0
	dafa.active_frames = 30.0
	dafa.recovery_frames = 1.0
	dafa.total_duration = 32.0
	dafa.can_cancel_from_frame = -1.0
	ResourceSaver.save(dafa, OUTPUT_DIR + "mojiao_dafa.tres")
	print("  ✓ 血魔大法 (地阶)")
	
	# 5. 天魔解体（天阶下品）
	var jie_ti = MartialArtData.new()
	jie_ti.id = "mojiao_jie_ti"
	jie_ti.name = "天魔解体"
	jie_ti.description = "魔教禁忌秘法，元婴期以上修士可修炼。燃烧精血和元婴，短时间内获得恐怖战力，但会损伤根基。"
	jie_ti.martial_art_type = MartialArtData.MartialArtType.BUFF
	jie_ti.weapon_type = MartialArtData.WeaponType.NONE
	jie_ti.school = MartialArtData.SchoolType.MOJIAO
	jie_ti.grade = MartialArtData.GradeType.LEGENDARY
	jie_ti.unlock_level = 75
	jie_ti.damage_base = 0.0
	jie_ti.damage_scale = 0.0
	jie_ti.hit_count = 0
	jie_ti.element_type = "暗"
	jie_ti.cost_stamina = 80.0
	jie_ti.cost_mana = 250.0
	jie_ti.cooldown = 180.0
	jie_ti.startup_frames = 1.5
	jie_ti.active_frames = 20.0
	jie_ti.recovery_frames = 2.0
	jie_ti.total_duration = 23.5
	jie_ti.can_cancel_from_frame = -1.0
	ResourceSaver.save(jie_ti, OUTPUT_DIR + "mojiao_jie_ti.tres")
	print("  ✓ 天魔解体 (天阶)")

## 创建少林寺功法（体修宗门 - 无属性/佛门）- 5个
func create_shaolin_martial_arts():
	print("\n创建少林寺功法（体修宗门）...")
	
	# 1. 罗汉拳（黄阶）
	var luohan = MartialArtData.new()
	luohan.id = "shaolin_luohan"
	luohan.name = "罗汉拳"
	luohan.description = "少林基础拳法，炼气期修士可修炼。刚猛有力，是少林弟子的入门功夫。"
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
	
	# 2. 大力金刚掌（玄阶）
	var dali = MartialArtData.new()
	dali.id = "shaolin_dali"
	dali.name = "大力金刚掌"
	dali.description = "少林七十二绝技之一，筑基期修士可修炼。掌力刚猛，可开山裂石。"
	dali.martial_art_type = MartialArtData.MartialArtType.ATTACK
	dali.weapon_type = MartialArtData.WeaponType.FIST
	dali.school = MartialArtData.SchoolType.SHAOLIN
	dali.grade = MartialArtData.GradeType.RARE
	dali.unlock_level = 30
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
	
	# 3. 龙爪手（玄阶）
	var longzhao = MartialArtData.new()
	longzhao.id = "shaolin_longzhao"
	longzhao.name = "龙爪手"
	longzhao.description = "少林擒拿功夫，筑基期修士可修炼。手如龙爪，可擒拿敌人，封锁经脉。"
	longzhao.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	longzhao.weapon_type = MartialArtData.WeaponType.FIST
	longzhao.school = MartialArtData.SchoolType.SHAOLIN
	longzhao.grade = MartialArtData.GradeType.RARE
	longzhao.unlock_level = 32
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
	
	# 4. 金刚不坏体（地阶）
	var jingang = MartialArtData.new()
	jingang.id = "shaolin_jingang"
	jingang.name = "金刚不坏体"
	jingang.description = "少林七十二绝技之一，金丹期修士可修炼。修炼至大成可刀枪不入，金丹不破。"
	jingang.martial_art_type = MartialArtData.MartialArtType.DEFENSE
	jingang.weapon_type = MartialArtData.WeaponType.NONE
	jingang.school = MartialArtData.SchoolType.SHAOLIN
	jingang.grade = MartialArtData.GradeType.EPIC
	jingang.unlock_level = 52
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
	print("  ✓ 金刚不坏体 (地阶)")
	
	# 5. 易筋经（天阶下品）
	var yijin = MartialArtData.new()
	yijin.id = "shaolin_yijin"
	yijin.name = "易筋经"
	yijin.description = "少林镇寺之宝，元婴期以上修士可修炼。佛门至高心法，可改易筋骨，脱胎换骨，延寿千年。"
	yijin.martial_art_type = MartialArtData.MartialArtType.BUFF
	yijin.weapon_type = MartialArtData.WeaponType.NONE
	yijin.school = MartialArtData.SchoolType.SHAOLIN
	yijin.grade = MartialArtData.GradeType.LEGENDARY
	yijin.unlock_level = 70
	yijin.damage_base = 0.0
	yijin.damage_scale = 0.0
	yijin.hit_count = 0
	yijin.element_type = "光"
	yijin.cost_stamina = 50.0
	yijin.cost_mana = 150.0
	yijin.cooldown = 60.0
	yijin.startup_frames = 1.0
	yijin.active_frames = 30.0
	yijin.recovery_frames = 1.0
	yijin.total_duration = 32.0
	yijin.can_cancel_from_frame = -1.0
	ResourceSaver.save(yijin, OUTPUT_DIR + "shaolin_yijin.tres")
	print("  ✓ 易筋经 (天阶)")

## 创建武当派功法（阴阳修士 - 无属性/阴阳）- 5个
func create_wudang_martial_arts():
	print("\n创建武当派功法（阴阳修士）...")
	
	# 1. 武当基础剑法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "wudang_basic"
	basic.name = "武当基础剑法"
	basic.description = "武当派入门剑法，炼气期修士可修炼。讲究以柔克刚，四两拨千斤。"
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
	
	# 2. 太极拳（玄阶）
	var taijiquan = MartialArtData.new()
	taijiquan.id = "wudang_taijiquan"
	taijiquan.name = "太极拳"
	taijiquan.description = "武当派拳法，筑基期修士可修炼。以柔克刚，绵里藏针，阴阳调和。"
	taijiquan.martial_art_type = MartialArtData.MartialArtType.ATTACK
	taijiquan.weapon_type = MartialArtData.WeaponType.FIST
	taijiquan.school = MartialArtData.SchoolType.WUDANG
	taijiquan.grade = MartialArtData.GradeType.RARE
	taijiquan.unlock_level = 29
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
	
	# 3. 真武七截阵（玄阶）
	var zhenwu = MartialArtData.new()
	zhenwu.id = "wudang_zhenwu"
	zhenwu.name = "真武七截阵"
	zhenwu.description = "武当派阵法，筑基期修士可修炼。七人合力，威力倍增，可提升队友战力。"
	zhenwu.martial_art_type = MartialArtData.MartialArtType.BUFF
	zhenwu.weapon_type = MartialArtData.WeaponType.NONE
	zhenwu.school = MartialArtData.SchoolType.WUDANG
	zhenwu.grade = MartialArtData.GradeType.RARE
	zhenwu.unlock_level = 34
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
	
	# 4. 两仪剑法（地阶）
	var liangyi = MartialArtData.new()
	liangyi.id = "wudang_liangyi"
	liangyi.name = "两仪剑法"
	liangyi.description = "武当派剑法，金丹期修士可修炼。阴阳相济，刚柔并济，剑意通玄。"
	liangyi.martial_art_type = MartialArtData.MartialArtType.ATTACK
	liangyi.weapon_type = MartialArtData.WeaponType.SWORD
	liangyi.school = MartialArtData.SchoolType.WUDANG
	liangyi.grade = MartialArtData.GradeType.EPIC
	liangyi.unlock_level = 54
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
	print("  ✓ 两仪剑法 (地阶)")
	
	# 5. 太极玄功（天阶中品）
	var taiji = MartialArtData.new()
	taiji.id = "wudang_taiji"
	taiji.name = "太极玄功"
	taiji.description = "武当派至高心法，化神期修士可修炼。阴阳调和，道法自然，可领悟阴阳法则，延寿三千年。"
	taiji.martial_art_type = MartialArtData.MartialArtType.BUFF
	taiji.weapon_type = MartialArtData.WeaponType.NONE
	taiji.school = MartialArtData.SchoolType.WUDANG
	taiji.grade = MartialArtData.GradeType.LEGENDARY
	taiji.unlock_level = 90
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
	print("  ✓ 太极玄功 (天阶)")

## 创建丐帮功法（散修联盟 - 无属性）- 5个
func create_gaibang_martial_arts():
	print("\n创建丐帮功法（散修联盟）...")
	
	# 1. 丐帮基础棍法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "gaibang_basic"
	basic.name = "丐帮基础棍法"
	basic.description = "丐帮弟子入门棍法，炼气期修士可修炼。简单实用，适合散修。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.STAFF
	basic.school = MartialArtData.SchoolType.GAIBANG
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
	
	# 2. 打狗棒法（玄阶）
	var dagou = MartialArtData.new()
	dagou.id = "gaibang_dagou"
	dagou.name = "打狗棒法"
	dagou.description = "丐帮帮主代代相传的棍法，筑基期修士可修炼。共三十六路，变化莫测。"
	dagou.martial_art_type = MartialArtData.MartialArtType.ATTACK
	dagou.weapon_type = MartialArtData.WeaponType.STAFF
	dagou.school = MartialArtData.SchoolType.GAIBANG
	dagou.grade = MartialArtData.GradeType.RARE
	dagou.unlock_level = 27
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
	print("  ✓ 打狗棒法 (玄阶)")
	
	# 3. 逍遥游掌（玄阶）
	var xiaoyaoyou = MartialArtData.new()
	xiaoyaoyou.id = "gaibang_xiaoyaoyou"
	xiaoyaoyou.name = "逍遥游掌"
	xiaoyaoyou.description = "丐帮掌法，筑基期修士可修炼。掌法飘逸，如行云流水。"
	xiaoyaoyou.martial_art_type = MartialArtData.MartialArtType.ATTACK
	xiaoyaoyou.weapon_type = MartialArtData.WeaponType.FIST
	xiaoyaoyou.school = MartialArtData.SchoolType.GAIBANG
	xiaoyaoyou.grade = MartialArtData.GradeType.RARE
	xiaoyaoyou.unlock_level = 33
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
	
	# 4. 降龙十八掌（地阶上品）
	var xianglong = MartialArtData.new()
	xianglong.id = "gaibang_xianglong"
	xianglong.name = "降龙十八掌"
	xianglong.description = "丐帮至高掌法，金丹期修士可修炼。刚猛无俦，天下第一掌法，掌力可降龙。"
	xianglong.martial_art_type = MartialArtData.MartialArtType.ATTACK
	xianglong.weapon_type = MartialArtData.WeaponType.FIST
	xianglong.school = MartialArtData.SchoolType.GAIBANG
	xianglong.grade = MartialArtData.GradeType.EPIC
	xianglong.unlock_level = 58
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
	print("  ✓ 降龙十八掌 (地阶)")
	
	# 5. 天下无狗（天阶）
	var tianxia = MartialArtData.new()
	tianxia.id = "gaibang_tianxia"
	tianxia.name = "天下无狗"
	tianxia.description = "丐帮至高绝学，元婴期以上修士可修炼。打狗棒法的终极奥义，棍意通天，可破元婴。"
	tianxia.martial_art_type = MartialArtData.MartialArtType.ATTACK
	tianxia.weapon_type = MartialArtData.WeaponType.STAFF
	tianxia.school = MartialArtData.SchoolType.GAIBANG
	tianxia.grade = MartialArtData.GradeType.LEGENDARY
	tianxia.unlock_level = 82
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

## 创建唐门功法（机关炼器 - 金/毒属性）- 5个
func create_tangmen_martial_arts():
	print("\n创建唐门功法（机关炼器）...")
	
	# 1. 唐门基础暗器（黄阶）
	var basic = MartialArtData.new()
	basic.id = "tangmen_basic"
	basic.name = "唐门基础暗器"
	basic.description = "唐门入门暗器手法，炼气期修士可修炼。教导弟子如何使用飞针、飞刀等暗器。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.NONE
	basic.school = MartialArtData.SchoolType.TANGMEN
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
	
	# 2. 暴雨梨花针（玄阶）
	var lihua = MartialArtData.new()
	lihua.id = "tangmen_lihua"
	lihua.name = "暴雨梨花针"
	lihua.description = "唐门暗器绝技，筑基期修士可修炼。一次发射数十枚银针，如暴雨梨花，针针带毒。"
	lihua.martial_art_type = MartialArtData.MartialArtType.ATTACK
	lihua.weapon_type = MartialArtData.WeaponType.NONE
	lihua.school = MartialArtData.SchoolType.TANGMEN
	lihua.grade = MartialArtData.GradeType.RARE
	lihua.unlock_level = 26
	lihua.damage_base = 100.0
	lihua.damage_scale = 1.3
	lihua.hit_count = 12
	lihua.element_type = "毒"
	lihua.cost_stamina = 20.0
	lihua.cost_mana = 40.0
	lihua.cooldown = 6.0
	lihua.startup_frames = 0.3
	lihua.active_frames = 1.5
	lihua.recovery_frames = 0.5
	lihua.total_duration = 2.3
	lihua.can_cancel_from_frame = -1.0
	ResourceSaver.save(lihua, OUTPUT_DIR + "tangmen_lihua.tres")
	print("  ✓ 暴雨梨花针 (玄阶)")
	
	# 3. 七星海棠毒（玄阶）
	var qixing = MartialArtData.new()
	qixing.id = "tangmen_qixing"
	qixing.name = "七星海棠毒"
	qixing.description = "唐门剧毒，筑基期修士可修炼。中毒者七日内必死，可削弱敌人防御和恢复能力。"
	qixing.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	qixing.weapon_type = MartialArtData.WeaponType.NONE
	qixing.school = MartialArtData.SchoolType.TANGMEN
	qixing.grade = MartialArtData.GradeType.RARE
	qixing.unlock_level = 31
	qixing.damage_base = 50.0
	qixing.damage_scale = 0.5
	qixing.hit_count = 1
	qixing.element_type = "毒"
	qixing.cost_stamina = 15.0
	qixing.cost_mana = 50.0
	qixing.cooldown = 15.0
	qixing.startup_frames = 0.5
	qixing.active_frames = 20.0
	qixing.recovery_frames = 0.5
	qixing.total_duration = 21.0
	qixing.can_cancel_from_frame = -1.0
	ResourceSaver.save(qixing, OUTPUT_DIR + "tangmen_qixing.tres")
	print("  ✓ 七星海棠毒 (玄阶)")
	
	# 4. 孔雀翎（地阶）
	var kongque = MartialArtData.new()
	kongque.id = "tangmen_kongque"
	kongque.name = "孔雀翎"
	kongque.description = "唐门至宝，金丹期修士可修炼。天下第一暗器，一击必杀，机关精妙，威力无穷。"
	kongque.martial_art_type = MartialArtData.MartialArtType.ATTACK
	kongque.weapon_type = MartialArtData.WeaponType.NONE
	kongque.school = MartialArtData.SchoolType.TANGMEN
	kongque.grade = MartialArtData.GradeType.EPIC
	kongque.unlock_level = 56
	kongque.damage_base = 500.0
	kongque.damage_scale = 4.0
	kongque.hit_count = 1
	kongque.element_type = "金"
	kongque.cost_stamina = 80.0
	kongque.cost_mana = 150.0
	kongque.cooldown = 30.0
	kongque.startup_frames = 1.0
	kongque.active_frames = 0.5
	kongque.recovery_frames = 1.5
	kongque.total_duration = 3.0
	kongque.can_cancel_from_frame = -1.0
	ResourceSaver.save(kongque, OUTPUT_DIR + "tangmen_kongque.tres")
	print("  ✓ 孔雀翎 (地阶)")
	
	# 5. 含沙射影（天阶）
	var hansha = MartialArtData.new()
	hansha.id = "tangmen_hansha"
	hansha.name = "含沙射影"
	hansha.description = "唐门至高暗器绝学，元婴期以上修士可修炼。无形无影，防不胜防，暗器与毒术的完美结合。"
	hansha.martial_art_type = MartialArtData.MartialArtType.ATTACK
	hansha.weapon_type = MartialArtData.WeaponType.NONE
	hansha.school = MartialArtData.SchoolType.TANGMEN
	hansha.grade = MartialArtData.GradeType.LEGENDARY
	hansha.unlock_level = 78
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

## 创建明教功法（火修宗门 - 火属性）- 5个
func create_mingjiao_martial_arts():
	print("\n创建明教功法（火修宗门）...")
	
	# 1. 明教基础刀法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "mingjiao_basic"
	basic.name = "明教基础刀法"
	basic.description = "明教入门刀法，炼气期修士可修炼。刀势刚猛，带有火焰之力。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.BLADE
	basic.school = MartialArtData.SchoolType.MINGJIAO
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
	
	# 2. 烈火刀法（玄阶）
	var liehuo = MartialArtData.new()
	liehuo.id = "mingjiao_liehuo"
	liehuo.name = "烈火刀法"
	liehuo.description = "明教刀法，筑基期修士可修炼。刀势如烈火燎原，势不可挡，火焰灼烧敌人。"
	liehuo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	liehuo.weapon_type = MartialArtData.WeaponType.BLADE
	liehuo.school = MartialArtData.SchoolType.MINGJIAO
	liehuo.grade = MartialArtData.GradeType.RARE
	liehuo.unlock_level = 28
	liehuo.damage_base = 140.0
	liehuo.damage_scale = 1.7
	liehuo.hit_count = 4
	liehuo.element_type = "火"
	liehuo.cost_stamina = 25.0
	liehuo.cost_mana = 35.0
	liehuo.cooldown = 6.0
	liehuo.startup_frames = 0.4
	liehuo.active_frames = 1.0
	liehuo.recovery_frames = 0.5
	liehuo.total_duration = 1.9
	liehuo.can_cancel_from_frame = 1.2
	liehuo.combo_chain.append("mingjiao_shenghuo")
	ResourceSaver.save(liehuo, OUTPUT_DIR + "mingjiao_liehuo.tres")
	print("  ✓ 烈火刀法 (玄阶)")
	
	# 3. 圣火令（玄阶）
	var shenghuo = MartialArtData.new()
	shenghuo.id = "mingjiao_shenghuo"
	shenghuo.name = "圣火令"
	shenghuo.description = "明教圣物，筑基期修士可修炼。可发出圣火攻击敌人，火焰永不熄灭。"
	shenghuo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	shenghuo.weapon_type = MartialArtData.WeaponType.NONE
	shenghuo.school = MartialArtData.SchoolType.MINGJIAO
	shenghuo.grade = MartialArtData.GradeType.RARE
	shenghuo.unlock_level = 36
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
	
	# 4. 焚天煮海（地阶上品）
	var fentian = MartialArtData.new()
	fentian.id = "mingjiao_fentian"
	fentian.name = "焚天煮海"
	fentian.description = "明教火系大招，金丹期修士可修炼。召唤烈焰焚烧一切，火海滔天，可焚金丹。"
	fentian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	fentian.weapon_type = MartialArtData.WeaponType.NONE
	fentian.school = MartialArtData.SchoolType.MINGJIAO
	fentian.grade = MartialArtData.GradeType.EPIC
	fentian.unlock_level = 60
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
	
	# 5. 乾坤大挪移（天阶）
	var qiankun = MartialArtData.new()
	qiankun.id = "mingjiao_qiankun"
	qiankun.name = "乾坤大挪移"
	qiankun.description = "明教镇教神功，化神期修士可修炼。可挪移乾坤，反弹敌人攻击，领悟空间法则。"
	qiankun.martial_art_type = MartialArtData.MartialArtType.DEFENSE
	qiankun.weapon_type = MartialArtData.WeaponType.NONE
	qiankun.school = MartialArtData.SchoolType.MINGJIAO
	qiankun.grade = MartialArtData.GradeType.LEGENDARY
	qiankun.unlock_level = 88
	qiankun.damage_base = 0.0
	qiankun.damage_scale = 0.0
	qiankun.hit_count = 0
	qiankun.element_type = "无"
	qiankun.cost_stamina = 40.0
	qiankun.cost_mana = 180.0
	qiankun.cooldown = 45.0
	qiankun.startup_frames = 0.8
	qiankun.active_frames = 15.0
	qiankun.recovery_frames = 1.0
	qiankun.total_duration = 16.8
	qiankun.can_cancel_from_frame = -1.0
	ResourceSaver.save(qiankun, OUTPUT_DIR + "mingjiao_qiankun.tres")
	print("  ✓ 乾坤大挪移 (天阶)")

## 创建五毒教功法（毒修蛊修 - 毒/木属性）- 5个
func create_wudu_martial_arts():
	print("\n创建五毒教功法（毒修蛊修）...")
	
	# 1. 五毒基础掌法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "wudu_basic"
	basic.name = "五毒基础掌法"
	basic.description = "五毒教入门掌法，炼气期修士可修炼。掌力带有微毒，可侵蚀敌人。"
	basic.martial_art_type = MartialArtData.MartialArtType.ATTACK
	basic.weapon_type = MartialArtData.WeaponType.FIST
	basic.school = MartialArtData.SchoolType.WUDU
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
	
	# 2. 五毒神掌（玄阶）
	var shenzhang = MartialArtData.new()
	shenzhang.id = "wudu_shenzhang"
	shenzhang.name = "五毒神掌"
	shenzhang.description = "五毒教掌法，筑基期修士可修炼。掌力含毒，中者必死，毒入骨髓。"
	shenzhang.martial_art_type = MartialArtData.MartialArtType.ATTACK
	shenzhang.weapon_type = MartialArtData.WeaponType.FIST
	shenzhang.school = MartialArtData.SchoolType.WUDU
	shenzhang.grade = MartialArtData.GradeType.RARE
	shenzhang.unlock_level = 30
	shenzhang.damage_base = 130.0
	shenzhang.damage_scale = 1.5
	shenzhang.hit_count = 5
	shenzhang.element_type = "毒"
	shenzhang.cost_stamina = 30.0
	shenzhang.cost_mana = 45.0
	shenzhang.cooldown = 8.0
	shenzhang.startup_frames = 0.4
	shenzhang.active_frames = 1.2
	shenzhang.recovery_frames = 0.6
	shenzhang.total_duration = 2.2
	shenzhang.can_cancel_from_frame = -1.0
	ResourceSaver.save(shenzhang, OUTPUT_DIR + "wudu_shenzhang.tres")
	print("  ✓ 五毒神掌 (玄阶)")
	
	# 3. 蛇蝎美人（玄阶）
	var shexie = MartialArtData.new()
	shexie.id = "wudu_shexie"
	shexie.name = "蛇蝎美人"
	shexie.description = "五毒教媚功，筑基期修士可修炼。可魅惑敌人，使其失去战斗力，神识混乱。"
	shexie.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	shexie.weapon_type = MartialArtData.WeaponType.NONE
	shexie.school = MartialArtData.SchoolType.WUDU
	shexie.grade = MartialArtData.GradeType.RARE
	shexie.unlock_level = 37
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
	
	# 4. 万蛊噬心（地阶中品）
	var wangu = MartialArtData.new()
	wangu.id = "wudu_wangu"
	wangu.name = "万蛊噬心"
	wangu.description = "五毒教禁术，金丹期修士可修炼。以万蛊噬心，令敌人痛不欲生，持续削弱，蛊毒噬金丹。"
	wangu.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	wangu.weapon_type = MartialArtData.WeaponType.NONE
	wangu.school = MartialArtData.SchoolType.WUDU
	wangu.grade = MartialArtData.GradeType.EPIC
	wangu.unlock_level = 62
	wangu.damage_base = 80.0
	wangu.damage_scale = 1.0
	wangu.hit_count = 1
	wangu.element_type = "毒"
	wangu.cost_stamina = 40.0
	wangu.cost_mana = 100.0
	wangu.cooldown = 25.0
	wangu.startup_frames = 1.0
	wangu.active_frames = 30.0
	wangu.recovery_frames = 1.0
	wangu.total_duration = 32.0
	wangu.can_cancel_from_frame = -1.0
	ResourceSaver.save(wangu, OUTPUT_DIR + "wudu_wangu.tres")
	print("  ✓ 万蛊噬心 (地阶)")
	
	# 5. 毒龙钻（天阶）
	var dulong = MartialArtData.new()
	dulong.id = "wudu_dulong"
	dulong.name = "毒龙钻"
	dulong.description = "五毒教至高绝学，元婴期以上修士可修炼。凝聚万毒之力，化为毒龙攻击，毒龙可破元婴。"
	dulong.martial_art_type = MartialArtData.MartialArtType.ATTACK
	dulong.weapon_type = MartialArtData.WeaponType.NONE
	dulong.school = MartialArtData.SchoolType.WUDU
	dulong.grade = MartialArtData.GradeType.LEGENDARY
	dulong.unlock_level = 85
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

## 创建逍遥派功法（全能修士 - 水/空间属性）- 5个
func create_xiaoyao_martial_arts():
	print("\n创建逍遥派功法（全能修士）...")
	
	# 1. 逍遥基础身法（黄阶）
	var basic = MartialArtData.new()
	basic.id = "xiaoyao_basic"
	basic.name = "逍遥基础身法"
	basic.description = "逍遥派入门身法，炼气期修士可修炼。身形飘逸，来去自如，如履平地。"
	basic.martial_art_type = MartialArtData.MartialArtType.MOVEMENT
	basic.weapon_type = MartialArtData.WeaponType.NONE
	basic.school = MartialArtData.SchoolType.XIAOYAO
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
	
	# 2. 凌波微步（玄阶）
	var lingbo = MartialArtData.new()
	lingbo.id = "xiaoyao_lingbo"
	lingbo.name = "凌波微步"
	lingbo.description = "逍遥派轻功绝学，筑基期修士可修炼。身法飘逸，如履平地，可短距离瞬移。"
	lingbo.martial_art_type = MartialArtData.MartialArtType.MOVEMENT
	lingbo.weapon_type = MartialArtData.WeaponType.NONE
	lingbo.school = MartialArtData.SchoolType.XIAOYAO
	lingbo.grade = MartialArtData.GradeType.RARE
	lingbo.unlock_level = 32
	lingbo.damage_base = 0.0
	lingbo.damage_scale = 0.0
	lingbo.hit_count = 0
	lingbo.element_type = "无"
	lingbo.cost_stamina = 25.0
	lingbo.cost_mana = 30.0
	lingbo.cooldown = 5.0
	lingbo.startup_frames = 0.1
	lingbo.active_frames = 2.0
	lingbo.recovery_frames = 0.1
	lingbo.total_duration = 2.2
	lingbo.can_cancel_from_frame = -1.0
	ResourceSaver.save(lingbo, OUTPUT_DIR + "xiaoyao_lingbo.tres")
	print("  ✓ 凌波微步 (玄阶)")
	
	# 3. 小无相功（玄阶）
	var xiaowuxiang = MartialArtData.new()
	xiaowuxiang.id = "xiaoyao_xiaowuxiang"
	xiaowuxiang.name = "小无相功"
	xiaowuxiang.description = "逍遥派内功，筑基期修士可修炼。可模仿他人武功，无形无相，变化万千。"
	xiaowuxiang.martial_art_type = MartialArtData.MartialArtType.BUFF
	xiaowuxiang.weapon_type = MartialArtData.WeaponType.NONE
	xiaowuxiang.school = MartialArtData.SchoolType.XIAOYAO
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
	
	# 4. 天山六阳掌（地阶）
	var tianshan = MartialArtData.new()
	tianshan.id = "xiaoyao_tianshan"
	tianshan.name = "天山六阳掌"
	tianshan.description = "逍遥派掌法，金丹期修士可修炼。掌力至阳至刚，可破除阴寒之气，掌意通天。"
	tianshan.martial_art_type = MartialArtData.MartialArtType.ATTACK
	tianshan.weapon_type = MartialArtData.WeaponType.FIST
	tianshan.school = MartialArtData.SchoolType.XIAOYAO
	tianshan.grade = MartialArtData.GradeType.EPIC
	tianshan.unlock_level = 64
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
	
	# 5. 北冥神功（天阶上品）
	var beiming = MartialArtData.new()
	beiming.id = "xiaoyao_beiming"
	beiming.name = "北冥神功"
	beiming.description = "逍遥派至高心法，元婴期以上修士可修炼。可吸取他人内力为己用，领悟水之法则，延寿五千年。"
	beiming.martial_art_type = MartialArtData.MartialArtType.BUFF
	beiming.weapon_type = MartialArtData.WeaponType.NONE
	beiming.school = MartialArtData.SchoolType.XIAOYAO
	beiming.grade = MartialArtData.GradeType.LEGENDARY
	beiming.unlock_level = 92
	beiming.damage_base = 0.0
	beiming.damage_scale = 0.0
	beiming.hit_count = 0
	beiming.element_type = "水"
	beiming.cost_stamina = 50.0
	beiming.cost_mana = 160.0
	beiming.cooldown = 70.0
	beiming.startup_frames = 1.2
	beiming.active_frames = 45.0
	beiming.recovery_frames = 1.2
	beiming.total_duration = 47.4
	beiming.can_cancel_from_frame = -1.0
	ResourceSaver.save(beiming, OUTPUT_DIR + "xiaoyao_beiming.tres")
	print("  ✓ 北冥神功 (天阶)")