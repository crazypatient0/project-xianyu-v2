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

# 步骤4: 获取每一页的商品链接和详情
rm -rf /tmp/xianyu_search
mkdir -p /tmp/xianyu_search

for ((page=1; page<=PAGES; page++)); do
    echo "=== 第 $page 页 ==="

    # 获取快照（用于链接）
    echo "获取页面快照..."
    mcporter call safari.safari_snapshot --args '{"tabIndex":1}' > /tmp/xianyu_search/page_${page}.txt 2>&1

    # 提取商品链接
    grep -o 'href="https://www\.goofish\.com/item?id=[^"]*"' /tmp/xianyu_search/page_${page}.txt | sed 's/href="//;s/"//' | sort -u > /tmp/xianyu_search/links_${page}.txt
    link_count=$(wc -l < /tmp/xianyu_search/links_${page}.txt)
    echo "第${page}页: ${link_count} 个商品链接"

    # 提取当前页商品详情（改进版）
    echo "提取商品详情..."
    osascript << 'EOF' > /tmp/xianyu_search/products_${page}.json
tell application "Safari"
    tell window 1
        tell current tab
            do JavaScript "
var items = [];
var cards = document.querySelectorAll('a[href*=\"/item?id=\"]');
for(var i=0; i<cards.length && i<30; i++){
    var card = cards[i];
    var priceNum = card.querySelector('.number--NKh1vXWM');
    var priceDec = card.querySelector('.decimal--lSAcITCN');
    var price = priceNum ? (priceNum.innerText + (priceDec ? priceDec.innerText : '')) : '';
    var titleEl = card.querySelector('.main-title--sMrtWSJa');
    var title = titleEl ? titleEl.innerText.replace(/\\n/g,' ').substring(0,200) : '';
    var walker = document.createTreeWalker(card, NodeFilter.SHOW_TEXT, null, false);
    var texts = [];
    while(walker.nextNode()) {
        var t = walker.currentNode.nodeValue.trim();
        if(t && t.length > 0 && t.length < 30) texts.push(t);
    }
    var loc = '';
    var wants = '';
    for(var j=0; j<texts.length; j++) {
        if(texts[j].match(/人想要/)) {
            var m = texts[j].match(/(\\d+)人想要/);
            wants = m ? m[1] : '';
        }
    }
    for(var j=0; j<texts.length; j++) {
        var t = texts[j];
        if(t.match(/^.{2,4}$/) && 
           !t.match(/想要/) && 
           !t.match(/信用/) && 
           !t.match(/好评/) && 
           !t.match(/全新/) && 
           !t.match(/\\d+/) &&
           !t.match(/回复/) &&
           !t.match(/天内/) &&
           !t.match(/降价/) &&
           !t.match(/批发/) &&
           !t.match(/零售/) &&
           !t.match(/包邮/) &&
           !t.match(/自提/) &&
           !t.match(/全新/) &&
           !t.match(/几乎/)) {
            loc = t;
            break;
        }
    }
    items.push({title: title, price: price, loc: loc, wants: wants, url: card.href});
}
JSON.stringify(items);
"
        end tell
    end tell
end tell
EOF
    product_count=$(python3 -c "import json,sys; f=open('/tmp/xianyu_search/products_${page}.json'); d=json.load(f); print(len(d))" 2>/dev/null || echo 0)
    echo "第${page}页: ${product_count} 条详情"

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

# 步骤6: 合并所有详情并存入数据库
echo "保存到数据库..."
DB_PATH="/Users/lucifer/.openclaw/workspace-xiaoyu/project-xianyu/xianyu-automation/data/xianyu_products.db"
rm -f "$DB_PATH"

python3 << 'PYEOF'
import sqlite3
import os
import json

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

# 收集所有URL
all_urls = set()
with open("/tmp/xianyu_search/all_links.txt") as f:
    for line in f:
        url = line.strip()
        if url:
            all_urls.add(url)

# 收集所有页面的商品数据
url_to_data = {}
for page in range(1, 10):
    fname = f"/tmp/xianyu_search/products_{page}.json"
    if not os.path.exists(fname):
        break
    with open(fname) as f:
        content = f.read().strip()
        if content:
            try:
                products = json.loads(content)
                for p in products:
                    if p.get("url"):
                        url_to_data[p["url"]] = p
            except:
                pass

print(f"已提取 {len(url_to_data)} 个商品详情")

# 构建最终商品列表
final_products = []
for url in sorted(all_urls):
    if url in url_to_data:
        p = url_to_data[url]
        final_products.append({
            "url": url,
            "title": p.get("title", ""),
            "price": p.get("price", ""),
            "location": p.get("loc", ""),
            "wants": p.get("wants", "")
        })
    else:
        final_products.append({"url": url, "title": "", "price": "", "location": "", "wants": ""})

# 保存到数据库
saved = 0
for p in final_products:
    c.execute('INSERT OR IGNORE INTO products (url, title, price, location, wants) VALUES (?, ?, ?, ?, ?)',
             (p["url"], p["title"], p["price"], p["location"], p["wants"]))
    saved += 1

conn.commit()

# 统计
c.execute("SELECT COUNT(*) FROM products")
total = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM products WHERE price != ''")
with_price = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM products WHERE location != ''")
with_loc = c.fetchone()[0]
c.execute("SELECT COUNT(*) FROM products WHERE wants != ''")
with_wants = c.fetchone()[0]

print(f"数据库: {total} 个商品")
print(f"  - 有价格: {with_price}")
print(f"  - 有位置: {with_loc}")
print(f"  - 有想要数: {with_wants}")

# 示例
if total > 0:
    print("\n=== 商品示例 ===")
    c.execute("SELECT price, location, wants, title FROM products LIMIT 5")
    for row in c.fetchall():
        price = row[0] if row[0] else "?"
        loc = row[1] if row[1] else "?"
        wants = row[2] if row[2] else "0"
        title = (row[3] or "无标题")[:50]
        print(f"  ¥{price} | {loc} | {wants}人想要 | {title}...")

conn.close()
PYEOF

echo ""
echo "=== 完成 ==="
