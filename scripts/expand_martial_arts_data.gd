extends SceneTree

## 功法数据扩展工具
## 为其他门派添加更多功法

const OUTPUT_DIR = "res://data/martial_arts/"

func _init():
	print("=== 开始扩展功法数据 ===")
	
	# 确保输出目录存在
	var dir_path = OUTPUT_DIR.replace("res://", "")
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	# 添加更多门派功法
	create_tangmen_martial_arts()    # 唐门（暗器、毒）
	create_mingjiao_martial_arts()   # 明教（火系）
	create_wudu_martial_arts()       # 五毒教（毒系）
	create_xiaoyao_martial_arts()    # 逍遥派（辅助）
	create_emei_martial_arts()       # 峨眉派（治疗）
	
	print("\n=== 功法数据扩展完成！===")
	print("新增了更多门派的功法")
	print("位置: " + OUTPUT_DIR)
	
	quit()

## 创建唐门功法（暗器、毒）
func create_tangmen_martial_arts():
	print("\n创建唐门功法...")
	
	# 暴雨梨花针（玄阶）
	var lihua = MartialArtData.new()
	lihua.id = "tangmen_lihua"
	lihua.name = "暴雨梨花针"
	lihua.description = "唐门暗器绝技，一次发射数十枚银针，如暴雨梨花。"
	lihua.martial_art_type = MartialArtData.MartialArtType.ATTACK
	lihua.weapon_type = MartialArtData.WeaponType.NONE
	lihua.school = MartialArtData.SchoolType.GENERIC
	lihua.grade = MartialArtData.GradeType.RARE
	lihua.unlock_level = 25
	lihua.damage_base = 100.0
	lihua.damage_scale = 1.3
	lihua.hit_count = 12
	lihua.element_type = "金"
	lihua.cost_stamina = 20.0
	lihua.cost_mana = 40.0
	lihua.cooldown = 6.0
	lihua.startup_frames = 0.3
	lihua.active_frames = 1.5
	lihua.recovery_frames = 0.5
	lihua.total_duration = 2.3
	lihua.can_cancel_from_frame = -1.0
	ResourceSaver.save(lihua, OUTPUT_DIR + "tangmen_lihua.tres")
	print("  ✓ 暴雨梨花针")
	
	# 孔雀翎（地阶）
	var kongque = MartialArtData.new()
	kongque.id = "tangmen_kongque"
	kongque.name = "孔雀翎"
	kongque.description = "唐门至宝，天下第一暗器，一击必杀。"
	kongque.martial_art_type = MartialArtData.MartialArtType.ATTACK
	kongque.weapon_type = MartialArtData.WeaponType.NONE
	kongque.school = MartialArtData.SchoolType.GENERIC
	kongque.grade = MartialArtData.GradeType.EPIC
	kongque.unlock_level = 50
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
	print("  ✓ 孔雀翎")
	
	# 七星海棠毒（玄阶）- 减益型
	var qixing = MartialArtData.new()
	qixing.id = "tangmen_qixing"
	qixing.name = "七星海棠毒"
	qixing.description = "唐门剧毒，中毒者七日内必死。可削弱敌人防御。"
	qixing.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	qixing.weapon_type = MartialArtData.WeaponType.NONE
	qixing.school = MartialArtData.SchoolType.GENERIC
	qixing.grade = MartialArtData.GradeType.RARE
	qixing.unlock_level = 30
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
	print("  ✓ 七星海棠毒")

## 创建明教功法（火系）
func create_mingjiao_martial_arts():
	print("\n创建明教功法...")
	
	# 烈火刀法（玄阶）
	var liehuo = MartialArtData.new()
	liehuo.id = "mingjiao_liehuo"
	liehuo.name = "烈火刀法"
	liehuo.description = "明教刀法，刀势如烈火燎原，势不可挡。"
	liehuo.martial_art_type = MartialArtData.MartialArtType.ATTACK
	liehuo.weapon_type = MartialArtData.WeaponType.BLADE
	liehuo.school = MartialArtData.SchoolType.GENERIC
	liehuo.grade = MartialArtData.GradeType.RARE
	liehuo.unlock_level = 27
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
	liehuo.combo_chain.append("mingjiao_qiankun")
	ResourceSaver.save(liehuo, OUTPUT_DIR + "mingjiao_liehuo.tres")
	print("  ✓ 烈火刀法")
	
	# 乾坤大挪移（天阶）
	var qiankun = MartialArtData.new()
	qiankun.id = "mingjiao_qiankun"
	qiankun.name = "乾坤大挪移"
	qiankun.description = "明教镇教神功，可挪移乾坤，反弹敌人攻击。化神期修士可修炼。"
	qiankun.martial_art_type = MartialArtData.MartialArtType.DEFENSE
	qiankun.weapon_type = MartialArtData.WeaponType.NONE
	qiankun.school = MartialArtData.SchoolType.GENERIC
	qiankun.grade = MartialArtData.GradeType.LEGENDARY
	qiankun.unlock_level = 85
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
	print("  ✓ 乾坤大挪移")

## 创建五毒教功法（毒系）
func create_wudu_martial_arts():
	print("\n创建五毒教功法...")
	
	# 五毒神掌（玄阶）
	var wudu_zhang = MartialArtData.new()
	wudu_zhang.id = "wudu_shenzhang"
	wudu_zhang.name = "五毒神掌"
	wudu_zhang.description = "五毒教掌法，掌力含毒，中者必死。"
	wudu_zhang.martial_art_type = MartialArtData.MartialArtType.ATTACK
	wudu_zhang.weapon_type = MartialArtData.WeaponType.FIST
	wudu_zhang.school = MartialArtData.SchoolType.GENERIC
	wudu_zhang.grade = MartialArtData.GradeType.RARE
	wudu_zhang.unlock_level = 32
	wudu_zhang.damage_base = 130.0
	wudu_zhang.damage_scale = 1.5
	wudu_zhang.hit_count = 5
	wudu_zhang.element_type = "毒"
	wudu_zhang.cost_stamina = 30.0
	wudu_zhang.cost_mana = 45.0
	wudu_zhang.cooldown = 8.0
	wudu_zhang.startup_frames = 0.4
	wudu_zhang.active_frames = 1.2
	wudu_zhang.recovery_frames = 0.6
	wudu_zhang.total_duration = 2.2
	wudu_zhang.can_cancel_from_frame = -1.0
	ResourceSaver.save(wudu_zhang, OUTPUT_DIR + "wudu_shenzhang.tres")
	print("  ✓ 五毒神掌")
	
	# 万蛊噬心（地阶）- 减益型
	var wangu = MartialArtData.new()
	wangu.id = "wudu_wangu"
	wangu.name = "万蛊噬心"
	wangu.description = "五毒教禁术，以万蛊噬心，令敌人痛不欲生，持续削弱。"
	wangu.martial_art_type = MartialArtData.MartialArtType.DEBUFF
	wangu.weapon_type = MartialArtData.WeaponType.NONE
	wangu.school = MartialArtData.SchoolType.GENERIC
	wangu.grade = MartialArtData.GradeType.EPIC
	wangu.unlock_level = 55
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
	print("  ✓ 万蛊噬心")

## 创建逍遥派功法（辅助）
func create_xiaoyao_martial_arts():
	print("\n创建逍遥派功法...")
	
	# 凌波微步（玄阶）
	var lingbo = MartialArtData.new()
	lingbo.id = "xiaoyao_lingbo"
	lingbo.name = "凌波微步"
	lingbo.description = "逍遥派轻功绝学，身法飘逸，如履平地。"
	lingbo.martial_art_type = MartialArtData.MartialArtType.MOVEMENT
	lingbo.weapon_type = MartialArtData.WeaponType.NONE
	lingbo.school = MartialArtData.SchoolType.GENERIC
	lingbo.grade = MartialArtData.GradeType.RARE
	lingbo.unlock_level = 35
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
	print("  ✓ 凌波微步")
	
	# 北冥神功（天阶）
	var beiming = MartialArtData.new()
	beiming.id = "xiaoyao_beiming"
	beiming.name = "北冥神功"
	beiming.description = "逍遥派至高心法，可吸取他人内力为己用。返虚期修士可修炼。"
	beiming.martial_art_type = MartialArtData.MartialArtType.BUFF
	beiming.weapon_type = MartialArtData.WeaponType.NONE
	beiming.school = MartialArtData.SchoolType.GENERIC
	beiming.grade = MartialArtData.GradeType.LEGENDARY
	beiming.unlock_level = 78
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
	print("  ✓ 北冥神功")

## 创建峨眉派功法（治疗、辅助）
func create_emei_martial_arts():
	print("\n创建峨眉派功法...")
	
	# 峨眉剑法（玄阶）
	var emei_jian = MartialArtData.new()
	emei_jian.id = "emei_jianfa"
	emei_jian.name = "峨眉剑法"
	emei_jian.description = "峨眉派剑法，剑势轻灵，如行云流水。"
	emei_jian.martial_art_type = MartialArtData.MartialArtType.ATTACK
	emei_jian.weapon_type = MartialArtData.WeaponType.SWORD
	emei_jian.school = MartialArtData.SchoolType.EMEI
	emei_jian.grade = MartialArtData.GradeType.RARE
	emei_jian.unlock_level = 26
	emei_jian.damage_base = 110.0
	emei_jian.damage_scale = 1.4
	emei_jian.hit_count = 3
	emei_jian.element_type = "无"
	emei_jian.cost_stamina = 20.0
	emei_jian.cost_mana = 30.0
	emei_jian.cooldown = 5.0
	emei_jian.startup_frames = 0.3
	emei_jian.active_frames = 0.9
	emei_jian.recovery_frames = 0.4
	emei_jian.total_duration = 1.6
	emei_jian.can_cancel_from_frame = 1.0
	ResourceSaver.save(emei_jian, OUTPUT_DIR + "emei_jianfa.tres")
	print("  ✓ 峨眉剑法")
	
	# 九阳神功（天阶）
	var jiuyang = MartialArtData.new()
	jiuyang.id = "emei_jiuyang"
	jiuyang.name = "九阳神功"
	jiuyang.description = "峨眉派至高心法，至刚至阳，可疗伤护体。合道期修士可修炼。"
	jiuyang.martial_art_type = MartialArtData.MartialArtType.BUFF
	jiuyang.weapon_type = MartialArtData.WeaponType.NONE
	jiuyang.school = MartialArtData.SchoolType.EMEI
	jiuyang.grade = MartialArtData.GradeType.LEGENDARY
	jiuyang.unlock_level = 95
	jiuyang.damage_base = 0.0
	jiuyang.damage_scale = 0.0
	jiuyang.hit_count = 0
	jiuyang.element_type = "火"
	jiuyang.cost_stamina = 70.0
	jiuyang.cost_mana = 220.0
	jiuyang.cooldown = 100.0
	jiuyang.startup_frames = 2.0
	jiuyang.active_frames = 90.0
	jiuyang.recovery_frames = 2.0
	jiuyang.total_duration = 94.0
	jiuyang.can_cancel_from_frame = -1.0
	ResourceSaver.save(jiuyang, OUTPUT_DIR + "emei_jiuyang.tres")
	print("  ✓ 九阳神功")