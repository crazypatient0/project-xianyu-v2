# 闲鱼自动化技能 - 阶段成果记录

**日期**: 2026-04-03  
**版本**: v0.1

---

## 一、已实现功能

### 1. 商品搜索 ✅
- **工具**: `safari_mcp` (safari_search_products / safari_navigate + JavaScript)
- **流程**: 搜索 → 提取商品数据 → 返回结构化结果
- **可提取字段**: 标题、价格、地区、链接、卖家信息

### 2. 商品详情页 ✅
- **工具**: `safari_mcp` + JavaScript 提取动态内容
- **可提取**: 标题、价格、型号、配置、描述等
- **注意**: 闲鱼是 SPA，需 JavaScript 渲染后才能提取

### 3. 登录状态检测 ✅
- **工具**: Safari MCP + AppleScript
- **判断逻辑**: 检查页面是否有"登录"按钮
- **已验证**: 未登录显示"登录"按钮，已登录显示用户名

### 4. 商品自动发布 ✅ (完整链路)
- **工具**: xianyu-auto-ops + Draw Things API + Safari MCP
- **流程**:
  1. xianyu-auto-ops 生成商品文案（标题/描述/价格/AI绘图提示词）
  2. Draw Things API 生成商品图片
  3. Safari MCP 填写发布表单
  4. 自动发布商品

### 5. AI 商品图片生成 ✅
- **工具**: Draw Things API
- **端点**: `POST localhost:7860/sdapi/v1/txt2img`
- **协议**: Stable Diffusion 兼容
- **超时**: 120秒（同步阻塞）

### 6. 消息页面 ✅
- **进入**: 主页右侧"消息"按钮 → `/im`
- **结构**: 左侧对话列表 + 右侧聊天窗口

### 7. 消息发送 ✅
- **工具**: Safari MCP
- **流程**: 点击对话 → 填写输入框 → 点击发送
- **验证**: 消息发送后显示"已读"

---

## 二、部分实现 / 受限功能

### 消息列表获取 ⚠️
- **现状**: 可获取当前可见的 10+ 条对话
- **问题**: 闲鱼使用 rc-virtual-list（虚拟滚动），只渲染可见区域
- **限制**: 程序化滚动无法触发 React 状态更新
- **解决思路**:
  - OS 级 CGEvent 注入（需特殊权限）
  - React DevTools 桥接
  - 闲鱼 API 直接调用（需签名验证）

### API 调用 ⚠️
- **已发现 API**:
  - 搜索: `https://h5api.m.goofish.com/h5/mtop.taobao.idlemessage.pc.user.query/4.0/`
  - 消息: `mtop.taobao.idlemessage.pc.user.query`
- **限制**: 需要有效 Cookie + 签名验证
- **签名算法**: 需要 app secret，非公开

---

## 三、技术架构

```
xianyu-automation/
├── SKILL.md                      # 技能核心定义
├── references/
│   ├── xianyu_api.md           # 闲鱼 URL/分类/术语
│   ├── safari_mcp_tools.md     # Safari MCP 工具详细用法
│   └── xianyu_auto_ops_reference.md  # xianyu-auto-ops 参考
├── scripts/
│   ├── search_product.sh         # 商品搜索
│   ├── monitor_price.sh         # 价格监控
│   ├── get_hot_items.py         # 热门商品
│   ├── check_login.py           # 登录检测
│   └── generate_image.py         # Draw Things API 封装
└── docs/
    └── TEST_REPORT.md          # 测试报告
```

---

## 四、关键代码片段

### Safari 自动打开
```bash
osascript -e 'tell application "Safari" to activate'
```

### 图片上传（成功）
```python
safari_upload_file(
    filePath="/Users/lucifer/Desktop/ai_assistant_service.png",
    selector="input[type='file']"
)
```

### 消息发送
```python
safari_fill(ref="输入框_ref", value="消息内容")
safari_click(ref="发送按钮_ref")
```

---

## 五、测试结果

| 测试项 | 结果 | 日期 |
|--------|------|------|
| Safari MCP 连接 | ✅ | 2026-04-03 |
| 商品搜索 | ✅ | 2026-04-03 |
| 商品详情页 | ✅ | 2026-04-03 |
| 登录检测 | ✅ | 2026-04-03 |
| 商品发布（虚拟商品） | ✅ | 2026-04-03 |
| AI 图片生成 | ✅ | 2026-04-03 |
| 消息页面进入 | ✅ | 2026-04-03 |
| 消息发送 | ✅ | 2026-04-03 |
| 消息列表完整获取 | ⚠️ 部分 | 2026-04-03 |

---

## 六、下一步

- [ ] 订单管理功能（查看/确认发货）
- [ ] 批量发布商品
- [ ] 价格监控自动化
- [ ] 买家咨询自动回复

---

**结论**: 核心功能已基本打通，消息列表获取受虚拟滚动限制，但当前可见部分可正常使用。
