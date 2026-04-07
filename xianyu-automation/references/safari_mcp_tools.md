# Safari MCP 工具详细用法

## 导航工具

### safari_navigate
导航到指定 URL。
```
safari_navigate({url: "https://www.goofish.com"})
```

### safari_go_back / safari_go_forward
前进或后退。
```
safari_go_back({})
safari_go_forward({})
```

### safari_reload
刷新页面。
```
safari_reload({})
```

## 交互工具

### safari_click
点击元素。使用 ref（从 snapshot 获取）或 selector。
```
safari_snapshot({})
→ safari_click({ref: "0_5"})
```

### safari_fill
填写表单字段。
```
safari_fill({ref: "0_10", value: "商品标题"})
```

### safari_type_text
逐字输入（适合搜索框，触发自动补全）。
```
safari_type_text({ref: "0_10", text: "iPhone 15"})
```

### safari_press_key
按键操作。
```
safari_press_key({key: "enter"})
safari_press_key({key: "tab", modifiers: ["shift"]})
```

### safari_scroll
滚动页面。
```
safari_scroll({direction: "down", amount: 500})
safari_scroll({direction: "up", amount: 300})
```

## 信息获取

### safari_snapshot
获取页面元素快照（首选）。
```
safari_snapshot({})
→ 返回 {elements: [{ref, tag, text, attributes}]}
```

### safari_get_text
获取页面文本内容。
```
safari_get_text({})
safari_get_text({selector: ".price"})
```

### safari_evaluate
在页面执行 JavaScript。
```
safari_evaluate({script: "document.title"})
safari_evaluate({script: "document.querySelector('.price').textContent"})
```

### safari_screenshot
截图。
```
safari_screenshot({})
safari_screenshot({fullPage: true})
```

### safari_network
查看网络请求。
```
safari_network({limit: 50})
```

## 标签页管理

### safari_new_tab
打开新标签。
```
safari_new_tab({url: "https://example.com"})
```

### safari_list_tabs
列出所有标签页。
```
safari_list_tabs({})
```

### safari_switch_tab
切换标签页。
```
safari_switch_tab({index: 2})
```

### safari_close_tab
关闭当前标签。
```
safari_close_tab({})
```

## 等待策略

### safari_wait
固定等待（尽量少用）。
```
safari_wait({ms: 3000})
```

### safari_wait_for
等待元素或文本出现。
```
safari_wait_for({text: "商品详情", timeout: 10000})
safari_wait_for({selector: ".price", timeout: 5000})
```

### safari_wait_for_new_tab
等待新标签页打开。
```
safari_wait_for_new_tab({timeout: 10000})
```

## 提取工具

### safari_extract_links
提取所有链接。
```
safari_extract_links({limit: 50})
safari_extract_links({filter: "goofish.com"})
```

### safari_extract_images
提取所有图片。
```
safari_extract_images({limit: 30})
```

### safari_extract_meta
提取 meta 信息（SEO）。
```
safari_extract_meta({})
```

## 存储管理

### safari_local_storage / safari_session_storage
获取或设置存储。
```
safari_local_storage({key: "cart"})
safari_set_local_storage({key: "test", value: "123"})
```

## Cookie 管理

### safari_get_cookies
获取当前页面 cookies。
```
safari_get_cookies({})
```

### safari_set_cookie
设置 cookie。
```
safari_set_cookie({name: "session", value: "abc", domain: ".goofish.com"})
```

## AppleScript 底层命令

当 Safari MCP 工具不满足时，可直接使用 `exec` 执行 osascript：

```bash
# 获取当前 URL
osascript -e 'tell application "Safari" to return URL of front document'

# 获取页面源码
osascript -e 'tell application "Safari" to do JavaScript "document.documentElement.outerHTML" in front document'

# 执行点击
osascript -e 'tell application "Safari" to do JavaScript "document.querySelector(\"#btn\").click()" in front document'

# 滚动到元素
osascript -e 'tell application "Safari" to do JavaScript "document.querySelector(\".target\").scrollIntoView()" in front document'
```

## 常用 JavaScript 片段

### 提取商品价格
```javascript
document.querySelector('.price').textContent.trim()
document.querySelector('[data-price]').dataset.price
```

### 提取商品标题
```javascript
document.querySelector('.title').textContent.trim()
document.querySelector('h1').textContent.trim()
```

### 提取商品列表
```javascript
[...document.querySelectorAll('.item')].map(el => ({
  title: el.querySelector('.title')?.textContent?.trim(),
  price: el.querySelector('.price')?.textContent?.trim(),
  url: el.querySelector('a')?.href
}))
```

### 检查页面是否加载完成
```javascript
document.readyState === 'complete'
```

### 滚动到底部加载更多
```javascript
window.scrollTo(0, document.body.scrollHeight)
```

### 等待元素出现（轮询）
```javascript
(function waitFor(selector, timeout) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      const el = document.querySelector(selector);
      if (el) resolve(el);
      else if (Date.now() - start > timeout) reject(new Error('Timeout'));
      else setTimeout(check, 200);
    };
    check();
  })();
})('.price', 10000)
```
