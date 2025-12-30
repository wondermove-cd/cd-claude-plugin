# CD Claude Plugin - 설치 가이드

## 📦 설치 방법

### 방법 1: 원클릭 설치 (권장)

프로젝트 폴더에서 다음 명령어를 실행하세요:

```bash
curl -fsSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/install.sh | bash
```

**설치 과정**:
1. 기존 `.claude` 폴더가 있으면 자동 백업
2. 플러그인 파일 다운로드 및 복사
3. 필요한 디렉토리 구조 생성
4. `.gitignore` 자동 생성 (없는 경우)

**완료 후**:
```
============================================
 설치 완료!
============================================

📂 설치된 구조:
  .claude/          - 플러그인 파일
  CLAUDE.md         - 메인 설정 파일
  .ux-docs/         - UX 문서 저장소
  .claude-state/    - 런타임 상태

🚀 다음 단계:
  1. Claude Code 실행
  2. /ux init "프로젝트명" 또는 /ux onboard
  3. /ux project-code SKUBER
```

---

### 방법 2: 수동 설치

#### Step 1: 레포지토리 클론

```bash
git clone https://github.com/wondermove-cd/cd-claude-plugin.git
```

#### Step 2: 프로젝트에 복사

```bash
cd /path/to/your-project

# .claude 폴더 복사
cp -r /path/to/cd-claude-plugin/.claude .

# CLAUDE.md 복사
cp /path/to/cd-claude-plugin/CLAUDE.md .
```

#### Step 3: 디렉토리 구조 생성

```bash
mkdir -p .ux-docs
mkdir -p .claude-state
mkdir -p docs
```

#### Step 4: .gitignore 설정

`.gitignore`에 다음 추가:

```
# Claude Code state
.claude-state/
.ux-docs/
docs/

# Environment
.env
.env.local

# macOS
.DS_Store
```

---

## 🔍 설치 확인

### 파일 구조 확인

```bash
ls -la
```

다음 항목들이 있어야 합니다:
```
.claude/
CLAUDE.md
.ux-docs/
.claude-state/
```

### Claude Code에서 확인

```bash
# Claude Code 실행 후
/ux init "테스트"
```

정상적으로 실행되면 설치 완료!

---

## ⚙️ 환경 설정

### 1. 프로젝트 코드 설정 (필수)

```bash
/ux project-code SKUBER
```

프로젝트 코드는 JIRA 티켓 생성 시 사용됩니다:
- 티켓 제목: `[SKUBER] 기능명`
- 태그: `SKUBER`

### 2. JIRA 연동 (선택)

#### 환경변수 설정

`.bashrc` 또는 `.zshrc`에 추가:

```bash
export JIRA_EMAIL='your-email@company.com'
export JIRA_API_TOKEN='your-api-token'
```

**API 토큰 생성**:
https://id.atlassian.com/manage-profile/security/api-tokens

#### JIRA 초기화

```bash
/jira-init YOUR_PROJECT_KEY
```

### 3. Figma 연동 (선택)

```bash
# Claude MCP Figma 서버 설정 필요
claude mcp add --transport http figma https://mcp.figma.com/mcp

# Figma 동기화
/ux figma-sync [Figma 파일 URL]
```

---

## 🚀 첫 사용

### 신규 프로젝트

```bash
# 1. 프로젝트 초기화
/ux init "My Amazing Project"

# 2. 프로젝트 코드 설정
/ux project-code MYPROJ

# 3. 기획 시작
/ux plan "첫 번째 기능"
```

### 기존 프로젝트

```bash
# 1. 프로젝트 온보딩 (자동 분석)
/ux onboard

# 2. 프로젝트 코드 설정
/ux project-code EXISTING

# 3. 새 기능 기획
/ux plan "새로운 기능"
```

---

## 🛠️ 트러블슈팅

### 설치 오류

#### "Permission denied" 오류

```bash
# 설치 스크립트에 실행 권한 부여
chmod +x install.sh
./install.sh
```

#### "git not found" 오류

Git이 설치되어 있지 않습니다:

**macOS**:
```bash
xcode-select --install
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt-get update
sudo apt-get install git
```

#### 다운로드 실패

네트워크 문제이거나 레포지토리가 비공개일 수 있습니다.
수동 설치를 시도하세요.

### 명령어 작동 안 함

#### .claude 폴더 확인

```bash
ls -la .claude
```

폴더가 없으면 설치 재시도:
```bash
rm -rf .claude CLAUDE.md
# 설치 스크립트 재실행
```

#### CLAUDE.md 확인

```bash
cat CLAUDE.md
```

파일이 비어있거나 없으면:
```bash
curl -o CLAUDE.md https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/CLAUDE.md
```

### 기존 설정과 충돌

기존 `.claude` 폴더가 있는 경우:

```bash
# 백업
mv .claude .claude.backup.$(date +%Y%m%d_%H%M%S)

# 재설치
curl -fsSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/install.sh | bash
```

---

## 🔄 업데이트

### 최신 버전으로 업데이트

```bash
# 현재 설정 백업
cp -r .claude .claude.backup
cp CLAUDE.md CLAUDE.md.backup

# 재설치 (최신 버전 다운로드)
curl -fsSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/install.sh | bash
```

### 변경사항 확인

```bash
# 백업과 비교
diff -r .claude .claude.backup
```

---

## 🗑️ 제거

플러그인을 완전히 제거하려면:

```bash
# 플러그인 파일 삭제
rm -rf .claude
rm CLAUDE.md

# 생성된 문서 삭제 (선택)
rm -rf .ux-docs
rm -rf .claude-state
rm -rf docs
```

**주의**: `.ux-docs`와 `docs`에는 작성한 문서가 포함되어 있습니다.
삭제 전 백업을 권장합니다.

---

## 📞 지원

- **GitHub Issues**: https://github.com/wondermove-cd/cd-claude-plugin/issues
- **문서**: https://github.com/wondermove-cd/cd-claude-plugin
- **이메일**: support@wondermove.com

---

## 📝 라이선스

© 원더무브 연구소
