import Foundation
import ARKit
import RealityKit
import Combine

enum MeasurementType {
    case chairHeight
    case tableHeight
}

class ARMeasurementController: NSObject, ObservableObject {
    @Published var measurementResult: Double?
    @Published var isMeasuring = false
    @Published var measurementType: MeasurementType = .chairHeight
    @Published var errorMessage: String?
    @Published var measurementState: MeasurementState = .notStarted
    
    enum MeasurementState {
        case notStarted
        case waitingForEndPoint
    }
    
    private var arView: ARView?
    private var startAnchor: ARAnchor?
    private var endAnchor: ARAnchor?
    
    func startMeasurement(type: MeasurementType) {
        measurementType = type
        measurementResult = nil
        errorMessage = nil
        isMeasuring = true
        measurementState = .notStarted
    }
    
    func setupARView(_ arView: ARView) {
        self.arView = arView
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Start AR session
        arView.session.run(configuration)
    }
    
    func handleTap(at point: CGPoint) {
        guard let arView = arView else { return }
        
        let raycastQuery = arView.makeRaycastQuery(from: point, 
                                                  allowing: .estimatedPlane, 
                                                  alignment: .any)
        
        guard let query = raycastQuery else {
            errorMessage = "Unable to create raycast query"
            return
        }
        
        guard let result = arView.session.raycast(query).first else {
            errorMessage = "No raycast results"
            return
        }
        
        if startAnchor == nil {
            // First point - start of measurement
            let anchor = ARAnchor(transform: result.worldTransform)
            arView.session.add(anchor: anchor)
            startAnchor = anchor
            measurementState = .waitingForEndPoint
        } else {
            // Second point - end of measurement
            let anchor = ARAnchor(transform: result.worldTransform)
            arView.session.add(anchor: anchor)
            endAnchor = anchor
            
            // Calculate distance
            if let startAnchor = startAnchor, let endAnchor = endAnchor {
                let startPosition = simd_make_float3(startAnchor.transform.columns.3.x,
                                                    startAnchor.transform.columns.3.y,
                                                    startAnchor.transform.columns.3.z)
                
                let endPosition = simd_make_float3(endAnchor.transform.columns.3.x,
                                                  endAnchor.transform.columns.3.y,
                                                  endAnchor.transform.columns.3.z)
                
                // For height measurement, we really only care about the y-axis difference
                let height = abs(endPosition.y - startPosition.y)
                measurementResult = Double(height * 100) // Convert to centimeters
                
                // Reset anchors for new measurement
                resetAnchors()
            }
        }
    }
    
    func resetAnchors() {
        if let arView = arView {
            if let startAnchor = startAnchor {
                arView.session.remove(anchor: startAnchor)
            }
            if let endAnchor = endAnchor {
                arView.session.remove(anchor: endAnchor)
            }
        }
        
        startAnchor = nil
        endAnchor = nil
        measurementState = .notStarted
    }
    
    func stopMeasurement() {
        resetAnchors()
        isMeasuring = false
    }
} 
