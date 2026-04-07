---
name: xianyu-automation
description: 闲鱼自动化技能。使用Safari MCP控制Safari操作闲鱼。触发场景：(1)搜索/查看商品 (2)获取热门推荐 (3)监控价格 (4)发布管理商品 (5)检测登录状态。
---

# 闲鱼自动化

## 工具

| 工具 | 功能 |
|------|------|
| safari__safari_new_tab | 打开新标签页 |
| safari__safari_navigate | 导航到URL |
| safari__safari_evaluate | 执行JavaScript |
| safari__safari_snapshot | 获取页面元素 |
| safari__safari_screenshot | 截图 |

## 模块1: 登录检测

### 触发
用户说"测试登录"、"检测登录状态"时触发。

### 工作流
1. `safari__safari_new_tab` → `https://www.goofish.com`
2. `safari__safari_evaluate` → 执行检测JS
3. 判断结果

### 检测JS
```javascript
(function(){
  var iframe=document.querySelector('iframe[src*="passport.goofish.com"]');
  var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
  var userEl=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');
  var userName=userEl?userEl.innerText.trim():'';
  return JSON.stringify({hasLoginIframe:hasLoginIframe,userName:userName});
})()
```

### 判断标准
- `hasLoginIframe === true` → 未登录
- `userName` 有值 → 已登录

## 模块2: 商品搜索

### 工作流
1. `safari__safari_new_tab` → `https://www.goofish.com/2fn?keyword=关键词`
2. `safari__safari_snapshot` → 获取商品列表

## 模块3: 价格监控

### 工作流
1. `safari__safari_navigate` → 商品详情页
2. `safari__safari_evaluate` → 提取价格

## 标签页管理
- 操作完成后**立即关闭**多余标签页
- 未登录时保持标签页打开

## 闲鱼URL
- 首页：`https://www.goofish.com`
- 搜索：`https://www.goofish.com/2fn?keyword=关键词`
- 商品：`https://www.goofish.com/item?id=商品ID`
- 发布：`https://www.goofish.com/publish`
