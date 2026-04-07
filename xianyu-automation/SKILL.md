---
name: xianyu-automation
description: 闲鱼自动化技能。触发：(1)用户说"登录检测"→模块1 (2)用户说"搜索商品"→模块2 (3)用户说"价格监控"→模块3 (4)用户说"发布商品"→模块4
---

# 闲鱼自动化

## 模块索引

| 触发条件 | 功能 | 脚本 |
|---------|------|------|
| "登录检测" | 登录状态检测 | scripts/01_login_check.sh |
| "搜索商品" | 商品搜索 | scripts/02_search.sh |
| "价格监控" | 价格变动监控 | scripts/03_price_watch.sh |
| "发布商品" | 发布商品 | scripts/04_publish.sh |

## 工具
- safari__safari_new_tab
- safari__safari_navigate
- safari__safari_evaluate
- safari__safari_snapshot

## 标签页管理
操作完成后立即关闭多余标签页。未登录时保持打开。

## URL
- 首页：https://www.goofish.com
- 搜索：https://www.goofish.com/2fn?keyword=关键词
- 商品：https://www.goofish.com/item?id=ID
- 发布：https://www.goofish.com/publish
