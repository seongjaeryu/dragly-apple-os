# drag.ly Makefile
# macOS에서 실행하세요.

.PHONY: all build release dmg clean help

# 기본 타겟
all: build

# Debug 빌드
build:
	@echo "Building drag.ly (Debug)..."
	xcodebuild -project dragly.xcodeproj -scheme dragly -configuration Debug build

# Release 빌드
release:
	@echo "Building drag.ly (Release)..."
	xcodebuild -project dragly.xcodeproj -scheme dragly -configuration Release build

# DMG 생성
dmg:
	@echo "Building DMG..."
	./scripts/build-dmg.sh

# 빌드 정리
clean:
	@echo "Cleaning..."
	rm -rf build/
	rm -rf release/
	rm -rf ~/Library/Developer/Xcode/DerivedData/dragly-*
	xcodebuild -project dragly.xcodeproj -scheme dragly clean

# 도움말
help:
	@echo "drag.ly Build Commands"
	@echo ""
	@echo "  make build    - Debug 빌드"
	@echo "  make release  - Release 빌드"
	@echo "  make dmg      - DMG 파일 생성"
	@echo "  make clean    - 빌드 파일 정리"
	@echo "  make help     - 이 도움말 표시"
