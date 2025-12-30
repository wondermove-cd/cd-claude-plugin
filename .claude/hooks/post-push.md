---
name: post-push
description: Git push 후 자동으로 Confluence 문서를 업데이트합니다.
trigger: after git push
---

# Post-Push Hook - Confluence 자동 업데이트

Git push가 성공하면 자동으로 Confluence 문서를 업데이트합니다.

## 실행 조건

- `git push` 명령어 실행 성공 시
- `main` 또는 `master` 브랜치에 푸시했을 때
- 문서 관련 파일이 변경되었을 때

---

## 자동 실행 프로토콜

### Step 1: Push 완료 감지

Git push가 성공하면 자동으로 다음 메시지 표시:

```
✅ Push 완료!

📄 Confluence 문서를 업데이트하시겠습니까?

변경된 파일:
- README.md
- .claude/commands/jira-figma-sync.md
- CONFLUENCE.md

[Y] 자동 업데이트
[N] 건너뛰기
[V] 변경사항 미리보기
```

---

### Step 2: Confluence 문서 생성

CONFLUENCE.md를 기반으로 Confluence 페이지 업데이트:

```python
import requests
import json
from datetime import datetime

def update_confluence_after_push():
    """
    Git push 후 Confluence 문서 자동 업데이트
    """
    # 1. CONFLUENCE.md 읽기
    with open('CONFLUENCE.md', 'r', encoding='utf-8') as f:
        markdown_content = f.read()

    # 2. 변경사항 확인
    changed_files = get_changed_files()

    # 3. 문서 관련 파일이 변경되었는지 확인
    doc_files = [
        'README.md',
        'CONFLUENCE.md',
        '.claude/commands/',
        '.claude/skills/',
        'INSTALL.md'
    ]

    has_doc_changes = any(
        any(doc in file for doc in doc_files)
        for file in changed_files
    )

    if not has_doc_changes:
        print("📝 문서 변경사항 없음 - Confluence 업데이트 스킵")
        return

    # 4. 사용자 확인
    response = input("\n📄 Confluence 문서를 업데이트하시겠습니까? [Y/n/v]: ")

    if response.lower() == 'v':
        # 미리보기
        preview_confluence_changes(markdown_content, changed_files)
        response = input("\n업데이트하시겠습니까? [Y/n]: ")

    if response.lower() in ['', 'y', 'yes']:
        # Confluence 업데이트 실행
        success = update_confluence_page(markdown_content, changed_files)

        if success:
            print("✅ Confluence 문서 업데이트 완료!")
            print("🔗 https://wondermove-official.atlassian.net/wiki/spaces/CG1/pages/1061912621")
        else:
            print("❌ Confluence 업데이트 실패")
    else:
        print("⏭️ Confluence 업데이트 건너뜀")

def get_changed_files():
    """
    마지막 커밋에서 변경된 파일 목록 가져오기
    """
    import subprocess

    result = subprocess.run(
        ['git', 'diff', '--name-only', 'HEAD~1', 'HEAD'],
        capture_output=True,
        text=True
    )

    return result.stdout.strip().split('\n')

def preview_confluence_changes(content, changed_files):
    """
    Confluence 업데이트 미리보기
    """
    print("\n" + "="*50)
    print(" Confluence 업데이트 미리보기")
    print("="*50)

    print(f"\n📝 변경된 파일 ({len(changed_files)}개):")
    for file in changed_files[:10]:  # 최대 10개만 표시
        print(f"  • {file}")

    if len(changed_files) > 10:
        print(f"  ... 외 {len(changed_files) - 10}개")

    print(f"\n📄 문서 크기: {len(content)} 문자")
    print(f"📅 업데이트 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🔗 대상 페이지: CD Claude Plugin (1061912621)")

def update_confluence_page(markdown_content, changed_files):
    """
    Confluence 페이지 업데이트
    """
    # 환경변수 확인
    jira_email = os.getenv('JIRA_EMAIL')
    jira_token = os.getenv('JIRA_API_TOKEN')
    jira_host = os.getenv('JIRA_HOST', 'https://wondermove-official.atlassian.net')

    if not jira_email or not jira_token:
        print("⚠️ JIRA 환경변수가 설정되지 않았습니다.")
        print("   JIRA_EMAIL, JIRA_API_TOKEN을 설정해주세요.")
        return False

    # 1. 현재 페이지 정보 가져오기
    page_id = "1061912621"
    url = f"{jira_host}/wiki/api/v2/pages/{page_id}"

    response = requests.get(
        url,
        auth=(jira_email, jira_token),
        headers={"Content-Type": "application/json"}
    )

    if response.status_code != 200:
        print(f"❌ 페이지 조회 실패: {response.status_code}")
        return False

    current_page = response.json()
    current_version = current_page['version']['number']

    # 2. Markdown을 Confluence 포맷으로 변환
    confluence_html = markdown_to_confluence(markdown_content)

    # 3. 변경 이력 추가
    change_log = create_change_log(changed_files)
    confluence_html += change_log

    # 4. 페이지 업데이트
    update_data = {
        "id": page_id,
        "status": "current",
        "title": "CD Claude Plugin - 시스템 개요 및 설치 가이드",
        "spaceId": "431489095",
        "body": {
            "representation": "storage",
            "value": confluence_html
        },
        "version": {
            "number": current_version + 1,
            "message": f"Auto-update from Git push ({datetime.now().strftime('%Y-%m-%d %H:%M')})"
        }
    }

    response = requests.put(
        url,
        auth=(jira_email, jira_token),
        headers={"Content-Type": "application/json"},
        json=update_data
    )

    return response.status_code == 200

def markdown_to_confluence(md):
    """
    Markdown을 Confluence Storage Format으로 변환
    """
    import re

    html = md

    # Headers
    html = re.sub(r'^#### (.+)$', r'<h4>\1</h4>', html, flags=re.MULTILINE)
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)

    # Bold
    html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)

    # Code blocks
    html = re.sub(
        r'```bash\n(.*?)\n```',
        r'<ac:structured-macro ac:name="code"><ac:parameter ac:name="language">bash</ac:parameter><ac:plain-text-body><![CDATA[\1]]></ac:plain-text-body></ac:structured-macro>',
        html,
        flags=re.DOTALL
    )
    html = re.sub(
        r'```\n(.*?)\n```',
        r'<ac:structured-macro ac:name="code"><ac:plain-text-body><![CDATA[\1]]></ac:plain-text-body></ac:structured-macro>',
        html,
        flags=re.DOTALL
    )

    # Inline code
    html = re.sub(r'`([^`]+)`', r'<code>\1</code>', html)

    # Links
    html = re.sub(r'\[([^\]]+)\]\(([^\)]+)\)', r'<a href="\2">\1</a>', html)

    # Blockquotes
    html = re.sub(r'^> (.+)$', r'<blockquote><p>\1</p></blockquote>', html, flags=re.MULTILINE)

    # Line breaks
    html = re.sub(r'\n\n', '<p></p>', html)
    html = re.sub(r'\n', '<br/>', html)

    return html

def create_change_log(changed_files):
    """
    변경 이력 섹션 생성
    """
    from datetime import datetime

    html = '<hr/>'
    html += '<h2>📝 최근 업데이트</h2>'
    html += f'<p><strong>업데이트 일시</strong>: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>'
    html += '<p><strong>변경된 파일</strong>:</p>'
    html += '<ul>'

    for file in changed_files[:10]:
        html += f'<li><code>{file}</code></li>'

    if len(changed_files) > 10:
        html += f'<li>... 외 {len(changed_files) - 10}개</li>'

    html += '</ul>'
    html += f'<p>🔗 <a href="https://github.com/wondermove-cd/cd-claude-plugin/commits/main">GitHub 커밋 이력</a></p>'

    return html
```

---

## 설정

### 자동 업데이트 활성화

`.claude/config.json`에 설정:

```json
{
  "hooks": {
    "post-push": {
      "enabled": true,
      "auto_update_confluence": true,
      "confluence_page_id": "1061912621",
      "confluence_space": "CG1",
      "ask_confirmation": true,
      "skip_if_no_doc_changes": true
    }
  }
}
```

### 환경변수 설정

Confluence 업데이트를 위한 환경변수 (JIRA와 동일):

```bash
# .zshrc 또는 .bashrc에 추가
export JIRA_HOST="https://wondermove-official.atlassian.net"
export JIRA_EMAIL="your-email@wondermove.net"
export JIRA_API_TOKEN="your-api-token"

source ~/.zshrc
```

---

## 사용 예시

### 예시 1: 일반 Push

```bash
git push origin main

# 출력:
# To github.com:wondermove-cd/cd-claude-plugin.git
#    abc1234..def5678  main -> main
#
# ✅ Push 완료!
#
# 📄 Confluence 문서를 업데이트하시겠습니까?
#
# 변경된 파일:
# - README.md
# - .claude/commands/jira-figma-sync.md
#
# [Y] 자동 업데이트
# [N] 건너뛰기
# [V] 변경사항 미리보기
```

### 예시 2: 미리보기 후 업데이트

```bash
git push origin main

# [V] 선택
# ══════════════════════════════════════════════════
#  Confluence 업데이트 미리보기
# ══════════════════════════════════════════════════
#
# 📝 변경된 파일 (2개):
#   • README.md
#   • .claude/commands/jira-figma-sync.md
#
# 📄 문서 크기: 15,234 문자
# 📅 업데이트 시간: 2025-12-30 17:30:00
# 🔗 대상 페이지: CD Claude Plugin (1061912621)
#
# 업데이트하시겠습니까? [Y/n]: Y
#
# ✅ Confluence 문서 업데이트 완료!
# 🔗 https://wondermove-official.atlassian.net/wiki/spaces/CG1/pages/1061912621
```

### 예시 3: 문서 변경 없음 (자동 스킵)

```bash
git push origin main

# 출력:
# To github.com:wondermove-cd/cd-claude-plugin.git
#    abc1234..def5678  main -> main
#
# 📝 문서 변경사항 없음 - Confluence 업데이트 스킵
```

---

## 수동 업데이트

언제든지 수동으로 Confluence 업데이트 가능:

```bash
# Python 스크립트 실행
python3 << 'PYTHON_SCRIPT'
# [위의 update_confluence_after_push() 함수 복사]

update_confluence_after_push()
PYTHON_SCRIPT
```

또는 간단하게:

```bash
# CONFLUENCE.md를 Confluence에 업데이트
claude "CONFLUENCE.md 파일을 Confluence 페이지 1061912621에 업데이트해줘"
```

---

## Hook 작동 방식

### 1. Git Push 감지

Git push 명령어 실행 후 자동으로 트리거:

```
User → git push → GitHub → Hook 실행 → Confluence 업데이트
```

### 2. 파일 변경 확인

문서 관련 파일만 체크:

```python
doc_files = [
    'README.md',
    'CONFLUENCE.md',
    '.claude/commands/',
    '.claude/skills/',
    'INSTALL.md',
    '.claude/templates/'
]
```

### 3. 사용자 확인

자동 업데이트 전 사용자에게 확인:

```
ask_confirmation: true  → 확인 메시지 표시
ask_confirmation: false → 자동 업데이트 (확인 없음)
```

---

## 변경 이력 추적

Confluence 페이지 하단에 자동으로 업데이트 이력 추가:

```
📝 최근 업데이트

업데이트 일시: 2025-12-30 17:30:00

변경된 파일:
• README.md
• .claude/commands/jira-figma-sync.md
• .claude/skills/figma-link-tracker/skill.md

🔗 GitHub 커밋 이력
```

---

## 에러 처리

| 에러 | 원인 | 해결 |
|------|------|------|
| 환경변수 없음 | JIRA_EMAIL, JIRA_API_TOKEN 미설정 | 환경변수 설정 |
| 인증 실패 | API 토큰 만료 | 토큰 재생성 |
| 페이지 조회 실패 | 잘못된 페이지 ID | 페이지 ID 확인 |
| 변환 실패 | Markdown 포맷 오류 | CONFLUENCE.md 문법 확인 |

---

## 고급 설정

### 특정 파일만 감지

`.claude/config.json`:

```json
{
  "hooks": {
    "post-push": {
      "watch_files": [
        "README.md",
        "CONFLUENCE.md",
        ".claude/commands/**/*.md"
      ],
      "ignore_files": [
        ".claude/state/**",
        "**/*.json"
      ]
    }
  }
}
```

### 자동 커밋 메시지에 Confluence 링크 추가

```bash
# 커밋 메시지에 Confluence 링크 자동 추가
git commit -m "feat: 새 기능 추가

Confluence: https://wondermove-official.atlassian.net/wiki/spaces/CG1/pages/1061912621
"
```

---

## 베스트 프랙티스

### 1. CONFLUENCE.md 최신 유지

항상 CONFLUENCE.md를 최신으로 유지:

```bash
# README.md 변경 시 CONFLUENCE.md도 함께 업데이트
git add README.md CONFLUENCE.md
git commit -m "docs: 문서 업데이트"
git push
```

### 2. 변경사항 미리보기

중요한 변경 시 미리보기 사용:

```bash
# Push 후 [V] 선택하여 미리보기
```

### 3. 정기 동기화

주기적으로 Confluence와 GitHub 동기화 확인:

```bash
# 주 1회 전체 동기화
/confluence-sync --force
```

---

## 관련 명령어

- `/confluence-sync` - 수동 Confluence 동기화
- `/confluence-preview` - 업데이트 미리보기
- `/confluence-history` - 업데이트 이력 조회

---

## 참조

- **Confluence REST API**: https://developer.atlassian.com/cloud/confluence/rest/v2/
- **Git Hooks**: https://git-scm.com/docs/githooks
- **설정 파일**: `.claude/config.json`
