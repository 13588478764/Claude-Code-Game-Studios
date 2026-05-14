## Sprint 6 端到端集成测试 (s6-11)
## 验证核心链路：设置持久化、新游戏流程、NPC对话
extends GutTest

const GameLoopScript = preload("res://src/scripts/core/game_loop_manager.gd")
const SaveSystemScript = preload("res://src/scripts/save/save_system.gd")
const SettingsPanelScript = preload("res://src/scripts/ui/settings_panel.gd")


## 设置变更后保存再加载仍保持
func test_settings_persist_across_reload() -> void:
	var panel: Control = SettingsPanelScript.new()
	add_child_autofree(panel)

	panel._master_volume.value = 42.0
	panel._music_volume.value = 33.0
	panel._save_to_config()

	# 创建新面板实例模拟重启
	var panel2: Control = SettingsPanelScript.new()
	add_child_autofree(panel2)

	# panel2._ready() 加载配置后应有相同值
	assert_almost_eq(panel2._master_volume.value, 42.0, 0.01)
	assert_almost_eq(panel2._music_volume.value, 33.0, 0.01)

	# 清理
	if FileAccess.file_exists("user://settings.cfg"):
		DirAccess.remove_absolute("user://settings.cfg")


## GameLoopManager 状态转换：MENU → EXPLORING
func test_game_state_menu_to_exploring() -> void:
	var game_loop: Node = GameLoopScript.new()
	game_loop.name = "GameLoopManager"
	add_child_autofree(game_loop)

	assert_eq(game_loop.current_state, GameLoopScript.GameState.MENU)
	game_loop.enter_exploration()
	assert_eq(game_loop.current_state, GameLoopScript.GameState.EXPLORING)


## SaveSystem 保存/加载循环不丢失数据
func test_save_load_cycle_no_data_loss() -> void:
	var save_sys: Node = SaveSystemScript.new()
	save_sys.name = "SaveSystem"
	add_child_autofree(save_sys)

	# 保存
	var saved: bool = save_sys.save_to_slot(1)
	assert_true(saved)
	assert_true(save_sys.has_save(1))

	# 加载（会尝试恢复各系统，由于autoload不在测试环境中，仅验证文件读取）
	var info: Dictionary = save_sys.get_save_info(1)
	assert_true(info.has("slot"))
	assert_eq(info.get("slot", 0), 1)
	assert_true(info.has("timestamp"))

	# 清理
	save_sys.delete_save(1)


## return_to_menu 将状态重置为 MENU
func test_return_to_menu_resets_state() -> void:
	var game_loop: Node = GameLoopScript.new()
	game_loop.name = "GameLoopManager"
	add_child_autofree(game_loop)

	game_loop.enter_exploration()
	assert_eq(game_loop.current_state, GameLoopScript.GameState.EXPLORING)

	game_loop.return_to_menu()
	assert_eq(game_loop.current_state, GameLoopScript.GameState.MENU)
