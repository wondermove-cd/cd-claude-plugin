---
description: JIRA 티켓의 화면 구성 섹션을 업데이트하고 변경 이력을 자동으로 기록합니다.
allowed-tools: Read, Bash
argument-hint: [JIRA 티켓 키] [업데이트 내용]
---

# /jira-screen-update - 화면 구성 업데이트 및 이력 관리

JIRA 티켓 Description의 "화면 구성" 섹션을 업데이트하고, 변경 이력을 자동으로 추적합니다.

## 목적

- 화면 구성 변경 시 자동으로 이력 기록
- 언제, 누가, 무엇을 변경했는지 추적
- Figma 링크 연동 시 자동 업데이트
- 변경 이력 테이블 자동 관리

---

## 사용법

```bash
# 화면 구성 업데이트
/jira-screen-update CD-123 "좌측 네비게이션 메뉴 추가"

# Figma 링크와 함께 업데이트
/jira-screen-update CD-123 "프로필 헤더 디자인 변경" --figma https://www.figma.com/file/ABC123/...

# 여러 줄 업데이트
/jira-screen-update CD-123 "
- 상단 헤더 레이아웃 변경
- 버튼 위치 조정
- 색상 테마 업데이트
"
```

---

## 실행 프로토콜

### Step 1: 현재 Description 가져오기

```python
def get_ticket_description(jira_key):
    """
    JIRA 티켓의 현재 Description 가져오기
    """
    url = f"{JIRA_HOST}/rest/api/3/issue/{jira_key}"

    response = requests.get(
        url,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={"Content-Type": "application/json"}
    )

    if response.status_code != 200:
        raise Exception(f"Failed to fetch ticket: {response.status_code}")

    return response.json()['fields']['description']
```

---

### Step 2: 화면 구성 섹션 찾기

```python
def find_screen_section(description):
    """
    Description에서 "화면 구성" 섹션 찾기

    반환:
    - section_index: 화면 구성 헤더의 인덱스
    - table_index: 업데이트 이력 테이블의 인덱스
    - content: 현재 화면 구성 내용
    """
    content = description.get('content', [])

    section_index = None
    table_index = None
    screen_content = []

    in_screen_section = False

    for i, item in enumerate(content):
        # 화면 구성 헤더 찾기
        if item.get('type') == 'heading':
            heading_text = item['content'][0]['text'] if item.get('content') else ''

            if '화면 구성' in heading_text:
                section_index = i
                in_screen_section = True
                continue
            elif in_screen_section and item['attrs'].get('level') == 2:
                # 다음 섹션 시작
                in_screen_section = False

        # 화면 구성 섹션 내에서 테이블 찾기
        if in_screen_section and item.get('type') == 'table':
            # 테이블 헤더 확인 (날짜, 작성자, 변경 내용)
            first_row = item['content'][0] if item.get('content') else None
            if first_row:
                headers = [cell['content'][0]['content'][0]['text']
                          for cell in first_row['content'] if cell.get('content')]
                if '날짜' in headers and '작성자' in headers and '변경 내용' in headers:
                    table_index = i

        # 화면 구성 내용 수집
        if in_screen_section and item.get('type') in ['paragraph', 'bulletList']:
            screen_content.append(item)

    return section_index, table_index, screen_content
```

---

### Step 3: 업데이트 이력 행 추가

```python
def add_update_history(description, table_index, update_info):
    """
    업데이트 이력 테이블에 새 행 추가

    update_info:
    - date: 업데이트 날짜 (YYYY-MM-DD)
    - author: 작성자 이름
    - changes: 변경 내용
    - figma_link: Figma 링크 (선택)
    """
    content = description.get('content', [])

    if table_index is None:
        # 테이블이 없으면 생성
        table = create_history_table()
        # 화면 구성 섹션 다음에 삽입
        content.insert(section_index + 1, table)
        table_index = section_index + 1

    # 기존 테이블 가져오기
    table = content[table_index]

    # 새 행 생성
    new_row = {
        "type": "tableRow",
        "content": [
            {
                "type": "tableCell",
                "content": [{
                    "type": "paragraph",
                    "content": [{"type": "text", "text": update_info['date']}]
                }]
            },
            {
                "type": "tableCell",
                "content": [{
                    "type": "paragraph",
                    "content": [{"type": "text", "text": update_info['author']}]
                }]
            },
            {
                "type": "tableCell",
                "content": [{
                    "type": "paragraph",
                    "content": create_change_content(update_info)
                }]
            }
        ]
    }

    # 테이블에 행 추가 (헤더 다음에)
    table['content'].insert(1, new_row)

    return content

def create_change_content(update_info):
    """
    변경 내용 컨텐츠 생성 (Figma 링크 포함 가능)
    """
    content = [{"type": "text", "text": update_info['changes']}]

    # Figma 링크가 있으면 추가
    if update_info.get('figma_link'):
        content.append({"type": "text", "text": " | "})
        content.append({
            "type": "text",
            "text": "🔗 Figma",
            "marks": [{
                "type": "link",
                "attrs": {"href": update_info['figma_link']}
            }]
        })

    return content

def create_history_table():
    """
    업데이트 이력 테이블 생성
    """
    return {
        "type": "table",
        "content": [
            {
                "type": "tableRow",
                "content": [
                    {
                        "type": "tableHeader",
                        "content": [{
                            "type": "paragraph",
                            "content": [{"type": "text", "text": "날짜"}]
                        }]
                    },
                    {
                        "type": "tableHeader",
                        "content": [{
                            "type": "paragraph",
                            "content": [{"type": "text", "text": "작성자"}]
                        }]
                    },
                    {
                        "type": "tableHeader",
                        "content": [{
                            "type": "paragraph",
                            "content": [{"type": "text", "text": "변경 내용"}]
                        }]
                    }
                ]
            }
        ]
    }
```

---

### Step 4: 화면 구성 내용 업데이트

```python
def update_screen_content(description, section_index, table_index, new_content):
    """
    화면 구성 내용 업데이트

    new_content: 새로운 화면 구성 설명 (문자열 또는 리스트)
    """
    content = description.get('content', [])

    # 기존 화면 구성 내용 제거 (헤더와 테이블 사이)
    # section_index (화면 구성 헤더) 다음부터 table_index 전까지
    if table_index:
        del content[section_index + 1:table_index]
        # 인덱스 재조정
        table_index = section_index + 1

    # 새 내용 추가
    new_paragraphs = []

    if isinstance(new_content, str):
        # 줄바꿈으로 분리
        lines = new_content.strip().split('\n')
        for line in lines:
            if line.strip():
                new_paragraphs.append({
                    "type": "paragraph",
                    "content": [{"type": "text", "text": line.strip()}]
                })
    elif isinstance(new_content, list):
        # 리스트로 전달된 경우
        bullet_list = {"type": "bulletList", "content": []}
        for item in new_content:
            bullet_list["content"].append({
                "type": "listItem",
                "content": [{
                    "type": "paragraph",
                    "content": [{"type": "text", "text": item}]
                }]
            })
        new_paragraphs.append(bullet_list)

    # 화면 구성 헤더 다음에 삽입
    for i, para in enumerate(new_paragraphs):
        content.insert(section_index + 1 + i, para)

    return content
```

---

### Step 5: Description 업데이트

```python
def update_jira_description(jira_key, updated_description):
    """
    JIRA 티켓 Description 업데이트
    """
    url = f"{JIRA_HOST}/rest/api/3/issue/{jira_key}"

    update_data = {
        "fields": {
            "description": updated_description
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

### Step 6: 전체 업데이트 프로세스

```python
def screen_update(jira_key, changes, author=None, figma_link=None):
    """
    화면 구성 업데이트 메인 함수
    """
    # 1. 현재 Description 가져오기
    description = get_ticket_description(jira_key)

    # 2. 화면 구성 섹션 찾기
    section_index, table_index, current_content = find_screen_section(description)

    if section_index is None:
        print(f"⚠️ '화면 구성' 섹션을 찾을 수 없습니다.")
        return False

    # 3. 작성자 정보 가져오기 (제공되지 않은 경우 JIRA 사용자 정보 사용)
    if not author:
        author = get_current_jira_user()

    # 4. 업데이트 정보 생성
    update_info = {
        'date': datetime.now().strftime('%Y-%m-%d'),
        'author': author,
        'changes': changes,
        'figma_link': figma_link
    }

    # 5. 업데이트 이력 추가
    updated_content = add_update_history(description, table_index, update_info)

    # 6. 화면 구성 내용 업데이트 (선택)
    # updated_content = update_screen_content(description, section_index, table_index, new_screen_content)

    # 7. Description 업데이트
    description['content'] = updated_content
    success = update_jira_description(jira_key, description)

    if success:
        print(f"✅ 화면 구성 업데이트 완료: {jira_key}")
        print(f"   날짜: {update_info['date']}")
        print(f"   작성자: {update_info['author']}")
        print(f"   변경 내용: {changes}")
        if figma_link:
            print(f"   Figma: {figma_link}")
    else:
        print(f"❌ 업데이트 실패: {jira_key}")

    return success

def get_current_jira_user():
    """
    현재 JIRA 사용자 정보 가져오기
    """
    url = f"{JIRA_HOST}/rest/api/3/myself"

    response = requests.get(
        url,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={"Content-Type": "application/json"}
    )

    if response.status_code == 200:
        user = response.json()
        return user['displayName']
    else:
        return JIRA_EMAIL.split('@')[0]
```

---

## 출력 형식

### 성공 케이스

```
============================================
 화면 구성 업데이트
============================================

🎫 티켓: CD-123 "기능 노출 관리"

📝 업데이트 정보:
 • 날짜: 2025-12-30
 • 작성자: 디자이너A
 • 변경 내용: 좌측 네비게이션 메뉴 추가

🔗 Figma 링크: 있음
   https://www.figma.com/file/ABC123/...

✅ Description 업데이트 완료

업데이트 이력:
┌────────────┬──────────┬────────────────────────────────┐
│ 날짜       │ 작성자   │ 변경 내용                      │
├────────────┼──────────┼────────────────────────────────┤
│ 2025-12-30 │ 디자이너A│ 좌측 네비게이션 메뉴 추가 | 🔗 │
│ 2025-12-28 │ System   │ 최초 생성                      │
└────────────┴──────────┴────────────────────────────────┘

JIRA 티켓: https://wondermove-official.atlassian.net/browse/CD-123

============================================
```

---

## Figma 연동 자동 업데이트

`/jira-figma-sync` 명령어 실행 시 자동으로 화면 구성 업데이트:

```python
def figma_sync_with_screen_update(jira_key, figma_links):
    """
    Figma 동기화 시 화면 구성 업데이트 이력도 함께 추가
    """
    # 1. Figma Description 추가
    figma_section = create_figma_section(figma_links, figma_info_list)
    append_to_description(jira_key, figma_section)

    # 2. 화면 구성 업데이트 이력 추가
    for link in figma_links:
        changes = f"Figma 디자인 업데이트: {link['file_name']}"
        screen_update(
            jira_key,
            changes=changes,
            author=link['author'],
            figma_link=link['url']
        )
```

---

## 사용 예시

### 예시 1: 단순 텍스트 업데이트

```bash
/jira-screen-update CD-123 "좌측 네비게이션: Settings 메뉴 하위에 Function Exposure 추가"
```

**결과**:
```
날짜       | 작성자   | 변경 내용
-----------|----------|----------------------------------
2025-12-30 | 기획자A  | 좌측 네비게이션: Settings 메뉴...
2025-12-28 | System   | 최초 생성
```

### 예시 2: Figma 링크와 함께 업데이트

```bash
/jira-screen-update CD-123 "메인 테이블 컬럼 구조 변경" \
  --figma https://www.figma.com/file/ABC123/Function-Exposure
```

**결과**:
```
날짜       | 작성자   | 변경 내용
-----------|----------|----------------------------------
2025-12-30 | 디자이너B| 메인 테이블 컬럼 구조 변경 | 🔗 Figma
2025-12-29 | 기획자A  | 좌측 네비게이션...
```

### 예시 3: 여러 줄 업데이트

```bash
/jira-screen-update CD-123 "
화면 레이아웃 대폭 수정:
- 상단 헤더 재디자인
- 테이블 필터 추가
- Apply 버튼 위치 변경
"
```

---

## 자동화 옵션

### Figma 동기화 시 자동 업데이트

`.claude/integrations/jira_config.json`에 설정 추가:

```json
{
  "figma": {
    "auto_sync": true,
    "auto_update_screen": true,  // Figma 동기화 시 화면 구성 자동 업데이트
    "track_links": true
  }
}
```

---

## 에러 처리

| 에러 | 원인 | 해결 |
|------|------|------|
| 화면 구성 섹션 없음 | Description에 "화면 구성" 헤더 없음 | 티켓 Description에 화면 구성 섹션 추가 |
| JIRA 인증 실패 | API 토큰 오류 | `/jira-init` 재실행 |
| 권한 없음 | 티켓 수정 권한 부족 | JIRA 관리자 문의 |

---

## 연계 기능

- `/jira-push` - Worktree 동기화 시 화면 구성 포함
- `/jira-figma-sync` - Figma 링크 추가 시 자동 이력 업데이트
- `/ux design` - 화면 설계 시 화면 구성 자동 생성

---

## 베스트 프랙티스

### 1. 변경 내용 작성 규칙

명확하고 간결하게:

```
✅ 좋은 예:
"좌측 네비게이션: Settings > Function Exposure 추가"

❌ 나쁜 예:
"메뉴 수정"
```

### 2. 주기적인 업데이트

디자인 변경 시마다 즉시 기록:

```bash
# 디자인 변경 직후
/jira-screen-update CD-123 "..." --figma URL
```

### 3. Figma 링크 연동

가능하면 Figma 링크 포함:

```bash
# Figma 링크 포함
/jira-screen-update CD-123 "테이블 레이아웃 변경" \
  --figma https://www.figma.com/file/...
```

---

## 참조 파일

- `.claude/integrations/jira_config.json` - JIRA 설정
- `.claude-state/jira_mapping.json` - 매핑 정보
- `.claude/commands/jira-figma-sync.md` - Figma 연동

---

## API 문서

- **JIRA REST API**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- **ADF Spec**: https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/
