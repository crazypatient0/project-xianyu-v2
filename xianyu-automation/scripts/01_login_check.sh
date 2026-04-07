#!/bin/bash
# 登录检测 - 使用Safari MCP工具

echo "=== 登录检测 ==="

# 步骤1: 打开闲鱼首页
echo "1. safari__safari_new_tab → https://www.goofish.com"

# 步骤2: 执行JS检测
echo "2. safari__safari_evaluate → 检测passport iframe"

# 检测JS:
cat << 'JSEOF'
(function(){
  var iframe=document.querySelector('iframe[src*="passport.goofish.com"]');
  var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
  var userEl=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');
  var userName=userEl?userEl.innerText.trim():'';
  return JSON.stringify({hasLoginIframe:hasLoginIframe,userName:userName});
})()
JSEOF

# 判断结果
echo ""
echo "判断:"
echo "- hasLoginIframe === true → 未登录"
echo "- userName 有值 → 已登录"
