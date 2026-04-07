# 功能1：登录检测

## 描述
检测用户是否已登录闲鱼

## 触发场景
用户说"测试登录功能"、"检测登录状态"时触发

## 实现方式

### 工具
- `safari__safari_new_tab` - 打开新标签页
- `safari__safari_evaluate` - 执行JS检测

### JS检测逻辑
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
- 两者都没有 → 无法确定

### 实验记录

**日期：** 2026-04-07
**结果：** ✅ 功能正常

**调用工具：**
| 步骤 | 工具 | 结果 |
|------|------|------|
| 1 | safari__safari_new_tab | ✅ 成功打开闲鱼 |
| 2 | safari__safari_evaluate | ✅ JS执行成功 |

**检测结果：**
```json
{
  "hasLoginIframe": true,
  "userName": "",
  "url": "https://www.goofish.com/"
}
```

**结论：** Safari未登录闲鱼（passport iframe存在）
