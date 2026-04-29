#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
改进encounter目录中的GDScript文件
应用统一的代码改进标准
"""

import os
import re
from pathlib import Path

# 配置
ENCOUNTER_DIR = "src/scripts/encounter"
FILES_TO_IMPROVE = [
    "encounter_data_structures.gd",
    "encounter_integration.gd",
    "encounter_record_manager.gd",
    "encounter_reward_manager.gd",
    "history_display_manager.gd",
    "history_logger.gd",
    "history_persistence_manager.gd",
    "logic_tree_manager.gd",
    "trigger_mechanism_manager.gd",
]

def extract_class_name_from_filename(filename):
    """从文件名提取类名"""
    # 将snake_case转换为PascalCase
    parts = filename.replace(".gd", "").split("_")
    return "".join(word.capitalize() for word in parts)

def extract_file_description(content):
    """从文件内容中提取文件描述"""
    # 查找第一个注释块
    lines = content.split("\n")
    description = ""
    for line in lines[:20]:
        if line.strip().startswith("#"):
            description += line.strip().lstrip("#").strip() + "\n"
        elif line.strip() == "":
            continue
        else:
            break
    return description.strip()

def has_class_name(content):
    """检查文件是否有class_name定义"""
    return "class_name" in content

def has_proper_structure(content):
    """检查文件是否有适当的结构"""
    return "# ============================================================================" in content

def improve_file(filepath):
    """改进单个文件"""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    filename = os.path.basename(filepath)
    class_name = extract_class_name_from_filename(filename)
    
    # 如果已经有class_name和适当的结构，跳过
    if has_class_name(content) and has_proper_structure(content):
        print(f"✓ {filename} 已经改进过，跳过")
        return False
    
    # 提取文件描述
    description = extract_file_description(content)
    if not description:
        description = f"{class_name}系统"
    
    # 构建新的文件头
    new_header = f"""## {class_name}
## {description}
##
## 主要功能：
## - 待补充

extends Node

class_name {class_name}

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================
"""
    
    # 移除原始的文件头和extends/class_name定义
    lines = content.split("\n")
    start_idx = 0
    
    # 跳过注释行
    for i, line in enumerate(lines):
        if line.strip().startswith("extends") or line.strip().startswith("class_name"):
            start_idx = i + 1
            break
        elif not line.strip().startswith("#") and line.strip() != "":
            start_idx = i
            break
    
    # 获取剩余的内容
    remaining_content = "\n".join(lines[start_idx:]).strip()
    
    # 组合新的文件内容
    new_content = new_header + "\n" + remaining_content
    
    # 写入文件
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(new_content)
    
    print(f"✓ 改进了 {filename}")
    return True

def main():
    """主函数"""
    print("开始改进encounter目录中的文件...")
    print(f"目录: {ENCOUNTER_DIR}")
    print()
    
    improved_count = 0
    
    for filename in FILES_TO_IMPROVE:
        filepath = os.path.join(ENCOUNTER_DIR, filename)
        
        if not os.path.exists(filepath):
            print(f"✗ 文件不存在: {filepath}")
            continue
        
        try:
            if improve_file(filepath):
                improved_count += 1
        except Exception as e:
            print(f"✗ 改进 {filename} 时出错: {e}")
    
    print()
    print(f"完成！改进了 {improved_count} 个文件")

if __name__ == "__main__":
    main()