#!/bin/bash
# 商品搜索 - 获取多页商品并存入数据库
# 用法: ./02_search.sh <关键词> [页数]

KEYWORD="${1:-iphone}"
PAGES="${2:-2}"

echo "=== 商品搜索: $KEYWORD (第1-$PAGES页) ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB_PATH="$SCRIPT_DIR/../data/xianyu_products.db"

mkdir -p "$(dirname "$DB_PATH")"
sqlite3 "$DB_PATH" "CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT UNIQUE, title TEXT, price DECIMAL(10,2), location TEXT, seller TEXT, description TEXT, views TEXT, wants TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
sqlite3 "$DB_PATH" "DELETE FROM products;"

# 打开搜索页
echo "打开搜索页..."
ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$KEYWORD'))")
osascript -e "tell application \"Safari\" to open location \"https://www.goofish.com/search?q=$ENCODED\""
sleep 4

# 创建提取脚本
EXTRACT_SCRIPT="/tmp/xianyu_search_extract.scpt"
cat > "$EXTRACT_SCRIPT" << 'EOF'
tell application "Safari"
    tell window 1
        tell current tab
            set js to "var r={urls:[]};var ls=document.querySelectorAll('a[href*=item]');ls.forEach(function(l){if(l.href.match(/item\\?id=/)&&l.href.match(/goofish/)&&r.urls.indexOf(l.href)<0)r.urls.push(l.href);});JSON.stringify(r);"
            do JavaScript js
        end tell
    end tell
end tell
EOF

mkdir -p /tmp/xianyu_search
rm -f /tmp/xianyu_search/urls_*.txt

# 遍历页面
total=0
for ((page=1; page<=PAGES; page++)); do
    echo "=== 第 $page 页 ==="
    
    # 提取URL
    osascript "$EXTRACT_SCRIPT" > /tmp/xianyu_search/page_${page}.json 2>/dev/null
    
    count=$(python3 -c "import json; d=json.load(open('/tmp/xianyu_search/page_${page}.json')); print(len(d.get('urls',[])))" 2>/dev/null || echo 0)
    echo "提取到 $count 个URL"
    
    # 保存URL到文件
    python3 -c "import json; d=json.load(open('/tmp/xianyu_search/page_${page}.json')); [print(u) for u in d.get('urls',[])]" > /tmp/xianyu_search/urls_${page}.txt 2>/dev/null
    
    total=$((total + count))
    
    # 翻页
    if [ $page -lt $PAGES ]; then
        echo "翻页..."
        osascript -e 'tell application "Safari" to tell window 1 to tell current tab to do JavaScript "window.scrollTo(0, document.body.scrollHeight)"'
        sleep 2
        osascript -e 'tell application "Safari" to tell window 1 to tell current tab to do JavaScript "var b=document.querySelectorAll(\"button[class*=arrow]\"); if(b[b.length-1]) b[b.length-1].click();"'
        sleep 3
    fi
done

# 合并去重
cat /tmp/xianyu_search/urls_*.txt | sort -u > /tmp/xianyu_search/all_urls.txt
unique=$(wc -l < /tmp/xianyu_search/all_urls.txt)
echo ""
echo "=== 去重后共 $unique 个商品 ==="

# 写入数据库
echo "保存到数据库..."
saved=0
while IFS= read -r url; do
    [ -z "$url" ] && continue
    sqlite3 "$DB_PATH" "INSERT OR IGNORE INTO products (url) VALUES ('$url');" 2>/dev/null && saved=$((saved+1))
    echo -ne "\r已保存: $saved / $unique"
done < /tmp/xianyu_search/all_urls.txt

echo ""
echo "=== 完成 ==="

# 显示结果
sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM products;"