#!/bin/bash
# 价格监控 - 读取数据库商品并抓取最新价格
# 用法: ./03_price_watch.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_PATH="$SCRIPT_DIR/../data/xianyu_products.db"

echo "=== 价格监控 ==="

# ========== 步骤1: 检查Safari可用性 ==========
echo "检查Safari..."
osascript -e 'tell application "Safari" to return count of windows' > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "错误: Safari不可用"
    exit 1
fi

window_count=$(osascript -e 'tell application "Safari" to return count of windows')
if [ "$window_count" -eq 0 ]; then
    osascript -e 'tell application "Safari" to make new document'
    sleep 1
fi
echo "Safari ✅"

# ========== 步骤2: 检查Safari MCP可用性 ==========
echo "检查Safari MCP..."
mcporter list > /dev/null 2>&1 || { echo "错误: mcporter不可用"; exit 1; }
mcporter list 2>/dev/null | grep -q "safari" || { echo "错误: Safari MCP server未运行"; exit 1; }
echo "Safari MCP ✅"

# ========== 步骤3: 检查数据库和表 ==========
echo "检查数据库和表..."
if [ ! -f "$DB_PATH" ]; then
    echo "错误: 数据库不存在: $DB_PATH"
    exit 1
fi
echo "数据库: $DB_PATH ✅"

python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
c = conn.cursor()
c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='price_history'")
if not c.fetchone():
    c.execute('''CREATE TABLE price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        price REAL,
        datetime TEXT)''')
    conn.commit()
conn.close()
print("price_history 表就绪 ✅")
PYEOF
if [ $? -ne 0 ]; then
    echo "错误: 检查/创建表失败"
    exit 1
fi

# ========== 步骤4: 获取去重后的商品URL（全部） ==========
echo "读取去重后的商品URL..."
URL_COUNT=$(python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
db_path = sys.argv[1]
try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("SELECT COUNT(DISTINCT url) FROM products WHERE url != ''")
    count = c.fetchone()[0]
    c.execute("SELECT DISTINCT url FROM products WHERE url != ''")
    urls = [row[0] for row in c.fetchall()]
    conn.close()
    with open("/tmp/price_watch_urls.txt", "w") as f:
        for url in urls:
            f.write(url + "\n")
    print(count)
except Exception as e:
    print(f"错误: {e}")
    sys.exit(1)
PYEOF
)

if [ $? -ne 0 ] || [ -z "$URL_COUNT" ]; then
    echo "读取数据库失败"
    exit 1
fi
echo "共 $URL_COUNT 个去重商品"

# ========== 步骤5: 逐个访问商品（拟人化操作） ==========
mkdir -p /tmp/price_watch
processed=0
failed=0
saved=0

while IFS= read -r url; do
    [ -z "$url" ] && continue
    processed=$((processed + 1))
    echo -ne "\r[$processed/$URL_COUNT] "

    # 打开新标签页访问URL
    osascript -e 'tell application "Safari" to tell window 1 to set current tab to (make new tab with properties {URL:"'"$url"'})' 2>/dev/null
    sleep 3

    # 拟人化操作: 随机滚动50-300像素
    scroll_px=$((RANDOM % 251 + 50))
    osascript << 'SCROLLEOF'
tell application "Safari"
    tell window 1
        tell current tab
            do JavaScript "window.scrollBy(0, " & L & ")"
        end tell
    end tell
end tell
SCROLLEOF
    # 随机停留5-30秒
    stay_time=$((RANDOM % 26 + 5))
    echo " 滚动${scroll_px}px, 停留${stay_time}秒..."
    sleep $stay_time

    # 提取数据
    tmpfile="/tmp/price_watch/p_$$.json"
    osascript << 'OUTEREOF' > "$tmpfile"
tell application "Safari"
    tell window 1
        tell current tab
            do JavaScript "
var r={url:window.location.href,price:''};
var pn=document.querySelector('.number--NKh1vXWM');
var pd=document.querySelector('.decimal--lSAcITCN');
if(pn){r.price=pn.innerText+(pd?pd.innerText:'');}
JSON.stringify(r);
"
        end tell
    end tell
end tell
OUTEREOF

    if [ -f "$tmpfile" ] && [ -s "$tmpfile" ]; then
        result=$(python3 - "$DB_PATH" "$tmpfile" << 'PYEOF'
import sqlite3, sys, json
from datetime import datetime
db_path, tmpfile = sys.argv[1], sys.argv[2]
try:
    with open(tmpfile) as f:
        data = json.load(f)
    if not data.get("url") or not data.get("price"):
        sys.exit(1)
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    price = float(data["price"])
    dt = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    c.execute("INSERT INTO price_history (url, price, datetime) VALUES (?, ?, ?)",
        (data["url"], price, dt))
    conn.commit()
    conn.close()
    print(f"¥{price}")
except:
    sys.exit(1)
PYEOF
)
        if [ $? -eq 0 ]; then
            saved=$((saved + 1))
            echo -ne "\r[$processed/$URL_COUNT] ✅ $result\n"
        else
            failed=$((failed + 1))
            echo -ne "\r[$processed/$URL_COUNT] ❌ 解析失败\n"
        fi
    else
        failed=$((failed + 1))
        echo -ne "\r[$processed/$URL_COUNT] ❌ 无输出\n"
    fi
    rm -f "$tmpfile"

done < /tmp/price_watch_urls.txt

echo ""
echo "=== 完成: 成功 $saved, 失败 $failed ==="

# ========== 步骤6: 显示最新记录 ==========
python3 - "$DB_PATH" << 'PYEOF'
import sqlite3, sys
db_path = sys.argv[1]
conn = sqlite3.connect(db_path)
c = conn.cursor()
c.execute("SELECT price, url, datetime FROM price_history ORDER BY id DESC LIMIT 10")
print("\n=== 最新价格记录 ===")
print(f"{'价格':>8} | {'URL片段':<30} | {'时间'}")
print("-" * 70)
for row in c.fetchall():
    p = f"¥{row[0]}" if row[0] else "¥?"
    u = row[1][-30:] if row[1] else "?"
    print(f"{p:>8} | {u:<30} | {row[2]}")
conn.close()
PYEOF
echo "=== 完成 ==="