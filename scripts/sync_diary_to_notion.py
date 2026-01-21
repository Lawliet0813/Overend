import os
import json
import re
from urllib import request, error
from datetime import datetime

API_KEY = os.environ.get("NOTION_API_KEY", "")
PAGE_ID = os.environ.get("NOTION_PAGE_ID", "")
DIARY_PATH = "/Users/lawliet/OVEREND/DOCS/development/DEVELOPMENT_DIARY.md"

def extract_today_entry(path):
    today_str = datetime.now().strftime("%Y-%m-%d")
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    pattern = rf"### {today_str}.*?\n(?=\n### |## |\Z)"
    match = re.search(pattern, content, re.DOTALL)
    if match:
        return match.group(0).strip()
    return None

def md_to_blocks(md):
    blocks = []
    lines = md.split('\n')
    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        if line.startswith('### '):
            blocks.append({
                "object": "block",
                "type": "heading_3",
                "heading_3": {"rich_text": [{"type": "text", "text": {"content": line[4:]}}]}
            })
        elif line.startswith('**') and line.endswith('**'):
             blocks.append({
                "object": "block",
                "type": "paragraph",
                "paragraph": {"rich_text": [{"type": "text", "text": {"content": line[2:-2]}, "annotations": {"bold": True}}]}
            })
        elif line.startswith('1. '):
            blocks.append({
                "object": "block",
                "type": "numbered_list_item",
                "numbered_list_item": {"rich_text": [{"type": "text", "text": {"content": line[3:]}}]}
            })
        elif line.startswith('- '):
            blocks.append({
                "object": "block",
                "type": "bulleted_list_item",
                "bulleted_list_item": {"rich_text": [{"type": "text", "text": {"content": line[2:]}}]}
            })
        else:
            blocks.append({
                "object": "block",
                "type": "paragraph",
                "paragraph": {"rich_text": [{"type": "text", "text": {"content": line}}]}
            })
    return blocks

def sync_to_notion(blocks):
    url = f"https://api.notion.com/v1/blocks/{PAGE_ID}/children"
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "Notion-Version": "2022-06-28"
    }
    data = json.dumps({"children": blocks}).encode('utf-8')
    req = request.Request(url, data=data, headers=headers, method='PATCH')
    try:
        with request.urlopen(req) as response:
            return response.getcode(), response.read().decode('utf-8')
    except error.HTTPError as e:
        return e.code, e.read().decode('utf-8')

if __name__ == "__main__":
    entry = extract_today_entry(DIARY_PATH)
    if entry:
        print(f"Extracted entry snippet:\n{entry[:200]}...")
        blocks = md_to_blocks(entry)
        code, text = sync_to_notion(blocks)
        if code == 200:
            print("Successfully synced to Notion!")
        else:
            print(f"Failed to sync: {code}")
            print(text)
    else:
        print("No entry found for today.")
