#!/bin/bash
# 商品搜索 - 获取多页商品并存入数据库
# 用法: ./02_search.sh <关键词> [页数]
# 默认获取1页

KEYWORD="${1:-mac}"
PAGES="${2:-1}"

echo "=== 商品搜索: $KEYWORD (第1-$PAGES页) ==="

# 确保数据库目录存在
DB_DIR="/Users/lucifer/.openclaw/workspace-xiaoyu/project-xianyu/xianyu-automation/data"
mkdir -p "$DB_DIR"
DB_FILE="$DB_DIR/xianyu_products.db"

# 步骤1: 确保Safari运行
echo "1. 激活Safari..."
osascript -e 'tell application "Safari" to activate'
sleep 1

# 步骤2: 导航到搜索页
echo "2. 导航到搜索页..."
osascript -e 'tell application "Safari" to set URL of front document to "https://www.goofish.com/search?q='"$KEYWORD"'"'
sleep 3

# 步骤3: 提取所有页的商品链接
echo "3. 提取各页商品链接..."

rm -f /tmp/search_links.json /tmp/search_page_*.json
ALL_LINKS=()

for ((page=1; page<=PAGES; page++)); do
    echo "   === 第 $page 页 ==="
    
    # 提取当前页链接
    osascript > /tmp/search_page_${page}.json << 'EOF'
set js to "JSON.stringify([].map.call(document.querySelectorAll('a[href*=\"/item?id=\"]'), function(a){return a.href}).slice(0,30))"
tell application "Safari"
  do JavaScript js in front document
end tell
EOF

    count=$(python3 -c "import json; print(len(json.load(open('/tmp/search_page_${page}.json'))))" 2>/dev/null || echo 0)
    echo "   获取到 $count 个链接"
    
    # 点击下一页（如果是最后一页则跳过）
    if [ $page -lt $PAGES ]; then
        echo "   点击下一页..."
        
        # 使用XPath点击下一页按钮
        # XPath: //*[@id="content"]/div[2]/div[4]/div/div[1]/button[2]/div
        # 注意: 必须用文件方式执行JS，直接 -e 内联会有转义问题
        cat > /tmp/xpath_next.js << 'JSEOF'
var btn = document.evaluate(
  "//*[@id='content']/div[2]/div[4]/div/div[1]/button[2]/div",
  document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
).singleNodeValue;
if(btn){ btn.click(); "clicked"; } else { "not_found"; }
JSEOF
        osascript -e 'set js to do shell script "cat /tmp/xpath_next.js"
tell application "Safari"
  do JavaScript js in front document
end tell'
        
        sleep 3
    fi
done

# 合并所有页链接并去重
echo "   合并并去重链接..."
python3 << 'PYEOF'
import json
import os

all_links = []
seen = set()
for i in range(1, 100):
    fname = f"/tmp/search_page_{i}.json"
    if not os.path.exists(fname):
        break
    try:
        links = json.load(open(fname))
        for link in links:
            url = link.split('&')[0]  # 去除多余参数
            if url not in seen:
                seen.add(url)
                all_links.append(url)
    except:
        pass

with open('/tmp/search_links.json', 'w') as f:
    json.dump(all_links, f)

print(f"合并后共 {len(all_links)} 个唯一链接")
PYEOF

link_count=$(python3 -c "import json; print(len(json.load(open('/tmp/search_links.json'))))")
echo "   总计: $link_count 个商品链接"

if [ "$link_count" -eq 0 ]; then
  echo "   错误: 无法获取商品链接"
  exit 1
fi

# 步骤4: 访问商品获取详情
echo "4. 获取商品详情..."

python3 << 'PYEOF'
import json
import subprocess
import time
import re

LOCATIONS = [
    '北京', '上海', '天津', '重庆',
    '广东', '浙江', '江苏', '四川', '山东', '河南', '湖北', '湖南',
    '河北', '山西', '辽宁', '吉林', '黑龙江', '安徽', '福建', '江西',
    '海南', '贵州', '云南', '陕西', '甘肃', '青海', '台湾',
    '内蒙古', '广西', '西藏', '宁夏', '新疆', '香港', '澳门',
    '广州', '深圳', '成都', '杭州', '武汉', '西安', '南京', '苏州',
    '大连', '沈阳', '青岛', '长沙', '郑州', '东莞', '佛山', '宁波'
]

with open('/tmp/search_links.json') as f:
    links = json.load(f)

print(f"   准备获取 {len(links)} 个商品详情...")

results = []
for i, url in enumerate(links):
    try:
        subprocess.run([
            'osascript', '-e', 
            f'tell application "Safari" to set URL of front document to "{url}"'
        ], capture_output=True)
        time.sleep(2)
        
        result = subprocess.run([
            'osascript', '-e', 
            'tell application "Safari" to do JavaScript "document.body.innerText" in front document'
        ], capture_output=True, text=True)
        
        text = result.stdout
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        
        info = {'url': url, 'price': '', 'title': '', 'location': '', 'wants': '0'}
        
        # 解析价格
        for line in lines:
            if '¥' in line:
                m = re.search(r'¥\s*(\d+[\.d]*)?', line)
                if m and m.group(1):
                    info['price'] = m.group(1).replace('d', '.')
                    break
        
        # 想要数
        for line in lines:
            m = re.search(r'(\d+)\s*人想要', line)
            if m:
                info['wants'] = m.group(1)
                break
        
        # 位置
        for j, line in enumerate(lines):
            if re.search(r'\d+\s*(小时|天|分钟)前来过', line):
                if j > 0:
                    prev = lines[j-1]
                    if prev in LOCATIONS or (len(prev) <= 6 and re.match(r'^[\u4e00-\u9fa5]+$', prev)):
                        info['location'] = prev
                        break
        
        if not info['location']:
            for j, line in enumerate(lines):
                if '来过' in line and j > 0:
                    prev = lines[j-1]
                    if len(prev) <= 6 and re.match(r'^[\u4e00-\u9fa5]+$', prev):
                        if prev not in ['搜索', '网页版', '综合', '个人', '全新']:
                            info['location'] = prev
                            break
        
        # 标题
        for line in lines:
            line = line.strip()
            if len(line) > 15 and not line.startswith('¥') and '想要' not in line and '浏览' not in line and '信用' not in line and '来过' not in line:
                info['title'] = line[:80]
                break
        
        results.append(info)
        price = info['price'] or '?'
        wants = info['wants']
        loc = info['location'] or '?'
        print(f"   [{i+1}] ¥{price} | {loc} | {wants}人想要")
        
    except Exception as e:
        print(f"   [{i+1}] 错误: {e}")

with open('/tmp/search_details.json', 'w') as f:
    json.dump(results, f, ensure_ascii=False)

print(f"   完成: {len(results)} 个商品")
PYEOF

# 步骤5: 存入数据库
echo "5. 保存到数据库..."

python3 << "PYEOF"
import sqlite3
import json

DB_PATH = "/Users/lucifer/.openclaw/workspace-xiaoyu/project-xianyu/xianyu-automation/data"
DB_FILE = f"{DB_PATH}/xianyu_products.db"

conn = sqlite3.connect(DB_FILE)
c = conn.cursor()
c.execute('''CREATE TABLE IF NOT EXISTS products (
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

try:
    with open('/tmp/search_details.json') as f:
        products = json.load(f)
    
    saved = 0
    skipped = 0
    for p in products:
        try:
            c.execute('''INSERT INTO products (url, title, price, location, wants) 
                         VALUES (?, ?, ?, ?, ?)''',
                     (p.get('url',''), p.get('title',''), p.get('price',''), 
                      p.get('location',''), p.get('wants','0')))
            saved += 1
        except:
            skipped += 1
    
    conn.commit()
    print(f"   新增 {saved} 个商品 (跳过 {skipped} 个重复)")
except Exception as e:
    print(f"   保存失败: {e}")

c.execute("SELECT COUNT(*) FROM products")
total = c.fetchone()[0]
print(f"   数据库总计: {total} 个商品")

if total > 0:
    print("\n=== 商品示例 (最新) ===")
    c.execute("SELECT price, location, wants, title FROM products ORDER BY id DESC LIMIT 5")
    for row in c.fetchall():
        price = row[0] if row[0] else "?"
        loc = row[1] if row[1] else "?"
        wants = row[2] if row[2] else "0"
        title = (row[3] or "")[:40]
        print(f"  ¥{price} | {loc} | {wants}人想要 | {title}")

conn.close()
PYEOF

echo ""
echo "=== 完成 ==="