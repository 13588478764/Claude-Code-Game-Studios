## test_inventory_panel_load.gd
## S2-07 背包面板场景加载测试

extends GutTest

func test_inventory_panel_scene_loads():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	assert_not_null(scene, "背包面板场景应该可以加载")

func test_inventory_panel_instantiates():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "背包面板场景应该可以实例化")
	instance.queue_free()

func test_inventory_panel_root_type():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "背包面板根节点应该是CanvasLayer")
	instance.queue_free()

func test_inventory_panel_script_exists():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var script_path = instance.get_script()
	assert_not_null(script_path, "场景应该有脚本附加")
	instance.queue_free()

func test_inventory_panel_z_index():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.layer, 200, "背包面板Z-index应该是200")
	instance.queue_free()

func test_inventory_panel_has_silver_label():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var silver_label = instance.get_node_or_null("PanelContainer/VBox/HeaderHBox/SilverLabel")
	assert_not_null(silver_label, "背包面板Header区域应有银两标签")
	instance.queue_free()

func test_inventory_panel_has_capacity_label():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var cap_label = instance.get_node_or_null("PanelContainer/VBox/HeaderHBox/CapacityLabel")
	assert_not_null(cap_label, "背包面板Header区域应有容量标签")
	instance.queue_free()

func test_inventory_panel_has_filter_buttons():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var filter_all = instance.get_node_or_null("PanelContainer/VBox/FilterHBox/FilterAllButton")
	var filter_equip = instance.get_node_or_null("PanelContainer/VBox/FilterHBox/FilterEquipButton")
	var filter_consumable = instance.get_node_or_null("PanelContainer/VBox/FilterHBox/FilterConsumableButton")
	var filter_material = instance.get_node_or_null("PanelContainer/VBox/FilterHBox/FilterMaterialButton")
	assert_not_null(filter_all, "应有全部过滤按钮")
	assert_not_null(filter_equip, "应有装备过滤按钮")
	assert_not_null(filter_consumable, "应有消耗品过滤按钮")
	assert_not_null(filter_material, "应有材料过滤按钮")
	instance.queue_free()

func test_inventory_panel_has_item_detail_panel():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var detail = instance.get_node_or_null("PanelContainer/VBox/ItemDetailPanel")
	assert_not_null(detail, "背包面板应有物品详情面板")
	instance.queue_free()

func test_inventory_panel_has_action_buttons():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var use_btn = instance.get_node_or_null("PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/UseButton")
	var sell_btn = instance.get_node_or_null("PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/SellButton")
	assert_not_null(use_btn, "应有使用按钮")
	assert_not_null(sell_btn, "应有出售按钮")
	instance.queue_free()
