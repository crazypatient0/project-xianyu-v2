#!/usr/bin/env python3
import subprocess
import json
import time
import sys
import os
import sqlite3

DB_PATH = os.path.join(os.path.dirname(__file__), "../data/xianyu_products.db")
SCRIPT_FILE = "/tmp/xianyu_check_login.scpt"

def write_script(content):
    with open(SCRIPT_FILE, 'w') as f:
        f.write(content)

def run_applescript(content):
    write_script(content)
    result = subprocess.run(['/usr/bin/osascript', SCRIPT_FILE], capture_output=True)
    return result.stdout.decode().strip()

def check_login():
    js = """(function(){
var iframe=document.querySelector('iframe[src*=passport.goofish.com]');
var hasLoginIframe=!!iframe&&iframe.src.indexOf('mini_login.htm')!==-1;
var userEl=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');
var userName=userEl?userEl.innerText.trim():'';
var bodyText=document.body?document.body.innerText:'';
var hasMyPublish=bodyText.indexOf('我的发布')!==-1;
var hasMySold=bodyText.indexOf('我买到的')!==-1||bodyText.indexOf('我卖出的')!==-1;
return '{hasLoginIframe:'+hasLoginIframe+',userName:'+userName+',hasMyPublish:'+hasMyPublish+',hasMySold:'+hasMySold+'}';
})()"""
    content = f"""tell application "Safari"
    set r to do JavaScript "{js}" in front document
    return r
end tell"""
    try:
        output = run_applescript(content)
        if not output:
            return None
        data = json.loads(output)
        if data.get('hasLoginIframe'):
            return False
        if data.get('userName') or data.get('hasMyPublish') or data.get('hasMySold'):
            return True
        return False
    except:
        return None

def ensure_db():
    d = os.path.dirname(DB_PATH)
    if d: os.makedirs(d, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute('''CREATE TABLE IF NOT EXISTS user_info (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, url TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)''')
    conn.commit()
    conn.close()

def main():
    print("📱 打开闲鱼...")
    js_open = """tell application "Safari"
    activate
    open location "https://www.goofish.com"
    delay 8
end tell"""
    run_applescript(js_open)
    
    for i in range(30):
        result = check_login()
        if result is True:
            print("✅ 已登录")
            ensure_db()
            conn = sqlite3.connect(DB_PATH)
            js2 = """(function(){var u=document.querySelector('.user-nick,.nick-name,[class*=user-nick]');var n=u?u.innerText.trim():'';return '{name:'+n+',url:'+window.location.href+'}'})()"""
            content2 = f"""tell application "Safari"
    set r to do JavaScript "{js2}" in front document
    return r
end tell"""
            output = run_applescript(content2)
            if output:
                try:
                    data = json.loads(output)
                    conn.execute("INSERT INTO user_info (username, url) VALUES (?, ?)", (data.get('name', ''), data.get('url', '')))
                    conn.commit()
                    print(f"   用户: {data.get('name')}")
                except:
                    pass
            conn.close()
            print("🔔 LOGIN_SUCCESS")
            sys.exit(0)
        elif result is False:
            print(f"\r⏳ 未登录 (第{i+1}次/30)，请扫码登录...", end='', flush=True)
            time.sleep(2)
        else:
            print(f"\r⚠️ 检测失败，重试中...", end='', flush=True)
            time.sleep(2)
    
    print("\n❌ 登录超时")
    sys.exit(1)

if __name__ == "__main__":
    main()
