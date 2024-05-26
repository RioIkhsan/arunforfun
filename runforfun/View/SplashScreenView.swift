//
//  SplashScreenView.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI

/// A splash screen view that appears when the app is opened
struct SplashScreenView: View {
    @State private var isActive = false
    let transitionDuration: Double = 3.0 // Duration to show the splash screen
    
    var body: some View {
        if isActive {
            StartingRunView()
        } else {
            VStack {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.greenPrimary)
                    Text("WARNING")
                        .font(Font.custom("FugazOne-Regular", size: 48))
                        .foregroundColor(.greenPrimary)
                } .padding()
                
                Text("This is an augmented reality apps. Please be aware of your surroundings to avoid any accidents. Stay safe and have fun!")
                    .font(Font.custom("HelveticaNeue-Regular", size: 32))
                    .foregroundColor(.greenPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: 630, alignment: .top)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blackBg)
            .onAppear {
                // Transition to the next view after the specified duration
                DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
