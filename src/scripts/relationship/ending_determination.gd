## 结局判定系统
## 根据道心值和NPC关系值判定游戏结局
extends RefCounted
class_name EndingDetermination

## 结局类型
enum EndingType {
	DEFAULT,
	RIGHTEOUS_LEADER,
	EVIL_OVERLORD,
	HIDDEN_MASTER,
	FREE_SPIRIT,
}

## 阈值容忍度调节（降低所有阈值要求）
var ending_threshold_tolerance: int = 0

## 判定结局，返回 EndingType
func determine_ending(relationship_manager: RelationshipManager) -> EndingType:
	# 优先级: 隐世 > 逍遥 > 正道 > 魔道 > 默认
	if _check_hidden_master(relationship_manager):
		return EndingType.HIDDEN_MASTER
	if _check_free_spirit(relationship_manager):
		return EndingType.FREE_SPIRIT
	if _check_righteous_leader(relationship_manager):
		return EndingType.RIGHTEOUS_LEADER
	if _check_evil_overlord(relationship_manager):
		return EndingType.EVIL_OVERLORD
	return EndingType.DEFAULT

## 获取结局名称
static func get_ending_name(ending: EndingType) -> String:
	match ending:
		EndingType.RIGHTEOUS_LEADER:
			return "正道领袖"
		EndingType.EVIL_OVERLORD:
			return "魔道霸主"
		EndingType.HIDDEN_MASTER:
			return "隐世大能"
		EndingType.FREE_SPIRIT:
			return "逍遥散仙"
		_:
			return "江湖浪子"

## 正道领袖: 道心>=60, 柳如烟关系>=70, 玄机真人关系>=50
func _check_righteous_leader(rm: RelationshipManager) -> bool:
	var t := ending_threshold_tolerance
	return (rm.get_dao_heart_value() >= 60 - t
		and rm.get_relationship_value("liuruyan") >= 70 - t
		and rm.get_relationship_value("xuanjizhenren") >= 50 - t)

## 魔道霸主: 道心<=-60, 萧寒夜关系>=70, 血无痕关系>=30
func _check_evil_overlord(rm: RelationshipManager) -> bool:
	var t := ending_threshold_tolerance
	return (rm.get_dao_heart_value() <= -60 + t
		and rm.get_relationship_value("xiaohanye") >= 70 - t
		and rm.get_relationship_value("xuewuhen") >= 30 - t)

## 隐世大能: 道心-30~+30, 慕容雪关系>=80, 玄机真人关系>=60
func _check_hidden_master(rm: RelationshipManager) -> bool:
	var t := ending_threshold_tolerance
	var dao := rm.get_dao_heart_value()
	return (dao >= -30 - t and dao <= 30 + t
		and rm.get_relationship_value("murongxue") >= 80 - t
		and rm.get_relationship_value("xuanjizhenren") >= 60 - t)

## 逍遥散仙: 所有核心NPC关系>=50, 道心-20~+20
func _check_free_spirit(rm: RelationshipManager) -> bool:
	var t := ending_threshold_tolerance
	var dao := rm.get_dao_heart_value()
	if dao < -20 - t or dao > 20 + t:
		return false

	var core_npcs := ["yunzhonghe", "liuruyan", "xuanjizhenren", "xiaohanye", "xuewuhen", "murongxue"]
	for npc_id in core_npcs:
		if rm.get_relationship_value(npc_id) < 50 - t:
			return false
	return true
