---
description: JIRA 티켓 댓글의 Figma 링크를 읽어 Frame별 업데이트 내용을 Description에 자동 추가합니다.
allowed-tools: Read, Bash
argument-hint: [JIRA 티켓 키]
---

# /jira-figma-sync - Figma 업데이트 자동 동기화

JIRA 티켓 댓글에 있는 Figma 링크들을 읽어서, Frame별 업데이트 내용을 티켓 Description에 자동으로 추가합니다.

## 목적

- JIRA 티켓 댓글에서 Figma 링크 자동 수집
- Figma File/Frame 정보 자동 분석
- Frame별 업데이트 내용을 Description에 구조화하여 추가
- 디자인 변경 이력 자동 추적

---

## 사용법

```bash
# 특정 티켓의 Figma 링크 동기화
/jira-figma-sync CD-123

# 현재 Worktree의 모든 티켓 동기화
/jira-figma-sync --all

# Dry run (미리보기)
/jira-figma-sync CD-123 --dry-run
```

---

## 실행 프로토콜

### Step 0: 환경 확인

필수 환경변수 확인:

```bash
# JIRA 연동
JIRA_HOST
JIRA_EMAIL
JIRA_API_TOKEN

# Figma 연동 (선택)
FIGMA_ACCESS_TOKEN
```

**Figma Access Token 생성** (선택):
- https://www.figma.com/developers/api#access-tokens
- Personal Access Token 생성
- `.bashrc` 또는 `.zshrc`에 추가:
  ```bash
  export FIGMA_ACCESS_TOKEN="figd_your_token"
  ```

> **참고**: Token이 없어도 공개 링크에서 기본 정보는 추출 가능합니다.

---

### Step 1: JIRA 티켓 댓글 수집

```python
import requests
import re

def get_ticket_comments(jira_key):
    """
    JIRA 티켓의 모든 댓글 가져오기
    """
    url = f"{JIRA_HOST}/rest/api/3/issue/{jira_key}/comment"

    response = requests.get(
        url,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={"Content-Type": "application/json"}
    )

    if response.status_code != 200:
        raise Exception(f"Failed to fetch comments: {response.status_code}")

    return response.json()['comments']
```

---

### Step 2: Figma 링크 추출

댓글에서 Figma 링크 패턴 매칭:

```python
def extract_figma_links(comments):
    """
    댓글에서 Figma 링크 추출

    지원 형식:
    - https://www.figma.com/file/{file_id}/{file_name}
    - https://www.figma.com/design/{file_id}/{file_name}
    - https://www.figma.com/file/{file_id}?node-id={node_id}
    """
    figma_pattern = re.compile(
        r'https://(?:www\.)?figma\.com/(?:file|design)/([a-zA-Z0-9]+)/([^?\s]+)(?:\?.*?node-id=([^&\s]+))?'
    )

    links = []
    for comment in comments:
        body = comment['body']
        # ADF (Atlassian Document Format) 텍스트 추출
        text = extract_text_from_adf(body)

        matches = figma_pattern.finditer(text)
        for match in matches:
            file_id = match.group(1)
            file_name = match.group(2)
            node_id = match.group(3) if match.group(3) else None

            links.append({
                'file_id': file_id,
                'file_name': file_name,
                'node_id': node_id,
                'url': match.group(0),
                'comment_id': comment['id'],
                'author': comment['author']['displayName'],
                'created': comment['created']
            })

    return links

def extract_text_from_adf(adf_body):
    """
    Atlassian Document Format에서 텍스트 추출
    """
    if isinstance(adf_body, str):
        return adf_body

    if isinstance(adf_body, dict):
        text_parts = []
        if 'content' in adf_body:
            for item in adf_body['content']:
                text_parts.append(extract_text_from_adf(item))
        if 'text' in adf_body:
            text_parts.append(adf_body['text'])
        return ' '.join(text_parts)

    return ''
```

---

### Step 3: Figma 파일 정보 가져오기

#### Option A: Figma API 사용 (Token 있을 때)

```python
def get_figma_file_info(file_id):
    """
    Figma API로 파일 정보 가져오기
    """
    if not FIGMA_ACCESS_TOKEN:
        return None

    url = f"https://api.figma.com/v1/files/{file_id}"

    response = requests.get(
        url,
        headers={"X-Figma-Token": FIGMA_ACCESS_TOKEN}
    )

    if response.status_code != 200:
        print(f"Warning: Figma API failed ({response.status_code})")
        return None

    data = response.json()

    return {
        'name': data['name'],
        'lastModified': data['lastModified'],
        'version': data['version'],
        'frames': extract_frames(data['document'])
    }

def extract_frames(node, frames=None):
    """
    Figma 파일에서 Frame 목록 추출
    """
    if frames is None:
        frames = []

    if node['type'] == 'FRAME':
        frames.append({
            'id': node['id'],
            'name': node['name'],
            'type': node['type']
        })

    if 'children' in node:
        for child in node['children']:
            extract_frames(child, frames)

    return frames
```

#### Option B: 링크 파싱 (Token 없을 때)

```python
def parse_figma_link(link):
    """
    Figma 링크에서 기본 정보 추출
    """
    return {
        'file_id': link['file_id'],
        'file_name': link['file_name'].replace('-', ' ').replace('%20', ' '),
        'node_id': link['node_id'],
        'url': link['url']
    }
```

---

### Step 4: Description 업데이트 내용 생성

```python
def create_figma_section(figma_links, figma_info_list):
    """
    Description에 추가할 Figma 섹션 생성 (ADF 형식)
    """
    content = []

    # 헤더
    content.append({
        "type": "heading",
        "attrs": {"level": 2},
        "content": [{"type": "text", "text": "🎨 디자인 업데이트"}]
    })

    # Figma 링크별 정보
    for link, info in zip(figma_links, figma_info_list):
        # 파일명
        content.append({
            "type": "heading",
            "attrs": {"level": 3},
            "content": [{"type": "text", "text": f"📄 {info['file_name']}"}]
        })

        # 메타 정보
        content.append({
            "type": "paragraph",
            "content": [
                {"type": "text", "text": "업데이트: ", "marks": [{"type": "strong"}]},
                {"type": "text", "text": link['created'][:10]},
                {"type": "text", "text": " | 담당: ", "marks": [{"type": "strong"}]},
                {"type": "text", "text": link['author']}
            ]
        })

        # Figma 링크
        content.append({
            "type": "paragraph",
            "content": [
                {"type": "text", "text": "🔗 ", "marks": [{"type": "strong"}]},
                {
                    "type": "text",
                    "text": "Figma에서 보기",
                    "marks": [{"type": "link", "attrs": {"href": link['url']}}]
                }
            ]
        })

        # Frame 목록 (API 사용 시)
        if info.get('frames'):
            content.append({
                "type": "paragraph",
                "content": [{"type": "text", "text": "Frame 목록:", "marks": [{"type": "strong"}]}]
            })

            frame_list = {"type": "bulletList", "content": []}
            for frame in info['frames']:
                frame_list["content"].append({
                    "type": "listItem",
                    "content": [{
                        "type": "paragraph",
                        "content": [{"type": "text", "text": frame['name']}]
                    }]
                })
            content.append(frame_list)

        # 구분선
        content.append({"type": "rule"})

    return content

def append_to_description(jira_key, figma_section):
    """
    기존 Description에 Figma 섹션 추가
    """
    # 1. 현재 Description 가져오기
    url = f"{JIRA_HOST}/rest/api/3/issue/{jira_key}"
    response = requests.get(
        url,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={"Content-Type": "application/json"}
    )

    current_desc = response.json()['fields']['description']

    # 2. 기존 Figma 섹션 제거 (중복 방지)
    new_content = []
    skip = False
    for item in current_desc.get('content', []):
        if item.get('type') == 'heading':
            heading_text = item['content'][0]['text'] if item.get('content') else ''
            if '🎨 디자인 업데이트' in heading_text:
                skip = True
                continue

        if skip and item.get('type') == 'rule':
            skip = False
            continue

        if not skip:
            new_content.append(item)

    # 3. 새 Figma 섹션 추가
    new_content.extend(figma_section)

    # 4. Description 업데이트
    update_data = {
        "fields": {
            "description": {
                "type": "doc",
                "version": 1,
                "content": new_content
            }
        }
    }

    response = requests.put(
        url,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={"Content-Type": "application/json"},
        json=update_data
    )

    return response.status_code == 204
```

---

### Step 5: 전체 동기화 실행

```python
def sync_figma_to_jira(jira_key):
    """
    메인 동기화 함수
    """
    print(f"🔍 티켓 분석 중: {jira_key}")

    # 1. 댓글 수집
    comments = get_ticket_comments(jira_key)
    print(f"   댓글: {len(comments)}개")

    # 2. Figma 링크 추출
    figma_links = extract_figma_links(comments)
    if not figma_links:
        print("   ⚠️ Figma 링크 없음")
        return

    print(f"   Figma 링크: {len(figma_links)}개")

    # 3. Figma 정보 수집
    figma_info_list = []
    for link in figma_links:
        info = get_figma_file_info(link['file_id'])
        if not info:
            info = parse_figma_link(link)
        figma_info_list.append(info)

    # 4. Description 업데이트
    figma_section = create_figma_section(figma_links, figma_info_list)
    success = append_to_description(jira_key, figma_section)

    # 5. 화면 구성 업데이트 이력 추가
    if success and config.get('figma', {}).get('auto_update_screen', True):
        for link in figma_links:
            screen_update(
                jira_key,
                changes=f"Figma 디자인 업데이트: {link['file_name']}",
                author=link['author'],
                figma_link=link['url']
            )

    if success:
        print(f"   ✅ Description 업데이트 완료")
        print(f"   ✅ 화면 구성 이력 추가 완료")
    else:
        print(f"   ❌ 업데이트 실패")

    return success
```

---

## 출력 형식

### 성공 케이스

```
============================================
 JIRA-Figma 동기화
============================================

🔍 티켓: CD-123 "사용자 프로필 화면"

📝 분석 결과:
 • 댓글: 5개
 • Figma 링크: 2개

🎨 Figma 파일:
 1. User Profile Design v2
    • Frame: Profile Header
    • Frame: User Info Card
    • Frame: Settings Panel
    • 업데이트: 2025-12-28
    • 작성자: 디자이너A

 2. Profile Components
    • Frame: Avatar Component
    • Frame: Badge Component
    • 업데이트: 2025-12-29
    • 작성자: 디자이너B

✅ Description 업데이트 완료

JIRA 티켓: https://wondermove-official.atlassian.net/browse/CD-123

============================================
```

### 전체 동기화 (--all)

```
============================================
 JIRA-Figma 전체 동기화
============================================

Worktree 분석 중...
 • Epic: 2개
 • Task: 5개
 • Subtask: 12개

동기화 진행:

✅ CD-101: Figma 링크 2개 동기화 완료
⏭️ CD-102: Figma 링크 없음 (스킵)
✅ CD-103: Figma 링크 1개 동기화 완료
❌ CD-104: 권한 없음 (스킵)
✅ CD-105: Figma 링크 3개 동기화 완료

결과:
 • 성공: 3개
 • 스킵: 2개
 • 실패: 1개

============================================
```

---

## 에러 처리

| 에러 | 원인 | 해결 |
|------|------|------|
| JIRA 인증 실패 | API 토큰 오류 | `/jira-init` 재실행 |
| Figma API 실패 | Token 없음/만료 | Token 재생성 또는 링크 파싱 모드 사용 |
| 권한 없음 | 티켓 수정 권한 부족 | JIRA 관리자 문의 |
| 링크 없음 | 댓글에 Figma 링크 없음 | 댓글에 Figma 링크 추가 |

---

## Figma 링크 형식

### 지원되는 링크 형식

1. **파일 링크**:
   ```
   https://www.figma.com/file/ABC123/File-Name
   https://www.figma.com/design/ABC123/File-Name
   ```

2. **특정 Frame 링크**:
   ```
   https://www.figma.com/file/ABC123/File-Name?node-id=123:456
   ```

3. **공유 링크**:
   ```
   https://www.figma.com/file/ABC123/File-Name?type=design&node-id=123:456
   ```

---

## 사용 예시

### 예시 1: 단일 티켓 동기화

```bash
# 1. JIRA 티켓에 댓글 작성
# "디자인 시안 업데이트: https://www.figma.com/file/ABC123/User-Profile"

# 2. 동기화 실행
/jira-figma-sync CD-123

# 3. Description에 자동 추가됨:
# 🎨 디자인 업데이트
# 📄 User Profile
# 🔗 Figma에서 보기
# Frame 목록:
# • Profile Header
# • User Info Card
```

### 예시 2: 여러 링크 동기화

```bash
# 댓글 1: "메인 화면: https://www.figma.com/file/ABC123/Main"
# 댓글 2: "컴포넌트: https://www.figma.com/file/DEF456/Components"

/jira-figma-sync CD-124

# Description에 두 파일 모두 추가됨
```

### 예시 3: 전체 Worktree 동기화

```bash
/jira-figma-sync --all

# Worktree의 모든 티켓 자동 처리
```

---

## 자동화 옵션

### 훅 설정

`.claude/hooks/on-jira-comment.sh` 생성:

```bash
#!/bin/bash
# JIRA 댓글 작성 시 자동 동기화

JIRA_KEY=$1

if [[ -n "$JIRA_KEY" ]]; then
    /jira-figma-sync "$JIRA_KEY"
fi
```

---

## 연계 기능

- `/jira-push` - Worktree → JIRA 동기화 시 Figma 링크도 함께 동기화
- `/jira-status` - Figma 링크 유무도 함께 표시
- `/ux design` - 화면 설계 시 Figma 링크 자동 추가 제안

---

## 다음 단계

- `/jira-status` - 동기화 결과 확인
- `/jira-pull` - JIRA → Worktree 역방향 동기화 (미구현)

---

## 참조 파일

- `.claude/integrations/jira_config.json` - JIRA 설정
- `.claude-state/jira_mapping.json` - 매핑 정보
- `.claude-state/worktree.json` - Worktree

---

## API 문서

- **JIRA API**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- **Figma API**: https://www.figma.com/developers/api
