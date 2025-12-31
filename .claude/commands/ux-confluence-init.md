---
description: 프로젝트 분석 문서를 Confluence에 자동 업로드합니다.
allowed-tools: Bash, Read, Write
argument-hint: [project-name]
---

# /ux confluence-init - Confluence 프로젝트 문서 초기화

현재 프로젝트의 `.ux-docs/` 문서를 Confluence의 "CD Group > 200 Projects > [프로젝트명]" 하위에 페이지로 생성합니다.

## 사용법

```bash
# 자동으로 프로젝트명 감지
/ux confluence-init

# 프로젝트명 직접 지정
/ux confluence-init IDCX
```

---

## 실행 절차

### Step 1: 환경 변수 확인

```bash
# Confluence API 접근을 위한 환경 변수 확인
JIRA_HOST='https://wondermove-official.atlassian.net'
JIRA_EMAIL='vision@wondermove.net'
JIRA_API_TOKEN='...'
```

### Step 2: 프로젝트 정보 수집

```python
import os
import json

# 프로젝트명 자동 감지
project_name = os.path.basename(os.getcwd()).upper()

# .ux-docs/ 문서 읽기
docs_dir = '.ux-docs'
documents = {}

if os.path.exists(f'{docs_dir}/PROJECT_CONTEXT.md'):
    with open(f'{docs_dir}/PROJECT_CONTEXT.md', 'r') as f:
        documents['context'] = f.read()

if os.path.exists(f'{docs_dir}/FUNCTIONAL_REQUIREMENTS.md'):
    with open(f'{docs_dir}/FUNCTIONAL_REQUIREMENTS.md', 'r') as f:
        documents['requirements'] = f.read()

if os.path.exists(f'{docs_dir}/USER_FLOWS.md'):
    with open(f'{docs_dir}/USER_FLOWS.md', 'r') as f:
        documents['flows'] = f.read()
```

### Step 3: Confluence 폴더 찾기

```python
import requests

# "200 Projects" 폴더 ID: 431390804
# 프로젝트 폴더 검색
project_folder_search = f"space=CG1 and title~'{project_name}'"
url = f"{jira_host}/wiki/rest/api/content/search?cql={project_folder_search}"

response = requests.get(url, auth=(email, token))
result = response.json()

if result['size'] == 0:
    print(f"❌ Confluence에서 '{project_name}' 폴더를 찾을 수 없습니다.")
    print(f"Confluence에서 먼저 폴더를 생성하세요: CD Group > 200 Projects > 20X {project_name}")
    exit(1)

parent_page_id = result['results'][0]['id']
```

### Step 4: Markdown → Confluence HTML 변환

```python
import re

def markdown_to_confluence_html(md_text):
    """
    Markdown을 Confluence Storage Format(HTML)으로 변환
    """
    html = md_text

    # 1. 헤더 변환
    html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^#### (.+)$', r'<h4>\1</h4>', html, flags=re.MULTILINE)

    # 2. 코드 블록
    def replace_code_block(match):
        lang = match.group(1) or 'text'
        code = match.group(2)
        return f'''<ac:structured-macro ac:name="code">
<ac:parameter ac:name="language">{lang}</ac:parameter>
<ac:plain-text-body><![CDATA[{code}]]></ac:plain-text-body>
</ac:structured-macro>'''

    html = re.sub(r'```(\w+)?\n(.*?)```', replace_code_block, html, flags=re.DOTALL)

    # 3. 볼드, 이탤릭
    html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
    html = re.sub(r'\*(.+?)\*', r'<em>\1</em>', html)

    # 4. 인라인 코드
    html = re.sub(r'`(.+?)`', r'<code>\1</code>', html)

    # 5. 리스트
    lines = html.split('\n')
    result = []
    in_list = False

    for line in lines:
        if re.match(r'^- ', line):
            if not in_list:
                result.append('<ul>')
                in_list = True
            result.append(f'<li>{line[2:]}</li>')
        else:
            if in_list:
                result.append('</ul>')
                in_list = False
            result.append(line)

    if in_list:
        result.append('</ul>')

    html = '\n'.join(result)

    # 6. 단락
    html = re.sub(r'\n\n+', '</p><p>', html)
    html = f'<p>{html}</p>'

    # 7. 정리
    html = re.sub(r'<p>\s*</p>', '', html)
    html = re.sub(r'<p>(<h\d>)', r'\1', html)
    html = re.sub(r'(</h\d>)</p>', r'\1', html)

    return html.strip()
```

### Step 5: Confluence 페이지 생성

```python
# 페이지 내용 구성
page_title = f"{project_name} - 프로젝트 분석"

page_body = f"""
<ac:structured-macro ac:name="info">
  <ac:rich-text-body>
    <p>이 문서는 Claude Code 플러그인을 통해 자동 생성되었습니다.</p>
    <p>마지막 업데이트: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
  </ac:rich-text-body>
</ac:structured-macro>

<h2>목차</h2>
<ac:structured-macro ac:name="toc">
  <ac:parameter ac:name="maxLevel">3</ac:parameter>
</ac:structured-macro>

<hr/>

{markdown_to_confluence_html(documents.get('context', ''))}

<hr/>

<h2>기능 요구사항</h2>
{markdown_to_confluence_html(documents.get('requirements', ''))}

<hr/>

<h2>사용자 플로우</h2>
{markdown_to_confluence_html(documents.get('flows', ''))}
"""

# 페이지 생성 요청
payload = {
    "type": "page",
    "title": page_title,
    "space": {"key": "CG1"},
    "ancestors": [{"id": parent_page_id}],
    "body": {
        "storage": {
            "value": page_body,
            "representation": "storage"
        }
    }
}

url = f"{jira_host}/wiki/rest/api/content"
response = requests.post(url, json=payload, headers=headers, auth=auth)

if response.status_code == 200:
    result = response.json()
    page_id = result['id']
    page_url = f"{jira_host}/wiki{result['_links']['webui']}"
    print(f"✅ Confluence 페이지 생성 완료!")
    print(f"📄 페이지: {page_title}")
    print(f"🔗 URL: {page_url}")

    # 페이지 ID를 .claude-state/confluence.json에 저장
    with open('.claude-state/confluence.json', 'w') as f:
        json.dump({
            'page_id': page_id,
            'page_url': page_url,
            'project_name': project_name,
            'created_at': datetime.now().isoformat()
        }, f, indent=2)
else:
    print(f"❌ 페이지 생성 실패: {response.status_code}")
    print(response.text)
```

---

## 페이지 업데이트

기존 페이지가 있으면 업데이트:

```python
# 기존 페이지 확인
search_url = f"{jira_host}/wiki/rest/api/content/search?cql=space=CG1 and title~'{page_title}'"
response = requests.get(search_url, auth=auth)
result = response.json()

if result['size'] > 0:
    # 업데이트 모드
    existing_page = result['results'][0]
    page_id = existing_page['id']
    current_version = existing_page['version']['number']

    # 버전 증가
    payload = {
        "id": page_id,
        "type": "page",
        "title": page_title,
        "space": {"key": "CG1"},
        "body": {
            "storage": {
                "value": page_body,
                "representation": "storage"
            }
        },
        "version": {
            "number": current_version + 1,
            "message": "Updated by Claude Code plugin"
        }
    }

    update_url = f"{jira_host}/wiki/rest/api/content/{page_id}"
    response = requests.put(update_url, json=payload, headers=headers, auth=auth)

    if response.status_code == 200:
        print(f"✅ 페이지 업데이트 완료! (버전 {current_version + 1})")
else:
    # 생성 모드 (위 Step 5와 동일)
    pass
```

---

## 자동 업데이트 설정

`.claude/hooks/post-push.sh`:

```bash
#!/bin/bash

# Git push 후 Confluence 자동 업데이트
if [ -f ".claude-state/confluence.json" ]; then
    echo "📡 Confluence 페이지 업데이트 중..."
    /ux confluence-init
fi
```

---

## 출력 예시

```
🔍 프로젝트 정보 수집 중...
  프로젝트명: IDCX
  문서 수: 3개
    ✓ PROJECT_CONTEXT.md
    ✓ FUNCTIONAL_REQUIREMENTS.md
    ✓ USER_FLOWS.md

🔍 Confluence 폴더 검색 중...
  ✓ "201 IDCX" 폴더 발견 (ID: 433061889)

📝 페이지 생성 중...
  ✓ Markdown → HTML 변환 완료
  ✓ API 요청 전송 완료

✅ Confluence 페이지 생성 완료!
📄 페이지: IDCX - 프로젝트 분석
🔗 URL: https://wondermove-official.atlassian.net/wiki/spaces/CG1/pages/1063026694
```

---

## 에러 처리

| 에러 | 원인 | 해결 |
|------|------|------|
| 프로젝트 폴더 없음 | Confluence에 폴더 미생성 | Confluence에서 "200 Projects" 하위에 폴더 생성 |
| API 인증 실패 | JIRA_API_TOKEN 만료 | 새 토큰 발급 및 환경 변수 업데이트 |
| 문서 파일 없음 | .ux-docs/ 비어있음 | `/ux onboard` 또는 `/ux init` 먼저 실행 |
| HTML 변환 오류 | Markdown 문법 오류 | 문서 검증 후 재시도 |

---

## 참고

- **Confluence REST API**: https://developer.atlassian.com/cloud/confluence/rest/v2/
- **Storage Format**: https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html
- **관련 명령어**: `/ux onboard`, `/ux init`
