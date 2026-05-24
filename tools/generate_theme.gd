## 主题生成器 — 水墨修真风 UI 主题
## 在 Godot 编辑器中运行: 右键 → Run Script（EditorScript）
## 或通过命令行: godot --headless --script tools/generate_theme.gd
@tool
extends EditorScript


## 色彩常量（来自 Art Bible）
const COLOR_PRIMARY := Color("#2E8B57")       ## 青绿 — 主色
const COLOR_DARK := Color("#1A1A2E")          ## 深墨 — 面板背景
const COLOR_ACCENT_RED := Color("#DC143C")    ## 深红 — 警告
const COLOR_GOLD := Color("#FFD700")          ## 金色 — 焦点/标题
const COLOR_TEXT := Color("#F5F5DC")          ## 米白 — 正文文字
const COLOR_TEXT_DIM := Color(0.86, 0.86, 0.78, 0.6)  ## 米白偏暗 — 辅助文字
const COLOR_TEXT_DISABLED := Color(0.5, 0.5, 0.5, 0.5) ## 禁用文字
const COLOR_BG_OVERLAY := Color(0.04, 0.04, 0.08, 0.85) ## 半透明墨 — 弹窗背景

## 字号常量
const FONT_SIZE_HEADER_LARGE := 32
const FONT_SIZE_HEADER_MEDIUM := 22
const FONT_SIZE_HEADER_SMALL := 16
const FONT_SIZE_BODY_MEDIUM := 18
const FONT_SIZE_BODY_SMALL := 14
const FONT_SIZE_BUTTON := 20
const FONT_SIZE_BUTTON_SMALL := 16

## 输出路径
const OUTPUT_PATH := "res://assets/themes/main_theme.tres"

## 字体路径（如果存在则加载）
const FONT_REGULAR_PATH := "res://assets/fonts/NotoSerifCJKsc-Regular.otf"
const FONT_BOLD_PATH := "res://assets/fonts/NotoSerifCJKsc-Bold.otf"


func _run() -> void:
	var theme := Theme.new()

	## 尝试加载自定义字体
	var font_regular: Font = _try_load_font(FONT_REGULAR_PATH)
	var font_bold: Font = _try_load_font(FONT_BOLD_PATH)

	if font_regular == null:
		print("[主题生成] 未找到自定义字体，使用 Godot 默认字体")
	else:
		print("[主题生成] 已加载自定义字体: %s" % FONT_REGULAR_PATH)

	## ========== 默认 Label 样式 ==========
	_setup_default_label(theme, font_regular, font_bold)

	## ========== 默认 Button 样式 ==========
	_setup_default_button(theme, font_bold)

	## ========== 默认 Panel / PanelContainer 样式 ==========
	_setup_default_panel(theme)

	## ========== 默认 ScrollBar 样式 ==========
	_setup_scrollbar(theme)

	## ========== 默认 CheckButton / CheckBox 样式 ==========
	_setup_check_controls(theme)

	## ========== 默认 HSlider 样式 ==========
	_setup_slider(theme)

	## ========== 默认 TabContainer 样式 ==========
	_setup_tab_container(theme)

	## ========== 默认 LineEdit 样式 ==========
	_setup_line_edit(theme)

	## ========== Label 变体 ==========
	_setup_label_variations(theme, font_regular, font_bold)

	## ========== Button 变体 ==========
	_setup_button_variations(theme, font_bold)

	## 保存
	var err := ResourceSaver.save(theme, OUTPUT_PATH)
	if err == OK:
		print("[主题生成] 已保存: %s" % OUTPUT_PATH)
	else:
		push_error("[主题生成] 保存失败: %s, 错误码: %d" % [OUTPUT_PATH, err])


func _try_load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null


## 创建指定大小的 FontVariation
func _make_font_variation(base_font: Font, size: int) -> Font:
	if base_font == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base_font
	return fv


## ========== 默认 Label ==========
func _setup_default_label(theme: Theme, font_regular: Font, _font_bold: Font) -> void:
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.3))
	theme.set_font_size("font_size", "Label", FONT_SIZE_BODY_MEDIUM)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	if font_regular:
		theme.set_font("font", "Label", font_regular)


## ========== 默认 Button ==========
func _setup_default_button(theme: Theme, font_bold: Font) -> void:
	## 字体
	theme.set_font_size("font_size", "Button", FONT_SIZE_BUTTON)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_GOLD)
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.92, 0.5, 1.0))
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DISABLED)
	theme.set_color("font_focus_color", "Button", COLOR_GOLD)
	if font_bold:
		theme.set_font("font", "Button", font_bold)

	## Normal — 青绿背景
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PRIMARY
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(12)
	normal.content_margin_left = 24
	normal.content_margin_right = 24
	normal.border_color = Color(0.22, 0.65, 0.42, 0.6)
	normal.set_border_width_all(1)
	theme.set_stylebox("normal", "Button", normal)

	## Hover — 金色边框 + 亮化背景
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.25, 0.62, 0.42, 1.0)
	hover.set_corner_radius_all(4)
	hover.set_content_margin_all(12)
	hover.content_margin_left = 24
	hover.content_margin_right = 24
	hover.border_color = COLOR_GOLD
	hover.set_border_width_all(2)
	theme.set_stylebox("hover", "Button", hover)

	## Pressed — 深色
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.15, 0.42, 0.25, 1.0)
	pressed.set_corner_radius_all(4)
	pressed.set_content_margin_all(12)
	pressed.content_margin_left = 24
	pressed.content_margin_right = 24
	pressed.border_color = COLOR_GOLD
	pressed.set_border_width_all(2)
	theme.set_stylebox("pressed", "Button", pressed)

	## Disabled — 灰色
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color(0.15, 0.15, 0.2, 0.5)
	disabled.set_corner_radius_all(4)
	disabled.set_content_margin_all(12)
	disabled.content_margin_left = 24
	disabled.content_margin_right = 24
	disabled.border_color = Color(0.3, 0.3, 0.3, 0.3)
	disabled.set_border_width_all(1)
	theme.set_stylebox("disabled", "Button", disabled)

	## Focus — 金色发光边框
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.set_corner_radius_all(4)
	focus.set_content_margin_all(12)
	focus.content_margin_left = 24
	focus.content_margin_right = 24
	focus.border_color = COLOR_GOLD
	focus.set_border_width_all(2)
	focus.shadow_color = Color(1.0, 0.84, 0, 0.3)
	focus.shadow_size = 4
	theme.set_stylebox("focus", "Button", focus)


## ========== 默认 Panel ==========
func _setup_default_panel(theme: Theme) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_DARK
	panel_style.set_corner_radius_all(6)
	panel_style.border_color = Color(0.3, 0.3, 0.25, 0.4)
	panel_style.set_border_width_all(1)
	theme.set_stylebox("panel", "Panel", panel_style)
	theme.set_stylebox("panel", "PanelContainer", panel_style.duplicate())


## ========== ScrollBar ==========
func _setup_scrollbar(theme: Theme) -> void:
	## VScrollBar
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.1, 0.1, 0.15, 0.5)
	scroll_bg.set_corner_radius_all(3)
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)

	var scroll_grabber := StyleBoxFlat.new()
	scroll_grabber.bg_color = COLOR_PRIMARY
	scroll_grabber.set_corner_radius_all(3)
	theme.set_stylebox("grabber", "VScrollBar", scroll_grabber)

	var scroll_grabber_hover := StyleBoxFlat.new()
	scroll_grabber_hover.bg_color = Color(0.25, 0.62, 0.42, 1.0)
	scroll_grabber_hover.set_corner_radius_all(3)
	theme.set_stylebox("grabber_highlight", "VScrollBar", scroll_grabber_hover)

	## HScrollBar
	theme.set_stylebox("scroll", "HScrollBar", scroll_bg.duplicate())
	theme.set_stylebox("grabber", "HScrollBar", scroll_grabber.duplicate())
	theme.set_stylebox("grabber_highlight", "HScrollBar", scroll_grabber_hover.duplicate())


## ========== CheckButton / CheckBox ==========
func _setup_check_controls(theme: Theme) -> void:
	theme.set_color("font_color", "CheckButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "CheckButton", COLOR_GOLD)
	theme.set_color("font_pressed_color", "CheckButton", COLOR_PRIMARY)
	theme.set_font_size("font_size", "CheckButton", FONT_SIZE_BODY_MEDIUM)

	theme.set_color("font_color", "CheckBox", COLOR_TEXT)
	theme.set_color("font_hover_color", "CheckBox", COLOR_GOLD)
	theme.set_font_size("font_size", "CheckBox", FONT_SIZE_BODY_MEDIUM)


## ========== HSlider ==========
func _setup_slider(theme: Theme) -> void:
	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	slider_bg.set_corner_radius_all(4)
	slider_bg.set_content_margin_all(0)
	theme.set_stylebox("slider", "HSlider", slider_bg)

	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = COLOR_PRIMARY
	slider_fill.set_corner_radius_all(4)
	slider_fill.set_content_margin_all(0)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)

	var slider_highlight := StyleBoxFlat.new()
	slider_highlight.bg_color = Color(0.25, 0.62, 0.42, 1.0)
	slider_highlight.set_corner_radius_all(4)
	slider_highlight.set_content_margin_all(0)
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_highlight)


## ========== TabContainer ==========
func _setup_tab_container(theme: Theme) -> void:
	theme.set_color("font_selected_color", "TabContainer", COLOR_GOLD)
	theme.set_color("font_unselected_color", "TabContainer", COLOR_TEXT_DIM)
	theme.set_color("font_hovered_color", "TabContainer", COLOR_TEXT)
	theme.set_font_size("font_size", "TabContainer", FONT_SIZE_BODY_MEDIUM)

	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = COLOR_DARK
	tab_selected.border_color = COLOR_GOLD
	tab_selected.border_width_bottom = 2
	tab_selected.set_corner_radius_all(0)
	tab_selected.corner_radius_top_left = 4
	tab_selected.corner_radius_top_right = 4
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)

	var tab_unselected := StyleBoxFlat.new()
	tab_unselected.bg_color = Color(0.1, 0.1, 0.15, 0.5)
	tab_unselected.set_corner_radius_all(0)
	tab_unselected.corner_radius_top_left = 4
	tab_unselected.corner_radius_top_right = 4
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_DARK
	panel_style.set_corner_radius_all(0)
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.border_color = Color(0.3, 0.3, 0.25, 0.3)
	panel_style.set_border_width_all(1)
	panel_style.border_width_top = 0
	theme.set_stylebox("panel", "TabContainer", panel_style)


## ========== LineEdit ==========
func _setup_line_edit(theme: Theme) -> void:
	theme.set_color("font_color", "LineEdit", COLOR_TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", COLOR_TEXT_DIM)
	theme.set_color("caret_color", "LineEdit", COLOR_GOLD)
	theme.set_color("selection_color", "LineEdit", Color(0.18, 0.55, 0.34, 0.4))
	theme.set_font_size("font_size", "LineEdit", FONT_SIZE_BODY_MEDIUM)

	var le_normal := StyleBoxFlat.new()
	le_normal.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	le_normal.set_corner_radius_all(4)
	le_normal.border_color = Color(0.3, 0.3, 0.25, 0.5)
	le_normal.set_border_width_all(1)
	le_normal.set_content_margin_all(8)
	theme.set_stylebox("normal", "LineEdit", le_normal)

	var le_focus := StyleBoxFlat.new()
	le_focus.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	le_focus.set_corner_radius_all(4)
	le_focus.border_color = COLOR_GOLD
	le_focus.set_border_width_all(2)
	le_focus.set_content_margin_all(8)
	theme.set_stylebox("focus", "LineEdit", le_focus)


## ========== Label 变体 ==========
func _setup_label_variations(theme: Theme, font_regular: Font, font_bold: Font) -> void:
	## HeaderLarge — 32px 金色粗体
	theme.set_type_variation("HeaderLarge", "Label")
	theme.set_font_size("font_size", "HeaderLarge", FONT_SIZE_HEADER_LARGE)
	theme.set_color("font_color", "HeaderLarge", COLOR_GOLD)
	theme.set_color("font_shadow_color", "HeaderLarge", Color(0, 0, 0, 0.5))
	theme.set_constant("shadow_offset_x", "HeaderLarge", 2)
	theme.set_constant("shadow_offset_y", "HeaderLarge", 2)
	if font_bold:
		theme.set_font("font", "HeaderLarge", font_bold)

	## HeaderMedium — 22px 米白粗体
	theme.set_type_variation("HeaderMedium", "Label")
	theme.set_font_size("font_size", "HeaderMedium", FONT_SIZE_HEADER_MEDIUM)
	theme.set_color("font_color", "HeaderMedium", COLOR_TEXT)
	if font_bold:
		theme.set_font("font", "HeaderMedium", font_bold)

	## HeaderSmall — 16px 米白偏暗
	theme.set_type_variation("HeaderSmall", "Label")
	theme.set_font_size("font_size", "HeaderSmall", FONT_SIZE_HEADER_SMALL)
	theme.set_color("font_color", "HeaderSmall", COLOR_TEXT_DIM)
	if font_regular:
		theme.set_font("font", "HeaderSmall", font_regular)

	## BodyMedium — 18px 米白
	theme.set_type_variation("BodyMedium", "Label")
	theme.set_font_size("font_size", "BodyMedium", FONT_SIZE_BODY_MEDIUM)
	theme.set_color("font_color", "BodyMedium", COLOR_TEXT)
	if font_regular:
		theme.set_font("font", "BodyMedium", font_regular)

	## BodySmall — 14px 米白偏暗
	theme.set_type_variation("BodySmall", "Label")
	theme.set_font_size("font_size", "BodySmall", FONT_SIZE_BODY_SMALL)
	theme.set_color("font_color", "BodySmall", COLOR_TEXT_DIM)
	if font_regular:
		theme.set_font("font", "BodySmall", font_regular)


## ========== Button 变体 ==========
func _setup_button_variations(theme: Theme, font_bold: Font) -> void:
	## MainMenuButton — 大号主菜单按钮，水墨边框风格
	theme.set_type_variation("MainMenuButton", "Button")
	theme.set_font_size("font_size", "MainMenuButton", 24)
	theme.set_color("font_color", "MainMenuButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "MainMenuButton", COLOR_GOLD)
	theme.set_color("font_pressed_color", "MainMenuButton", Color(1.0, 0.92, 0.5, 1.0))
	theme.set_color("font_disabled_color", "MainMenuButton", COLOR_TEXT_DISABLED)
	theme.set_color("font_focus_color", "MainMenuButton", COLOR_GOLD)
	if font_bold:
		theme.set_font("font", "MainMenuButton", font_bold)

	var mm_normal := StyleBoxFlat.new()
	mm_normal.bg_color = Color(0.08, 0.08, 0.12, 0.7)
	mm_normal.set_corner_radius_all(6)
	mm_normal.set_content_margin_all(16)
	mm_normal.content_margin_left = 48
	mm_normal.content_margin_right = 48
	mm_normal.border_color = Color(0.4, 0.35, 0.2, 0.5)
	mm_normal.set_border_width_all(1)
	theme.set_stylebox("normal", "MainMenuButton", mm_normal)

	var mm_hover := StyleBoxFlat.new()
	mm_hover.bg_color = Color(0.12, 0.12, 0.18, 0.85)
	mm_hover.set_corner_radius_all(6)
	mm_hover.set_content_margin_all(16)
	mm_hover.content_margin_left = 48
	mm_hover.content_margin_right = 48
	mm_hover.border_color = COLOR_GOLD
	mm_hover.set_border_width_all(2)
	mm_hover.shadow_color = Color(1.0, 0.84, 0, 0.15)
	mm_hover.shadow_size = 6
	theme.set_stylebox("hover", "MainMenuButton", mm_hover)

	var mm_pressed := StyleBoxFlat.new()
	mm_pressed.bg_color = Color(0.06, 0.06, 0.1, 0.9)
	mm_pressed.set_corner_radius_all(6)
	mm_pressed.set_content_margin_all(16)
	mm_pressed.content_margin_left = 48
	mm_pressed.content_margin_right = 48
	mm_pressed.border_color = COLOR_GOLD
	mm_pressed.set_border_width_all(2)
	theme.set_stylebox("pressed", "MainMenuButton", mm_pressed)

	var mm_disabled := StyleBoxFlat.new()
	mm_disabled.bg_color = Color(0.08, 0.08, 0.1, 0.4)
	mm_disabled.set_corner_radius_all(6)
	mm_disabled.set_content_margin_all(16)
	mm_disabled.content_margin_left = 48
	mm_disabled.content_margin_right = 48
	mm_disabled.border_color = Color(0.2, 0.2, 0.2, 0.3)
	mm_disabled.set_border_width_all(1)
	theme.set_stylebox("disabled", "MainMenuButton", mm_disabled)

	var mm_focus := StyleBoxFlat.new()
	mm_focus.bg_color = Color(0, 0, 0, 0)
	mm_focus.set_corner_radius_all(6)
	mm_focus.set_content_margin_all(16)
	mm_focus.content_margin_left = 48
	mm_focus.content_margin_right = 48
	mm_focus.border_color = COLOR_GOLD
	mm_focus.set_border_width_all(2)
	mm_focus.shadow_color = Color(1.0, 0.84, 0, 0.25)
	mm_focus.shadow_size = 6
	theme.set_stylebox("focus", "MainMenuButton", mm_focus)

	## PauseMenuButton — 暂停菜单按钮，半透明背景
	theme.set_type_variation("PauseMenuButton", "Button")
	theme.set_font_size("font_size", "PauseMenuButton", 20)
	theme.set_color("font_color", "PauseMenuButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "PauseMenuButton", COLOR_GOLD)
	theme.set_color("font_pressed_color", "PauseMenuButton", Color(1.0, 0.92, 0.5, 1.0))
	theme.set_color("font_disabled_color", "PauseMenuButton", COLOR_TEXT_DISABLED)
	theme.set_color("font_focus_color", "PauseMenuButton", COLOR_GOLD)
	if font_bold:
		theme.set_font("font", "PauseMenuButton", font_bold)

	var pm_normal := StyleBoxFlat.new()
	pm_normal.bg_color = Color(0.1, 0.1, 0.15, 0.6)
	pm_normal.set_corner_radius_all(4)
	pm_normal.set_content_margin_all(12)
	pm_normal.content_margin_left = 36
	pm_normal.content_margin_right = 36
	pm_normal.border_color = Color(0.3, 0.3, 0.25, 0.4)
	pm_normal.set_border_width_all(1)
	theme.set_stylebox("normal", "PauseMenuButton", pm_normal)

	var pm_hover := StyleBoxFlat.new()
	pm_hover.bg_color = Color(0.12, 0.12, 0.18, 0.75)
	pm_hover.set_corner_radius_all(4)
	pm_hover.set_content_margin_all(12)
	pm_hover.content_margin_left = 36
	pm_hover.content_margin_right = 36
	pm_hover.border_color = COLOR_GOLD
	pm_hover.set_border_width_all(2)
	theme.set_stylebox("hover", "PauseMenuButton", pm_hover)

	var pm_pressed := StyleBoxFlat.new()
	pm_pressed.bg_color = Color(0.06, 0.06, 0.1, 0.8)
	pm_pressed.set_corner_radius_all(4)
	pm_pressed.set_content_margin_all(12)
	pm_pressed.content_margin_left = 36
	pm_pressed.content_margin_right = 36
	pm_pressed.border_color = COLOR_GOLD
	pm_pressed.set_border_width_all(2)
	theme.set_stylebox("pressed", "PauseMenuButton", pm_pressed)

	var pm_focus := StyleBoxFlat.new()
	pm_focus.bg_color = Color(0, 0, 0, 0)
	pm_focus.set_corner_radius_all(4)
	pm_focus.set_content_margin_all(12)
	pm_focus.content_margin_left = 36
	pm_focus.content_margin_right = 36
	pm_focus.border_color = COLOR_GOLD
	pm_focus.set_border_width_all(2)
	pm_focus.shadow_color = Color(1.0, 0.84, 0, 0.2)
	pm_focus.shadow_size = 4
	theme.set_stylebox("focus", "PauseMenuButton", pm_focus)

	## PrimaryButton — 强调按钮（确认/应用）
	theme.set_type_variation("PrimaryButton", "Button")
	theme.set_font_size("font_size", "PrimaryButton", FONT_SIZE_BUTTON)
	theme.set_color("font_color", "PrimaryButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "PrimaryButton", COLOR_GOLD)
	theme.set_color("font_focus_color", "PrimaryButton", COLOR_GOLD)
	if font_bold:
		theme.set_font("font", "PrimaryButton", font_bold)

	var pri_normal := StyleBoxFlat.new()
	pri_normal.bg_color = COLOR_PRIMARY
	pri_normal.set_corner_radius_all(4)
	pri_normal.set_content_margin_all(10)
	pri_normal.content_margin_left = 28
	pri_normal.content_margin_right = 28
	pri_normal.border_color = Color(0.22, 0.65, 0.42, 0.6)
	pri_normal.set_border_width_all(1)
	theme.set_stylebox("normal", "PrimaryButton", pri_normal)

	var pri_hover := StyleBoxFlat.new()
	pri_hover.bg_color = Color(0.25, 0.62, 0.42, 1.0)
	pri_hover.set_corner_radius_all(4)
	pri_hover.set_content_margin_all(10)
	pri_hover.content_margin_left = 28
	pri_hover.content_margin_right = 28
	pri_hover.border_color = COLOR_GOLD
	pri_hover.set_border_width_all(2)
	theme.set_stylebox("hover", "PrimaryButton", pri_hover)

	var pri_pressed := StyleBoxFlat.new()
	pri_pressed.bg_color = Color(0.15, 0.42, 0.25, 1.0)
	pri_pressed.set_corner_radius_all(4)
	pri_pressed.set_content_margin_all(10)
	pri_pressed.content_margin_left = 28
	pri_pressed.content_margin_right = 28
	pri_pressed.border_color = COLOR_GOLD
	pri_pressed.set_border_width_all(2)
	theme.set_stylebox("pressed", "PrimaryButton", pri_pressed)

	var pri_focus := StyleBoxFlat.new()
	pri_focus.bg_color = Color(0, 0, 0, 0)
	pri_focus.set_corner_radius_all(4)
	pri_focus.set_content_margin_all(10)
	pri_focus.content_margin_left = 28
	pri_focus.content_margin_right = 28
	pri_focus.border_color = COLOR_GOLD
	pri_focus.set_border_width_all(2)
	pri_focus.shadow_color = Color(1.0, 0.84, 0, 0.2)
	pri_focus.shadow_size = 4
	theme.set_stylebox("focus", "PrimaryButton", pri_focus)

	## LoadingCancelButton — 小号次级按钮
	theme.set_type_variation("LoadingCancelButton", "Button")
	theme.set_font_size("font_size", "LoadingCancelButton", FONT_SIZE_BUTTON_SMALL)
	theme.set_color("font_color", "LoadingCancelButton", COLOR_TEXT_DIM)
	theme.set_color("font_hover_color", "LoadingCancelButton", COLOR_TEXT)
	theme.set_color("font_focus_color", "LoadingCancelButton", COLOR_GOLD)
	if font_bold:
		theme.set_font("font", "LoadingCancelButton", font_bold)

	var lc_normal := StyleBoxFlat.new()
	lc_normal.bg_color = Color(0.15, 0.15, 0.2, 0.5)
	lc_normal.set_corner_radius_all(3)
	lc_normal.set_content_margin_all(8)
	lc_normal.content_margin_left = 20
	lc_normal.content_margin_right = 20
	lc_normal.border_color = Color(0.3, 0.3, 0.3, 0.4)
	lc_normal.set_border_width_all(1)
	theme.set_stylebox("normal", "LoadingCancelButton", lc_normal)

	var lc_hover := StyleBoxFlat.new()
	lc_hover.bg_color = Color(0.2, 0.2, 0.25, 0.6)
	lc_hover.set_corner_radius_all(3)
	lc_hover.set_content_margin_all(8)
	lc_hover.content_margin_left = 20
	lc_hover.content_margin_right = 20
	lc_hover.border_color = COLOR_TEXT
	lc_hover.set_border_width_all(1)
	theme.set_stylebox("hover", "LoadingCancelButton", lc_hover)

	var lc_focus := StyleBoxFlat.new()
	lc_focus.bg_color = Color(0, 0, 0, 0)
	lc_focus.set_corner_radius_all(3)
	lc_focus.set_content_margin_all(8)
	lc_focus.content_margin_left = 20
	lc_focus.content_margin_right = 20
	lc_focus.border_color = COLOR_GOLD
	lc_focus.set_border_width_all(1)
	theme.set_stylebox("focus", "LoadingCancelButton", lc_focus)
