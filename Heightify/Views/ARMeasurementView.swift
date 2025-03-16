import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    var measurementController: ARMeasurementController
    @Binding var showError: Bool
    @Binding var errorMessage: String
    var languageSettings: LanguageSettings
    
    func makeUIView(context: Context) -> ARView {
        #if os(visionOS)
        let arView = ARView(frame: .zero)
        DispatchQueue.main.async {
            errorMessage = "ar_not_available_visionpro".localized(using: languageSettings)
            showError = true
        }
        return arView
        #else
        let arView = ARView(frame: .zero)
        
        // Check AR capabilities before setup
        if ARConfiguration.checkARCapabilities() {
            ARConfiguration.setupARView(arView)
            measurementController.setupARView(arView)
            
            // Add tap gesture recognizer
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, 
                                                   action: #selector(Coordinator.handleTap(_:)))
            arView.addGestureRecognizer(tapGesture)
            
            // Add scene update handler for iOS < 18 to handle label orientation updates
            if #available(iOS 18.0, *) {
                // 使用内置BillboardComponent，无需额外处理
            } else {
                // 添加场景更新处理器，确保文本标签始终朝向相机
                arView.scene.subscribe(to: SceneEvents.Update.self) { event in
                    context.coordinator.updateLabelsOrientation(arView: arView)
                }
            }
        } else {
            DispatchQueue.main.async {
                errorMessage = "ar_not_available".localized(using: languageSettings)
                showError = true
            }
        }
        
        return arView
        #endif
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
            #if !os(visionOS)
            if let arView = recognizer.view as? ARView {
                let tapLocation = recognizer.location(in: arView)
                parent.measurementController.handleTap(at: tapLocation)
            }
            #endif
        }
        
        func updateLabelsOrientation(arView: ARView) {
            #if !os(visionOS)
            // 获取相机位置
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
            let cameraPosition = simd_make_float3(cameraTransform.columns.3.x,
                                               cameraTransform.columns.3.y,
                                               cameraTransform.columns.3.z)
            
            // 更新距离标签朝向
            if let distanceLabel = parent.measurementController.getDistanceLabel() {
                // 获取标签位置
                let labelPosition = distanceLabel.position(relativeTo: nil)
                
                // 计算方向向量
                let direction = normalize(labelPosition - cameraPosition)
                
                // 创建一个朝向相机的变换
                let forward = SIMD3<Float>(0, 0, -1)
                let targetDirection = -direction
                
                // 计算旋转轴和角度
                let dotProduct = simd_dot(forward, targetDirection)
                let angle = acos(min(max(dotProduct, -1.0), 1.0))
                
                if angle > 0.001 { // 避免非常小的角度导致问题
                    let rotationAxis = normalize(simd_cross(forward, targetDirection))
                    distanceLabel.orientation = simd_quatf(angle: angle, axis: rotationAxis)
                }
            }
            #endif
        }
    }
}

struct ARMeasurementView: View {
    @ObservedObject var measurementController: ARMeasurementController
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageSettings: LanguageSettings
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showGuide = true
    
    var body: some View {
        ZStack {
            ARViewContainer(measurementController: measurementController,
                          showError: $showError,
                          errorMessage: $errorMessage,
                          languageSettings: languageSettings)
                .edgesIgnoringSafeArea(.all)
            
            // 顶部控制区域
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
                    
                    // 显示/隐藏指南按钮
                    Button(action: {
                        showGuide.toggle()
                    }) {
                        Image(systemName: showGuide ? "info.circle.fill" : "info.circle")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding(.trailing)
                }
                .padding(.top, 40)
                
                // 如果显示指南，添加指导信息
                if showGuide {
                    measurementGuideView
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // 测量控制和结果区域
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
                        // 添加调整模式按钮和状态提示
                        if measurementController.isAdjusting {
                            Text("adjustment_guide".localized(using: languageSettings))
                                .foregroundColor(.yellow)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.7)))
                                .padding(.bottom, 8)
                        }
                        
                        // 按钮行
                        HStack(spacing: 20) {
                            Button(action: {
                                measurementController.toggleAdjustmentMode()
                            }) {
                                HStack {
                                    Image(systemName: measurementController.isAdjusting ? "slider.horizontal.below.rectangle" : "slider.horizontal.3")
                                    Text(measurementController.isAdjusting ? "finish_adjustment".localized(using: languageSettings) : "adjust_measurement".localized(using: languageSettings))
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8).fill(measurementController.isAdjusting ? Color.yellow : Color.orange))
                                .foregroundColor(.white)
                            }
                            
                            if !measurementController.isAdjusting {
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
                }
                .padding(.bottom, 50)
            }
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("error_title".localized(using: languageSettings)),
                message: Text(errorMessage),
                dismissButton: .default(Text("ok_button".localized(using: languageSettings))) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            // 进入页面5秒后隐藏指南
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showGuide = false
                }
            }
        }
    }
    
    // 测量指南视图
    private var measurementGuideView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ar_guide_title".localized(using: languageSettings))
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "1.circle.fill")
                    .foregroundColor(.green)
                Text("ar_guide_step1".localized(using: languageSettings))
                    .foregroundColor(.white)
            }
            
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "2.circle.fill")
                    .foregroundColor(.red)
                Text("ar_guide_step2".localized(using: languageSettings))
                    .foregroundColor(.white)
            }
            
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "3.circle.fill")
                    .foregroundColor(.blue)
                Text("ar_guide_step3".localized(using: languageSettings))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.7)))
    }
} 