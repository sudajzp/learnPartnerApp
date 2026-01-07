#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import json
import time
import os
import hashlib

# 添加应用包中的Python依赖路径到sys.path
app_root = os.path.dirname(os.path.abspath(__file__))
python_lib_path = os.path.join(app_root, '..', 'Library', 'Python')
sys.path.insert(0, python_lib_path)

# 尝试导入requests库，如果失败则使用urllib.request
try:
    import requests
    use_requests = True
except ImportError:
    import urllib.request
    import urllib.error
    use_requests = False

def get_application_support_directory():
    """
    获取应用支持目录路径
    """
    try:
        app_support_dir = os.path.expanduser("~/.learnpartner")
        if not os.path.exists(app_support_dir):
            os.makedirs(app_support_dir)
        return app_support_dir
    except Exception as e:
        print(f"获取应用支持目录失败: {e}")
        return None

def save_api_key(api_key):
    """
    保存API密钥到配置文件
    """
    try:
        app_support_dir = get_application_support_directory()
        if not app_support_dir:
            return False
        
        config_path = os.path.join(app_support_dir, "config.json")
        config = {
            "api_key": api_key,
            "updated_at": time.time()
        }
        
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(config, f, ensure_ascii=False, indent=4)
        return True
    except Exception as e:
        print(f"保存API密钥失败: {e}")
        return False

def load_api_key():
    """
    从配置文件加载API密钥
    """
    try:
        app_support_dir = get_application_support_directory()
        if not app_support_dir:
            return None
        
        config_path = os.path.join(app_support_dir, "config.json")
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                config = json.load(f)
                return config.get("api_key")
        return None
    except Exception as e:
        print(f"加载API密钥失败: {e}")
        return None

def translate_text(text, source_lang='auto', target_lang='zh-CN'):
    """
    使用阿里云百炼模型进行翻译
    """
    try:
        # 加载API密钥
        api_key = load_api_key()
        if not api_key:
            return {
                'success': False,
                'text': '',
                'error': 'API密钥未配置，请在应用设置中配置阿里云百炼API密钥'
            }
        
        # 阿里云百炼API请求参数
        url = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        
        # 构建请求体
        payload = {
            "model": "qwen-turbo",
            "input": {
                "messages": [
                    {
                        "role": "system",
                        "content": f"你是一个专业的翻译工具，请将以下文本从{source_lang}翻译成{target_lang}，仅返回翻译结果，不要添加任何解释或额外信息。"
                    },
                    {
                        "role": "user",
                        "content": text
                    }
                ]
            },
            "parameters": {
                "temperature": 0.3,
                "max_tokens": 2000
            }
        }
        
        # 发送请求 - 根据use_requests选择使用requests或urllib.request
        if use_requests:
            # 使用requests库
            response = requests.post(url, headers=headers, json=payload, timeout=10)
            response.raise_for_status()
            
            # 解析响应
            result = response.json()
        else:
            # 使用urllib.request
            import json
            data = json.dumps(payload).encode('utf-8')
            req = urllib.request.Request(url, data=data, headers=headers)
            
            try:
                with urllib.request.urlopen(req, timeout=10) as response:
                    # 获取响应状态码
                    if response.status != 200:
                        return f"网络请求失败，状态码: {response.status}"
                    
                    # 读取并解析响应内容
                    response_data = response.read().decode('utf-8')
                    result = json.loads(response_data)
            except urllib.error.URLError as e:
                return f"网络请求失败: {str(e)}"
            except urllib.error.HTTPError as e:
                return f"网络请求失败，HTTP错误: {str(e.code)} - {str(e.reason)}"
        
        # 处理响应结果
        if "output" in result and "text" in result["output"]:
            translated_text = result["output"]["text"].strip()
            return translated_text
        else:
            return f"响应格式错误: {json.dumps(result, ensure_ascii=False)}"
            
    except Exception as e:
        return f"翻译失败: {str(e)}"

if __name__ == '__main__':
    # 检查是否是设置API密钥的请求
    if len(sys.argv) == 3 and sys.argv[1] == "--set-api-key":
        api_key = sys.argv[2]
        if save_api_key(api_key):
            print(json.dumps({
                'success': True,
                'message': 'API密钥已保存'
            }, ensure_ascii=False))
        else:
            print(json.dumps({
                'success': False,
                'error': '保存API密钥失败'
            }, ensure_ascii=False))
        sys.exit(0)
    
    # 正常翻译请求
    if len(sys.argv) < 2:
        print(json.dumps({
            'success': False,
            'text': '',
            'error': 'No text provided'
        }, ensure_ascii=False))
        sys.exit(1)
    
    # 解码URL编码的文本
    import urllib.parse
    text = urllib.parse.unquote(sys.argv[1])
    source_lang = sys.argv[2] if len(sys.argv) > 2 else 'auto'
    target_lang = sys.argv[3] if len(sys.argv) > 3 else 'zh-CN'
    
    result = translate_text(text, source_lang, target_lang)
    print(json.dumps(result, ensure_ascii=False))