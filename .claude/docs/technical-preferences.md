# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Forward+/Forward Mobile (Godot 4 default)
- **Physics**: Jolt Physics (Godot 4.6 default)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Steam (PC), iOS (iPhone/iPad)
- **Input Methods**: Keyboard/Mouse, Gamepad, Touch (iOS)
- **Primary Input**: Keyboard/Mouse (PC), Touch (iOS)
- **Gamepad Support**: Partial (recommended)
- **Touch Support**: Full (iOS, touch_emulate_mouse)
- **Platform Notes**: Steam PC + iOS双平台。UI需适配PC分辨率（1920x1080~3840x2160）和iOS安全区（刘海/灵动岛）。视觉小说模式天然适配触摸屏。

## Naming Conventions

- **Classes**: PascalCase (e.g., PlayerController)
- **Variables**: snake_case (e.g., move_speed)
- **Signals/Events**: snake_case past tense (e.g., health_changed)
- **Files**: snake_case matching class (e.g., player_controller.gd)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., PlayerController.tscn)
- **Constants**: UPPER_SNAKE_CASE (e.g., MAX_HEALTH)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: < 5000 for PC deployment
- **Memory Ceiling**: 8GB for PC deployment

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: 70% for core gameplay systems
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |