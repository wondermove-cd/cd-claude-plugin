#!/bin/bash

# ============================================
# CD Claude Plugin - Symlink 설치 스크립트
# ============================================
# 복사 대신 심볼릭 링크로 연결하여 중앙 관리 가능
# ============================================

# 색상 정의
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} CD Claude Plugin - Symlink 설치${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# 플러그인 디렉토리 확인
PLUGIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo -e "${GREEN}✓${NC} 플러그인 디렉토리: $PLUGIN_DIR"

# 대상 디렉토리 확인
TARGET_DIR=$(pwd)
echo -e "${GREEN}✓${NC} 설치 대상: $TARGET_DIR"
echo ""

# .claude 디렉토리 생성
if [ ! -d ".claude" ]; then
    mkdir -p .claude
    echo -e "${GREEN}✓${NC} .claude 디렉토리 생성"
fi

# 기존 파일 백업 (복사된 파일이 있는 경우)
if [ -d ".claude/commands" ] && [ ! -L ".claude/commands" ]; then
    echo -e "${YELLOW}⚠️  기존 commands 폴더 발견 - 백업 중...${NC}"
    mv .claude/commands .claude/commands.backup.$(date +%Y%m%d_%H%M%S)
fi

if [ -d ".claude/skills" ] && [ ! -L ".claude/skills" ]; then
    echo -e "${YELLOW}⚠️  기존 skills 폴더 발견 - 백업 중...${NC}"
    mv .claude/skills .claude/skills.backup.$(date +%Y%m%d_%H%M%S)
fi

# Symlink 생성 함수
create_symlink() {
    local source="$1"
    local target="$2"

    # 기존 심링크가 있으면 삭제
    if [ -L "$target" ]; then
        rm "$target"
    fi

    # 심볼릭 링크 생성
    ln -s "$source" "$target"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Symlink 생성: $(basename "$target")"
    else
        echo -e "${RED}✗${NC} Symlink 실패: $(basename "$target")"
        return 1
    fi
}

# Commands 심링크
echo ""
echo "📁 Commands 연결 중..."
create_symlink "$PLUGIN_DIR/.claude/commands" ".claude/commands"

# Skills 심링크
echo ""
echo "🎯 Skills 연결 중..."
create_symlink "$PLUGIN_DIR/.claude/skills" ".claude/skills"

# Templates는 복사 (프로젝트별 커스터마이징 필요)
echo ""
echo "📄 Templates 복사 중..."
if [ ! -d ".claude/templates" ]; then
    mkdir -p .claude/templates
fi

for template in "$PLUGIN_DIR"/.claude/templates/*.md; do
    if [ -f "$template" ]; then
        filename=$(basename "$template")
        if [ ! -f ".claude/templates/$filename" ]; then
            cp "$template" ".claude/templates/"
            echo -e "${GREEN}✓${NC} Template 복사: $filename"
        else
            echo -e "${YELLOW}○${NC} Template 존재: $filename (건너뜀)"
        fi
    fi
done

# 프로젝트별 설정 파일 생성 (없는 경우)
if [ ! -f ".claude/config.json" ]; then
    echo ""
    echo "⚙️  설정 파일 생성 중..."
    cat > .claude/config.json << 'EOF'
{
  "project": {
    "name": "",
    "code": "",
    "description": ""
  },
  "hooks": {
    "post-push": {
      "enabled": false,
      "auto_update_confluence": false
    }
  },
  "skills": {
    "context-manager": {
      "enabled": true,
      "auto_suggest_save": true,
      "auto_suggest_restore": true
    }
  },
  "symlink_mode": true,
  "plugin_version": "symlink",
  "plugin_path": "PLUGIN_PATH_PLACEHOLDER"
}
EOF

    # 플러그인 경로 삽입
    sed -i '' "s|PLUGIN_PATH_PLACEHOLDER|$PLUGIN_DIR|g" .claude/config.json
    echo -e "${GREEN}✓${NC} config.json 생성"
fi

# 상태 디렉토리 생성
if [ ! -d ".claude-state" ]; then
    mkdir -p .claude-state
    echo -e "${GREEN}✓${NC} .claude-state 디렉토리 생성"
fi

# .ux-docs 디렉토리 생성 (없는 경우)
if [ ! -d ".ux-docs" ]; then
    mkdir -p .ux-docs
    echo -e "${GREEN}✓${NC} .ux-docs 디렉토리 생성"
fi

# 설치 검증
echo ""
echo "🔍 설치 검증 중..."

# Symlink 확인
if [ -L ".claude/commands" ]; then
    command_count=$(ls -1 "$PLUGIN_DIR/.claude/commands/"*.md 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} Commands: ${command_count}개 (Symlink)"
else
    echo -e "${RED}✗${NC} Commands symlink 실패"
fi

if [ -L ".claude/skills" ]; then
    skill_count=$(ls -1 "$PLUGIN_DIR/.claude/skills/"*/skill.md 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} Skills: ${skill_count}개 (Symlink)"
else
    echo -e "${RED}✗${NC} Skills symlink 실패"
fi

template_count=$(ls -1 .claude/templates/*.md 2>/dev/null | wc -l)
echo -e "${GREEN}✓${NC} Templates: ${template_count}개 (복사됨)"

# 성공 메시지
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} ✅ Symlink 설치 완료!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "📋 설치 내용:"
echo " • Commands: 중앙 저장소와 연결 (자동 업데이트)"
echo " • Skills: 중앙 저장소와 연결 (자동 업데이트)"
echo " • Templates: 프로젝트별 복사 (커스터마이징 가능)"
echo ""
echo -e "${BLUE}💡 이제 플러그인 업데이트 시:${NC}"
echo "   1. cd ~/Documents/Claude/cd-claude-plugin"
echo "   2. git pull"
echo "   3. 모든 프로젝트에 자동 반영!"
echo ""
echo -e "${YELLOW}⚠️  주의사항:${NC}"
echo "   - Symlink가 깨지지 않도록 플러그인 폴더를 이동하지 마세요"
echo "   - 프로젝트별 커스터마이징은 templates 폴더에서만 가능합니다"
echo ""