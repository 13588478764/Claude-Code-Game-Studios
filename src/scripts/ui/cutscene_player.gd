## 过场动画播放器（视觉小说式）
## 静态帧序列 + 交叉淡入淡出 + Ken Burns 运镜 + 旁白字幕 + 点击推进/ESC 跳过
## 数据源：data/cutscenes/{id}.json（由 CutsceneManager 加载后传入 play()）
## 帧图：assets/ui/cutscene_frames/{image}.png（1920×1080，缺失时显示占位标题）
extends CanvasLayer
class_name CutscenePlayer

signal frame_changed(frame_index: int)
signal cutscene_finished()

const FRAMES_DIR := "res://assets/ui/cutscene_frames/"
const KEN_BURNS_ZOOM := 1.06  ## 运镜缩放幅度（偶数帧推进、奇数帧拉远）

@onready var _background: ColorRect = $Background
@onready var _frame_a: TextureRect = $FrameA
@onready var _frame_b: TextureRect = $FrameB
@onready var _placeholder_label: Label = $PlaceholderLabel
@onready var _narration_panel: PanelContainer = $NarrationPanel
@onready var _narration_label: Label = $NarrationPanel/MarginContainer/NarrationLabel
@onready var _skip_hint: Label = $SkipHint

var _frames: Array = []
var _fade_duration: float = 0.8
var _skippable: bool = true
var _current_index: int = -1
var _playing: bool = false
var _play_token: int = 0  ## 防竞态：每次 play/skip 递增，await 后校验


## 开始播放过场定义
## @param definition: data/cutscenes/{id}.json 解析出的 Dictionary
func play(definition: Dictionary) -> void:
	_frames = definition.get("frames", [])
	_fade_duration = maxf(0.1, float(definition.get("fade_duration", 0.8)))
	_skippable = bool(definition.get("skippable", true))
	_skip_hint.visible = _skippable
	if _frames.is_empty():
		push_warning("[CutscenePlayer] 过场定义无帧，直接结束")
		_finish()
		return
	_playing = true
	_play_token += 1
	_show_frame(0, _play_token)


func is_playing() -> bool:
	return _playing


func get_current_frame_index() -> int:
	return _current_index


## 跳过整个过场（立即结束）
func skip() -> void:
	if not _playing or not _skippable:
		return
	_play_token += 1
	_finish()


# ============================================================================
# 内部实现
# ============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if event.is_action_pressed("ui_cancel") and _skippable:
		skip()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


## 推进到下一帧（点击/确认键）
func _advance() -> void:
	if _current_index + 1 >= _frames.size():
		_play_token += 1
		_finish()
		return
	_play_token += 1
	_show_frame(_current_index + 1, _play_token)


func _show_frame(index: int, token: int) -> void:
	_current_index = index
	var frame: Dictionary = _frames[index]
	var duration: float = maxf(0.5, float(frame.get("duration", 3.0)))

	var incoming := _frame_b if index % 2 == 0 else _frame_a
	var outgoing := _frame_a if index % 2 == 0 else _frame_b

	# 帧图加载（缺失时显示占位标题，保证资产未齐时系统可联调）
	var image_name: String = frame.get("image", "")
	var tex: Texture2D = _load_frame_texture(image_name)
	if tex != null:
		incoming.texture = tex
		incoming.visible = true
		_placeholder_label.visible = false
	else:
		incoming.visible = false
		_placeholder_label.text = frame.get("title", image_name)
		_placeholder_label.visible = true

	# Ken Burns 运镜：偶数帧推进、奇数帧拉远
	incoming.pivot_offset = incoming.size / 2.0
	var zoom_from := Vector2.ONE if index % 2 == 0 else Vector2.ONE * KEN_BURNS_ZOOM
	var zoom_to := Vector2.ONE * KEN_BURNS_ZOOM if index % 2 == 0 else Vector2.ONE
	incoming.scale = zoom_from
	var kb_tween := create_tween()
	kb_tween.tween_property(incoming, "scale", zoom_to, duration + _fade_duration)

	# 交叉淡入淡出
	incoming.modulate.a = 0.0
	var fade_tween := create_tween().set_parallel(true)
	fade_tween.tween_property(incoming, "modulate:a", 1.0, _fade_duration)
	if _current_index > 0:
		fade_tween.tween_property(outgoing, "modulate:a", 0.0, _fade_duration)
	else:
		# 首帧从黑场淡入
		outgoing.modulate.a = 0.0

	# 旁白字幕
	var narration: String = frame.get("narration", "")
	_narration_panel.visible = not narration.is_empty()
	_narration_label.text = narration

	frame_changed.emit(index)

	# 定时自动推进
	await get_tree().create_timer(duration).timeout
	if token != _play_token or not _playing:
		return
	if index + 1 >= _frames.size():
		_finish()
	else:
		_show_frame(index + 1, token)


func _load_frame_texture(image_name: String) -> Texture2D:
	if image_name.is_empty():
		return null
	# 支持两种写法：短名（拼 FRAMES_DIR）或 res:// 全路径（复用任意现有资产，如 backgrounds/）
	var path := image_name if image_name.begins_with("res://") else FRAMES_DIR + image_name + ".png"
	if not ResourceLoader.exists(path):
		push_warning("[CutscenePlayer] 帧图缺失（占位显示）: %s" % path)
		return null
	return load(path) as Texture2D


func _finish() -> void:
	if not _playing:
		return
	_playing = false
	# 淡出到黑场后释放
	var tween := create_tween()
	tween.tween_property(_background, "color:a", 1.0, 0.3)
	tween.parallel().tween_property(_frame_a, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(_frame_b, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(_narration_panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	cutscene_finished.emit()
	queue_free()
