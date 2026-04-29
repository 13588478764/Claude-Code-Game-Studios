#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
改进所有GDScript文件
应用统一的代码改进标准
"""

import os
import re
from pathlib import Path

# 配置
SCRIPTS_DIR = "src/scripts"
EXCLUDE_DIRS = ["core", "database", "experience", "save", "test"]

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
            desc_line = line.strip().lstrip("#").strip()
            if desc_line and not desc_line.startswith("="):
                description += desc_line + "\n"
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
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        return None, f"读取文件失败: {e}"
    
    filename = os.path.basename(filepath)
    class_name = extract_class_name_from_filename(filename)
    
    # 如果已经有class_name和适当的结构，跳过
    if has_class_name(content) and has_proper_structure(content):
        return False, "已改进"
    
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
    
    # 跳过注释行和空行
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
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True, "改进成功"
    except Exception as e:
        return None, f"写入文件失败: {e}"

def find_gdscript_files(root_dir):
    """查找所有GDScript文件"""
    gdscript_files = []
    
    for root, dirs, files in os.walk(root_dir):
        # 过滤排除的目录
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        
        for file in files:
            if file.endswith(".gd") and not file.endswith(".uid"):
                filepath = os.path.join(root, file)
                gdscript_files.append(filepath)
    
    return sorted(gdscript_files)

def main():
    """主函数"""
    print("开始改进所有GDScript文件...")
    print(f"目录: {SCRIPTS_DIR}")
    print()
    
    # 查找所有GDScript文件
    gdscript_files = find_gdscript_files(SCRIPTS_DIR)
    print(f"找到 {len(gdscript_files)} 个GDScript文件")
    print()
    
    improved_count = 0
    skipped_count = 0
    error_count = 0
    
    for filepath in gdscript_files:
        filename = os.path.basename(filepath)
        result, message = improve_file(filepath)
        
        if result is True:
            print(f"✓ 改进了 {filename}")
            improved_count += 1
        elif result is False:
            print(f"⊘ {filename} - {message}")
            skipped_count += 1
        else:
            print(f"✗ {filename} - {message}")
            error_count += 1
    
    print()
    print(f"完成！")
    print(f"  改进: {improved_count} 个文件")
    print(f"  跳过: {skipped_count} 个文件")
    print(f"  错误: {error_count} 个文件")

if __name__ == "__main__":
    main()