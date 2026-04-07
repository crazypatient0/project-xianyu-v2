#!/bin/bash
# 闲鱼商品搜索脚本
# 使用 Safari MCP 打开搜索页面并提取商品数据

KEYWORD="${1:-iPhone}"
MAX_PAGES="${2:-1}"

echo "🔍 搜索关键词: $KEYWORD"
echo "="50

# 使用 Safari 打开搜索页面
osascript -e '
tell application "Safari"
    activate
    make new document
    set URL of front document to "https://www.goofish.com/search?q='"$KEYWORD"'"
end tell
'

echo "🌐 页面加载中，等待3秒..."
sleep 3

# 提取商品数据（通过 JavaScript）
osascript -e '
tell application "Safari"
    tell front document
        set productCount to do JavaScript "
            var items = document.querySelectorAll(\"a[href*=\"/item?id=\"]\");
            var seen = new Set();
            var products = [];
            
            items.forEach(function(a) {
                var match = a.href.match(/\\/item\\?id=(\\d+)/);
                if (match && !seen.has(match[1])) {
                    seen.add(match[1]);
                    var text = (a.innerText || \"\").replace(/\\s+/g, \" \").trim();
                    var priceMatch = text.match(/¥[\\d,\\.]+/);
                    var price = priceMatch ? priceMatch[0] : \"\";
                    products.push({
                        id: match[1],
                        url: a.href,
                        text: text.substring(0, 100),
                        price: price
                    });
                }
            });
            
            return JSON.stringify(products);
        "
        
        return productCount
    end tell
end tell
'

echo ""
echo "✅ 搜索完成"
echo "📋 请在 Safari 窗口中查看结果"
