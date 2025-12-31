# CD Claude Plugin - 설치 가이드

## 🚀 빠른 설치 (권장)

### 방법 1: 원라인 설치
```bash
curl -sSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/quick-install.sh | bash
```

### 방법 2: 수동 설치
```bash
# 1. 플러그인 클론 (처음 설치 시)
git clone git@github.com:wondermove-cd/cd-claude-plugin.git ~/Documents/Claude/cd-claude-plugin

# 2. 프로젝트로 이동
cd ~/프로젝트경로

# 3. Symlink 설치 실행
bash ~/Documents/Claude/cd-claude-plugin/install-symlink.sh
```

---

## 📦 설치 방식 비교

### Symlink 방식 (권장) ✅
```bash
bash ~/Documents/Claude/cd-claude-plugin/install-symlink.sh
```

**장점:**
- 중앙 관리: Git pull 한 번으로 모든 프로젝트 업데이트
- 디스크 절약: 중복 파일 없음
- 즉시 반영: 재설치 불필요

**구조:**
```
프로젝트/.claude/
├── commands -> ~/Documents/Claude/cd-claude-plugin/.claude/commands (심링크)
├── skills -> ~/Documents/Claude/cd-claude-plugin/.claude/skills (심링크)
└── templates/ (복사됨 - 커스터마이징 가능)
```

### 복사 방식 (기존)
```bash
bash ~/Documents/Claude/cd-claude-plugin/install.sh
```

**단점:**
- 각 프로젝트마다 업데이트 필요
- 디스크 공간 중복 사용
- 버전 불일치 가능성

---

## 🔄 업데이트 방법

### 플러그인 업데이트
```bash
# 플러그인 저장소 업데이트
cd ~/Documents/Claude/cd-claude-plugin
git pull origin main

# Symlink 프로젝트는 자동 반영됨!
```

### 전체 프로젝트 일괄 업데이트
```bash
# 모든 프로젝트 검색 및 업데이트
bash ~/Documents/Claude/cd-claude-plugin/update-all-projects.sh
```

---

## 🔀 기존 프로젝트 전환

복사 방식에서 Symlink 방식으로 전환:

```bash
cd ~/기존프로젝트
bash ~/Documents/Claude/cd-claude-plugin/install-symlink.sh
```

기존 파일은 자동 백업됩니다 (`.backup.날짜시간`)

---

## 🛠️ 문제 해결

### SSH 키 오류
```bash
# HTTPS로 변경
cd ~/Documents/Claude/cd-claude-plugin
git remote set-url origin https://github.com/wondermove-cd/cd-claude-plugin.git
```

### Symlink 깨짐
```bash
# 재설치
cd ~/프로젝트
bash ~/Documents/Claude/cd-claude-plugin/install-symlink.sh
```

### 플러그인 삭제
```bash
# 프로젝트에서 플러그인 제거
rm -rf .claude .claude-state .ux-docs
```

---

## 📋 설치 확인

```bash
# Symlink 확인
ls -la .claude/

# 명령어 목록 확인
ls .claude/commands/

# 설정 확인
cat .claude/config.json | grep symlink_mode
```

---

## 💡 추가 정보

- **GitHub**: https://github.com/wondermove-cd/cd-claude-plugin
- **문서**: [README.md](README.md)
- **명령어 목록**: [COMMANDS.md](COMMANDS.md)