import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    @Published var isMusicEnabled = true
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "Pulse", withExtension: "mp3") else {
            print("Could not find Pulse.mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Бесконечное повторение
            audioPlayer?.volume = 0.5
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func playMusic() {
        guard isMusicEnabled else { return }
        audioPlayer?.play()
    }
    
    func stopMusic() {
        audioPlayer?.stop()
    }
    
    func toggleMusic() {
        isMusicEnabled.toggle()
        if isMusicEnabled {
            playMusic()
        } else {
            stopMusic()
        }
    }
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
}
