# drag.ly

macOS Menu Bar Drag & Paste Utility — v0.1

## 개요

drag.ly는 LLM(ChatGPT, Claude 등) 응답을 읽는 중 떠오르는 생각을 임시로 큐에 저장해두었다가, 필요할 때 **드래그 & 페이스트**로 삽입할 수 있는 macOS 메뉴바 유틸리티입니다.

## 주요 기능

- **메뉴바 앱**: Dock에 표시되지 않음 (LSUIElement)
- **플로팅 윈도우**: Always-on-top, 즉시 표시
- **생각 큐잉**: 텍스트 카드 추가, 편집, 삭제, 재정렬
- **드래그 & 페이스트**: 카드를 드래그하여 어디든 텍스트 삽입
- **체크리스트 스타일**: 드래그 완료 시 checked 상태 (dim + shrink)
- **데이터 영속성**: UserDefaults를 통한 앱 재시작 후에도 데이터 유지

## 시스템 요구사항

- macOS 13.0 (Ventura) 이상
- Xcode 15.0 이상

## 설치 및 빌드

### Xcode에서 빌드

1. `dragly.xcodeproj` 파일을 Xcode에서 열기
2. 빌드 타겟이 `dragly`인지 확인
3. `⌘+R`로 빌드 및 실행

### 터미널에서 빌드

```bash
cd dragly
xcodebuild -project dragly.xcodeproj -scheme dragly -configuration Release build
```

## 사용법

### 기본 조작

| 동작 | 방법 |
|------|------|
| 윈도우 토글 | 메뉴바 아이콘 클릭 또는 `⌃+⌥+D` |
| 새 카드 추가 | 텍스트 입력 후 `Enter` |
| 카드 편집 | 카드 더블클릭 |
| 카드 드래그 | 카드를 드래그하여 원하는 위치에 드롭 |
| 윈도우 숨기기 | `ESC` 키 |
| 컨텍스트 메뉴 | 메뉴바 아이콘 우클릭 |

### 단축키

| 단축키 | 동작 |
|--------|------|
| `⌃+⌥+D` | 윈도우 토글 (글로벌 핫키) |
| `Enter` | 새 카드 추가 |
| `ESC` | 윈도우 숨기기 |

### 윈도우 위치/크기

- 윈도우는 드래그로 위치 이동 가능
- 모서리 드래그로 크기 조절 가능
- 위치/크기 변경 시 메뉴바 아이콘이 변경됨 (리셋 가능 표시)
- 우클릭 메뉴의 "Reset Window Position"으로 기본 위치로 복원

### 카드 상태

- **일반**: 드래그 대기 상태
- **Checked**: 드래그 완료 후 dim + height shrink 상태
- **Clear Completed**: 체크된 카드 일괄 삭제

## 프로젝트 구조

```
dragly/
├── dragly.xcodeproj/
│   └── project.pbxproj
└── dragly/
    ├── AppDelegate.swift          # 앱 진입점, 글로벌 핫키 등록
    ├── Info.plist                 # 앱 설정 (LSUIElement 등)
    ├── dragly.entitlements        # 권한 설정
    ├── Assets.xcassets/           # 앱 아이콘
    ├── Models/
    │   ├── QueueItem.swift        # 큐 아이템 모델
    │   └── QueueStore.swift       # 큐 저장소 (ObservableObject)
    ├── Controllers/
    │   ├── MenuBarController.swift        # 메뉴바 관리
    │   └── FloatingWindowController.swift # 플로팅 윈도우 관리
    └── Views/
        ├── FloatingContentView.swift      # 메인 콘텐츠 뷰
        └── CardView.swift                 # 개별 카드 뷰
```

## 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                      AppDelegate                         │
│  - 글로벌 핫키 등록 (⌃+⌥+D)                              │
│  - MenuBarController 초기화                              │
│  - FloatingWindowController 초기화                       │
└─────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
┌───────────────┐ ┌─────────────────┐ ┌─────────────┐
│ MenuBarController │ │ FloatingWindow  │ │ QueueStore  │
│                │ │   Controller    │ │ (Singleton) │
│ - StatusItem   │ │                 │ │             │
│ - 우클릭 메뉴  │ │ - NSWindow      │ │ - items[]   │
│ - 리셋 표시    │ │ - 위치/크기 저장│ │ - CRUD      │
└───────────────┘ │ - ESC 처리      │ │ - UserDefaults│
                  └─────────────────┘ └─────────────┘
                            │
                            ▼
                  ┌─────────────────┐
                  │FloatingContentView│
                  │                 │
                  │ - Header        │
                  │ - QueueList     │
                  │ - InputArea     │
                  └─────────────────┘
                            │
                            ▼
                  ┌─────────────────┐
                  │    CardView     │
                  │                 │
                  │ - 텍스트 표시   │
                  │ - 드래그 지원   │
                  │ - checked 상태  │
                  │ - 애니메이션    │
                  └─────────────────┘
```

## 권한

- **Accessibility**: 글로벌 핫키 사용을 위해 필요할 수 있음
  - 시스템 환경설정 > 개인정보 및 보안 > 손쉬운 사용에서 앱 허용

## 제한사항

- macOS 전용
- 클라우드 동기화 없음
- 멀티 디바이스 지원 없음
- Markdown/서식 지원 없음

## 라이선스

Copyright © 2024. All rights reserved.
