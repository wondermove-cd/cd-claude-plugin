---
name: design-system
description: 디자인 시스템 규칙을 자동으로 참조합니다. 컴포넌트, 색상, 타이포그래피 관련 작업 시 활성화됩니다.
allowed-tools: Read
---

# Design System Skill

## 목적

일관된 디자인 시스템을 유지하고 기획서에 올바른 컴포넌트/토큰을 사용하도록 돕습니다.

## 활성화 조건

다음 상황에서 자동 활성화:
- UI 컴포넌트 설계 시
- 색상, 폰트, 간격 지정 시
- "버튼", "카드", "색상", "타이포" 키워드 언급 시
- `/ux spec` 커맨드 실행 시

## 디자인 시스템 구조

### 계층

```
디자인 토큰 (Design Tokens)
    ↓
기본 컴포넌트 (Primitive Components)
    ↓
복합 컴포넌트 (Composite Components)
    ↓
페이지 템플릿 (Page Templates)
```

---

## 1. 디자인 토큰

### 1.1 색상 (Colors)

**참조**: `.ux-docs/DESIGN_TOKENS.md`

#### Primary Colors

```
기획서 표기:
- 색상: Primary-500 (#1A73E8)
```

#### Semantic Colors

```
- Success: Green-500 (#34A853)
- Error: Red-500 (#EA4335)
- Warning: Yellow-500 (#FBBC04)
- Info: Blue-500 (#4285F4)
```

#### Neutral Colors

```
- Gray-900: #202124 (제목)
- Gray-700: #5F6368 (본문)
- Gray-500: #9AA0A6 (보조 텍스트)
- Gray-300: #DADCE0 (테두리)
- Gray-100: #F1F3F4 (배경)
```

**사용 예시**:

```markdown
## 화면 색상 정의

- 배경: Gray-100
- 제목: Gray-900
- 본문: Gray-700
- 주요 버튼: Primary-500
- 경고 메시지: Error-500 배경 + White 텍스트
```

### 1.2 타이포그래피 (Typography)

**참조**: `.ux-docs/DESIGN_TOKENS.md`

#### 폰트 패밀리

```
- Heading: "Pretendard", sans-serif
- Body: "Pretendard", sans-serif
- Code: "JetBrains Mono", monospace
```

#### 타입 스케일

```
기획서 표기:
- H1: Heading-XL (32px, Bold)
- H2: Heading-L (24px, Bold)
- H3: Heading-M (20px, SemiBold)
- Body-L: 16px, Regular
- Body-M: 14px, Regular
- Body-S: 12px, Regular
- Caption: 11px, Regular
```

**사용 예시**:

```markdown
## 타이포그래피 정의

- 페이지 제목: Heading-XL, Gray-900
- 섹션 제목: Heading-L, Gray-900
- 본문: Body-M, Gray-700
- 캡션: Caption, Gray-500
```

### 1.3 간격 (Spacing)

**참조**: `.ux-docs/DESIGN_TOKENS.md`

#### 스페이싱 스케일 (8px 기반)

```
기획서 표기:
- Space-1: 4px
- Space-2: 8px
- Space-3: 12px
- Space-4: 16px
- Space-6: 24px
- Space-8: 32px
- Space-12: 48px
```

**사용 예시**:

```markdown
## 레이아웃 간격

- 섹션 간격: Space-12
- 카드 내부 패딩: Space-4
- 버튼 간격: Space-2
```

---

## 2. 기본 컴포넌트

### 2.1 버튼 (Button)

**참조**: `.ux-docs/UX_PATTERNS.md`

#### 버튼 Variants

| Variant | 용도 | 스타일 |
|---------|------|--------|
| Primary | 주요 동작 (페이지당 1개) | Solid, Primary-500 배경 |
| Secondary | 보조 동작 | Outline, Primary-500 테두리 |
| Tertiary | 추가 옵션 | Text only, Primary-500 색상 |
| Danger | 삭제/위험 동작 | Solid, Error-500 배경 |

#### 버튼 Sizes

| Size | 높이 | 패딩 | 폰트 |
|------|------|------|------|
| Large | 48px | 24px 좌우 | Body-L |
| Medium | 40px | 16px 좌우 | Body-M |
| Small | 32px | 12px 좌우 | Body-S |

#### 버튼 States

| State | 스타일 |
|-------|--------|
| Default | 기본 색상 |
| Hover | 10% 어두움 |
| Active | 20% 어두움 |
| Disabled | 40% 투명도, 클릭 불가 |
| Loading | 스피너 + 텍스트 "처리 중..." |

**기획서 표기**:

```markdown
## 버튼 정의

### 저장 버튼
- Variant: Primary
- Size: Medium
- 텍스트: "저장"
- 위치: 우측 하단
- States:
  - Default: Primary-500 배경
  - Loading: "저장 중..." + 스피너
  - Disabled: 필수 입력 필드 미작성 시
```

### 2.2 입력 필드 (Input Field)

#### Input Variants

| Variant | 용도 |
|---------|------|
| Text | 단일 줄 텍스트 |
| Textarea | 여러 줄 텍스트 |
| Number | 숫자만 입력 |
| Email | 이메일 형식 검증 |
| Password | 비밀번호 (마스킹) |

#### Input States

| State | 스타일 |
|-------|--------|
| Default | Gray-300 테두리 |
| Focus | Primary-500 테두리, 2px |
| Error | Error-500 테두리 + 오류 메시지 (하단) |
| Disabled | Gray-100 배경, 입력 불가 |

**기획서 표기**:

```markdown
## 입력 필드 정의

### 이메일 입력
- Variant: Email
- Label: "이메일 *필수"
- Placeholder: "user@example.com"
- Helper text: "회사 이메일을 입력해주세요"
- Validation:
  - 형식: 이메일 패턴 검증
  - 오류 메시지: "올바른 이메일 형식을 입력해주세요"
```

### 2.3 카드 (Card)

#### Card Variants

| Variant | 용도 | 스타일 |
|---------|------|--------|
| Default | 일반 콘텐츠 | 테두리, 그림자 없음 |
| Elevated | 강조 콘텐츠 | 그림자 있음 |
| Outlined | 구분 필요 콘텐츠 | 테두리 있음 |

**기획서 표기**:

```markdown
## 카드 정의

### 프로젝트 카드
- Variant: Elevated
- 크기: 320x240px
- 패딩: Space-4
- 그림자: Shadow-2
- 구성:
  - 상단: 프로젝트 썸네일 (240x120px)
  - 중간: 프로젝트명 (Heading-M)
  - 하단: 상태 태그 + 수정일 (Body-S, Gray-500)
- Hover: 그림자 강화 (Shadow-4)
```

---

## 3. 복합 컴포넌트

### 3.1 모달 (Modal)

**구조**:

```
+----------------------------------+
| ✕ (닫기)                        |
| {제목} (Heading-L)              |
| -------------------------------- |
| {본문 콘텐츠}                   |
| -------------------------------- |
| [취소] [확인]                   |
+----------------------------------+
```

**기획서 표기**:

```markdown
## 모달 정의

### 삭제 확인 모달
- 크기: 400x240px (고정)
- 위치: 화면 중앙
- 배경: 반투명 Black (0.5 opacity)
- 구성:
  - 제목: "프로젝트 삭제" (Heading-L)
  - 본문: "정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."
  - 버튼:
    - 취소: Secondary, Medium
    - 삭제: Danger, Medium
- Behavior:
  - Esc 키: 모달 닫기
  - 배경 클릭: 모달 닫기
  - 포커스: 첫 번째 버튼 (취소)
```

### 3.2 테이블 (Table)

**기획서 표기**:

```markdown
## 테이블 정의

### 프로젝트 목록 테이블
- 컬럼:
  1. 체크박스 (40px)
  2. 프로젝트명 (300px, Sortable)
  3. 상태 (120px, Tag)
  4. 생성일 (150px, Sortable)
  5. 액션 (80px, 아이콘 버튼)
- 스타일:
  - 헤더: Gray-100 배경, Heading-M
  - 행: Hover 시 Gray-50 배경
  - 구분선: Gray-300, 1px
- Pagination:
  - 위치: 테이블 하단
  - 페이지당 20개 항목
```

---

## 4. 페이지 템플릿

### 4.1 대시보드 레이아웃

```
+------------------+------------------+
| Sidebar (240px)  | Main Content     |
| - Logo           | - Header (64px)  |
| - Navigation     | - Breadcrumb     |
| - User Profile   | - Content        |
+------------------+------------------+
```

### 4.2 폼 레이아웃

```
+----------------------------------+
| Header                           |
| - Title                          |
| - Subtitle                       |
+----------------------------------+
| Form Fields (최대 600px 너비)   |
| - Field 1                        |
| - Field 2                        |
| ...                              |
+----------------------------------+
| Actions (우측 정렬)              |
| [취소] [저장]                   |
+----------------------------------+
```

---

## 자동 검증

기획서 작성 시 다음을 자동 체크:

```
[DESIGN SYSTEM] 검증 결과

❌ 잘못된 색상 사용:
   - 현재: #FF0000
   - 제안: Error-500 (#EA4335) 사용

⚠️ 비표준 컴포넌트:
   - "사용자 정의 버튼" 감지
   - 표준 Button 컴포넌트 사용 권장

✅ 올바른 타이포그래피 사용:
   - 제목: Heading-L
   - 본문: Body-M

개선 제안:
1. DESIGN_TOKENS.md의 정의된 색상 사용
2. UX_PATTERNS.md의 표준 컴포넌트 사용
3. 커스텀 컴포넌트 최소화
```

---

## 디자인 시스템 업데이트

### Figma 동기화

```bash
/ux figma-sync [Figma URL]
```

실행 시:
1. Figma에서 최신 디자인 토큰 추출
2. `DESIGN_TOKENS.md` 자동 업데이트
3. `UX_PATTERNS.md`에 새 컴포넌트 추가

### 수동 업데이트

새로운 컴포넌트 추가 시:

```markdown
## {컴포넌트명}

### Variants
{Variants 정의}

### Sizes
{Sizes 정의}

### States
{States 정의}

### 사용 예시
{예시 코드}
```

---

## 참조 파일

- `.ux-docs/DESIGN_TOKENS.md` - 색상, 타이포, 간격
- `.ux-docs/UX_PATTERNS.md` - 컴포넌트 패턴
- Figma: [디자인 시스템 라이브러리](링크)
