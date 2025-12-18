# drag.ly — macOS Menu Bar Drag & Paste Utility
Version: v0.1 (Toy Project)

You are **Claude Code (Local)**.

Your task is to design and implement a minimal macOS application called **drag.ly**.

This is a **small, focused utility**, not a full product.
Do NOT over-engineer.
Do NOT add cloud, accounts, sync, or AI features.

---

## 1. Core Problem

When users are reading LLM responses (ChatGPT, Claude, etc.), 
they often think of new points **while reading**.

Interrupting the chat input:
- Breaks context
- Pollutes prompts
- Reduces answer quality

Users need a way to:
- Temporarily queue thoughts
- Keep them visually separate
- Insert them later via **drag & paste**

---

## 2. Core Concept

**Queue thoughts → Drag → Paste anywhere**

Not:
- A note-taking app
- A clipboard manager
- A chat client

This is a **behavior-first utility**.

---

## 3. Platform & Constraints

- macOS only
- Native Swift
- Prefer AppKit (SwiftUI allowed if necessary)
- No web, no extensions
- No backend

---

## 4. App Type

### Menu Bar App
- No Dock icon (LSUIElement = true)
- Status bar icon always visible
- Left-click toggles floating window
- Right-click menu:
  - Show / Hide
  - Clear All
  - Quit

---

## 5. Floating Window

### Behavior
- Always-on-top
- Appears instantly
- Lightweight
- Minimal chrome

### Details
- Window level: floating / status
- Appears near cursor OR centered (choose one and document)
- ESC hides window
- Does NOT aggressively steal focus

---

## 6. Queue Items (Cards)

Each queued thought is:
- Plain text
- Short (1–3 lines typical)
- Editable before use
- Reorderable
- Deletable

---

## 7. Drag & Paste (Critical)

This is the **core feature**.

### Requirements
- Each card must be draggable
- Dragging exports **plain text**
- Must work with:
  - Browsers (ChatGPT, Claude)
  - Code editors (VS Code, Xcode)
  - Any standard text input

### Behavior
- Native macOS drag (NSPasteboard)
- Visual drag preview required
- On successful drop:
  - Decide and document:
    - Auto-remove card OR
    - Keep until manual delete

---

## 8. Keyboard UX

- Global hotkey to toggle window
- Enter = create new card
- ESC = hide window
- Optional:
  - Arrow key navigation
  - Cmd+Delete to remove card

If global hotkey requires Accessibility permission, that is acceptable.

---

## 9. Data & Persistence

- In-memory queue is enough
- Persistence across app restarts is OPTIONAL
- If implemented:
  - Use UserDefaults or lightweight local storage
  - No CoreData unless absolutely necessary

---

## 10. Architecture (Suggested)

- AppDelegate / App lifecycle
- MenuBarController
- FloatingWindowController
- QueueStore (simple observable)
- QueueItem model
- DragProvider (pasteboard integration)

Keep it simple and readable.

---

## 11. Non-Goals (Strict)

Do NOT implement:
- Cloud sync
- AI features
- App detection
- Auto-paste
- Browser injection
- User accounts
- Formatting / markdown
- Multi-device support

---

## 12. Definition of Done (v0.1)

- App runs as menu bar app
- Floating window toggles instantly
- Thoughts can be queued in < 1 second
- Cards can be dragged into ChatGPT / Claude inputs
- No crashes
- Code is clean and understandable

---

## 13. Instruction Order

1. Confirm key UX decisions (window behavior, card removal)
2. Propose a concrete implementation plan
3. Implement step by step
4. Do NOT add extra features

This is a **small, sharp tool**.
Focus on speed, clarity, and reliability.
