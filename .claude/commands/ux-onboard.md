---
description: 기존 프로젝트를 분석하여 UX 문서 세트를 자동 생성합니다.
allowed-tools: Read, Write, Edit, Glob, Grep
argument-hint:
---

# UX Onboard - 기존 프로젝트 온보딩

## 목적

기존 프로젝트의 구조, 패턴, 규칙을 분석하여 8개의 핵심 컨텍스트 문서를 자동 생성합니다.

## 실행 절차

### Step 1: 프로젝트 구조 분석

다음 파일들을 탐색합니다:

```bash
# README 파일 찾기
**/{README.md,readme.md,README.txt}

# 기획 문서 찾기
**/{PRD,기획서,요구사항,requirement}*/*.{md,pdf,docx}

# Figma 링크 찾기 (README, 문서에서)
# UI 스크린샷 찾기
**/screenshots/**/*.{png,jpg}
**/images/ui/**/*.{png,jpg}
```

### Step 2: 8개 핵심 문서 생성

#### 1. PROJECT_CONTEXT.md

분석 내용:
- README.md 기반 프로젝트 개요
- package.json/requirements.txt에서 기술 스택 추출
- 프로젝트 목표 및 배경

#### 2. USER_RESEARCH.md

분석 내용:
- 기존 기획 문서에서 타겟 사용자 추출
- 페르소나 정보 수집
- 기존 사용자 리서치 결과 정리

#### 3. INFORMATION_ARCHITECTURE.md

분석 내용:
- 프로젝트 폴더 구조 분석
- 주요 페이지/화면 목록 추출
- 네비게이션 구조 파악

#### 4. USER_FLOWS.md

분석 내용:
- 기존 기획서에서 플로우 다이어그램 추출
- 주요 사용자 시나리오 정리

#### 5. FUNCTIONAL_REQUIREMENTS.md

분석 내용:
- 기존 PRD, 요구사항 문서 통합
- 기능 목록 체계화

#### 6. UX_PATTERNS.md

분석 내용:
- UI 스크린샷 분석 (있는 경우)
- 반복되는 UI 패턴 추출
- 컴포넌트 사용 패턴 정리

#### 7. DESIGN_TOKENS.md

분석 내용:
- CSS/SCSS 파일에서 색상, 폰트, 간격 추출
- 디자인 시스템 변수 정리

```scss
// 예: 색상 변수 추출
$primary-color: #1a73e8;
$secondary-color: #34a853;
```

#### 8. SPEC_CONVENTIONS.md

분석 내용:
- 기존 기획서의 작성 스타일 분석
- 템플릿 구조 파악
- 용어 사전 구축

### Step 3: CURRENT_CONTEXT.md 생성

```markdown
# 현재 작업 컨텍스트

## 워크플로우 상태

- **현재 단계**: 온보딩 완료
- **다음 단계**: 기존 컨텍스트 확인 후 작업 시작

## 프로젝트 요약

{프로젝트 한 줄 요약}

## 핵심 규칙

{추출된 핵심 규칙 3-5개}

## 최근 업데이트

- {날짜}: 프로젝트 온보딩 완료
```

### Step 4: 완료 보고

```
============================================
 [UX ONBOARD] 기존 프로젝트 분석 완료
============================================

 프로젝트: {감지된 프로젝트명}

 분석된 파일:
 • README.md
 • {기획 문서 개수}개 기획 문서
 • {스크린샷 개수}개 UI 스크린샷

 생성된 문서:
 ✅ PROJECT_CONTEXT.md
 ✅ USER_RESEARCH.md
 ✅ INFORMATION_ARCHITECTURE.md
 ✅ USER_FLOWS.md
 ✅ FUNCTIONAL_REQUIREMENTS.md
 ✅ UX_PATTERNS.md
 ✅ DESIGN_TOKENS.md
 ✅ SPEC_CONVENTIONS.md
 ✅ CURRENT_CONTEXT.md

 다음 단계:
 1. 컨텍스트 확인: /ux status
 2. 새 기능 기획: /ux plan [기능명]
 3. Figma 동기화: /ux figma-sync [URL]

============================================
```

## 분석 팁

- 파일이 많으면 대표적인 것만 샘플링
- Figma URL이 있으면 나중에 `/ux figma-sync` 실행 제안
- 기존 문서가 부족하면 템플릿 기본값 사용

## 참조 파일

- `.claude/templates/` - 각 문서 템플릿
