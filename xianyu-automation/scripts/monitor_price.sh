#!/bin/bash
# 闲鱼价格监控脚本
# 用法: ./monitor_price.sh "商品URL" "目标价格"
# 示例: ./monitor_price.sh "https://www.goofish.com/item?id=xxx" "2500"

PRODUCT_URL="${1:-}"
TARGET_PRICE="${2:-}"

if [ -z "$PRODUCT_URL" ] || [ -z "$TARGET_PRICE" ]; then
    echo "用法: $0 \"商品URL\" \"目标价格\""
    echo "示例: $0 \"https://www.goofish.com/item?id=xxx\" \"2500\""
    exit 1
fi

echo "📱 商品URL: $PRODUCT_URL"
echo "🎯 目标价格: ¥$TARGET_PRICE"
echo ""

# 打开商品页面
osascript - <<EOF
tell application "Safari"
    activate
    open location "$PRODUCT_URL"
    delay 3
end tell
EOF

# 获取当前价格
CURRENT_PRICE=$(osascript - <<'JAVASCRIPT'
tell application "Safari"
    do JavaScript "document.querySelector('.price')?.textContent?.trim() || '未找到价格'" in front document
end tell
JAVASCRIPT
)

echo "💰 当前价格: $CURRENT_PRICE"

# 比较价格
if echo "$CURRENT_PRICE" | grep -q "^[0-9]"; then
    COMPARISON=$(echo "$CURRENT_PRICE" "$TARGET_PRICE" | awk '{if($1<=$2) print "✅ 达到目标价"; else print "❌ 未达到目标价"}')
    echo "$COMPARISON"
else
    echo "⚠️ 无法解析价格，请手动检查"
fi

echo ""
echo "✅ 页面已打开，请手动确认"
