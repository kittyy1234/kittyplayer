import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var overlay: Overlay?
    var statusItem: NSStatusItem?
    let media = Media()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem?.button {
            if let img = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "KittyPlayer") {
                img.isTemplate = true
                btn.image = img
            } else {
                btn.title = "ᗢ"
            }
            btn.toolTip = "KittyPlayer"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Player", action: #selector(showPlayer), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Hide Player", action: #selector(hidePlayer), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())

        let sourceMenu = NSMenu()
        let spotifyItem = NSMenuItem(title: "Spotify", action: #selector(setSourceSpotify), keyEquivalent: "")
        spotifyItem.state = media.activeSource == .spotify ? .on : .off
        sourceMenu.addItem(spotifyItem)
        let appleItem = NSMenuItem(title: "Apple Music", action: #selector(setSourceAppleMusic), keyEquivalent: "")
        appleItem.state = media.activeSource == .appleMusic ? .on : .off
        sourceMenu.addItem(appleItem)
        let sourceParent = NSMenuItem(title: "Source", action: nil, keyEquivalent: "")
        sourceParent.submenu = sourceMenu
        menu.addItem(sourceParent)

        menu.addItem(NSMenuItem(title: "Connect Spotify…", action: #selector(connectSpotify), keyEquivalent: "l"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KittyPlayer", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu

        overlay = Overlay(media: media)
        overlay?.show()

        media.spotify.ensureToken { [weak self] ok in
            DispatchQueue.main.async {
                self?.overlay?.sendAuthStatus(connected: ok)
                if ok {
                    self?.media.spotify.fetchPlaylists { list in
                        self?.overlay?.sendPlaylists(list)
                    }
                }
            }
        }

        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.media.poll { state in
                self?.overlay?.sendNowPlaying(state)
            }
        }
    }

    @objc func showPlayer() { overlay?.show() }
    @objc func hidePlayer() { overlay?.hide() }

    @objc func setSourceSpotify() {
        media.activeSource = .spotify
        refreshSourceMenu()
    }

    @objc func setSourceAppleMusic() {
        media.activeSource = .appleMusic
        refreshSourceMenu()
    }

    private func refreshSourceMenu() {
        guard let menu = statusItem?.menu,
              let sourceParent = menu.items.first(where: { $0.title == "Source" }),
              let sub = sourceParent.submenu else { return }
        for item in sub.items {
            if item.title == "Spotify" {
                item.state = media.activeSource == .spotify ? .on : .off
            } else if item.title == "Apple Music" {
                item.state = media.activeSource == .appleMusic ? .on : .off
            }
        }
    }

    @objc func connectSpotify() {
        media.spotify.login { [weak self] ok in
            DispatchQueue.main.async {
                self?.overlay?.sendAuthStatus(connected: ok)
                if ok {
                    self?.media.spotify.fetchPlaylists { list in
                        self?.overlay?.sendPlaylists(list)
                    }
                }
            }
        }
    }

    @objc func quit() {
        overlay?.close()
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
