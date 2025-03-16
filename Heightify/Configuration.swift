import Foundation
import ARKit
import RealityKit

class ARConfiguration {
    static func checkARCapabilities() -> Bool {
        // Check if AR is supported on this device
        if !ARWorldTrackingConfiguration.isSupported {
            print("AR World Tracking is not supported on this device")
            return false
        }
        
        // Check camera authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            var isAuthorized = false
            let semaphore = DispatchSemaphore(value: 0)
            
            AVCaptureDevice.requestAccess(for: .video) { granted in
                isAuthorized = granted
                semaphore.signal()
            }
            
            _ = semaphore.wait(timeout: .now() + 1.0)
            return isAuthorized
        case .denied, .restricted:
            print("Camera access is denied or restricted")
            return false
        @unknown default:
            return false
        }
    }
    
    static func setupARView(_ arView: ARView) {
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        
        // Enable people occlusion if supported
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        // Start AR session with configuration
        arView.session.run(config)
        
        // Setup debug options for development
        #if DEBUG
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        #endif
    }
} 