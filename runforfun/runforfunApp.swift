//
//  arunforfunApp.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI

@main
struct arunforfunApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .supportedOrientations(.landscape)
        }
    }
}

extension View {
    func supportedOrientations(_ orientation: UIInterfaceOrientationMask) -> some View {
        self.onAppear {
            AppDelegate.orientationLock = orientation
            UIDevice.current.setValue(orientation == .landscape ? UIInterfaceOrientation.landscapeRight.rawValue : UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        .onDisappear {
            AppDelegate.orientationLock = .all
        }
    }
}
