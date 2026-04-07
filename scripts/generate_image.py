#!/usr/bin/env python3
"""
Draw Things API 图片生成脚本
通过 Draw Things 本地 API 生成 AI 图片
"""

import subprocess
import json
import base64
import argparse
import os
from pathlib import Path

def generate_image(prompt, negative_prompt="", width=1024, height=1024, 
                   steps=20, cfg_scale=7.5, sampler="DPM++ 2M Karras",
                   output_path=None, timeout=120):
    """
    调用 Draw Things API 生成图片
    
    Args:
        prompt: 图片描述
        negative_prompt: 负面提示词
        width: 图片宽度
        height: 图片高度
        steps: 生成步数
        cfg_scale: CFG 强度
        sampler: 采样器
        output_path: 输出路径
        timeout: 超时时间（秒）
    
    Returns:
        str: 生成的图片路径
    """
    api_url = "http://localhost:7860/sdapi/v1/txt2img"
    
    payload = {
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "width": width,
        "height": height,
        "steps": steps,
        "cfg_scale": cfg_scale,
        "sampler_name": sampler
    }
    
    # 构建 curl 命令
    cmd = [
        "curl", "-s", "--max-time", str(timeout),
        "-X", "POST", api_url,
        "-H", "Content-Type: application/json",
        "-d", json.dumps(payload)
    ]
    
    print(f"🎨 正在生成图片...")
    print(f"   提示词: {prompt[:50]}...")
    print(f"   尺寸: {width}x{height}")
    print(f"   步数: {steps}")
    
    # 执行请求
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        raise Exception(f"API 请求失败: {result.stderr}")
    
    # 解析响应
    data = json.loads(result.stdout)
    
    if "error" in data:
        raise Exception(f"生成错误: {data['error']}")
    
    if "images" not in data or len(data["images"]) == 0:
        raise Exception("未返回图片数据")
    
    # 解码图片
    img_data = base64.b64decode(data["images"][0])
    
    # 确定输出路径
    if output_path is None:
        desktop = Path.home() / "Desktop"
        output_path = desktop / f"generated_{int(os.times().elapsed * 1000)}.png"
    
    # 保存图片
    with open(output_path, "wb") as f:
        f.write(img_data)
    
    print(f"✅ 图片已保存: {output_path}")
    print(f"   大小: {len(img_data) / 1024:.1f} KB")
    
    return str(output_path)


def main():
    parser = argparse.ArgumentParser(description="使用 Draw Things API 生成图片")
    parser.add_argument("--prompt", "-p", required=True, help="图片描述")
    parser.add_argument("--negative", "-n", default="", help="负面提示词")
    parser.add_argument("--width", "-W", type=int, default=1024, help="图片宽度")
    parser.add_argument("--height", "-H", type=int, default=1024, help="图片高度")
    parser.add_argument("--steps", "-s", type=int, default=20, help="生成步数")
    parser.add_argument("--cfg", "-c", type=float, default=7.5, help="CFG 强度")
    parser.add_argument("--sampler", default="DPM++ 2M Karras", help="采样器")
    parser.add_argument("--output", "-o", help="输出路径")
    parser.add_argument("--timeout", "-t", type=int, default=120, help="超时时间(秒)")
    
    args = parser.parse_args()
    
    try:
        output_path = generate_image(
            prompt=args.prompt,
            negative_prompt=args.negative,
            width=args.width,
            height=args.height,
            steps=args.steps,
            cfg_scale=args.cfg,
            sampler=args.sampler,
            output_path=args.output,
            timeout=args.timeout
        )
        print(f"\n📦 输出文件: {output_path}")
    except Exception as e:
        print(f"❌ 生成失败: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
