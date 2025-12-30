---
description: GitHub에서 최신 플러그인을 pull하여 현재 프로젝트에 업데이트합니다.
allowed-tools: Bash
argument-hint: [--force]
---

# /plugin-update - 플러그인 업데이트

GitHub 레포지토리에서 최신 cd-claude-plugin을 pull하여 현재 프로젝트에 적용합니다.

## 사용법

```bash
# 기본 업데이트 (변경사항 표시 + 확인)
/plugin-update

# 강제 업데이트 (확인 없이 바로 적용)
/plugin-update --force

# Dry run (어떤 파일이 업데이트될지만 확인)
/plugin-update --dry-run
```

---

## 실행 절차

### Step 1: 플러그인 레포지토리 업데이트

```bash
cd ~/Documents/Claude/cd-claude-plugin
git pull origin main
```

### Step 2: 변경사항 확인

```bash
# 마지막 pull 이후 변경된 파일 확인
git log --oneline -5
git diff --name-only HEAD@{1} HEAD
```

### Step 3: 현재 프로젝트에 적용

```bash
# install.sh 실행
bash ~/Documents/Claude/cd-claude-plugin/install.sh
```

---

## 전체 스크립트

```bash
#!/bin/bash

# 색상 정의
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} CD Claude Plugin - 업데이트${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# 플러그인 디렉토리 확인
PLUGIN_DIR="$HOME/Documents/Claude/cd-claude-plugin"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}❌ 플러그인 디렉토리를 찾을 수 없습니다: $PLUGIN_DIR${NC}"
    echo ""
    echo "플러그인을 먼저 클론하세요:"
    echo "  cd ~/Documents/Claude"
    echo "  git clone git@github.com:wondermove-cd/cd-claude-plugin.git"
    exit 1
fi

# 현재 프로젝트 디렉토리 확인
CURRENT_DIR=$(pwd)
if [ ! -d ".claude" ]; then
    echo -e "${YELLOW}⚠️  현재 디렉토리에 .claude 폴더가 없습니다.${NC}"
    echo "플러그인이 설치되지 않은 프로젝트입니다."
    echo ""
    read -p "플러그인을 새로 설치하시겠습니까? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        echo "업데이트를 취소합니다."
        exit 0
    fi
fi

# 플러그인 레포지토리로 이동
cd "$PLUGIN_DIR" || exit 1

echo "📡 플러그인 레포지토리 업데이트 중..."
echo ""

# 현재 커밋 해시 저장
OLD_COMMIT=$(git rev-parse HEAD)

# Git pull
git pull origin main

# 새 커밋 해시
NEW_COMMIT=$(git rev-parse HEAD)

echo ""

# 변경사항 확인
if [ "$OLD_COMMIT" == "$NEW_COMMIT" ]; then
    echo -e "${GREEN}✅ 이미 최신 버전입니다.${NC}"
    echo ""
    exit 0
fi

echo -e "${YELLOW}📝 변경사항:${NC}"
echo ""
git log --oneline --no-merges $OLD_COMMIT..$NEW_COMMIT
echo ""

echo -e "${YELLOW}📄 변경된 파일:${NC}"
echo ""
git diff --name-status $OLD_COMMIT $NEW_COMMIT | head -20
echo ""

# 확인 메시지 (--force 옵션이 없으면)
if [[ ! "$*" =~ "--force" ]] && [[ ! "$*" =~ "--dry-run" ]]; then
    read -p "현재 프로젝트에 업데이트를 적용하시겠습니까? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        echo "업데이트를 취소합니다."
        exit 0
    fi
fi

# Dry run 모드
if [[ "$*" =~ "--dry-run" ]]; then
    echo -e "${BLUE}📋 Dry Run 모드 - 실제 업데이트는 하지 않습니다.${NC}"
    echo ""
    echo "업데이트될 파일 목록:"
    echo ""

    # install.sh가 복사할 파일들 미리보기
    for src in .claude/commands/*.md; do
        if [ -f "$src" ]; then
            echo "  • $(basename "$src")"
        fi
    done

    for src in .claude/skills/*/skill.md; do
        if [ -f "$src" ]; then
            echo "  • skills/$(dirname "$(basename "$(dirname "$src")")")/skill.md"
        fi
    done

    echo ""
    echo "실제 업데이트하려면 /plugin-update 를 다시 실행하세요."
    exit 0
fi

# 현재 프로젝트로 돌아가기
cd "$CURRENT_DIR" || exit 1

echo ""
echo -e "${GREEN}🔄 현재 프로젝트에 업데이트 적용 중...${NC}"
echo ""

# install.sh 실행
bash "$PLUGIN_DIR/install.sh"

INSTALL_STATUS=$?

echo ""

if [ $INSTALL_STATUS -eq 0 ]; then
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN} ✅ 플러그인 업데이트 완료!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "업데이트된 버전:"
    echo "  이전: ${OLD_COMMIT:0:7}"
    echo "  최신: ${NEW_COMMIT:0:7}"
    echo ""
    echo "변경 로그:"
    git -C "$PLUGIN_DIR" log --oneline --no-merges $OLD_COMMIT..$NEW_COMMIT | head -3
    echo ""
else
    echo -e "${RED}============================================${NC}"
    echo -e "${RED} ❌ 플러그인 업데이트 실패${NC}"
    echo -e "${RED}============================================${NC}"
    echo ""
    echo "install.sh 실행 중 오류가 발생했습니다."
    echo ""
    exit 1
fi
```

---

## 출력 형식

### 업데이트 있음

```
============================================
 CD Claude Plugin - 업데이트
============================================

📡 플러그인 레포지토리 업데이트 중...

📝 변경사항:

80452fb fix: Figma 동기화 포맷 개선 - 간결한 테이블 형식
aea8da9 feat: JIRA-Figma 동기화 개선 (Nodes API + Comments)
941901a feat: 세션 컨텍스트 저장/복원 기능 추가

📄 변경된 파일:

M       .claude/commands/jira-figma-sync.md
A       .claude/commands/context-save.md
A       .claude/commands/context-restore.md
A       .claude/skills/context-manager/skill.md

현재 프로젝트에 업데이트를 적용하시겠습니까? [Y/n]: Y

🔄 현재 프로젝트에 업데이트 적용 중...

============================================
 CD Claude Plugin - 설치 스크립트
============================================

📋 설치 내용:
 • Commands: 15개
 • Skills: 7개
 • Templates: 3개

✅ 설치 완료!

============================================
 ✅ 플러그인 업데이트 완료!
============================================

업데이트된 버전:
  이전: aea8da9
  최신: 80452fb

변경 로그:
80452fb fix: Figma 동기화 포맷 개선 - 간결한 테이블 형식
```

### 이미 최신 버전

```
============================================
 CD Claude Plugin - 업데이트
============================================

📡 플러그인 레포지토리 업데이트 중...

✅ 이미 최신 버전입니다.
```

### Dry Run 모드

```
============================================
 CD Claude Plugin - 업데이트
============================================

📡 플러그인 레포지토리 업데이트 중...

📝 변경사항:
...

📋 Dry Run 모드 - 실제 업데이트는 하지 않습니다.

업데이트될 파일 목록:

  • jira-figma-sync.md
  • context-save.md
  • context-restore.md
  • skills/context-manager/skill.md

실제 업데이트하려면 /plugin-update 를 다시 실행하세요.
```

---

## 사용 시나리오

### 시나리오 1: 정기 업데이트

```bash
# 주 1회 플러그인 업데이트 확인
/plugin-update

# 변경사항 확인 후 적용
# [Y] 입력
```

### 시나리오 2: 새 기능 출시 후

```bash
# GitHub에 새 기능이 푸시된 후
/plugin-update --force

# 바로 적용
```

### 시나리오 3: 여러 프로젝트 업데이트

```bash
# 프로젝트 1
cd ~/project1
/plugin-update --force

# 프로젝트 2
cd ~/project2
/plugin-update --force

# 프로젝트 3
cd ~/project3
/plugin-update --force
```

---

## 에러 처리

| 에러 | 원인 | 해결 |
|------|------|------|
| 플러그인 디렉토리 없음 | 플러그인 미설치 | `git clone` 먼저 실행 |
| Git pull 실패 | 네트워크 오류 | 인터넷 연결 확인 |
| install.sh 실패 | 파일 권한 문제 | `chmod +x install.sh` |
| .claude 폴더 없음 | 플러그인 미설치 프로젝트 | 새로 설치 옵션 선택 |

---

## 자동화

### Cron으로 주기적 업데이트

`.zshrc` 또는 `.bashrc`에 추가:

```bash
# 플러그인 업데이트 alias
alias plugin-update="cd ~/Documents/Claude/cd-claude-plugin && git pull && echo '플러그인이 업데이트되었습니다. 프로젝트에 적용하려면 /plugin-update를 실행하세요.'"
```

### 세션 시작 시 업데이트 확인

`.claude/hooks/on-session-start.sh`:

```bash
#!/bin/bash
# 세션 시작 시 플러그인 업데이트 확인

PLUGIN_DIR="$HOME/Documents/Claude/cd-claude-plugin"

if [ -d "$PLUGIN_DIR" ]; then
    cd "$PLUGIN_DIR"

    # 원격 변경사항 확인 (fetch만)
    git fetch origin main --quiet

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "💡 새로운 플러그인 업데이트가 있습니다!"
        echo "   /plugin-update 를 실행하여 업데이트하세요."
        echo ""
    fi
fi
```

---

## 베스트 프랙티스

### 1. 정기적 업데이트

```bash
# 주 1회 업데이트 확인
/plugin-update --dry-run

# 변경사항 확인 후 적용
/plugin-update
```

### 2. 중요 업데이트 알림 받기

GitHub 레포지토리 Watch 설정:
- Releases only
- 새 버전 출시 시 이메일 알림

### 3. 여러 프로젝트 일괄 업데이트

```bash
# 스크립트로 자동화
for project in ~/projects/*; do
    if [ -d "$project/.claude" ]; then
        echo "Updating $project..."
        cd "$project"
        /plugin-update --force
    fi
done
```

---

## 관련 명령어

- `/ux status` - 플러그인 버전 확인
- `/context-save` - 업데이트 전 컨텍스트 저장
- `/context-restore` - 업데이트 후 컨텍스트 복원

---

## 참조

- **플러그인 레포지토리**: https://github.com/wondermove-cd/cd-claude-plugin
- **설치 가이드**: `INSTALL.md`
- **변경 로그**: GitHub Releases
