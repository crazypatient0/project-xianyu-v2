#!/usr/bin/env python3
"""
闲鱼商品数据库管理
使用 SQLite 存储商品检索数据
"""

import sqlite3
import json
import re
from datetime import datetime
from typing import List, Dict, Optional

DB_PATH = "/Users/lucifer/.openclaw/workspace/project-xianyu/data/xianyu_products.db"

def parse_price(price_str: str) -> float:
    """
    解析价格字符串，只提取数字
    
    Args:
        price_str: 价格字符串，如 '¥1200' 或 '¥1,299.00'
    
    Returns:
        float: 价格数字，如 1200.0 或 1299.0
    """
    if not price_str:
        return 0.0
    # 匹配价格模式：¥符号后跟数字（可能有逗号分隔）
    match = re.search(r'¥\s*([\d,]+\.?\d*)', str(price_str))
    if match:
        cleaned = match.group(1).replace(',', '')
        try:
            return float(cleaned) if cleaned else 0.0
        except ValueError:
            return 0.0
    # 兜底：移除所有非数字字符，取第一个连续数字
    numbers = re.findall(r'\d+\.?\d*', str(price_str))
    if numbers:
        try:
            return float(numbers[0]) if numbers[0] else 0.0
        except ValueError:
            return 0.0
    return 0.0

def get_db():
    """获取数据库连接"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """初始化数据库"""
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id TEXT UNIQUE NOT NULL,
            title TEXT,
            price REAL DEFAULT 0,
            location TEXT,
            seller TEXT,
            want_count TEXT,
            url TEXT,
            search_keyword TEXT,
            stime TEXT,
            utime TEXT,
            raw_data TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 创建索引
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_item_id ON products(item_id)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_stime ON products(stime)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_search_keyword ON products(search_keyword)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_price ON products(price)
    ''')
    
    conn.commit()
    conn.close()
    print(f"✅ 数据库初始化完成: {DB_PATH}")

def insert_or_update(product: Dict, search_keyword: str) -> bool:
    """
    插入或更新商品记录
    
    Args:
        product: 商品数据字典
        search_keyword: 搜索关键词
    
    Returns:
        bool: True 表示新增, False 表示更新
    """
    conn = get_db()
    cursor = conn.cursor()
    
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    item_id = product.get('id', '')
    
    # 检查是否存在
    cursor.execute('SELECT id FROM products WHERE item_id = ?', (item_id,))
    exists = cursor.fetchone() is not None
    
    if exists:
        # 更新记录
        cursor.execute('''
            UPDATE products SET
                title = ?,
                price = ?,
                location = ?,
                seller = ?,
                want_count = ?,
                url = ?,
                search_keyword = ?,
                utime = ?,
                updated_at = ?
            WHERE item_id = ?
        ''', (
            product.get('title', ''),
            parse_price(product.get('price', '')),
            product.get('location', ''),
            product.get('seller', ''),
            product.get('wantCount', ''),
            product.get('url', ''),
            search_keyword,
            now,
            now,
            item_id
        ))
        conn.commit()
        conn.close()
        return False
    else:
        # 新增记录
        cursor.execute('''
            INSERT INTO products (
                item_id, title, price, location, seller, want_count,
                url, search_keyword, stime, utime, raw_data
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            item_id,
            product.get('title', ''),
            parse_price(product.get('price', '')),
            product.get('location', ''),
            product.get('seller', ''),
            product.get('wantCount', ''),
            product.get('url', ''),
            search_keyword,
            now,
            now,
            json.dumps(product, ensure_ascii=False)
        ))
        conn.commit()
        conn.close()
        return True

def batch_insert(products: List[Dict], search_keyword: str) -> tuple:
    """
    批量插入或更新商品
    
    Args:
        products: 商品列表
        search_keyword: 搜索关键词
    
    Returns:
        tuple: (新增数量, 更新数量)
    """
    new_count = 0
    update_count = 0
    
    for product in products:
        is_new = insert_or_update(product, search_keyword)
        if is_new:
            new_count += 1
        else:
            update_count += 1
    
    return (new_count, update_count)

def get_product(item_id: str) -> Optional[Dict]:
    """根据 item_id 获取商品"""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM products WHERE item_id = ?', (item_id,))
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return dict(row)
    return None

def get_products_by_keyword(keyword: str, limit: int = 100) -> List[Dict]:
    """根据关键词获取商品列表"""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM products 
        WHERE search_keyword = ? 
        ORDER BY stime DESC 
        LIMIT ?
    ''', (keyword, limit))
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]

def get_all_products(limit: int = 1000, offset: int = 0) -> List[Dict]:
    """获取所有商品"""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT * FROM products 
        ORDER BY stime DESC 
        LIMIT ? OFFSET ?
    ''', (limit, offset))
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]

def search_products(keyword: str, min_price: float = None, max_price: float = None) -> List[Dict]:
    """搜索商品（标题或关键词）"""
    conn = get_db()
    cursor = conn.cursor()
    
    query = 'SELECT * FROM products WHERE title LIKE ?'
    params = [f'%{keyword}%']
    
    if min_price is not None:
        query += ' AND price >= ?'
        params.append(min_price)
    
    if max_price is not None:
        query += ' AND price <= ?'
        params.append(max_price)
    
    query += ' ORDER BY stime DESC LIMIT 100'
    
    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]

def get_products_by_price_range(min_price: float, max_price: float, keyword: str = None) -> List[Dict]:
    """根据价格区间获取商品"""
    conn = get_db()
    cursor = conn.cursor()
    
    query = 'SELECT * FROM products WHERE price >= ? AND price <= ?'
    params = [min_price, max_price]
    
    if keyword:
        query += ' AND title LIKE ?'
        params.append(f'%{keyword}%')
    
    query += ' ORDER BY price ASC LIMIT 100'
    
    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]

def get_stats() -> Dict:
    """获取数据库统计信息"""
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('SELECT COUNT(*) as total FROM products')
    total = cursor.fetchone()['total']
    
    cursor.execute('SELECT COUNT(DISTINCT item_id) as unique_count FROM products')
    unique_count = cursor.fetchone()['unique_count']
    
    cursor.execute('SELECT COUNT(DISTINCT search_keyword) as keyword_count FROM products')
    keyword_count = cursor.fetchone()['keyword_count']
    
    cursor.execute('SELECT search_keyword, COUNT(*) as count FROM products GROUP BY search_keyword ORDER BY count DESC')
    keywords = [dict(row) for row in cursor.fetchall()]
    
    # 价格统计
    cursor.execute('SELECT MIN(price) as min_price, MAX(price) as max_price, AVG(price) as avg_price FROM products WHERE price > 0')
    price_stats = dict(cursor.fetchone())
    
    conn.close()
    
    return {
        'total': total,
        'unique_count': unique_count,
        'keyword_count': keyword_count,
        'keywords': keywords,
        'price_stats': price_stats
    }

def delete_old_products(days: int = 30) -> int:
    """删除指定天数前的数据"""
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute('DELETE FROM products WHERE stime < datetime("now", "-" || ? || " days")', (days,))
    deleted = cursor.rowcount
    
    conn.commit()
    conn.close()
    
    return deleted

def clear_all():
    """清空所有数据"""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM products')
    deleted = cursor.rowcount
    conn.commit()
    conn.close()
    return deleted

if __name__ == "__main__":
    import sys
    
    # 初始化数据库
    init_db()
    
    if len(sys.argv) > 1:
        if sys.argv[1] == '--stats':
            stats = get_stats()
            print(f"\n📊 数据库统计:")
            print(f"   总记录数: {stats['total']}")
            print(f"   独立商品: {stats['unique_count']}")
            print(f"   搜索关键词: {stats['keyword_count']}")
            if stats['price_stats']['min_price']:
                print(f"   价格范围: ¥{stats['price_stats']['min_price']:.0f} - ¥{stats['price_stats']['max_price']:.0f}")
                print(f"   平均价格: ¥{stats['price_stats']['avg_price']:.0f}")
            print(f"\n   关键词分布:")
            for kw in stats['keywords'][:10]:
                print(f"   - {kw['search_keyword']}: {kw['count']}条")
        
        elif sys.argv[1] == '--list':
            products = get_all_products(limit=20)
            print(f"\n📦 最近 {len(products)} 条记录:")
            for p in products:
                print(f"   [{p['item_id']}] {p['title'][:40]}... | ¥{p['price']:.0f} | {p['location']}")
        
        elif sys.argv[1] == '--clear':
            deleted = clear_all()
            print(f"\n🗑️ 已清空 {deleted} 条记录")
    
    print(f"\n✅ 数据库操作完成")
