---
description: Worktree 상태를 JIRA로 동기화합니다. 프로젝트 코드를 티켓 제목과 태그에 자동 추가합니다.
allowed-tools: Read, Write, Edit, Bash
argument-hint: [--force] [--dry-run]
---

# /jira-push

현재 Worktree 상태를 JIRA로 동기화합니다.
**프로젝트(레이블) > 에픽 > 업무 > 하위 업무** 구조로 티켓을 생성합니다.

## 사용법

```bash
/jira-push              # 변경된 항목만 동기화
/jira-push --force      # 전체 강제 동기화
/jira-push --dry-run    # 실제 실행 없이 미리보기
```

## 사전 조건

1. **프로젝트 코드 설정** (필수)
   - `/ux project-code SKUBER` 실행
   - 미설정 시 자동으로 요청

2. **JIRA 연동 초기화**
   - `/jira-init` 완료
   - 환경변수 설정 (`JIRA_EMAIL`, `JIRA_API_TOKEN`)

3. **Worktree 데이터**
   - `worktree.json`에 데이터 존재

---

## 실행 프로토콜

### Step 0: 프로젝트 코드 확인

`.ux-docs/PROJECT_CONTEXT.md`에서 프로젝트 코드 로드:

```markdown
**프로젝트 코드**: SKUBER
```

**프로젝트 코드가 없는 경우**:

```
============================================
 [JIRA PUSH] 프로젝트 코드 필요
============================================

 ⚠️ 프로젝트 코드가 설정되지 않았습니다.

 프로젝트 코드는 JIRA 티켓 생성 시 다음과 같이 사용됩니다:
 • 제목: [{코드}] 티켓 제목
 • 태그: {코드}

 사용할 프로젝트 코드를 입력해주세요:
 (영문 대문자와 숫자만, 2-10자)

 예시: SKUBER, DCP, PLATFORM

 입력: _____

============================================
```

사용자 입력 받은 후:
1. 형식 검증 (영문 대문자, 숫자, 2-10자)
2. `PROJECT_CONTEXT.md` 업데이트
3. `jira_config.json` 업데이트
4. 진행 계속

---

### Step 1: 설정 및 매핑 로드

```python
from jira_connector import (
    JiraConnector, load_config, load_mapping,
    load_worktree, save_mapping
)

config = load_config()
project_code = config['jira'].get('project_code', '')  # 프로젝트 코드 로드

if not project_code:
    # Step 0으로 돌아가서 프로젝트 코드 요청
    pass

mapping = load_mapping()
worktree = load_worktree()

connector = JiraConnector(config)
```

---

### Step 2: Worktree 분석

Worktree 구조 파싱 (4단계 계층):

#### 계층 구조

1. **프로젝트** (레이블로 관리)
   - 가장 큰 단위, 모든 티켓에 레이블로 추가
   - 예: "SKUBER", "IDCX", "FLITE"

2. **에픽** (상위 항목)
   - 중/단기적 특정 목표를 가진 주요 업무 타이틀
   - 데일리 리포트에 표시되는 대표 단위
   - 예: "사용자 인증 시스템", "대시보드 개발", "결제 시스템"

3. **업무** (메인 티켓)
   - 실질적인 태스크 단위, 구체적 작업 내용
   - 에픽의 목표 달성을 위한 세부 단위
   - 시작/마감 기한 필수 등록
   - 예: "로그인 화면 퍼블리싱", "회원가입 API 구현"

4. **하위 업무** (서브 티켓)
   - 업무 수행을 위한 개인 to-do list
   - 데일리/위클리 리포트에 미노출
   - 예: "로그인 폼 컴포넌트 제작", "validation 로직 구현"

---

### Step 3: JIRA 동기화 (프로젝트 코드 적용)

#### 제목 포맷 함수

```python
def format_title(title, project_code):
    """
    티켓 제목에 프로젝트 코드 prefix 추가

    예시:
    - 원본: "클러스터 모니터링 기능"
    - 결과: "[SKUBER] 클러스터 모니터링 기능"
    """
    return f"[{project_code}] {title}"

def get_labels(project_code):
    """
    프로젝트 코드를 포함한 라벨 리스트 반환

    예시:
    - project_code: "SKUBER"
    - 결과: ["SKUBER"]
    """
    return [project_code]
```

#### 티켓 설명 생성 (상세 내용 필수!)

```python
def create_description(problem, requirements, solution, design_intent, screens, steps, result="작업 완료 후 업데이트 예정"):
    """
    JIRA 티켓 설명을 구조화하여 생성

    필수 섹션:
    1. 요구사항
    2. 해결방안
    3. 디자인 의도
    4. 화면 구성
    5. 작업 Step (ordered list)
    6. 결과
    """
    content = []

    # 요구사항
    content.append({
        "type": "heading",
        "attrs": {"level": 2},
        "content": [{"type": "text", "text": "요구사항"}]
    })
    bullet_list = {"type": "bulletList", "content": []}
    for req in requirements:
        bullet_list["content"].append({
            "type": "listItem",
            "content": [{"type": "paragraph", "content": [{"type": "text", "text": req}]}]
        })
    content.append(bullet_list)

    # 해결방안
    content.append({
        "type": "heading",
        "attrs": {"level": 2},
        "content": [{"type": "text", "text": "해결방안"}]
    })
    content.append({
        "type": "paragraph",
        "content": [{"type": "text", "text": solution}]
    })

    # 디자인 의도
    if design_intent:
        content.append({
            "type": "heading",
            "attrs": {"level": 2},
            "content": [{"type": "text", "text": "디자인 의도"}]
        })
        content.append({
            "type": "paragraph",
            "content": [{"type": "text", "text": design_intent}]
        })

    # 화면 구성
    if screens:
        content.append({
            "type": "heading",
            "attrs": {"level": 2},
            "content": [{"type": "text", "text": "화면 구성"}]
        })

        # 화면 구성 섹션 시작
        content.append({
            "type": "expand",
            "attrs": {"title": "화면 구성 상세"},
            "content": []
        })

        # 화면 구성 내용
        screen_content = []
        for screen in screens:
            screen_content.append({
                "type": "paragraph",
                "content": [{"type": "text", "text": screen}]
            })

        # 화면 구성 업데이트 이력 (처음에는 비어있음)
        content.append({
            "type": "panel",
            "attrs": {"panelType": "info"},
            "content": [{
                "type": "paragraph",
                "content": [{
                    "type": "text",
                    "text": "📝 화면 구성 업데이트 이력",
                    "marks": [{"type": "strong"}]
                }]
            }]
        })

        # 업데이트 이력 테이블 헤더
        content.append({
            "type": "table",
            "content": [
                {
                    "type": "tableRow",
                    "content": [
                        {"type": "tableHeader", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "날짜"}]}]},
                        {"type": "tableHeader", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "작성자"}]}]},
                        {"type": "tableHeader", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "변경 내용"}]}]}
                    ]
                },
                {
                    "type": "tableRow",
                    "content": [
                        {"type": "tableCell", "content": [{"type": "paragraph", "content": [{"type": "text", "text": datetime.now().strftime('%Y-%m-%d')}]}]},
                        {"type": "tableCell", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "System"}]}]},
                        {"type": "tableCell", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "최초 생성"}]}]}
                    ]
                }
            ]
        })

        # 실제 화면 구성 내용
        for screen in screens:
            content.append({
                "type": "paragraph",
                "content": [{"type": "text", "text": screen}]
            })

    # 작업 Step (ordered list)
    content.append({
        "type": "heading",
        "attrs": {"level": 2},
        "content": [{"type": "text", "text": "Step"}]
    })
    ordered_list = {"type": "orderedList", "content": []}
    for step in steps:
        ordered_list["content"].append({
            "type": "listItem",
            "content": [{"type": "paragraph", "content": [{"type": "text", "text": step}]}]
        })
    content.append(ordered_list)

    # 결과
    content.append({
        "type": "heading",
        "attrs": {"level": 2},
        "content": [{"type": "text", "text": "결과"}]
    })
    content.append({
        "type": "paragraph",
        "content": [{"type": "text", "text": result}]
    })

    return {"type": "doc", "version": 1, "content": content}
```

#### 새 항목: JIRA 이슈 생성

```python
# 프로젝트는 레이블로 관리
project_labels = [project_code]  # 예: ["SKUBER"]

# 에픽 생성 (중/단기 목표, 데일리 리포트에 표시)
epic_result = connector.create_issue(
    issue_type='에픽',
    summary=format_title(epic['title'], project_code),
    description=create_description(
        problem=epic.get('problem', '주요 목표 및 배경'),
        requirements=epic.get('requirements', ['달성해야 할 핵심 목표']),
        solution=epic.get('solution', '단계별 접근 방법'),
        design_intent=epic.get('design_intent', '전체적인 방향성'),
        screens=epic.get('screens', []),
        steps=epic.get('steps', ['기획', '디자인', '개발', '테스트', '배포']),
        result=epic.get('result', '목표 달성')
    ),
    labels=project_labels + ['epic']  # 프로젝트 레이블 추가
)

# 업무 생성 (실질적 태스크, 시작/마감 기한 필수)
# 예: "로그인 화면 퍼블리싱", "회원가입 API 구현"
task_result = connector.create_issue(
    issue_type='업무',
    summary=format_title(task['title'], project_code),
    description=create_description(
        problem=task.get('problem', '구현해야 할 기능'),
        requirements=task.get('requirements', ['기능 요구사항']),
        solution=task.get('solution', '구현 방법'),
        design_intent=task.get('design_intent', 'UI/UX 의도'),
        screens=task.get('screens', ['관련 화면']),
        steps=task.get('steps', ['작업 순서']),
        result=task.get('result', '기능 구현 완료')
    ),
    epic_link=epic_result['key'],  # 에픽 연결 (필수)
    labels=project_labels + ['task'],  # 프로젝트 레이블 추가
    start_date=task.get('start_date', ''),  # 시작 기한 (필수)
    due_date=task.get('due_date', ''),  # 마감 기한 (필수)
    story_points=task.get('story_points', 3)
)

# 하위 업무 생성 (개인 to-do, 리포트 미노출)
# 예: "로그인 컴포넌트 제작", "validation 로직 구현"
subtask_result = connector.create_issue(
    issue_type='하위 업무',
    summary=format_title(subtask['title'], project_code),
    description=create_description(
        problem=subtask.get('problem', '구현 세부사항'),
        requirements=subtask.get('requirements', ['세부 요구사항']),
        solution=subtask.get('solution', '구현 방법'),
        design_intent='',  # Sub-task는 디자인 의도 생략 가능
        screens=[],  # Sub-task는 화면 구성 생략 가능
        steps=subtask.get('steps', ['구현 단계']),
        result=subtask.get('result', '완료 조건')
    ),
    parent_key=task_result['key'],  # Task의 하위로 연결
    labels=get_labels(project_code) + ['subtask'],
    time_estimate=subtask.get('time_estimate', '2h')  # 예상 시간
)

# 완료된 항목은 Done으로 전환
if task['status'] == 'done':
    connector.transition_issue(task_result['key'], 'Done')
    # 완료일 설정 (오늘 날짜)
    connector.set_resolution_date(task_result['key'], datetime.now().strftime('%Y-%m-%d'))
```

**JIRA API 요청 예시**:

```json
{
  "fields": {
    "project": {"key": "PROJ"},
    "summary": "[SKUBER] 클러스터 모니터링 기능",
    "issuetype": {"name": "Task"},
    "parent": {"key": "PROJ-100"},
    "labels": ["SKUBER"]
  }
}
```

#### 기존 항목: 상태 업데이트

```python
# 매핑에서 JIRA 키 조회
jira_key = mapping['mappings'].get(task_id)

# 상태 동기화
if task['status'] == 'in_progress':
    connector.transition_issue(jira_key, 'In Progress')
elif task['status'] == 'done':
    connector.transition_issue(jira_key, 'Done')
elif task['status'] == 'blocked':
    connector.transition_issue(jira_key, 'Blocked')
    connector.add_comment(jira_key, f"🚫 블로커: {task.get('blocker', '')}")
```

---

### Step 4: 매핑 저장

```python
# 새로 생성된 매핑 추가
mapping['mappings'][worktree_id] = jira_key
mapping['reverse_mappings'][jira_key] = worktree_id
mapping['last_sync'] = datetime.now().isoformat()

save_mapping(mapping)
```

---

## 출력 형식

```
============================================
 JIRA 동기화 (Push)
============================================

 프로젝트 코드: SKUBER

 Worktree → JIRA:

 Epic:
 ✅ EPIC-001 → PROJ-100 "[SKUBER] 사용자 인증 시스템" (생성됨)

 Story:
 ✅ STORY-001 → PROJ-101 "[SKUBER] 회원가입" (생성됨)
 ✅ STORY-002 → PROJ-105 "[SKUBER] 로그인" (생성됨)

 Task:
 ✅ TASK-001 → PROJ-102 "[SKUBER] User 엔티티" (상태: In Progress)
 ✅ TASK-002 → PROJ-103 "[SKUBER] 회원가입 API" (상태: Done)
 ✅ TASK-003 → PROJ-104 "[SKUBER] 입력 검증" (생성됨)
 ⏭️ TASK-004 (변경 없음)

 태그: SKUBER (모든 티켓에 추가됨)

 요약:
 • 생성: 5개
 • 업데이트: 2개
 • 스킵: 1개
 • 에러: 0개

 JIRA 대시보드:
 https://company.atlassian.net/browse/PROJ

 💡 Tip:
 JIRA에서 "labels = SKUBER" 필터로 프로젝트별 티켓 조회 가능

============================================
```

---

## --dry-run 출력

```
============================================
 JIRA 동기화 미리보기 (Dry Run)
============================================

 프로젝트 코드: SKUBER

 실행 예정 작업:

 [CREATE] Epic "[SKUBER] 사용자 인증" → Epic 생성
          Tags: [SKUBER]

 [CREATE] Story "[SKUBER] 회원가입" → Story 생성 (parent: Epic)
          Tags: [SKUBER]

 [CREATE] Task "[SKUBER] User 엔티티" → Task 생성 (parent: Story)
          Tags: [SKUBER]

 [UPDATE] TASK-001 → PROJ-102 상태 변경: In Progress

 총 4개 작업 예정

 실제 실행: /jira-push

============================================
```

---

## 프로젝트 코드 활용 예시

### 예시 1: 단일 프로젝트

```bash
/ux project-code SKUBER
/jira-push
```

**JIRA 티켓**:
- `PROJ-100`: `[SKUBER] 클러스터 모니터링`
- `PROJ-101`: `[SKUBER] 알림 설정`
- Tags: `SKUBER`

### 예시 2: 다중 프로젝트 관리

**프로젝트 A**:
```bash
cd /project-a
/ux project-code PROJA
/jira-push
```

**프로젝트 B**:
```bash
cd /project-b
/ux project-code PROJB
/jira-push
```

**JIRA 필터**:
- 프로젝트 A 티켓: `labels = PROJA`
- 프로젝트 B 티켓: `labels = PROJB`
- 모든 티켓: `labels in (PROJA, PROJB)`

---

## 에러 처리

| 에러 | 원인 | 해결 |
|------|------|------|
| 프로젝트 코드 없음 | `/ux project-code` 미실행 | 프로젝트 코드 입력 또는 설정 |
| 형식 오류 | 잘못된 프로젝트 코드 형식 | 영문 대문자와 숫자만 사용 (2-10자) |
| JIRA 인증 실패 | API 토큰 오류 | 토큰 재생성 |
| 권한 없음 | 티켓 생성 권한 부족 | JIRA 관리자 문의 |

---

## 연계 동작

- `/ux tasks` 완료 후 자동 호출 가능 (설정 시)
- `/worktree done` 실행 시 자동 상태 동기화 (훅)

---

## 다음 단계

- `/jira-status` - 동기화 결과 확인
- `/jira-pull` - JIRA 변경사항 가져오기
- `/ux project-code` - 프로젝트 코드 변경

---

## 참조 파일

- `.ux-docs/PROJECT_CONTEXT.md` - 프로젝트 코드 저장
- `.claude/integrations/jira_config.json` - JIRA 설정
- `.claude-state/jira_mapping.json` - 매핑 정보
- `.claude-state/worktree.json` - Worktree 데이터
