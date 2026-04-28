extends Control

# 历史记录显示管理器
# 实现图鉴式UI界面，提供查询、筛选、排序和搜索功能

# 信号定义
signal history_displayed()

# 引用历史记录器
var history_logger = null

# UI组件引用
@onready var main_container: VBoxContainer = $MainContainer
@onready var top_bar: HBoxContainer = $MainContainer/TopBar
@onready var search_box: LineEdit = $MainContainer/TopBar/SearchBox
@onready var filter_dropdown: OptionButton = $MainContainer/TopBar/FilterDropdown
@onready var sort_dropdown: OptionButton = $MainContainer/TopBar/SortDropdown
@onready var list_container: VBoxContainer = $MainContainer/ListContainer
@onready var detail_panel: Panel = $MainContainer/DetailPanel
@onready var list_view: ItemList = $MainContainer/ListContainer/ListView
@onready var detail_view: RichTextLabel = $MainContainer/DetailPanel/DetailView

# 初始化
func _ready():
	# 加载历史记录器
	if history_logger == null:
		# 尝试从场景中获取或创建新的历史记录器
		history_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	
	# 设置UI组件
	setup_ui()
	
	# 连接信号
	search_box.text_changed.connect(_on_search_text_changed)
	filter_dropdown.item_selected.connect(_on_filter_selected)
	sort_dropdown.item_selected.connect(_on_sort_selected)
	list_view.item_selected.connect(_on_item_selected)

# 设置UI
func setup_ui():
	# 设置筛选下拉框
	filter_dropdown.clear()
	filter_dropdown.add_item("全部类型", 0)
	filter_dropdown.add_item("战斗", 1)
	filter_dropdown.add_item("事件", 2)
	filter_dropdown.add_item("探索", 3)
	filter_dropdown.add_item("随机", 4)
	
	# 设置排序下拉框
	sort_dropdown.clear()
	sort_dropdown.add_item("时间降序", 0)
	sort_dropdown.add_item("时间升序", 1)
	sort_dropdown.add_item("标题", 2)
	
	# 刷新显示
	refresh_display()

# 显示历史记录界面
func show_history_interface():
	visible = true
	refresh_display()

# 刷新显示
func refresh_display():
	# 获取所有记录
	var all_records = history_logger.get_all_records()
	
	# 应用筛选和排序
	var filtered_records = apply_filter(all_records)
	var sorted_records = apply_sort(filtered_records)
	
	# 显示列表
	display_encounter_list(sorted_records)
	
	# 触发信号
	emit_signal("history_displayed")

# 显示奇遇列表
func display_encounter_list(history_records):
	# 清空现有列表
	list_view.clear()
	
	# 添加记录到列表
	for record in history_records:
		var item_text = record.title
		if record.encounter_type != "":
			item_text += " (%s)" % record.encounter_type
		
		var item_idx = list_view.add_item(item_text)
		
		# 应用视觉反馈
		apply_visual_feedback(record, item_idx)

# 显示奇遇详情
func display_encounter_detail(selected_record):
	if selected_record == null:
		detail_view.text = "请选择一个奇遇记录查看详情"
		return
	
	var detail_text = "[center][b][u]%s[/u][/b][/center]\n\n" % selected_record.title
	detail_text += "[b]奇遇ID:[/b] %s\n" % selected_record.encounter_id
	detail_text += "[b]类型:[/b] %s\n" % selected_record.encounter_type
	detail_text += "[b]时间:[/b] %s\n" % str(selected_record.timestamp)
	detail_text += "[b]位置:[/b] (%d, %d)\n" % [int(selected_record.position.x), int(selected_record.position.y)]
	detail_text += "[b]天气:[/b] %s\n" % selected_record.weather
	detail_text += "[b]结果:[/b] %s\n" % selected_record.outcome
	detail_text += "[b]奖励:[/b] %s\n" % str(selected_record.rewards)
	detail_text += "[b]玩家等级:[/b] %d\n" % selected_record.player_level
	detail_text += "[b]玩家境界:[/b] %s\n" % selected_record.player_realm
	detail_text += "[b]玩家属性:[/b] %s\n" % str(selected_record.player_attributes)
	
	detail_view.text = detail_text

# 应用筛选
func apply_filter(records):
	var filter_type = filter_dropdown.get_item_text(filter_dropdown.selected)
	var search_term = search_box.text.to_lower()
	
	var filtered_records = []
	
	for record in records:
		var matches_filter = true
		var matches_search = true
		
		# 类型筛选
		if filter_type != "全部类型":
			if record.encounter_type != filter_type:
				matches_filter = false
		
		# 搜索筛选
		if search_term != "":
			if not record.title.to_lower().contains(search_term) and \
			   not record.encounter_type.to_lower().contains(search_term) and \
			   not record.outcome.to_lower().contains(search_term):
				matches_search = false
		
		if matches_filter and matches_search:
			filtered_records.append(record)
	
	return filtered_records

# 应用排序
func apply_sort(records):
	var sort_type = sort_dropdown.selected
	
	match sort_type:
		0: # 时间降序
			records.sort_custom(func(a, b): return a.timestamp > b.timestamp)
		1: # 时间升序
			records.sort_custom(func(a, b): return a.timestamp < b.timestamp)
		2: # 标题
			records.sort_custom(func(a, b): return a.title.to_lower() < b.title.to_lower())
	
	return records

# 应用视觉反馈
func apply_visual_feedback(record, item_idx):
	# 根据稀有度设置颜色（这里简化为根据奖励数量判断稀有度）
	var reward_count = record.rewards.size()
	if reward_count > 3:
		# 稀有记录，使用金色
		list_view.set_item_custom_fg_color(item_idx, Color.YELLOW)
	elif reward_count > 1:
		# 普通记录，使用白色
		list_view.set_item_custom_fg_color(item_idx, Color.WHITE)
	else:
		# 常见记录，使用灰色
		list_view.set_item_custom_fg_color(item_idx, Color.GRAY)

# 搜索功能
func search_records(search_term):
	# 搜索框的文本变化会自动触发刷新
	pass

# 事件处理函数
func _on_search_text_changed(new_text):
	refresh_display()

func _on_filter_selected(index):
	refresh_display()

func _on_sort_selected(index):
	refresh_display()

func _on_item_selected(index):
	var all_records = history_logger.get_all_records()
	var filtered_records = apply_filter(all_records)
	var sorted_records = apply_sort(filtered_records)
	
	if index < sorted_records.size():
		var selected_record = sorted_records[index]
		display_encounter_detail(selected_record)

# 测试函数
func test_display():
	print("开始测试查询与显示系统...")
	
	# 创建测试历史记录器
	var test_logger = load("res://src/scripts/encounter/history_logger.gd").new()
	
	# 创建测试数据
	var test_encounters = [
		{
			"id": "test_encounter_001",
			"title": "破庙避雨",
			"type": "探索",
			"outcome": "success",
			"rewards": ["神秘丹药", "经验100"],
			"position": Vector2(100, 200),
			"weather": "雨",
			"player_data": {
				"level": 5,
				"realm": "筑基",
				"attributes": {"福缘": 80, "悟性": 75}
			},
			"metadata": {"test": true}
		},
		{
			"id": "test_encounter_002",
			"title": "山中遇敌",
			"type": "战斗",
			"outcome": "victory",
			"rewards": ["精良武器", "经验200", "银两50"],
			"position": Vector2(300, 400),
			"weather": "晴",
			"player_data": {
				"level": 8,
				"realm": "筑基",
				"attributes": {"福缘": 70, "悟性": 85}
			},
			"metadata": {"test": true}
		},
		{
			"id": "test_encounter_003",
			"title": "奇人指点",
			"type": "事件",
			"outcome": "partial_success",
			"rewards": ["武学秘籍"],
			"position": Vector2(500, 600),
			"weather": "阴",
			"player_data": {
				"level": 12,
				"realm": "金丹",
				"attributes": {"福缘": 90, "悟性": 95}
			},
			"metadata": {"test": true}
		}
	]
	
	# 记录测试数据
	for test_data in test_encounters:
		test_logger.log_encounter(test_data)
	
	# 设置测试用的历史记录器
	history_logger = test_logger
	
	# 设置UI可见性（在实际使用中，这将是场景的一部分）
	visible = true
	
	# 刷新显示
	refresh_display()
	
	print("查询与显示系统测试完成")