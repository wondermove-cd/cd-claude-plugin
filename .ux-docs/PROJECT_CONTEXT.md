# CD Claude Plugin - 프로젝트 컨텍스트

## 프로젝트 개요

**프로젝트명**: CD Claude Plugin
**프로젝트 코드**: PLUGIN
**타입**: Internal Tool / Developer Tool
**시작일**: 2025-12-30
**상태**: ✅ 완료 (운영 중)

---

## 목적

기획/디자인 팀의 업무 자동화를 위한 Claude Code 플러그인 개발

### 핵심 가치

- **일관된 품질**: 프로젝트 시작부터 완료까지 동일한 UX 설계 품질 보장
- **자동화**: 매뉴얼 제작, 기획서 작성, JIRA 동기화 자동화
- **팀 협업**: JIRA 연동으로 진행 상황 투명하게 공유

---

## 타겟 사용자

### Primary
- **기획자**: PRD 작성, 기능 요구사항 정의, 태스크 분해
- **디자이너**: 화면 설계, 매뉴얼 제작, 디자인 시스템 관리

### Secondary
- **개발자**: 기획 문서 참조, JIRA 티켓 확인

---

## 주요 기능

### 1. 프로젝트 온보딩
- `/ux init`: 신규 프로젝트 8개 문서 자동 생성
- `/ux onboard`: 기존 프로젝트 분석 및 문서화
- `/ux project-code`: JIRA 프로젝트 코드 관리

### 2. 기획 워크플로우
- `/ux plan`: PRD 자동 생성
- `/ux design`: 화면 시안 제안 (와이어프레임, 엣지 케이스)
- `/ux tasks`: Epic → Story → Task 분해

### 3. 매뉴얼 제작
- `/ux manual init`: 매뉴얼 프로젝트 초기화
- `/ux manual outline`: 목차 자동 생성
- `/ux manual page`: 4가지 템플릿 기반 페이지 작성
- `/ux manual build`: PPT 변환 가이드

### 4. JIRA 연동
- `/jira-init`: JIRA 연결 초기화
- `/jira-push`: Worktree → JIRA 동기화
- `/jira-status`: 동기화 현황 확인

---

## 기술 스택

### 플랫폼
- Claude Code (Anthropic)
- Markdown (명령어 정의)
- JSON (설정 및 상태 관리)

### 연동
- JIRA REST API v3
- Figma API (계획)

### 도구
- Bash (설치 스크립트)
- Git (버전 관리)

---

## 프로젝트 구조

```
cd-claude-plugin/
├── .claude/
│   ├── commands/         # 13개 슬래시 명령어
│   ├── skills/          # 5개 자동 활성화 스킬
│   ├── templates/       # 문서 템플릿
│   └── integrations/    # JIRA 설정
├── .ux-docs/            # UX 문서 저장소
├── .claude-state/       # 런타임 상태 (worktree, jira_mapping)
├── docs/                # 생성된 기획 문서
├── README.md            # 사용 가이드
├── INSTALL.md           # 설치 가이드
└── install.sh           # 자동 설치 스크립트
```

---

## JIRA 연동

**상태**: ✅ 연동 완료
**프로젝트 키**: CD
**Host**: https://wondermove-official.atlassian.net
**마지막 테스트**: 2025-12-30

### 티켓 생성 규칙

- **제목 포맷**: `[PLUGIN] {티켓 제목}`
- **태그**: `PLUGIN`
- **이슈 타입**: Epic, Story, Task

---

## 팀 정보

**팀명**: Creative & Design Team
**조직**: 원더무브

**주요 사용자**:
- 기획자
- 디자이너
- 개발자 (참조)

---

## 배포

**레포지토리**: https://github.com/wondermove-cd/cd-claude-plugin
**접근**: Private (팀 계정 공유)
**설치 방법**:
```bash
cd ~/Documents/Claude
git clone git@github.com:wondermove-cd/cd-claude-plugin.git
cd your-project
bash ~/Documents/Claude/cd-claude-plugin/install.sh
```

---

## 성공 지표

### 정량
- ✅ 명령어: 13개 구현
- ✅ 스킬: 5개 구현
- ✅ 문서: README, INSTALL, DEPLOY 작성
- ✅ JIRA 연동: 완료

### 정성
- 팀 내 플러그인 도입률
- 매뉴얼 제작 시간 단축
- 기획 문서 품질 향상

---

## 다음 단계

### Phase 2 (계획)
- [ ] Figma 연동 구현
- [ ] 매뉴얼 PPT 자동 변환
- [ ] JIRA Pull (양방향 동기화)
- [ ] 사용자 피드백 수집 및 개선

---

**마지막 업데이트**: 2025-12-30
