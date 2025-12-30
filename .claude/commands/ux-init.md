---
description: 신규 프로젝트를 초기화하고 UX 문서 기본 세트를 생성합니다.
allowed-tools: Write, Edit, Glob, Bash
argument-hint: [프로젝트명]
---

# UX Init - 신규 프로젝트 초기화

## 목적

신규 프로젝트의 UX 문서 구조를 초기화하고 기본 템플릿을 생성합니다.

## 실행 절차

### Step 1: 프로젝트명 확인

$ARGUMENTS에서 프로젝트명 파악 또는 질문:

```
프로젝트명을 입력해주세요:
```

### Step 2: 디렉토리 구조 생성

다음 폴더 구조를 생성합니다:

```
.ux-docs/
├── PROJECT_CONTEXT.md
├── USER_RESEARCH.md
├── INFORMATION_ARCHITECTURE.md
├── USER_FLOWS.md
├── FUNCTIONAL_REQUIREMENTS.md
├── UX_PATTERNS.md
├── DESIGN_TOKENS.md
├── SPEC_CONVENTIONS.md
├── CURRENT_CONTEXT.md
└── manuals/

.claude-state/
├── worktree.json
└── jira_mapping.json

docs/
└── .gitkeep
```

### Step 3: 기본 문서 생성

각 문서를 템플릿을 기반으로 생성합니다:

#### PROJECT_CONTEXT.md

```markdown
# 프로젝트 컨텍스트: {프로젝트명}

## 프로젝트 개요

**프로젝트명**: {프로젝트명}
**시작일**: {날짜}
**상태**: 기획 중

## 배경 및 목적

{이 섹션은 /ux plan 실행 시 자동으로 채워집니다}

## 타겟 사용자

{이 섹션은 /ux plan 실행 시 자동으로 채워집니다}

## 핵심 기능

{이 섹션은 /ux plan 실행 시 자동으로 채워집니다}
```

#### CURRENT_CONTEXT.md

```markdown
# 현재 작업 컨텍스트

## 워크플로우 상태

- **현재 단계**: 초기화 완료
- **다음 단계**: /ux plan 실행

## 진행 중인 작업

없음

## 최근 업데이트

- {날짜}: 프로젝트 초기화 완료
```

### Step 4: worktree.json 초기화

```json
{
  "project": "{프로젝트명}",
  "created_at": "{ISO 날짜}",
  "epics": []
}
```

### Step 5: 완료 보고

```
============================================
 [UX INIT] 프로젝트 초기화 완료
============================================

 프로젝트: {프로젝트명}

 생성된 문서:
 ✅ .ux-docs/PROJECT_CONTEXT.md
 ✅ .ux-docs/USER_RESEARCH.md
 ✅ .ux-docs/INFORMATION_ARCHITECTURE.md
 ✅ .ux-docs/USER_FLOWS.md
 ✅ .ux-docs/FUNCTIONAL_REQUIREMENTS.md
 ✅ .ux-docs/UX_PATTERNS.md
 ✅ .ux-docs/DESIGN_TOKENS.md
 ✅ .ux-docs/SPEC_CONVENTIONS.md
 ✅ .ux-docs/CURRENT_CONTEXT.md

 다음 단계:
 1. Figma 디자인 시스템이 있다면: /ux figma-sync [URL]
 2. 기획 시작: /ux plan [기능명]

============================================
```

## 참조 파일

- `.claude/templates/` - 각 문서 템플릿
