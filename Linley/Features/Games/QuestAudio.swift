import SwiftUI
import AVFoundation

/// Bundled CC0 audio only. No downloads, microphone access or background audio mode.
@MainActor
final class QuestAudio: ObservableObject {
    static let resources = ["quest-music.m4a", "quest-step.wav", "quest-collect.wav", "quest-win.wav", "quest-star.wav"]
    @Published var musicEnabled: Bool { didSet {
        defaults.set(musicEnabled, forKey: "linley.quest.music")
        if musicEnabled { interrupted = false }
        updateMusic()
    } }
    @Published var effectsEnabled: Bool { didSet { defaults.set(effectsEnabled, forKey: "linley.quest.effects"); if !effectsEnabled { effect?.stop() } } }
    @Published private(set) var message: String?
    @Published private(set) var isPlaying = false
    private let defaults: UserDefaults
    private var music: AVAudioPlayer?
    private var effect: AVAudioPlayer?
    private var visible = false
    private var interrupted = false
    private var lastStep = Date.distantPast

    init(defaults: UserDefaults = .standard) {
        #if DEBUG
        self.defaults = ProcessInfo.processInfo.arguments.contains("--quest-ui-tests") ? UserDefaults(suiteName: "linley.quest.audio.ui-tests")! : defaults
        #else
        self.defaults = defaults
        #endif
        musicEnabled = self.defaults.object(forKey: "linley.quest.music") as? Bool ?? true
        effectsEnabled = self.defaults.object(forKey: "linley.quest.effects") as? Bool ?? true
    }

    static func resourceURL(_ name: String, bundle: Bundle = .main) -> URL? {
        let path = name as NSString
        return bundle.url(forResource: path.deletingPathExtension, withExtension: path.pathExtension, subdirectory: "QuestAudio")
    }

    func setVisible(_ value: Bool) {
        visible = value
        if !value { effect?.stop() }
        updateMusic()
    }

    func interrupt(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began {
            interrupted = true; effect?.stop(); updateMusic()
        } else {
            let options = (notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
            interrupted = !AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
            updateMusic()
        }
    }

    func routeChanged(_ notification: Notification) {
        guard let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
        // Unplugging headphones should not start music through the speakers.
        musicEnabled = false
        effect?.stop()
    }

    func play(_ name: String) {
        guard visible, !interrupted, effectsEnabled else { return }
        if name == "quest-step.wav" {
            guard Date().timeIntervalSince(lastStep) > 0.13, effect?.isPlaying != true else { return }
            lastStep = Date()
        }
        do {
            try configureSession()
            guard let url = Self.resourceURL(name) else { throw CocoaError(.fileNoSuchFile) }
            effect?.stop()
            effect = try AVAudioPlayer(contentsOf: url)
            effect?.volume = name == "quest-step.wav" ? 0.16 : 0.45
            if effect?.play() != true { throw CocoaError(.fileReadUnknown) }
            message = nil
        } catch { message = "Sound couldn't play. You can keep exploring." }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }

    private func updateMusic() {
        guard visible, !interrupted, musicEnabled else { music?.pause(); isPlaying = false; return }
        do {
            try configureSession()
            if music == nil {
                guard let url = Self.resourceURL("quest-music.m4a") else { throw CocoaError(.fileNoSuchFile) }
                music = try AVAudioPlayer(contentsOf: url)
                music?.numberOfLoops = -1
                music?.volume = 0.18
                music?.prepareToPlay()
            }
            isPlaying = music?.play() == true
            if !isPlaying { throw CocoaError(.fileReadUnknown) }
            message = nil
        } catch { isPlaying = false; message = "Music couldn't play. Your game is ready without it." }
    }
}

struct QuestAudioSettings: View {
    @ObservedObject var audio: QuestAudio
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Your sound") {
                    Toggle("Music", isOn: $audio.musicEnabled).accessibilityIdentifier("questMusicToggle")
                    Toggle("Sound effects", isOn: $audio.effectsEnabled).accessibilityIdentifier("questEffectsToggle")
                    Text("Low-volume game audio follows Silent Mode. Music pauses when you leave the game or put the app in the background.")
                    Button("Try a collection sound") { audio.play("quest-collect.wav") }.disabled(!audio.effectsEnabled)
                }
                Section("Music and sound credits") {
                    Text("Flowerbed Fields — Zane Little Music\nInterface Sounds — Kenney\nBoth released under CC0 1.0. Bundled for offline play.")
                }
                if let message = audio.message { Text(message) }
            }.navigationTitle("Game Sound")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
