# HealthPoiseManager 单元测试
# 验证生命值/架势值计算、破防机制、濒死状态和回合结算

extends GutTest

var _manager

func before_each():
	# 手动创建并初始化
	_manager = HealthPoiseManager.new()
	# 手动调用 _ready 来初始化内部变量
	_manager._ready()

func after_each():
	# 清理管理器，防止孤儿节点
	if is_instance_valid(_manager):
		_manager.free()
		_manager = null


# ============================================================================
# 测试 1：生命值计算 - 基础公式
# 公式: max_hp = 100 + 根骨 * 2.0 + 装备加成
# ============================================================================
func test_base_hp_with_default_stats():
	# 默认根骨=10
	var expected = 100 + 10 * 2.0  # 120
	assert_eq(_manager.calculate_max_hp(), int(expected),
		"默认属性下最大生命值应该是 120")


func test_hp_with_high_constitution():
	_manager.con_stat = 50
	var expected = 100 + 50 * 2.0  # 200
	assert_eq(_manager.calculate_max_hp(), int(expected),
		"根骨50时最大生命值应该是 200")


func test_hp_min_clamped_at_100():
	_manager.con_stat = -100  # 极端负值
	assert_eq(_manager.calculate_max_hp(), 100,
		"最小生命值应该是 100")


func test_hp_max_clamped_at_2000():
	_manager.con_stat = 1000  # 极端正值
	assert_eq(_manager.calculate_max_hp(), 2000,
		"最大生命值应该是 2000")


# ============================================================================
# 测试 2：架势值计算 - 基础公式
# 公式: max_poise = 50 + 定力 * 1.5 + 装备加成
# ============================================================================
func test_base_poise_with_default_stats():
	# 默认定力=10
	var expected = 50 + 10 * 1.5  # 65
	assert_eq(_manager.calculate_max_poise(), int(expected),
		"默认属性下最大架势值应该是 65")


func test_poise_with_high_willpower():
	_manager.wil_stat = 100
	var expected = 50 + 100 * 1.5  # 200
	assert_eq(_manager.calculate_max_poise(), int(expected),
		"定力100时最大架势值应该是 200")


func test_poise_min_clamped_at_50():
	_manager.wil_stat = -100
	assert_eq(_manager.calculate_max_poise(), 50,
		"最小架势值应该是 50")


func test_poise_max_clamped_at_800():
	_manager.wil_stat = 1000
	assert_eq(_manager.calculate_max_poise(), 800,
		"最大架势值应该是 800")


# ============================================================================
# 测试 3：受到生命值伤害
# ============================================================================
func test_apply_damage_reduces_hp():
	_manager.max_hp = 100
	_manager.current_hp = 100
	
	_manager.apply_damage_to_hp(30)
	
	assert_eq(_manager.current_hp, 70, "受到30点伤害后生命值应该是 70")


func test_apply_damage_at_critical_hp_triggers_status():
	_manager.max_hp = 100
	_manager.current_hp = 100
	_manager.status = HealthPoiseManager.STATUS_NORMAL
	
	_manager.apply_damage_to_hp(91)  # 剩9点
	
	assert_eq(_manager.status, HealthPoiseManager.STATUS_CRITICAL,
		"生命值低于10%时应该进入濒死状态")


func test_apply_damage_to_zero_triggers_death():
	_manager.max_hp = 100
	_manager.current_hp = 50
	
	_manager.apply_damage_to_hp(50)
	
	assert_eq(_manager.current_hp, 0, "生命值应该为 0")
	assert_eq(_manager.status, HealthPoiseManager.STATUS_DEAD,
		"生命值为0时应该触发死亡状态")


func test_damage_on_dead_does_nothing():
	_manager.max_hp = 100
	_manager.current_hp = 0
	_manager.status = HealthPoiseManager.STATUS_DEAD
	
	var result = _manager.apply_damage_to_hp(100)
	
	assert_eq(result, 0, "对死亡目标造成伤害应该返回 0")
	assert_eq(_manager.current_hp, 0, "死亡目标生命值应该保持为 0")


func test_damage_minimum_one():
	_manager.max_hp = 100
	_manager.current_hp = 50
	
	_manager.apply_damage_to_hp(0)
	
	assert_eq(_manager.current_hp, 49, "0点伤害应该至少造成 1 点")


# ============================================================================
# 测试 4：架势值伤害和破防
# ============================================================================
func test_apply_poise_damage():
	_manager.max_poise = 100
	_manager.current_poise = 100
	
	_manager.apply_damage_to_poise(40)
	
	assert_eq(_manager.current_poise, 60, "受到40点架势伤害后应该是 60")


func test_heavy_attack_poise_damage():
	_manager.max_poise = 100
	_manager.current_poise = 100
	
	_manager.apply_damage_to_poise(40, true)
	
	# 重攻击: 40 * 1.5 = 60, 100 - 60 = 40
	assert_eq(_manager.current_poise, 40, "重攻击应该造成 1.5 倍架势伤害")


func test_poise_damage_minimum_zero():
	_manager.max_poise = 100
	_manager.current_poise = 10
	
	_manager.apply_damage_to_poise(50)
	
	assert_eq(_manager.current_poise, 0, "架势值不应该低于 0")


func test_break_state_triggered_at_zero_poise():
	_manager.max_poise = 100
	_manager.current_poise = 100
	
	_manager.apply_damage_to_poise(100)
	
	assert_eq(_manager.status, HealthPoiseManager.STATUS_BREAK,
		"架势值为0时应该触发破防状态")
	assert_true(_manager.is_in_break_state(), "应该处于破防状态")


func test_break_state_damage_multiplier():
	_manager.max_hp = 100
	_manager.current_hp = 100
	_manager.status = HealthPoiseManager.STATUS_BREAK
	
	# 破防时受到伤害: 20 * 1.5 = 30
	_manager.apply_damage_after_break(20)
	
	assert_eq(_manager.current_hp, 70, "破防状态应该受到 1.5 倍伤害")


# ============================================================================
# 测试 5：防御动作恢复架势
# ============================================================================
func test_defend_action_restores_poise():
	_manager.max_poise = 100
	_manager.current_poise = 20
	
	_manager.on_defend_action()
	
	# 防御恢复 50%: 100 * 0.5 = 50, 20 + 50 = 70
	assert_true(_manager.current_poise >= 70, "防御应该恢复 50% 架势值")
	assert_eq(_manager.status, HealthPoiseManager.STATUS_DEFENDING,
		"防御时状态应该变为防御")


# ============================================================================
# 测试 6：回合结算
# ============================================================================
func test_turn_end_normal_poise_recovery():
	_manager.max_poise = 100
	_manager.current_poise = 10
	_manager.status = HealthPoiseManager.STATUS_NORMAL
	
	_manager.on_turn_end()
	
	# 恢复 20%: 100 * 0.2 = 20, 10 + 20 = 30
	assert_true(_manager.current_poise >= 30, "正常状态回合结束应该恢复 20% 架势值")


func test_turn_end_break_timer_decrement():
	_manager.status = HealthPoiseManager.STATUS_BREAK
	_manager.break_timer = 2
	
	_manager.on_turn_end()
	
	assert_eq(_manager.break_timer, 1, "破防计时应该减少 1")


func test_turn_end_break_expiry():
	_manager.status = HealthPoiseManager.STATUS_BREAK
	_manager.break_timer = 1
	
	_manager.on_turn_end()
	
	assert_eq(_manager.status, HealthPoiseManager.STATUS_NORMAL,
		"破防计时结束应该恢复正常状态")
	assert_eq(_manager.current_poise, 0,
		"破防结束后架势值应该为 0")


# ============================================================================
# 测试 7：状态检查
# ============================================================================
func test_status_info_returns_all_data():
	_manager.max_hp = 100
	_manager.current_hp = 50
	_manager.max_poise = 80
	_manager.current_poise = 40
	_manager.is_in_combat = true
	
	var info = _manager.get_status_info()
	
	assert_eq(info.current_hp, 50, "状态信息中的当前生命值应该正确")
	assert_eq(info.current_poise, 40, "状态信息中的当前架势值应该正确")
	assert_true(info.is_in_combat, "状态信息中的战斗中状态应该正确")
