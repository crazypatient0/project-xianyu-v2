#!/bin/bash
# 商品搜索 - 使用Safari MCP工具

KEYWORD="${1:-}"

if [ -z "$KEYWORD" ]; then
  echo "用法: $0 <关键词>"
  exit 1
fi

echo "=== 商品搜索: $KEYWORD ==="

# 步骤1: 打开Safari
osascript -e 'tell application "Safari" to activate'

# 步骤2: 打开搜索页
mcporter call safari.safari_new_tab --args '{"url":"https://www.goofish.com/search?q='$KEYWORD'"}'

# 步骤3: 获取商品列表
mcporter call safari.safari_snapshot
