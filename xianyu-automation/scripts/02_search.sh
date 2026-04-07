#!/bin/bash
# 商品搜索 - 使用Safari MCP工具
# 用法: ./02_search.sh <关键词>

KEYWORD="${1:-}"

if [ -z "$KEYWORD" ]; then
  echo "用法: $0 <关键词>"
  exit 1
fi

echo "=== 商品搜索: $KEYWORD ==="

# 步骤1: 打开Safari
osascript -e 'tell application "Safari" to activate'

# 步骤2: 打开搜索页
mcporter call safari.safari_new_tab --args "{\"url\":\"https://www.goofish.com/search?q=$KEYWORD\"}"

# 步骤3: 等待页面加载
sleep 3

# 步骤4: 滚动加载更多商品
for i in 1 2 3 4 5; do
  echo "滚动第 $i 次..."
  osascript -e 'tell application "Safari" to tell window 1 to tell current tab to do JavaScript "window.scrollTo(0, document.body.scrollHeight)"' 2>/dev/null
  sleep 2
done

# 步骤5: 获取快照
echo "获取商品列表..."
mcporter call safari.safari_snapshot --args '{"tabIndex":4}'

echo ""
echo "=== 搜索完成 ==="
echo "提示: 使用Python脚本提取商品详情并存入数据库"
