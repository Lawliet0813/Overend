#!/usr/bin/env python3
"""
用 tw-function-call-reasoning-10k 資料集測試與改進 OVEREND AI 功能

功能：
1. 提取高品質 Few-shot 範例用於改進 Prompt
2. 生成適合 OVEREND 使用的繁中 Tool Calling 範例
3. 分析資料集中的思考過程模式

使用方法:
    source .venv/bin/activate
    python scripts/enhance_ai_with_dataset.py
"""

from datasets import load_dataset
import json
import os
from pathlib import Path
from typing import List, Dict, Any

# 載入資料集
print("🔄 載入 tw-function-call-reasoning-10k 資料集...")
ds = load_dataset('twinkle-ai/tw-function-call-reasoning-10k', split='train')
print(f"✅ 載入完成！共 {len(ds)} 筆資料")


# ========================================
# 1. 提取 Few-shot 範例
# ========================================

def extract_fewshot_examples(keywords: List[str], limit: int = 5) -> List[Dict]:
    """根據關鍵字提取適合作為 Few-shot 範例的資料"""
    examples = []
    for example in ds:
        query = example['query_zhtw']
        if any(kw in query for kw in keywords):
            examples.append({
                'query': example['query_zhtw'],
                'think': example['think'],
                'answer': json.loads(example['answer']) if isinstance(example['answer'], str) else example['answer'],
                'tools': json.loads(example['tools']) if isinstance(example['tools'], str) else example['tools']
            })
            if len(examples) >= limit:
                break
    return examples


def generate_fewshot_prompt(examples: List[Dict]) -> str:
    """生成 Few-shot Prompt 模板"""
    prompt_parts = []
    
    for i, ex in enumerate(examples, 1):
        tool_names = [t['name'] for t in ex['tools'][:3]]
        prompt_parts.append(f"""
### 範例 {i}
使用者指令: {ex['query'][:100]}...
可用工具: {', '.join(tool_names)}
思考過程: {ex['think'][:200]}...
答案: {json.dumps(ex['answer'], ensure_ascii=False)[:200]}...
""")
    
    return "\n".join(prompt_parts)


# ========================================
# 2. 分析 Chain-of-Thought 模式
# ========================================

def analyze_cot_patterns(sample_size: int = 100) -> Dict[str, int]:
    """分析 Chain-of-Thought 推理中的常見模式"""
    patterns = {
        '檢視可用的功能': 0,
        '參數分析': 0,
        '步驟分解': 0,
        '驗證邏輯': 0,
        '首先/然後/最後': 0,
    }
    
    for example in ds.select(range(sample_size)):
        think = example['think']
        if '檢視' in think or '查看' in think:
            patterns['檢視可用的功能'] += 1
        if '參數' in think:
            patterns['參數分析'] += 1
        if '第一' in think or '步驟' in think:
            patterns['步驟分解'] += 1
        if '確認' in think or '驗證' in think:
            patterns['驗證邏輯'] += 1
        if '首先' in think or '然後' in think or '最後' in think:
            patterns['首先/然後/最後'] += 1
    
    return patterns


# ========================================
# 3. 生成 OVEREND 專用範例
# ========================================

def generate_overend_examples():
    """生成適合 OVEREND 學術寫作工具的範例格式"""
    
    # 模擬 OVEREND 工具定義
    overend_tools = [
        {
            "name": "analyzeWriting",
            "description": "分析學術寫作內容，檢查語法、風格和邏輯問題",
            "parameters": {
                "text": {"description": "要分析的文本", "type": "str"},
                "academicMode": {"description": "是否使用學術模式", "type": "bool", "default": True}
            }
        },
        {
            "name": "rewriteText",
            "description": "改寫文本，可選擇不同風格：formal、academic、concise、elaborate",
            "parameters": {
                "text": {"description": "原始文本", "type": "str"},
                "style": {"description": "改寫風格", "type": "str", "default": "academic"}
            }
        },
        {
            "name": "translateAcademic",
            "description": "進行學術翻譯，保留專業術語",
            "parameters": {
                "text": {"description": "要翻譯的文本", "type": "str"},
                "sourceLang": {"description": "來源語言", "type": "str"},
                "targetLang": {"description": "目標語言", "type": "str"}
            }
        },
        {
            "name": "extractPDFMetadata",
            "description": "從 PDF 中提取書目資訊",
            "parameters": {
                "title": {"description": "文獻標題", "type": "str"},
                "authors": {"description": "作者列表", "type": "list"},
                "year": {"description": "出版年份", "type": "int"},
                "journal": {"description": "期刊名稱", "type": "str"},
                "doi": {"description": "DOI 識別碼", "type": "str"}
            }
        },
        {
            "name": "generateCitation",
            "description": "生成引用格式",
            "parameters": {
                "metadata": {"description": "書目資訊", "type": "object"},
                "style": {"description": "引用格式：APA、MLA、Chicago", "type": "str"}
            }
        }
    ]
    
    # 生成範例查詢和預期回應
    overend_examples = [
        {
            "query_zhtw": "請分析這段學術寫作，檢查是否有語法或風格問題：「我認為這個研究很棒，結果證明我們的假設是對的。」",
            "tools": overend_tools[:2],
            "think": """
好的，使用者想要分析一段學術寫作的語法和風格問題。

首先，我需要確認可用的工具。我看到有 "analyzeWriting" 這個工具，它可以分析學術寫作內容，檢查語法、風格和邏輯問題。

檢視參數：
- text: 需要提供要分析的文本，就是使用者給的那段話
- academicMode: 因為這是學術寫作，應該設為 true

使用者明確說這是「學術寫作」，所以我應該啟用學術模式。這個工具會檢查：
1. 語法問題（如標點符號）
2. 風格問題（如「我認為」這種第一人稱用法在學術寫作中不太適合）
3. 邏輯問題

因此，我將呼叫 analyzeWriting 工具，設定 academicMode 為 true。
""",
            "answer": [
                {
                    "name": "analyzeWriting",
                    "arguments": {
                        "text": "我認為這個研究很棒，結果證明我們的假設是對的。",
                        "academicMode": True
                    }
                }
            ]
        },
        {
            "query_zhtw": "我需要將這段中文摘要翻譯成英文，並且保持學術風格：「本研究探討人工智慧在教育領域的應用，透過量化分析驗證其效果。」",
            "tools": overend_tools[2:3],
            "think": """
使用者需要進行學術翻譯，將中文翻譯成英文。

檢視可用的工具，有 "translateAcademic" 這個功能專門用於學術翻譯，可以保留專業術語。

參數設定：
- text: 需要翻譯的中文摘要
- sourceLang: 來源語言是中文，應該用 "zh-TW" 或 "Chinese"
- targetLang: 目標語言是英文，應該用 "en" 或 "English"

這個工具很適合這個任務，因為它會保持學術風格並正確處理術語如「量化分析」、「人工智慧」等。
""",
            "answer": [
                {
                    "name": "translateAcademic",
                    "arguments": {
                        "text": "本研究探討人工智慧在教育領域的應用，透過量化分析驗證其效果。",
                        "sourceLang": "zh-TW",
                        "targetLang": "en"
                    }
                }
            ]
        },
        {
            "query_zhtw": "請將這段文字改寫得更正式：「這篇論文寫得不錯，但有些地方可以更好。」",
            "tools": overend_tools[1:2],
            "think": """
使用者想要將一段比較口語化的評論改寫成更正式的版本。

查看可用工具，"rewriteText" 可以改寫文本，並支持不同風格。

參數分析：
- text: 原始文本就是使用者給的那句話
- style: 使用者說要「更正式」，所以應該選擇 "formal" 或 "academic"

由於使用者明確要求「正式」，我選擇 style = "formal"。這會將口語化的表達（如「不錯」、「可以更好」）轉換為正式的書面語。
""",
            "answer": [
                {
                    "name": "rewriteText",
                    "arguments": {
                        "text": "這篇論文寫得不錯，但有些地方可以更好。",
                        "style": "formal"
                    }
                }
            ]
        }
    ]
    
    return overend_examples


# ========================================
# 4. 生成改進建議報告
# ========================================

def generate_improvement_report():
    """生成 OVEREND AI 改進建議報告"""
    
    report = """# OVEREND AI Tool Calling 改進建議

## 基於 tw-function-call-reasoning-10k 資料集分析

### 1. Chain-of-Thought 推理模式分析

從資料集中觀察到的高效推理模式：

1. **工具識別階段**
   - 首先列出所有可用工具
   - 分析每個工具的用途和參數

2. **參數對應階段**
   - 逐一將使用者需求對應到工具參數
   - 處理預設值和可選參數

3. **驗證階段**
   - 確認參數類型正確
   - 檢查必要參數是否完整

### 2. 推薦的 Prompt 結構

```
你是一個 [功能描述] 專家。

可用工具：
[工具列表及描述]

推理步驟：
1. 首先，識別使用者的具體需求
2. 然後，選擇最適合的工具
3. 接著，對應參數值
4. 最後，驗證並輸出結果

⚠️ 注意事項：
- 不要使用佔位符
- 參數值必須來自使用者輸入
- 如果找不到資訊，使用 null 或空值
```

### 3. Few-shot 範例格式

每個範例應包含：
- 使用者指令（繁體中文）
- 完整的思考過程
- 結構化的工具呼叫結果

### 4. 建議的改進項目

| 優先級 | 項目 | 說明 |
|-------|------|------|
| P0 | 加入 CoT 推理 | 在 Tool Calling 前加入明確的思考步驟 |
| P1 | Few-shot 範例 | 在 System Prompt 中加入 2-3 個範例 |
| P2 | 參數驗證 | 加入參數類型和範圍檢查 |
| P3 | 錯誤處理 | 當必要資訊缺失時的降級策略 |

### 5. 現有 OVEREND Tools 與資料集對應

| OVEREND Tool | 對應資料集範例類型 | 建議改進 |
|--------------|------------------|---------|
| extractPDFMetadata | 資訊提取類 | 加入文件類型判斷的 CoT |
| analyzeWriting | 文本分析類 | 加入問題優先級排序邏輯 |
| rewriteText | 文本轉換類 | 加入風格特徵描述 |
| translateAcademic | 翻譯類 | 加入術語保留驗證 |
| generateCitation | 格式生成類 | 加入引用格式驗證 |

## 下一步行動

1. [ ] 更新 ExtractPDFMetadataTool 的 Instructions，加入 CoT 模式
2. [ ] 在 WritingAIDomain 中加入 Few-shot 範例
3. [ ] 建立驗證測試案例
"""
    
    return report


# ========================================
# 主程式
# ========================================

def main():
    output_dir = Path("scripts/ai_enhancement")
    output_dir.mkdir(exist_ok=True)
    
    print("\n" + "=" * 70)
    print("📊 1. 分析 Chain-of-Thought 推理模式")
    print("=" * 70)
    
    patterns = analyze_cot_patterns(200)
    print("\n常見推理模式統計（200 個樣本）：")
    for pattern, count in sorted(patterns.items(), key=lambda x: -x[1]):
        print(f"  - {pattern}: {count} 次 ({count/2:.1f}%)")
    
    print("\n" + "=" * 70)
    print("📝 2. 提取 Few-shot 範例")
    print("=" * 70)
    
    # 提取不同類型的範例
    search_examples = extract_fewshot_examples(['搜尋', '查詢', '找'], 3)
    convert_examples = extract_fewshot_examples(['轉換', '改寫', '翻譯'], 3)
    analyze_examples = extract_fewshot_examples(['分析', '計算', '檢查'], 3)
    
    print(f"\n找到範例：")
    print(f"  - 搜尋/查詢類: {len(search_examples)} 個")
    print(f"  - 轉換/改寫類: {len(convert_examples)} 個")
    print(f"  - 分析/計算類: {len(analyze_examples)} 個")
    
    # 儲存範例
    all_examples = {
        'search': search_examples,
        'convert': convert_examples,
        'analyze': analyze_examples
    }
    
    with open(output_dir / 'fewshot_examples.json', 'w', encoding='utf-8') as f:
        json.dump(all_examples, f, ensure_ascii=False, indent=2)
    print(f"\n✅ 已儲存到 {output_dir / 'fewshot_examples.json'}")
    
    print("\n" + "=" * 70)
    print("🛠️ 3. 生成 OVEREND 專用範例")
    print("=" * 70)
    
    overend_examples = generate_overend_examples()
    
    with open(output_dir / 'overend_fewshot_examples.json', 'w', encoding='utf-8') as f:
        json.dump(overend_examples, f, ensure_ascii=False, indent=2)
    print(f"\n✅ 已儲存 {len(overend_examples)} 個 OVEREND 專用範例到 {output_dir / 'overend_fewshot_examples.json'}")
    
    # 顯示一個範例
    print("\n📌 範例預覽:")
    ex = overend_examples[0]
    print(f"指令: {ex['query_zhtw']}")
    print(f"思考過程: {ex['think'][:200]}...")
    print(f"答案: {json.dumps(ex['answer'], ensure_ascii=False)}")
    
    print("\n" + "=" * 70)
    print("📋 4. 生成改進建議報告")
    print("=" * 70)
    
    report = generate_improvement_report()
    
    with open(output_dir / 'improvement_report.md', 'w', encoding='utf-8') as f:
        f.write(report)
    print(f"\n✅ 已儲存改進建議報告到 {output_dir / 'improvement_report.md'}")
    
    print("\n" + "=" * 70)
    print("🎉 完成！")
    print("=" * 70)
    print(f"""
生成的檔案：
  📁 {output_dir}/
     ├── fewshot_examples.json      - 從資料集提取的範例
     ├── overend_fewshot_examples.json - OVEREND 專用範例
     └── improvement_report.md      - AI 改進建議報告

下一步：
  1. 查看 improvement_report.md 了解改進建議
  2. 將 overend_fewshot_examples.json 中的範例整合到 Prompt
  3. 測試改進後的 Tool Calling 效果
""")


if __name__ == "__main__":
    main()
