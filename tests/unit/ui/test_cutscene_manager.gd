extends GutTest
## CutsceneManager / CutscenePlayer / PlayCutsceneEffect 单元测试
## 覆盖：定义加载、播放生命周期、防重入、跳过、缺失容错、对话效果对接

const DialogueDataScript := preload("res://src/scripts/dialogue/dialogue_data.gd")

var _manager: Node = null


func before_each() -> void:
	# 使用项目 autoload 单例（GUT 运行时会加载 project.godot 的 autoload）
	_manager = get_tree().root.get_node_or_null("CutsceneManager")
	assert_not_null(_manager, "CutsceneManager autoload 应存在")


func after_each() -> void:
	# 清理：若测试中残留播放，强制跳过并等待释放
	if _manager != null and _manager.is_playing():
		_manager.skip_current()
		await wait_for_signal(_manager.cutscene_finished, 3.0, "测试清理：等待过场结束超时")
	_manager = null


# ============================================================================
# 定义加载
# ============================================================================

func test_load_definition_ascension_memory() -> void:
	var def: Dictionary = _manager.load_cutscene_definition("act1_ascension_memory")
	assert_false(def.is_empty(), "飞升记忆过场定义应加载成功")
	assert_eq(def.get("id", ""), "act1_ascension_memory")
	assert_true(bool(def.get("skippable", false)), "应可跳过")
	var frames: Array = def.get("frames", [])
	assert_eq(frames.size(), 5, "记忆碎片应为5帧（对应剧本5个画面）")
	for frame in frames:
		assert_true(frame.has("image"), "每帧应有 image 字段")
		assert_true(frame.has("narration"), "每帧应有 narration 字段")


func test_load_definition_travel_montage() -> void:
	var def: Dictionary = _manager.load_cutscene_definition("travel_montage")
	assert_false(def.is_empty(), "赶路过场定义应加载成功")
	assert_eq(def.get("frames", []).size(), 1, "赶路过场为单帧（2秒）")


func test_load_definition_act2_departure_with_reused_assets() -> void:
	var def: Dictionary = _manager.load_cutscene_definition("act2_departure")
	assert_false(def.is_empty(), "Act2 离镇过场定义应加载成功")
	var frames: Array = def.get("frames", [])
	assert_eq(frames.size(), 3, "离镇过场应为3帧（镇-道-山门）")
	# 复用现有背景资产（res:// 全路径），必须真实存在
	for frame in frames:
		var image: String = frame.get("image", "")
		assert_true(image.begins_with("res://"), "离镇帧图应使用 res:// 全路径复用现有资产")
		assert_true(ResourceLoader.exists(image), "帧图应真实存在: %s" % image)


func test_load_definition_not_found_returns_empty() -> void:
	var def: Dictionary = _manager.load_cutscene_definition("nonexistent_cutscene_xyz")
	assert_true(def.is_empty(), "不存在的过场ID应返回空字典")


func test_load_definition_illegal_id_returns_empty() -> void:
	assert_true(_manager.load_cutscene_definition("").is_empty(), "空ID应返回空")
	assert_true(_manager.load_cutscene_definition("../escape").is_empty(), "路径穿越ID应返回空")
	assert_true(_manager.load_cutscene_definition("a/b").is_empty(), "含斜杠ID应返回空")


# ============================================================================
# 播放生命周期
# ============================================================================

func test_play_cutscene_starts_and_skip_finishes() -> void:
	watch_signals(_manager)
	var ok: bool = _manager.play_cutscene("travel_montage")
	assert_true(ok, "赶路过场应开始播放")
	assert_true(_manager.is_playing(), "播放中状态应为true")
	assert_signal_emitted(_manager, "cutscene_started", "应发出开始信号")

	_manager.skip_current()
	await wait_for_signal(_manager.cutscene_finished, 3.0, "跳过后应快速结束")
	assert_signal_emitted(_manager, "cutscene_finished")
	assert_false(_manager.is_playing(), "结束后状态应为false")


func test_play_cutscene_rejects_reentry() -> void:
	assert_true(_manager.play_cutscene("travel_montage"))
	var second: bool = _manager.play_cutscene("act1_ascension_memory")
	assert_false(second, "播放中应拒绝重复播放")
	assert_true(_manager.is_playing())


func test_play_cutscene_missing_id_fails() -> void:
	watch_signals(_manager)
	var ok: bool = _manager.play_cutscene("nonexistent_cutscene_xyz")
	assert_false(ok, "缺失ID应播放失败")
	assert_signal_emitted(_manager, "cutscene_failed", "应发出失败信号")
	assert_false(_manager.is_playing())


func test_play_cutscene_missing_frames_uses_placeholder() -> void:
	# 帧图尚未生成（Part E 资产待生产），应走占位路径而非崩溃
	watch_signals(_manager)
	assert_true(_manager.play_cutscene("act1_ascension_memory"))
	assert_true(_manager.is_playing())
	_manager.skip_current()
	await wait_for_signal(_manager.cutscene_finished, 3.0, "占位播放应可跳过结束")
	assert_signal_emitted(_manager, "cutscene_finished")


# ============================================================================
# 对话效果对接（cutscene_play）
# ============================================================================

func test_parse_effect_cutscene_play() -> void:
	var dialogue_mgr := get_tree().root.get_node_or_null("DialogueManager")
	assert_not_null(dialogue_mgr, "DialogueManager autoload 应存在")
	var effect: Object = dialogue_mgr._parse_effect({
		"type": "cutscene_play",
		"target": "act1_ascension_memory"
	})
	assert_not_null(effect, "cutscene_play 效果应被解析")
	assert_eq(effect.type, DialogueDataScript.Effect.EffectType.PLAY_CUTSCENE, "效果类型应为 PLAY_CUTSCENE")
	assert_eq(effect.target, "act1_ascension_memory", "target 应为过场ID")


func test_play_cutscene_effect_execute_starts_playback() -> void:
	var effect := DialogueDataScript.PlayCutsceneEffect.new("travel_montage")
	effect.execute()
	await get_tree().process_frame
	assert_true(_manager.is_playing(), "效果执行后过场应开始播放")
	_manager.skip_current()
	await wait_for_signal(_manager.cutscene_finished, 3.0, "清理：等待结束")


# ============================================================================
# 快速旅行过场接入（fast_travel_manager.gd start_travel_process）
# ============================================================================

func test_fast_travel_process_plays_montage_cutscene() -> void:
	var ftm := FastTravelManager.new()
	add_child_autofree(ftm)  # 触发 _ready（示例节点+默认位置 qingyun_mountain）
	watch_signals(ftm)

	ftm.start_travel_process("jiangnan_town", 2)
	await get_tree().process_frame
	assert_true(_manager.is_playing(), "旅行应触发 travel_montage 过场播放")
	assert_eq(ftm.current_state, FastTravelManager.TravelState.TRAVELING, "应处于旅行中状态")

	# 过场自然播放完毕（2s 帧 + 淡入淡出 ≈ 2.7s）后应完成旅行
	await wait_for_signal(ftm.travel_completed, 6.0, "过场结束后应完成旅行")
	assert_signal_emitted(ftm, "travel_completed")
	assert_eq(ftm.current_location, "jiangnan_town", "过场结束后位置应更新")
	assert_false(_manager.is_playing(), "过场应已结束")
