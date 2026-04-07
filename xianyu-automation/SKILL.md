---
name: xianyu-automation
description: 闲鱼自动化技能 - 集成 Safari MCP 实现闲鱼商品搜索、热门推荐、价格监控、发布管理等功能。当用户需要以下操作时触发：(1) 搜索闲鱼商品或查看价格 (2) 获取闲鱼热门商品推荐 (3) 监控关注商品价格变动 (4) 发布或管理闲鱼商品 (5) 执行闲鱼养号任务。底层使用 AppleScript + JavaScript 通过 Safari 浏览器操作。
---

# 闲鱼自动化 (Xianyu Automation)

## 概述

通过 Safari MCP (AppleScript + JavaScript) 控制 Safari 浏览器，实现闲鱼平台的自动化操作。包括商品搜索、价格查询、热门推荐、价格监控、商品发布等功能。

**前置要求：**
- Safari MCP 已配置于 OpenClaw (`mcp.servers.safari`)
- macOS 上的 Safari 浏览器
- AppleScript 执行权限

## 核心能力

### 1. 商品搜索

使用 `safari_navigate` 打开闲鱼搜索页面，搜索关键词获取商品列表。

```
https://www.goofish.com/2fn?price=xxx  # 闲鱼搜索URL格式
```

### 2. 价格监控

定时检查关注商品的价格变动，达到目标价时提醒用户。

### 3. 热门推荐

获取闲鱼当日热门商品，筛选有利润空间的商品推荐给用户。

### 4. 商品发布

通过 Safari 填写表单发布商品（需滑块验证人工介入）。

## 快速开始

### 打开闲鱼搜索
```
safari_navigate → https://www.goofish.com
```

### 获取页面内容
```
safari_get_text → 获取当前页面文本
safari_snapshot → 获取页面元素快照
safari_screenshot → 截图
```

### 执行 JavaScript 操作
```
safari_evaluate → 执行 JS 获取页面数据
```

## 图片生成 (Draw Things API)

使用本地 Draw Things AI 生成商品图片。

### API 信息

| 项目 | 值 |
|------|-----|
| **端点** | `POST http://localhost:7860/sdapi/v1/txt2img` |
| **协议** | Stable Diffusion 兼容 |
| **超时** | 120 秒 |

### 调用示例

```python
import subprocess, json, base64

payload = {
    "prompt": "商品描述",
    "negative_prompt": "排除元素",
    "width": 1024,
    "height": 1024,
    "steps": 20,
    "cfg_scale": 7.5,
    "sampler_name": "DPM++ 2M Karras"
}

cmd = ["curl", "-s", "--max-time", "120", "-X", "POST",
       "http://localhost:7860/sdapi/v1/txt2img",
       "-H", "Content-Type: application/json",
       "-d", json.dumps(payload)]

result = subprocess.run(cmd, capture_output=True, text=True)
data = json.loads(result.stdout)
img_data = base64.b64decode(data['images'][0])
with open("output.png", "wb") as f:
    f.write(img_data)
```

### 脚本工具

```bash
python scripts/generate_image.py -p "描述" -n "负面词" -W 1024 -H 1024 -s 20
```

---

## ⚠️ 铁律：标签页管理

**每次使用完标签页后必须立即关闭！**

操作流程：
1. `safari_new_tab` → 打开新标签
2. 完成操作（导航/点击/提取数据）
3. `safari_close_tab` → **立即关闭标签页**

❌ **禁止**：打开多个标签页不关闭
❌ **禁止**：操作完成后不关闭标签页
⚠️ **例外**：检测到用户未登录时，保持标签页打开，让用户完成登录

---

## 工具清单

| 工具 | 功能 |
|------|------|
| `safari_navigate` | 导航到 URL |
| `safari_click` | 点击页面元素 |
| `safari_type_text` | 输入文字 |
| `safari_get_text` | 获取文本内容 |
| `safari_snapshot` | 获取元素快照 |
| `safari_screenshot` | 页面截图 |
| `safari_evaluate` | 执行 JavaScript |
| `safari_scroll` | 滚动页面 |
| `safari_new_tab` | 打开新标签页 |
| `safari_list_tabs` | 列出所有标签页 |
| `safari_switch_tab` | 切换标签页 |

## 工作流程

### 价格汇报流程
1. `safari_navigate` → 打开闲鱼商品页
2. `safari_evaluate` → 执行 JS 提取价格
3. 对比历史价格计算涨跌
4. 汇报给用户

### 发布商品流程
1. `safari_navigate` → 打开发布页面
2. `safari_fill` → 填写标题/价格/描述
3. `safari_click` → 点击发布按钮
4. 处理滑块验证（可能需要人工介入）

## 注意事项

- **滑块验证**：闲鱼发布需要滑块验证，Safari MCP 无法自动完成，需要人工辅助或第三方打码平台
- **页面加载**：网络慢时使用 `delay` 等待，或轮询 `document.readyState`
- **登录状态**：Safari 保持用户的登录态，无需重复登录
- **CPU 占用**：Safari MCP 比 Chrome 低约 60%，适合长时间运行

## scripts/

- `search_product.sh` - 搜索商品脚本
- `monitor_price.sh` - 价格监控脚本
- `get_hot_items.py` - 获取热门商品
- `check_login.py` - 检测登录状态

## references/

- `xianyu_api.md` - 闲鱼相关 URL 和 API 参考
- `safari_mcp_tools.md` - Safari MCP 工具详细用法
