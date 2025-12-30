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

### Step 3: Figma 정보 수집 (개선된 방식 ⭐)

#### 핵심 개선사항

**Before (문제점)**:
- ❌ Files API로 전체 파일 다운로드 (169,349 Frame) → 타임아웃
- ❌ 임의로 5개 Frame만 선택 → 의미 없는 데이터

**After (개선)**:
- ✅ **Nodes API**로 특정 Frame만 조회 → 빠름!
- ✅ **Comments API**로 Frame별 댓글 수집 → 변경사항 추적
- ✅ **JIRA 댓글 텍스트**에서 변경사항 설명 추출

#### Step 3-1: Figma Nodes API로 Frame 정보 가져오기

```python
def get_figma_frame_info(file_id, node_id):
    """
    Figma Nodes API로 특정 Frame 정보 가져오기

    Before: Files API (전체 파일 다운로드, 느림)
    After: Nodes API (특정 Node만 조회, 빠름!)
    """
    if not FIGMA_ACCESS_TOKEN:
        return None

    # URL node-id 형식(10953-47730) → API 형식(10953:47730) 변환
    figma_node_id = node_id.replace('-', ':')

    # Nodes API 사용
    url = f"https://api.figma.com/v1/files/{file_id}/nodes?ids={figma_node_id}"

    response = requests.get(
        url,
        headers={"X-Figma-Token": FIGMA_ACCESS_TOKEN}
    )

    if response.status_code != 200:
        print(f"Warning: Figma Nodes API failed ({response.status_code})")
        return None

    data = response.json()

    # Node 정보 추출
    if figma_node_id in data.get('nodes', {}):
        node_info = data['nodes'][figma_node_id]
        return {
            'file_name': data.get('name', 'Unknown File'),
            'frame_name': node_info['document'].get('name', 'Unknown Frame'),
            'node_id': figma_node_id,
            'last_modified': data.get('lastModified', '')
        }

    return None

def get_figma_comments(file_id, node_id):
    """
    Figma Comments API로 Frame별 댓글 가져오기
    """
    if not FIGMA_ACCESS_TOKEN:
        return []

    figma_node_id = node_id.replace('-', ':')

    url = f"https://api.figma.com/v1/files/{file_id}/comments"

    response = requests.get(
        url,
        headers={"X-Figma-Token": FIGMA_ACCESS_TOKEN}
    )

    if response.status_code != 200:
        return []

    all_comments = response.json().get('comments', [])

    # 특정 Node의 댓글만 필터링
    node_comments = [
        c for c in all_comments
        if c.get('client_meta') and
           c['client_meta'].get('node_id') == figma_node_id
    ]

    return node_comments
```

#### Step 3-2: JIRA 댓글에서 변경사항 설명 추출

```python
def extract_change_description_from_comment(comment_body, figma_url):
    """
    JIRA 댓글에서 Figma 링크 다음 줄의 변경사항 설명 추출

    예시:
    https://www.figma.com/design/xxx?node-id=10953-47730
    로그인 버튼 텍스트 변경: "로그인" → "Sign In"

    → "로그인 버튼 텍스트 변경: "로그인" → "Sign In"" 추출
    """
    text = extract_text_from_adf(comment_body)

    # Figma 링크 이후의 텍스트 찾기
    if figma_url in text:
        # URL 이후의 텍스트 추출
        after_url = text.split(figma_url, 1)[1].strip()

        # 첫 줄만 추출 (여러 줄인 경우)
        lines = after_url.split('\n')
        if lines and lines[0].strip():
            return lines[0].strip()

    # blockCard 형태인 경우 (URL만 있고 텍스트 없음)
    return None
```

#### Step 3-3: 링크 파싱 (Fallback)

```python
def parse_figma_link_fallback(link):
    """
    Figma Token이 없을 때 기본 정보만 추출
    """
    return {
        'file_id': link['file_id'],
        'file_name': link['file_name'].replace('-', ' ').replace('%20', ' '),
        'node_id': link['node_id'],
        'url': link['url']
    }
```

---

### Step 4: Description 포맷 검증 및 수정

#### Step 4-1: 6섹션 구조 검증

```python
def validate_description_format(description_adf):
    """
    Description이 6섹션 구조를 따르는지 검증

    필수 섹션:
    1. 요구사항
    2. 해결방안
    3. 디자인 의도
    4. 화면 구성
    5. Step
    6. 결과
    """
    required_sections = [
        "요구사항",
        "해결방안",
        "디자인 의도",
        "화면 구성",
        "Step",
        "결과"
    ]

    content = description_adf.get('content', [])

    found_sections = []
    for item in content:
        if item.get('type') == 'heading':
            heading_text = extract_text_from_adf(item)
            for section in required_sections:
                if section in heading_text:
                    found_sections.append(section)

    missing_sections = [s for s in required_sections if s not in found_sections]

    return {
        'is_valid': len(missing_sections) == 0,
        'missing_sections': missing_sections,
        'found_sections': found_sections
    }

def create_default_description():
    """
    6섹션 구조의 기본 Description 생성
    """
    return {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "heading",
                "attrs": {"level": 2},
                "content": [{"type": "text", "text": "요구사항"}]
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": "(작성 필요)"}]
            },
            {
                "type": "heading",
                "attrs": {"level": 2},
                "content": [{"type": "text", "text": "해결방안"}]
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": "(작성 필요)"}]
            },
            {
                "type": "heading",
                "attrs": {"level": 2},
                "content": [{"type": "text", "text": "디자인 의도"}]
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": "(작성 필요)"}]
            },
            {
                "type": "heading",
                "attrs": {"level": 2},
                "content": [{"type": "text", "text": "화면 구성"}]
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": "업데이트 이력:", "marks": [{"type": "strong"}]}]
            },
            {
                "type": "table",
                "content": [
                    {
                        "type": "tableRow",
                        "content": [
                            {"type": "tableHeader", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "날짜"}]}]},
                            {"type": "tableHeader", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "작성자"}]}]},
                            {"type": "tableHeader", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "변경 내용"}]}]}
                        ]
                    }
                ]
            },
            {
                "type": "heading",
                "attrs": {"level": 2},
                "content": [{"type": "text", "text": "Step"}]
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": "(작성 필요)"}]
            },
            {
                "type": "heading",
                "attrs": {"level": 2},
                "content": [{"type": "text", "text": "결과"}]
            },
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": "작업 완료 후 업데이트 예정"}]
            }
        ]
    }
```

#### Step 4-2: Figma 섹션 생성 (개선된 버전)

```python
def create_figma_update_rows(figma_data_list):
    """
    화면 구성 테이블에 추가할 업데이트 행 생성

    최종 포맷:
    | 날짜 | 작성자 | 변경 내용 |
    | 2025-12-30 | vision | 📄 KIA IDCX > C_0101<br>See More 버튼 추가 |

    figma_data: {
        'file_name': str,
        'frame_name': str,
        'node_id': str,
        'jira_comment_change': str,  # JIRA 댓글의 변경사항 설명
        'figma_comments': list,      # Figma의 댓글들
        'author': str,
        'created': str,
        'url': str
    }
    """
    rows = []

    for data in figma_data_list:
        # 날짜
        date_str = data['created'][:10]

        # 작성자
        author = data['author']

        # 변경 내용 구성
        change_parts = []

        # 1. 파일명 > Frame명 (한 줄로)
        if data.get('file_name') and data.get('frame_name'):
            change_parts.append({
                "type": "text",
                "text": f"📄 {data['file_name']} > {data['frame_name']}"
            })
        elif data.get('frame_name'):
            change_parts.append({
                "type": "text",
                "text": f"📄 {data['frame_name']}"
            })

        # 2. JIRA 댓글의 변경사항 또는 Figma 댓글 (하나만 선택)
        description_text = None

        if data.get('jira_comment_change'):
            # JIRA 댓글 우선 (전체 내용)
            description_text = data['jira_comment_change']
        elif data.get('figma_comments') and len(data['figma_comments']) > 0:
            # Figma 댓글 (전체 내용, 길이 제한 없음)
            description_text = data['figma_comments'][0].get('message', '')

        # 3. 변경사항 텍스트를 같은 paragraph에 추가
        if description_text:
            if change_parts:
                # 줄바꿈 추가
                change_parts.append({"type": "hardBreak"})
            change_parts.append({
                "type": "text",
                "text": description_text
            })

        # 테이블 행 생성
        row = {
            "type": "tableRow",
            "content": [
                {
                    "type": "tableCell",
                    "content": [{
                        "type": "paragraph",
                        "content": [{"type": "text", "text": date_str}]
                    }]
                },
                {
                    "type": "tableCell",
                    "content": [{
                        "type": "paragraph",
                        "content": [{"type": "text", "text": author}]
                    }]
                },
                {
                    "type": "tableCell",
                    "content": [{
                        "type": "paragraph",
                        "content": change_parts if change_parts else [{"type": "text", "text": "(변경 내용 없음)"}]
                    }]
                }
            ]
        }

        rows.append(row)

    return rows
```

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

## 사용 예시 (개선된 버전 ⭐)

### 예시 1: JIRA 댓글에 변경사항 작성

**12월 30일 - 첫 번째 업데이트**:

JIRA 댓글:
```
https://www.figma.com/design/PsCISK2RuhCPs8FZurojeP/KIA-IDCX?node-id=10953-47730
로그인 버튼 텍스트 변경: "로그인" → "Sign In"
```

동기화 실행:
```bash
/jira-figma-sync CD-279
```

**화면 구성 테이블 결과**:
| 날짜 | 작성자 | 변경 내용 |
|------|--------|----------|
| 2025-12-30 | vision | 📄 KIA IDCX > C_0101<br>로그인 버튼 텍스트 변경: "로그인" → "Sign In" |

---

**12월 31일 - 두 번째 업데이트 (누적)**:

JIRA 댓글:
```
https://www.figma.com/design/PsCISK2RuhCPs8FZurojeP/KIA-IDCX?node-id=10953-47782
See More 버튼 추가 및 약관 모달 레이아웃 수정
```

동기화 실행:
```bash
/jira-figma-sync CD-279
```

**화면 구성 테이블 결과 (누적)**:
| 날짜 | 작성자 | 변경 내용 |
|------|--------|----------|
| 2025-12-30 | vision | 📄 KIA IDCX > C_0101<br>로그인 버튼 텍스트 변경: "로그인" → "Sign In" |
| 2025-12-31 | vision | 📄 KIA IDCX > C_0101_disclaimer modal<br>See More 버튼 추가 및 약관 모달 레이아웃 수정 |

---

### 예시 2: Figma 댓글 자동 수집 (JIRA 댓글 설명 없을 때)

**Figma에서 Frame에 댓글 작성**:
```
"헤더 영역 패딩 16px → 20px 변경, 프로필 아이콘 크기 32px → 36px로 조정"
```

**JIRA 댓글에 링크만 추가**:
```
https://www.figma.com/design/xxx?node-id=10953-47800
```

**동기화 실행 후 결과**:
| 날짜 | 작성자 | 변경 내용 |
|------|--------|----------|
| 2025-12-30 | vision | 📄 KIA IDCX > C_0101<br>로그인 버튼 텍스트 변경: "로그인" → "Sign In" |
| 2025-12-31 | vision | 📄 KIA IDCX > C_0101_disclaimer modal<br>See More 버튼 추가 및 약관 모달 레이아웃 수정 |
| 2026-01-02 | designer | 📄 KIA IDCX > Header<br>헤더 영역 패딩 16px → 20px 변경, 프로필 아이콘 크기 32px → 36px로 조정 |

→ **Figma 댓글 전체 내용이 그대로 표시됨**

---

### 예시 3: Description 포맷 자동 수정

**Before (비어있거나 불완전한 Description)**:
```
(빈 Description)
```

**동기화 실행**:
```bash
/jira-figma-sync CD-279
```

**결과**:
- ✅ 6섹션 구조 자동 생성 (요구사항, 해결방안, 디자인 의도, 화면 구성, Step, 결과)
- ✅ 화면 구성 테이블에 Figma 업데이트 자동 추가

---

### 예시 4: 전체 Worktree 동기화

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
