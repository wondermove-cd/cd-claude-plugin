---
description: 프로젝트 코드를 설정하거나 확인합니다. JIRA 티켓 생성 시 사용됩니다.
allowed-tools: Read, Write, Edit
argument-hint: [프로젝트코드]
---

# UX Project Code - 프로젝트 코드 관리

## 목적

프로젝트 코드를 설정하여 JIRA 티켓 생성 시 자동으로 prefix와 태그를 추가합니다.

## 사용법

```bash
# 프로젝트 코드 설정
/ux project-code SKUBER

# 현재 설정된 프로젝트 코드 확인
/ux project-code

# 프로젝트 코드 변경
/ux project-code NEW_CODE
```

## 실행 절차

### Step 1: 프로젝트 코드 확인

$ARGUMENTS에서 프로젝트 코드 파악:

- **인자 있음**: 새 프로젝트 코드 설정
- **인자 없음**: 현재 프로젝트 코드 표시

### Step 2: PROJECT_CONTEXT.md 로드

`.ux-docs/PROJECT_CONTEXT.md` 파일 읽기:

```markdown
## 프로젝트 정보

**프로젝트 코드**: SKUBER
**프로젝트명**: SKuber Kubernetes Management
```

### Step 3-A: 프로젝트 코드 설정 (인자 있음)

#### 검증

프로젝트 코드 형식 확인:
- 영문 대문자와 숫자만 허용
- 2-10자 길이
- 예: `SKUBER`, `PROJ1`, `DCP`

**잘못된 예시**:
```
❌ skuber (소문자 포함)
❌ SKU-BER (특수문자 포함)
❌ S (너무 짧음)
❌ VERY_LONG_PROJECT (너무 길고 특수문자 포함)
```

#### PROJECT_CONTEXT.md 업데이트

```markdown
## 프로젝트 정보

**프로젝트 코드**: {새 프로젝트 코드}
**프로젝트명**: {프로젝트명}
**시작일**: {날짜}
**상태**: {상태}
```

#### jira_config.json 업데이트

`.claude/integrations/jira_config.json`에도 저장:

```json
{
  "jira": {
    "enabled": true,
    "project_code": "{프로젝트 코드}",
    "project_key": "{JIRA 프로젝트 키}",
    ...
  }
}
```

### Step 3-B: 프로젝트 코드 조회 (인자 없음)

현재 설정된 프로젝트 코드 표시:

```
============================================
 현재 프로젝트 코드
============================================

 프로젝트 코드: SKUBER
 프로젝트명: SKuber Kubernetes Management

 사용 예시:
 • JIRA 티켓 제목: [SKUBER] 클러스터 모니터링 기능
 • JIRA 태그: SKUBER

 변경: /ux project-code NEW_CODE

============================================
```

### Step 4: 완료 보고

**설정 성공 시**:

```
============================================
 [UX PROJECT CODE] 프로젝트 코드 설정 완료
============================================

 프로젝트 코드: {코드}

 적용 위치:
 ✅ .ux-docs/PROJECT_CONTEXT.md
 ✅ .claude/integrations/jira_config.json

 JIRA 티켓 생성 시:
 • 제목 형식: [{코드}] 티켓 제목
 • 태그: {코드}

 다음 단계:
 1. JIRA 연동: /jira-init {JIRA_PROJECT_KEY}
 2. 티켓 생성: /jira-push

============================================
```

**미설정 상태 조회 시**:

```
============================================
 프로젝트 코드 미설정
============================================

 ⚠️ 프로젝트 코드가 설정되지 않았습니다.

 설정 방법:
 /ux project-code {프로젝트코드}

 예시:
 /ux project-code SKUBER
 /ux project-code DCP
 /ux project-code PLATFORM

 💡 Tip:
 프로젝트 코드는 JIRA 티켓 생성 시
 제목 prefix와 태그로 자동 추가됩니다.

============================================
```

---

## 프로젝트 코드 규칙

### 형식

- **허용**: 영문 대문자 (A-Z), 숫자 (0-9)
- **길이**: 2-10자
- **예시**: `SKUBER`, `DCP`, `PLATFORM`, `PROJ01`

### 사용 위치

#### 1. JIRA 티켓 제목

```
[{프로젝트코드}] {원본 제목}

예시:
원본: "클러스터 모니터링 기능"
변환: "[SKUBER] 클러스터 모니터링 기능"
```

#### 2. JIRA 태그 (Labels)

```
labels: ["{프로젝트코드}"]

예시: ["SKUBER"]
```

#### 3. 문서 참조

모든 기획 문서의 헤더에 자동 포함:

```markdown
# {문서 제목}

**프로젝트**: {프로젝트코드} - {프로젝트명}
```

---

## 자동 연계

### JIRA Push 전 체크

`/jira-push` 실행 시 프로젝트 코드 자동 확인:

```
[JIRA PUSH] 프로젝트 코드 확인

❌ 프로젝트 코드가 설정되지 않았습니다.

먼저 프로젝트 코드를 설정해주세요:
/ux project-code {코드}

예시: /ux project-code SKUBER
```

### 다중 프로젝트 관리

프로젝트별로 다른 코드 사용:

```bash
# 프로젝트 A
cd /project-a
/ux project-code PROJA

# 프로젝트 B
cd /project-b
/ux project-code PROJB
```

---

## 예시 시나리오

### 시나리오 1: 신규 프로젝트 시작

```bash
# 1. 프로젝트 초기화
/ux init "SKuber Kubernetes Management"

# 2. 프로젝트 코드 설정
/ux project-code SKUBER

# 3. 기획 진행
/ux plan "클러스터 모니터링"

# 4. JIRA 연동
/jira-init SKUBER-JIRA
/jira-push

# 결과: JIRA 티켓 제목 = "[SKUBER] 클러스터 모니터링"
```

### 시나리오 2: 기존 프로젝트 온보딩

```bash
# 1. 온보딩
/ux onboard

# 2. 프로젝트 코드 설정 요청 받음
> 프로젝트 코드를 입력해주세요: SKUBER

# 3. 자동 설정 및 진행
```

---

## 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| 형식 오류 | 소문자 또는 특수문자 포함 | 대문자와 숫자만 사용 |
| 변경 안됨 | 파일 권한 문제 | 파일 쓰기 권한 확인 |
| JIRA에 반영 안됨 | jira_config.json 미동기화 | `/ux project-code` 재실행 |

---

## 참조 파일

- `.ux-docs/PROJECT_CONTEXT.md` - 프로젝트 정보
- `.claude/integrations/jira_config.json` - JIRA 설정
