# CD Claude Plugin - 종합 개선 제안서

> **현재 워크플로우 분석 및 MCP/Skill/Sub-Agent 활용 방안**

작성일: 2025-12-30
대상: UX/디자인팀 워크플로우 자동화

---

## 📊 현재 상태 분석

### 구현된 기능 (총 31개 파일)

**Commands (16개)**:
- UX 워크플로우: init, onboard, plan, design, tasks, manual-* (7개)
- JIRA 연동: init, push, status, figma-sync, screen-update (5개)
- 플러그인 관리: context-save/restore, plugin-update, confluence-sync (4개)

**Skills (6개)**:
- ux-writing, accessibility, design-system, handoff-spec, manual-template, figma-link-tracker, context-manager

**현재 워크플로우**:
```mermaid
graph LR
    A[/ux init] --> B[/ux plan]
    B --> C[/ux design]
    C --> D[/ux tasks]
    D --> E[/jira-push]
    E --> F[Figma 링크 추가]
    F --> G[/jira-figma-sync]
    G --> H[/context-save]
```

---

## 🔴 현재 Pain Points

### 1. **수동 실행이 많음**
- ❌ 각 명령어를 순차적으로 실행해야 함
- ❌ JIRA 댓글 → Figma 동기화 수동 트리거
- ❌ Confluence 업데이트 확인 필요

### 2. **외부 API 의존성**
- ❌ JIRA/Figma API 토큰 관리 번거로움
- ❌ API 호출 실패 시 에러 처리 미흡
- ❌ 토큰 만료 시 재설정 필요

### 3. **컨텍스트 단절**
- ❌ Compact 후 작업 맥락 손실
- ❌ 여러 명령어 실행 시 중간 결과 유실
- ❌ 세션 간 연속성 부족

### 4. **Python 스크립트 실행 복잡도**
- ❌ 명령어 문서에 Python 코드만 있음
- ❌ 실제 실행 가능한 스크립트 별도 관리 필요
- ❌ 코드 중복 (각 명령어마다 JIRA API 호출 코드 반복)

### 5. **변경사항 추적 한계**
- ❌ Figma 버전 diff 불가능 (API 한계)
- ❌ JIRA 티켓 변경 이력 추적 수동
- ❌ 디자인 변경 원인 추론 어려움

---

## 💡 개선 방안 (우선순위별)

---

## ⭐ Priority 1: MCP (Model Context Protocol) 활용

### 문제
현재 JIRA/Figma API를 직접 호출하면서:
- 토큰 관리 복잡
- API 호출 코드 중복
- 에러 처리 산재

### 해결: MCP Server 구축

```typescript
// .claude/mcp-servers/jira-server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "jira-mcp-server",
  version: "1.0.0",
}, {
  capabilities: {
    tools: {},
  },
});

// Tool: JIRA 티켓 생성
server.setRequestHandler("tools/call", async (request) => {
  if (request.params.name === "create_jira_ticket") {
    const { summary, description, issueType } = request.params.arguments;

    // JIRA API 호출 (토큰은 서버가 관리)
    const ticket = await createJiraTicket({
      project: process.env.JIRA_PROJECT_KEY,
      summary,
      description,
      issuetype: issueType
    });

    return {
      content: [{
        type: "text",
        text: `티켓 생성 완료: ${ticket.key}`
      }]
    };
  }
});

// Tool: Figma 프레임 정보 조회
server.setRequestHandler("tools/call", async (request) => {
  if (request.params.name === "get_figma_frame") {
    const { fileId, nodeId } = request.params.arguments;

    const frame = await getFigmaNode(fileId, nodeId);

    return {
      content: [{
        type: "text",
        text: JSON.stringify(frame, null, 2)
      }]
    };
  }
});
```

**MCP 설정 (.claude/mcp-config.json)**:
```json
{
  "mcpServers": {
    "jira": {
      "command": "node",
      "args": [".claude/mcp-servers/jira-server.js"],
      "env": {
        "JIRA_HOST": "${JIRA_HOST}",
        "JIRA_EMAIL": "${JIRA_EMAIL}",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
      }
    },
    "figma": {
      "command": "node",
      "args": [".claude/mcp-servers/figma-server.js"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "${FIGMA_ACCESS_TOKEN}"
      }
    }
  }
}
```

### 장점
✅ **토큰 중앙 관리**: MCP 서버에서 환경변수 한 번만 설정
✅ **코드 재사용**: 모든 명령어가 동일한 MCP tool 호출
✅ **에러 처리 통합**: MCP 서버에서 재시도, fallback 로직 구현
✅ **캐싱 가능**: Figma 파일 정보 캐싱으로 API 호출 감소

### 구현 예시
```bash
# Before (Python 스크립트)
python3 << 'EOF'
import requests
jira_response = requests.post(
    f"{JIRA_HOST}/rest/api/3/issue",
    auth=(JIRA_EMAIL, JIRA_API_TOKEN),
    json={...}
)
EOF

# After (MCP 사용)
mcp__jira create_jira_ticket \
  --summary "로그인 화면 개선" \
  --description "..." \
  --issueType "Task"
```

---

## ⭐ Priority 2: Sub-Agent 활용

### 문제
복잡한 multi-step 작업을 수동으로 관리:
- JIRA 푸시 → Figma 동기화 → Confluence 업데이트 (3단계)
- 각 단계마다 명령어 실행 필요
- 중간 실패 시 재시작 어려움

### 해결: 워크플로우 오케스트레이션 Agent

```markdown
# .claude/agents/ux-workflow-agent.md
---
name: ux-workflow-agent
description: UX 기획부터 JIRA 동기화까지 전체 워크플로우 자동화
tools: Read, Write, Bash, Task
---

## Agent 목적

사용자가 `/ux flow [기능명]` 한 번만 실행하면:
1. PRD 작성 (`/ux plan`)
2. 화면 설계 (`/ux design`)
3. 태스크 분해 (`/ux tasks`)
4. JIRA 푸시 (`/jira-push`)
5. Confluence 업데이트 (`/confluence-sync`)

**자동으로 수행**

## 실행 프로토콜

### Step 1: 워크플로우 계획 수립
사용자 입력: "로그인 화면 개선"

1. PROJECT_CONTEXT.md 읽어서 프로젝트 이해
2. 기존 UX_PATTERNS.md에서 유사 패턴 검색
3. 워크플로우 계획:
   - PRD 작성 (예상 시간: 2분)
   - 화면 설계 (예상 시간: 3분)
   - 태스크 분해 (예상 시간: 1분)
   - JIRA 푸시 (예상 시간: 30초)

### Step 2: 순차 실행

```python
# Pseudo-code
tasks = [
    {"name": "PRD 작성", "command": "/ux plan 로그인 화면 개선"},
    {"name": "화면 설계", "command": "/ux design"},
    {"name": "태스크 분해", "command": "/ux tasks"},
    {"name": "JIRA 푸시", "command": "/jira-push"}
]

for task in tasks:
    print(f"🔄 {task['name']} 진행 중...")
    result = execute_command(task['command'])

    if not result.success:
        print(f"❌ {task['name']} 실패: {result.error}")
        # 재시도 또는 스킵 여부 사용자에게 질문
        if not retry_or_skip(task):
            break

    print(f"✅ {task['name']} 완료")

    # 다음 단계로 컨텍스트 전달
    context[task['name']] = result.output

# 최종 요약
print("🎉 전체 워크플로우 완료!")
print(f"- PRD: docs/prd/로그인_화면_개선.md")
print(f"- 화면 설계: docs/design/로그인_화면_개선/")
print(f"- JIRA 티켓: CD-280 ~ CD-285 (6개)")
```

### Step 3: 에러 복구

중간 실패 시:
- 이전 단계 결과 저장 (`.claude-state/workflow-{timestamp}.json`)
- 실패 지점부터 재시작 옵션 제공
- 부분 완료 상태도 JIRA에 Draft로 저장
```

### 장점
✅ **원클릭 워크플로우**: 한 번에 전체 프로세스 완료
✅ **자동 재시도**: 실패 시 재시도 또는 스킵 로직
✅ **컨텍스트 유지**: 각 단계 결과를 다음 단계에 전달
✅ **중단 가능**: 언제든 멈추고 나중에 재개

---

## ⭐ Priority 3: Skill 자동화 확대

### 현재 Skill 활용도
- ✅ ux-writing: 키워드 감지 시 가이드라인 적용
- ✅ context-manager: JIRA 푸시 후 저장 제안
- ⚠️ **수동 트리거 많음**: Figma 링크 추가 후 직접 `/jira-figma-sync` 실행

### 개선: 이벤트 기반 Skill

#### 3-1. `jira-comment-watcher` Skill

```markdown
# .claude/skills/jira-comment-watcher/skill.md
---
name: jira-comment-watcher
description: JIRA 티켓에 댓글이 추가되면 자동으로 Figma 링크 감지 및 동기화
trigger: on-jira-comment-added
---

## 활성화 조건

1. `/jira-push` 실행 후 티켓이 생성되었을 때
2. 티켓 URL이 출력에 포함되어 있을 때

## 동작

### Step 1: JIRA Webhook 시뮬레이션

실제 webhook은 불가능하므로, 주기적으로 폴링:

```python
# 백그라운드에서 10분마다 실행
while True:
    recent_tickets = get_recent_jira_tickets(last_24_hours=True)

    for ticket in recent_tickets:
        comments = get_comments(ticket.key)

        for comment in comments:
            if has_figma_link(comment):
                print(f"💡 {ticket.key}에 Figma 링크 감지!")
                print(f"   /jira-figma-sync {ticket.key} 를 실행하시겠습니까? [Y/n]")

                if user_confirms():
                    execute_command(f"/jira-figma-sync {ticket.key}")

    sleep(600)  # 10분 대기
```

### Step 2: 자동 실행 모드

`.claude/config.json`에서 자동 실행 활성화:
```json
{
  "skills": {
    "jira-comment-watcher": {
      "enabled": true,
      "auto_sync": true,  // 확인 없이 바로 실행
      "poll_interval_minutes": 10
    }
  }
}
```
```

#### 3-2. `figma-version-tracker` Skill

```markdown
# .claude/skills/figma-version-tracker/skill.md
---
name: figma-version-tracker
description: Figma 파일 버전 변경 감지 및 자동 JIRA 업데이트
---

## 동작

### Figma Version History API 활용

```python
def track_figma_versions():
    """
    Figma 파일의 버전 변경사항을 추적하여 JIRA에 자동 반영
    """
    # 프로젝트에서 사용 중인 Figma 파일 목록
    figma_files = get_tracked_figma_files()

    for file_id in figma_files:
        # 마지막 확인 이후 버전 조회
        versions = get_figma_versions(file_id, since=last_check_time)

        if versions:
            print(f"📝 {file_id} 에 {len(versions)}개 버전 업데이트 감지")

            for version in versions:
                # 버전 설명에서 JIRA 티켓 키 추출 (예: "CD-279 로그인 개선")
                jira_key = extract_jira_key(version.description)

                if jira_key:
                    # 자동으로 해당 티켓에 업데이트 추가
                    add_figma_update_to_jira(
                        jira_key=jira_key,
                        version=version,
                        changes=version.description
                    )

                    print(f"✅ {jira_key}에 Figma 버전 {version.id} 업데이트 추가")
```
```

### 장점
✅ **완전 자동화**: 수동 트리거 제거
✅ **실시간 동기화**: 변경사항 즉시 반영
✅ **양방향 연동**: Figma ↔ JIRA 자동 동기화

---

## ⭐ Priority 4: 실행 가능한 스크립트 분리

### 문제
현재 명령어 파일(`.md`)에 Python 코드가 포함되어 있지만:
- 실행 시 복잡한 heredoc 필요
- 코드 재사용 어려움
- 디버깅 불편

### 해결: Scripts 폴더 구조화

```
.claude/
├── commands/          # Markdown 문서 (사용법 설명)
│   └── jira-push.md
├── scripts/           # 실행 가능한 스크립트 (NEW!)
│   ├── jira/
│   │   ├── push.py
│   │   ├── sync.py
│   │   └── figma_sync.py
│   ├── figma/
│   │   ├── get_frames.py
│   │   └── get_comments.py
│   └── utils/
│       ├── adf_builder.py    # ADF 포맷 생성
│       └── env_loader.py     # 환경변수 로드
└── lib/               # 공통 라이브러리 (NEW!)
    ├── jira_client.py
    └── figma_client.py
```

**명령어 파일 간소화**:
```markdown
# .claude/commands/jira-push.md

## 실행

bash
python3 .claude/scripts/jira/push.py


**스크립트가 알아서 처리**:
- 환경변수 로드
- JIRA API 호출
- 에러 처리
- 결과 출력
```

**공통 라이브러리**:
```python
# .claude/lib/jira_client.py
from .utils.env_loader import load_env

class JiraClient:
    def __init__(self):
        env = load_env()
        self.host = env['JIRA_HOST']
        self.email = env['JIRA_EMAIL']
        self.token = env['JIRA_API_TOKEN']

    def create_issue(self, summary, description, issue_type="Task"):
        """JIRA 티켓 생성 (재사용 가능)"""
        # ...

    def update_description(self, key, adf_content):
        """Description 업데이트"""
        # ...
```

### 장점
✅ **코드 재사용**: 여러 명령어에서 동일한 함수 호출
✅ **테스트 가능**: 각 스크립트 단위 테스트 작성
✅ **디버깅 편리**: IDE에서 직접 실행 및 디버깅
✅ **타입 안전성**: TypeScript/Python type hints 활용

---

## ⭐ Priority 5: 통합 대시보드

### 문제
현재 상태 파악을 위해 여러 명령어 실행 필요:
- `/jira-status`: JIRA 동기화 상태
- `/context-restore --preview`: 세션 상태
- `git status`: 파일 변경사항

### 해결: 단일 대시보드 명령어

```bash
/ux dashboard
```

**출력**:
```
╔══════════════════════════════════════════════════════════════╗
║  UX Project Dashboard - IDCX                                 ║
╚══════════════════════════════════════════════════════════════╝

📊 프로젝트 상태
  • 프로젝트 코드: IDCX
  • 마지막 업데이트: 2025-12-30 18:30

🎫 JIRA 동기화
  • 총 티켓: 15개
  • 최근 푸시: 2시간 전
  • Figma 연동: 8개 티켓
  ⚠️  CD-279: Figma 링크 동기화 필요

📝 진행 중인 작업
  • Worktree: 3개 Epic, 12개 Task
  • In Progress: 2개
  • To Do: 5개

📄 변경된 파일
  • .ux-docs/: 3개 수정
  • docs/prd/: 1개 신규
  ⚠️  Git commit 대기: 4개 파일

💾 세션 상태
  • 마지막 저장: 1시간 전
  💡 /context-save 실행 권장

🔗 빠른 액션
  [1] /jira-push          JIRA 동기화
  [2] /jira-figma-sync    Figma 업데이트
  [3] /context-save       컨텍스트 저장
  [4] /plugin-update      플러그인 업데이트
```

---

## 📋 구현 우선순위 및 로드맵

### Phase 1: 즉시 개선 가능 (1주)
1. ✅ **Scripts 폴더 구조화** (2일)
   - 공통 라이브러리 분리
   - 각 명령어별 실행 스크립트 작성
   - 환경변수 로더 통합

2. ✅ **통합 대시보드** (1일)
   - `/ux dashboard` 명령어 추가
   - 프로젝트 상태 한눈에 확인

3. ✅ **Skill 자동화 확대** (2일)
   - `jira-comment-watcher` 구현
   - 백그라운드 폴링 로직 추가

### Phase 2: MCP 도입 (2주)
1. **MCP Server 구축** (1주)
   - JIRA MCP Server
   - Figma MCP Server
   - 기존 Python 스크립트 → MCP tool 호출로 마이그레이션

2. **MCP 테스트 및 최적화** (1주)
   - 에러 처리 강화
   - 캐싱 로직 추가
   - API 호출 횟수 최적화

### Phase 3: Sub-Agent 워크플로우 (1주)
1. **ux-workflow-agent** (3일)
   - 전체 워크플로우 오케스트레이션
   - 에러 복구 로직

2. **Figma 버전 트래킹** (2일)
   - `figma-version-tracker` Skill
   - 양방향 동기화

---

## 💰 예상 효과

### Before (현재)
```
기능 기획 → JIRA 티켓 생성 → Figma 동기화 → Confluence 업데이트
  ↓           ↓              ↓              ↓
15분         5분 (수동)      5분 (수동)     3분 (수동)

= 총 28분
```

### After (개선 후)
```
/ux flow "기능명" 실행 → 전체 자동화 → 결과 확인
  ↓                       ↓           ↓
1분                      5분 (자동)   1분

= 총 7분 (75% 시간 절감!)
```

### 추가 효과
- ✅ **에러 감소**: 수동 입력 오류 제거
- ✅ **일관성 향상**: 모든 티켓이 동일한 포맷
- ✅ **추적성 강화**: 모든 변경사항 자동 기록
- ✅ **협업 강화**: 실시간 동기화로 팀 투명성 증대

---

## 🎯 최종 권장 사항

### 즉시 시작 (이번 주)
1. **Scripts 폴더 구조화** → 코드 재사용성 확보
2. **통합 대시보드** → 사용자 경험 개선
3. **JIRA Comment Watcher Skill** → 수동 트리거 제거

### 다음 스프린트 (2주 후)
1. **MCP Server 구축** → API 관리 중앙화
2. **Sub-Agent 워크플로우** → 원클릭 자동화

### 장기 (1개월 후)
1. **Figma Version Tracking** → 양방향 동기화
2. **AI 기반 변경사항 요약** → GPT-4 Vision으로 화면 diff 분석

---

## 📚 참고 자료

- **MCP 공식 문서**: https://modelcontextprotocol.io/
- **Claude Code Agent 가이드**: https://docs.claude.com/claude-code/agents
- **JIRA REST API v3**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- **Figma API**: https://www.figma.com/developers/api

---

**다음 액션**: 위 제안 중 우선순위가 높은 항목부터 구현 시작
