import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow?
    var statusBarItem: NSStatusItem?
    var hasNotification = false

    func applicationDidFinishLaunching(_: Notification) {
        let contentView = ContentView(appDelegate: self)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window?.contentView = NSHostingView(rootView: contentView)
        window?.title = "TimeMeUp"
        window?.delegate = self

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let centerX = screenFrame.midX - 110
            let centerY = screenFrame.midY - 160
            window?.setFrame(NSRect(x: centerX, y: centerY, width: 220, height: 320), display: false, animate: false)
        }

        window?.setFrameAutosaveName("")

        window?.makeKeyAndOrderFront(nil)
    }

    @MainActor func removeStatusBarItem() {
        if let statusBarItem {
            NSStatusBar.system.removeStatusItem(statusBarItem)
            self.statusBarItem = nil
        }
    }

    @MainActor func updateStatusBarTimer(_ timeString: String) {
        let displayText = "⏱️ \(timeString)"
        statusBarItem?.button?.title = displayText
    }

    @MainActor func setNotificationState(_ hasNotification: Bool) {
        self.hasNotification = hasNotification
        if let statusBarItem, let currentTitle = statusBarItem.button?.title {
            let timeString = String(currentTitle.dropFirst(2))
            updateStatusBarTimer(timeString)
        }
    }

    @MainActor func clearNotification() {
        setNotificationState(false)
        clearDockBadge()
    }

    @MainActor func setDockNotification() {
        NSApp.dockTile.badgeLabel = "1"
        NSApp.dockTile.display()
    }

    @MainActor func clearDockBadge() {
        NSApp.dockTile.badgeLabel = nil
        NSApp.dockTile.display()
    }

    @MainActor func updateMenuPauseState(isPaused: Bool) {
        updateStatusBarMenu(isTimerActive: true, isPaused: isPaused)
    }

    @MainActor func setupStatusBarItem() {
        guard statusBarItem == nil else { return }

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem?.button {
            button.title = "⏱️ 00:00"
            button.action = #selector(statusBarItemClicked)
            button.target = self
        }

        updateStatusBarMenu(isTimerActive: true, isPaused: false)
    }

    @MainActor @objc func statusBarItemClicked() {
        showMainWindow()
        clearNotification()
    }

    @MainActor func updateStatusBarMenu(isTimerActive: Bool, isPaused: Bool = false) {
        guard let statusBarItem else { return }

        let menu = NSMenu()

        let showAppItem = NSMenuItem(title: "Show App", action: #selector(showMainWindow), keyEquivalent: "")
        showAppItem.target = self
        menu.addItem(showAppItem)

        if isTimerActive {
            menu.addItem(NSMenuItem.separator())

            let pauseResumeItem = NSMenuItem(
                title: isPaused ? "Resume" : "Pause",
                action: #selector(pauseResumeFromMenu),
                keyEquivalent: ""
            )
            pauseResumeItem.target = self
            menu.addItem(pauseResumeItem)

            let stopItem = NSMenuItem(title: "Stop Timer", action: #selector(stopFromMenu), keyEquivalent: "")
            stopItem.target = self
            menu.addItem(stopItem)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusBarItem.menu = menu
    }

    @MainActor @objc func showMainWindow() {
        clearNotification()
        clearDockBadge()

        if let window {
            window.level = .normal

            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let centerX = screenFrame.midX - 110
                let centerY = screenFrame.midY - 160
                window.setFrame(NSRect(x: centerX, y: centerY, width: 220, height: 320), display: true, animate: false)
            }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @MainActor func hideMainWindow() {
        window?.orderOut(nil)
    }

    @objc private func pauseResumeFromMenu() {
        NotificationCenter.default.post(name: NSNotification.Name("TogglePause"), object: nil)
    }

    @objc private func stopFromMenu() {
        NotificationCenter.default.post(name: NSNotification.Name("StopTimer"), object: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return statusBarItem == nil
    }

    func windowWillClose(_: Notification) {
        removeStatusBarItem()
    }
}
