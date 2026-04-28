#!/bin/bash

# 批量更新故事状态从 Complete 到 Pending Test
# 用于将已实现但未测试的故事标记为待测试状态

echo "开始批量更新故事状态..."

# 查找所有状态为 Complete 的故事文件
stories=$(find production/epics -name "story-*.md" -type f -exec grep -l "^> \*\*Status\*\*: Complete" {} \;)

count=0
for story in $stories; do
    # 使用 sed 替换状态
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 版本
        sed -i '' 's/^> \*\*Status\*\*: Complete$/> **Status**: Pending Test/' "$story"
    else
        # Linux 版本
        sed -i 's/^> \*\*Status\*\*: Complete$/> **Status**: Pending Test/' "$story"
    fi
    
    count=$((count + 1))
    echo "[$count] 已更新: $story"
done

echo ""
echo "✅ 完成! 共更新了 $count 个故事文件"
echo "所有故事状态已从 'Complete' 改为 'Pending Test'"