## 过场动画管理器（autoload: CutsceneManager）
## 职责：加载 data/cutscenes/{id}.json 定义 → 实例化 CutscenePlayer 播放 → 完成信号
## 触发方：对话效果 cutscene_play（PlayCutsceneEffect）、快速旅行、主线事件脚本
## 防重入：同一时间仅允许播放一个过场（GDD：过场属场景级操作，不回滚）
extends Node

signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)
signal cutscene_failed(cutscene_id: String, reason: String)

const CUTSCENE_DIR := "res://data/cutscenes/"
const PLAYER_SCENE_PATH := "res://src/scenes/ui/cutscene_player.tscn"

var _player: CutscenePlayer = null
var _current_id: String = ""


## 是否正在播放过场
func is_playing() -> bool:
	return _player != null


## 播放指定过场
## @param cutscene_id: data/cutscenes/ 下的文件名（不含扩展名），如 "act1_ascension_memory"
## @return 是否成功开始播放
func play_cutscene(cutscene_id: String) -> bool:
	if is_playing():
		push_warning("[CutsceneManager] 过场播放中，忽略重复请求: %s" % cutscene_id)
		return false
	var definition := load_cutscene_definition(cutscene_id)
	if definition.is_empty():
		cutscene_failed.emit(cutscene_id, "过场定义缺失或解析失败")
		return false
	var packed: PackedScene = load(PLAYER_SCENE_PATH)
	if packed == null:
		cutscene_failed.emit(cutscene_id, "播放器场景缺失: %s" % PLAYER_SCENE_PATH)
		return false
	_player = packed.instantiate() as CutscenePlayer
	_current_id = cutscene_id
	# 加到场景树根节点最上层，确保覆盖所有游戏 UI
	get_tree().root.add_child(_player)
	_player.cutscene_finished.connect(_on_player_finished)
	cutscene_started.emit(cutscene_id)
	_player.play(definition)
	return true


## 跳过当前过场（若可跳过）
func skip_current() -> void:
	if _player != null:
		_player.skip()


## 加载过场定义（公开以便测试与预校验）
## @return 解析成功的 Dictionary；文件缺失/格式错误时返回空 Dictionary
func load_cutscene_definition(cutscene_id: String) -> Dictionary:
	if cutscene_id.is_empty() or cutscene_id.contains("/") or cutscene_id.contains(".."):
		push_warning("[CutsceneManager] 非法过场ID: %s" % cutscene_id)
		return {}
	var path := CUTSCENE_DIR + cutscene_id + ".json"
	if not FileAccess.file_exists(path):
		push_warning("[CutsceneManager] 过场定义不存在: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("[CutsceneManager] 过场定义格式错误（应为JSON对象）: %s" % path)
		return {}
	var definition: Dictionary = parsed
	if not definition.has("frames") or not definition["frames"] is Array:
		push_warning("[CutsceneManager] 过场定义缺少 frames 数组: %s" % path)
		return {}
	return definition


func _on_player_finished() -> void:
	var finished_id := _current_id
	_player = null
	_current_id = ""
	cutscene_finished.emit(finished_id)
