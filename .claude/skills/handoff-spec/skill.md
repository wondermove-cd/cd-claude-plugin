---
name: handoff-spec
description: 개발팀 전달용 스펙 문서 포맷을 자동으로 적용합니다. 핸드오프 문서 작성 시 활성화됩니다.
allowed-tools: Read
---

# Handoff Spec Skill

## 목적

디자이너/기획자가 개발자에게 명확하고 구현 가능한 스펙을 전달하도록 돕습니다.

## 활성화 조건

다음 상황에서 자동 활성화:
- `/ux handoff` 커맨드 실행 시
- "핸드오프", "개발 전달", "스펙 문서" 키워드 언급 시
- `docs/handoff/` 폴더 내 파일 작성 시

## 핸드오프 문서 구조

### 필수 섹션

```markdown
1. 개요 (Overview)
2. 화면 목록 (Screens)
3. 컴포넌트 스펙 (Component Specs)
4. 인터랙션 (Interactions)
5. API 요구사항 (API Requirements)
6. 에셋 목록 (Assets)
7. 예외 처리 (Error Handling)
8. 테스트 시나리오 (Test Scenarios)
```

---

## 1. 개요 (Overview)

**목적**: 개발자가 전체 맥락을 빠르게 이해

```markdown
# {기능명} 개발 스펙

## 개요

| 항목 | 내용 |
|------|------|
| 기능명 | {기능명} |
| 우선순위 | P0 / P1 / P2 |
| 담당 디자이너 | {이름} |
| 담당 개발자 | {이름} |
| 일정 | {시작일} ~ {마감일} |
| 관련 문서 | [PRD](링크), [Figma](링크) |

## 핵심 요구사항

{3-5개 핵심 기능 요약}

1. {핵심 기능 1}
2. {핵심 기능 2}
3. {핵심 기능 3}

## 기술 스택 (권장)

- Frontend: {프레임워크}
- Backend: {언어/프레임워크}
- Database: {DB 종류}
```

---

## 2. 화면 목록 (Screens)

**목적**: 모든 화면과 플로우 명확히 정의

```markdown
## 화면 목록

### 2.1 화면 구조

```
1. 로그인 화면 (Login)
   ├─ 1-1. 이메일 입력 화면
   ├─ 1-2. 비밀번호 입력 화면
   └─ 1-3. 비밀번호 찾기 화면

2. 대시보드 (Dashboard)
   ├─ 2-1. 메인 대시보드
   ├─ 2-2. 프로젝트 목록
   └─ 2-3. 프로젝트 상세
```

### 2.2 화면별 스펙

#### Screen 1-1: 이메일 입력 화면

**스크린샷**:
[첨부: 01_login_email.png]

**URL**: `/login`

**레이아웃**:
- 너비: 400px (중앙 정렬)
- 배경: White
- 패딩: 24px

**구성 요소**:
1. 로고 (상단 중앙)
2. 제목: "이메일로 로그인" (Heading-L)
3. 이메일 입력 필드
4. 다음 버튼 (Primary, Full width)
5. 소셜 로그인 버튼 (Secondary)

**상태**:
- 기본: 이메일 입력 필드 포커스
- 입력 중: 다음 버튼 활성화
- 오류: 이메일 형식 오류 메시지 표시
```

---

## 3. 컴포넌트 스펙 (Component Specs)

**목적**: 각 UI 요소의 정확한 구현 스펙 제공

```markdown
## 컴포넌트 스펙

### 3.1 버튼

#### Primary Button

**스타일**:
```css
background: #1A73E8;
color: #FFFFFF;
font: Pretendard, 16px, Medium;
padding: 12px 24px;
border-radius: 8px;
min-height: 48px;
```

**States**:
- Default: background #1A73E8
- Hover: background #1557B0
- Active: background #0D47A1
- Disabled: background #1A73E8, opacity 0.4
- Loading: text "처리 중..." + spinner

**Behavior**:
- 클릭 시: {동작 설명}
- 키보드: Enter 키로도 실행 가능

### 3.2 입력 필드

#### Email Input

**스타일**:
```css
width: 100%;
height: 48px;
padding: 12px 16px;
border: 1px solid #DADCE0;
border-radius: 4px;
font: Pretendard, 14px, Regular;
```

**Validation**:
- 형식: 이메일 정규식 `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`
- 필수: true
- 오류 메시지: "올바른 이메일 형식을 입력해주세요"

**States**:
- Default: border #DADCE0
- Focus: border #1A73E8, 2px
- Error: border #EA4335 + 오류 메시지 (하단, Red-500)
- Disabled: background #F1F3F4
```

---

## 4. 인터랙션 (Interactions)

**목적**: 사용자 동작에 따른 반응 명확히 정의

```markdown
## 인터랙션

### 4.1 로그인 플로우

#### Case 1: 정상 로그인

```
User Action → System Response

1. 이메일 입력 → 형식 검증 (실시간)
2. "다음" 클릭 → 비밀번호 화면으로 이동 (페이드 전환, 300ms)
3. 비밀번호 입력 → 형식 검증
4. "로그인" 클릭 → 로딩 스피너 표시 (500ms 후)
5. API 성공 → 대시보드로 리다이렉트 (즉시)
```

#### Case 2: 이메일 형식 오류

```
User Action → System Response

1. 잘못된 이메일 입력 → 실시간 검증 없음 (onBlur 시에만)
2. 다음 필드로 이동 (Blur) → 오류 메시지 표시
   - 메시지: "올바른 이메일 형식을 입력해주세요"
   - 위치: 입력 필드 하단
   - 색상: Error-500
   - 아이콘: ✗
3. 다시 입력 필드 포커스 → 오류 메시지 유지 (입력 시작하면 제거)
```

#### Case 3: API 오류

```
User Action → System Response

1. "로그인" 클릭 → 로딩 스피너
2. API 실패 (500ms 후) → 스피너 제거 + 오류 메시지 표시
   - 메시지: "일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
   - 위치: 화면 상단 (Toast)
   - 지속 시간: 5초 (자동 사라짐)
   - 닫기 버튼: ✕
```

### 4.2 애니메이션

| 요소 | 타입 | Duration | Easing |
|------|------|----------|--------|
| 페이지 전환 | Fade | 300ms | ease-in-out |
| 모달 열기 | Slide up + Fade | 250ms | ease-out |
| 버튼 Hover | Scale | 150ms | ease-in-out |
| 토스트 메시지 | Slide down | 200ms | ease-out |
```

---

## 5. API 요구사항 (API Requirements)

**목적**: 백엔드 개발자와의 명확한 계약 정의

```markdown
## API 요구사항

### 5.1 로그인 API

**Endpoint**: `POST /api/auth/login`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success - 200)**:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGci...",
    "refresh_token": "dGhpcyBp...",
    "user": {
      "id": 123,
      "email": "user@example.com",
      "name": "홍길동"
    }
  }
}
```

**Response (Error - 401)**:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "이메일 또는 비밀번호가 일치하지 않습니다."
  }
}
```

**Error Codes**:
| Code | HTTP | 메시지 | UI 표시 |
|------|------|--------|---------|
| INVALID_CREDENTIALS | 401 | 이메일 또는 비밀번호 불일치 | "이메일 또는 비밀번호가 일치하지 않습니다." |
| USER_NOT_FOUND | 404 | 사용자 없음 | "등록되지 않은 이메일입니다." |
| SERVER_ERROR | 500 | 서버 오류 | "일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요." |
```

---

## 6. 에셋 목록 (Assets)

**목적**: 필요한 모든 디자인 에셋 명확히 전달

```markdown
## 에셋 목록

### 6.1 이미지

| 파일명 | 크기 | 포맷 | 용도 |
|--------|------|------|------|
| logo.svg | - | SVG | 로고 (반응형) |
| login_bg.png | 1920x1080 | PNG | 로그인 배경 |
| icon_check.svg | 24x24 | SVG | 체크 아이콘 |

**다운로드**: [Figma 에셋 링크](링크)

### 6.2 아이콘

Figma Icons 라이브러리 사용:
- 체크: `icon/check-circle`
- 오류: `icon/error-outline`
- 경고: `icon/warning-outline`

### 6.3 폰트

- Primary: Pretendard (Google Fonts)
  - Weights: 400 (Regular), 500 (Medium), 700 (Bold)
  - CDN: `https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/static/pretendard.css`

### 6.4 디자인 토큰 (CSS Variables)

```css
/* Colors */
--color-primary-500: #1A73E8;
--color-gray-900: #202124;
--color-error-500: #EA4335;

/* Typography */
--font-heading-l: 24px / 32px Pretendard Bold;
--font-body-m: 14px / 20px Pretendard Regular;

/* Spacing */
--space-2: 8px;
--space-4: 16px;
```
```

---

## 7. 예외 처리 (Error Handling)

**목적**: 모든 오류 상황에 대한 UI 정의

```markdown
## 예외 처리

### 7.1 클라이언트 오류

| 오류 상황 | UI 반응 | 복구 방법 |
|----------|---------|----------|
| 이메일 형식 오류 | 입력 필드 하단 오류 메시지 | 올바른 형식 재입력 |
| 필수 필드 미입력 | "필수 항목입니다" 메시지 | 입력 후 재시도 |
| 네트워크 끊김 | 상단 Toast: "인터넷 연결을 확인해주세요" | 연결 후 재시도 버튼 |

### 7.2 서버 오류

| HTTP Code | 메시지 | UI 위치 |
|-----------|--------|---------|
| 400 | "요청이 올바르지 않습니다" | Toast (상단) |
| 401 | "이메일 또는 비밀번호가 일치하지 않습니다" | 입력 필드 하단 |
| 403 | "접근 권한이 없습니다" | Toast + 로그인 화면 리다이렉트 |
| 500 | "일시적인 문제가 발생했습니다" | Toast |

### 7.3 타임아웃

```
요청 타임아웃: 10초
초과 시: "응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요"
재시도 버튼 표시
```
```

---

## 8. 테스트 시나리오 (Test Scenarios)

**목적**: QA 팀이 테스트할 체크리스트 제공

```markdown
## 테스트 시나리오

### 8.1 정상 플로우

- [ ] 올바른 이메일/비밀번호로 로그인 성공
- [ ] 로그인 후 대시보드로 이동
- [ ] 토큰이 localStorage에 저장됨

### 8.2 오류 케이스

- [ ] 잘못된 이메일 형식 입력 시 오류 메시지 표시
- [ ] 잘못된 비밀번호 입력 시 "일치하지 않습니다" 메시지
- [ ] 네트워크 오류 시 재시도 버튼 표시

### 8.3 엣지 케이스

- [ ] 이메일 필드 공백 입력 방지
- [ ] 비밀번호 복사/붙여넣기 가능
- [ ] 브라우저 뒤로가기 동작 확인

### 8.4 접근성

- [ ] Tab 키로 모든 요소 접근 가능
- [ ] Enter 키로 폼 제출 가능
- [ ] 스크린리더로 오류 메시지 읽힘

### 8.5 반응형

- [ ] 모바일 (375px): 레이아웃 정상
- [ ] 태블릿 (768px): 레이아웃 정상
- [ ] 데스크톱 (1920px): 레이아웃 정상
```

---

## 핸드오프 체크리스트

문서 작성 완료 전:

- [ ] **완전성**
  - 모든 화면 스펙 작성
  - 모든 컴포넌트 스타일 정의
  - 모든 인터랙션 시나리오 정의

- [ ] **명확성**
  - 애매한 표현 없음
  - 픽셀 단위로 정확한 수치
  - "적당히", "대략" 같은 표현 금지

- [ ] **구현 가능성**
  - 기술적으로 구현 가능한 스펙
  - 성능 고려 (애니메이션, 이미지 크기 등)

- [ ] **에셋**
  - 모든 이미지/아이콘 제공
  - 파일명 규칙 준수
  - 다양한 해상도 (1x, 2x, 3x) 제공

- [ ] **커뮤니케이션**
  - 개발자와 리뷰 완료
  - 질문사항 해결
  - Figma 링크 공유

---

## 자동 검증

핸드오프 문서 작성 시 다음을 자동 체크:

```
[HANDOFF SPEC] 검증 결과

✅ 모든 필수 섹션 포함
⚠️ API 스펙 미완성:
   - Error Codes 정의 필요
❌ 에셋 누락:
   - logo.svg
   - login_bg.png

개선 제안:
1. API 오류 코드 전체 정의 추가
2. Figma에서 에셋 Export
3. 개발자와 리뷰 일정 잡기
```

---

## 참조 파일

- `.ux-docs/FUNCTIONAL_REQUIREMENTS.md` - 기능 요구사항
- `.ux-docs/UX_PATTERNS.md` - 컴포넌트 스펙
- `.ux-docs/DESIGN_TOKENS.md` - 디자인 토큰
- `docs/prd/*/prd.md` - PRD 문서
