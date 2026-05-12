extends PanelContainer
class_name PartyMemberSlot

## 单个队友槽位
## 显示队友头像、HP条和倒地状态

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var info_container: VBoxContainer = $HBoxContainer/InfoContainer
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var hp_bar: ProgressBar = $HBoxContainer/InfoContainer/HPBar
@onready var hp_label: Label = $HBoxContainer/InfoContainer/HPBar/HPLabel
@onready var downed_overlay: ColorRect = $DownedOverlay

# 缓存数据
var _member_id: String = ""
var _cached_hp: int = 0
var _cached_max_hp: int = 1
var _cached_is_downed: bool = false
var _hp_dirty: bool = false

func _ready() -> void:
	# 设置初始状态
	downed_overlay.hide()
	portrait.custom_minimum_size = Vector2(60, 60)
	hp_bar.custom_minimum_size = Vector2(240, 16)

func _process(_delta: float) -> void:
	if _hp_dirty:
		_apply_hp_update()
		_hp_dirty = false

# ============================================================================
# 公共接口
# ============================================================================

func set_member_data(member: Dictionary) -> void:
	## 设置队友数据
	_member_id = member["id"]
	name_label.text = member["name"]
	update_hp(member["hp"], member["max_hp"])
	set_downed_state(member["is_downed"])
	_load_portrait(member["id"])

func update_member_data(member: Dictionary) -> void:
	## 更新队友数据
	name_label.text = member["name"]
	update_hp(member["hp"], member["max_hp"])
	set_downed_state(member["is_downed"])

func update_hp(current: int, max_value: int) -> void:
	## 更新HP值(带平滑过渡动画)
	if _cached_hp != current or _cached_max_hp != max_value:
		_cached_hp = current
		_cached_max_hp = max_value
		_hp_dirty = true
		# 立即应用 HP 颜色（不等下一帧 _process）：
		# - 颜色是关键即时反馈，延迟会导致初次显示一帧白色
		# - 测试也依赖立即可观察的颜色状态
		# - tween 动画本身仍是异步的，所以"立即"指的是 modulate 颜色立即生效，
		#   bar 的 value 通过 tween 0.1s 平滑过渡到目标
		# 注意：必须 is_node_ready 才能访问 @onready 节点，
		# 否则首次 set_member_data 时（_ready 之前）会失败
		if is_node_ready():
			_apply_hp_update()
			_hp_dirty = false

func set_downed_state(is_downed: bool) -> void:
	## 设置倒地状态
	if _cached_is_downed != is_downed:
		_cached_is_downed = is_downed
		
		if is_downed:
			# 倒地:显示灰色滤镜,隐藏HP条
			downed_overlay.show()
			hp_bar.hide()
		else:
			# 复活:隐藏灰色滤镜,显示HP条
			downed_overlay.hide()
			hp_bar.show()

# ============================================================================
# 内部函数
# ============================================================================

func _apply_hp_update() -> void:
	## 应用HP更新(带平滑过渡动画)
	hp_bar.max_value = float(_cached_max_hp)
	hp_label.text = "%d / %d" % [_cached_hp, _cached_max_hp]
	
	# HP条平滑过渡(0.1秒)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hp_bar, "value", float(_cached_hp), 0.1)
	
	# 根据HP百分比改变颜色
	var hp_percentage = float(_cached_hp) / _cached_max_hp
	if hp_percentage < 0.3:
		hp_bar.modulate = Color.RED
	elif hp_percentage < 0.6:
		hp_bar.modulate = Color.YELLOW
	else:
		hp_bar.modulate = Color.GREEN

func _load_portrait(member_id: String) -> void:
	## 加载队友头像
	var portrait_path = "res://assets/ui/party_portraits/party_member_%s.png" % member_id
	
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	else:
		push_warning("Missing party portrait: %s" % portrait_path)
		portrait.texture = _create_default_portrait(member_id)

func _create_default_portrait(member_id: String) -> Texture2D:
	## 创建默认占位符头像
	var image = Image.create(60, 60, false, Image.FORMAT_RGBA8)
	
	# 填充灰色圆形
	for y in range(60):
		for x in range(60):
			var dx = x - 30.0
			var dy = y - 30.0
			var distance = sqrt(dx * dx + dy * dy)
			
			if distance <= 28:
				image.set_pixel(x, y, Color.GRAY)
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	
	var texture = ImageTexture.create_from_image(image)
	return texture