---
name: xianyu-automation
description: 闲鱼自动化技能。触发：(1)用户说"登录检测"→模块1 (2)用户说"搜索商品"→模块2 (3)用户说"价格监控"→模块3 (4)用户说"发布商品"→模块4
---

# 闲鱼自动化

## ⚠️ 前提条件

**仅使用 AppleScript 操作 Safari，无需 MCP。**

每次操作前需确保 Safari 已运行：
```bash
osascript -e 'tell application "Safari" to activate'
```

## 模块索引

| 触发条件 | 功能 | 脚本 |
|---------|------|------|
| "登录检测" | 登录状态检测 | scripts/01_login_check.sh |
| "搜索商品" | 商品搜索 | scripts/02_search.sh |
| "价格监控" | 价格变动监控 | scripts/03_price_watch.sh |
| "发布商品" | 发布商品 | scripts/04_publish.sh |

## 核心工具：AppleScript

所有 Safari 操作均通过 AppleScript 实现，不依赖 MCP：

```bash
# 打开闲鱼
osascript -e 'tell application "Safari" to activate'
osascript -e 'tell application "Safari" to set URL of front document to "https://www.goofish.com"'

# 执行 JavaScript 检测
osascript << 'EOF'
tell application "Safari"
  do JavaScript "
    (function(){
      // 检测逻辑
    })()
  " in front document
end tell
EOF
```

## 标签页管理
操作完成后立即关闭多余标签页。未登录时保持打开。

## URL
- 首页：https://www.goofish.com
- 搜索：https://www.goofish.com/search?q=关键词
- 商品：https://www.goofish.com/item?id=ID
- 发布：https://www.goofish.com/publish
