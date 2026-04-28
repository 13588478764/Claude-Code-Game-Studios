#!/bin/bash

# GUT 测试运行脚本
# 用于运行 Godot Unit Test (GUT) 框架的测试

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$PROJECT_ROOT/src"

echo -e "${GREEN}=== GUT 测试运行器 ===${NC}"
echo "项目目录: $PROJECT_ROOT"
echo "源代码目录: $SRC_DIR"
echo ""

# 检查 Godot 是否安装
if ! command -v godot &> /dev/null; then
    echo -e "${RED}错误: 未找到 Godot 命令${NC}"
    echo "请确保 Godot 已安装并添加到 PATH"
    exit 1
fi

# 检查 GUT 框架是否存在
if [ ! -d "$SRC_DIR/addons/gut" ]; then
    echo -e "${RED}错误: 未找到 GUT 框架${NC}"
    echo "请确保 GUT 框架已安装在 src/addons/gut/"
    exit 1
fi

# 进入源代码目录
cd "$SRC_DIR" || exit 1

# 显示使用说明
show_usage() {
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all                    运行所有测试"
    echo "  character              运行角色系统测试"
    echo "  enemy_scaling          运行敌人缩放系统测试"
    echo "  attribute              运行属性点机制测试"
    echo "  <test_file_path>       运行指定的测试文件"
    echo ""
    echo "示例:"
    echo "  $0 all"
    echo "  $0 character"
    echo "  $0 attribute"
    echo "  $0 res://tests/unit/character/attribute_point_mechanics_test.gd"
}

# 运行测试
run_tests() {
    local test_arg="$1"
    
    echo -e "${YELLOW}运行测试...${NC}"
    echo ""
    
    case "$test_arg" in
        all)
            echo "运行所有测试"
            godot -d -s addons/gut/gut.gd
            ;;
        character)
            echo "运行角色系统测试"
            godot -d -s addons/gut/gut.gd -gdir=res://tests/unit/character
            ;;
        enemy_scaling)
            echo "运行敌人缩放系统测试"
            godot -d -s addons/gut/gut.gd -gdir=res://tests/unit/enemy_scaling
            ;;
        attribute)
            echo "运行属性点机制测试"
            godot -d -s addons/gut/gut.gd -gtest=res://tests/unit/character/attribute_point_mechanics_test.gd
            ;;
        res://*)
            echo "运行指定测试: $test_arg"
            godot -d -s addons/gut/gut.gd -gtest="$test_arg"
            ;;
        *)
            echo -e "${RED}未知选项: $test_arg${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# 主逻辑
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}未指定测试选项，运行所有测试${NC}"
    echo ""
    run_tests "all"
else
    run_tests "$1"
fi

echo ""
echo -e "${GREEN}测试完成${NC}"