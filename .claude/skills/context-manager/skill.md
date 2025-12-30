---
name: context-manager
description: 중요 작업 후 자동으로 세션 컨텍스트 저장을 제안합니다.
trigger:
  - after-command
keywords:
  - jira-push
  - git push
  - worktree
  - task complete
  - 완료
---

# Context Manager Skill

세션 컨텍스트를 자동으로 관리하여 작업 중단 시에도 쉽게 복원할 수 있도록 합니다.

## 활성화 조건

다음 상황에서 자동으로 활성화됩니다:

### 1. JIRA 푸시 후
- `/jira-push` 명령어 실행 완료
- 여러 티켓이 생성되었을 때

### 2. Git Push 후
- `git push` 명령어 실행 완료
- 여러 파일이 커밋되었을 때

### 3. 중요 작업 완료
- Worktree 업데이트 (Epic/Task 추가)
- 여러 태스크 완료 표시
- 새 기능 문서 작성 완료

### 4. 세션 시작 시
- Claude Code 재시작 감지
- 저장된 컨텍스트가 있을 때

## 동작 방식

### 자동 저장 제안

중요 작업 후 자동으로 저장을 제안합니다:

```
✅ [작업] 완료!

💡 컨텍스트를 저장하시겠습니까?

다음 세션에서 /context-restore 로 작업을 이어갈 수 있습니다.

실행: /context-save
```

### 복원 제안

세션 시작 시 저장된 컨텍스트가 있으면:

```
💾 저장된 세션 컨텍스트를 발견했습니다.

📅 저장 시간: 2025-12-30 15:00:00 (3시간 전)
💡 마지막 작업: Figma 연동 기능 추가

복원하시겠습니까?

실행: /context-restore
```

## 구현 로직

### 1. 저장 트리거 감지

```python
def should_suggest_save(last_command, changed_files):
    """
    컨텍스트 저장을 제안해야 하는지 확인
    """
    # JIRA 푸시 후
    if last_command == 'jira-push':
        return True

    # Git push 후
    if last_command.startswith('git push'):
        return True

    # Worktree 변경
    if '.claude-state/worktree.json' in changed_files:
        return True

    # 여러 문서 파일 변경
    doc_files = [f for f in changed_files if f.endswith('.md')]
    if len(doc_files) >= 3:
        return True

    return False
```

### 2. 세션 시작 감지

```python
def check_saved_context():
    """
    저장된 컨텍스트가 있는지 확인
    """
    from pathlib import Path
    import json
    from datetime import datetime

    context_file = Path('.claude-state/session-context.json')

    if not context_file.exists():
        return None

    with open(context_file, 'r', encoding='utf-8') as f:
        context = json.load(f)

    # 경과 시간 계산
    saved_time = datetime.fromisoformat(context['timestamp'])
    elapsed = datetime.now() - saved_time

    return {
        "timestamp": context['timestamp'],
        "elapsed_hours": elapsed.total_seconds() / 3600,
        "focus": context['user_context']['current_focus']
    }
```

### 3. 자동 제안 메시지

```python
def suggest_context_save():
    """
    컨텍스트 저장 제안 메시지
    """
    print("\n" + "=" * 50)
    print(" 💡 팁: 컨텍스트 저장")
    print("=" * 50)
    print("\n현재 작업 상태를 저장하면 다음 세션에서")
    print("중단된 지점부터 작업을 이어갈 수 있습니다.")
    print("\n실행: /context-save")

def suggest_context_restore(context_info):
    """
    컨텍스트 복원 제안 메시지
    """
    print("\n" + "=" * 50)
    print(" 💾 저장된 세션 발견")
    print("=" * 50)

    hours = int(context_info['elapsed_hours'])
    if hours < 1:
        time_str = f"{int(context_info['elapsed_hours'] * 60)}분 전"
    elif hours < 24:
        time_str = f"{hours}시간 전"
    else:
        days = int(hours / 24)
        time_str = f"{days}일 전"

    print(f"\n📅 저장 시간: {time_str}")
    print(f"💡 마지막 작업: {context_info['focus']}")
    print("\n이전 작업을 계속하시겠습니까?")
    print("\n실행: /context-restore")
```

## 사용 예시

### 예시 1: JIRA 푸시 후

```bash
/jira-push

# 출력:
# ✅ JIRA 푸시 완료! 8개 티켓 생성/업데이트
#
# ==================================================
#  💡 팁: 컨텍스트 저장
# ==================================================
#
# 현재 작업 상태를 저장하면 다음 세션에서
# 중단된 지점부터 작업을 이어갈 수 있습니다.
#
# 실행: /context-save
```

### 예시 2: 세션 시작 시

```bash
# Claude Code 재시작 후

# 자동 출력:
# ==================================================
#  💾 저장된 세션 발견
# ==================================================
#
# 📅 저장 시간: 3시간 전
# 💡 마지막 작업: Figma 연동 기능 추가
#
# 이전 작업을 계속하시겠습니까?
#
# 실행: /context-restore
```

### 예시 3: 여러 파일 변경 후

```bash
# 여러 .md 파일 수정 후

# 출력:
# ==================================================
#  💡 팁: 컨텍스트 저장
# ==================================================
#
# 현재 작업 상태를 저장하면 다음 세션에서
# 중단된 지점부터 작업을 이어갈 수 있습니다.
#
# 실행: /context-save
```

## 설정

### 자동 제안 활성화/비활성화

`.claude/config.json`:

```json
{
  "skills": {
    "context-manager": {
      "enabled": true,
      "auto_suggest_save": true,
      "auto_suggest_restore": true,
      "save_triggers": [
        "jira-push",
        "git-push",
        "worktree-update"
      ],
      "min_files_for_suggestion": 3
    }
  }
}
```

### 옵션 설명

- `enabled`: 스킬 활성화 여부
- `auto_suggest_save`: 자동 저장 제안 활성화
- `auto_suggest_restore`: 세션 시작 시 복원 제안 활성화
- `save_triggers`: 저장을 제안할 트리거 목록
- `min_files_for_suggestion`: 파일 변경 기반 제안 최소 개수

## 제안 빈도 제어

너무 자주 제안하지 않도록 쿨다운 적용:

```python
def should_suggest_with_cooldown():
    """
    마지막 제안 이후 충분한 시간이 지났는지 확인
    """
    from pathlib import Path
    import json
    from datetime import datetime, timedelta

    cooldown_file = Path('.claude-state/last-suggestion.json')

    if not cooldown_file.exists():
        return True

    with open(cooldown_file, 'r') as f:
        data = json.load(f)

    last_suggestion = datetime.fromisoformat(data['timestamp'])
    cooldown_period = timedelta(minutes=30)  # 30분 쿨다운

    return datetime.now() - last_suggestion > cooldown_period
```

## 베스트 프랙티스

### 1. 중요 작업 후 즉시 저장

```bash
/jira-push
/context-save  # 즉시 저장
```

### 2. 장시간 작업 시 주기적 저장

```bash
# 1시간마다
/context-save
```

### 3. 작업 전환 시 저장

```bash
# 다른 프로젝트로 전환하기 전
/context-save
```

### 4. 세션 시작 시 복원 확인

```bash
# 작업 시작 시
/context-restore --preview  # 미리보기
/context-restore           # 복원
```

## 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 제안이 너무 자주 표시됨 | 쿨다운 설정 짧음 | config.json에서 쿨다운 시간 증가 |
| 제안이 표시되지 않음 | 스킬 비활성화됨 | config.json에서 enabled: true 확인 |
| 복원 제안이 안 나옴 | 저장된 컨텍스트 없음 | /context-save 먼저 실행 |

## 관련 명령어

- `/context-save` - 컨텍스트 수동 저장
- `/context-restore` - 컨텍스트 복원
- `/ux status` - 현재 상태 확인

## 참조

- **저장 명령어**: `.claude/commands/context-save.md`
- **복원 명령어**: `.claude/commands/context-restore.md`
- **설정 파일**: `.claude/config.json`
