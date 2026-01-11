 #!/usr/bin/env python3
"""
測試改進後的 OVEREND AI Tool Calling

這個腳本模擬 Apple Intelligence 的 Tool Calling 流程，
使用改進後的 CoT 推理和 Few-shot 範例來測試效果。

使用方法:
    source .venv/bin/activate
    python scripts/test_improved_ai.py
"""

import json
import os
from pathlib import Path

# 模擬改進後的 Prompt
IMPROVED_PDF_EXTRACTION_PROMPT = """
你是學術文獻書目識別專家。你的任務是從 PDF 文字內容中識別並提取真實的書目資訊。

📋 推理步驟（Chain-of-Thought）：

1. 首先，仔細閱讀 PDF 內容，識別文獻的結構。
   - 找出標題區域（通常在文件開頭，字體較大或加粗）
   - 找出作者區域（通常在標題下方）
   - 找出出版資訊區域（可能包含年份、期刊名稱、DOI）

2. 然後，逐一提取各個欄位：
   - 標題：找到實際的完整標題文字
   - 作者：列出所有作者的真實姓名
   - 年份：找到四位數的出版年份
   - 期刊/會議：找到發表來源名稱
   - DOI：找到以 10. 開頭的識別碼

3. 接著，驗證提取的資訊：
   - 確認標題不是佔位符（如「論文標題」「Paper Title」）
   - 確認作者不是假名（如「作者1」「張三」「John Doe」）
   - 確認年份是合理的（通常在 1900-2026 之間）

4. 最後，判斷文獻類型並調用工具：
   - article: 期刊文章（有期刊名稱、卷期頁碼）
   - inproceedings: 會議論文（有會議名稱）
   - thesis: 學位論文（有學校名稱、學位類型）
   - book: 書籍（有出版社、ISBN）
   - misc: 無法確定類型

📝 範例（Few-shot）：

範例 1 - 期刊文章提取：
輸入：「Deep Learning for Natural Language Processing: A Survey
       Authors: John Smith, Mary Johnson
       Published in: Journal of AI Research, 2023
       DOI: 10.1016/j.jair.2023.01.001」
思考：這是一篇期刊文章，標題是「Deep Learning for Natural Language Processing: A Survey」，
      作者有兩位 John Smith 和 Mary Johnson，發表於 2023 年的 Journal of AI Research。
結果：title="Deep Learning for Natural Language Processing: A Survey",
      authors=["John Smith", "Mary Johnson"], year="2023",
      journal="Journal of AI Research", doi="10.1016/j.jair.2023.01.001",
      documentType=article

範例 2 - 資訊缺失處理：
輸入：「研究方法論探討
       （文件內容模糊，無法辨識作者和出版資訊）」
思考：只能識別到標題，其他資訊無法確定，應該填入空值而非猜測。
結果：title="研究方法論探討", authors=[], year=null,
      journal=null, doi=null, documentType=misc
"""

IMPROVED_WRITING_ANALYSIS_PROMPT = """
你是專業的寫作分析專家。

📋 推理步驟（Chain-of-Thought）：

1. 首先，通讀整段文字，理解整體內容和語境。

2. 然後，檢查語法問題：
   - 標點符號使用是否正確
   - 句子結構是否完整
   - 主謂賓是否搭配

3. 接著，檢查風格問題：
   - 是否有口語化表達
   - 是否有不當的人稱使用
   - 用詞是否恰當

4. 最後，檢查邏輯問題：
   - 論述是否連貫
   - 因果關係是否清晰
   - 是否有矛盾之處

📝 範例（Few-shot）：

範例 1 - 學術寫作分析：
輸入：「我認為這個研究很棒，結果證明我們的假設是對的。」
思考：這段文字有幾個學術寫作問題：
      1. 使用第一人稱「我」「我們」
      2. 口語化表達「很棒」
      3. 過於主觀的判斷
結果：
- styleIssues: [
    {original: "我認為", suggestion: "本研究認為", explanation: "學術寫作應避免第一人稱", severity: "high"},
    {original: "很棒", suggestion: "具有重要意義", explanation: "應使用客觀學術用語", severity: "medium"},
    {original: "我們的", suggestion: "本研究的", explanation: "使用第三人稱表述", severity: "high"}
  ]
- overallFeedback: "文字整體流暢，但需調整為學術寫作風格"
"""


# ========================================
# 測試用例
# ========================================

PDF_TEST_CASES = [
    {
        "name": "期刊文章 - 清晰資訊",
        "input": """
Attention Is All You Need

Ashish Vaswani, Noam Shazeer, Niki Parmar, Jakob Uszkoreit,
Llion Jones, Aidan N. Gomez, Lukasz Kaiser, Illia Polosukhin

Abstract: The dominant sequence transduction models are based on complex recurrent or
convolutional neural networks...

Published in: Advances in Neural Information Processing Systems 30 (NIPS 2017)
arXiv:1706.03762
        """,
        "expected": {
            "title": "Attention Is All You Need",
            "authors": ["Ashish Vaswani", "Noam Shazeer", "Niki Parmar", "Jakob Uszkoreit", "Llion Jones", "Aidan N. Gomez", "Lukasz Kaiser", "Illia Polosukhin"],
            "year": "2017",
            "documentType": "inproceedings"
        }
    },
    {
        "name": "中文論文",
        "input": """
人工智慧在教育領域的應用與挑戰

作者：陳明志、林雅婷、王建國

摘要：本研究探討人工智慧技術在教育場域中的實際應用...

發表於：《教育科技期刊》2024年第15卷第3期
DOI: 10.6178/JETS.202403.15(3).001
        """,
        "expected": {
            "title": "人工智慧在教育領域的應用與挑戰",
            "authors": ["陳明志", "林雅婷", "王建國"],
            "year": "2024",
            "journal": "教育科技期刊",
            "doi": "10.6178/JETS.202403.15(3).001",
            "documentType": "article"
        }
    },
    {
        "name": "資訊缺失情況",
        "input": """
[掃描文件 - 影像模糊]

...研究方法論的重要性...
...無法辨識其他內容...
        """,
        "expected": {
            "title": "",  # 無法識別，應返回空
            "authors": [],
            "year": None,
            "documentType": "misc"
        }
    }
]

WRITING_TEST_CASES = [
    {
        "name": "學術寫作 - 多處問題",
        "input": "我認為這個研究很棒，結果證明我們的假設是對的。大家都知道這個方法是最好的。",
        "expected_issues": {
            "styleIssues": [
                {"original": "我認為", "suggestion": "本研究認為"},
                {"original": "很棒", "suggestion": "具有重要意義"},
                {"original": "我們的", "suggestion": "本研究的"},
                {"original": "大家都知道", "suggestion": "普遍認為"},
                {"original": "最好的", "suggestion": "較為有效的"}
            ]
        }
    },
    {
        "name": "學術寫作 - 無問題",
        "input": "本研究透過實證分析驗證了假設，結果顯示變數間存在顯著相關。",
        "expected_issues": {
            "styleIssues": [],
            "grammarIssues": [],
            "logicIssues": []
        }
    },
    {
        "name": "語法問題",
        "input": "這個研究很重要。。因為它可以幫助我們理解，，問題的本質。",
        "expected_issues": {
            "grammarIssues": [
                {"original": "。。", "suggestion": "。"},
                {"original": "，，", "suggestion": "，"}
            ]
        }
    }
]


def simulate_cot_reasoning(prompt: str, input_text: str) -> dict:
    """模擬 Chain-of-Thought 推理過程"""
    print(f"\n{'='*60}")
    print("🤖 模擬 AI 推理過程")
    print(f"{'='*60}")
    
    # 顯示推理步驟
    steps = [
        "1️⃣ 首先，閱讀並理解輸入內容...",
        "2️⃣ 然後，識別關鍵資訊區域...",
        "3️⃣ 接著，提取並驗證各欄位...",
        "4️⃣ 最後，判斷類型並生成結果..."
    ]
    
    for step in steps:
        print(f"   {step}")
    
    print(f"\n📝 輸入內容預覽:")
    print(f"   {input_text[:100]}...")
    
    return {"status": "simulated"}


def test_pdf_extraction():
    """測試 PDF 元數據提取"""
    print("\n" + "="*70)
    print("📄 測試 PDF 元數據提取 (改進版)")
    print("="*70)
    
    results = []
    
    for i, case in enumerate(PDF_TEST_CASES):
        print(f"\n--- 測試案例 {i+1}: {case['name']} ---")
        
        # 模擬推理過程
        simulate_cot_reasoning(IMPROVED_PDF_EXTRACTION_PROMPT, case['input'])
        
        # 顯示預期結果
        print(f"\n✅ 預期提取結果:")
        for key, value in case['expected'].items():
            print(f"   - {key}: {value}")
        
        results.append({
            "name": case['name'],
            "status": "待實機測試",
            "expected": case['expected']
        })
    
    return results


def test_writing_analysis():
    """測試寫作分析"""
    print("\n" + "="*70)
    print("✍️ 測試寫作分析 (改進版)")
    print("="*70)
    
    results = []
    
    for i, case in enumerate(WRITING_TEST_CASES):
        print(f"\n--- 測試案例 {i+1}: {case['name']} ---")
        print(f"📝 輸入: {case['input']}")
        
        # 模擬推理過程
        print("\n🤖 模擬 AI 推理過程:")
        print("   1️⃣ 通讀整段文字，理解語境...")
        print("   2️⃣ 檢查語法問題...")
        print("   3️⃣ 檢查風格問題...")
        print("   4️⃣ 檢查邏輯問題...")
        
        # 顯示預期結果
        print(f"\n✅ 預期檢測到的問題:")
        for issue_type, issues in case['expected_issues'].items():
            if issues:
                print(f"   {issue_type}: {len(issues)} 個問題")
                for issue in issues[:3]:  # 只顯示前3個
                    print(f"      - \"{issue['original']}\" → \"{issue['suggestion']}\"")
            else:
                print(f"   {issue_type}: 無問題 ✓")
        
        results.append({
            "name": case['name'],
            "status": "待實機測試",
            "expected_issues": case['expected_issues']
        })
    
    return results


def generate_test_report(pdf_results, writing_results):
    """生成測試報告"""
    report = {
        "test_date": "2026-01-11",
        "improvements_applied": [
            "Chain-of-Thought 推理步驟",
            "Few-shot 範例",
            "佔位符過濾邏輯"
        ],
        "pdf_extraction_tests": pdf_results,
        "writing_analysis_tests": writing_results,
        "notes": "這些測試案例需要在實際 macOS 26.0 環境中用 Apple Intelligence 驗證"
    }
    
    output_dir = Path("scripts/ai_enhancement")
    output_dir.mkdir(exist_ok=True)
    
    with open(output_dir / "test_report.json", 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 測試報告已儲存到 {output_dir / 'test_report.json'}")
    
    return report


def main():
    print("="*70)
    print("🧪 OVEREND AI Tool Calling 改進測試")
    print("="*70)
    print("\n這個腳本模擬改進後的 AI 推理流程，")
    print("驗證 CoT 推理步驟和 Few-shot 範例的設計。\n")
    
    # 測試 PDF 提取
    pdf_results = test_pdf_extraction()
    
    # 測試寫作分析
    writing_results = test_writing_analysis()
    
    # 生成報告
    generate_test_report(pdf_results, writing_results)
    
    # 總結
    print("\n" + "="*70)
    print("📊 測試總結")
    print("="*70)
    print(f"""
改進內容：
  ✅ ExtractPDFMetadataTool: 加入 CoT + Few-shot
  ✅ AnalyzeWritingTool: 加入 CoT + Few-shot
  ✅ 編譯驗證通過

測試案例：
  📄 PDF 提取: {len(pdf_results)} 個案例
  ✍️ 寫作分析: {len(writing_results)} 個案例

下一步：
  1. 在 OVEREND 應用中實際測試這些案例
  2. 觀察 Tool Calling 的準確度變化
  3. 根據結果進一步調整 Prompt

提示：可以在 Xcode 執行應用，匯入 PDF 文件來測試改進效果。
""")


if __name__ == "__main__":
    main()
