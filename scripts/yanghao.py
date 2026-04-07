#!/usr/bin/env python3
"""
闲鱼养号功能
自动浏览商品、获取商品数据并存入数据库
模拟真人操作：随机选择标签、随机滑动距离、随机停顿时间
"""

import sys
import os
import json
import random
import time
import re

# Add scripts directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database import init_db, batch_insert, get_stats

# Safari AppleScript helper
def run_applescript(script):
    """Execute AppleScript and return result"""
    import subprocess
    result = subprocess.run(
        ['osascript', '-e', script],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()

def safari_open_url(url):
    """Open URL in Safari using AppleScript"""
    script = f'''
    tell application "Safari"
        activate
        tell front document
            set URL to "{url}"
        end tell
    end tell
    '''
    run_applescript(script)

def safari_click_element_by_text(text):
    """Click element by text content"""
    script = f'''
    tell application "Safari"
        activate
        tell front document
            do JavaScript "
                var elements = document.querySelectorAll('span, div, a');
                for (var el of elements) {{
                    if (el.innerText && el.innerText.trim() === '{text}') {{
                        el.click();
                        break;
                    }}
                }}
            "
        end tell
    end tell
    '''
    run_applescript(script)

def safari_scroll_random():
    """Scroll down by random amount"""
    distances = [200, 300, 400, 500, 600, 700, 800]
    distance = random.choice(distances)
    script = f'''
    tell application "Safari"
        activate
        tell front document
            do JavaScript "window.scrollBy(0, {distance});"
        end tell
    end tell
    '''
    run_applescript(script)

def safari_get_product_count():
    """Get current number of products on page"""
    script = '''
    tell application "Safari"
        activate
        tell front document
            do JavaScript "
                var items = document.querySelectorAll('a[href*=\"/item?id=\"]');
                var ids = new Set();
                items.forEach(function(a) {{
                    var m = a.href.match(/\\/item\\?id=(\\d+)/);
                    if (m) ids.add(m[1]);
                }});
                return ids.size;
            "
        end tell
    end tell
    '''
    try:
        result = run_applescript(script)
        return int(result) if result.isdigit() else 0
    except:
        return 0

def safari_extract_products():
    """Extract products from current page"""
    script = '''
    tell application "Safari"
        activate
        tell front document
            do JavaScript "
                (function() {
                    var items = document.querySelectorAll('a[href*=\"/item?id=\"]');
                    var products = [];
                    var seen = new Set();
                    
                    items.forEach(function(a) {
                        var href = a.href;
                        var match = href.match(/\\/item\\?id=(\\d+)/);
                        if (match && !seen.has(match[1])) {
                            seen.add(match[1]);
                            
                            var parent = a.closest('[class*=\\"item\\"]') || a.parentElement;
                            var title = (a.innerText || '').replace(/\\s+/g, ' ').trim();
                            var price = '';
                            var priceMatch = title.match(/¥[\\d,\\.]+/);
                            if (priceMatch) price = priceMatch[0];
                            
                            var wantMatch = title.match(/(\\d+)人想要/);
                            var wantCount = wantMatch ? wantMatch[1] : '0';
                            
                            // Extract location/seller info
                            var sellerMatch = title.match(/(卖家信用[\\u4e00-\\u9fa5]+)/);
                            var seller = sellerMatch ? sellerMatch[1] : '';
                            
                            // Clean title
                            var cleanTitle = title
                                .replace(/¥[\\d,\\.]+/g, '')
                                .replace(/\\d+人想要/g, '')
                                .replace(/(卖家信用[\\u4e00-\\u9fa5]+)/g, '')
                                .replace(/[^\\u4e00-\\u9fa5a-zA-Z0-9\\s]/g, '')
                                .replace(/\\s+/g, ' ')
                                .trim()
                                .substring(0, 100);
                            
                            products.push({
                                id: match[1],
                                title: cleanTitle,
                                price: price,
                                wantCount: wantCount,
                                seller: seller,
                                url: href
                            });
                        }
                    });
                    
                    return JSON.stringify(products);
                })()
            "
        end tell
    end tell
    '''
    
    try:
        result = run_applescript(script)
        if result and result.startswith('{') or result.startswith('['):
            return json.loads(result)
        return []
    except Exception as e:
        print(f"❌ 提取商品失败: {e}")
        return []

def yanghao_main(keyword=None, min_products=10, max_products=50):
    """
    养号主流程
    
    Args:
        keyword: 指定标签关键词（默认随机选择）
        min_products: 最少获取商品数量
        max_products: 最多获取商品数量
    
    Returns:
        dict: 执行结果统计
    """
    print("=" * 50)
    print("🕵️ 闲鱼养号功能启动")
    print("=" * 50)
    
    # 初始化数据库
    init_db()
    
    # 标签列表
    tabs = ['猜你喜欢', '个人闲置', 'BJD娃娃', '垂钓', '吉他乐器', 
            '台球', '摄影摄像', '钱币收藏', '女装穿搭', '居家好物', '大牌美妆']
    
    # 随机选择标签
    if keyword is None:
        keyword = random.choice(tabs)
    
    print(f"\n📍 选择的标签: {keyword}")
    
    # 打开闲鱼首页
    print(f"\n🌐 打开闲鱼首页...")
    safari_open_url("https://www.goofish.com")
    time.sleep(3)  # 等待页面加载
    
    # 点击标签
    print(f"👆 点击「{keyword}」标签...")
    safari_click_element_by_text(keyword)
    time.sleep(2)  # 等待切换
    
    # 确定要获取的商品数量
    target_count = random.randint(min_products, max_products)
    print(f"\n🎯 目标获取商品数: {target_count}")
    
    # 记录初始商品数
    initial_count = safari_get_product_count()
    print(f"📊 初始商品数: {initial_count}")
    
    all_products = []
    scroll_count = 0
    
    # 滚动直到达到目标或超时
    max_scrolls = 30
    delays = [1.5, 2.0, 2.5, 3.0, 3.5, 4.0]  # 随机延迟（秒）
    
    print(f"\n🔄 开始滚动加载...")
    
    while len(all_products) < target_count and scroll_count < max_scrolls:
        scroll_count += 1
        
        # 随机滑动距离
        distances = [300, 400, 500, 600, 700]
        distance = random.choice(distances)
        
        print(f"  第{scroll_count}次滚动: +{distance}px", end='')
        
        # 滚动
        safari_scroll_random()
        
        # 随机延迟（模拟真人操作）
        delay = random.choice(delays)
        print(f" | 等待{delay:.1f}秒")
        time.sleep(delay)
        
        # 获取当前商品数
        current_count = safari_get_product_count()
        
        # 提取商品
        products = safari_extract_products()
        
        # 合并去重
        existing_ids = {p['id'] for p in all_products}
        new_products = [p for p in products if p['id'] not in existing_ids]
        all_products.extend(new_products)
        
        print(f"    当前商品: {current_count} | 新增: {len(new_products)} | 总计: {len(all_products)}")
        
        # 如果连续多次没有新增，尝试换个位置
        if len(new_products) == 0 and random.random() < 0.3:
            print(f"    🔄 无新增，随机微调位置...")
            safari_scroll_random()
            time.sleep(2)
    
    print(f"\n📦 共获取商品: {len(all_products)} 个")
    
    # 保存到数据库
    if all_products:
        print(f"\n💾 保存到数据库...")
        search_keyword = keyword
        new_count, update_count = batch_insert(all_products, search_keyword)
        print(f"   🆕 新增: {new_count} 条")
        print(f"   🔄 更新: {update_count} 条")
    
    # 显示数据库统计
    stats = get_stats()
    print(f"\n📊 数据库统计:")
    print(f"   总记录: {stats['total']}")
    print(f"   独立商品: {stats['unique_count']}")
    
    print("\n" + "=" * 50)
    print("✅ 养号完成！")
    print("=" * 50)
    
    return {
        'tab': keyword,
        'products_found': len(all_products),
        'scroll_count': scroll_count,
        'stats': stats
    }


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='闲鱼养号功能')
    parser.add_argument('--tab', '-t', help='指定标签（如：猜你喜欢、个人闲置）')
    parser.add_argument('--min', type=int, default=10, help='最少获取商品数')
    parser.add_argument('--max', type=int, default=50, help='最多获取商品数')
    
    args = parser.parse_args()
    
    result = yanghao_main(
        keyword=args.tab,
        min_products=args.min,
        max_products=args.max
    )
    
    print(f"\n📋 执行结果:")
    print(f"   标签: {result['tab']}")
    print(f"   获取商品: {result['products_found']}")
    print(f"   滚动次数: {result['scroll_count']}")
