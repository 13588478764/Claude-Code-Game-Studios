extends CanvasLayer

# 战斗反馈系统管理器
# 处理伤害数字颜色、战斗特效、音频反馈和状态效果视觉反馈

# 信号定义
signal feedback_played

# 预制体路径
var damage_number_prefab = preload("res://src/scenes/ui/damage_number.tscn")
var combat_effect_prefab = preload("res://src/scenes/ui/combat_effect.tscn")
var status_icon_animation_prefab = preload("res://src/scenes/ui/status_icon_animation.tscn")

# 音频资源路径
var audio_resources = {
	"ui_click": "res://src/assets/audio/ui_click.wav",
	"hit": "res://src/assets/audio/hit.wav",
	"critical": "res://src/assets/audio/critical.wav",
	"skill": "res://src/assets/audio/skill.wav",
	"background_music": "res://src/assets/audio/battle_bgm.wav"
}

# 初始化
func _ready():
	# 初始化音频系统
	initialize_audio_system()

# 初始化音频系统
func initialize_audio_system():
	# 预加载音频资源
	for key in audio_resources:
		var resource = load(audio_resources[key])
		audio_resources[key] = resource

# 显示伤害数字
func show_damage_number(damage_data):
	# 创建伤害数字节点
	var damage_number = damage_number_prefab.instantiate()
	
	# 设置伤害数字文本
	damage_number.text = str(damage_data.value)
	
	# 根据伤害类型设置颜色
	var damage_color = get_damage_color(damage_data.type)
	damage_number.add_theme_color_override("font_color", damage_color)
	
	# 设置位置
	damage_number.position = damage_data.position
	
	# 添加到场景
	$CombatFeedback.add_child(damage_number)
	
	# 播放动画
	play_damage_number_animation(damage_number)
	
	emit_signal("feedback_played")

# 获取伤害颜色
func get_damage_color(damage_type):
	if damage_type == "外功":
		return Color.WHITE
	elif damage_type == "内功":
		return Color.BLUE
	elif damage_type == "暴击":
		return Color.GOLD
	elif damage_type == "真实":
		return Color.RED
	else:
		return Color.WHITE

# 播放伤害数字动画
func play_damage_number_animation(damage_number):
	# 创建动画
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	# 位置动画
	tween.tween_property(damage_number, "position", damage_number.position + Vector2(0, -100), 1.0)
	
	# 透明度动画
	tween.tween_property(damage_number, "modulate:a", 0.0, 1.0)
	
	# 动画完成后删除节点
	tween.tween_callback(damage_number.queue_free)

# 播放战斗特效
func play_combat_effect(effect_type, position):
	# 根据特效类型创建对应的特效
	var effect = combat_effect_prefab.instantiate()
	effect.position = position
	
	# 设置特效类型
	effect.set_effect_type(effect_type)
	
	# 添加到场景
	$CombatFeedback.add_child(effect)
	
	# 播放特效动画
	play_effect_animation(effect)
	
	emit_signal("feedback_played")

# 播放特效动画
func play_effect_animation(effect):
	# 创建动画
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	# 缩放动画
	tween.tween_property(effect, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(effect, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
	
	# 透明度动画
	tween.tween_property(effect, "modulate:a", 0.0, 0.8).set_delay(0.4)
	
	# 动画完成后删除节点
	tween.tween_callback(effect.queue_free)

# 播放音频反馈
func play_audio_feedback(audio_type):
	# 检查音频类型是否存在
	if audio_resources.has(audio_type):
		var audio_stream = audio_resources[audio_type]
		
		# 创建音频播放器
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = audio_stream
		add_child(audio_player)
		
		# 播放音频
		audio_player.play()
		
		# 播放完成后删除节点
		audio_player.connect("finished", Callable(audio_player, "queue_free"))
	
	emit_signal("feedback_played")

# 处理状态图标动画
func animate_status_icons(status_data):
	# 为每个状态效果创建动画
	for status in status_data:
		var animation = status_icon_animation_prefab.instantiate()
		
		# 设置状态图标
		animation.set_status_icon(status.icon)
		
		# 设置动画参数
		animation.set_duration(status.duration)
		
		# 添加到状态图标容器
		$CombatFeedback/StatusIcons.add_child(animation)
		
		# 播放动画
		play_status_icon_animation(animation)
	
	emit_signal("feedback_played")

# 播放状态图标动画
func play_status_icon_animation(animation):
	# 创建动画
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	# 旋转动画
	tween.tween_method(animation.rotate, 0, TAU, 2.0)
	
	# 闪烁动画
	tween.tween_property(animation, "modulate:a", 0.5, 0.5, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_loops(4)
	
	# 持续时间动画
	var duration = animation.get_duration()
	tween.tween_property(animation, "scale", Vector2(0.8, 0.8), duration)

# 处理战斗事件反馈
func handle_combat_event(event_data):
	match event_data.type:
		"damage_dealt":
			show_damage_number(event_data.data)
		"skill_used":
			play_combat_effect("skill", event_data.position)
			play_audio_feedback("skill")
		"hit":
			play_combat_effect("hit", event_data.position)
			play_audio_feedback("hit")
		"critical":
			play_combat_effect("critical", event_data.position)
			play_audio_feedback("critical")
		"status_applied":
			animate_status_icons([event_data.data])
		"ui_interaction":
			play_audio_feedback("ui_click")

# 同步战斗反馈
func sync_feedback_with_combat(attack_data):
	# 确保反馈与战斗事件同步
	if Engine.get_main_loop().get_process_time() < 0.05:  # 50ms延迟检查
		handle_combat_event(attack_data)
	else:
		# 如果延迟过高，记录警告
		print("WARNING: Combat feedback delay exceeds 50ms")

# 检查性能影响
func check_performance_impact():
	# 检查当前场景中的反馈节点数量
	var feedback_nodes = $CombatFeedback.get_children()
	
	if feedback_nodes.size() > 20:  # 如果反馈节点过多
		print("WARNING: Too many feedback nodes, performance may be impacted")
		# 清理一些旧的反馈节点
		cleanup_old_feedback()

# 清理旧的反馈
func cleanup_old_feedback():
	var feedback_nodes = $CombatFeedback.get_children()
	
	# 移除一半的节点
	for i in range(feedback_nodes.size() / 2):
		if feedback_nodes.size() > 0:
			feedback_nodes[i].queue_free()