## 帮助/教程面板控制器
## 对应 UX Spec: design/ux/help-tutorial.md
## Z-index = 180（在HUD之上、设置面板之下）
## 注意：面板打开时不暂停游戏

extends CanvasLayer

## 帮助面板打开时发出
signal help_panel_opened(entry_source: String, current_tab: String)
## 帮助面板关闭时发出
signal help_panel_closed(current_tab: String, time_opened_seconds: float)
## Tab切换时发出
signal help_tab_switched(tab_name: String)
## 教程步骤完成时发出
signal tutorial_step_completed(chapter_id: String, step_id: String, step_number: int)
## 教程步骤解锁时发出
signal tutorial_step_unlocked(chapter_id: String, step_id: String, unlock_trigger: String)
## 教程推迟时发出
signal tutorial_deferred(chapter_id: String, step_id: String)
## 情境提示关闭时发出
signal contextual_toast_dismissed(toast_id: String, action: String)
## 搜索系统说明时发出
signal help_system_searched(query: String, result_count: int)

## 场景引用
@onready var _panel: PanelContainer = $HelpPanelContainer
@onready var _title_label: Label = $HelpPanelContainer/VBox/HeaderHBox/TitleLabel
@onready var _progress_label: Label = $HelpPanelContainer/VBox/HeaderHBox/ProgressLabel
@onready var _close_btn: Button = $HelpPanelContainer/VBox/HeaderHBox/CloseButton
@onready var _tab_bar: TabBar = $HelpPanelContainer/VBox/TabBar
@onready var _tutorial_tab: ScrollContainer = $HelpPanelContainer/VBox/TabContent/TutorialTab
@onready var _systems_tab: ScrollContainer = $HelpPanelContainer/VBox/TabContent/SystemsTab
@onready var _controls_tab: ScrollContainer = $HelpPanelContainer/VBox/TabContent/ControlsTab
@onready var _wuxing_combat_tab: ScrollContainer = $HelpPanelContainer/VBox/TabContent/WuxingCombatTab
@onready var _tutorial_chapter_list: ItemList = $HelpPanelContainer/VBox/TabContent/TutorialTab/TutorialVBox/TutorialChapterList
@onready var _tutorial_content_label: RichTextLabel = $HelpPanelContainer/VBox/TabContent/TutorialTab/TutorialVBox/TutorialContentLabel
@onready var _prev_step_btn: Button = $HelpPanelContainer/VBox/TabContent/TutorialTab/TutorialVBox/TutorialNavHBox/PrevStepButton
@onready var _mark_done_btn: Button = $HelpPanelContainer/VBox/TabContent/TutorialTab/TutorialVBox/TutorialNavHBox/MarkDoneButton
@onready var _next_step_btn: Button = $HelpPanelContainer/VBox/TabContent/TutorialTab/TutorialVBox/TutorialNavHBox/NextStepButton
@onready var _search_box: LineEdit = $HelpPanelContainer/VBox/TabContent/SystemsTab/SystemsVBox/SearchBox
@onready var _system_list: ItemList = $HelpPanelContainer/VBox/TabContent/SystemsTab/SystemsVBox/SystemList
@onready var _system_detail_label: RichTextLabel = $HelpPanelContainer/VBox/TabContent/SystemsTab/SystemsVBox/SystemDetailLabel
@onready var _controls_content: RichTextLabel = $HelpPanelContainer/VBox/TabContent/ControlsTab/ControlsVBox/ControlsContent
@onready var _wuxing_matrix_label: RichTextLabel = $HelpPanelContainer/VBox/TabContent/WuxingCombatTab/WuxingCombatVBox/WuxingMatrixLabel
@onready var _combat_tips_label: RichTextLabel = $HelpPanelContainer/VBox/TabContent/WuxingCombatTab/WuxingCombatVBox/CombatTipsLabel

## 配置常量
const CONFIG_PATH: String = "user://tutorial_progress.json"

## 是否打开
var _is_open: bool = false
## 打开时间
var _open_time_ms: float = 0.0
## 上次关闭时的Tab索引
var _last_tab_index: int = 0
## 当前教程章节和步骤
var _current_chapter_index: int = 0
var _current_step_index: int = 0
## 教程进度数据
var _tutorial_progress: Dictionary = {}
## 推迟的教程章节
var _deferred_chapters: Array[String] = []
## 已关闭的情境提示
var _dismissed_toasts: Array[String] = []
## 减少运动设置
var _reduce_motion: bool = false
## 情境提示Toast实例
var _contextual_toast: Node = null


func _ready() -> void:
	visible = false

	# 加载情境提示Toast
	_load_contextual_toast()

	# 连接信号
	_close_btn.pressed.connect(close_panel)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_tutorial_chapter_list.item_selected.connect(_on_tutorial_chapter_selected)
	_prev_step_btn.pressed.connect(_on_prev_step)
	_next_step_btn.pressed.connect(_on_next_step)
	_mark_done_btn.pressed.connect(_on_mark_done)
	_search_box.text_changed.connect(_on_search_text_changed)
	_search_box.text_submitted.connect(_on_search_text_submitted)
	_system_list.item_selected.connect(_on_system_selected)

	# 加载进度和设置
	_load_progress()
	_reduce_motion = _load_reduce_motion_setting()

	# 填充静态内容
	_populate_tutorial_data()
	_populate_systems_data()
	_populate_controls_data()
	_populate_wuxing_combat_data()

	# 更新进度显示
	_update_progress_label()

	# 初始Tab
	_on_tab_changed(_last_tab_index)


## 打开帮助面板
func open_panel(source: String = "f1_key", target_tab: int = -1, target_item_id: String = "") -> void:
	if _is_open:
		return

	_is_open = true
	_open_time_ms = Time.get_ticks_msec()
	visible = true
	_panel.position.x = _panel.size.x

	if target_tab >= 0:
		_tab_bar.current_tab = target_tab
	else:
		_tab_bar.current_tab = _last_tab_index

	# 滑入动画
	if _reduce_motion:
		_panel.position.x = 0
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "position:x", 0.0, 0.3)

	# 更新Tab内容
	_on_tab_changed(_tab_bar.current_tab)

	help_panel_opened.emit(source, _get_tab_name(_tab_bar.current_tab))


## 关闭帮助面板
func close_panel() -> void:
	if not _is_open:
		return

	var time_spent = (Time.get_ticks_msec() - _open_time_ms) / 1000.0
	_last_tab_index = _tab_bar.current_tab
	_is_open = false

	# 滑出动画
	if _reduce_motion:
		_panel.position.x = _panel.size.x
		visible = false
	else:
		var tween = create_tween()
		tween.tween_property(_panel, "position:x", _panel.size.x, 0.25)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.finished.connect(func(): visible = false)

	help_panel_closed.emit(_get_tab_name(_tab_bar.current_tab), time_spent)


## 显示情境提示
func show_contextual_toast(toast_id: String, title: String, body: String, related_chapter_id: String = "") -> void:
	if _contextual_toast == null:
		_load_contextual_toast()
	if _contextual_toast != null:
		_contextual_toast.show_toast(toast_id, title, body, related_chapter_id)


## Tab切换
func _on_tab_changed(tab_index: int) -> void:
	var tabs: Array[Control] = [_tutorial_tab, _systems_tab, _controls_tab, _wuxing_combat_tab]
	for i in range(tabs.size()):
		if tabs[i] != null:
			tabs[i].visible = (i == tab_index)

	if _is_open:
		help_tab_switched.emit(_get_tab_name(tab_index))


## 填充教程数据
func _populate_tutorial_data() -> void:
	_tutorial_chapter_list.clear()

	# 教程章节数据（占位，后续从TutorialSystem读取）
	var chapters = [
		{"id": "first_steps", "title": "初入修真界", "steps": [
			{"id": "welcome", "title": "欢迎来到修真界", "content": "[b]欢迎来到修真界！[/b]\n\n这是一个修仙与武侠交织的世界。你将在这里经历从炼气到渡劫的九大境界。\n\n[b]基本操作：[/b]\n- WASD / 方向键：移动\n- 鼠标点击：交互\n- M键：打开大地图\n- F1：打开帮助\n- ESC：暂停游戏"},
			{"id": "movement", "title": "移动与探索", "content": "[b]移动与探索[/b]\n\n使用 WASD 或方向键在场景中移动。靠近NPC或物品时会出现交互提示。\n\n探索世界可以发现隐藏的仙缘奇遇和珍贵资源。"},
			{"id": "first_npc", "title": "与NPC对话", "content": "[b]与NPC对话[/b]\n\n靠近NPC后按交互键即可对话。部分NPC会提供任务或传授功法。"},
		]},
		{"id": "combat_basics", "title": "战斗入门", "steps": [
			{"id": "first_combat", "title": "第一次战斗", "content": "[b]回合制战斗[/b]\n\n战斗采用回合制。五行相克是关键：\n- [color=#FFD700]金[/color] 克 [color=#90EE90]木[/color]\n- [color=#90EE90]木[/color] 克 [color=#DEB887]土[/color]\n- [color=#DEB887]土[/color] 克 [color=#4169E1]水[/color]\n- [color=#4169E1]水[/color] 克 [color=#FF4500]火[/color]\n- [color=#FF4500]火[/color] 克 [color=#FFD700]金[/color]\n\n利用相克属性攻击可获得伤害加成。"},
			{"id": "basic_attack", "title": "基础攻击", "content": "[b]基础攻击[/b]\n\n选择攻击技能，系统会根据五行相克计算伤害。选择合适的武学能事半功倍。"},
		]},
		{"id": "realm_system", "title": "境界系统", "steps": [
			{"id": "realm_intro", "title": "什么是境界？", "content": "[b]境界系统[/b]\n\n修真界分为九大境界：\n1. 炼气\n2. 筑基\n3. 金丹\n4. 元婴\n5. 化神\n6. 返虚\n7. 合道\n8. 大乘\n9. 渡劫\n\n每个境界都有属性加成，突破后所有属性增加10%。"},
			{"id": "realm_breakthrough", "title": "境界突破", "content": "[b]境界突破[/b]\n\n当修为达到当前境界上限时，可尝试突破。\n\n突破条件：\n- 达到所需等级\n- 拥有突破丹\n- 通过心境试炼\n\n突破失败可能导致修为倒退，请做好准备。"},
		]},
		{"id": "equipment_inventory", "title": "装备与背包", "steps": [
			{"id": "first_item", "title": "获得第一件物品", "content": "[b]物品系统[/b]\n\n按 I 键打开背包。物品分为：\n- 装备（武器、防具、饰品）\n- 消耗品（丹药、符箓）\n- 材料（炼器、炼丹原料）\n\n新获得的物品会标记'NEW'角标。"},
		]},
		{"id": "quest_encounter", "title": "任务与奇遇", "steps": [
			{"id": "quest_basics", "title": "任务系统", "content": "[b]任务系统[/b]\n\n任务分为主线任务和支线任务。完成任务可获得经验、灵石和稀有物品。\n\n任务目标会在大地图上以标记显示。"},
			{"id": "encounter_basics", "title": "仙缘奇遇", "content": "[b]仙缘奇遇[/b]\n\n在探索过程中可能触发仙缘事件。奇遇可能带来好处，也可能暗藏危险。\n\n福缘属性影响奇遇触发概率和稀有掉落率。"},
		]},
	]

	for chapter in chapters:
		_tutorial_chapter_list.add_item(chapter.title)
		# 检查完成状态
		var chapter_progress = _tutorial_progress.get(chapter.id, {})
		var completed_count = 0
		for step in chapter.steps:
			if chapter_progress.get(step.id, {}).get("completed", false):
				completed_count += 1
		if completed_count == chapter.steps.size():
			# 全部完成，添加✓标记
			var idx = _tutorial_chapter_list.item_count - 1
			_tutorial_chapter_list.set_item_text(idx, chapter.title + " ✓")


## 填充系统说明数据
func _populate_systems_data() -> void:
	_system_list.clear()

	# 系统说明词条
	var systems = [
		{"id": "combat", "title": "战斗系统", "detail": "[b]战斗系统[/b]\n\n采用回合制战斗，结合五行相克机制。\n\n[b]回合流程：[/b]\n1. 根据速度决定行动顺序\n2. 选择行动（攻击、防御、技能、物品）\n3. 计算伤害与效果\n4. 进入下一回合\n\n[b]胜负条件：[/b]\n- 胜利：敌方生命值归零\n- 失败：己方全部角色生命值归零"},
		{"id": "realm", "title": "境界系统", "detail": "[b]境界系统[/b]\n\n九大修真境界，每个境界提供不同的属性加成。\n\n[b]境界列表：[/b]\n- 炼气（基础境界）\n- 筑基（属性+10%）\n- 金丹（属性+20%）\n- 元婴（属性+30%）\n- 化神（属性+40%）\n- 返虚（属性+50%）\n- 合道（属性+60%）\n- 大乘（属性+70%）\n- 渡劫（属性+80%）"},
		{"id": "wuxing", "title": "五行系统", "detail": "[b]五行相克[/b]\n\n金克木，木克土，土克水，水克火，火克金。\n\n相克攻击造成 150% 伤害。\n被克制攻击造成 50% 伤害。\n\n[b]五行属性来源：[/b]\n- 武学自带五行属性\n- 装备可提供五行加成"},
		{"id": "economy", "title": "经济系统", "detail": "[b]经济系统[/b]\n\n游戏中的主要货币是灵石。\n\n[b]灵石获取：[/b]\n- 完成任务\n- 出售物品\n- 奇遇奖励\n\n[b]灵石消耗：[/b]\n- 购买物品\n- 快速旅行\n- 炼丹"},
		{"id": "exploration", "title": "探索系统", "detail": "[b]探索系统[/b]\n\n在修真界中探索各个区域。每个区域有探索进度。\n\n[b]探索内容：[/b]\n- 仙缘奇遇\n- 隐藏资源点\n- NPC互动\n- 挑战试炼\n\n区域探索度100%后获得额外奖励。"},
		{"id": "equipment", "title": "装备系统", "detail": "[b]装备系统[/b]\n\n装备分为：武器、防具、饰品。\n\n[b]品质等级：[/b]\n- 普通（白色）\n- 稀有（蓝色）\n- 史诗（紫色）\n- 传说（金色）\n\n每个装备部位有境界解锁要求。"},
	]

	for system in systems:
		_system_list.add_item(system.title)


## 填充控制说明数据
func _populate_controls_data() -> void:
	_controls_content.text = """[b]控制说明[/b]

[b]移动：[/b]
- WASD / 方向键：移动角色

[b]交互：[/b]
- 鼠标点击 / E键：与NPC或物品交互
- 空格键：确认/跳跃

[b]界面快捷键：[/b]
- M键：打开/关闭大地图
- I键：打开/关闭背包
- F1：打开/关闭帮助面板
- ESC：暂停/继续游戏
- Tab键：在帮助面板Tab间切换

[b]战斗快捷键：[/b]
- 鼠标点击：选择行动
- 数字键 1-9：快捷选择技能

[b]系统快捷键：[/b]
- +/-：缩放（大地图）
- L键：图例（大地图）
"""


## 填充五行与战斗数据
func _populate_wuxing_combat_data() -> void:
	_wuxing_matrix_label.text = """[b]五行相克矩阵[/b]

| 克制方 → 被克制方 |
|------|------|
| [color=#FFD700]金[/color]  →  [color=#90EE90]木[/color] |
| [color=#90EE90]木[/color]  →  [color=#DEB887]土[/color] |
| [color=#DEB887]土[/color]  →  [color=#4169E1]水[/color] |
| [color=#4169E1]水[/color]  →  [color=#FF4500]火[/color] |
| [color=#FF4500]火[/color]  →  [color=#FFD700]金[/color] |

## 相克攻击：[b]+50%[/b] 伤害
## 被克制攻击：[b]-50%[/b] 伤害
"""

	_combat_tips_label.text = """[b]战斗技巧[/b]

1. [b]了解敌人弱点[/b]：每个敌人有五行弱点，针对性选择武学
2. [b]合理使用防御[/b]：防御可减少 50% 受到的伤害，但不会反击
3. [b]管理内力[/b]：强力武学消耗内力，注意保留足够内力
4. [b]利用连携[/b]：连续攻击同一弱点可触发连携加成
5. [b]及时使用丹药[/b]：生命低于30%时及时治疗，避免被击败
6. [b]观察行动顺序[/b]：速度高的角色先行动，优先控制或输出
"""


## 教程章节选中
func _on_tutorial_chapter_selected(index: int) -> void:
	_current_chapter_index = index
	_current_step_index = 0
	_show_current_tutorial_step()


## 显示当前教程步骤
func _show_current_tutorial_step() -> void:
	var chapters = _get_tutorial_chapters()
	if _current_chapter_index < 0 or _current_chapter_index >= chapters.size():
		return

	var chapter = chapters[_current_chapter_index]
	if chapter.steps.size() == 0:
		return

	# 确保步骤索引有效
	if _current_step_index >= chapter.steps.size():
		_current_step_index = chapter.steps.size() - 1
	if _current_step_index < 0:
		_current_step_index = 0

	var step = chapter.steps[_current_step_index]
	_tutorial_content_label.text = step.content

	# 更新按钮状态
	_prev_step_btn.disabled = (_current_step_index <= 0)
	_next_step_btn.disabled = (_current_step_index >= chapter.steps.size() - 1)


## 上一页
func _on_prev_step() -> void:
	if _current_step_index > 0:
		_current_step_index -= 1
		_show_current_tutorial_step()


## 下一页
func _on_next_step() -> void:
	var chapters = _get_tutorial_chapters()
	if _current_chapter_index < 0 or _current_chapter_index >= chapters.size():
		return

	var chapter = chapters[_current_chapter_index]
	if _current_step_index < chapter.steps.size() - 1:
		_current_step_index += 1
		_show_current_tutorial_step()


## 标记为已完成
func _on_mark_done() -> void:
	var chapters = _get_tutorial_chapters()
	if _current_chapter_index < 0 or _current_chapter_index >= chapters.size():
		return

	var chapter = chapters[_current_chapter_index]
	var step = chapter.steps[_current_step_index]

	# 记录完成状态
	if not _tutorial_progress.has(chapter.id):
		_tutorial_progress[chapter.id] = {}
	_tutorial_progress[chapter.id][step.id] = {"completed": true}

	# 保存进度
	_save_progress()

	# 更新进度显示
	_update_progress_label()

	tutorial_step_completed.emit(chapter.id, step.id, _current_step_index)

	# 自动跳转下一步
	_on_next_step()


## 推迟教程
func _defer_tutorial(chapter_id: String) -> void:
	if chapter_id not in _deferred_chapters:
		_deferred_chapters.append(chapter_id)
	tutorial_deferred.emit(chapter_id, "")
	_save_progress()


## 情境提示关闭
func _dismiss_toast(toast_id: String) -> void:
	if toast_id not in _dismissed_toasts:
		_dismissed_toasts.append(toast_id)
	contextual_toast_dismissed.emit(toast_id, "dismiss")
	_save_progress()


## 搜索文本变化
func _on_search_text_changed(new_text: String) -> void:
	_system_list.clear()

	var systems = _get_systems_data()
	if new_text.strip_edges().is_empty():
		for system in systems:
			_system_list.add_item(system.title)
	else:
		var query = new_text.to_lower()
		var count = 0
		for system in systems:
			if system.title.to_lower().contains(query) or system.detail.to_lower().contains(query):
				_system_list.add_item(system.title)
				count += 1
		help_system_searched.emit(new_text, count)


## 搜索文本提交
func _on_search_text_submitted(new_text: String) -> void:
	pass  # 搜索实时过滤，提交时不需要额外处理


## 系统词条选中
func _on_system_selected(index: int) -> void:
	var systems = _get_systems_data()
	if index < 0 or index >= systems.size():
		return

	_system_detail_label.text = systems[index].detail


## 获取教程章节数据
func _get_tutorial_chapters() -> Array:
	# 与 _populate_tutorial_data 中的数据保持一致
	return [
		{"id": "first_steps", "title": "初入修真界", "steps": [
			{"id": "welcome", "title": "欢迎来到修真界"},
			{"id": "movement", "title": "移动与探索"},
			{"id": "first_npc", "title": "与NPC对话"},
		]},
		{"id": "combat_basics", "title": "战斗入门", "steps": [
			{"id": "first_combat", "title": "第一次战斗"},
			{"id": "basic_attack", "title": "基础攻击"},
		]},
		{"id": "realm_system", "title": "境界系统", "steps": [
			{"id": "realm_intro", "title": "什么是境界？"},
			{"id": "realm_breakthrough", "title": "境界突破"},
		]},
		{"id": "equipment_inventory", "title": "装备与背包", "steps": [
			{"id": "first_item", "title": "获得第一件物品"},
		]},
		{"id": "quest_encounter", "title": "任务与奇遇", "steps": [
			{"id": "quest_basics", "title": "任务系统"},
			{"id": "encounter_basics", "title": "仙缘奇遇"},
		]},
	]


## 获取系统说明数据
func _get_systems_data() -> Array:
	return [
		{"id": "combat", "title": "战斗系统"},
		{"id": "realm", "title": "境界系统"},
		{"id": "wuxing", "title": "五行系统"},
		{"id": "economy", "title": "经济系统"},
		{"id": "exploration", "title": "探索系统"},
		{"id": "equipment", "title": "装备系统"},
	]


## 加载教程进度
func _load_progress() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		_tutorial_progress = {}
		return

	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		_tutorial_progress = {}
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null:
		_tutorial_progress = {}
	else:
		_tutorial_progress = json
		_last_tab_index = json.get("last_tab_index", 0)


## 保存教程进度
func _save_progress() -> void:
	var data = _tutorial_progress.duplicate()
	data["last_tab_index"] = _last_tab_index

	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


## 更新进度标签
func _update_progress_label() -> void:
	var total_steps = 0
	var completed_steps = 0

	var chapters = _get_tutorial_chapters()
	for chapter in chapters:
		for step in chapter.steps:
			total_steps += 1
			var chapter_prog = _tutorial_progress.get(chapter.id, {})
			if chapter_prog.get(step.id, {}).get("completed", false):
				completed_steps += 1

	_progress_label.text = "教程进度: %d/%d" % [completed_steps, total_steps]


## 获取Tab名称
func _get_tab_name(tab_index: int) -> String:
	match tab_index:
		0: return "教程"
		1: return "系统说明"
		2: return "控制"
		3: return "五行与战斗"
		_: return "未知"


## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_F1:
				if _is_open:
					close_panel()
					get_viewport().set_input_as_handled()
			KEY_LEFT, KEY_RIGHT:
				if _is_open:
					var tab_count = _tab_bar.tab_count
					var next_tab = _tab_bar.current_tab
					if event.keycode == KEY_RIGHT:
						next_tab = (next_tab + 1) % tab_count
					else:
						next_tab = (next_tab - 1 + tab_count) % tab_count
					_tab_bar.current_tab = next_tab
					get_viewport().set_input_as_handled()


## 读取减少运动设置
func _load_reduce_motion_setting() -> bool:
	var settings_path = "user://settings.json"
	if not FileAccess.file_exists(settings_path):
		return false
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return false
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null:
		return false
	return json.get("reduce_motion", false)


## 加载情境提示Toast
func _load_contextual_toast() -> void:
	var scene = load("res://src/scenes/ui/contextual_toast.tscn")
	if scene != null:
		_contextual_toast = scene.instantiate()
		get_tree().root.add_child(_contextual_toast)
		_contextual_toast.learn_more_clicked.connect(_on_toast_learn_more)
		_contextual_toast.later_clicked.connect(_on_toast_later)
		_contextual_toast.dismissed.connect(_on_toast_dismissed)
	else:
		push_warning("无法加载情境提示Toast场景")


func _on_toast_learn_more(toast_id: String, related_chapter_id: String) -> void:
	# GDScript 不支持 Python 风格的 keyword arguments（target_item_id=...）
	# open_panel 签名: (source: String, target_tab: int = -1, target_item_id: String = "")
	# 第 2 个参数是 int 类型，必须传 -1（默认值）；第 3 个才是 target_item_id
	open_panel("contextual_toast", -1, related_chapter_id)


func _on_toast_later(toast_id: String) -> void:
	_defer_tutorial(toast_id)


func _on_toast_dismissed(toast_id: String, action: String) -> void:
	_dismiss_toast(toast_id)
