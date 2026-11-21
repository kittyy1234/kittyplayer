import Foundation
import AppKit

final class AppleMusic {
    func control(_ action: String) {
        let cmd: String
        switch action {
        case "playpause":
            cmd = "tell application \"Music\" to playpause"
        case "next":
            cmd = "tell application \"Music\" to next track"
        case "prev":
            cmd = "tell application \"Music\" to previous track"
        default:
            return
        }
        run(cmd)
    }

    func scrub(_ seconds: Double) {
        run("tell application \"Music\" to set player position to \(Int(seconds))")
    }

    func setVolume(_ v: Double) {
        let vol = max(0, min(100, Int((v * 100).rounded())))
        run("tell application \"Music\" to set sound volume to \(vol)")
    }

    func pollState(completion: @escaping ([String: Any]) -> Void) {
        let script = """
        if application "Music" is running then
          tell application "Music"
            try
              set cTrack to current track
              set trackName to name of cTrack
              set artistName to artist of cTrack
              set totalDur to duration of cTrack
              set playerPos to player position
              set pState to player state as string
              set curVol to sound volume
              set albumName to album of cTrack
              return trackName & "||" & artistName & "||" & totalDur & "||" & playerPos & "||" & pState & "||" & albumName & "||" & curVol
            on error
              return "No Track"
            end try
          end tell
        end if
        return "No Track"
        """
        DispatchQueue.global(qos: .utility).async {
            var error: NSDictionary?
            let result = NSAppleScript(source: script)?.executeAndReturnError(&error)
            let stdout = result?.stringValue ?? "No Track"
            if stdout == "No Track" {
                DispatchQueue.main.async {
                    completion([
                        "track": "KittyPlayer",
                        "artist": "No track playing",
                        "position": 0,
                        "duration": 1,
                        "status": "paused",
                        "image": "",
                        "id": "",
                        "source": "appleMusic"
                    ])
                }
                return
            }
            let parts = stdout.components(separatedBy: "||")
            guard parts.count >= 5 else { return }
            let duration = Double(parts[2]) ?? 1
            let position = Double(parts[3]) ?? 0
            let volume = parts.count > 6 ? max(0, min(1, (Double(parts[6]) ?? 70) / 100)) : 0.7
            DispatchQueue.main.async {
                completion([
                    "track": parts[0],
                    "artist": parts[1],
                    "duration": duration,
                    "position": position,
                    "status": parts[4].lowercased(),
                    "image": "",
                    "id": "",
                    "volume": volume,
                    "source": "appleMusic"
                ])
            }
        }
    }

    private func run(_ source: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
        }
    }
}
