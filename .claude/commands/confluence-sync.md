---
description: GitHub 레포지토리와 Confluence 문서를 수동으로 동기화합니다.
allowed-tools: Read, Bash
argument-hint: [--force] [--preview]
---

# /confluence-sync - Confluence 수동 동기화

CONFLUENCE.md 파일을 Confluence 페이지로 수동 업데이트합니다.

## 사용법

```bash
# 기본 동기화 (확인 메시지 표시)
/confluence-sync

# 강제 동기화 (확인 없이 바로 실행)
/confluence-sync --force

# 미리보기만 (실제 업데이트 없음)
/confluence-sync --preview
```

---

## 실행 절차

### Step 1: CONFLUENCE.md 읽기

```python
with open('CONFLUENCE.md', 'r', encoding='utf-8') as f:
    markdown_content = f.read()
```

### Step 2: Markdown → Confluence 변환

```python
confluence_html = markdown_to_confluence(markdown_content)
```

### Step 3: Confluence 페이지 업데이트

```python
# 페이지 ID: 1061912621
# Space: CG1
update_confluence_page(confluence_html)
```

---

## 출력 형식

```
============================================
 Confluence 동기화
============================================

📄 소스: CONFLUENCE.md
🔗 대상: CD Claude Plugin (1061912621)
📅 시간: 2025-12-30 17:30:00

📝 문서 크기: 15,234 문자
📦 섹션: 12개

✅ 동기화 완료!

Confluence: https://wondermove-official.atlassian.net/wiki/spaces/CG1/pages/1061912621

============================================
```

---

## 참조

- **Hook 문서**: `.claude/hooks/post-push.md`
- **설정 파일**: `.claude/config.json`
