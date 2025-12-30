#!/bin/bash

# CD Claude Plugin Installer
# 원더무브 연구소 - 기획/디자인 팀 전용 Claude Code 플러그인

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} CD Claude Plugin - 설치 스크립트${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if running in a directory
check_directory() {
    if [ ! -d ".git" ]; then
        print_warning "현재 디렉토리가 Git 프로젝트가 아닙니다."
        read -p "여기에 플러그인을 설치하시겠습니까? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            print_error "설치가 취소되었습니다."
            exit 1
        fi
    fi
}

# Backup existing .claude directory
backup_existing() {
    if [ -d ".claude" ]; then
        print_warning ".claude 폴더가 이미 존재합니다."
        backup_dir=".claude.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "기존 폴더를 백업합니다: $backup_dir"
        mv .claude "$backup_dir"
        print_success "백업 완료: $backup_dir"
    fi

    if [ -f "CLAUDE.md" ]; then
        print_warning "CLAUDE.md 파일이 이미 존재합니다."
        mv CLAUDE.md "CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "기존 CLAUDE.md 백업 완료"
    fi
}

# Download and install
install_plugin() {
    print_info "플러그인을 다운로드합니다..."

    # Create temporary directory
    temp_dir=$(mktemp -d)

    # Clone repository
    git clone --depth 1 https://github.com/wondermove-cd/cd-claude-plugin.git "$temp_dir" 2>/dev/null || {
        print_error "다운로드에 실패했습니다."
        print_error "레포지토리 URL을 확인해주세요: https://github.com/wondermove-cd/cd-claude-plugin"
        rm -rf "$temp_dir"
        exit 1
    }

    # Copy files
    print_info "파일을 복사합니다..."
    cp -r "$temp_dir/.claude" .
    cp "$temp_dir/CLAUDE.md" .

    # Cleanup
    rm -rf "$temp_dir"

    print_success "플러그인 파일 복사 완료"
}

# Create initial structure
create_structure() {
    print_info "초기 디렉토리 구조를 생성합니다..."

    # Create directories
    mkdir -p .ux-docs
    mkdir -p .claude-state
    mkdir -p docs

    # Create .gitignore if not exists
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
# Claude Code state
.claude-state/
.ux-docs/
docs/

# Environment
.env
.env.local

# macOS
.DS_Store
EOF
        print_success ".gitignore 생성 완료"
    fi

    print_success "디렉토리 구조 생성 완료"
}

# Show next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN} 설치 완료!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${BLUE}📂 설치된 구조:${NC}"
    echo "  .claude/          - 플러그인 파일"
    echo "  CLAUDE.md         - 메인 설정 파일"
    echo "  .ux-docs/         - UX 문서 저장소 (자동 생성)"
    echo "  .claude-state/    - 런타임 상태 (자동 생성)"
    echo ""
    echo -e "${BLUE}🚀 다음 단계:${NC}"
    echo ""
    echo "  1. Claude Code 실행"
    echo ""
    echo "  2. 프로젝트 초기화 (둘 중 하나 선택)"
    echo -e "     ${YELLOW}신규 프로젝트:${NC} /ux init \"프로젝트명\""
    echo -e "     ${YELLOW}기존 프로젝트:${NC} /ux onboard"
    echo ""
    echo "  3. 프로젝트 코드 설정 (JIRA 티켓용)"
    echo -e "     ${YELLOW}/ux project-code SKUBER${NC}"
    echo ""
    echo "  4. 기획 시작"
    echo -e "     ${YELLOW}/ux plan \"기능명\"${NC}"
    echo ""
    echo -e "${BLUE}📖 상세 가이드:${NC}"
    echo "  https://github.com/wondermove-cd/cd-claude-plugin"
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo ""
}

# Main installation process
main() {
    print_header

    # Check directory
    check_directory

    # Backup existing files
    backup_existing

    # Install plugin
    install_plugin

    # Create structure
    create_structure

    # Show next steps
    show_next_steps
}

# Run main
main
