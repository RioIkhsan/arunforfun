//
//  RunViewModel.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import Foundation
import Combine

/// Manages the state and logic for the run
class RunViewModel: ObservableObject {
    @Published var planeDetected = false
    @Published var showStartButton = false
    @Published var showFinishPopup = false
    @Published var showLosePopup = false
    @Published var stopwatchManager = StopwatchManager()
    
    /// Starts the run
    func startRun() {
        stopwatchManager.start()
        showStartButton = false
    }
    
    /// Resets the run
    func resetRun() {
        stopwatchManager.reset()
        showFinishPopup = false
        showLosePopup = false
        showStartButton = true
        planeDetected = false
    }
    
    /// Finishes the run
    func finishRun() {
        stopwatchManager.stop()
        showFinishPopup = true
    }
    
    /// Ends the run with a loss
    func loseRun() {
        stopwatchManager.stop()
        showLosePopup = true
    }
}
