# 배포 가이드

## GitHub 레포지토리 푸시

### 1. GitHub 레포지토리 생성

1. https://github.com/wondermove-cd 로 이동
2. "New repository" 클릭
3. Repository name: `cd-claude-plugin`
4. Description: `기획/디자인 팀 전용 Claude Code 플러그인`
5. Public으로 설정
6. **"Initialize this repository with a README" 체크 해제**
7. "Create repository" 클릭

### 2. 로컬에서 푸시

```bash
cd /Users/jhkim/Documents/Claude/cd-claude-plugin

# 이미 완료된 작업:
# git init
# git add -A
# git commit -m "Initial commit"
# git branch -M main
# git remote add origin https://github.com/wondermove-cd/cd-claude-plugin.git

# 푸시
git push -u origin main
```

**인증 방법**:

#### 옵션 A: Personal Access Token (권장)

1. GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
2. "Generate new token" 클릭
3. 권한 선택: `repo` 전체 체크
4. 토큰 생성 및 복사

푸시 시:
```bash
Username: wondermove-cd
Password: [생성한 토큰 붙여넣기]
```

#### 옵션 B: SSH

```bash
# SSH 키 생성 (없는 경우)
ssh-keygen -t ed25519 -C "your-email@company.com"

# SSH 키를 GitHub에 등록
cat ~/.ssh/id_ed25519.pub
# 복사 후 GitHub Settings > SSH keys에 등록

# Remote URL을 SSH로 변경
git remote set-url origin git@github.com:wondermove-cd/cd-claude-plugin.git

# 푸시
git push -u origin main
```

---

## 푸시 확인

성공하면:
```
Enumerating objects: X, done.
Counting objects: 100% (X/X), done.
Delta compression using up to N threads
Compressing objects: 100% (X/X), done.
Writing objects: 100% (X/X), XX.XX KiB | XX.XX MiB/s, done.
Total X (delta X), reused 0 (delta 0), pack-reused 0
To https://github.com/wondermove-cd/cd-claude-plugin.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

브라우저에서 확인:
https://github.com/wondermove-cd/cd-claude-plugin

---

## 설치 스크립트 테스트

### 다른 프로젝트에서 테스트

```bash
# 테스트 프로젝트 생성
mkdir -p ~/test-cd-plugin
cd ~/test-cd-plugin

# 원클릭 설치
curl -fsSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/install.sh | bash
```

**예상 출력**:
```
============================================
 CD Claude Plugin - 설치 스크립트
============================================

ℹ️  플러그인을 다운로드합니다...
✅ 플러그인 파일 복사 완료
ℹ️  초기 디렉토리 구조를 생성합니다...
✅ 디렉토리 구조 생성 완료

============================================
 설치 완료!
============================================

📂 설치된 구조:
  .claude/          - 플러그인 파일
  CLAUDE.md         - 메인 설정 파일
  ...
```

---

## GitHub Pages 설정 (선택)

프로젝트 문서를 웹으로 제공:

1. GitHub 레포지토리 > Settings > Pages
2. Source: Deploy from a branch
3. Branch: main, folder: / (root)
4. Save

문서 접근:
https://wondermove-cd.github.io/cd-claude-plugin/

---

## Release 생성

### v1.0.0 릴리스

1. GitHub 레포지토리 > Releases > "Create a new release"
2. Tag: `v1.0.0`
3. Title: `v1.0.0 - Initial Release`
4. Description:

```markdown
## 🎉 CD Claude Plugin v1.0.0

기획/디자인 팀 전용 Claude Code 플러그인 첫 릴리스입니다.

### ✨ 주요 기능

- **프로젝트 온보딩**: `/ux init`, `/ux onboard`
- **기획 워크플로우**: `/ux plan`, `/ux flow`, `/ux spec`
- **매뉴얼 제작**: `/ux manual init/outline/page/build` (핵심!)
- **JIRA 연동**: 프로젝트 코드 기반 티켓 생성
- **자동 스킬**: UX 라이팅, 접근성, 디자인 시스템 등

### 📦 설치

**원클릭 설치**:
\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/install.sh | bash
\`\`\`

### 📖 문서

- [README](https://github.com/wondermove-cd/cd-claude-plugin/blob/main/README.md)
- [설치 가이드](https://github.com/wondermove-cd/cd-claude-plugin/blob/main/INSTALL.md)

### 🙏 Credits

원더무브 연구소
```

5. "Publish release" 클릭

---

## 업데이트 배포

향후 업데이트 시:

```bash
# 변경사항 커밋
git add -A
git commit -m "feat: 새 기능 추가"
git push origin main

# 새 릴리스 생성
# GitHub에서 v1.1.0 릴리스 생성
```

사용자는 자동으로 최신 버전을 받게 됩니다:
```bash
curl -fsSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/install.sh | bash
```

---

## 트러블슈팅

### Push 실패: "Permission denied"

organization 권한 확인:
1. GitHub > wondermove-cd > Settings > Member privileges
2. 자신의 계정이 write 권한이 있는지 확인

### 레포지토리가 이미 존재

기존 레포지토리 삭제 후 재생성 또는:
```bash
git remote set-url origin https://github.com/wondermove-cd/cd-claude-plugin.git
git push -f origin main  # 강제 푸시 (주의!)
```

---

## 완료 체크리스트

- [ ] GitHub 레포지토리 생성
- [ ] 로컬에서 푸시 완료
- [ ] 설치 스크립트 테스트
- [ ] README 확인
- [ ] v1.0.0 릴리스 생성
- [ ] 팀원들에게 공유
