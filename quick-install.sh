#!/bin/bash

# ============================================
# CD Claude Plugin - 원라인 설치 스크립트
# ============================================
# 사용법:
#   curl -sSL https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/quick-install.sh | bash
# 또는:
#   wget -qO- https://raw.githubusercontent.com/wondermove-cd/cd-claude-plugin/main/quick-install.sh | bash
# ============================================

set -e

# 색상 정의
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} CD Claude Plugin - 빠른 설치${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# 플러그인 디렉토리 설정
PLUGIN_DIR="$HOME/Documents/Claude/cd-claude-plugin"

# 1. 플러그인 디렉토리 확인/클론/업데이트
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "📥 플러그인을 GitHub에서 다운로드 중..."
    echo ""

    # SSH 먼저 시도
    if git clone git@github.com:wondermove-cd/cd-claude-plugin.git "$PLUGIN_DIR" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} GitHub 클론 완료 (SSH)"
    else
        # HTTPS로 대체
        echo "SSH 실패. HTTPS로 시도 중..."
        git clone https://github.com/wondermove-cd/cd-claude-plugin.git "$PLUGIN_DIR"
        echo -e "${GREEN}✓${NC} GitHub 클론 완료 (HTTPS)"
    fi
else
    echo "🔄 플러그인 최신 버전으로 업데이트 중..."
    cd "$PLUGIN_DIR"
    git pull origin main
    echo -e "${GREEN}✓${NC} 플러그인 업데이트 완료"
fi

echo ""

# 2. 현재 프로젝트에 Symlink 설치
CURRENT_DIR=$(pwd)
echo "📁 현재 프로젝트: $CURRENT_DIR"
echo ""

# install-symlink.sh 실행
if [ -f "$PLUGIN_DIR/install-symlink.sh" ]; then
    bash "$PLUGIN_DIR/install-symlink.sh"
else
    echo -e "${RED}❌ 설치 스크립트를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} ✅ 설치 완료!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "사용 가능한 명령어를 보려면: /help"
echo ""