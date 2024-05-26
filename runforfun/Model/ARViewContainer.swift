//
//  ARViewContainer.swift
//  arunforfun
//
//  Created by Rio Ikhsan on 21/05/24.
//

import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var planeDetected: Bool
    @Binding var showStartButton: Bool
    @Binding var showStopwatch: Bool
    @Binding var gameSessionActive: Bool
    @ObservedObject var stopwatchManager: StopwatchManager
    var onFinish: () -> Void
    var onLose: () -> Void
    var playSound: () -> Void
    @Binding var arView: ARView? // To pass ARView back to ContentView
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        self.arView = arView // Pass the ARView instance back
        
        // Add ARCoachingOverlayView for plane detection
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        arView.session.delegate = context.coordinator
        
        // Configure AR session for horizontal plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        
        // Add tap gesture recognizer for object placement
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, playSound: playSound)
    }
    
    // Coordinator: Handles AR session events and interactions
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var startPointPlaced = false
        var startPosition: SIMD3<Float>?
        var finishPosition: SIMD3<Float>?
        var obstacleEntity1: ModelEntity?
        var obstacleEntity2: ModelEntity?
        var obstacleAnchor1: AnchorEntity?
        var obstacleAnchor2: AnchorEntity?
        var obstacleTimer1: Timer?
        var obstacleTimer2: Timer?
        var playSound: () -> Void
        
        init(_ parent: ARViewContainer, playSound: @escaping () -> Void) {
            self.parent = parent
            self.playSound = playSound
        }
        
        // AR session callback when anchors are added
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if anchor is ARPlaneAnchor {
                    DispatchQueue.main.async {
                        self.parent.planeDetected = true
                        print("Plane detected")
                    }
                }
            }
        }
        
        // Handle tap gestures to place objects
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            
            let tapLocation = recognizer.location(in: arView)
            let results = arView.raycast(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal)
            
            if let firstResult = results.first {
                let position = simd_make_float3(firstResult.worldTransform.columns.3)
                
                if !startPointPlaced {
                    // Place the start point using StartPoint.rcproject
                    placeEntity(named: "StartPoint", at: position, in: arView)
                    startPosition = position
                    startPointPlaced = true
                    print("Start Point Placed using StartPoint.rcproject")
                    playSound()
                    
                    // Calculate finish position with the specified offset
                    let finishPosition = position + SIMD3<Float>(-0.3, 1.3, -6)
                    placeModel(named: "FinishFlag", at: finishPosition, in: arView)
                    self.finishPosition = finishPosition
                    print("Finish Point Placed using FinishFlag.usdz at \(finishPosition)")
                    playSound()
                    
                    // Place intermediate circles along the path using ArrowTrack.rcproject
                    let numberOfIntermediateCircles = 3
                    for i in 1..<numberOfIntermediateCircles {
                        let fraction = Float(i) / Float(numberOfIntermediateCircles)
                        let intermediatePosition = position + fraction * SIMD3<Float>(0, 0, -6)
                        placeEntity(named: "ArrowTrack", at: intermediatePosition, in: arView)
                        print("Intermediate Point \(i) Placed using ArrowTrack.rcproject")
                        playSound()
                    }
                    
                    // Place the first obstacle in the path
                    let obstaclePosition1 = position + SIMD3<Float>(0, 0, -2)
                    placeAndAnimateObstacle1(at: obstaclePosition1, in: arView)
                    print("Obstacle 1 Placed and Animated")
                    playSound()
                    
                    // Place the second obstacle in the path
                    let obstaclePosition2 = obstaclePosition1 + SIMD3<Float>(0, 0, -2)
                    placeAndAnimateObstacle2(at: obstaclePosition2, in: arView)
                    print("Obstacle 2 Placed and Animated")
                    playSound()
                    
                    // Show the start button and stopwatch after all objects are placed
                    DispatchQueue.main.async {
                        self.parent.showStartButton = true
                        self.parent.showStopwatch = true
                        print("Start button and stopwatch shown")
                    }
                    
                    // Start a timer for the lose condition (e.g., 60 seconds)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        if self.parent.gameSessionActive && !self.parent.stopwatchManager.isStopped {
                            self.parent.stopwatchManager.stop()
                            self.parent.onLose()
                            print("Game session lose condition triggered")
                        }
                    }
                }
            }
        }
        
        // Place an entity from an .rcproject file at the specified position
        private func placeEntity(named name: String, at position: SIMD3<Float>, in arView: ARView) {
            guard let entity = try? Entity.load(named: name) else {
                print("Failed to load entity: \(name)")
                return
            }
            let anchorEntity = AnchorEntity(world: position)
            anchorEntity.addChild(entity)
            arView.scene.addAnchor(anchorEntity)
        }
        
        // Place a model from a .usdz file at the specified position
        private func placeModel(named name: String, at position: SIMD3<Float>, in arView: ARView) {
            guard let modelEntity = try? Entity.loadModel(named: name) else {
                print("Failed to load model: \(name)")
                return
            }
            let anchorEntity = AnchorEntity(world: position)
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
        }
        
        // Place and animate the first obstacle at the specified position
        private func placeAndAnimateObstacle1(at position: SIMD3<Float>, in arView: ARView) {
            let anchorEntity = AnchorEntity(world: position)
            let cube = MeshResource.generateBox(size: [0.7, 1.6, 0.7])  // Adjusted size of the cube
            let material = SimpleMaterial(color: .black, isMetallic: true)  // Adjusted color and material
            let modelEntity = ModelEntity(mesh: cube, materials: [material])
            
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            obstacleEntity1 = modelEntity
            obstacleAnchor1 = anchorEntity
            
            startObstacleAnimation1()
        }
        
        // Start the animation for the first obstacle
        private func startObstacleAnimation1() {
            guard let obstacleEntity = obstacleEntity1 else { return }
            
            var direction: Float = 1.0
            let moveDistance: Float = 1.0
            let duration: TimeInterval = 1.0
            
            obstacleTimer1 = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
                let currentPosition = obstacleEntity.position
                let newPosition = SIMD3<Float>(direction * moveDistance, currentPosition.y, currentPosition.z)
                obstacleEntity.move(to: Transform(translation: newPosition), relativeTo: obstacleEntity.parent, duration: duration)
                
                direction *= -1.0
                print("Obstacle 1 animated to new position: \(newPosition)")
            }
        }
        
        // Place and animate the second obstacle at the specified position
        private func placeAndAnimateObstacle2(at position: SIMD3<Float>, in arView: ARView) {
            let anchorEntity = AnchorEntity(world: position)
            let cube = MeshResource.generateBox(size: [0.7, 1.6, 0.7])  // Adjusted size of the cube
            let material = SimpleMaterial(color: .black, isMetallic: true)  // Adjusted color and material
            let modelEntity = ModelEntity(mesh: cube, materials: [material])
            
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            obstacleEntity2 = modelEntity
            obstacleAnchor2 = anchorEntity
            
            startObstacleAnimation2()
        }
        
        // Start the animation for the second obstacle
        private func startObstacleAnimation2() {
            guard let obstacleEntity = obstacleEntity2 else { return }
            
            var direction: Float = 1.0
            let moveDistance: Float = 1.0
            let duration: TimeInterval = 0.5 // Faster animation
            
            obstacleTimer2 = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
                let currentPosition = obstacleEntity.position
                let newPosition = SIMD3<Float>(direction * moveDistance, currentPosition.y, currentPosition.z)
                obstacleEntity.move(to: Transform(translation: newPosition), relativeTo: obstacleEntity.parent, duration: duration)
                
                direction *= -1.0
                print("Obstacle 2 animated to new position: \(newPosition)")
            }
        }
        
        // Stop all obstacle animations
        func stopObstacleAnimations() {
            obstacleTimer1?.invalidate()
            obstacleTimer1 = nil
            obstacleTimer2?.invalidate()
            obstacleTimer2 = nil
            print("Obstacle animations stopped")
        }
        
        // AR session callback for frame updates
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let finishPosition = finishPosition, let obstacleAnchor1 = obstacleAnchor1, let obstacleAnchor2 = obstacleAnchor2, let cameraTransform = session.currentFrame?.camera.transform else { return }
            let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
            
            let distanceToFinish = simd_distance(cameraPosition, finishPosition)
            let distanceToObstacle1 = simd_distance(cameraPosition, obstacleAnchor1.transform.translation)
            let distanceToObstacle2 = simd_distance(cameraPosition, obstacleAnchor2.transform.translation)
            
            // Check if the player has reached the finish point
            if distanceToFinish < 0.5 { // threshold to detect arrival
                DispatchQueue.main.async {
                    self.stopObstacleAnimations()
                    self.parent.stopwatchManager.stop()
                    print("Arrived at Finish Point")
                    self.parent.onFinish()
                }
            }
            
            // Check if the player has collided with any obstacle
            if self.parent.gameSessionActive && (distanceToObstacle1 < 0.01 || distanceToObstacle2 < 0.01) { // threshold to detect collision
                DispatchQueue.main.async {
                    self.stopObstacleAnimations()
                    self.parent.stopwatchManager.stop()
                    print("Collided with Obstacle")
                    self.parent.onLose()
                }
            }
        }
    }
}
