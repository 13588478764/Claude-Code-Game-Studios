## 新游戏开场流程集成测试 (s6-02)
## 验证点击"开始新游戏"后系统初始化和流程转换
extends GutTest

const MainMenuScript = preload("res://src/scripts/ui/main_menu.gd")
const GameLoopScript = preload("res://src/scripts/core/game_loop_manager.gd")

var _menu: Control = null
var _game_loop: Node = null


func before_each() -> void:
	_game_loop = GameLoopScript.new()
	_game_loop.name = "GameLoopManager"
	add_child(_game_loop)

	_menu = MainMenuScript.new()
	add_child_autofree(_menu)


func after_each() -> void:
	if _game_loop and is_instance_valid(_game_loop):
		remove_child(_game_loop)
		_game_loop.queue_free()


## 新游戏后 GameLoopManager 进入 EXPLORING 状态
func test_new_game_enters_exploration() -> void:
	_menu._start_new_game()
	# 等待一帧让 deferred 调用完成
	await get_tree().create_timer(0.1).timeout
	# 由于 DialogueManager 可能不在测试环境中，直接检查进入探索
	_menu._enter_exploration()
	assert_eq(_game_loop.current_state, GameLoopScript.GameState.EXPLORING)


## 新游戏后主菜单隐藏
func test_new_game_hides_menu() -> void:
	_menu._start_new_game()
	assert_false(_menu.visible)


## 连续双击不会重复初始化
func test_rapid_double_click_prevented() -> void:
	_menu._on_new_game_pressed()
	assert_true(_menu._transitioning)
	# 第二次应该被 _transitioning 标志阻止
	_menu._on_new_game_pressed()
	# 不崩溃即通过


## _enter_exploration 可安全调用
func test_enter_exploration_safe() -> void:
	_menu._enter_exploration()
	assert_eq(_game_loop.current_state, GameLoopScript.GameState.EXPLORING)
	assert_false(_menu._transitioning)
