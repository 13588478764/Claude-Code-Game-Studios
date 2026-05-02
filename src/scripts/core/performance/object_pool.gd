## ObjectPool基类 - 对象复用池
## 用于减少GC压力，提高性能
class_name ObjectPool
extends Node

## 池中对象的最大数量
var pool_size: int = 10
## 池中可用对象列表
var available_objects: Array = []
## 池中已使用对象列表
var in_use_objects: Array = []
## 对象创建函数
var object_factory: Callable
## 对象重置函数
var reset_function: Callable

func _init(p_pool_size: int, p_factory: Callable, p_reset: Callable) -> void:
	pool_size = p_pool_size
	object_factory = p_factory
	reset_function = p_reset
	
	# 预分配对象
	for i in range(pool_size):
		var obj = object_factory.call()
		available_objects.append(obj)

## 从池中获取对象
func acquire() -> Variant:
	if available_objects.is_empty():
		# 池耗尽，自动扩容或复用最旧的对象
		var obj = object_factory.call()
		in_use_objects.append(obj)
		return obj
	
	var obj = available_objects.pop_back()
	in_use_objects.append(obj)
	return obj

## 将对象归还到池中
func release(obj: Variant) -> void:
	if obj in in_use_objects:
		in_use_objects.erase(obj)
		reset_function.call(obj)
		available_objects.append(obj)

## 获取池的统计信息
func get_stats() -> Dictionary:
	return {
		"pool_size": pool_size,
		"available": available_objects.size(),
		"in_use": in_use_objects.size(),
		"total": available_objects.size() + in_use_objects.size()
	}

## 清空池
func clear() -> void:
	available_objects.clear()
	in_use_objects.clear()

## 获取可用对象数量
func get_available_count() -> int:
	return available_objects.size()

## 获取已使用对象数量
func get_in_use_count() -> int:
	return in_use_objects.size()