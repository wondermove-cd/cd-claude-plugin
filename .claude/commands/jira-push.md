---
description: Worktree 상태를 JIRA로 동기화합니다. 프로젝트 코드를 티켓 제목과 태그에 자동 추가합니다.
allowed-tools: Read, Write, Edit, Bash
argument-hint: [--force] [--dry-run]
---

# /jira-push

현재 Worktree 상태를 JIRA로 동기화합니다.
**프로젝트 코드가 티켓 제목 prefix와 태그로 자동 추가됩니다.**

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

Worktree 구조 파싱:
- Epic 목록
- Story 목록 (Epic 하위)
- Task 목록 (Story 하위)

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

#### 새 항목: JIRA 이슈 생성

```python
# Epic 생성
epic_result = connector.create_issue(
    issue_type='Epic',
    summary=format_title(epic['title'], project_code),  # 프로젝트 코드 추가
    description=epic.get('description', ''),
    labels=get_labels(project_code)  # 태그 추가
)

# Story 생성 (parent로 Epic 연결)
story_result = connector.create_issue(
    issue_type='Story',
    summary=format_title(story['title'], project_code),  # 프로젝트 코드 추가
    parent_key=epic_result['key'],
    labels=get_labels(project_code)  # 태그 추가
)

# Task 생성 (parent로 Story 연결)
task_result = connector.create_issue(
    issue_type='Task',
    summary=format_title(task['title'], project_code),  # 프로젝트 코드 추가
    parent_key=story_result['key'],
    labels=get_labels(project_code)  # 태그 추가
)
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
