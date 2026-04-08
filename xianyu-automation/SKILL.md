---
name: xianyu-automation
description: 闲鱼自动化技能。触发：(1)用户说"登录检测"→模块1 (2)用户说"搜索商品"→模块2 (3)用户说"价格监控"→模块3 (4)用户说"发布商品"→模块4
---

# 闲鱼自动化

## 触发条件

| 用户说 | 功能 | 脚本 | 参数 |
|--------|------|------|------|
| 登录检测 | 检测登录状态 | 01_login_check.sh | 无 |
| 搜索商品 | 多页商品搜索+存储 | 02_search.sh | `<关键词> [数量=5]` |
| 价格监控 | 监控商品价格变动 | 03_price_watch.sh | 待实现 |
| 发布商品 | 发布新商品 | 04_publish.sh | 待实现 |

## 核心知识

### 搜索脚本 (02_search.sh)

**参数：**
- `关键词`: 必须提供，要搜索的商品名称
- `数量`: 默认5个，需要的商品数量（自动计算页数，每页30个）

**用法示例：**
```bash
./02_search.sh iphone 10    # 搜索iphone，获取10个
./02_search.sh mac          # 搜索mac，获取5个（默认）
```

**数据提取：**
- 价格: 匹配 `¥数字` 模式
- 位置: 匹配 `城市 + X小时/天/分钟前来过` 模式
- 卖家: `div[class*="item-user-info-nick--"]` 标签内容
- 想要数: 匹配 `X人想要` 模式
- 浏览数: 匹配 `X浏览` 模式

**翻页：**
- 使用 XPath 点击下一页: `//*[@id="content"]/div[2]/div[4]/div/div[1]/button[2]/div`
- 必须用 JS 文件方式执行，直接 -e 内联会转义失败

### 操作方式

- **AppleScript**: 纯 `osascript` 操作 Safari，无 MCP 依赖
- **URL规律**: 
  - 首页: goofish.com
  - 搜索: search?q=关键词
  - 商品: item?id=ID
  - 发布: publish
- **登录检测**: 检测 `passport` iframe，存在=未登录

### 标签页管理

- 操作完立即关闭多余标签页
- 未登录时保持打开登录页

## 数据存储

- 数据库: `data/xianyu_products.db`（相对于脚本位置）
- 表结构:
  ```sql
  CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT UNIQUE,
    title TEXT,
    price TEXT,
    location TEXT,
    seller TEXT,
    views TEXT,
    wants TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
  ```

## 注意事项

- seller/ views/ wants 字段从商品详情页提取
- 翻页重叠率约10%（XPath点击方式）
- 最多支持10页（约300个商品）