## LODUpdateScheduler - LOD更新调度器
## 根据优先级和分辨率调度HUD组件的更新频率
class_name LODUpdateScheduler
extends Node

## 优先级定义
enum Priority {
	P0 = 0,  # 立即更新
	P1 = 1,  # 0.1秒更新一次
	P2 = 2,  # 0.3秒更新一次
	P3 = 3,  # 0.5秒更新一次
	P4 = 4   # 1秒更新一次
}

## LOD级别定义
enum LODLevel {
	LOW = 0,    # 低LOD: 1280x720
	MEDIUM = 1, # 中LOD: 1920x1080
	HIGH = 2    # 高LOD: 2560x1440+
}

## 更新间隔（秒）
var update_intervals: Dictionary = {
	Priority.P0: 0.0,
	Priority.P1: 0.1,
	Priority.P2: 0.3,
	Priority.P3: 0.5,
	Priority.P4: 1.0
}

## 注册的组件
var registered_components: Dictionary = {}
## 上次更新时间
var last_update_times: Dictionary = {}
## 当前LOD级别
var current_lod: int = LODLevel.MEDIUM
## 当前时间
var current_time: float = 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	current_time += delta
	
	# 检查分辨率变化，更新LOD级别
	_update_lod_level()

## 注册组件
func register_component(component_name: String, priority: int) -> void:
	registered_components[component_name] = priority
	last_update_times[component_name] = 0.0

## 注销组件
func unregister_component(component_name: String) -> void:
	registered_components.erase(component_name)
	last_update_times.erase(component_name)

## 检查组件是否应该更新
func should_update(component_name: String) -> bool:
	if not registered_components.has(component_name):
		return false
	
	var priority = registered_components[component_name]
	var interval = update_intervals[priority]
	
	# P0优先级总是返回true
	if priority == Priority.P0:
		return true
	
	var last_time = last_update_times.get(component_name, 0.0)
	if current_time - last_time >= interval:
		last_update_times[component_name] = current_time
		return true
	
	return false

## 更新LOD级别
func _update_lod_level() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var width = int(viewport_size.x)
	
	var new_lod = LODLevel.MEDIUM
	if width <= 1280:
		new_lod = LODLevel.LOW
	elif width >= 2560:
		new_lod = LODLevel.HIGH
	
	if new_lod != current_lod:
		current_lod = new_lod
		_on_lod_changed()

## LOD级别变化时的处理
func _on_lod_changed() -> void:
	# 重置所有组件的更新时间，强制立即更新
	for component_name in last_update_times.keys():
		last_update_times[component_name] = 0.0

## 获取当前LOD级别
func get_current_lod() -> int:
	return current_lod

## 获取LOD级别名称
func get_lod_name() -> String:
	match current_lod:
		LODLevel.LOW:
			return "LOW"
		LODLevel.MEDIUM:
			return "MEDIUM"
		LODLevel.HIGH:
			return "HIGH"
		_:
			return "UNKNOWN"

## 获取统计信息
func get_stats() -> Dictionary:
	return {
		"current_lod": get_lod_name(),
		"registered_components": registered_components.size(),
		"current_time": current_time
	}

## 强制更新所有组件
func force_update_all() -> void:
	for component_name in last_update_times.keys():
		last_update_times[component_name] = 0.0