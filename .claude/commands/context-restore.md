---
description: 이전 세션의 컨텍스트를 복원하고 작업을 이어갑니다.
allowed-tools: Read, Bash
argument-hint: [--preview] [--history]
---

# /context-restore - 세션 컨텍스트 복원

이전 세션에서 저장된 컨텍스트를 복원하여 작업을 중단된 곳부터 이어갑니다.

## 사용법

```bash
# 최신 컨텍스트 복원
/context-restore

# 미리보기 (복원하지 않고 확인만)
/context-restore --preview

# 히스토리 조회
/context-restore --history

# 특정 세션 복원
/context-restore --session 20251230_150000
```

---

## 복원되는 정보

### 1. 작업 상태
- 진행 중이던 태스크
- 완료/대기 중인 태스크 목록
- 다음 수행할 작업 제안

### 2. JIRA 상태
- 프로젝트 코드
- 최근 생성된 티켓 ID
- 동기화 상태

### 3. 파일 컨텍스트
- 작업 중이던 파일 목록
- Git 상태
- 작업 디렉토리

### 4. 작업 흐름
- 마지막 작업 내용
- 중단된 지점
- 추천 다음 액션

---

## 실행 절차

### Step 1: 컨텍스트 파일 읽기

```python
import json
from pathlib import Path
from datetime import datetime

def load_session_context(session_id=None):
    """
    저장된 컨텍스트 파일 읽기
    """
    state_dir = Path('.claude-state')

    if session_id:
        # 특정 세션 복원
        context_file = state_dir / 'context-history' / f'context_{session_id}.json'
    else:
        # 최신 컨텍스트 복원
        context_file = state_dir / 'session-context.json'

    if not context_file.exists():
        return None

    with open(context_file, 'r', encoding='utf-8') as f:
        return json.load(f)

def list_context_history():
    """
    저장된 컨텍스트 히스토리 조회
    """
    history_dir = Path('.claude-state/context-history')

    if not history_dir.exists():
        return []

    contexts = []
    for file in sorted(history_dir.glob('context_*.json'), reverse=True):
        with open(file, 'r', encoding='utf-8') as f:
            context = json.load(f)
            contexts.append({
                "session_id": context['session_id'],
                "timestamp": context['timestamp'],
                "focus": context['user_context']['current_focus'],
                "tasks_in_progress": len(context['tasks']['in_progress'])
            })

    return contexts
```

### Step 2: 컨텍스트 표시

```python
def display_context(context, preview_mode=False):
    """
    복원된 컨텍스트를 사용자에게 표시
    """
    print("=" * 60)
    if preview_mode:
        print(" 🔍 세션 컨텍스트 미리보기")
    else:
        print(" 🔄 세션 컨텍스트 복원")
    print("=" * 60)

    # 세션 정보
    print(f"\n🆔 세션 ID: {context['session_id']}")
    print(f"📅 저장 시간: {context['timestamp']}")

    # 경과 시간 계산
    saved_time = datetime.fromisoformat(context['timestamp'])
    elapsed = datetime.now() - saved_time
    hours = int(elapsed.total_seconds() / 3600)
    minutes = int((elapsed.total_seconds() % 3600) / 60)

    if hours > 0:
        print(f"⏱️  경과 시간: {hours}시간 {minutes}분 전")
    else:
        print(f"⏱️  경과 시간: {minutes}분 전")

    # 작업 상태
    print("\n" + "-" * 60)
    print(" 📋 작업 상태")
    print("-" * 60)

    tasks = context['tasks']
    print(f"\n✅ 완료: {len(tasks['completed'])}개")
    for task in tasks['completed'][:3]:
        print(f"   • {task['title']}")
    if len(tasks['completed']) > 3:
        print(f"   ... 외 {len(tasks['completed']) - 3}개")

    print(f"\n🔄 진행 중: {len(tasks['in_progress'])}개")
    for task in tasks['in_progress']:
        print(f"   • {task['title']}")
        print(f"     Epic: {task['epic']}")

    print(f"\n⏳ 대기 중: {len(tasks['pending'])}개")
    for task in tasks['pending'][:3]:
        print(f"   • {task['title']}")
    if len(tasks['pending']) > 3:
        print(f"   ... 외 {len(tasks['pending']) - 3}개")

    # JIRA 상태
    if context['jira']['project_code']:
        print("\n" + "-" * 60)
        print(" 🎫 JIRA 상태")
        print("-" * 60)
        print(f"\n프로젝트 코드: {context['jira']['project_code']}")
        print(f"최근 티켓: {len(context['jira']['recent_tickets'])}개")

        if context['jira']['recent_tickets']:
            print("\n최근 생성된 티켓:")
            for ticket_id in context['jira']['recent_tickets'][-5:]:
                print(f"   • {ticket_id}")

    # 파일 상태
    if context['files']['changed_files']:
        print("\n" + "-" * 60)
        print(" 📄 변경된 파일")
        print("-" * 60)

        for file_info in context['files']['changed_files'][:5]:
            status_icon = "M" if file_info['status'] == 'M' else "A" if file_info['status'] == 'A' else "?"
            print(f"   [{status_icon}] {file_info['path']}")

        if len(context['files']['changed_files']) > 5:
            print(f"   ... 외 {len(context['files']['changed_files']) - 5}개")

    # 현재 작업 포커스
    print("\n" + "-" * 60)
    print(" 💡 마지막 작업 내용")
    print("-" * 60)
    print(f"\n{context['user_context']['current_focus']}")

    # 다음 액션 제안
    if not preview_mode:
        print("\n" + "=" * 60)
        print(" 🎯 추천 다음 액션")
        print("=" * 60)

        suggestions = generate_action_suggestions(context)
        for i, suggestion in enumerate(suggestions, 1):
            print(f"\n{i}. {suggestion['action']}")
            print(f"   이유: {suggestion['reason']}")

def generate_action_suggestions(context):
    """
    컨텍스트를 기반으로 다음 액션 제안
    """
    suggestions = []

    tasks = context['tasks']

    # 진행 중인 태스크가 있으면
    if tasks['in_progress']:
        task = tasks['in_progress'][0]
        suggestions.append({
            "action": f"'{task['title']}' 작업 계속하기",
            "reason": "마지막으로 진행 중이던 태스크입니다"
        })

    # 변경된 파일이 있으면
    if context['files']['changed_files']:
        suggestions.append({
            "action": "Git 커밋 및 푸시",
            "reason": f"{len(context['files']['changed_files'])}개의 변경된 파일이 있습니다"
        })

    # JIRA 동기화가 필요하면
    if context['jira']['project_code'] and tasks['completed']:
        suggestions.append({
            "action": "/jira-push 실행",
            "reason": f"{len(tasks['completed'])}개의 완료된 태스크를 JIRA에 동기화하세요"
        })

    # 대기 중인 태스크가 있으면
    if tasks['pending']:
        task = tasks['pending'][0]
        suggestions.append({
            "action": f"다음 태스크 시작: '{task['title']}'",
            "reason": "대기 중인 다음 작업입니다"
        })

    # 컨텍스트 저장이 오래되었으면
    saved_time = datetime.fromisoformat(context['timestamp'])
    elapsed_hours = (datetime.now() - saved_time).total_seconds() / 3600

    if elapsed_hours > 2:
        suggestions.append({
            "action": "/context-save 실행",
            "reason": "컨텍스트 저장이 오래되었습니다"
        })

    return suggestions[:3]  # 최대 3개만 제안
```

### Step 3: 히스토리 조회

```python
def display_history():
    """
    저장된 컨텍스트 히스토리 표시
    """
    contexts = list_context_history()

    if not contexts:
        print("저장된 컨텍스트 히스토리가 없습니다.")
        return

    print("=" * 70)
    print(" 📚 컨텍스트 히스토리")
    print("=" * 70)

    for i, ctx in enumerate(contexts, 1):
        saved_time = datetime.fromisoformat(ctx['timestamp'])
        time_str = saved_time.strftime('%Y-%m-%d %H:%M:%S')

        print(f"\n{i}. {ctx['session_id']}")
        print(f"   📅 {time_str}")
        print(f"   💡 {ctx['focus']}")
        print(f"   🔄 진행 중: {ctx['tasks_in_progress']}개")

    print("\n" + "=" * 70)
    print("\n복원하려면: /context-restore --session [세션ID]")
```

### Step 4: 실제 복원 수행

```python
def restore_context(context):
    """
    컨텍스트를 실제로 적용
    (정보를 표시하고 사용자가 작업을 이어갈 수 있도록 안내)
    """
    display_context(context, preview_mode=False)

    print("\n" + "=" * 60)
    print(" ✅ 컨텍스트 복원 완료!")
    print("=" * 60)
    print("\n위의 정보를 참고하여 작업을 계속하세요.")
    print("필요한 경우 `/ux status`로 현재 상태를 다시 확인할 수 있습니다.")

def main():
    """
    메인 실행 함수
    """
    import sys

    # 인자 파싱
    args = sys.argv[1:]

    if '--history' in args:
        display_history()
        return

    preview_mode = '--preview' in args

    session_id = None
    if '--session' in args:
        session_idx = args.index('--session')
        if session_idx + 1 < len(args):
            session_id = args[session_idx + 1]

    # 컨텍스트 로드
    context = load_session_context(session_id)

    if not context:
        print("❌ 저장된 컨텍스트를 찾을 수 없습니다.")
        print("\n먼저 /context-save 명령어로 컨텍스트를 저장하세요.")
        return

    # 미리보기 또는 복원
    if preview_mode:
        display_context(context, preview_mode=True)
    else:
        restore_context(context)

if __name__ == '__main__':
    main()
```

---

## 출력 형식

### 기본 복원

```
============================================================
 🔄 세션 컨텍스트 복원
============================================================

🆔 세션 ID: 20251230_150000
📅 저장 시간: 2025-12-30T15:00:00
⏱️  경과 시간: 3시간 30분 전

------------------------------------------------------------
 📋 작업 상태
------------------------------------------------------------

✅ 완료: 12개
   • JIRA 연동 구현
   • Figma 동기화 기능 추가
   • 문서 업데이트
   ... 외 9개

🔄 진행 중: 1개
   • 컨텍스트 복원 기능 구현
     Epic: 플러그인 코어 기능

⏳ 대기 중: 3개
   • 매뉴얼 생성 기능
   • 접근성 체커
   • 디자인 시스템 연동
   ... 외 0개

------------------------------------------------------------
 🎫 JIRA 상태
------------------------------------------------------------

프로젝트 코드: PLUGIN
최근 티켓: 8개

최근 생성된 티켓:
   • CD-269
   • CD-270
   • CD-271
   • CD-272
   • CD-273

------------------------------------------------------------
 📄 변경된 파일
------------------------------------------------------------

   [M] .claude/commands/context-save.md
   [A] .claude/commands/context-restore.md
   [M] README.md

------------------------------------------------------------
 💡 마지막 작업 내용
------------------------------------------------------------

컨텍스트 복원 기능 구현

============================================================
 🎯 추천 다음 액션
============================================================

1. '컨텍스트 복원 기능 구현' 작업 계속하기
   이유: 마지막으로 진행 중이던 태스크입니다

2. Git 커밋 및 푸시
   이유: 3개의 변경된 파일이 있습니다

3. /jira-push 실행
   이유: 12개의 완료된 태스크를 JIRA에 동기화하세요

============================================================
 ✅ 컨텍스트 복원 완료!
============================================================

위의 정보를 참고하여 작업을 계속하세요.
필요한 경우 `/ux status`로 현재 상태를 다시 확인할 수 있습니다.
```

### 히스토리 조회

```
======================================================================
 📚 컨텍스트 히스토리
======================================================================

1. 20251230_180000
   📅 2025-12-30 18:00:00
   💡 Confluence 자동 업데이트 구현
   🔄 진행 중: 1개

2. 20251230_150000
   📅 2025-12-30 15:00:00
   💡 Figma 연동 기능 추가
   🔄 진행 중: 2개

3. 20251230_120000
   📅 2025-12-30 12:00:00
   💡 JIRA 티켓 생성 및 동기화
   🔄 진행 중: 1개

======================================================================

복원하려면: /context-restore --session [세션ID]
```

---

## 사용 시나리오

### 시나리오 1: 세션 재시작 후

```bash
# Claude Code 재시작 후
/context-restore

# 출력: 이전 작업 내용과 추천 액션 표시
# 사용자는 추천 액션을 따라 작업 재개
```

### 시나리오 2: Compact 발생 후

```bash
# 컨텍스트가 압축된 후
/context-restore

# 모든 작업 상태와 JIRA 정보 복원
```

### 시나리오 3: 이전 버전으로 돌아가기

```bash
# 히스토리 조회
/context-restore --history

# 특정 세션 복원
/context-restore --session 20251230_120000
```

---

## 자동 복원

다음 상황에서 자동으로 컨텍스트 복원이 제안됩니다:

1. Claude Code 시작 시 (저장된 컨텍스트가 있으면)
2. `/ux` 명령어 실행 시 (컨텍스트가 없으면)
3. Compact 발생 후

---

## 베스트 프랙티스

### 1. 주기적 저장

중요 작업 후 컨텍스트 저장:

```bash
# JIRA 푸시 후
/jira-push
/context-save

# 중요 기능 완성 후
git commit -m "feat: 새 기능 추가"
/context-save
```

### 2. 작업 시작 시 복원

매 세션 시작 시 컨텍스트 복원:

```bash
# 작업 시작
/context-restore

# 상태 확인
/ux status

# 작업 재개
```

### 3. 히스토리 활용

실수로 작업을 놓쳤다면 이전 세션으로 복원:

```bash
/context-restore --history
/context-restore --session [세션ID]
```

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 컨텍스트를 찾을 수 없음 | 저장된 적 없음 | `/context-save` 먼저 실행 |
| 오래된 정보만 표시됨 | 최근 저장 안 함 | 주기적으로 `/context-save` 실행 |
| 히스토리가 비어있음 | 백업 파일 없음 | 정상 (첫 사용 시) |

---

## 관련 명령어

- `/context-save` - 현재 컨텍스트 저장
- `/ux status` - 현재 프로젝트 상태 확인
- `/jira-status` - JIRA 동기화 상태 확인

---

## 참조

- **저장 명령어**: `/context-save`
- **설정 파일**: `.claude/config.json`
- **상태 파일**: `.claude-state/session-context.json`
