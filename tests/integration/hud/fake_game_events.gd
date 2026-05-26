extends Node
## FakeGameEvents — 仅用于 hud_signal_bridge_test 的 GameEvents 替身
##
## 用 declared signals 替代 add_user_signal, 因为 combat_manager 通过
## `_game_events.signal_name.emit()` 点访问要求是 Signal 属性, 不能是 user signal。
##
## 包含 P0 10/10 HUD 桥接信号 (s7-18 主 PR 8 个 + A2 PR 新增 2 个) + 战斗周期信号。

signal combat_started()
signal combat_ended(victory: bool, rewards: Dictionary)
signal combat_turn_changed(turn_number: int)
signal player_hp_changed(current: int, max_value: int)
signal player_qi_changed(current: int, max_value: int)
signal player_poise_changed(current: int, max_value: int)
signal enemy_hp_changed(enemy_id: String, current: int, max_value: int)
signal enemy_selected(enemy: Dictionary)
signal combat_action_queue_updated(queue: Array)
# A2 PR 新增 — WeaknessSystem 桥接
signal enemy_weakness_revealed(enemy_id: String, element: String)
signal enemy_status_changed(enemy_id: String, status: String)
