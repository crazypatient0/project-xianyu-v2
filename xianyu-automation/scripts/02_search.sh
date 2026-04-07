#!/bin/bash
# 商品搜索 - 获取多页商品并存入数据库
# 用法: ./02_search.sh <关键词> [页数]
# 默认获取3页（约90个商品）

KEYWORD="${1:-iphone}"
PAGES="${2:-3}"

echo "=== 商品搜索: $KEYWORD (第1-$PAGES页) ==="

# 步骤1: 打开Safari
echo "打开Safari..."
osascript -e 'tell application "Safari" to activate'

# 步骤2: 导航到搜索页
echo "导航到搜索页..."
osascript -e 'tell application "Safari" to tell window 1 to tell current tab to set URL to "https://www.goofish.com/search?q='"$KEYWORD"'"'

# 步骤3: 等待页面加载
sleep 3

# 步骤4: 获取每一页的商品链接
mkdir -p /tmp/xianyu_search
rm -f /tmp/xianyu_search/page_*.txt /tmp/xianyu_search/links_*.txt

for ((page=1; page<=PAGES; page++)); do
    echo "=== 第 $page 页 ==="

    # 获取快照
    echo "获取页面快照..."
    mcporter call safari.safari_snapshot --args '{"tabIndex":1}' > /tmp/xianyu_search/page_${page}.txt 2>&1

    # 提取商品链接
    grep -o 'href="https://www\.goofish\.com/item?id=[^"]*"' /tmp/xianyu_search/page_${page}.txt | sed 's/href="//;s/"//' | sort -u > /tmp/xianyu_search/links_${page}.txt
    count=$(wc -l < /tmp/xianyu_search/links_${page}.txt)
    echo "第${page}页: ${count} 个商品"

    # 点击下一页（如果不是最后一页）
    if [ $page -lt $PAGES ]; then
        echo "点击下一页..."
        osascript -e 'tell application "Safari" to tell window 1 to tell current tab to do JavaScript "var btns = document.querySelectorAll(\"button[class*=\\\"pagination-arrow\\\"]\"); if(btns[1]){ btns[1].click(); }"' 2>/dev/null
        sleep 3
    fi
done

# 步骤5: 合并所有链接
cat /tmp/xianyu_search/links_*.txt | sort -u > /tmp/xianyu_search/all_links.txt
total=$(wc -l < /tmp/xianyu_search/all_links.txt)
echo ""
echo "=== 总计: $total 个商品 ==="

# 步骤6: 保存到数据库
echo "保存到数据库..."
DB_PATH="/Users/lucifer/.openclaw/workspace-xiaoyu/project-xianyu/xianyu-automation/data/xianyu_products.db"
rm -f "$DB_PATH"

python3 << 'PYEOF'
import sqlite3
import os
import re

DB_PATH = "/Users/lucifer/.openclaw/workspace-xiaoyu/project-xianyu/xianyu-automation/data/xianyu_products.db"
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

conn = sqlite3.connect(DB_PATH)
c = conn.cursor()
c.execute('''CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT UNIQUE,
    title TEXT,
    price TEXT,
    location TEXT,
    seller TEXT,
    description TEXT,
    views TEXT,
    wants TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
''')

with open("/tmp/xianyu_search/all_links.txt") as f:
    all_links = [line.strip() for line in f if line.strip()]

snapshots = {
    1: "/tmp/xianyu_search/page_1.txt",
    2: "/tmp/xianyu_search/page_2.txt", 
    3: "/tmp/xianyu_search/page_3.txt"
}

products = {}
for url in all_links:
    products[url] = {"url": url, "title": "", "price": ""}

for page_num, snap_path in snapshots.items():
    if not os.path.exists(snap_path):
        continue
    with open(snap_path) as f:
        snapshot = f.read()
    pattern = re.compile(r'ref=\d+_\d+ link "([^"]+)" focusable href="(https://www\.goofish\.com/item\?id=[^"]+)"')
    for match in pattern.finditer(snapshot):
        title = match.group(1)
        url = match.group(2)
        if url in products:
            products[url]["title"] = title[:300]
            pm = re.search(r'¥(\d+(?:\.\d+)?)', title)
            if pm:
                products[url]["price"] = pm.group(1)

saved = 0
for p in products.values():
    if p["title"] or p["price"]:
        c.execute('INSERT OR IGNORE INTO products (url, title, price) VALUES (?, ?, ?)',
                 (p["url"], p["title"], p["price"]))
        saved += 1

conn.commit()
print(f"已保存 {saved} 个商品到数据库")
conn.close()
PYEOF

echo ""
echo "=== 完成 ==="
