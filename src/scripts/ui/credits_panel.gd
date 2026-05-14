## 制作人员字幕面板
## 显示滚动制作人员名单

extends CanvasLayer

signal credits_closed

@onready var _panel: PanelContainer = $PanelContainer
@onready var _close_btn: Button = $PanelContainer/VBox/CloseButton
@onready var _scroll: ScrollContainer = $PanelContainer/VBox/ScrollContainer
@onready var _content: RichTextLabel = $PanelContainer/VBox/ScrollContainer/CreditsContent

var _scroll_speed: float = 30.0
var _is_scrolling: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close_btn.pressed.connect(close_panel)


func open_panel() -> void:
	visible = true
	_is_scrolling = true
	_scroll.scroll_vertical = 0
	_close_btn.grab_focus()
	_populate_credits()


func close_panel() -> void:
	_is_scrolling = false
	visible = false
	credits_closed.emit()


func _process(delta: float) -> void:
	if not visible or not _is_scrolling:
		return
	_scroll.scroll_vertical += int(_scroll_speed * delta)


func _populate_credits() -> void:
	_content.clear()
	_content.append_text("[center][font_size=24]武侠奇遇录[/font_size][/center]\n\n")
	_content.append_text("[center]— 制作团队 —[/center]\n\n")
	_content.append_text("[center]游戏设计 / 程序开发\nClaude Code Game Studios[/center]\n\n")
	_content.append_text("[center]— 技术 —[/center]\n\n")
	_content.append_text("[center]引擎: Godot Engine 4.6\n语言: GDScript\n测试: GUT Framework[/center]\n\n")
	_content.append_text("[center]— 特别感谢 —[/center]\n\n")
	_content.append_text("[center]Godot Engine 社区\nAnthropic Claude[/center]\n\n")
	_content.append_text("[center]感谢您的游玩！[/center]\n\n\n\n")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close_panel()
			get_viewport().set_input_as_handled()
