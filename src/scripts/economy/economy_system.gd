# 武侠奇遇录 - 经济系统
# 负责管理游戏中的银两、材料、商店和交易系统

extends Node

# 资源类型枚举
enum ResourceType {
	SILVER,           # 银两
	REINFORCEMENT_STONE, # 强化石
	BREAKTHROUGH_PILL,   # 突破丹
	CRAFTING_MATERIAL,   # 打造材料
	GEMSTONE,         # 宝石
	CONSUMABLE        # 消耗品
}

# 商店类型枚举
enum ShopType {
	REGULAR,    # 普通商店
	BLACK_MARKET # 黑市
}

# 经济配置
var config = {
	"silver_cap": 500000,                    # 银两上限
	"reinforcement_cost_base": 50,          # 强化基础费用
	"reinforcement_cost_multiplier": 1.5,   # 强化费用倍数
	"sell_price_ratio": 0.5,                # 出售价格比例
	"salvage_material_ratio": 0.7,         # 拆解材料比例
	"breakthrough_pill_base_price": 5000,   # 突破丹基础价格
	"black_market_refresh_hours": 24,       # 黑市刷新时间（小时）
	"luck_drop_bonus": 1.0                 # 福缘掉落加成系数
}

# 当前经济状态
var silver = 0                             # 当前银两数量
var materials = {                          # 材料库存
	"reinforcement_stone_common": 0,
	"reinforcement_stone_rare": 0,
	"reinforcement_stone_epic": 0,
	"breakthrough_pill": 0,
	"iron_ore": 0,
	"spirit_wood": 0,
	"beast_hide": 0,
	"red_gem": 0,
	"blue_gem": 0,
	"green_gem": 0,
	"yellow_gem": 0,
	"purple_gem": 0,
	"diamond_gem": 0,
	"health_potion": 0,
	"mana_potion": 0
}

# 商店库存
var shop_inventory = {
	"regular": {
		"health_potion": {"price": 50, "stock": -1},      # -1表示无限库存
		"mana_potion": {"price": 50, "stock": -1},
		"reinforcement_stone_common": {"price": 100, "stock": -1},
		"repair_hammer": {"price": 10, "stock": -1}
	},
	"black_market": {
		"reinforcement_stone_rare": {"price": 1000, "stock": 5},
		"reinforcement_stone_epic": {"price": 5000, "stock": 2},
		"breakthrough_pill": {"price": 0, "stock": 1},    # 价格动态计算
		"random_purple_equipment": {"price": 3000, "stock": 1}
	}
}

# 最后黑市刷新时间
var last_black_market_refresh = 0

func _ready():
	print("经济系统初始化完成")
	load_economy_data()

func load_economy_data():
	"""加载经济数据"""
	# 这里应该从存档加载经济数据
	# 简化实现：暂时只打印信息
	print("加载经济数据...")

func add_silver(amount):
	"""添加银两"""
	if amount <= 0:
		return false
	
	silver += amount
	if silver > config["silver_cap"]:
		silver = config["silver_cap"]
		push_warning("银两达到上限: %d" % config["silver_cap"])
	
	print("获得银两: %d (当前: %d)" % [amount, silver])
	return true

func remove_silver(amount):
	"""移除银两"""
	if amount <= 0 or silver < amount:
		return false
	
	silver -= amount
	print("消耗银两: %d (当前: %d)" % [amount, silver])
	return true

func add_material(material_type, amount):
	"""添加材料"""
	if amount <= 0:
		return
	
	if materials.has(material_type):
		materials[material_type] += amount
		print("获得材料: %s x%d (当前: %d)" % [material_type, amount, materials[material_type]])
	else:
		push_warning("未知材料类型: %s" % material_type)

func remove_material(material_type, amount):
	"""移除材料"""
	if amount <= 0 or not materials.has(material_type) or materials[material_type] < amount:
		return false
	
	materials[material_type] -= amount
	print("消耗材料: %s x%d (当前: %d)" % [material_type, amount, materials[material_type]])
	return true

func get_material_count(material_type):
	"""获取材料数量"""
	if materials.has(material_type):
		return materials[material_type]
	return 0

func calculate_sell_price(item_value):
	"""计算出售价格"""
	return int(item_value * config["sell_price_ratio"])

func calculate_salvage_materials(item_value):
	"""计算拆解材料价值"""
	return int(item_value * config["salvage_material_ratio"])

func calculate_reinforcement_cost(current_level):
	"""计算强化费用"""
	var cost = config["reinforcement_cost_base"] * pow(config["reinforcement_cost_multiplier"], current_level)
	return int(cost)

func calculate_breakthrough_pill_price(realm_level):
	"""计算突破丹价格"""
	return config["breakthrough_pill_base_price"] * realm_level

func buy_item(shop_type, item_id, quantity=1):
	"""购买物品"""
	if not shop_inventory.has(shop_type) or not shop_inventory[shop_type].has(item_id):
		push_warning("商店中没有此物品: %s" % item_id)
		return false
	
	var item_info = shop_inventory[shop_type][item_id]
	
	# 计算实际价格（突破丹需要动态计算）
	var actual_price = item_info["price"]
	if item_id == "breakthrough_pill":
		var character_system = get_node_or_null("/root/CharacterSystem")
		if character_system != null:
			actual_price = calculate_breakthrough_pill_price(character_system.realm_index + 1)
		else:
			actual_price = calculate_breakthrough_pill_price(1)  # 默认值
	
	var total_cost = actual_price * quantity
	
	# 检查库存
	if item_info["stock"] != -1 and item_info["stock"] < quantity:
		push_warning("库存不足: %s" % item_id)
		return false
	
	# 检查银两
	if silver < total_cost:
		push_warning("银两不足，需要: %d, 当前: %d" % [total_cost, silver])
		return false
	
	# 扣除银两
	remove_silver(total_cost)
	
	# 添加物品到背包
	add_material(item_id, quantity)
	
	# 更新库存
	if item_info["stock"] != -1:
		item_info["stock"] -= quantity
	
	print("购买成功: %s x%d, 花费: %d银两" % [item_id, quantity, total_cost])
	return true

func sell_item(item_id, quantity=1):
	"""出售物品"""
	if not materials.has(item_id) or materials[item_id] < quantity:
		push_warning("没有足够的物品出售: %s" % item_id)
		return false
	
	# 获取物品价值（这里简化，实际应该从物品数据库获取）
	var item_value = get_item_base_value(item_id)
	if item_value <= 0:
		push_warning("无法出售此物品: %s" % item_id)
		return false
	
	var sell_price = calculate_sell_price(item_value)
	var total_income = sell_price * quantity
	
	# 移除物品
	remove_material(item_id, quantity)
	
	# 添加银两
	add_silver(total_income)
	
	print("出售成功: %s x%d, 获得: %d银两" % [item_id, quantity, total_income])
	return true

func salvage_item(item_id, quantity=1):
	"""拆解物品"""
	if not materials.has(item_id) or materials[item_id] < quantity:
		push_warning("没有足够的物品拆解: %s" % item_id)
		return false
	
	# 获取物品价值
	var item_value = get_item_base_value(item_id)
	if item_value <= 0:
		push_warning("无法拆解此物品: %s" % item_id)
		return false
	
	var material_value = calculate_salvage_materials(item_value)
	
	# 移除物品
	remove_material(item_id, quantity)
	
	# 添加拆解材料（这里简化，实际应该根据物品类型返回不同材料）
	add_material("iron_ore", material_value)
	
	print("拆解成功: %s x%d, 获得材料价值: %d" % [item_id, quantity, material_value])
	return true

func get_item_base_value(item_id):
	"""获取物品基础价值"""
	# 这里应该从物品数据库获取物品价值
	# 简化实现：根据物品类型返回固定价值
	match item_id:
		"health_potion":
			return 100
		"mana_potion":
			return 100
		"reinforcement_stone_common":
			return 200
		"reinforcement_stone_rare":
			return 2000
		"reinforcement_stone_epic":
			return 10000
		"breakthrough_pill":
			return 10000
		"iron_ore":
			return 50
		"spirit_wood":
			return 50
		"beast_hide":
			return 50
		"red_gem":
			return 500
		"blue_gem":
			return 500
		"green_gem":
			return 500
		"yellow_gem":
			return 500
		"purple_gem":
			return 1000
		"diamond_gem":
			return 5000
		_:
			return 0

func refresh_black_market():
	"""刷新黑市"""
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_black_market_refresh >= config["black_market_refresh_hours"] * 3600:
		# 重置黑市库存
		shop_inventory["black_market"]["reinforcement_stone_rare"]["stock"] = 5
		shop_inventory["black_market"]["reinforcement_stone_epic"]["stock"] = 2
		shop_inventory["black_market"]["breakthrough_pill"]["stock"] = 1
		shop_inventory["black_market"]["random_purple_equipment"]["stock"] = 1
		
		last_black_market_refresh = current_time
		print("黑市已刷新")
		return true
	
	return false

func calculate_drop_bonus(luck_stat):
	"""计算掉落加成"""
	return 1.0 + (luck_stat / 100.0) * config["luck_drop_bonus"]

func add_drop_rewards(enemy_level, enemy_type, luck_stat):
	"""添加战斗掉落奖励"""
	var drop_multiplier = calculate_drop_bonus(luck_stat)
	
	# 基础银两掉落
	var base_silver = 0
	match enemy_type:
		"normal":
			base_silver = enemy_level * 5 + randi_range(0, 10)
		"elite":
			base_silver = enemy_level * 20 + randi_range(20, 50)
		"boss":
			base_silver = enemy_level * 100 + randi_range(100, 300)
		_:
			base_silver = enemy_level * 5
	
	var final_silver = int(base_silver * drop_multiplier)
	add_silver(final_silver)
	
	# 材料掉落
	if enemy_type == "normal" and randf() < 0.1:
		add_material("reinforcement_stone_common", 1)
	elif enemy_type == "elite":
		if randf() < 0.5:
			add_material("reinforcement_stone_rare", 1)
		if randf() < 0.2:
			add_material("red_gem", 1)
	elif enemy_type == "boss":
		add_material("reinforcement_stone_epic", 1)
		if randf() < 0.8:
			add_material("purple_gem", 1)
	
	print("战斗掉落: %d银两" % final_silver)

func repair_equipment(max_durability):
	"""修理装备"""
	var repair_cost = int(max_durability * 0.1)
	if remove_silver(repair_cost):
		print("装备修理成功，花费: %d银两" % repair_cost)
		return true
	return false

func fast_travel_cost(distance):
	"""计算快速旅行费用"""
	if distance <= 100:  # 短距离免费
		return 0
	return distance * 10

func pay_fast_travel(distance):
	"""支付快速旅行费用"""
	var cost = fast_travel_cost(distance)
	if cost == 0:
		return true
	if remove_silver(cost):
		print("快速旅行成功，花费: %d银两" % cost)
		return true
	return false

# 调试函数
func debug_print_economy_info():
	"""打印经济信息用于调试"""
	print("=== 经济系统信息 ===")
	print("银两: %d" % silver)
	print("材料库存:")
	for material in materials:
		if materials[material] > 0:
			print("  %s: %d" % [material, materials[material]])
	
	print("普通商店库存:")
	for item in shop_inventory["regular"]:
		var stock = shop_inventory["regular"][item]["stock"]
		var price = shop_inventory["regular"][item]["price"]
		print("  %s: 价格=%d, 库存=%s" % [item, price, "无限" if stock == -1 else str(stock)])
	
	print("黑市库存:")
	for item in shop_inventory["black_market"]:
		var stock = shop_inventory["black_market"][item]["stock"]
		var price = shop_inventory["black_market"][item]["price"]
		if item == "breakthrough_pill":
			var character_system = get_node_or_null("/root/CharacterSystem")
			if character_system != null:
				price = calculate_breakthrough_pill_price(character_system.realm_index + 1)
			else:
				price = calculate_breakthrough_pill_price(1)  # 默认值
		print("  %s: 价格=%d, 库存=%s" % [item, price, "无限" if stock == -1 else str(stock)])
	
	print("====================")

# UI回调函数
func _on_test_combat_drop_pressed():
	"""测试战斗掉落按钮回调"""
	print("=== 战斗掉落测试 ===")
	
	# 初始化角色数据
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(1000)  # 升级到10级
	else:
		push_warning("无法访问CharacterSystem")
	
	# 测试不同敌人类型的掉落
	add_drop_rewards(10, "normal", 50)   # 普通敌人，福缘50
	add_drop_rewards(10, "elite", 50)   # 精英敌人，福缘50
	add_drop_rewards(10, "boss", 50)    # Boss敌人，福缘50
	
	# 检查经济状态
	debug_print_economy_info()
	
	print("====================")

func _on_test_shop_purchase_pressed():
	"""测试商店购买按钮回调"""
	print("=== 商店购买测试 ===")
	
	# 添加初始银两
	silver = 10000
	
	# 购买普通商店物品
	buy_item("regular", "health_potion", 5)
	buy_item("regular", "reinforcement_stone_common", 2)
	
	# 购买黑市物品
	buy_item("black_market", "reinforcement_stone_rare", 1)
	
	# 检查经济状态
	debug_print_economy_info()
	
	print("====================")

func _on_test_item_sell_pressed():
	"""测试物品出售按钮回调"""
	print("=== 物品出售测试 ===")
	
	# 添加测试物品
	materials["health_potion"] = 10
	materials["reinforcement_stone_common"] = 5
	
	# 出售物品
	sell_item("health_potion", 5)
	sell_item("reinforcement_stone_common", 2)
	
	# 检查经济状态
	debug_print_economy_info()
	
	print("====================")

func _on_test_reinforcement_cost_pressed():
	"""测试强化费用按钮回调"""
	print("=== 强化费用测试 ===")
	
	# 测试不同强化等级的费用
	for level in range(1, 6):
		var cost = calculate_reinforcement_cost(level)
		print("强化到+%d级费用: %d银两" % [level, cost])
	
	# 测试突破丹价格
	for realm in range(1, 5):
		var pill_price = calculate_breakthrough_pill_price(realm)
		print("境界%d突破丹价格: %d银两" % [realm, pill_price])
	
	print("====================")