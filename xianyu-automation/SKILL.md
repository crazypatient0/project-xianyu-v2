---
name: xianyu-automation
description: 闲鱼自动化技能。触发：(1)用户说"登录检测"→模块1 (2)用户说"搜索商品"→模块2 (3)用户说"价格监控"→模块3 (4)用户说"发布商品"→模块4
---

# 闲鱼自动化

## 触发条件

| 用户说 | 功能 | 脚本 |
|--------|------|------|
| 登录检测 | 检测登录状态 | 01_login_check.sh |
| 搜索商品 | 多页商品搜索+存储 | 02_search.sh |
| 价格监控 | 监控商品价格变动 | 03_price_watch.sh |
| 发布商品 | 发布新商品 | 04_publish.sh |

## 核心知识

- **操作方式**: 纯 AppleScript + osascript 操作 Safari
- **登录检测**: passport iframe 存在=未登录，有用户名=已登录
- **标签页**: 操作完立即关闭多余标签页，未登录时保持打开
- **URL规律**: 
  - 首页 goofish.com
  - 搜索 search?q=关键词
  - 商品 item?id=ID
  - 发布 publish

## 数据存储

- 数据库: data/xianyu_products.db
- 商品表: products（url,title,price,location,seller,views,wants,created_at）