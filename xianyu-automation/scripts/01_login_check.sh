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

# 步骤3: 执行JavaScript检测
echo "3. 执行登录状态检测..."

RESULT=$(osascript << 'JSEOF'
tell application "Safari"
  set js to "
(function(){
  var iframe=document.querySelector('iframe[src*=\"passport.goofish.com\"]');
  var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
  var userEl=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');
  var userName=userEl?userEl.innerText.trim():'';
  return JSON.stringify({hasLoginIframe:hasLoginIframe,userName:userName});
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

# 提取 hasLoginIframe
HAS_IFRAME=$(echo "$RESULT" | sed 's/.*"hasLoginIframe":\([^,]*\).*/\1/' | tr -d ' ')
# 提取 userName
USER_NAME=$(echo "$RESULT" | sed 's/.*"userName":"\([^"]*\)".*/\1/')

if [ "$HAS_IFRAME" = "true" ]; then
  echo "❌ 未登录 (检测到登录iframe)"
  echo "   请手动登录后重新运行检测"
elif [ -n "$USER_NAME" ]; then
  echo "✅ 已登录"
  echo "   用户名: $USER_NAME"
else
  echo "⚠️ 状态未知"
  echo "   原始响应: $RESULT"
fi

echo ""
