#!/usr/bin/env python3
import subprocess
import json
import re
import sqlite3
import os
import time

DB_PATH = "/Users/lucifer/.openclaw/workspace-xiaoyu/project-xianyu/xianyu-automation/data/xianyu_products.db"

def ensure_dir():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

def init_db():
    ensure_dir()
    conn = sqlite3.connect(DB_PATH)
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
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )''')
    conn.commit()
    return conn

def call_mcporter(cmd, args=None):
    if args:
        result = subprocess.run(
            ['mcporter', 'call', cmd, '--args', json.dumps(args)],
            capture_output=True, text=True, timeout=30
        )
    else:
        result = subprocess.run(
            ['mcporter', 'call', cmd],
            capture_output=True, text=True, timeout=30
        )
    return result.stdout

def get_snapshot(tab=4):
    result = call_mcporter('safari.safari_snapshot', {"tabIndex": tab})
    return result

def parse_products_from_snapshot(snapshot_text):
    products = []
    
    link_pattern = re.compile(r'ref=\d+_(\d+) link "([^"]+)" focusable href="(https://www\.goofish\.com/item\?id=[^"]+)"')
    
    for match in link_pattern.finditer(snapshot_text):
        ref_num = match.group(1)
        title = match.group(2)
        url = match.group(3)
        
        if '/item?' in url:
            price_match = re.search(r'¥(\d+(?:\.\d+)?)', title)
            price = price_match.group(1) if price_match else ''
            
            products.append({
                'url': url,
                'title': title[:300],
                'price': price
            })
    
    return products

def save_to_db(conn, products):
    c = conn.cursor()
    saved = 0
    for p in products:
        try:
            c.execute('''INSERT OR IGNORE INTO products (url, title, price) VALUES (?, ?, ?)''',
                     (p['url'], p['title'], p['price']))
            saved += 1
        except Exception as e:
            print(f"  保存失败: {p['url']}: {e}")
    conn.commit()
    return saved

def main():
    print("=== 商品搜索提取 ===")
    
    conn = init_db()
    print(f"数据库: {DB_PATH}")
    
    snapshot = get_snapshot(tab=4)
    with open("/tmp/snapshot_search.txt", "w") as f:
        f.write(snapshot)
    
    products = parse_products_from_snapshot(snapshot)
    print(f"解析到 {len(products)} 个商品")
    
    saved = save_to_db(conn, products)
    print(f"成功保存 {saved} 个商品")
    
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM products")
    total = c.fetchone()[0]
    print(f"数据库总计: {total} 个商品")
    
    if total > 0:
        print("\n=== 商品示例 ===")
        c.execute("SELECT price, title FROM products LIMIT 3")
        for row in c.fetchall():
            print(f"  ¥{row[0] if row[0] else '?'} - {row[1][:60]}...")
    
    conn.close()
    print("\n=== 完成 ===")

if __name__ == "__main__":
    main()
