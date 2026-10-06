import AppKit
import ServiceManagement

@MainActor
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let power = PowerAssertionManager()

    private var currentMode: AwakeMode = .off
    private var lastActiveMode: AwakeMode = .display
    private var currentTheme: IconTheme = .eye

    private enum DefaultsKey {
        static let currentMode = "Awake.currentMode"
        static let lastActiveMode = "Awake.lastActiveMode"
        static let iconTheme = "Awake.iconTheme"
    }

    // MARK: - Entry point

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // LSUIElement=true keeps us out of the Dock; accessory is a second net.
        app.setActivationPolicy(.accessory)
        app.run()
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        restorePreferences()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else {
            NSLog("Awake: could not create status item button")
            NSApp.terminate(nil)
            return
        }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        // Re-assert after sleep; the system drops assertions across sleep.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Restore saved mode (first launch defaults to off).
        setMode(currentMode, persistLastActive: false)
        if currentMode.isActive {
            lastActiveMode = currentMode
        }
        savePreferences()
    }

    func applicationWillTerminate(_ notification: Notification) {
        power.release()
    }

    // MARK: - Click handling

    @objc private func handleClick(_ sender: NSStatusItem) {
        guard let event = NSApp.currentEvent else {
            cycleMode()
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu(for: event)
        } else {
            cycleMode()
        }
    }

    private func cycleMode() {
        setMode(currentMode.next())
    }

    // MARK: - Mode

    private func setMode(_ mode: AwakeMode, persistLastActive: Bool = true) {
        if power.apply(mode) {
            currentMode = mode
            if mode.isActive, persistLastActive {
                lastActiveMode = mode
            }
        } else {
            // Assertion failed — fall back to off so the icon never lies.
            currentMode = .off
            NSLog("Awake: failed to take assertion, falling back to off")
        }
        refreshUI()
        savePreferences()
    }

    private func refreshUI() {
        guard let button = statusItem?.button else { return }
        button.image = currentTheme.image(for: currentMode)
        button.toolTip = currentMode.tooltip
        button.appearsDisabled = false
    }

    // MARK: - Menu (right-click)

    private func showMenu(for event: NSEvent) {
        let menu = NSMenu()

        for mode in AwakeMode.allCases {
            let item = NSMenuItem(
                title: mode.menuTitle,
                action: #selector(selectMode(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (mode == currentMode) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let themeHeader = NSMenuItem(title: "Icon Theme", action: nil, keyEquivalent: "")
        themeHeader.isEnabled = false
        menu.addItem(themeHeader)
        for theme in IconTheme.allCases {
            let item = NSMenuItem(
                title: theme.menuTitle,
                action: #selector(selectTheme(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = theme.rawValue
            item.state = (theme == currentTheme) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: "Quit Awake",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Pop up at the status button for the right-click event.
        if let button = statusItem?.button {
            NSMenu.popUpContextMenu(menu, with: event, for: button)
        }
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let mode = AwakeMode(rawValue: raw)
        else { return }
        setMode(mode)
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard
            let raw = sender.representedObject as? String,
            let theme = IconTheme(rawValue: raw)
        else { return }
        currentTheme = theme
        refreshUI()
        savePreferences()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Awake: Launch-at-Login toggle failed: \(error)")
        }
    }

    @objc private func quit(_ sender: Any?) {
        power.release()
        NSApp.terminate(nil)
    }

    // MARK: - Sleep / wake

    @objc private func systemDidWake(_ notification: Notification) {
        // Re-take the assertion; sleep clears it.
        if currentMode.isActive {
            setMode(currentMode, persistLastActive: false)
        }
    }

    // MARK: - Preferences

    private func restorePreferences() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: DefaultsKey.currentMode),
           let mode = AwakeMode(rawValue: raw)
        {
            currentMode = mode
        } else {
            currentMode = .off
        }
        if let raw = defaults.string(forKey: DefaultsKey.lastActiveMode),
           let mode = AwakeMode(rawValue: raw), mode.isActive
        {
            lastActiveMode = mode
        }
        if let raw = defaults.string(forKey: DefaultsKey.iconTheme),
           let theme = IconTheme(rawValue: raw)
        {
            currentTheme = theme
        }
    }

    private func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(currentMode.rawValue, forKey: DefaultsKey.currentMode)
        defaults.set(lastActiveMode.rawValue, forKey: DefaultsKey.lastActiveMode)
        defaults.set(currentTheme.rawValue, forKey: DefaultsKey.iconTheme)
    }
}
