#!/usr/bin/env python3
"""
探索 tw-function-call-reasoning-10k 資料集
用於學習 Function Calling 的繁體中文範例

使用方法:
    source .venv/bin/activate
    python scripts/explore_function_calling_dataset.py
"""

from datasets import load_dataset
import json
import random

def load_data():
    """載入資料集"""
    print("🔄 載入資料集中...")
    ds = load_dataset('twinkle-ai/tw-function-call-reasoning-10k', split='train')
    print(f"✅ 載入完成！共 {len(ds)} 筆資料")
    return ds

def show_dataset_info(ds):
    """顯示資料集基本資訊"""
    print("\n" + "=" * 70)
    print("📊 資料集資訊")
    print("=" * 70)
    print(f"資料筆數: {len(ds)}")
    print(f"欄位: {ds.column_names}")
    print()
    print("欄位說明:")
    print("  - id: 樣本唯一編號")
    print("  - query: 英文原始指令")
    print("  - query_zhtw: 繁體中文翻譯指令")
    print("  - tools: 可用工具清單 (JSON)")
    print("  - think: 繁體中文推理過程 (Chain-of-Thought)")
    print("  - answer: 預期執行的工具與參數 (JSON)")
    print("  - messages: Hermes 格式對話歷程 (SFT 微調用)")

def show_example(ds, idx):
    """顯示單一範例的詳細內容"""
    example = ds[idx]
    
    print("\n" + "=" * 70)
    print(f"📝 範例 #{idx}")
    print("=" * 70)
    
    print(f"\n🔹 ID: {example['id']}")
    
    print(f"\n🔹 英文指令:")
    print(f"   {example['query']}")
    
    print(f"\n🔹 繁體中文指令:")
    print(f"   {example['query_zhtw']}")
    
    # 解析並顯示工具
    tools = json.loads(example['tools']) if isinstance(example['tools'], str) else example['tools']
    print(f"\n🛠️ 可用工具 ({len(tools)} 個):")
    for i, tool in enumerate(tools[:3]):  # 只顯示前3個
        print(f"   {i+1}. {tool['name']}: {tool['description'][:80]}...")
    if len(tools) > 3:
        print(f"   ... 還有 {len(tools) - 3} 個工具")
    
    print(f"\n💭 思考過程 (Chain-of-Thought):")
    think = example['think']
    # 分段顯示
    for line in think.split('\n')[:10]:
        if line.strip():
            print(f"   {line[:100]}{'...' if len(line) > 100 else ''}")
    if len(think.split('\n')) > 10:
        print("   ...")
    
    print(f"\n✅ 預期答案:")
    answer = json.loads(example['answer']) if isinstance(example['answer'], str) else example['answer']
    print(f"   {json.dumps(answer, ensure_ascii=False, indent=2)}")

def show_messages_format(ds, idx):
    """顯示 Hermes 格式的 messages 結構"""
    example = ds[idx]
    
    print("\n" + "=" * 70)
    print(f"💬 Hermes 格式 Messages (範例 #{idx})")
    print("=" * 70)
    
    messages = json.loads(example['messages']) if isinstance(example['messages'], str) else example['messages']
    
    for msg in messages:
        role = msg.get('role', 'unknown')
        content = msg.get('content', '')
        
        if role == 'system':
            print(f"\n🔧 [SYSTEM]")
            print(f"   {content[:200]}...")
        elif role == 'user':
            print(f"\n👤 [USER]")
            print(f"   {content}")
        elif role == 'assistant':
            print(f"\n🤖 [ASSISTANT]")
            # 可能包含 <think> 和 tool_calls
            if '<think>' in content:
                think_start = content.find('<think>') + 7
                think_end = content.find('</think>')
                think_content = content[think_start:think_end]
                print(f"   <think>{think_content[:150]}...</think>")
            if 'tool_calls' in msg:
                print(f"   tool_calls: {json.dumps(msg['tool_calls'], ensure_ascii=False)[:200]}...")

def search_by_keyword(ds, keyword, limit=5):
    """根據關鍵字搜尋範例"""
    print("\n" + "=" * 70)
    print(f"🔍 搜尋關鍵字: '{keyword}'")
    print("=" * 70)
    
    found = []
    for i, example in enumerate(ds):
        if keyword in example['query_zhtw']:
            found.append(i)
            if len(found) >= limit:
                break
    
    print(f"找到 {len(found)} 個相關範例")
    for idx in found:
        example = ds[idx]
        print(f"\n  #{idx}: {example['query_zhtw'][:80]}...")
    
    return found

def export_sample(ds, indices, output_file):
    """匯出指定範例到 JSON 檔案"""
    samples = []
    for idx in indices:
        example = ds[idx]
        samples.append({
            'id': example['id'],
            'query_zhtw': example['query_zhtw'],
            'tools': json.loads(example['tools']) if isinstance(example['tools'], str) else example['tools'],
            'think': example['think'],
            'answer': json.loads(example['answer']) if isinstance(example['answer'], str) else example['answer']
        })
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(samples, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 已匯出 {len(samples)} 個範例到 {output_file}")

def main():
    ds = load_data()
    
    # 顯示資料集資訊
    show_dataset_info(ds)
    
    # 隨機顯示一個範例
    random_idx = random.randint(0, len(ds) - 1)
    show_example(ds, random_idx)
    
    # 顯示 messages 格式
    show_messages_format(ds, random_idx)
    
    # 搜尋特定關鍵字
    print("\n" + "=" * 70)
    print("🎯 常見操作類型範例")
    print("=" * 70)
    
    keywords = ['搜尋', '計算', '獲取', '轉換', '查詢']
    for kw in keywords:
        indices = search_by_keyword(ds, kw, limit=2)
    
    # 匯出範例
    sample_indices = random.sample(range(len(ds)), 10)
    export_sample(ds, sample_indices, 'scripts/sample_function_calls.json')
    
    print("\n" + "=" * 70)
    print("🎉 探索完成！")
    print("=" * 70)
    print("\n提示：")
    print("  - 使用 show_example(ds, idx) 查看特定範例")
    print("  - 使用 search_by_keyword(ds, '關鍵字') 搜尋範例")
    print("  - 使用 export_sample(ds, [idx1, idx2], 'output.json') 匯出範例")

if __name__ == "__main__":
    main()
