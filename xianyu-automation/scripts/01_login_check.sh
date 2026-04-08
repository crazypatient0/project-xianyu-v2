#!/bin/bash
# 登录检测 - 纯AppleScript实现，无MCP依赖

echo "=== 闲鱼登录检测 ==="

# 步骤1: 确保Safari运行
echo "1. 激活Safari..."
osascript -e 'tell application "Safari" to activate'
sleep 1

# 步骤2: 打开闲鱼首页
echo "2. 打开闲鱼首页..."
osascript -e 'tell application "Safari"
  if (count of windows) = 0 then make new document
  set URL of front document to "https://www.goofish.com"
  activate
end tell'
echo "   → https://www.goofish.com"
sleep 3

# 步骤3: 执行JavaScript检测（增强版：同时检测多个登录标志）
echo "3. 执行登录状态检测..."

RESULT=$(osascript << 'JSEOF'
tell application "Safari"
  set js to "
(function(){
  var iframe=document.querySelector('iframe[src*=\"passport.goofish.com\"]');
  var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
  var hasOrders=document.body.innerText.indexOf(\"订单\")!==-1;
  var hasProfile=document.body.innerText.indexOf(\"我\")!==-1;
  var userEl=document.querySelector('.user-nick,.nick-name,[class*=\"user-nick\"],[class*=\"nick\"],.username,[class*=\"username\"]');
  var userName=userEl?userEl.innerText.trim():'';
  return JSON.stringify({hasLoginIframe:hasLoginIframe,hasOrders:hasOrders,hasProfile:hasProfile,userName:userName});
})()
"
  do JavaScript js in front document
end tell
JSEOF
)

echo "   原始结果: $RESULT"

# 步骤4: 解析并判断
echo ""
echo "=== 检测结果 ==="

# 判断逻辑：hasLoginIframe=false 且 (hasOrders=true 或 hasProfile=true 或 userName有值)
if echo "$RESULT" | grep -q '"hasLoginIframe":false'; then
  if echo "$RESULT" | grep -q '"hasOrders":true'; then
    echo "✅ 已登录 (检测到'订单'元素)"
  elif echo "$RESULT" | grep -q '"hasProfile":true'; then
    echo "✅ 已登录 (检测到'我'元素)"
  elif echo "$RESULT" | grep -q '"userName":"[^"]*[^"]"'; then
    USER_NAME=$(echo "$RESULT" | sed 's/.*"userName":"\([^"]*\)".*/\1/')
    echo "✅ 已登录 (用户名: $USER_NAME)"
  else
    echo "⚠️ 状态未知 - hasLoginIframe=false 但无明确登录标志"
    echo "   原始响应: $RESULT"
  fi
else
  echo "❌ 未登录 (检测到登录iframe)"
  echo "   请手动登录后重新运行检测"
fi

echo ""