import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    var measurementController: ARMeasurementController
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Check AR capabilities before setup
        if ARConfiguration.checkARCapabilities() {
            ARConfiguration.setupARView(arView)
            measurementController.setupARView(arView)
            
            // Add tap gesture recognizer
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, 
                                                   action: #selector(Coordinator.handleTap(_:)))
            arView.addGestureRecognizer(tapGesture)
        } else {
            DispatchQueue.main.async {
                errorMessage = "AR功能不可用或相机权限未授予"
                showError = true
            }
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            if let arView = recognizer.view as? ARView {
                let tapLocation = recognizer.location(in: arView)
                parent.measurementController.handleTap(at: tapLocation)
            }
        }
    }
}

struct ARMeasurementView: View {
    @ObservedObject var measurementController: ARMeasurementController
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageSettings: LanguageSettings
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            ARViewContainer(measurementController: measurementController,
                          showError: $showError,
                          errorMessage: $errorMessage)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        measurementController.stopMeasurement()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 20) {
                    if let errorMessage = measurementController.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.8)))
                    }
                    
                    if let measurement = measurementController.measurementResult {
                        Text("\("measurement_result".localized(using: languageSettings)): \(String(format: "%.1f", measurement)) cm")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                    } else {
                        let instructionText = measurementController.measurementState == .notStarted ?
                            "tap_to_start_measurement".localized(using: languageSettings) :
                            "tap_to_end_measurement".localized(using: languageSettings)
                        
                        Text(instructionText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                    }
                    
                    if let measurement = measurementController.measurementResult {
                        HStack(spacing: 20) {
                            Button(action: {
                                // Reset measurement for a new one
                                measurementController.resetAnchors()
                                measurementController.measurementResult = nil
                            }) {
                                Text("measure_again".localized(using: languageSettings))
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                // Use the measurement and return to main view
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("use_measurement".localized(using: languageSettings))
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.green))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("错误"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
} 