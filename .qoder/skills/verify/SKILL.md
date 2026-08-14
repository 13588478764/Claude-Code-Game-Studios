---
name: verify
description: 运行 GUT 单元+集成测试并汇总结果。在完成 gameplay/逻辑改动后、提交前、或用户要求验证时使用。
---

运行本仓库的自动化测试并给出结论。

## 步骤

1. 依次运行两套测试（每个可能需要 1-3 分钟，耐心等待完成）：
   ```bash
   godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit -ginclude_subdirs -glog=1
   godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/integration -ginclude_subdirs -glog=1
   ```
   注意：必须带 `-ginclude_subdirs`，否则只跑顶层 3 个脚本（46 测试），漏掉约 400 个子系统测试。
2. 解析输出：统计 通过/失败/跳过 数量，列出每个失败测试的名称与断言信息。
3. 如有失败，先读失败测试与被测代码，判断是回归还是测试本身过期，给出修复方向但不要擅自修改（遵循仓库协作协议）。
4. 只改动单个系统时，可只跑对应子目录加速，如 `-gdir=tests/unit/combat`；但最终结论前必须完整跑一遍 unit。

## 汇总格式

- 单元测试：X 通过 / Y 失败 / Z 跳过
- 集成测试：X 通过 / Y 失败 / Z 跳过
- 失败明细（如有）+ 初步归因
- 结论：可提交 / 需修复
