# CD Claude Plugin - 시스템 개요 및 설치 가이드

> **기획/디자인 팀을 위한 Claude Code 업무 자동화 도구**

---

## 📋 시스템 개요

### 목적

CD Claude Plugin은 기획/디자인 팀의 업무 자동화를 위한 Claude Code 플러그인입니다.

**핵심 가치**: "프로젝트 시작부터 완료까지, 언제 투입되든 동일한 품질"

### 주요 기능

#### 1. 프로젝트 온보딩

| 명령어 | 설명 |
|--------|------|
| `/ux init` | 신규 프로젝트 초기화 및 8개 문서 자동 생성 |
| `/ux onboard` | 기존 프로젝트 분석 및 컨텍스트 학습 |
| `/ux project-code` | 프로젝트 코드 설정 (JIRA 티켓용) |

#### 2. 기획 워크플로우

```
/ux plan → /ux flow → /ux design → /ux tasks → /jira-push
```

| 명령어 | 설명 |
|--------|------|
| `/ux plan` | PRD/기획서 자동 생성 |
| `/ux flow` | 사용자 플로우 다이어그램 생성 |
| `/ux design` | 화면 시안 제안 (와이어프레임, 엣지 케이스) |
| `/ux tasks` | Epic → Task → Subtask 분해 |

#### 3. 매뉴얼 제작

```
/ux manual init → /ux manual outline → /ux manual page → /ux manual build
```

| 명령어 | 설명 |
|--------|------|
| `/ux manual init` | 매뉴얼 프로젝트 초기화 |
| `/ux manual outline` | 목차 자동 생성 |
| `/ux manual page` | 개별 페이지 초안 작성 (템플릿 기반) |
| `/ux manual build` | PPT 변환 가이드 |

#### 4. JIRA 연동

| 명령어 | 설명 |
|--------|------|
| `/jira-init` | JIRA 연결 초기화 |
| `/jira-push` | Worktree → JIRA 동기화 (Epic/Task/Subtask) |
| `/jira-status` | 동기화 현황 확인 |

**티켓 생성 규칙**:
- 제목: `[프로젝트코드] 티켓명`
- 태그: `프로젝트코드`
- 설명: 4가지 필수 섹션 (문제점, 요구사항, 작업 Step, 결과)

### 자동 활성화 스킬

| 스킬 | 활성화 시점 | 역할 |
|------|------------|------|
| `ux-writing` | 기획서 작성, 문구 정의 시 | UX 라이팅 가이드라인 자동 적용 |
| `accessibility` | UI 설계, 색상 지정 시 | WCAG 접근성 기준 자동 체크 |
| `design-system` | 컴포넌트 관련 작업 시 | 디자인 시스템 규칙 자동 참조 |
| `handoff-spec` | 핸드오프 문서 작성 시 | 개발 전달 포맷 자동 적용 |
| `manual-template` | 매뉴얼 작성 시 | 매뉴얼 템플릿 자동 적용 |

---

## 📦 설치 방법

### 사전 요구사항

- Claude Code CLI 설치 완료
- Git 설치
- wondermove-cd GitHub 계정 SSH 키 등록

### Step 1: 플러그인 레포지토리 클론 (최초 1회)

```bash
# 플러그인을 다운로드할 위치로 이동
cd ~/repos

# 레포지토리 클론
git clone git@github.com:wondermove-cd/cd-claude-plugin.git
```

> **참고**: Private 레포지토리이므로 wondermove-cd 계정의 SSH 키가 필요합니다.

### Step 2: 프로젝트에 설치

#### 방법 A: 자동 설치 스크립트 (권장)

```bash
# 프로젝트 폴더로 이동
cd /path/to/your-project

# 설치 스크립트 실행
bash ~/repos/cd-claude-plugin/install.sh
```

**설치 과정**:
1. 기존 `.claude` 폴더 자동 백업
2. 플러그인 파일 복사
3. 필요한 디렉토리 구조 생성 (`.ux-docs`, `.claude-state`, `docs`)
4. `.gitignore` 자동 생성

#### 방법 B: 수동 설치

```bash
# 프로젝트 폴더로 이동
cd /path/to/your-project

# 플러그인 파일 복사
cp -r ~/repos/cd-claude-plugin/.claude .
cp ~/repos/cd-claude-plugin/CLAUDE.md .

# 디렉토리 구조 생성
mkdir -p .ux-docs .claude-state docs

# .gitignore 추가
cat >> .gitignore << 'EOF'

# Claude Code state
.claude-state/
.ux-docs/
docs/

# Environment
.env
.env.local

# macOS
.DS_Store
EOF
```

### Step 3: 설치 확인

```bash
# 파일 구조 확인
ls -la

# 다음 항목들이 있어야 함:
# .claude/
# CLAUDE.md
# .ux-docs/
# .claude-state/
```

```bash
# Claude Code에서 테스트
/ux init "테스트 프로젝트"
```

정상적으로 실행되면 설치 완료!

---

## ⚙️ 환경 설정

### 1. 프로젝트 코드 설정 (필수)

```bash
/ux project-code MYPROJECT
```

프로젝트 코드는 JIRA 티켓 생성 시 사용됩니다:
- 티켓 제목: `[MYPROJECT] 기능명`
- 태그: `MYPROJECT`

### 2. JIRA 연동 설정 (선택)

#### 환경변수 설정

`.bashrc` 또는 `.zshrc`에 개인별로 추가:

```bash
# JIRA 연동 설정
export JIRA_HOST="https://wondermove-official.atlassian.net"
export JIRA_EMAIL="your-email@wondermove.net"
export JIRA_API_TOKEN="your-api-token"

# 적용
source ~/.zshrc
```

**API 토큰 생성**: https://id.atlassian.com/manage-profile/security/api-tokens

#### JIRA 초기화

```bash
# CD 프로젝트 키로 초기화
/jira-init CD
```

### 3. Figma 연동 (선택)

```bash
# Figma 동기화
/ux figma-sync [Figma 파일 URL]
```

---

## 🚀 사용 방법

### 신규 프로젝트 시작

```bash
# 1. 프로젝트 초기화
/ux init "My Amazing Project"

# 2. 프로젝트 코드 설정
/ux project-code MYPROJ

# 3. JIRA 초기화 (선택)
/jira-init CD

# 4. 기획 시작
/ux plan "첫 번째 기능"
```

### 기존 프로젝트 투입

```bash
# 1. 프로젝트 온보딩 (자동 분석)
/ux onboard

# 2. 프로젝트 코드 설정
/ux project-code EXISTING

# 3. 새 기능 기획
/ux plan "새로운 기능"
```

### 기획 워크플로우

```bash
# 1. PRD 작성
/ux plan "실시간 알림 기능"

# 2. 플로우 설계
/ux flow

# 3. 화면 시안 제안
/ux design

# 4. 태스크 분해
/ux tasks

# 5. JIRA 동기화
/jira-push
```

### 매뉴얼 제작

```bash
# 1. 매뉴얼 프로젝트 생성
/ux manual init "SKuber v2.0"

# 2. 목차 자동 생성
/ux manual outline

# 3. 개별 페이지 작성
/ux manual page "클러스터 관리"
/ux manual page "모니터링"

# 4. 스크린샷 저장
# .ux-docs/manuals/[제품명]/assets/screenshots/ 폴더에 저장

# 5. PPT 빌드 준비
/ux manual build
```

---

## 🏗️ 프로젝트 구조

설치 후 프로젝트 구조:

```
project/
├── CLAUDE.md                    # Claude Code 메인 설정
├── README.md
│
├── .claude/
│   ├── commands/                # 슬래시 커맨드 (13개)
│   │   ├── ux-init.md
│   │   ├── ux-onboard.md
│   │   ├── ux-plan.md
│   │   ├── ux-design.md
│   │   ├── ux-tasks.md
│   │   ├── ux-manual-*.md
│   │   ├── jira-*.md
│   │   └── ...
│   │
│   ├── skills/                  # 자동 활성화 스킬 (5개)
│   │   ├── ux-writing/
│   │   ├── accessibility/
│   │   ├── design-system/
│   │   ├── handoff-spec/
│   │   └── manual-template/
│   │
│   ├── templates/               # 문서 템플릿
│   │   ├── prd-template.md
│   │   └── manual-page-template.md
│   │
│   ├── integrations/            # JIRA 설정
│   │   └── jira_config.json
│   │
│   └── best-practices/          # UX 베스트 프랙티스
│
├── .ux-docs/                    # UX 문서 저장소 (자동 생성)
│   ├── PROJECT_CONTEXT.md
│   ├── USER_RESEARCH.md
│   ├── INFORMATION_ARCHITECTURE.md
│   ├── USER_FLOWS.md
│   ├── FUNCTIONAL_REQUIREMENTS.md
│   ├── UX_PATTERNS.md
│   ├── DESIGN_TOKENS.md
│   ├── SPEC_CONVENTIONS.md
│   ├── CURRENT_CONTEXT.md
│   └── manuals/                 # 매뉴얼 프로젝트들
│       └── [제품명]/
│
├── .claude-state/               # 런타임 상태
│   ├── worktree.json            # 작업 트리 (Epic > Task > Subtask)
│   └── jira_mapping.json        # JIRA ID 매핑
│
└── docs/                        # 생성된 기획 문서
    ├── prd/                     # PRD 문서
    ├── design/                  # 화면 설계
    └── handoff/                 # 개발 전달 문서
```

---

## 🔄 업데이트

### 최신 버전으로 업데이트

```bash
# 1. 플러그인 레포지토리 업데이트
cd ~/repos/cd-claude-plugin
git pull origin main

# 2. 프로젝트에서 백업 및 재설치
cd /path/to/your-project
cp -r .claude .claude.backup.$(date +%Y%m%d_%H%M%S)

# 3. 재설치
bash ~/repos/cd-claude-plugin/install.sh
```

---

## 🛠️ 트러블슈팅

### 설치 오류

#### "Permission denied" 오류

```bash
chmod +x install.sh
./install.sh
```

#### SSH 클론 실패

1. SSH 키 생성: `ssh-keygen -t ed25519 -C "your-email@wondermove.net"`
2. 공개키 복사: `cat ~/.ssh/id_ed25519.pub`
3. GitHub에 등록: https://github.com/settings/keys
4. 재시도

### 명령어 작동 안 함

#### .claude 폴더 확인

```bash
ls -la .claude

# 폴더가 없으면 재설치
bash ~/repos/cd-claude-plugin/install.sh
```

### JIRA 연결 실패

```bash
# 환경변수 확인
echo $JIRA_EMAIL
echo $JIRA_API_TOKEN

# 연결 테스트
/jira-init CD
```

---

## 📊 JIRA 티켓 생성 규칙

### 계층 구조

- **Epic**: 대규모 기능 단위 (예: 사용자 인증 시스템)
- **Task**: Epic의 하위 기능 단위 (예: 회원가입 기능)
- **Subtask**: Task의 실제 구현 작업 (예: User 엔티티 설계)

### 티켓 형식

모든 티켓은 다음 4가지 필수 섹션을 포함합니다:

1. **문제점 / 해결해야 할 이슈**: 왜 이 작업이 필요한가?
2. **요구사항**: 무엇을 만들어야 하는가? (bullet list)
3. **작업 Step**: 어떻게 진행할 것인가? (ordered list)
4. **결과**: 무엇이 완성되었는가? (작업 완료 후 업데이트)

### 날짜 관리

- **Due Date**: 작업 마감일 (기본: 2026-01-02)
- **Completion Date**: 작업 완료일 (Done 상태로 전환 시 자동 설정)

### 프로젝트 코드 활용

**티켓 생성 예시**:
```
제목: [SKUBER] 클러스터 모니터링 기능
태그: SKUBER
```

**JIRA 필터링**:
- 프로젝트별 조회: `labels = SKUBER`
- 다중 프로젝트: `labels in (SKUBER, DCP, PLATFORM)`

---

## 📈 기대 효과

| 지표 | 개선율 |
|------|--------|
| 온보딩 시간 | 50% 단축 |
| 기획 리뷰 지적사항 | 70% 감소 |
| 컨텍스트 재설명 시간 | 90% 절감 |
| 매뉴얼 제작 시간 | 60% 단축 |

---

## 📞 지원

- **GitHub**: https://github.com/wondermove-cd/cd-claude-plugin
- **이메일**: support@wondermove.com
- **Confluence**: https://wondermove-official.atlassian.net/wiki/spaces/CG1/

---

## 📝 버전 정보

- **최초 배포**: 2025-12-30
- **현재 버전**: 1.0.0
- **라이선스**: © 원더무브 연구소

---

**문서 작성**: CD Team
**최종 업데이트**: 2025-12-30
