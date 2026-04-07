#!/bin/bash
# 商品搜索 - 使用Safari MCP工具

# 参数: $1 = 关键词

KEYWORD="${1:-}"

if [ -z "$KEYWORD" ]; then
  echo "用法: $0 <关键词>"
  exit 1
fi

echo "=== 商品搜索: $KEYWORD ==="

# 步骤1: 打开搜索页
echo "1. safari__safari_new_tab → https://www.goofish.com/2fn?keyword=$KEYWORD"

# 步骤2: 获取商品列表
echo "2. safari__safari_snapshot → 获取商品列表"
