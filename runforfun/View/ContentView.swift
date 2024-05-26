//
//  ContentView.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI
import RealityKit // Import RealityKit for ARView
import ARKit // Import ARKit for ARWorldTrackingConfiguration
import AVFoundation // Import AVFoundation for audio playback

class StopwatchManager: ObservableObject {
    @Published var timeString = "00:00:00"
    @Published var isStopped = true
    private var timer: Timer?
    private var startTime: Date?
    
    func start() {
        startTime = Date()
        isStopped = false
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.updateTime()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isStopped = true
    }
    
    func reset() {
        stop()
        startTime = nil
        timeString = "00:00:00"
    }
    
    private func updateTime() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        let minutes = Int(elapsedTime / 60)
        let seconds = Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        let milliseconds = Int((elapsedTime * 100).truncatingRemainder(dividingBy: 100))
        
        DispatchQueue.main.async {
            self.timeString = String(format: "%02d:%02d:%02d", minutes, seconds, milliseconds)
        }
    }
}

class AudioManager {
    static let shared = AudioManager()
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    func playBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "apathy-bgm", withExtension: "mp3") else {
            print("Background music file not found")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.volume = 0.5 // Set volume to 50%
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.play()
            print("Background music started")
        } catch {
            print("Failed to initialize background music player: \(error.localizedDescription)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        print("Background music stopped")
    }
}

struct ContentView: View {
    let playSound: () -> Void
    
    @StateObject private var stopwatchManager = StopwatchManager()
    @State private var planeDetected = false
    @State private var showStartButton = false
    @State private var showStopwatch = false
    @State private var showFinishPopup = false
    @State private var showLosePopup = false
    @State private var gameSessionActive = false
    @State private var arView: ARView? // To access and reset ARView
    
    var body: some View {
        ZStack {
            ARViewContainer(
                planeDetected: $planeDetected,
                showStartButton: $showStartButton,
                showStopwatch: $showStopwatch,
                gameSessionActive: $gameSessionActive,
                stopwatchManager: stopwatchManager,
                onFinish: { self.showFinishPopup = true },
                onLose: { self.showLosePopup = true },
                playSound: playSound,
                arView: $arView // Pass the ARView binding
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Text(stopwatchManager.timeString)
                        .font(Font.custom("FugazOne-Regular", size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.greenPrimary)
                        .padding()
                        .background(Color.blackBg.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                }
                Spacer()
                
                if showStartButton {
                    Button(action: {
                        stopwatchManager.start()
                        showStartButton = false
                        gameSessionActive = true
                        print("Game session started")
                    }) {
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.greenPrimary)
                            .padding()
                    }
                    .padding(.bottom, 50)
                }
            }
            
            if showFinishPopup {
                FinishPopupView(finishTime: stopwatchManager.timeString) {
                    resetRun()
                }
            }
            
            if showLosePopup {
                LosePopupView {
                    resetRun()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AudioManager.shared.playBackgroundMusic()
            print("ContentView appeared")
        }
        .onDisappear {
            AudioManager.shared.stopBackgroundMusic()
            print("ContentView disappeared")
        }
    }
    
    private func resetRun() {
        // Reset the stopwatch
        stopwatchManager.reset()
        
        // Reset all game state variables
        showFinishPopup = false
        showLosePopup = false
        showStartButton = false
        planeDetected = false
        gameSessionActive = false
        print("Game session reset")
        
        // Restart AR session and animations
        arView?.session.pause()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showStartButton = true
            print("Start button shown")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(playSound: {})
    }
}
