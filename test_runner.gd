# 简单的测试运行脚本

extends Node

func _ready():
	# 加载并运行测试
	var test_script = load("res://tests/unit/encounter/trigger_mechanisms_and_events_test.gd")
	var test_instance = test_script.new()
	
	# 运行测试
	var results = test_instance.test_all()
	
	# 输出结果
	var passed_count = 0
	var total_count = results.size()
	
	print("开始运行触发机制与事件测试...")
	print("================================")
	
	for result in results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	# 退出
	get_tree().quit()