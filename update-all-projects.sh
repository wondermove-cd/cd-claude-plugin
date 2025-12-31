#!/bin/bash

# ============================================
# 모든 프로젝트 일괄 업데이트 스크립트
# ============================================
# 1. 플러그인 저장소 업데이트 (git pull)
# 2. Symlink 방식으로 설치된 프로젝트는 자동 반영
# 3. 복사 방식으로 설치된 프로젝트는 재설치
# ============================================

# 색상 정의
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} CD Claude Plugin - 전체 프로젝트 업데이트${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: 플러그인 저장소 업데이트
PLUGIN_DIR="$HOME/Documents/Claude/cd-claude-plugin"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}❌ 플러그인 디렉토리를 찾을 수 없습니다: $PLUGIN_DIR${NC}"
    exit 1
fi

echo "📡 플러그인 저장소 업데이트 중..."
cd "$PLUGIN_DIR" || exit 1

# 현재 커밋 해시 저장
OLD_COMMIT=$(git rev-parse HEAD)

# Git pull
git pull origin main

# 새 커밋 해시
NEW_COMMIT=$(git rev-parse HEAD)

echo ""

if [ "$OLD_COMMIT" == "$NEW_COMMIT" ]; then
    echo -e "${GREEN}✅ 이미 최신 버전입니다.${NC}"
else
    echo -e "${GREEN}✅ 플러그인 업데이트 완료${NC}"
    echo ""
    echo "📝 변경사항:"
    git log --oneline --no-merges $OLD_COMMIT..$NEW_COMMIT
fi

echo ""
echo "============================================"
echo ""

# Step 2: 프로젝트 검색 및 업데이트
echo "🔍 Claude 프로젝트 검색 중..."
echo ""

# 프로젝트 베이스 디렉토리들
PROJECT_BASES=(
    "$HOME/Documents/Claude"
    "$HOME/Projects"
    "$HOME/workspace"
)

SYMLINK_PROJECTS=()
COPY_PROJECTS=()
NO_PLUGIN_PROJECTS=()

# 각 베이스 디렉토리에서 .claude 폴더가 있는 프로젝트 찾기
for base in "${PROJECT_BASES[@]}"; do
    if [ -d "$base" ]; then
        while IFS= read -r project; do
            if [ -d "$project/.claude" ]; then
                project_name=$(basename "$project")

                # config.json 확인하여 설치 방식 파악
                if [ -f "$project/.claude/config.json" ]; then
                    if grep -q '"symlink_mode": true' "$project/.claude/config.json" 2>/dev/null; then
                        SYMLINK_PROJECTS+=("$project")
                    else
                        COPY_PROJECTS+=("$project")
                    fi
                elif [ -L "$project/.claude/commands" ]; then
                    # config.json은 없지만 symlink인 경우
                    SYMLINK_PROJECTS+=("$project")
                else
                    # config.json도 없고 symlink도 아닌 경우 (복사 방식)
                    COPY_PROJECTS+=("$project")
                fi
            fi
        done < <(find "$base" -maxdepth 2 -type d -name "*" ! -path "$PLUGIN_DIR" 2>/dev/null)
    fi
done

# 결과 출력
echo "📊 프로젝트 현황:"
echo ""

if [ ${#SYMLINK_PROJECTS[@]} -gt 0 ]; then
    echo -e "${GREEN}✓ Symlink 방식 (자동 업데이트됨): ${#SYMLINK_PROJECTS[@]}개${NC}"
    for project in "${SYMLINK_PROJECTS[@]}"; do
        echo "    • $(basename "$project")"
    done
    echo ""
fi

if [ ${#COPY_PROJECTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  복사 방식 (재설치 필요): ${#COPY_PROJECTS[@]}개${NC}"
    for project in "${COPY_PROJECTS[@]}"; do
        echo "    • $(basename "$project")"
    done
    echo ""
fi

# 복사 방식 프로젝트 업데이트 제안
if [ ${#COPY_PROJECTS[@]} -gt 0 ]; then
    echo "============================================"
    echo ""
    read -p "복사 방식 프로젝트를 Symlink 방식으로 전환하시겠습니까? [Y/n]: " -n 1 -r
    echo ""
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        for project in "${COPY_PROJECTS[@]}"; do
            echo "🔄 전환 중: $(basename "$project")"
            cd "$project" || continue

            # install-symlink.sh 실행
            if [ -f "$PLUGIN_DIR/install-symlink.sh" ]; then
                bash "$PLUGIN_DIR/install-symlink.sh"
            else
                echo -e "${RED}✗ install-symlink.sh를 찾을 수 없습니다${NC}"
            fi
            echo ""
        done
    else
        echo "복사 방식 프로젝트 업데이트를 건너뜁니다."
        echo ""
        echo "수동으로 업데이트하려면 각 프로젝트에서 다음 명령을 실행하세요:"
        echo "  bash ~/Documents/Claude/cd-claude-plugin/install.sh"
    fi
fi

# 완료 메시지
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} ✅ 전체 업데이트 완료!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

if [ ${#SYMLINK_PROJECTS[@]} -gt 0 ]; then
    echo "• Symlink 프로젝트: 자동 반영됨"
fi
if [ ${#COPY_PROJECTS[@]} -gt 0 ]; then
    echo "• 복사 방식 프로젝트: 전환 완료 또는 수동 업데이트 필요"
fi

echo ""
echo "💡 앞으로 플러그인 업데이트 시:"
echo "   1. 이 스크립트 실행: bash ~/Documents/Claude/cd-claude-plugin/update-all-projects.sh"
echo "   2. 또는 수동으로: cd ~/Documents/Claude/cd-claude-plugin && git pull"
echo ""