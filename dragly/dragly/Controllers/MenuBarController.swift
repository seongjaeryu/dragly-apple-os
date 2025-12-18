import Cocoa
import Combine

class MenuBarController {
    private var statusItem: NSStatusItem
    private var queueStore: QueueStore
    private var floatingWindowController: FloatingWindowController
    private var cancellables = Set<AnyCancellable>()

    init(queueStore: QueueStore, floatingWindowController: FloatingWindowController) {
        self.queueStore = queueStore
        self.floatingWindowController = floatingWindowController

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        setupStatusButton()
        setupMenu()
        observeWindowPositionChanges()
    }

    private func setupStatusButton() {
        if let button = statusItem.button {
            // Temporary icon - using SF Symbol
            if let image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "drag.ly") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "D"
            }

            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Show/Hide", action: #selector(toggleWindow), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Clear Completed", action: #selector(clearCompleted), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reset Window Position", action: #selector(resetWindowPosition), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit drag.ly", action: #selector(quitApp), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = nil // We'll show menu on right-click only
    }

    private func observeWindowPositionChanges() {
        floatingWindowController.$hasCustomPosition
            .sink { [weak self] hasCustomPosition in
                self?.updateStatusIcon(hasCustomPosition: hasCustomPosition)
            }
            .store(in: &cancellables)
    }

    private func updateStatusIcon(hasCustomPosition: Bool) {
        guard let button = statusItem.button else { return }

        if hasCustomPosition {
            // Show reset indicator - different icon
            if let image = NSImage(systemSymbolName: "square.stack.3d.up.badge.automatic", accessibilityDescription: "drag.ly (custom position)") {
                image.isTemplate = true
                button.image = image
            }
        } else {
            // Default icon
            if let image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "drag.ly") {
                image.isTemplate = true
                button.image = image
            }
        }
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Show context menu on right-click
            let menu = createContextMenu()
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            // Toggle window on left-click
            toggleWindow()
        }
    }

    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()

        let showHideItem = NSMenuItem(title: floatingWindowController.isVisible ? "Hide" : "Show", action: #selector(toggleWindow), keyEquivalent: "")
        showHideItem.target = self
        menu.addItem(showHideItem)

        menu.addItem(NSMenuItem.separator())

        let clearCompletedItem = NSMenuItem(title: "Clear Completed", action: #selector(clearCompleted), keyEquivalent: "")
        clearCompletedItem.target = self
        menu.addItem(clearCompletedItem)

        let clearAllItem = NSMenuItem(title: "Clear All", action: #selector(clearAll), keyEquivalent: "")
        clearAllItem.target = self
        menu.addItem(clearAllItem)

        menu.addItem(NSMenuItem.separator())

        if floatingWindowController.hasCustomPosition {
            let resetItem = NSMenuItem(title: "Reset Window Position", action: #selector(resetWindowPosition), keyEquivalent: "")
            resetItem.target = self
            menu.addItem(resetItem)
            menu.addItem(NSMenuItem.separator())
        }

        let quitItem = NSMenuItem(title: "Quit drag.ly", action: #selector(quitApp), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func toggleWindow() {
        floatingWindowController.toggle()
    }

    @objc private func clearCompleted() {
        queueStore.clearCompleted()
    }

    @objc private func clearAll() {
        queueStore.clearAll()
    }

    @objc private func resetWindowPosition() {
        floatingWindowController.resetPosition()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // Get status item frame for positioning
    var statusItemFrame: NSRect? {
        return statusItem.button?.window?.frame
    }
}
