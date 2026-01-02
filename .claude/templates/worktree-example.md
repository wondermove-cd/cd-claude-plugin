# Worktree 구조 예시 (Epic > Task > Sub-task)

## 계층 구조 가이드

### 1️⃣ Epic (프로젝트/기능 단위)
- **범위**: 전체 프로젝트 또는 큰 기능 묶음
- **기간**: 2-4주
- **예시**:
  - "사용자 인증 시스템"
  - "대시보드 개발"
  - "결제 시스템 구축"

### 2️⃣ Task (구체적 작업 단위)
- **범위**: 독립적으로 완료 가능한 기능
- **기간**: 1-3일
- **예시**:
  - "로그인 화면 퍼블리싱"
  - "회원가입 API 구현"
  - "비밀번호 재설정 기능"
  - "프로필 페이지 UI 개발"

### 3️⃣ Sub-task (세부 구현 단위)
- **범위**: 코드 레벨의 구체적 작업
- **기간**: 2-4시간
- **예시**:
  - "로그인 폼 컴포넌트 제작"
  - "이메일 validation 로직 구현"
  - "비밀번호 암호화 함수 작성"
  - "에러 메시지 UI 컴포넌트"

## 실제 예시 1: 로그인 시스템

```json
{
  "epics": [
    {
      "id": "EPIC-001",
      "title": "사용자 인증 시스템",
      "description": "로그인, 회원가입, 비밀번호 관리 전체",
      "tasks": [
        {
          "id": "TASK-001",
          "title": "로그인 화면 퍼블리싱",
          "story_points": 3,
          "subtasks": [
            {
              "id": "SUB-001",
              "title": "로그인 폼 컴포넌트 제작",
              "description": "이메일/비밀번호 입력 필드와 레이아웃",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-002",
              "title": "폼 validation 로직 구현",
              "description": "이메일 형식, 필수 필드 체크",
              "time_estimate": "2h"
            },
            {
              "id": "SUB-003",
              "title": "에러 메시지 표시 컴포넌트",
              "description": "validation 실패 시 에러 UI",
              "time_estimate": "2h"
            },
            {
              "id": "SUB-004",
              "title": "자동 로그인 체크박스 기능",
              "description": "Remember me 옵션 구현",
              "time_estimate": "1h"
            },
            {
              "id": "SUB-005",
              "title": "비밀번호 표시/숨김 토글",
              "description": "패스워드 필드 visibility 토글",
              "time_estimate": "1h"
            },
            {
              "id": "SUB-006",
              "title": "로그인 버튼 로딩 상태",
              "description": "API 호출 중 로딩 스피너",
              "time_estimate": "2h"
            }
          ]
        },
        {
          "id": "TASK-002",
          "title": "로그인 API 구현",
          "subtasks": [
            {
              "id": "SUB-007",
              "title": "로그인 엔드포인트 생성",
              "description": "POST /api/auth/login 라우트"
            },
            {
              "id": "SUB-008",
              "title": "이메일/비밀번호 검증 미들웨어",
              "description": "입력값 validation middleware"
            },
            {
              "id": "SUB-009",
              "title": "비밀번호 매칭 로직",
              "description": "bcrypt compare 구현"
            },
            {
              "id": "SUB-010",
              "title": "JWT 토큰 발급 서비스",
              "description": "액세스/리프레시 토큰 생성"
            },
            {
              "id": "SUB-011",
              "title": "로그인 실패 처리",
              "description": "실패 횟수 카운트, 계정 잠금"
            },
            {
              "id": "SUB-012",
              "title": "로그인 이력 저장",
              "description": "로그인 시간, IP 기록"
            }
          ]
        },
        {
          "id": "TASK-003",
          "title": "회원가입 화면 퍼블리싱",
          "subtasks": [
            {
              "id": "SUB-013",
              "title": "회원가입 폼 컴포넌트",
              "description": "이메일, 비밀번호, 이름, 전화번호 필드"
            },
            {
              "id": "SUB-014",
              "title": "비밀번호 강도 표시기",
              "description": "실시간 패스워드 강도 체크 UI"
            },
            {
              "id": "SUB-015",
              "title": "이메일 중복 체크 UI",
              "description": "실시간 중복 확인 표시"
            },
            {
              "id": "SUB-016",
              "title": "약관 동의 체크박스",
              "description": "필수/선택 약관 UI"
            },
            {
              "id": "SUB-017",
              "title": "회원가입 단계 표시",
              "description": "Step indicator 컴포넌트"
            }
          ]
        },
        {
          "id": "TASK-004",
          "title": "회원가입 API 구현",
          "subtasks": [
            {
              "id": "SUB-018",
              "title": "User 엔티티 및 스키마",
              "description": "데이터베이스 테이블 생성"
            },
            {
              "id": "SUB-019",
              "title": "이메일 중복 체크 API",
              "description": "GET /api/auth/check-email"
            },
            {
              "id": "SUB-020",
              "title": "비밀번호 암호화 서비스",
              "description": "bcrypt 해싱 구현"
            },
            {
              "id": "SUB-021",
              "title": "회원가입 validation",
              "description": "입력값 검증 미들웨어"
            },
            {
              "id": "SUB-022",
              "title": "인증 이메일 발송",
              "description": "이메일 서비스 연동"
            },
            {
              "id": "SUB-023",
              "title": "회원가입 트랜잭션 처리",
              "description": "DB 트랜잭션 관리"
            }
          ]
        }
      ]
    }
  ]
}
```

## Task 분해 체크리스트

### Task 레벨 확인
- [ ] 1-3일 내 완료 가능한가?
- [ ] 한 명이 독립적으로 작업 가능한가?
- [ ] 명확한 완료 기준이 있는가?
- [ ] 테스트 가능한 단위인가?

### Sub-task 레벨 확인
- [ ] 2-4시간 내 완료 가능한가?
- [ ] 코드 레벨의 구체적 작업인가?
- [ ] PR 단위로 관리 가능한가?
- [ ] 의존성이 명확한가?

## 잘못된 예시 ❌

```json
{
  "tasks": [
    {
      "title": "프론트엔드 개발",  // ❌ 너무 광범위
      "subtasks": [
        {
          "title": "UI 작업"  // ❌ 구체적이지 않음
        }
      ]
    }
  ]
}
```

## 올바른 예시 ✅

```json
{
  "tasks": [
    {
      "title": "로그인 화면 퍼블리싱",  // ✅ 구체적
      "subtasks": [
        {
          "title": "로그인 폼 컴포넌트 제작"  // ✅ 명확한 작업
        }
      ]
    }
  ]
}
```

## 실제 예시 2: 대시보드 개발

```json
{
  "epics": [
    {
      "id": "EPIC-002",
      "title": "대시보드 시스템",
      "description": "사용자 대시보드 전체 구축",
      "tasks": [
        {
          "id": "TASK-005",
          "title": "대시보드 메인 화면 퍼블리싱",
          "story_points": 5,
          "subtasks": [
            {
              "id": "SUB-024",
              "title": "대시보드 레이아웃 컴포넌트",
              "description": "그리드 시스템, 반응형 레이아웃",
              "time_estimate": "4h"
            },
            {
              "id": "SUB-025",
              "title": "통계 카드 컴포넌트 제작",
              "description": "숫자, 차트, 트렌드 표시",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-026",
              "title": "실시간 업데이트 로직",
              "description": "WebSocket 연결, 데이터 스트림",
              "time_estimate": "4h"
            },
            {
              "id": "SUB-027",
              "title": "차트 라이브러리 연동",
              "description": "Chart.js 또는 D3.js 통합",
              "time_estimate": "3h"
            }
          ]
        },
        {
          "id": "TASK-006",
          "title": "위젯 커스터마이징 기능",
          "story_points": 3,
          "subtasks": [
            {
              "id": "SUB-028",
              "title": "위젯 드래그앤드롭 구현",
              "description": "react-dnd 라이브러리 활용",
              "time_estimate": "4h"
            },
            {
              "id": "SUB-029",
              "title": "위젯 크기 조절 기능",
              "description": "리사이즈 핸들러 구현",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-030",
              "title": "레이아웃 저장/불러오기",
              "description": "사용자별 레이아웃 설정 저장",
              "time_estimate": "2h"
            }
          ]
        }
      ]
    }
  ]
}
```

## 실제 예시 3: 상품 관리 시스템

```json
{
  "epics": [
    {
      "id": "EPIC-003",
      "title": "상품 관리 시스템",
      "description": "상품 등록, 수정, 조회 기능",
      "tasks": [
        {
          "id": "TASK-007",
          "title": "상품 목록 페이지 개발",
          "story_points": 5,
          "subtasks": [
            {
              "id": "SUB-031",
              "title": "상품 테이블 컴포넌트",
              "description": "페이징, 정렬, 필터링 기능",
              "time_estimate": "4h"
            },
            {
              "id": "SUB-032",
              "title": "검색 필터 UI 구현",
              "description": "카테고리, 가격, 상태별 필터",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-033",
              "title": "대량 작업 기능",
              "description": "다중 선택, 일괄 삭제/수정",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-034",
              "title": "엑셀 내보내기 기능",
              "description": "검색 결과 CSV/Excel 변환",
              "time_estimate": "2h"
            }
          ]
        },
        {
          "id": "TASK-008",
          "title": "상품 등록 폼 개발",
          "story_points": 8,
          "subtasks": [
            {
              "id": "SUB-035",
              "title": "기본 정보 입력 폼",
              "description": "상품명, 가격, 카테고리",
              "time_estimate": "2h"
            },
            {
              "id": "SUB-036",
              "title": "이미지 업로드 컴포넌트",
              "description": "다중 이미지, 드래그앤드롭",
              "time_estimate": "4h"
            },
            {
              "id": "SUB-037",
              "title": "에디터 컴포넌트 연동",
              "description": "상품 설명 WYSIWYG 에디터",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-038",
              "title": "옵션 관리 UI",
              "description": "색상, 사이즈 등 동적 옵션",
              "time_estimate": "4h"
            },
            {
              "id": "SUB-039",
              "title": "재고 관리 로직",
              "description": "옵션별 재고 수량 관리",
              "time_estimate": "3h"
            },
            {
              "id": "SUB-040",
              "title": "유효성 검사 로직",
              "description": "필수 필드, 형식 체크",
              "time_estimate": "2h"
            }
          ]
        }
      ]
    }
  ]
}
```

## Task 분해 가이드라인

### 🎯 Epic 레벨 체크포인트
- [ ] 전체 기능 묶음을 나타내는가?
- [ ] 2-4주 안에 완료 가능한 범위인가?
- [ ] 비즈니스 가치가 명확한가?
- [ ] 여러 Task로 분해 가능한가?

### 📋 Task 레벨 체크포인트
- [ ] 독립적으로 테스트 가능한가?
- [ ] 1-3일 내 완료 가능한가?
- [ ] 한 명의 개발자가 담당 가능한가?
- [ ] 구체적인 산출물이 있는가?
- [ ] Story Point 추정이 가능한가? (1-8점)

### ⚙️ Sub-task 레벨 체크포인트
- [ ] 2-4시간 내 완료 가능한가?
- [ ] 코드 레벨의 구체적 작업인가?
- [ ] PR 하나로 관리 가능한가?
- [ ] 시간 추정이 명확한가?
- [ ] 기술적 구현 방법이 명확한가?