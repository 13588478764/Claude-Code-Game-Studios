# ADR-001: 核心架构决策

> **Status**: Accepted
> **Date**: 2026-04-26
> **Engine**: Godot 4.6
> **Affected Systems**: All

## Decision

采用 Godot 4.6 作为游戏引擎，使用 GDScript 编程语言，基于节点系统和信号系统构建游戏架构。

## Context

项目需要一个稳定、高效的游戏引擎来实现武侠 RPG 游戏。Godot 4.6 提供了：
- 完整的 2D/3D 支持
- 强大的节点系统和场景树
- 灵活的信号系统用于事件驱动编程
- 跨平台支持
- 开源和活跃的社区

## Implementation Guidelines

### 架构原则

1. **节点系统**
   - 所有游戏对象都应该继承自 Godot Node 类
   - 使用场景树组织游戏对象层级
   - 利用 `_ready()` 进行初始化，`_process()` 进行更新

2. **信号系统**
   - 使用信号实现系统间的通信
   - 避免直接的系统间依赖
   - 信号命名规范：`snake_case`，动词形式（如 `level_up`, `health_changed`）

3. **脚本组织**
   - 核心系统使用专用的 Manager 节点
   - 业务逻辑与 UI 分离
   - 使用依赖注入模式传递系统引用

4. **性能优化**
   - 使用对象池管理频繁创建/销毁的对象
   - 避免在 `_process()` 中进行复杂计算
   - 使用 `call_deferred()` 延迟非关键操作

### 命名规范

**文件和类名**:
- 系统文件：`[system]_system.gd` 或 `[system]_manager.gd`
- UI 脚本：`[screen]_ui.gd` 或 `[component]_ui_script.gd`
- 场景文件：`[system].tscn` 或 `[screen].tscn`

**信号名**:
- 格式：`snake_case`
- 示例：`level_up`, `health_changed`, `item_acquired`

**常量和枚举**:
- 格式：`UPPER_CASE`
- 示例：`MAX_LEVEL`, `COMBAT_STATE_NORMAL`

### 禁止模式

1. **禁止直接 UI 修改**
   - 业务逻辑不应直接修改 UI
   - 使用信号通知 UI 更新

2. **禁止全局变量**
   - 使用 Manager 节点和依赖注入
   - 避免 Autoload 单例（除非必要）

3. **禁止硬编码值**
   - 使用配置文件或常量
   - 数值应该来自 GDD 或配置

### 必需模式

1. **依赖注入**
   - 系统通过 `initialize()` 方法接收依赖
   - 避免在 `_ready()` 中查找其他节点

2. **信号驱动**
   - 系统间通信使用信号
   - 事件应该被发射而不是直接调用

3. **文档注释**
   - 所有公共方法使用 `##` 注释
   - 包含参数、返回值和异常说明

## Engine Compatibility

### Godot 4.6 特定说明

- **信号语法**: 使用 `signal_name.connect(callback)` 而不是 `connect("signal_name", self, "callback")`
- **类型提示**: 使用 `->` 进行返回类型提示
- **@onready**: 使用 `@onready` 注解自动初始化节点引用
- **枚举**: 使用 `enum` 定义状态和常量

### 已知限制

- GDScript 自动类型转换可能导致浮点数被转换为整数
- 需要显式类型转换时使用 `float()` 或 `int()`

## Consequences

### 优势

- ✅ 统一的架构风格
- ✅ 易于维护和扩展
- ✅ 清晰的系统边界
- ✅ 便于测试和调试

### 劣势

- ⚠️ 需要严格遵守规范
- ⚠️ 初期开发速度可能较慢
- ⚠️ 需要团队培训

## ADR Dependencies

无（这是第一个核心架构决策，不依赖其他 ADR）

## GDD Requirements Addressed

本 ADR 支持以下 GDD 系统：
- 游戏概念文档（design/gdd/game-concept.md）
- 所有核心游戏系统的技术基础
- 项目整体架构标准定义

## Related Decisions

- ADR-002: 战斗系统架构（待创建）
- ADR-003: UI 系统架构（待创建）

## References

- Godot 4.6 官方文档: https://docs.godotengine.org/
- GDScript 风格指南: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/style_guide.html