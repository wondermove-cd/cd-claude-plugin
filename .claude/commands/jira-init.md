---
description: JIRA 연동을 초기화하고 연결을 테스트합니다.
allowed-tools: Read, Write, Edit, Bash
argument-hint: [JIRA_PROJECT_KEY]
---

# /jira-init - JIRA 연동 초기화

JIRA 연동을 설정하고 연결을 테스트합니다.

## 사용법

```bash
/jira-init CD              # CD 프로젝트 키로 초기화
/jira-init                 # 대화형으로 프로젝트 키 입력
```

---

## 사전 준비

### 1. 환경변수 설정 (필수)

사용자의 `.bashrc` 또는 `.zshrc`에 다음 추가:

```bash
# JIRA 연동 설정
export JIRA_HOST="https://wondermove-official.atlassian.net"
export JIRA_EMAIL="your-email@wondermove.net"
export JIRA_API_TOKEN="your-api-token"
```

**API 토큰 생성 방법**:
1. https://id.atlassian.com/manage-profile/security/api-tokens 접속
2. "Create API token" 클릭
3. Name: `Claude Code - {본인이름}`
4. 토큰 복사 (한 번만 표시됨!)
5. 위 환경변수에 붙여넣기

**적용**:
```bash
source ~/.zshrc  # 또는 source ~/.bashrc
```

---

## 실행 절차

### Step 1: 환경변수 확인

```bash
echo "JIRA_HOST: $JIRA_HOST"
echo "JIRA_EMAIL: $JIRA_EMAIL"
echo "JIRA_API_TOKEN: ${JIRA_API_TOKEN:0:20}..." # 앞 20자만 표시
```

**환경변수 없는 경우**:

```
============================================
 [JIRA INIT] 환경변수 설정 필요
============================================

 ❌ JIRA 환경변수가 설정되지 않았습니다.

 다음 환경변수를 설정해주세요:

 1. 터미널에서 실행:
    echo 'export JIRA_HOST="https://wondermove-official.atlassian.net"' >> ~/.zshrc
    echo 'export JIRA_EMAIL="your-email@wondermove.net"' >> ~/.zshrc
    echo 'export JIRA_API_TOKEN="your-token"' >> ~/.zshrc
    source ~/.zshrc

 2. API 토큰 생성:
    https://id.atlassian.com/manage-profile/security/api-tokens

 설정 후 다시 실행해주세요: /jira-init

============================================
```

**진행 중단** - 환경변수 설정 후 재실행 요청

---

### Step 2: 프로젝트 키 확인

**Arguments에서 프로젝트 키 확인** 또는 대화형 입력:

```markdown
JIRA 프로젝트 키를 입력해주세요:
(예: CD, SKUBER, PLATFORM)

> _____
```

---

### Step 3: JIRA 연결 테스트

```bash
# JIRA API 호출로 프로젝트 존재 확인
curl -s \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_HOST/rest/api/3/project/$JIRA_PROJECT_KEY"
```

**성공 시**:
```json
{
  "id": "10001",
  "key": "CD",
  "name": "Creative & Design",
  "projectTypeKey": "software"
}
```

**실패 시**:
- 401: API 토큰 오류
- 403: 권한 없음
- 404: 프로젝트 키 오류

---

### Step 4: 설정 파일 생성

#### 4.1. jira_config.json 생성

```json
{
  "jira": {
    "host": "$JIRA_HOST",
    "project_key": "CD",
    "issue_types": {
      "epic": "Epic",
      "story": "Story",
      "task": "Task"
    },
    "transitions": {
      "todo": "To Do",
      "in_progress": "In Progress",
      "done": "Done",
      "blocked": "Blocked"
    },
    "custom_fields": {
      "project_code_field": "customfield_10001"
    }
  },
  "worktree": {
    "default_priority": "P1",
    "auto_sync": false
  },
  "created_at": "2025-12-30T15:30:00Z",
  "last_tested": "2025-12-30T15:30:00Z"
}
```

**저장 위치**: `.claude/integrations/jira_config.json`

#### 4.2. jira_mapping.json 초기화

```json
{
  "mappings": {},
  "reverse_mappings": {},
  "last_sync": null,
  "sync_history": []
}
```

**저장 위치**: `.claude-state/jira_mapping.json`

---

### Step 5: 권한 테스트

#### 5.1. 테스트 이슈 생성 (선택)

```bash
# 테스트 Epic 생성
curl -s -X POST \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": {"key": "CD"},
      "summary": "[TEST] Claude Code 연동 테스트",
      "description": "JIRA 연동 테스트용 Epic입니다. 삭제해도 됩니다.",
      "issuetype": {"name": "Epic"},
      "labels": ["claude-code-test"]
    }
  }' \
  "$JIRA_HOST/rest/api/3/issue"
```

**성공 응답**:
```json
{
  "id": "10100",
  "key": "CD-100",
  "self": "https://wondermove-official.atlassian.net/rest/api/3/issue/10100"
}
```

테스트 성공 시:
```
✅ 테스트 Epic 생성: CD-100
   https://wondermove-official.atlassian.net/browse/CD-100
   (이 티켓은 삭제하셔도 됩니다)
```

---

### Step 6: PROJECT_CONTEXT.md 업데이트

```markdown
## JIRA 연동

**상태**: ✅ 연동 완료
**프로젝트 키**: CD
**마지막 테스트**: 2025-12-30T15:30:00Z

### JIRA 설정

- **Host**: https://wondermove-official.atlassian.net
- **프로젝트**: Creative & Design (CD)
- **사용 가능한 이슈 타입**: Epic, Story, Task
```

---

## 완료 보고

```
============================================
 [JIRA INIT] 연동 완료
============================================

 ✅ JIRA 연결 성공

 JIRA 정보:
 • Host: https://wondermove-official.atlassian.net
 • 프로젝트: CD (Creative & Design)
 • 이메일: vision@wondermove.net

 생성된 파일:
 ✅ .claude/integrations/jira_config.json
 ✅ .claude-state/jira_mapping.json
 ✅ .ux-docs/PROJECT_CONTEXT.md (업데이트)

 권한 확인:
 ✅ 프로젝트 조회 - OK
 ✅ 이슈 생성 - OK
 ✅ 이슈 수정 - OK

 테스트 티켓:
 https://wondermove-official.atlassian.net/browse/CD-100
 (삭제하셔도 됩니다)

 다음 단계:
 1. 프로젝트 코드 설정: /ux project-code SKUBER
 2. 기획 시작: /ux plan "기능명"
 3. 태스크 생성: /ux tasks
 4. JIRA 동기화: /jira-push

============================================
```

---

## 에러 처리

### 환경변수 없음

```
❌ 환경변수 JIRA_EMAIL이 설정되지 않았습니다.

해결 방법:
1. 터미널에서 실행:
   export JIRA_EMAIL="your-email@wondermove.net"

2. 영구 설정 (권장):
   echo 'export JIRA_EMAIL="your-email@wondermove.net"' >> ~/.zshrc
   source ~/.zshrc
```

### API 토큰 오류 (401)

```
❌ JIRA 인증 실패 (401 Unauthorized)

원인: API 토큰이 만료되었거나 잘못되었습니다.

해결 방법:
1. 새 API 토큰 생성:
   https://id.atlassian.com/manage-profile/security/api-tokens

2. 환경변수 업데이트:
   export JIRA_API_TOKEN="new-token"
```

### 권한 없음 (403)

```
❌ JIRA 권한 부족 (403 Forbidden)

원인: CD 프로젝트에 대한 권한이 없습니다.

해결 방법:
JIRA 관리자에게 CD 프로젝트 접근 권한 요청
```

### 프로젝트 키 오류 (404)

```
❌ JIRA 프로젝트를 찾을 수 없습니다 (404 Not Found)

입력한 프로젝트 키: XYZ

해결 방법:
1. JIRA에서 프로젝트 키 확인:
   https://wondermove-official.atlassian.net/jira/projects

2. 올바른 프로젝트 키로 재실행:
   /jira-init CD
```

---

## 환경변수 확인 방법

```bash
# 모든 JIRA 환경변수 확인
env | grep JIRA

# 개별 확인
echo $JIRA_HOST
echo $JIRA_EMAIL
echo $JIRA_API_TOKEN
```

---

## 팀원 온보딩 체크리스트

새 팀원이 JIRA 연동 설정 시:

- [ ] API 토큰 생성
- [ ] 환경변수 설정 (.zshrc 또는 .bashrc)
- [ ] 터미널 재시작 또는 source 실행
- [ ] `/jira-init CD` 실행
- [ ] 테스트 티켓 확인

---

## 참조

- **JIRA REST API 문서**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- **API 토큰 관리**: https://id.atlassian.com/manage-profile/security/api-tokens
- **팀 JIRA**: https://wondermove-official.atlassian.net
