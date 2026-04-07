#!/usr/bin/env python3
"""
闲鱼热门商品获取脚本
通过 Safari 获取热门商品列表，提取标题、价格、链接

依赖: 无（使用 osascript 控制 Safari）
"""

import subprocess
import json
import re
import sys
from urllib.parse import quote

def run_applescript(script):
    """执行 AppleScript 并返回结果"""
    result = subprocess.run(
        ['osascript', '-e', script],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()

def search_xianyu(keyword, max_price=None, min_price=None):
    """
    搜索闲鱼商品
    
    Args:
        keyword: 搜索关键词
        max_price: 最高价格（可选）
        min_price: 最低价格（可选）
    
    Returns:
        搜索结果列表
    """
    encoded_keyword = quote(keyword)
    url = f"https://www.goofish.com/2fn?keyword={encoded_keyword}"
    
    if max_price:
        url += f"&price=0-{max_price}"
    if min_price and max_price:
        url = f"https://www.goofish.com/2fn?keyword={encoded_keyword}&price={min_price}-{max_price}"
    
    print(f"🔍 搜索: {keyword}")
    print(f"🔗 URL: {url}")
    
    # 打开搜索页面
    script = f'''
    tell application "Safari"
        activate
        open location "{url}"
        delay 3
    end tell
    '''
    run_applescript(script)
    
    return url

def extract_product_info():
    """
    从当前 Safari 页面提取商品信息
    
    Returns:
        商品信息列表
    """
    js_code = '''
    (function() {{
        const items = document.querySelectorAll('.item, .product-item, [data-item]');
        return JSON.stringify(Array.from(items).map(item => {{
            return {{
                title: item.querySelector('.title, .name, h3')?.textContent?.trim() || '',
                price: item.querySelector('.price, [data-price]')?.textContent?.trim() || '',
                url: item.querySelector('a')?.href || '',
                location: item.querySelector('.location, .region')?.textContent?.trim() || ''
            }};
        }}));
    }})()
    '''
    
    script = f'''
    tell application "Safari"
        set resultText to do JavaScript "{js_code.replace('"', '\\"')}" in front document
        return resultText
    end tell
    '''
    
    result = run_applescript(script)
    
    try:
        products = json.loads(result)
        return products
    except json.JSONDecodeError:
        print(f"⚠️ 无法解析页面内容，请确保在商品列表页面")
        return []

def print_products(products):
    """打印商品列表"""
    if not products:
        print("❌ 未找到商品")
        return
    
    print(f"\n📦 找到 {len(products)} 个商品:\n")
    
    for i, p in enumerate(products, 1):
        if not p.get('title'):
            continue
        print(f"{i}. {p['title']}")
        print(f"   💰 {p['price']}")
        if p.get('location'):
            print(f"   📍 {p['location']}")
        if p.get('url'):
            print(f"   🔗 {p['url']}")
        print()

def main():
    if len(sys.argv) < 2:
        print("用法: python3 get_hot_items.py <关键词> [最高价格] [最低价格]")
        print("示例: python3 get_hot_items.py \"iPhone\" 3000")
        sys.exit(1)
    
    keyword = sys.argv[1]
    max_price = sys.argv[2] if len(sys.argv) > 2 else None
    min_price = sys.argv[3] if len(sys.argv) > 3 else None
    
    search_xianyu(keyword, max_price, min_price)
    
    # 等待页面加载
    input("⏳ 页面加载完成后按回车继续...")
    
    products = extract_product_info()
    print_products(products)

if __name__ == "__main__":
    main()
