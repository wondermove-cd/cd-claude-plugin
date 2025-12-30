---
description: 작성된 매뉴얼 마크다운 파일들을 PPT 생성 준비 상태로 빌드합니다.
allowed-tools: Read, Write, Edit, Glob, Bash
argument-hint:
---

# UX Manual Build - 매뉴얼 빌드

## 목적

sections/ 폴더의 모든 마크다운 파일을 취합하고 PPT 생성을 위한 최종 파일을 준비합니다.

## 실행 절차

### Step 1: 매뉴얼 프로젝트 확인

`.ux-docs/manuals/` 디렉토리에서 매뉴얼 프로젝트 찾기:

- 프로젝트가 여러 개인 경우: 사용자에게 선택 요청

### Step 2: 완성도 검증

#### 필수 파일 체크

```
✅ MANUAL_OUTLINE.md 존재
✅ MANUAL_STYLE_GUIDE.md 존재
✅ sections/ 폴더에 최소 3개 이상 파일
```

#### 섹션 파일 검증

각 `.md` 파일에 대해:

```
- [ ] TODO 체크리스트 모두 완료?
- [ ] [스크린샷: ...] 태그의 파일이 실제 존재?
- [ ] 제목 포맷 일관성 확인
```

**경고 표시**:
```
⚠️ 미완성 섹션:
- sections/03_01_cluster.md - TODO 2개 남음
- sections/04_settings.md - 스크린샷 1개 누락
```

### Step 3: 스크린샷 매핑

모든 마크다운 파일에서 `[스크린샷: {파일명}]` 패턴 추출:

```markdown
## 스크린샷 매핑 테이블

| 파일명 | 참조 위치 | 상태 |
|--------|----------|------|
| 02_01_login.png | sections/02_getting_started.md:15 | ✅ |
| 03_01_cluster_main.png | sections/03_01_cluster.md:25 | ❌ 누락 |
| 03_01_cluster_step1.png | sections/03_01_cluster.md:35 | ✅ |
```

### Step 4: 통합 마크다운 생성

모든 섹션 파일을 목차 순서대로 결합:

```markdown
# {제품명} 사용자 매뉴얼

버전: v1.0
작성일: {날짜}

---

{sections/00_cover.md 내용}

---

{sections/01_overview.md 내용}

---

{sections/02_getting_started.md 내용}

---

...

---

## 문서 정보

- 총 페이지: {계산된 페이지 수}
- 스크린샷: {n}개
- 최종 수정일: {날짜}
```

**저장 위치**: `output/{제품명}_Manual_Full.md`

### Step 5: PPT 생성 가이드 출력

```markdown
# PPT 생성 가이드

## 1. 자동 변환 (권장)

### 옵션 A: Markdown to PPT 도구 사용

```bash
# Marp 사용 예시
npm install -g @marp-team/marp-cli
marp output/{제품명}_Manual_Full.md -o output/{제품명}_Manual.pptx --theme corporate
```

### 옵션 B: Python 스크립트 사용

```python
# python-pptx 라이브러리 사용
pip install python-pptx markdown
python scripts/md_to_ppt.py output/{제품명}_Manual_Full.md
```

## 2. 수동 변환

### 템플릿 다운로드

1. PowerPoint 템플릿 열기: `templates/manual_template.pptx`
2. 마스터 슬라이드 확인:
   - Title Slide (표지)
   - Section Header (섹션 제목)
   - Content with Image (기능 소개)
   - Steps Layout (단계별 가이드)
   - Table Layout (표/비교)

### 슬라이드 생성 순서

1. **표지 슬라이드**
   - 템플릿: Title Slide
   - 내용: 제품명, 버전, 날짜

2. **목차 슬라이드**
   - MANUAL_OUTLINE.md 기반

3. **섹션별 슬라이드**

각 마크다운 파일을:

#### 기능 소개 페이지 → Content with Image

- 좌측: 제목 + 설명
- 우측: 스크린샷
- 하단: 주요 특징 3개 (아이콘 + 텍스트)

#### 단계별 가이드 → Steps Layout

- 각 Step을 개별 슬라이드로 분리
- Step 번호 강조
- 스크린샷 우측 배치

#### 표/비교 → Table Layout

- 제목
- 표 내용
- 하단 참고사항

## 3. 스크린샷 삽입

### 자동 삽입

마크다운의 `[스크린샷: {파일명}]` 태그를 찾아:

```
assets/screenshots/{파일명}
```

해당 위치의 이미지를 PPT 슬라이드에 자동 삽입

### 수동 삽입

1. PPT에서 **삽입 > 그림** 메뉴
2. `assets/screenshots/` 폴더에서 해당 파일 선택
3. 크기 조정 및 배치

## 4. 최종 검토

- [ ] 모든 스크린샷 삽입 확인
- [ ] 페이지 번호 확인
- [ ] 폰트 일관성 확인
- [ ] 색상/브랜딩 가이드 적용
- [ ] 오탈자 검토
```

**저장 위치**: `output/PPT_GENERATION_GUIDE.md`

### Step 6: 빌드 리포트 생성

```markdown
# 매뉴얼 빌드 리포트

**제품명**: {제품명}
**빌드 일시**: {날짜 시간}
**빌더**: Claude Code UX Plugin

---

## 통계

| 항목 | 수량 |
|------|------|
| 총 섹션 | {n}개 |
| 총 페이지 (예상) | {n}페이지 |
| 스크린샷 | {n}개 |
| 단어 수 | {n} |

---

## 완성도

### 완료된 섹션 ({n}/{총n})

- ✅ 00_cover.md
- ✅ 01_overview.md
- ✅ 02_getting_started.md
...

### 미완성 섹션 ({n})

- ⚠️ 03_02_monitoring.md - TODO 2개 남음
- ⚠️ 05_faq.md - 내용 없음

---

## 스크린샷 상태

### 존재하는 스크린샷 ({n}/{총n})

- ✅ 02_01_login.png (150 KB)
- ✅ 03_01_cluster_main.png (320 KB)

### 누락된 스크린샷 ({n})

- ❌ 03_02_monitoring_dashboard.png
  - 참조 위치: sections/03_02_monitoring.md:25

---

## 다음 단계

1. ❌ 누락된 스크린샷 촬영
2. ⚠️ 미완성 섹션 작성 완료
3. ✅ PPT 생성 (자동 또는 수동)
4. ✅ 최종 검토 및 배포
```

**저장 위치**: `output/BUILD_REPORT.md`

### Step 7: 완료 보고

```
============================================
 [UX MANUAL BUILD] 빌드 완료
============================================

 매뉴얼: {제품명}

 생성된 파일:
 ✅ output/{제품명}_Manual_Full.md (통합 마크다운)
 ✅ output/PPT_GENERATION_GUIDE.md (PPT 생성 가이드)
 ✅ output/BUILD_REPORT.md (빌드 리포트)

 통계:
 📄 총 {n}페이지 (예상)
 📷 스크린샷 {n}/{총n}개
 ✅ 완료 섹션 {n}/{총n}개

 완성도: {퍼센트}%

 ⚠️ 주의사항:
 {미완성 섹션이 있으면 경고 표시}
 {누락된 스크린샷이 있으면 경고 표시}

 다음 단계:
 1. 빌드 리포트 확인:
    output/BUILD_REPORT.md

 2. PPT 생성 (옵션 선택):
    A. 자동 변환: output/PPT_GENERATION_GUIDE.md 참조
    B. 수동 작업: 템플릿 사용

 3. 최종 배포:
    output/{제품명}_Manual_v1.0.pptx

 💡 Tip:
 - 자동 변환 시 Marp 또는 python-pptx 사용 권장
 - 수동 작업 시 output/{제품명}_Manual_Full.md 참조

============================================
```

## PPT 자동 생성 스크립트 (옵션)

`.claude/integrations/md_to_ppt.py` 생성 (참고용):

```python
# Python-pptx를 사용한 자동 변환 예시
from pptx import Presentation
from pptx.util import Inches, Pt
import markdown
import re

def convert_md_to_ppt(md_file, output_ppt):
    # 마크다운 파싱
    with open(md_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # PPT 생성
    prs = Presentation('templates/manual_template.pptx')

    # 섹션별 슬라이드 생성
    # ... (구현 필요)

    prs.save(output_ppt)
    print(f"✅ PPT 생성 완료: {output_ppt}")

if __name__ == "__main__":
    import sys
    convert_md_to_ppt(sys.argv[1], sys.argv[1].replace('.md', '.pptx'))
```

## 참조 파일

- `.ux-docs/manuals/{제품명}/MANUAL_OUTLINE.md`
- `.ux-docs/manuals/{제품명}/sections/*.md`
- `.ux-docs/manuals/{제품명}/assets/screenshots/*.png`
