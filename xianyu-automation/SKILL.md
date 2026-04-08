---
name: xianyu-automation
description: 闲鱼自动化技能。触发：(1)用户说"登录检测"→模块1 (2)用户说"搜索商品"→模块2 (3)用户说"价格监控"→模块3 (4)用户说"发布商品"→模块4
---

# 闲鱼自动化

## ⚠️ 前提条件

**使用 AppleScript 操作 Safari，无需 MCP。**

每次操作 Safari 前需先激活：
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

## 核心知识

### AppleScript + Safari

Safari 没有原生 AppleScript Suite，操作窗口和执行 JS 需通过 `do JavaScript in front document`。

### 登录检测逻辑

- passport iframe 存在 + 无用户名 → **未登录**
- 存在用户名元素 → **已登录**

### 标签页管理

操作完成后立即关闭多余标签页。未登录时保持打开让用户登录。

### URL 规则

- 首页：https://www.goofish.com
- 搜索：https://www.goofish.com/search?q=关键词
- 商品：https://www.goofish.com/item?id=ID
- 发布：https://www.goofish.com/publish

### 数据库

- 路径：xianyu-automation/data/xianyu_products.db
- 商品表：products（url/title/price/location/seller/views/wants/created_at）
- 价格历史表：price_history（url/price/datetime）
