import AppKit
import BetterWarpCore
import Foundation
import ServiceManagement

private let officialLoginLauncher = "com.cloudflare.1dot1dot1dot1.macos.loginlauncherapp"
private let officialBundleID = "com.cloudflare.1dot1dot1dot1.macos"
private let officialGuiProcessPath = "/Applications/Cloudflare WARP.app/Contents/MacOS/Cloudflare WARP"

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let warp = WarpCLI()
    private let replacement = OfficialUIReplacement()
    private let loginItem = LoginItemManager()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var status = WarpStatus.unknown("Starting")
    private var statusTimer: Timer?
    private var replacementTimer: Timer?
    private var actionInFlight = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLog.write("Application launched")
        NSApp.setActivationPolicy(.accessory)
        UserDefaults.standard.register(defaults: [
            "replaceOfficialUI": false,
            "startAtLogin": true
        ])

        configureStatusButton()
        syncLoginItem()
        refreshStatus()

        if replaceOfficialUI {
            Task.detached { [replacement] in
                replacement.disableAndQuitOfficialUI()
            }
        }

        statusTimer = Timer.scheduledTimer(
            timeInterval: 8,
            target: self,
            selector: #selector(statusTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )

        replacementTimer = Timer.scheduledTimer(
            timeInterval: 45,
            target: self,
            selector: #selector(replacementTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusTimer?.invalidate()
        replacementTimer?.invalidate()
    }

    private var replaceOfficialUI: Bool {
        get { UserDefaults.standard.bool(forKey: "replaceOfficialUI") }
        set { UserDefaults.standard.set(newValue, forKey: "replaceOfficialUI") }
    }

    private var shouldStartAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "startAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "startAtLogin") }
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusButtonPressed(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        render()
    }

    @objc private func statusButtonPressed(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            status.canToggle ? toggleConnection() : openMenu()
            return
        }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            openMenu()
        } else if status.canToggle {
            toggleConnection()
        } else {
            openMenu()
        }
    }

    private func openMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let statusLine = NSMenuItem(title: status.menuTitle, action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)

        if let detail = status.detail, !detail.isEmpty {
            let detailLine = NSMenuItem(title: detail, action: nil, keyEquivalent: "")
            detailLine.isEnabled = false
            menu.addItem(detailLine)
        }

        menu.addItem(.separator())

        let toggleTitle = status.canToggle ? (status.prefersDisconnect ? "Disconnect WARP" : "Connect WARP") : "WARP Status Unavailable"
        let toggle = NSMenuItem(title: actionInFlight ? "Working..." : toggleTitle, action: #selector(toggleMenuItemPressed(_:)), keyEquivalent: "")
        toggle.target = self
        toggle.isEnabled = !actionInFlight && status.canToggle
        menu.addItem(toggle)

        if !status.canToggle {
            let openOfficial = NSMenuItem(title: "Open Cloudflare WARP", action: #selector(openOfficialPressed(_:)), keyEquivalent: "")
            openOfficial.target = self
            menu.addItem(openOfficial)
        }

        let refresh = NSMenuItem(title: "Refresh Status", action: #selector(refreshMenuItemPressed(_:)), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)

        let startAtLogin = NSMenuItem(title: "Start Better WARP at Login", action: #selector(startAtLoginPressed(_:)), keyEquivalent: "")
        startAtLogin.target = self
        startAtLogin.state = shouldStartAtLogin ? .on : .off
        menu.addItem(startAtLogin)

        let replace = NSMenuItem(title: "Replace Cloudflare Menu-Bar UI", action: #selector(replaceOfficialUIPressed(_:)), keyEquivalent: "")
        replace.target = self
        replace.state = replaceOfficialUI ? .on : .off
        menu.addItem(replace)

        menu.addItem(.separator())

        let advanced = NSMenuItem(title: "Advanced", action: nil, keyEquivalent: "")
        let advancedMenu = NSMenu()

        let disableOfficial = NSMenuItem(title: "Disable Official Flutter UI Now", action: #selector(disableOfficialUIPressed(_:)), keyEquivalent: "")
        disableOfficial.target = self
        advancedMenu.addItem(disableOfficial)

        let restoreOfficial = NSMenuItem(title: "Restore Official UI", action: #selector(restoreOfficialUIPressed(_:)), keyEquivalent: "")
        restoreOfficial.target = self
        advancedMenu.addItem(restoreOfficial)

        let openOfficial = NSMenuItem(title: "Open Cloudflare WARP", action: #selector(openOfficialPressed(_:)), keyEquivalent: "")
        openOfficial.target = self
        advancedMenu.addItem(openOfficial)

        advanced.submenu = advancedMenu
        menu.addItem(advanced)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Better WARP", action: #selector(quitPressed(_:)), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleMenuItemPressed(_ sender: NSMenuItem) {
        toggleConnection()
    }

    @objc private func refreshMenuItemPressed(_ sender: NSMenuItem) {
        refreshStatus()
    }

    @objc private func statusTimerFired(_ timer: Timer) {
        refreshStatus()
    }

    @objc private func replacementTimerFired(_ timer: Timer) {
        guard replaceOfficialUI else { return }
        Task.detached { [replacement] in
            replacement.disableAndQuitOfficialUI()
        }
    }

    @objc private func replaceOfficialUIPressed(_ sender: NSMenuItem) {
        replaceOfficialUI.toggle()
        if replaceOfficialUI {
            Task.detached { [replacement] in
                replacement.disableAndQuitOfficialUI()
            }
        }
        render()
    }

    @objc private func startAtLoginPressed(_ sender: NSMenuItem) {
        shouldStartAtLogin.toggle()
        syncLoginItem()
    }

    @objc private func disableOfficialUIPressed(_ sender: NSMenuItem) {
        Task.detached { [replacement] in
            replacement.disableAndQuitOfficialUI()
        }
    }

    @objc private func restoreOfficialUIPressed(_ sender: NSMenuItem) {
        replaceOfficialUI = false
        Task.detached { [replacement] in
            replacement.restoreOfficialUI()
        }
        render()
    }

    @objc private func openOfficialPressed(_ sender: NSMenuItem) {
        Task.detached { [replacement] in
            replacement.openOfficialUI()
        }
    }

    @objc private func quitPressed(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }

    private func toggleConnection() {
        guard !actionInFlight, status.canToggle else { return }
        actionInFlight = true

        let shouldDisconnect = status.prefersDisconnect
        AppLog.write(shouldDisconnect ? "Disconnect requested" : "Connect requested")
        status = shouldDisconnect ? .disconnecting : .connecting
        render()

        Task.detached { [warp] in
            let result = shouldDisconnect ? warp.disconnect() : warp.connect()
            let next = warp.status(fallbackError: result.errorText)
            await MainActor.run {
                if result.exitCode != 0 {
                    AppLog.write("Toggle command failed: \(result.errorText ?? "unknown error")")
                }
                self.actionInFlight = false
                self.status = next
                self.render()
            }
        }
    }

    private func refreshStatus() {
        Task.detached { [warp] in
            let next = warp.status()
            await MainActor.run {
                AppLog.write("Status refreshed: \(next.menuTitle)")
                self.status = next
                self.render()
            }
        }
    }

    private func syncLoginItem() {
        do {
            try loginItem.setEnabled(shouldStartAtLogin)
        } catch {
            AppLog.write("Login item update failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func render() {
        guard let button = statusItem.button else { return }
        button.image = MenuBarIcon.image(for: status)
        button.imagePosition = .imageLeft
        button.title = ""
        button.toolTip = status.toolTip
        button.contentTintColor = status.usesBundledIcon ? nil : status.tintColor
    }
}

private extension WarpStatus {
    var shortTitle: String {
        switch self {
        case .connected:
            return " WARP On"
        case .disconnected:
            return " WARP Off"
        case .connecting:
            return " Connecting"
        case .disconnecting:
            return " Disconnecting"
        case .unavailable:
            return " WARP Error"
        case .unknown:
            return " WARP"
        }
    }

    var menuTitle: String {
        switch self {
        case .connected:
            return "WARP is connected"
        case .disconnected:
            return "WARP is disconnected"
        case .connecting:
            return "WARP is connecting"
        case .disconnecting:
            return "WARP is disconnecting"
        case .unavailable:
            return "WARP is unavailable"
        case .unknown(let text):
            return "WARP status: \(text)"
        }
    }

    var detail: String? {
        switch self {
        case .connected(let reason, let mode), .disconnected(let reason, let mode):
            return [mode.map { "Mode: \($0)" }, reason].compactMap { $0 }.joined(separator: " - ")
        case .unavailable(let text), .unknown(let text):
            return text
        case .connecting, .disconnecting:
            return nil
        }
    }

    var toolTip: String {
        switch self {
        case .connected:
            return "Click to disconnect WARP. Right-click for options."
        case .disconnected:
            return "Click to connect WARP. Right-click for options."
        case .unknown, .unavailable:
            return "Right-click for WARP status options."
        case .connecting, .disconnecting:
            return "WARP is changing state."
        }
    }

    var tintColor: NSColor {
        switch self {
        case .connected:
            return .systemGreen
        case .disconnected:
            return .secondaryLabelColor
        case .connecting, .disconnecting:
            return .systemBlue
        case .unavailable:
            return .systemRed
        case .unknown:
            return .systemYellow
        }
    }

    var usesBundledIcon: Bool {
        switch self {
        case .connected, .disconnected:
            return true
        case .connecting, .disconnecting, .unavailable, .unknown:
            return false
        }
    }

    var symbol: NSImage? {
        let name: String
        switch self {
        case .connected:
            name = "shield.lefthalf.filled"
        case .disconnected:
            name = "shield.slash"
        case .connecting, .disconnecting:
            name = "arrow.triangle.2.circlepath"
        case .unavailable:
            name = "exclamationmark.shield"
        case .unknown:
            name = "shield"
        }

        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }
}

private enum MenuBarIcon {
    @MainActor
    static func image(for status: WarpStatus) -> NSImage? {
        switch status {
        case .connected:
            return bundledImage(named: "WarpOn")
        case .disconnected:
            return bundledImage(named: "WarpOff")
        case .connecting, .disconnecting, .unavailable, .unknown:
            return status.symbol
        }
    }

    @MainActor
    private static func bundledImage(named name: String) -> NSImage? {
        guard let image = NSImage(named: name) else {
            AppLog.write("Bundled menu-bar icon missing: \(name)")
            return nil
        }

        image.size = NSSize(width: 20, height: 20)
        image.isTemplate = true
        return image
    }
}

private struct OfficialUIReplacement: Sendable {
    private let runner = ProcessRunner()

    func disableAndQuitOfficialUI() {
        let disable = runner.run("/bin/launchctl", arguments: ["disable", "gui/\(getuid())/\(officialLoginLauncher)"])
        if disable.exitCode != 0 {
            AppLog.write("launchctl disable failed: \(disable.errorText ?? "unknown error")")
        }

        let quit = runner.run("/usr/bin/osascript", arguments: ["-e", "tell application id \"\(officialBundleID)\" to quit"])
        if quit.exitCode != 0 {
            AppLog.write("Official UI quit failed: \(quit.errorText ?? "unknown error")")
            let kill = runner.run("/usr/bin/pkill", arguments: ["-f", officialGuiProcessPath])
            if kill.exitCode == 0 {
                AppLog.write("Official UI process stopped with pkill fallback")
            } else {
                AppLog.write("Official UI pkill fallback failed: \(kill.errorText ?? "process not found")")
            }
        }
    }

    func restoreOfficialUI() {
        let enable = runner.run("/bin/launchctl", arguments: ["enable", "gui/\(getuid())/\(officialLoginLauncher)"])
        if enable.exitCode != 0 {
            AppLog.write("launchctl enable failed: \(enable.errorText ?? "unknown error")")
        }

        let open = runner.run("/usr/bin/open", arguments: ["-b", officialBundleID])
        if open.exitCode != 0 {
            AppLog.write("Official UI open failed: \(open.errorText ?? "unknown error")")
        }
    }

    func openOfficialUI() {
        let open = runner.run("/usr/bin/open", arguments: ["-b", officialBundleID])
        if open.exitCode != 0 {
            AppLog.write("Official UI open failed: \(open.errorText ?? "unknown error")")
        }
    }
}

private struct LoginItemManager: Sendable {
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}

private enum AppLog {
    static func write(_ message: String) {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Better WARP", isDirectory: true)
        let file = directory.appendingPathComponent("BetterWarp.log")

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
            let data = Data(line.utf8)

            if FileManager.default.fileExists(atPath: file.path) {
                let handle = try FileHandle(forWritingTo: file)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: file)
            }
        } catch {
            NSLog("Better WARP log failed: \(error.localizedDescription)")
        }
    }
}

@MainActor
private func runApplication() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

private func runMaintenanceCommandIfNeeded() -> Bool {
    let arguments = Set(CommandLine.arguments.dropFirst())
    guard !arguments.isEmpty else { return false }

    if arguments.contains("--unregister-login-item") {
        do {
            try LoginItemManager().setEnabled(false)
        } catch {
            AppLog.write("Login item unregister failed: \(error.localizedDescription)")
        }
    }

    if arguments.contains("--restore-official-ui") {
        OfficialUIReplacement().restoreOfficialUI()
    }

    return arguments.contains("--unregister-login-item") || arguments.contains("--restore-official-ui")
}

if !runMaintenanceCommandIfNeeded() {
    runApplication()
}
