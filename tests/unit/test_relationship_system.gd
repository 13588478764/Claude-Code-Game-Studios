## 关系系统单元测试
extends GutTest

var relationship_manager
var relationship_data: RelationshipData

func before_each():
	var RelationshipManagerScript = load("res://src/scripts/relationship/relationship_manager.gd")
	relationship_manager = RelationshipManagerScript.new()
	relationship_data = RelationshipData.new()

func after_each():
	relationship_manager.free()

## 测试关系值范围限制
func test_relationship_value_clamping():
	# 测试超出上限
	relationship_manager.set_relationship_value("test_npc", 150)
	assert_eq(relationship_manager.get_relationship_value("test_npc"), 100, "关系值应该被限制在100")
	
	# 测试超出下限
	relationship_manager.set_relationship_value("test_npc", -150)
	assert_eq(relationship_manager.get_relationship_value("test_npc"), -100, "关系值应该被限制在-100")

## 测试关系等级判定
func test_relationship_level_judgment():
	# 测试仇敌等级
	relationship_manager.set_relationship_value("npc1", -60)
	assert_eq(relationship_manager.get_relationship_level("npc1"), RelationshipData.RelationshipLevel.ENEMY, "应该是仇敌等级")
	
	# 测试冷淡等级
	relationship_manager.set_relationship_value("npc2", -20)
	assert_eq(relationship_manager.get_relationship_level("npc2"), RelationshipData.RelationshipLevel.COLD, "应该是冷淡等级")
	
	# 测试中立等级
	relationship_manager.set_relationship_value("npc3", 0)
	assert_eq(relationship_manager.get_relationship_level("npc3"), RelationshipData.RelationshipLevel.NEUTRAL, "应该是中立等级")
	
	# 测试友好等级
	relationship_manager.set_relationship_value("npc4", 30)
	assert_eq(relationship_manager.get_relationship_level("npc4"), RelationshipData.RelationshipLevel.FRIENDLY, "应该是友好等级")
	
	# 测试亲密等级
	relationship_manager.set_relationship_value("npc5", 60)
	assert_eq(relationship_manager.get_relationship_level("npc5"), RelationshipData.RelationshipLevel.INTIMATE, "应该是亲密等级")
	
	# 测试挚友等级
	relationship_manager.set_relationship_value("npc6", 90)
	assert_eq(relationship_manager.get_relationship_level("npc6"), RelationshipData.RelationshipLevel.BEST_FRIEND, "应该是挚友等级")

## 测试道心值范围限制
func test_dao_heart_value_clamping():
	# 测试超出上限
	relationship_manager.set_dao_heart_value(150)
	assert_eq(relationship_manager.get_dao_heart_value(), 100, "道心值应该被限制在100")
	
	# 测试超出下限
	relationship_manager.set_dao_heart_value(-150)
	assert_eq(relationship_manager.get_dao_heart_value(), -100, "道心值应该被限制在-100")

## 测试道心等级判定
func test_dao_heart_level_judgment():
	# 测试魔道宗师
	relationship_manager.set_dao_heart_value(-70)
	assert_eq(relationship_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.EVIL_MASTER, "应该是魔道宗师")
	
	# 测试魔道倾向
	relationship_manager.set_dao_heart_value(-40)
	assert_eq(relationship_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.EVIL_LEANING, "应该是魔道倾向")
	
	# 测试中立
	relationship_manager.set_dao_heart_value(0)
	assert_eq(relationship_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.NEUTRAL, "应该是中立")
	
	# 测试正道倾向
	relationship_manager.set_dao_heart_value(40)
	assert_eq(relationship_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.RIGHTEOUS_LEANING, "应该是正道倾向")
	
	# 测试正道宗师
	relationship_manager.set_dao_heart_value(70)
	assert_eq(relationship_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.RIGHTEOUS_MASTER, "应该是正道宗师")

## 测试关系值修改
func test_modify_relationship():
	relationship_manager.set_relationship_value("test_npc", 0)
	
	# 测试增加关系值
	relationship_manager.modify_relationship("test_npc", 20, "测试增加")
	assert_eq(relationship_manager.get_relationship_value("test_npc"), 20, "关系值应该增加20")
	
	# 测试减少关系值
	relationship_manager.modify_relationship("test_npc", -10, "测试减少")
	assert_eq(relationship_manager.get_relationship_value("test_npc"), 10, "关系值应该减少10")

## 测试道心值修改
func test_modify_dao_heart():
	relationship_manager.set_dao_heart_value(0)
	
	# 测试增加道心值
	relationship_manager.modify_dao_heart(30, "正道行为")
	assert_eq(relationship_manager.get_dao_heart_value(), 30, "道心值应该增加30")
	
	# 测试减少道心值
	relationship_manager.modify_dao_heart(-20, "魔道行为")
	assert_eq(relationship_manager.get_dao_heart_value(), 10, "道心值应该减少20")

## 测试商店折扣计算
func test_shop_discount():
	# 测试中立等级（无折扣）
	relationship_manager.set_relationship_value("merchant1", 0)
	assert_eq(relationship_manager.get_shop_discount("merchant1"), 0.0, "中立等级应该无折扣")
	
	# 测试友好等级（10%折扣）
	relationship_manager.set_relationship_value("merchant2", 30)
	assert_eq(relationship_manager.get_shop_discount("merchant2"), 0.10, "友好等级应该有10%折扣")
	
	# 测试亲密等级（20%折扣）
	relationship_manager.set_relationship_value("merchant3", 60)
	assert_eq(relationship_manager.get_shop_discount("merchant3"), 0.20, "亲密等级应该有20%折扣")
	
	# 测试挚友等级（30%折扣）
	relationship_manager.set_relationship_value("merchant4", 90)
	assert_eq(relationship_manager.get_shop_discount("merchant4"), 0.30, "挚友等级应该有30%折扣")

## 测试NPC态度修正
func test_npc_attitude_modifier():
	# 测试正道NPC对正道玩家的态度
	relationship_manager.set_dao_heart_value(70)
	var modifier: int = relationship_manager.get_npc_attitude_modifier("righteous_npc", "righteous")
	assert_eq(modifier, 20, "正道宗师应该获得正道NPC的+20态度修正")
	
	# 测试正道NPC对魔道玩家的态度
	relationship_manager.set_dao_heart_value(-70)
	modifier = relationship_manager.get_npc_attitude_modifier("righteous_npc", "righteous")
	assert_eq(modifier, -30, "魔道宗师应该获得正道NPC的-30态度修正")
	
	# 测试魔道NPC对魔道玩家的态度
	relationship_manager.set_dao_heart_value(-70)
	modifier = relationship_manager.get_npc_attitude_modifier("evil_npc", "evil")
	assert_eq(modifier, 20, "魔道宗师应该获得魔道NPC的+20态度修正")

## 测试关系等级变化信号
func test_relationship_level_change_signal():
	watch_signals(relationship_manager)
	
	# 从中立提升到友好
	relationship_manager.set_relationship_value("test_npc", 0)
	relationship_manager.modify_relationship("test_npc", 15, "测试")
	
	assert_signal_emitted(relationship_manager, "relationship_level_changed", "应该触发关系等级变化信号")

## 测试道心等级变化信号
func test_dao_heart_level_change_signal():
	watch_signals(relationship_manager)
	
	# 从中立变为正道倾向
	relationship_manager.set_dao_heart_value(0)
	relationship_manager.modify_dao_heart(35, "测试")
	
	assert_signal_emitted(relationship_manager, "dao_heart_level_changed", "应该触发道心等级变化信号")

## 测试保存和加载
func test_save_and_load():
	# 设置一些数据
	relationship_manager.set_relationship_value("npc1", 50)
	relationship_manager.set_relationship_value("npc2", -30)
	relationship_manager.set_dao_heart_value(40)
	relationship_manager.current_game_day = 10
	
	# 保存数据
	var save_data = relationship_manager.save_data()
	
	# 创建新的管理器并加载数据
	var RelationshipManagerScript = load("res://src/scripts/relationship/relationship_manager.gd")
	var new_manager = RelationshipManagerScript.new()
	new_manager.load_data(save_data)
	
	# 验证数据
	assert_eq(new_manager.get_relationship_value("npc1"), 50, "NPC1关系值应该被正确加载")
	assert_eq(new_manager.get_relationship_value("npc2"), -30, "NPC2关系值应该被正确加载")
	assert_eq(new_manager.get_dao_heart_value(), 40, "道心值应该被正确加载")
	assert_eq(new_manager.current_game_day, 10, "游戏天数应该被正确加载")
	
	new_manager.free()

## 测试关系历史记录
func test_relationship_history():
	relationship_manager.modify_relationship("test_npc", 10, "帮助NPC")
	relationship_manager.modify_relationship("test_npc", 5, "赠送礼物")
	
	var history = relationship_manager.get_relationship_history("test_npc")
	assert_eq(history.size(), 2, "应该有2条历史记录")
	assert_eq(history[0].delta, 10, "第一条记录应该是+10")
	assert_eq(history[1].delta, 5, "第二条记录应该是+5")

## 测试道心历史记录
func test_dao_heart_history():
	relationship_manager.modify_dao_heart(15, "正义行为")
	relationship_manager.modify_dao_heart(-10, "邪恶行为")
	
	var history = relationship_manager.get_dao_heart_history()
	assert_eq(history.size(), 2, "应该有2条历史记录")
	assert_eq(history[0].delta, 15, "第一条记录应该是+15")
	assert_eq(history[1].delta, -10, "第二条记录应该是-10")