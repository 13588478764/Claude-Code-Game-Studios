#!/bin/bash
# 运行UI集成测试脚本

echo "========================================="
echo "运行UI集成测试"
echo "========================================="

# 设置Godot路径（根据您的系统调整）
GODOT_PATH="godot"

# 检查Godot是否可用
if ! command -v $GODOT_PATH &> /dev/null; then
    echo "错误: 找不到Godot命令。请确保Godot已安装并在PATH中。"
    exit 1
fi

echo ""
echo "测试1: 角色成长UI集成测试"
echo "-----------------------------------------"
$GODOT_PATH --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/integration/ui/character_growth_ui_integration_test.gd -gexit

echo ""
echo "测试2: 奇遇事件UI集成测试"
echo "-----------------------------------------"
$GODOT_PATH --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/integration/ui/encounter_ui_integration_test.gd -gexit

echo ""
echo "========================================="
echo "集成测试完成"
echo "========================================="