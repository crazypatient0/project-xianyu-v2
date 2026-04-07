---
name: xianyu-automation
description: 闲鱼自动化技能。当需要以下操作时触发：(1) 搜索或查看闲鱼商品 (2) 获取热门推荐 (3) 监控价格 (4) 发布管理商品 (5) 检测登录状态。底层使用 Safari MCP 工具。
---

# 闲鱼自动化

## 模块1: 登录检测

### 触发
用户说"测试登录"、"检测登录状态"、"登录功能"时触发。

### 步骤
1. `safari__safari_new_tab` → 打开 `https://www.goofish.com`
2. `safari__safari_evaluate` → 执行 JS 检测

### JS 检测逻辑
```javascript
(function(){
  var iframe=document.querySelector('iframe[src*="passport.goofish.com"]');
  var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
  var userEl=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');
  var userName=userEl?userEl.innerText.trim():'';
  return JSON.stringify({hasLoginIframe:hasLoginIframe,userName:userName});
})()
```

### 判断
- `hasLoginIframe === true` → 未登录
- `userName` 有值 → 已登录

### 实验记录
见 `references/01_login_check.md`
