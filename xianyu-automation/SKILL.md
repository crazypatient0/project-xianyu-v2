---
name: xianyu-automation
description: 闲鱼自动化技能 - 通过 Safari MCP 控制 Safari 浏览器操作闲鱼平台。当用户需要：(1) 搜索闲鱼商品或查看价格 (2) 获取闲鱼热门商品推荐 (3) 监控商品价格变动 (4) 发布或管理闲鱼商品 (5) 检测登录状态 时触发。底层使用 Safari MCP 工具（safari__safari_*），禁止使用 osascript 或 subprocess 操作 Safari。
---

# 闲鱼自动化

## 核心原则

**必须使用 Safari MCP 工具**，禁止使用 osascript/subprocess 操作 Safari。

## 工具清单

| 工具 | 功能 |
|------|------|
| `safari__safari_new_tab` | 打开新标签页 |
| `safari__safari_navigate` | 导航到 URL |
| `safari__safari_evaluate` | 执行 JavaScript |
| `safari__safari_snapshot` | 获取页面元素快照 |
| `safari__safari_screenshot` | 截图 |
| `safari__safari_list_tabs` | 列出所有标签页 |
| `safari__safari_close_tab` | 关闭标签页 |

## 标签页管理

- 每次操作完成后**立即关闭标签页**
- 检测到未登录时保持标签页打开

## 工作流程

### 1. 登录检测

```
safari__safari_new_tab → https://www.goofish.com
safari__safari_evaluate → 检测 passport iframe
```

**JS 检测逻辑：**
```javascript
(function(){
  var iframe=document.querySelector('iframe[src*="passport.goofish.com"]');
  var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
  var userEl=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');
  var userName=userEl?userEl.innerText.trim():'';
  return JSON.stringify({hasLoginIframe:hasLoginIframe,userName:userName});
})()
```

### 2. 商品搜索

```
safari__safari_new_tab → https://www.goofish.com/2fn?keyword=关键词
safari__safari_snapshot → 获取商品列表
```

### 3. 热门推荐

```
safari__safari_new_tab → https://www.goofish.com
safari__safari_evaluate → 提取热门商品数据
```

### 4. 价格监控

```
safari__safari_navigate → 商品详情页
safari__safari_evaluate → 提取价格
```

### 5. 发布商品

```
safari__safari_navigate → https://www.goofish.com/publish
safari__safari_fill → 填写表单
safari__safari_click → 点击发布
```

**注意：** 滑块验证需人工介入

## AI 图片生成 (Draw Things API)

端点：`POST http://localhost:7860/sdapi/v1/txt2img`

```
import requests
import base64

payload = {
    "prompt": "商品描述",
    "negative_prompt": "排除元素",
    "width": 1024,
    "height": 1024,
    "steps": 20,
    "cfg_scale": 7.5,
    "sampler_name": "DPM++ 2M Karras"
}

r = requests.post("http://localhost:7860/sdapi/v1/txt2img", json=payload, timeout=120)
img_data = base64.b64decode(r.json()['images'][0])
```

## 闲鱼 URL

- 搜索：`https://www.goofish.com/2fn?keyword=关键词`
- 商品：`https://www.goofish.com/item?id=商品ID`
- 发布：`https://www.goofish.com/publish`
- 首页：`https://www.goofish.com`
