import Foundation

enum MediaSource {
    case spotify
    case appleMusic
}

final class Media {
    let spotify = Connector()
    let appleMusic = AppleMusic()
    var activeSource: MediaSource = .spotify

    func poll(completion: @escaping ([String: Any]) -> Void) {
        switch activeSource {
        case .spotify:
            spotify.pollState(completion: completion)
        case .appleMusic:
            appleMusic.pollState(completion: completion)
        }
    }

    func control(_ action: String) {
        switch activeSource {
        case .spotify:
            spotify.control(action)
        case .appleMusic:
            appleMusic.control(action)
        }
    }

    func scrub(_ seconds: Double) {
        switch activeSource {
        case .spotify:
            spotify.scrub(seconds)
        case .appleMusic:
            appleMusic.scrub(seconds)
        }
    }

    func setVolume(_ v: Double) {
        switch activeSource {
        case .spotify:
            spotify.setVolume(v)
        case .appleMusic:
            appleMusic.setVolume(v)
        }
    }

    func play(uri: String) {
        if activeSource == .spotify {
            spotify.play(uri: uri)
        }
    }
}
