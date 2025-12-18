import Cocoa
import SwiftUI
import Combine

class FloatingWindowController: NSObject, ObservableObject {
    private var window: NSWindow?
    private var queueStore: QueueStore
    private var cancellables = Set<AnyCancellable>()

    @Published var hasCustomPosition: Bool = false
    @Published var isVisible: Bool = false

    private let defaultWidth: CGFloat = 320
    private let defaultHeight: CGFloat = 400
    private let windowPositionKey = "dragly.windowPosition"
    private let windowSizeKey = "dragly.windowSize"

    init(queueStore: QueueStore) {
        self.queueStore = queueStore
        super.init()
        setupWindow()
        loadSavedPositionAndSize()
    }

    private func setupWindow() {
        let contentView = FloatingContentView(queueStore: queueStore)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: defaultWidth, height: defaultHeight),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        guard let window = window else { return }

        window.contentView = NSHostingView(rootView: contentView)
        window.title = "drag.ly"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor.windowBackgroundColor

        // Set minimum size
        window.minSize = NSSize(width: 280, height: 200)

        // Observe window movements and resizes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: window
        )

        // Handle ESC key to hide window
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.hide()
                return nil
            }
            return event
        }
    }

    private func loadSavedPositionAndSize() {
        let hasPosition = UserDefaults.standard.object(forKey: windowPositionKey) != nil
        let hasSize = UserDefaults.standard.object(forKey: windowSizeKey) != nil

        if hasPosition || hasSize {
            hasCustomPosition = true

            if let positionData = UserDefaults.standard.data(forKey: windowPositionKey),
               let position = try? JSONDecoder().decode(CGPoint.self, from: positionData) {
                window?.setFrameOrigin(position)
            }

            if let sizeData = UserDefaults.standard.data(forKey: windowSizeKey),
               let size = try? JSONDecoder().decode(CGSize.self, from: sizeData) {
                window?.setContentSize(size)
            }
        }
    }

    private func savePositionAndSize() {
        guard let window = window else { return }

        if let positionData = try? JSONEncoder().encode(window.frame.origin) {
            UserDefaults.standard.set(positionData, forKey: windowPositionKey)
        }

        if let sizeData = try? JSONEncoder().encode(window.frame.size) {
            UserDefaults.standard.set(sizeData, forKey: windowSizeKey)
        }

        hasCustomPosition = true
    }

    @objc private func windowDidMove(_ notification: Notification) {
        savePositionAndSize()
    }

    @objc private func windowDidResize(_ notification: Notification) {
        savePositionAndSize()
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let window = window else { return }

        if !hasCustomPosition {
            positionBelowMenuBar()
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
    }

    func hide() {
        window?.orderOut(nil)
        isVisible = false
    }

    func resetPosition() {
        UserDefaults.standard.removeObject(forKey: windowPositionKey)
        UserDefaults.standard.removeObject(forKey: windowSizeKey)

        window?.setContentSize(NSSize(width: defaultWidth, height: defaultHeight))
        positionBelowMenuBar()

        hasCustomPosition = false
    }

    private func positionBelowMenuBar() {
        guard let window = window,
              let screen = NSScreen.main else { return }

        let menuBarHeight: CGFloat = NSStatusBar.system.thickness
        let screenFrame = screen.frame
        let visibleFrame = screen.visibleFrame

        // Position window at center-top, below menu bar
        let x = screenFrame.midX - window.frame.width / 2
        let y = visibleFrame.maxY - window.frame.height - 10 // 10px padding from menu bar

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // Position near status item
    func positionNearStatusItem(statusItemFrame: NSRect) {
        guard let window = window else { return }

        let x = statusItemFrame.midX - window.frame.width / 2
        let y = statusItemFrame.minY - window.frame.height - 5

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
