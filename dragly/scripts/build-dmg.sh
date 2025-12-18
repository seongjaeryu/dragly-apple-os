#!/bin/bash

#
# drag.ly DMG Builder
# macOS에서 실행하세요.
#
# 사용법:
#   cd dragly
#   ./scripts/build-dmg.sh
#

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 설정
APP_NAME="dragly"
VERSION="0.1"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build"
RELEASE_DIR="release"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  drag.ly DMG Builder${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# macOS 확인
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}오류: 이 스크립트는 macOS에서만 실행할 수 있습니다.${NC}"
    exit 1
fi

# Xcode 확인
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}오류: Xcode가 설치되어 있지 않습니다.${NC}"
    echo "App Store에서 Xcode를 설치하세요."
    exit 1
fi

# 프로젝트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

if [[ ! -f "dragly.xcodeproj/project.pbxproj" ]]; then
    echo -e "${RED}오류: dragly.xcodeproj를 찾을 수 없습니다.${NC}"
    echo "스크립트를 dragly 폴더 내에서 실행하세요."
    exit 1
fi

echo -e "${YELLOW}1단계: 이전 빌드 정리 중...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

echo -e "${YELLOW}2단계: Release 빌드 중...${NC}"
xcodebuild \
    -project dragly.xcodeproj \
    -scheme dragly \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | grep -E "(Building|Linking|Signing|error:|warning:)" || true

# 빌드된 앱 찾기
APP_PATH=$(find "$BUILD_DIR" -name "dragly.app" -type d | head -1)

if [[ -z "$APP_PATH" ]]; then
    echo -e "${RED}오류: 빌드된 앱을 찾을 수 없습니다.${NC}"
    exit 1
fi

echo -e "${GREEN}빌드 완료: $APP_PATH${NC}"

echo -e "${YELLOW}3단계: DMG 생성 준비 중...${NC}"

# DMG용 임시 디렉토리 생성
DMG_TEMP="$BUILD_DIR/dmg_temp"
mkdir -p "$DMG_TEMP"

# 앱 복사
cp -R "$APP_PATH" "$DMG_TEMP/"

# Applications 폴더 심볼릭 링크 생성
ln -s /Applications "$DMG_TEMP/Applications"

# 배경 이미지용 숨김 폴더 (선택사항)
# mkdir -p "$DMG_TEMP/.background"

echo -e "${YELLOW}4단계: DMG 파일 생성 중...${NC}"

# DMG 생성
hdiutil create \
    -volname "drag.ly" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$RELEASE_DIR/$DMG_NAME"

echo -e "${YELLOW}5단계: 정리 중...${NC}"
rm -rf "$DMG_TEMP"

# 결과 확인
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
if [[ -f "$DMG_PATH" ]]; then
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  빌드 성공!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "  파일: ${GREEN}$DMG_PATH${NC}"
    echo -e "  크기: ${GREEN}$DMG_SIZE${NC}"
    echo ""
    echo -e "설치 방법:"
    echo -e "  1. DMG 파일 더블클릭"
    echo -e "  2. drag.ly를 Applications 폴더로 드래그"
    echo -e "  3. Applications에서 drag.ly 실행"
    echo ""

    # Finder에서 열기
    open "$RELEASE_DIR"
else
    echo -e "${RED}오류: DMG 생성에 실패했습니다.${NC}"
    exit 1
fi
