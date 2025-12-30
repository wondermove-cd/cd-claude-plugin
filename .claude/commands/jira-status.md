---
description: JIRA 연동 상태 및 동기화 현황을 확인합니다.
allowed-tools: Read, Bash
argument-hint:
---

# /jira-status - JIRA 상태 확인

JIRA 연동 상태, 동기화 현황, 매핑 정보를 확인합니다.

## 사용법

```bash
/jira-status        # 전체 상태 확인
```

---

## 실행 절차

### Step 1: 설정 파일 로드

```bash
# JIRA 설정
cat .claude/integrations/jira_config.json

# 매핑 정보
cat .claude-state/jira_mapping.json

# Worktree
cat .claude-state/worktree.json
```

---

### Step 2: JIRA 연결 상태 확인

```bash
# JIRA API 연결 테스트
curl -s -o /dev/null -w "%{http_code}" \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_HOST/rest/api/3/myself"
```

**결과**:
- `200`: ✅ 연결 정상
- `401`: ❌ 인증 실패
- `403`: ❌ 권한 없음
- `timeout`: ❌ 네트워크 오류

---

### Step 3: 동기화 현황 분석

#### 매핑 통계

```python
mapping = load_mapping()

total_mappings = len(mapping['mappings'])
last_sync = mapping.get('last_sync', 'Never')
sync_history_count = len(mapping.get('sync_history', []))
```

#### Worktree vs JIRA 비교

```python
worktree = load_worktree()

# Worktree 항목 수 (Epic > Task > Subtask 구조)
worktree_epics = len(worktree['epics'])
worktree_tasks = sum(len(epic['tasks']) for epic in worktree['epics'])
worktree_subtasks = sum(
    len(task['subtasks'])
    for epic in worktree['epics']
    for task in epic['tasks']
)

# JIRA 동기화된 항목 수
synced_count = total_mappings
not_synced_count = (worktree_epics + worktree_tasks + worktree_subtasks) - synced_count
```

---

## 출력 형식

```
============================================
 JIRA 연동 상태
============================================

🔗 연결 상태
 ✅ JIRA 연결: 정상
 • Host: https://wondermove-official.atlassian.net
 • 프로젝트: CD (Creative & Design)
 • 사용자: vision@wondermove.net
 • 마지막 확인: 2025-12-30 15:45:30

📊 동기화 현황
 • 마지막 동기화: 2025-12-30 14:30:00 (1시간 전)
 • 총 매핑: 12개
 • 동기화 이력: 5회

📦 Worktree 현황
 • Epic: 1개
 • Task: 2개
 • Subtask: 7개
 • 총: 10개

✅ JIRA 동기화 완료: 10개 (100%)
 • Epic: 1개 ✅
 • Task: 2개 ✅
 • Subtask: 7개 ✅

⏳ 동기화 대기: 0개

---

🎫 최근 생성된 티켓

1. CD-105: [SKUBER] E2E 테스트 작성
   상태: To Do
   생성: 2025-12-30 14:30
   https://wondermove-official.atlassian.net/browse/CD-105

2. CD-104: [SKUBER] API 연동
   상태: In Progress
   생성: 2025-12-30 14:28
   https://wondermove-official.atlassian.net/browse/CD-104

3. CD-103: [SKUBER] 회원가입 폼 UI 구현
   상태: Done
   생성: 2025-12-30 14:25
   https://wondermove-official.atlassian.net/browse/CD-103

---

💡 다음 작업

• 변경사항 동기화: /jira-push
• JIRA 변경사항 가져오기: /jira-pull (미구현)
• 프로젝트 코드 변경: /ux project-code

============================================
```

---

## 에러 상태 출력

### JIRA 연결 실패

```
============================================
 JIRA 연동 상태
============================================

❌ JIRA 연결: 실패

오류: 401 Unauthorized

원인:
API 토큰이 만료되었거나 잘못되었습니다.

해결 방법:
1. 새 API 토큰 생성:
   https://id.atlassian.com/manage-profile/security/api-tokens

2. 환경변수 업데이트:
   export JIRA_API_TOKEN="new-token"
   source ~/.zshrc

3. 재연결 테스트:
   /jira-init CD

============================================
```

---

### 동기화되지 않은 항목 있음

```
============================================
 JIRA 연동 상태
============================================

🔗 연결 상태: ✅ 정상

📊 동기화 현황
 • 마지막 동기화: 2025-12-30 10:00:00 (5시간 전)
 • 총 매핑: 7개

📦 Worktree 현황
 • Epic: 1개
 • Task: 2개
 • Subtask: 7개
 • 총: 10개

⚠️ 동기화 필요: 3개

동기화되지 않은 항목:
 • SUBTASK-008: 회원가입 이메일 발송
 • SUBTASK-009: 비밀번호 암호화 강화
 • SUBTASK-010: 로그 추가

💡 동기화 실행: /jira-push

============================================
```

---

## 상세 정보 (선택)

### 매핑 테이블

```
매핑 상세:

Worktree ID     | JIRA Key | 타입     | 상태        | 동기화 시간
----------------|----------|----------|-------------|------------------
EPIC-001        | CD-100   | Epic     | To Do       | 2025-12-30 14:20
TASK-001        | CD-101   | Task     | In Progress | 2025-12-30 14:22
SUBTASK-001     | CD-102   | Subtask  | Done        | 2025-12-30 14:25
SUBTASK-002     | CD-103   | Subtask  | Done        | 2025-12-30 14:27
SUBTASK-003     | CD-104   | Subtask  | In Progress | 2025-12-30 14:28
...
```

---

### 동기화 이력

```
동기화 이력:

# 5. 2025-12-30 14:30:00
   작업: Push
   결과: 3개 생성, 2개 업데이트

# 4. 2025-12-30 12:00:00
   작업: Push
   결과: 5개 생성

# 3. 2025-12-29 16:30:00
   작업: Push
   결과: 2개 생성

...
```

---

## 프로젝트 코드 정보

```
프로젝트 코드: SKUBER

사용 현황:
• 모든 티켓 제목에 [SKUBER] prefix 적용
• 모든 티켓에 "SKUBER" 태그 추가

JIRA 필터:
• 이 프로젝트 티켓만 보기:
  labels = SKUBER

• JQL 쿼리:
  project = CD AND labels = SKUBER

변경: /ux project-code NEW_CODE
```

---

## 빠른 확인 모드

간략한 상태만 표시:

```
JIRA: ✅  |  동기화: 10/10  |  대기: 0  |  마지막: 1시간 전
```

---

## 참조 파일

- `.claude/integrations/jira_config.json` - JIRA 설정
- `.claude-state/jira_mapping.json` - 매핑 정보
- `.claude-state/worktree.json` - Worktree
- `.ux-docs/PROJECT_CONTEXT.md` - 프로젝트 코드
