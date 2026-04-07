#!/bin/bash
# 价格监控 - 使用Safari MCP工具

# 参数: $1 = 商品URL

URL="${1:-}"

if [ -z "$URL" ]; then
  echo "用法: $0 <商品URL>"
  exit 1
fi

echo "=== 价格监控: $URL ==="

# 步骤1: 导航到商品页
echo "1. safari__safari_navigate → $URL"

# 步骤2: 提取价格
echo "2. safari__safari_evaluate → 提取价格"
