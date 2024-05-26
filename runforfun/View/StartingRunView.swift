//
//  StartingRunView.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI
import AVFoundation

/// The initial view for starting the run
struct StartingRunView: View {
    @State private var showTextAR = false
    @State private var showTextUNFORFUN = false
    @State private var showPlayButton = false
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("AR")
                        .font(Font.custom("FugazOne-Regular", size: 96))
                        .fontWeight(.bold)
                        .foregroundColor(.greenSecondary)
                        .offset(x: showTextAR ? 0 : -UIScreen.main.bounds.width)
                        .animation(Animation.easeOut(duration: 1).delay(0.5), value: showTextAR)
                    Text("UN FOR FUN")
                        .font(Font.custom("FugazOne-Regular", size: 96))
                        .fontWeight(.bold)
                        .foregroundColor(.greenPrimary)
                        .offset(x: showTextUNFORFUN ? 0 : UIScreen.main.bounds.width)
                        .animation(Animation.easeOut(duration: 1).delay(0.7), value: showTextUNFORFUN)
                }
                .padding()

                NavigationLink(destination: ContentView(playSound: playSound).navigationBarBackButtonHidden(true)) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 128))
                        .foregroundColor(.greenPrimary)
                        .padding()
                        .opacity(showPlayButton ? 1 : 0) // Initial opacity is 0 (hidden)
                        .animation(Animation.easeIn(duration: 1).delay(1.5), value: showPlayButton) // Fade-in animation
                }
                .simultaneousGesture(TapGesture().onEnded {
                    playSound()
                })
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blackBg)
            .onAppear {
                // Trigger the animations when the view appears
                self.showTextAR = true
                self.showTextUNFORFUN = true
                self.showPlayButton = true // Show the play button with fade-in animation
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Apply StackNavigationViewStyle to hide sidebar on iPad
    }
    
    private func playSound() {
        guard let url = Bundle.main.url(forResource: "tap-sound", withExtension: "mp3") else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}

struct StartingRunView_Previews: PreviewProvider {
    static var previews: some View {
        StartingRunView()
    }
}
