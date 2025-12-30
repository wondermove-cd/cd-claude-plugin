---
description: 현재 세션의 컨텍스트를 저장합니다.
allowed-tools: Read, Write, Bash
argument-hint: [--auto]
---

# /context-save - 세션 컨텍스트 저장

현재 작업 중인 세션의 컨텍스트를 저장하여 나중에 복원할 수 있도록 합니다.

## 사용법

```bash
# 수동 저장
/context-save

# 자동 저장 모드 (주요 작업 후 자동 실행)
/context-save --auto
```

---

## 저장되는 정보

### 1. 작업 상태
- 현재 진행 중인 태스크
- 완료된 태스크 목록
- 대기 중인 태스크

### 2. JIRA 상태
- 최근 생성된 티켓 ID
- Worktree 동기화 상태
- 프로젝트 코드

### 3. 파일 변경사항
- 최근 수정된 파일 목록
- 작업 중인 기능 (예: "피그마 연동 구현")

### 4. 컨텍스트 메타데이터
- 마지막 저장 시간
- 세션 ID
- 사용자 최근 메시지

---

## 실행 절차

### Step 1: 현재 상태 수집

```python
import json
import os
from datetime import datetime
from pathlib import Path

def collect_session_context():
    """
    현재 세션의 모든 컨텍스트 수집
    """
    context = {
        "session_id": generate_session_id(),
        "timestamp": datetime.now().isoformat(),
        "tasks": collect_task_state(),
        "jira": collect_jira_state(),
        "files": collect_file_state(),
        "user_context": collect_user_context()
    }

    return context

def collect_task_state():
    """
    TodoWrite 도구로 관리되는 태스크 상태 수집
    """
    # TODO 리스트가 있다면 파싱
    tasks = {
        "in_progress": [],
        "completed": [],
        "pending": []
    }

    # 현재 작업 중인 내용 추출
    # (실제로는 TodoWrite 상태를 읽을 수 없으므로 worktree.json 참조)

    worktree_path = Path('.claude-state/worktree.json')
    if worktree_path.exists():
        with open(worktree_path, 'r', encoding='utf-8') as f:
            worktree = json.load(f)

        for epic in worktree.get('epics', []):
            for task in epic.get('tasks', []):
                status = task.get('status', 'pending')
                task_info = {
                    "title": task['title'],
                    "epic": epic['title'],
                    "status": status
                }

                if status == 'in_progress':
                    tasks['in_progress'].append(task_info)
                elif status == 'done':
                    tasks['completed'].append(task_info)
                else:
                    tasks['pending'].append(task_info)

    return tasks

def collect_jira_state():
    """
    JIRA 연동 상태 수집
    """
    jira_state = {
        "project_code": None,
        "recent_tickets": [],
        "last_sync": None
    }

    # PROJECT_CONTEXT.md에서 프로젝트 코드 읽기
    context_path = Path('.ux-docs/PROJECT_CONTEXT.md')
    if context_path.exists():
        with open(context_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # "프로젝트 코드: PLUGIN" 형태로 저장되어 있음
            import re
            match = re.search(r'프로젝트 코드:\s*(\w+)', content)
            if match:
                jira_state['project_code'] = match.group(1)

    # jira_mapping.json에서 최근 티켓 읽기
    mapping_path = Path('.claude-state/jira_mapping.json')
    if mapping_path.exists():
        with open(mapping_path, 'r', encoding='utf-8') as f:
            mappings = json.load(f)
            jira_state['recent_tickets'] = list(mappings.values())[-10:]
            jira_state['last_sync'] = datetime.now().isoformat()

    return jira_state

def collect_file_state():
    """
    최근 수정된 파일 상태 수집
    """
    import subprocess

    # Git으로 최근 변경 파일 확인
    try:
        result = subprocess.run(
            ['git', 'status', '--porcelain'],
            capture_output=True,
            text=True,
            check=True
        )

        changed_files = []
        for line in result.stdout.strip().split('\n'):
            if line:
                status = line[:2].strip()
                filepath = line[3:]
                changed_files.append({
                    "path": filepath,
                    "status": status
                })

        return {
            "changed_files": changed_files,
            "working_directory": os.getcwd()
        }
    except:
        return {
            "changed_files": [],
            "working_directory": os.getcwd()
        }

def collect_user_context():
    """
    사용자 컨텍스트 수집
    (실제로는 대화 내역을 알 수 없으므로 현재 상태만 기록)
    """
    return {
        "last_command": None,  # 마지막 실행 명령어 (추론 필요)
        "current_focus": infer_current_focus()
    }

def infer_current_focus():
    """
    현재 작업 중인 내용 추론
    """
    # worktree에서 in_progress 태스크 확인
    worktree_path = Path('.claude-state/worktree.json')
    if worktree_path.exists():
        with open(worktree_path, 'r', encoding='utf-8') as f:
            worktree = json.load(f)

        for epic in worktree.get('epics', []):
            for task in epic.get('tasks', []):
                if task.get('status') == 'in_progress':
                    return f"{epic['title']} > {task['title']}"

    # 최근 변경 파일로 추론
    import subprocess
    try:
        result = subprocess.run(
            ['git', 'log', '-1', '--pretty=%B'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except:
        return "알 수 없음"

def generate_session_id():
    """
    세션 ID 생성
    """
    from datetime import datetime
    return datetime.now().strftime('%Y%m%d_%H%M%S')
```

### Step 2: 컨텍스트 저장

```python
def save_context(context, auto=False):
    """
    컨텍스트를 파일로 저장
    """
    state_dir = Path('.claude-state')
    state_dir.mkdir(exist_ok=True)

    context_file = state_dir / 'session-context.json'

    # 기존 컨텍스트가 있으면 히스토리로 이동
    if context_file.exists():
        history_dir = state_dir / 'context-history'
        history_dir.mkdir(exist_ok=True)

        # 기존 파일을 타임스탬프로 백업
        with open(context_file, 'r', encoding='utf-8') as f:
            old_context = json.load(f)
            old_timestamp = old_context.get('timestamp', 'unknown')

        backup_file = history_dir / f"context_{old_timestamp.replace(':', '-')}.json"
        context_file.rename(backup_file)

    # 새 컨텍스트 저장
    with open(context_file, 'w', encoding='utf-8') as f:
        json.dump(context, f, indent=2, ensure_ascii=False)

    if not auto:
        print("=" * 50)
        print(" 💾 세션 컨텍스트 저장 완료")
        print("=" * 50)
        print(f"\n📅 저장 시간: {context['timestamp']}")
        print(f"🆔 세션 ID: {context['session_id']}")
        print(f"\n📋 진행 중인 작업: {len(context['tasks']['in_progress'])}개")
        print(f"✅ 완료된 작업: {len(context['tasks']['completed'])}개")
        print(f"⏳ 대기 중인 작업: {len(context['tasks']['pending'])}개")

        if context['jira']['project_code']:
            print(f"\n🎫 JIRA 프로젝트: {context['jira']['project_code']}")
            print(f"📝 최근 티켓: {len(context['jira']['recent_tickets'])}개")

        if context['files']['changed_files']:
            print(f"\n📄 변경된 파일: {len(context['files']['changed_files'])}개")

        print(f"\n💡 현재 작업: {context['user_context']['current_focus']}")
        print("\n다음 세션에서 /context-restore 로 복원하세요.")

def main():
    """
    메인 실행 함수
    """
    import sys

    auto_mode = '--auto' in sys.argv

    context = collect_session_context()
    save_context(context, auto=auto_mode)

    if auto_mode:
        print("✓ 컨텍스트 자동 저장 완료")

if __name__ == '__main__':
    main()
```

---

## 출력 형식

```
==================================================
 💾 세션 컨텍스트 저장 완료
==================================================

📅 저장 시간: 2025-12-30T18:30:00
🆔 세션 ID: 20251230_183000

📋 진행 중인 작업: 1개
✅ 완료된 작업: 12개
⏳ 대기 중인 작업: 3개

🎫 JIRA 프로젝트: PLUGIN
📝 최근 티켓: 8개

📄 변경된 파일: 5개

💡 현재 작업: 컨텍스트 복원 기능 구현

다음 세션에서 /context-restore 로 복원하세요.
```

---

## 자동 저장 트리거

다음 상황에서 자동으로 컨텍스트가 저장됩니다:

1. `/jira-push` 실행 후
2. `/ux tasks` 완료 후
3. 중요 파일 변경 후 (예: worktree.json, PROJECT_CONTEXT.md)
4. Git push 전 (post-commit hook)

---

## 저장 위치

```
.claude-state/
├── session-context.json          # 최신 컨텍스트
└── context-history/               # 이전 컨텍스트 백업
    ├── context_20251230_150000.json
    ├── context_20251230_160000.json
    └── context_20251230_170000.json
```

---

## 참조

- **복원 명령어**: `/context-restore`
- **컨텍스트 조회**: `/ux status`
- **설정 파일**: `.claude/config.json`
