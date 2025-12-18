import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var floatingWindowController: FloatingWindowController?
    private var hotKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize the queue store
        let queueStore = QueueStore.shared

        // Initialize floating window controller
        floatingWindowController = FloatingWindowController(queueStore: queueStore)

        // Initialize menu bar controller
        menuBarController = MenuBarController(
            queueStore: queueStore,
            floatingWindowController: floatingWindowController!
        )

        // Register global hotkey (⌃+⌥+D)
        registerGlobalHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Save queue before termination
        QueueStore.shared.save()

        // Remove hotkey monitor
        if let monitor = hotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func registerGlobalHotKey() {
        // ⌃+⌥+D (Control + Option + D)
        let modifierFlags: NSEvent.ModifierFlags = [.control, .option]

        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifierFlags,
               event.charactersIgnoringModifiers?.lowercased() == "d" {
                self?.toggleFloatingWindow()
            }
        }

        // Also monitor local events for when app is focused
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifierFlags,
               event.charactersIgnoringModifiers?.lowercased() == "d" {
                self?.toggleFloatingWindow()
                return nil
            }
            return event
        }
    }

    private func toggleFloatingWindow() {
        floatingWindowController?.toggle()
    }
}
