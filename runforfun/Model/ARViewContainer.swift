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
        var obstacleEntity: ModelEntity?
        var obstacleAnchor: AnchorEntity?
        var obstacleTimer: Timer?
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
                    // Place the start point using StartPoint.reality
                    placeEntity(named: "StartPoint", at: position, in: arView)
                    startPosition = position
                    startPointPlaced = true
                    print("Start Point Placed using StartPoint.reality")
                    playSound()
                    
                    // Calculate finish position 2 meters away from start position
                    let finishPosition = position + SIMD3<Float>(0, 0, -2)
                    placeEntity(named: "FinishPoint", at: finishPosition, in: arView)
                    self.finishPosition = finishPosition
                    print("Finish Point Placed using FinishPoint.reality")
                    playSound()
                    
                    // Place intermediate circles along the path using ArrowTrack.rcproject
                    let numberOfIntermediateCircles = 3
                    for i in 1..<numberOfIntermediateCircles {
                        let fraction = Float(i) / Float(numberOfIntermediateCircles)
                        let intermediatePosition = position + fraction * SIMD3<Float>(0, 0, -2)
                        placeEntity(named: "ArrowTrack", at: intermediatePosition, in: arView)
                        print("Intermediate Point \(i) Placed using ArrowTrack.rcproject")
                        playSound()
                    }
                    
                    // Place an obstacle in the path
                    let obstaclePosition = position + SIMD3<Float>(0, 0, -1)
                    placeAndAnimateObstacle(at: obstaclePosition, in: arView)
                    print("Obstacle Placed and Animated")
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
        
        // Place an entity from a .reality or .rcproject file at the specified position
        private func placeEntity(named name: String, at position: SIMD3<Float>, in arView: ARView) {
            guard let entity = try? Entity.load(named: name) else {
                print("Failed to load entity: \(name)")
                return
            }
            let anchorEntity = AnchorEntity(world: position)
            anchorEntity.addChild(entity)
            arView.scene.addAnchor(anchorEntity)
        }
        
        // Place and animate an obstacle at the specified position
        private func placeAndAnimateObstacle(at position: SIMD3<Float>, in arView: ARView) {
            let anchorEntity = AnchorEntity(world: position)
            let cube = MeshResource.generateBox(size: [0.2, 0.5, 0.2])  // Adjusted size to make the cube taller
            let material = SimpleMaterial(color: .gray, isMetallic: false)
            let modelEntity = ModelEntity(mesh: cube, materials: [material])
            
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            obstacleEntity = modelEntity
            obstacleAnchor = anchorEntity
            
            startObstacleAnimation()
        }
        
        // Start the obstacle animation
        private func startObstacleAnimation() {
            guard let obstacleEntity = obstacleEntity else { return }
            
            var direction: Float = 1.0
            let moveDistance: Float = 0.5
            let duration: TimeInterval = 1.0
            
            obstacleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) { _ in
                let currentPosition = obstacleEntity.position
                let newPosition = SIMD3<Float>(currentPosition.x + direction * moveDistance, currentPosition.y, currentPosition.z)
                obstacleEntity.move(to: Transform(translation: newPosition), relativeTo: obstacleEntity.parent, duration: duration)
                
                direction *= -1.0
                print("Obstacle animated to new position: \(newPosition)")
            }
        }
        
        // Stop the obstacle animation
        func stopObstacleAnimation() {
            obstacleTimer?.invalidate()
            obstacleTimer = nil
            print("Obstacle animation stopped")
        }
        
        // AR session callback for frame updates
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let finishPosition = finishPosition, let obstacleAnchor = obstacleAnchor, let cameraTransform = session.currentFrame?.camera.transform else { return }
            let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
            
            let distanceToFinish = simd_distance(cameraPosition, finishPosition)
            let distanceToObstacle = simd_distance(cameraPosition, obstacleAnchor.transform.translation)
            
            // Check if the player has reached the finish point
            if distanceToFinish < 0.5 { // threshold to detect arrival
                DispatchQueue.main.async {
                    self.stopObstacleAnimation()
                    self.parent.stopwatchManager.stop()
                    print("Arrived at Finish Point")
                    self.parent.onFinish()
                }
            }
            
            // Check if the player has collided with the obstacle
            if self.parent.gameSessionActive && distanceToObstacle < 0.01 { // threshold to detect collision
                DispatchQueue.main.async {
                    self.stopObstacleAnimation()
                    self.parent.stopwatchManager.stop()
                    print("Collided with Obstacle")
                    self.parent.onLose()
                }
            }
        }
    }
}
