---
name: figma-link-tracker
description: JIRA 티켓 작업 시 Figma 링크를 자동으로 추적하고 동기화합니다.
trigger_mode: keyword
triggers:
  - "figma"
  - "디자인"
  - "시안"
  - "화면 설계"
  - "UI"
  - "프로토타입"
auto_activate: true
---

# Figma Link Tracker Skill

JIRA 티켓 댓글에서 Figma 링크를 자동으로 감지하고, 티켓 Description에 디자인 업데이트 내용을 자동 추가합니다.

## 활성화 조건

다음 키워드가 포함된 작업 시 자동 활성화:
- "figma"
- "디자인"
- "시안"
- "화면 설계"
- "UI"
- "프로토타입"

## 주요 기능

### 1. Figma 링크 자동 감지

대화에서 Figma 링크가 언급되면 자동으로 감지:

```
사용자: "디자인 시안을 Figma에 올렸어요. https://www.figma.com/file/ABC123/User-Profile"

→ 자동 감지하여 처리 제안
```

### 2. JIRA 티켓 댓글 스캔

JIRA 티켓 작업 중 자동으로 댓글에서 Figma 링크 추출:

```python
def scan_for_figma_links(jira_key):
    """
    JIRA 티켓 댓글에서 Figma 링크 스캔
    """
    # 1. 댓글 가져오기
    comments = get_ticket_comments(jira_key)

    # 2. Figma 링크 패턴 매칭
    figma_pattern = r'https://(?:www\.)?figma\.com/(?:file|design)/([a-zA-Z0-9]+)'

    links = []
    for comment in comments:
        text = extract_text_from_adf(comment['body'])
        matches = re.findall(figma_pattern, text)
        links.extend(matches)

    return links
```

### 3. Description 자동 업데이트 제안

Figma 링크 발견 시 자동으로 Description 업데이트 제안:

```
💡 [Figma Link Tracker]

Figma 링크 2개를 발견했습니다:
1. User Profile Design v2
2. Profile Components

티켓 Description에 추가하시겠습니까?
→ /jira-figma-sync CD-123
```

---

## 작동 방식

### 패턴 1: 대화 중 Figma 링크 언급

```
사용자: "프로필 화면 디자인 완료했습니다. Figma 링크: https://..."
어시스턴트:
1. Figma 링크 자동 감지
2. 파일 ID 추출: ABC123
3. JIRA 티켓 연관 확인
4. Description 업데이트 제안
```

### 패턴 2: JIRA 티켓 작업 시

```
사용자: "/jira-push CD-123"

어시스턴트:
1. 티켓 동기화 완료
2. 댓글 스캔 시작...
3. Figma 링크 2개 발견
4. 자동으로 `/jira-figma-sync CD-123` 실행 제안
```

### 패턴 3: 화면 설계 작업 시

```
사용자: "/ux design 프로필 화면"

어시스턴트:
1. 화면 시안 제안 생성
2. "Figma에 업로드하시겠습니까?" 제안
3. 링크 입력 시 자동으로 JIRA 댓글/Description에 추가
```

---

## 자동 실행 로직

### 조건 1: Figma 링크 감지

```python
def should_activate(context):
    """
    스킬 활성화 조건 체크
    """
    # 1. Figma 링크 패턴 체크
    if re.search(r'figma\.com', context['message']):
        return True

    # 2. 키워드 체크
    keywords = ['figma', '디자인', '시안', '화면 설계', 'UI', '프로토타입']
    if any(kw in context['message'].lower() for kw in keywords):
        return True

    return False
```

### 조건 2: JIRA 티켓 컨텍스트

```python
def check_jira_context(context):
    """
    현재 JIRA 티켓 작업 중인지 확인
    """
    # Worktree에서 현재 작업 중인 티켓 확인
    current_context = load_current_context()

    if current_context.get('current_jira_ticket'):
        return current_context['current_jira_ticket']

    return None
```

---

## 제공 기능

### 1. Figma 링크 추출

```python
def extract_figma_links(text):
    """
    텍스트에서 Figma 링크 추출

    지원 형식:
    - https://www.figma.com/file/{id}/{name}
    - https://www.figma.com/design/{id}/{name}
    - https://www.figma.com/file/{id}?node-id={node}
    """
    pattern = r'https://(?:www\.)?figma\.com/(?:file|design)/([a-zA-Z0-9]+)/([^?\s]+)(?:\?.*?node-id=([^&\s]+))?'

    matches = re.finditer(pattern, text)

    links = []
    for match in matches:
        links.append({
            'file_id': match.group(1),
            'file_name': match.group(2).replace('-', ' ').replace('%20', ' '),
            'node_id': match.group(3) if match.group(3) else None,
            'url': match.group(0)
        })

    return links
```

### 2. Figma 파일 정보 가져오기

```python
def get_figma_info(file_id):
    """
    Figma API 또는 링크 파싱으로 파일 정보 가져오기
    """
    # Option A: Figma API (Token 있을 때)
    if FIGMA_ACCESS_TOKEN:
        try:
            return fetch_from_figma_api(file_id)
        except:
            pass

    # Option B: 링크 파싱 (Token 없을 때)
    return parse_figma_link(file_id)

def fetch_from_figma_api(file_id):
    """
    Figma REST API로 파일 정보 가져오기
    """
    url = f"https://api.figma.com/v1/files/{file_id}"
    headers = {"X-Figma-Token": FIGMA_ACCESS_TOKEN}

    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        raise Exception(f"Figma API error: {response.status_code}")

    data = response.json()

    return {
        'name': data['name'],
        'lastModified': data['lastModified'],
        'version': data['version'],
        'frames': extract_frames(data['document'])
    }
```

### 3. Frame 정보 추출

```python
def extract_frames(node, frames=None):
    """
    Figma 문서에서 Frame 목록 추출 (재귀)
    """
    if frames is None:
        frames = []

    # Frame 타입 체크
    if node.get('type') == 'FRAME':
        frames.append({
            'id': node['id'],
            'name': node['name'],
            'type': node['type'],
            'children_count': len(node.get('children', []))
        })

    # 자식 노드 재귀 탐색
    if 'children' in node:
        for child in node['children']:
            extract_frames(child, frames)

    return frames
```

### 4. JIRA Description 업데이트

```python
def update_jira_with_figma(jira_key, figma_links):
    """
    JIRA 티켓 Description에 Figma 정보 추가
    """
    # 1. Figma 정보 수집
    figma_info_list = []
    for link in figma_links:
        info = get_figma_info(link['file_id'])
        figma_info_list.append(info)

    # 2. ADF 형식으로 변환
    figma_section = create_figma_section_adf(figma_links, figma_info_list)

    # 3. Description 업데이트
    success = append_to_jira_description(jira_key, figma_section)

    return success
```

---

## 사용자 인터랙션

### 제안 형식

```
💡 [Figma Link Tracker]

Figma 링크를 발견했습니다:

📄 User Profile Design v2
   🔗 https://www.figma.com/file/ABC123/...
   📅 업데이트: 2025-12-29
   👤 작성자: 디자이너A

   Frame:
   • Profile Header
   • User Info Card
   • Settings Panel

다음 작업을 실행하시겠습니까?

1. /jira-figma-sync CD-123  (Description에 추가)
2. Skip (건너뛰기)
```

### 자동 실행 모드

사용자가 "자동 실행 모드"를 켜면 제안 없이 바로 실행:

```bash
# 자동 실행 모드 활성화
/ux config set figma-auto-sync true

# 이후 Figma 링크 발견 시 자동으로 JIRA에 추가
```

---

## 설정

### `.claude/integrations/jira_config.json`

```json
{
  "figma": {
    "auto_sync": false,
    "track_links": true,
    "update_on_comment": true,
    "api_enabled": true
  }
}
```

---

## 출력 예시

### Figma 링크 감지 시

```
🎨 [Figma Link Tracker]

새로운 디자인 링크를 발견했습니다!

📄 User Profile Redesign
   🔗 https://www.figma.com/file/ABC123/User-Profile
   📅 2025-12-29
   👤 디자이너A

Frame 목록:
 • Profile Header (1/10)
 • User Info Card (2/10)
 • Settings Panel (3/10)
 • ... 7개 더

현재 작업 중인 티켓: CD-123 "사용자 프로필 화면"

Description에 추가하시겠습니까?
→ Yes / No / Later
```

---

## 연계 기능

- `/jira-figma-sync` - 수동 동기화 명령어
- `/ux design` - 화면 설계 시 Figma 링크 자동 제안
- `/jira-push` - Worktree 동기화 시 Figma 링크도 함께 동기화

---

## 베스트 프랙티스

### 1. Figma 링크 작성 규칙

댓글 작성 시 다음 형식 권장:

```
✅ 좋은 예:
"프로필 화면 디자인 완료: https://www.figma.com/file/ABC123/User-Profile"

❌ 나쁜 예:
"디자인 완료 (Figma 참고)" (링크 없음)
```

### 2. Frame 명명 규칙

Figma에서 Frame 이름을 명확하게:

```
✅ 좋은 예:
- "Profile Header - Desktop"
- "User Info Card - Mobile"

❌ 나쁜 예:
- "Frame 1"
- "Untitled"
```

### 3. 정기 동기화

일주일에 한 번 전체 동기화 권장:

```bash
# 전체 Worktree 동기화
/jira-figma-sync --all
```

---

## API 제한사항

### Figma API

- **Rate Limit**: 시간당 100 requests
- **Token**: Personal Access Token 필요
- **권한**: View 권한 이상 필요

### 해결 방법

Token 없이도 기본 동작 가능:
- 링크 파싱으로 파일명, URL 추출
- Frame 목록은 표시되지 않음
- API 사용 시에만 상세 정보 제공

---

## 참조

- **Figma API 문서**: https://www.figma.com/developers/api
- **JIRA REST API**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- **명령어 문서**: `.claude/commands/jira-figma-sync.md`
