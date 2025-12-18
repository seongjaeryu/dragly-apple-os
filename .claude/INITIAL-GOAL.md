# QueueNote (Toy Project) — macOS Menu Bar Floating Queue App
Version: Draft v0.1  
Purpose: Specification & Question List for Claude Code Implementation

---

## 1. Project Background

When using LLM chat tools (ChatGPT, Claude, Claude Code, etc.), users often think of additional points *while reading an answer*.
Interrupting the chat input mid-response can:
- Break context
- Pollute the prompt
- Reduce response quality

**QueueNote** is a lightweight macOS utility that lets users:
- Quickly queue thoughts as cards
- Keep them visually separate from the chat input
- Insert them later via drag-and-drop or paste

This is a **toy project**, but should be architected cleanly.

---

## 2. Core Goal (Immediate)

**macOS-only application** with:
- Menu bar (status bar) access
- Floating window that always stays on top
- Ultra-fast input for queued notes
- Minimal UI, zero friction

Web / browser extensions are **explicitly out of scope for v0.1**.

---

## 3. Primary UX Flow

1. User is reading an LLM response
2. New thought appears
3. User clicks menu bar icon OR uses global hotkey
4. Floating QueueNote window appears (frontmost)
5. User types a short note and presses Enter
6. Note becomes a draggable “card”
7. User continues reading LLM response
8. Later, user drags card into:
   - Chat input
   - Code editor
   - Text field
9. Card is consumed (removed or marked used)

---

## 4. Functional Requirements

### 4.1 Menu Bar App
- No Dock icon (LSUIElement)
- Status bar icon always visible
- Left-click toggles floating window
- Optional right-click menu:
  - Show / Hide
  - Clear all
  - Quit

### 4.2 Floating Window
- Always-on-top (`.floating` / `.statusBar` level)
- Appears centered or near cursor
- Does not steal focus aggressively
- Minimal shadow / border
- Resizable? (TBD)

### 4.3 Queue Notes
- Each note is a card
- Short text (1–3 lines typical)
- Editable before use
- Reorderable (drag inside app)
- Deletable

### 4.4 Drag & Drop
- Native macOS drag-out
- Must work with:
  - Browsers (ChatGPT, Claude, etc.)
  - Code editors (VS Code, Xcode)
- Dragging inserts plain text
- Visual drag preview required

### 4.5 Keyboard
- Global hotkey to toggle window
- Enter to submit note
- ESC to hide window
- Arrow keys to navigate cards (optional)

---

## 5. Non-Goals (v0.1)

- Cloud sync
- Multi-device support
- Web / browser extensions
- Automatic LLM detection
- AI features
- Rich formatting
- User accounts

---

## 6. Technical Constraints

### 6.1 Platform
- macOS only
- Minimum version: TBD (Monterey? Ventura?)

### 6.2 Language & Framework
Candidate options:
- Swift + AppKit
- SwiftUI + AppKit bridge
- Tauri (likely overkill)
- Electron (explicitly discouraged)

**Preference:** Native Swift (AppKit-first if needed)

---

## 7. Suggested Architecture (Initial)

- MenuBarController
- FloatingWindowController
- QueueStore (in-memory)
- QueueItem model
- DragProvider (NSPasteboard integration)

Persistence: optional, maybe UserDefaults (or none)

---

## 8. Open Questions (IMPORTANT)

Claude Code **must answer or decide** these before implementation.

### 8.1 Window Behavior
1. Should the floating window:
   - Auto-hide when focus is lost?
   - Stay visible until manually closed?
2. Should it appear:
   - Centered on screen?
   - Near mouse cursor?
   - Remember last position?

### 8.2 Drag & Drop Semantics
3. When a card is dragged out:
   - Should it auto-delete?
   - Should it remain until manually cleared?
4. Should drag include:
   - Plain text only?
   - Metadata (source, timestamp)?

### 8.3 Queue Limits
5. Max number of queue items?
6. Should older items auto-expire?

### 8.4 Keyboard UX
7. Global hotkey:
   - Fixed default?
   - User-configurable?
8. Should typing immediately focus input on open?

### 8.5 Persistence
9. Should queued notes persist across app restarts?
10. If yes, what is acceptable storage?
    - UserDefaults
    - Local JSON file
    - CoreData (probably overkill)

### 8.6 Visual Design
11. Light / dark mode?
12. Monospaced or system font?
13. Compact vs comfortable spacing?

### 8.7 Security / Permissions
14. Global hotkey requires Accessibility permission — acceptable?
15. Any sandbox restrictions that affect drag-out?

---

## 9. Stretch Ideas (Do NOT implement now)

- “Send to Chat” button for known apps
- Per-app queues
- Temporary markdown mode
- Auto-grouping thoughts
- Timeline view
- Web / browser injection (future)

---

## 10. Definition of Done (v0.1)

- Menu bar app runs
- Floating window toggles reliably
- Notes can be queued in < 1 second
- Dragging into ChatGPT / Claude works
- No crashes, no memory leaks
- Code is readable and minimal

---

## 11. Instruction to Claude Code

You are **Claude Code (Local)**.

Your task:
1. Review this document
2. Answer the open questions with reasonable defaults
3. Propose a concrete technical plan
4. ONLY THEN start implementation

Do NOT add features beyond scope.

