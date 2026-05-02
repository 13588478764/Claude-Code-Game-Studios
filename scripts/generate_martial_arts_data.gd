## 功法数据生成脚本
## 用于生成初始的功法数据资源文件

extends SceneTree

const OUTPUT_DIR = "res://data/martial_arts/"

func _init():
	print("开始生成功法数据...")
	
	# 确保输出目录存在
	if not DirAccess.dir_exists_absolute(OUTPUT_DIR):
		DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	
	# 生成各门派的代表功法
	generate_tianjian_martial_arts()  # 天剑盟
	generate_mojiao_martial_arts()    # 魔教
	generate_shaolin_martial_arts()   # 少林寺
	generate_wudang_martial_arts()    # 武当派
	generate_gaibang_martial_arts()   # 丐帮
	generate_tangmen_martial_arts()   # 唐门
	generate_mingjiao_martial_arts()  # 明教
	generate_wudu_martial_arts()      # 五毒教
	generate_xiaoyao_martial_arts()   # 逍遥派
	generate_generic_martial_arts()   # 通用功法
	
	print("功法数据生成完成！")
	quit()

## 生成天剑盟功法（剑修）
func generate_tianjian_martial_arts():
	print("生成天剑盟功法...")
	
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

## 生成魔教功法（魔修）
func generate_mojiao_martial_arts():
	print("生成魔教功法...")
	
	# 噬魂诀（玄阶）
	var shihun = MartialArtData.new()
	shihun.id = "mojiao_shihun"
	shihun.name = "噬魂诀"
	shihun.description = "魔教基础功法，吸取敌人精气，转化为自身力量。"
	shihun.martial_art_type = MartialArtData.MartialArtType.ATTACK
	shihun.weapon_type = MartialArtData.WeaponType.NONE
	shihun.school = MartialArtData.SchoolType.GENERIC
	shihun.grade = MartialArtData.GradeType.RARE
	shihun.unlock_level = 25
	shihun.damage_base = 100.0
	shihun.damage_scale = 1.8
	shihun.hit_count = 1
	shihun.element_type = "无"
	shihun.cost_stamina = 15.0
	shihun.cost_mana = 40.0
	shihun.cooldown = 6.0
	shihun.startup_frames = 0.5
	shihun.active_frames = 1.0
	shihun.recovery_frames = 0.5
	shihun.total_duration = 2.0
	shihun.can_cancel_from_frame = -1.0
	ResourceSaver.save(shihun, OUTPUT_DIR + "mojiao_shihun.tres")
	
	# 血魔大法（地阶中品）
	var xuemo = MartialArtData.new()
	xuemo.id = "mojiao_xuemo"
	xuemo.name = "血魔大法"
	xuemo.description = "魔教至高功法，以血炼体，以煞养神。金丹期修士可修炼。"
	xuemo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	xuemo.weapon_type = MartialArtData.WeaponType.NONE
	xuemo.school = MartialArtData.SchoolType.GENERIC
	xuemo.grade = MartialArtData.GradeType.EPIC
	xuemo.unlock_level = 50
	xuemo.damage_base = 300.0
	xuemo.damage_scale = 2.5
	xuemo.hit_count = 7
	xuemo.element_type = "无"
	xuemo.cost_stamina = 40.0
	xuemo.cost_mana = 80.0
	xuemo.cooldown = 12.0
	xuemo.startup_frames = 0.8
	xuemo.active_frames = 2.0
	xuemo.recovery_frames = 0.8
	xuemo.total_duration = 3.6
	xuemo.can_cancel_from_frame = -1.0
	ResourceSaver.save(xuemo, OUTPUT_DIR + "mojiao_xuemo.tres")

## 生成少林寺功法（体修）
func generate_shaolin_martial_arts():
	print("生成少林寺功法...")
	
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

## 生成武当派功法（道修）
func generate_wudang_martial_arts():
	print("生成武当派功法...")
	
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

## 生成丐帮功法（掌法）
func generate_gaibang_martial_arts():
	print("生成丐帮功法...")
	
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

## 生成唐门功法（机关毒器）
func generate_tangmen_martial_arts():
	print("生成唐门功法...")
	
	# 傀儡术（玄阶）
	var kuilei = MartialArtData.new()
	kuilei.id = "tangmen_kuilei"
	kuilei.name = "傀儡术"
	kuilei.description = "唐门机关术，操控傀儡作战。"
	kuilei.martial_art_type = MartialArtData.MartialArtType.ATTACK
	kuilei.weapon_type = MartialArtData.WeaponType.NONE
	kuilei.school = MartialArtData.SchoolType.GENERIC
	kuilei.grade = MartialArtData.GradeType.RARE
	kuilei.unlock_level = 32
	kuilei.damage_base = 80.0
	kuilei.damage_scale = 1.2
	kuilei.hit_count = 10
	kuilei.element_type = "无"
	kuilei.cost_stamina = 20.0
	kuilei.cost_mana = 50.0
	kuilei.cooldown = 15.0
	kuilei.startup_frames = 1.0
	kuilei.active_frames = 5.0
	kuilei.recovery_frames = 0.5
	kuilei.total_duration = 6.5
	kuilei.can_cancel_from_frame = -1.0
	ResourceSaver.save(kuilei, OUTPUT_DIR + "tangmen_kuilei.tres")
	
	# 唐门暗器谱（地阶中品）
	var anqi = MartialArtData.new()
	anqi.id = "tangmen_anqi"
	anqi.name = "唐门暗器谱"
	anqi.description = "唐门不传之秘，包含数百种暗器使用之法。"
	anqi.martial_art_type = MartialArtData.MartialArtType.ATTACK
	anqi.weapon_type = MartialArtData.WeaponType.NONE
	anqi.school = MartialArtData.SchoolType.GENERIC
	anqi.grade = MartialArtData.GradeType.EPIC
	anqi.unlock_level = 55
	anqi.damage_base = 250.0
	anqi.damage_scale = 2.2
	anqi.hit_count = 12
	anqi.element_type = "无"
	anqi.cost_stamina = 45.0
	anqi.cost_mana = 90.0
	anqi.cooldown = 14.0
	anqi.startup_frames = 0.6
	anqi.active_frames = 2.5
	anqi.recovery_frames = 0.9
	anqi.total_duration = 4.0
	anqi.can_cancel_from_frame = -1.0
	ResourceSaver.save(anqi, OUTPUT_DIR + "tangmen_anqi.tres")

## 生成明教功法（火修）
func generate_mingjiao_martial_arts():
	print("生成明教功法...")
	
	# 烈焰焚天诀（玄阶）
	var lieyan = MartialArtData.new()
	lieyan.id = "mingjiao_lieyan"
	lieyan.name = "烈焰焚天诀"
	lieyan.description = "明教火系功法，召唤烈焰焚烧敌人。"
	lieyan.martial_art_type = MartialArtData.MartialArtType.ATTACK
	lieyan.weapon_type = MartialArtData.WeaponType.NONE
	lieyan.school = MartialArtData.SchoolType.GENERIC
	lieyan.grade = MartialArtData.GradeType.RARE
	lieyan.unlock_level = 26
	lieyan.damage_base = 140.0
	lieyan.damage_scale = 1.7
	lieyan.hit_count = 3
	lieyan.element_type = "火"
	lieyan.cost_stamina = 18.0
	lieyan.cost_mana = 45.0
	lieyan.cooldown = 6.0
	lieyan.startup_frames = 0.6
	lieyan.active_frames = 1.5
	lieyan.recovery_frames = 0.4
	lieyan.total_duration = 2.5
	lieyan.can_cancel_from_frame = -1.0
	ResourceSaver.save(lieyan, OUTPUT_DIR + "mingjiao_lieyan.tres")
	
	# 圣火令（地阶上品）
	var shenghuo = MartialArtData.new()
	shenghuo.id = "mingjiao_shenghuo"
	shenghuo.name = "圣火令"
	shenghuo.description = "明教至高武学，以圣火之力，焚尽一切。"
	shenghuo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	shenghuo.weapon_type = MartialArtData.WeaponType.NONE
	shenghuo.school = MartialArtData.SchoolType.GENERIC
	shenghuo.grade = MartialArtData.GradeType.EPIC
	shenghuo.unlock_level = 58
	shenghuo.damage_base = 380.0
	shenghuo.damage_scale = 3.2
	shenghuo.hit_count = 8
	shenghuo.element_type = "火"
	shenghuo.cost_stamina = 55.0
	shenghuo.cost_mana = 110.0
	shenghuo.cooldown = 16.0
	shenghuo.startup_frames = 0.9
	shenghuo.active_frames = 2.8
	shenghuo.recovery_frames = 1.0
	shenghuo.total_duration = 4.7
	shenghuo.can_cancel_from_frame = -1.0
	ResourceSaver.save(shenghuo, OUTPUT_DIR + "mingjiao_shenghuo.tres")

## 生成五毒教功法（毒修蛊修）
func generate_wudu_martial_arts():
	print("生成五毒教功法...")
	
	# 万蛊噬心诀（玄阶）
	var wangu = MartialArtData.new()
	wangu.id = "wudu_wangu"
	wangu.name = "万蛊噬心诀"
	wangu.description = "五毒教蛊术，以蛊虫侵蚀敌人心神。"
	wangu.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	wangu.weapon_type = MartialArtData.WeaponType.NONE
	wangu.school = MartialArtData.SchoolType.GENERIC
	wangu.grade = MartialArtData.GradeType.RARE
	wangu.unlock_level = 29
	wangu.damage_base = 60.0
	wangu.damage_scale = 1.0
	wangu.hit_count = 1
	wangu.element_type = "无"
	wangu.cost_stamina = 15.0
	wangu.cost_mana = 55.0
	wangu.cooldown = 12.0
	wangu.startup_frames = 0.8
	wangu.active_frames = 8.0
	wangu.recovery_frames = 0.4
	wangu.total_duration = 9.2
	wangu.can_cancel_from_frame = -1.0
	ResourceSaver.save(wangu, OUTPUT_DIR + "wudu_wangu.tres")
	
	# 五毒神功（地阶中品）
	var wudu = MartialArtData.new()
	wudu.id = "wudu_shengong"
	wudu.name = "五毒神功"
	wudu.description = "五毒教至高功法，融合五种剧毒，威力惊人。"
	wudu.martial_art_type = MartialArtData.MartialArtType.ATTACK
	wudu.weapon_type = MartialArtData.WeaponType.NONE
	wudu.school = MartialArtData.SchoolType.GENERIC
	wudu.grade = MartialArtData.GradeType.EPIC
	wudu.unlock_level = 53
	wudu.damage_base = 280.0
	wudu.damage_scale = 2.4
	wudu.hit_count = 5
	wudu.element_type = "无"
	wudu.cost_stamina = 40.0
	wudu.cost_mana = 85.0
	wudu.cooldown = 13.0
	wudu.startup_frames = 0.7
	wudu.active_frames = 2.2
	wudu.recovery_frames = 0.8
	wudu.total_duration = 3.7
	wudu.can_cancel_from_frame = -1.0
	ResourceSaver.save(wudu, OUTPUT_DIR + "wudu_shengong.tres")

## 生成逍遥派功法（全能）
func generate_xiaoyao_martial_arts():
	print("生成逍遥派功法...")
	
	# 凌波微步（地阶）
	var lingbo = MartialArtData.new()
	lingbo.id = "xiaoyao_lingbo"
	lingbo.name = "凌波微步"
	lingbo.description = "逍遥派轻功绝学，身法飘逸，如履平地。"
	lingbo.martial_art_type = MartialArtData.MartialArtType.MOVEMENT
	lingbo.weapon_type = MartialArtData.WeaponType.NONE
	lingbo.school = MartialArtData.SchoolType.GENERIC
	lingbo.grade = MartialArtData.GradeType.EPIC
	lingbo.unlock_level = 46
	lingbo.damage_base = 0.0
	lingbo.damage_scale = 0.0
	lingbo.hit_count = 0
	lingbo.element_type = "无"
	lingbo.cost_stamina = 25.0
	lingbo.cost_mana = 40.0
	lingbo.cooldown = 5.0
	lingbo.startup_frames = 0.2
	lingbo.active_frames = 3.0
	lingbo.recovery_frames = 0.2
	lingbo.total_duration = 3.4
	lingbo.can_cancel_from_frame = -1.0
	ResourceSaver.save(lingbo, OUTPUT_DIR + "xiaoyao_lingbo.tres")
	
	# 北冥神功（天阶上品）
	var beiming = MartialArtData.new()
	beiming.id = "xiaoyao_beiming"
	beiming.name = "北冥神功"
	beiming.description = "逍遥派至高心法，可吸取他人内力为己用，深不可测。"
	beiming.martial_art_type = MartialArtData.MartialArtType.BUFF
	beiming.weapon_type = MartialArtData.WeaponType.NONE
	beiming.school = MartialArtData.SchoolType.GENERIC
	beiming.grade = MartialArtData.GradeType.LEGENDARY
	beiming.unlock_level = 92
	beiming.damage_base = 0.0
	beiming.damage_scale = 0.0
	beiming.hit_count = 0
	beiming.element_type = "无"
	beiming.cost_stamina = 70.0
	beiming.cost_mana = 250.0
	beiming.cooldown = 120.0
	beiming.startup_frames = 2.0
	beiming.active_frames = 90.0
	beiming.recovery_frames = 2.0
	beiming.total_duration = 94.0
	beiming.can_cancel_from_frame = -1.0
	ResourceSaver.save(beiming, OUTPUT_DIR + "xiaoyao_beiming.tres")

## 生成通用功法（新手功法）
func generate_generic_martial_arts():
	print("生成通用功法...")
	
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