#!/bin/bash
# 闲鱼商品搜索脚本
# 用法: ./search_product.sh "关键词" [价格区间]
# 示例: ./search_product.sh "iPhone 15" "2000-4000"

KEYWORD="${1:-}"
PRICE="${2:-}"

if [ -z "$KEYWORD" ]; then
    echo "用法: $0 \"关键词\" [价格区间]"
    echo "示例: $0 \"iPhone 15\" \"2000-4000\""
    exit 1
fi

# URL 编码
ENCODED_KEYWORD=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$KEYWORD'))")

# 构建搜索 URL
SEARCH_URL="https://www.goofish.com/2fn?keyword=${ENCODED_KEYWORD}"
if [ -n "$PRICE" ]; then
    SEARCH_URL="${SEARCH_URL}&price=${PRICE}"
fi

echo "🔍 搜索关键词: $KEYWORD"
echo "💰 价格区间: ${PRICE:-不限}"
echo "🔗 URL: $SEARCH_URL"
echo ""

# 使用 osascript 打开 Safari 并导航
osascript - <<EOF
tell application "Safari"
    activate
    open location "$SEARCH_URL"
    delay 3
end tell
EOF

echo "✅ 已打开发搜索页面"
