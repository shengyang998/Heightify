import Foundation
import ARKit
import RealityKit
import Combine
import SceneKit

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
    @Published var isAdjusting: Bool = false
    @Published var currentlyAdjusting: AdjustmentPoint = .none
    
    enum MeasurementState {
        case notStarted
        case waitingForEndPoint
        case completed
    }
    
    enum AdjustmentPoint {
        case none
        case start
        case end
    }
    
    private var arView: ARView?
    private var startAnchor: ARAnchor?
    private var endAnchor: ARAnchor?
    
    // 视觉元素
    private var startNode: Entity?
    private var endNode: Entity?
    private var measurementLine: Entity?
    private var distanceLabel: Entity?
    
    // 保存位置信息用于调整
    private var startPosition: SIMD3<Float>?
    private var endPosition: SIMD3<Float>?
    
    // 视觉元素颜色
    private let startColor = UIColor.systemGreen
    private let endColor = UIColor.systemRed
    private let lineColor = UIColor.systemBlue
    private let adjustingColor = UIColor.systemYellow
    
    func startMeasurement(type: MeasurementType) {
        #if os(visionOS)
        errorMessage = "ar_not_available_visionpro"
        return
        #else
        measurementType = type
        measurementResult = nil
        errorMessage = nil
        isMeasuring = true
        measurementState = .notStarted
        isAdjusting = false
        currentlyAdjusting = .none
        clearVisualElements()
        startPosition = nil
        endPosition = nil
        #endif
    }
    
    func setupARView(_ arView: ARView) {
        #if !os(visionOS)
        self.arView = arView
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Start AR session
        arView.session.run(configuration)
        #endif
    }
    
    func handleTap(at point: CGPoint) {
        #if !os(visionOS)
        guard let arView = arView else { return }
        
        // 如果正在调整模式，检查是否点击了球体标记
        if isAdjusting {
            if let hitEntity = performRaycast(from: point) {
                if hitEntity == startNode {
                    // 开始调整起点
                    currentlyAdjusting = .start
                    // 更新视觉反馈
                    updateMarkerColor(isStart: true, color: adjustingColor)
                    return
                } else if hitEntity == endNode {
                    // 开始调整终点
                    currentlyAdjusting = .end
                    // 更新视觉反馈
                    updateMarkerColor(isStart: false, color: adjustingColor)
                    return
                }
            }
            
            // 如果当前正在调整某个点，则将新的位置设为调整后的位置
            if currentlyAdjusting != .none {
                let raycastQuery = arView.makeRaycastQuery(from: point, 
                                                        allowing: .estimatedPlane, 
                                                        alignment: .any)
                
                guard let query = raycastQuery, let result = arView.session.raycast(query).first else {
                    return
                }
                
                let hitPosition = simd_make_float3(result.worldTransform.columns.3.x,
                                                result.worldTransform.columns.3.y,
                                                result.worldTransform.columns.3.z)
                
                if currentlyAdjusting == .start {
                    // 更新起点位置
                    updateStartPosition(to: hitPosition)
                } else if currentlyAdjusting == .end {
                    // 更新终点位置
                    updateEndPosition(to: hitPosition)
                }
                
                // 重置调整状态
                currentlyAdjusting = .none
                // 更新视觉反馈
                updateMarkerColor(isStart: true, color: startColor)
                updateMarkerColor(isStart: false, color: endColor)
                return
            }
            
            // 如果点击了空白区域，退出调整模式
            isAdjusting = false
            return
        }
        
        // 普通测量模式
        let raycastQuery = arView.makeRaycastQuery(from: point, 
                                                  allowing: .estimatedPlane, 
                                                  alignment: .any)
        
        guard let query = raycastQuery else {
            errorMessage = "ar_error_no_plane"
            return
        }
        
        guard let result = arView.session.raycast(query).first else {
            errorMessage = "ar_error_no_hit"
            return
        }
        
        // 获取点击位置的3D坐标
        let hitTransform = result.worldTransform
        let hitPosition = simd_make_float3(hitTransform.columns.3.x,
                                          hitTransform.columns.3.y,
                                          hitTransform.columns.3.z)
        
        if measurementState == .notStarted {
            // First point - start of measurement
            let anchor = ARAnchor(transform: result.worldTransform)
            arView.session.add(anchor: anchor)
            startAnchor = anchor
            
            // 保存起点位置
            startPosition = hitPosition
            
            // 添加起点可视化标记
            addVisualMarker(at: hitPosition, color: startColor, isStart: true)
            
            measurementState = .waitingForEndPoint
        } else if measurementState == .waitingForEndPoint {
            // Second point - end of measurement
            let anchor = ARAnchor(transform: result.worldTransform)
            arView.session.add(anchor: anchor)
            endAnchor = anchor
            
            // 保存终点位置
            endPosition = hitPosition
            
            // 添加终点可视化标记
            addVisualMarker(at: hitPosition, color: endColor, isStart: false)
            
            // Calculate distance
            if let startPosition = startPosition, let endPosition = endPosition {
                // For height measurement, we really only care about the y-axis difference
                let height = abs(endPosition.y - startPosition.y)
                measurementResult = Double(height * 100) // Convert to centimeters
                
                // 添加测量线和标签
                addMeasurementLine(from: startPosition, to: endPosition, distance: Double(height * 100))
                
                // 完成测量，设置状态为已完成
                measurementState = .completed
            }
        }
        #endif
    }
    
    // MARK: - 位置调整功能
    
    func toggleAdjustmentMode() {
        #if !os(visionOS)
        // 只有在测量完成后才能进入调整模式
        if measurementState == .completed {
            isAdjusting = !isAdjusting
            currentlyAdjusting = .none
        }
        #endif
    }
    
    private func performRaycast(from point: CGPoint) -> Entity? {
        #if !os(visionOS)
        guard let arView = arView else { return nil }
        
        // 使用ARKit的hitTest方法来获取点击的实体
        let hitResults = arView.hitTest(point, types: [.existingPlaneUsingExtent])
        
        for result in hitResults {
            // 通过hitTest后，我们需要再通过点击位置来识别是哪个实体
            // 这里需要使用自定义逻辑来确定是否点击到标记点
            
            // 获取点击位置的世界坐标
            let hitPosition = SCNVector3(result.worldTransform.columns.3.x,
                                         result.worldTransform.columns.3.y,
                                         result.worldTransform.columns.3.z)
            
            // 检查是否接近起点或终点
            if let startNode = startNode as? AnchorEntity {
                let startPosition = startNode.position(relativeTo: nil)
                let distance = simd_distance(SIMD3<Float>(hitPosition.x, hitPosition.y, hitPosition.z),
                                            startPosition)
                if distance < 0.05 { // 5cm的阈值
                    return startNode
                }
            }
            
            if let endNode = endNode as? AnchorEntity {
                let endPosition = endNode.position(relativeTo: nil)
                let distance = simd_distance(SIMD3<Float>(hitPosition.x, hitPosition.y, hitPosition.z),
                                           endPosition)
                if distance < 0.05 { // 5cm的阈值
                    return endNode
                }
            }
        }
        
        return nil
        #else
        return nil
        #endif
    }
    
    private func updateStartPosition(to position: SIMD3<Float>) {
        #if !os(visionOS)
        guard let endPosition = endPosition else { return }
        
        // 更新起点位置
        startPosition = position
        
        // 更新视觉元素
        updateMarkerPosition(isStart: true, position: position)
        
        // 重新计算距离和更新测量线
        let height = abs(endPosition.y - position.y)
        measurementResult = Double(height * 100) // 转换为厘米
        
        // 重新绘制测量线
        if let measurementLine = measurementLine {
            measurementLine.removeFromParent()
            self.measurementLine = nil
        }
        
        if let distanceLabel = distanceLabel {
            distanceLabel.removeFromParent()
            self.distanceLabel = nil
        }
        
        addMeasurementLine(from: position, to: endPosition, distance: Double(height * 100))
        #endif
    }
    
    private func updateEndPosition(to position: SIMD3<Float>) {
        #if !os(visionOS)
        guard let startPosition = startPosition else { return }
        
        // 更新终点位置
        endPosition = position
        
        // 更新视觉元素
        updateMarkerPosition(isStart: false, position: position)
        
        // 重新计算距离和更新测量线
        let height = abs(position.y - startPosition.y)
        measurementResult = Double(height * 100) // 转换为厘米
        
        // 重新绘制测量线
        if let measurementLine = measurementLine {
            measurementLine.removeFromParent()
            self.measurementLine = nil
        }
        
        if let distanceLabel = distanceLabel {
            distanceLabel.removeFromParent()
            self.distanceLabel = nil
        }
        
        addMeasurementLine(from: startPosition, to: position, distance: Double(height * 100))
        #endif
    }
    
    private func updateMarkerPosition(isStart: Bool, position: SIMD3<Float>) {
        #if !os(visionOS)
        guard let arView = arView else { return }
        
        // 移除现有标记
        if isStart {
            if let startNode = startNode {
                startNode.removeFromParent()
            }
            // 添加新标记
            addVisualMarker(at: position, color: isAdjusting && currentlyAdjusting == .start ? adjustingColor : startColor, isStart: true)
        } else {
            if let endNode = endNode {
                endNode.removeFromParent()
            }
            // 添加新标记
            addVisualMarker(at: position, color: isAdjusting && currentlyAdjusting == .end ? adjustingColor : endColor, isStart: false)
        }
        #endif
    }
    
    private func updateMarkerColor(isStart: Bool, color: UIColor) {
        #if !os(visionOS)
        if isStart, let startNode = startNode as? AnchorEntity,
           let sphereEntity = startNode.children.first as? ModelEntity {
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: true)
            sphereEntity.model?.materials = [material]
        } else if !isStart, let endNode = endNode as? AnchorEntity,
                  let sphereEntity = endNode.children.first as? ModelEntity {
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: true)
            sphereEntity.model?.materials = [material]
        }
        #endif
    }
    
    // MARK: - 视觉辅助功能
    
    private func addVisualMarker(at position: SIMD3<Float>, color: UIColor, isStart: Bool) {
        #if !os(visionOS)
        guard let arView = arView else { return }
        
        // 创建球体标记
        let meshResource = MeshResource.generateSphere(radius: 0.01)
        let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: true)
        let sphereEntity = ModelEntity(mesh: meshResource, materials: [material])
        
        // 创建锚点
        let anchorEntity = AnchorEntity(world: position)
        anchorEntity.addChild(sphereEntity)
        
        // 添加到场景
        arView.scene.addAnchor(anchorEntity)
        
        // 存储引用
        if isStart {
            self.startNode = anchorEntity
        } else {
            self.endNode = anchorEntity
        }
        #endif
    }
    
    private func addMeasurementLine(from start: SIMD3<Float>, to end: SIMD3<Float>, distance: Double) {
        #if !os(visionOS)
        guard let arView = arView else { return }
        
        // 如果是高度测量，创建垂直线
        let lineStart: SIMD3<Float>
        let lineEnd: SIMD3<Float>
        
        if measurementType == .chairHeight || measurementType == .tableHeight {
            // 垂直测量线 - 保持x和z相同，只变化y
            lineStart = start
            lineEnd = SIMD3<Float>(start.x, end.y, start.z)
        } else {
            // 普通测量线 - 直接连接两点
            lineStart = start
            lineEnd = end
        }
        
        // 计算线的中点 - 用于放置标签
        let midPoint = SIMD3<Float>(
            (lineStart.x + lineEnd.x) / 2,
            (lineStart.y + lineEnd.y) / 2,
            (lineStart.z + lineEnd.z) / 2
        )
        
        // 创建线实体
        let lineEntity = createLineEntity(from: lineStart, to: lineEnd, color: lineColor)
        
        // 创建标签显示距离
        let labelEntity = createDistanceLabel(at: midPoint, distance: distance)
        
        // 创建锚点并添加线和标签
        let anchorEntity = AnchorEntity(world: lineStart)
        anchorEntity.addChild(lineEntity)
        
        // 添加标签锚点
        let labelAnchor = AnchorEntity(world: midPoint)
        labelAnchor.addChild(labelEntity)
        
        // 添加到场景
        arView.scene.addAnchor(anchorEntity)
        arView.scene.addAnchor(labelAnchor)
        
        // 存储引用
        self.measurementLine = anchorEntity
        self.distanceLabel = labelAnchor
        #endif
    }
    
    private func createLineEntity(from start: SIMD3<Float>, to end: SIMD3<Float>, color: UIColor) -> Entity {
        #if !os(visionOS)
        // 计算线段长度
        let distance = simd_distance(start, end)
        
        // 创建线段宽度
        let lineThickness: Float = 0.002
        
        // 创建线段实体 (兼容旧版iOS)
        let lineEntity: ModelEntity
        
        if #available(iOS 18.0, *) {
            let cylinder = MeshResource.generateCylinder(height: distance, radius: lineThickness)
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            lineEntity = ModelEntity(mesh: cylinder, materials: [material])
        } else {
            // 使用盒子替代圆柱体
            let box = MeshResource.generateBox(size: [lineThickness, distance, lineThickness])
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            lineEntity = ModelEntity(mesh: box, materials: [material])
        }
        
        // 定位线段
        // 1. 移动到起点
        lineEntity.position = SIMD3<Float>(0, distance / 2, 0)
        
        // 2. 计算旋转 - 让圆柱体指向终点
        let directionVector = normalize(end - start)
        let defaultDirection = SIMD3<Float>(0, 1, 0) // 默认圆柱体方向是y轴向上
        
        // 使用四元数旋转 (修正参数格式)
        let angle = acos(simd_dot(defaultDirection, directionVector))
        if angle > 0.001 {  // 避免非常小的角度导致问题
            let rotationAxis = normalize(simd_cross(defaultDirection, directionVector))
            lineEntity.orientation = simd_quatf(angle: angle, axis: rotationAxis)
        }
        
        // 创建父实体
        let parentEntity = Entity()
        parentEntity.addChild(lineEntity)
        return parentEntity
        #else
        return Entity()
        #endif
    }
    
    private func createDistanceLabel(at position: SIMD3<Float>, distance: Double) -> Entity {
        #if !os(visionOS)
        // 创建文本资源
        let formattedDistance = String(format: "%.1f cm", distance)
        let textMesh = MeshResource.generateText(
            formattedDistance,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.05),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        // 创建白色材质
        let material = SimpleMaterial(color: .white, roughness: 0, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        
        // 添加黑色背景板增加可读性
        let textSize = textEntity.visualBounds(relativeTo: textEntity).extents
        let backgroundMesh = MeshResource.generatePlane(
            width: textSize.x + 0.02,
            height: textSize.y + 0.02
        )
        let backgroundMaterial = SimpleMaterial(color: UIColor.black.withAlphaComponent(0.6), roughness: 0, isMetallic: false)
        let backgroundEntity = ModelEntity(mesh: backgroundMesh, materials: [backgroundMaterial])
        
        // 放置背景在文本后面
        backgroundEntity.position = SIMD3<Float>(0, 0, -0.001)
        
        // 设置旋转，使标签始终面向相机
        textEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
        
        // 创建父实体
        let labelEntity = Entity()
        labelEntity.addChild(backgroundEntity)
        labelEntity.addChild(textEntity)
        
        // 设置视图锚点，让标签始终面向相机 (兼容旧版iOS)
        if #available(iOS 18.0, *) {
            labelEntity.components.set(BillboardComponent())
        } else {
            // 为旧版本iOS添加手动方向更新逻辑
            // 这里我们依靠ARView的每帧更新来保持文本朝向相机
            // (需要在ARViewContainer中添加更新逻辑)
        }
        
        return labelEntity
        #else
        return Entity()
        #endif
    }
    
    private func clearVisualElements() {
        #if !os(visionOS)
        // 移除所有视觉元素
        if let startNode = startNode {
            startNode.removeFromParent()
            self.startNode = nil
        }
        
        if let endNode = endNode {
            endNode.removeFromParent()
            self.endNode = nil
        }
        
        if let measurementLine = measurementLine {
            measurementLine.removeFromParent()
            self.measurementLine = nil
        }
        
        if let distanceLabel = distanceLabel {
            distanceLabel.removeFromParent()
            self.distanceLabel = nil
        }
        #endif
    }
    
    func resetAnchors() {
        #if !os(visionOS)
        if let arView = arView {
            if let startAnchor = startAnchor {
                arView.session.remove(anchor: startAnchor)
            }
            if let endAnchor = endAnchor {
                arView.session.remove(anchor: endAnchor)
            }
        }
        
        clearVisualElements()
        startAnchor = nil
        endAnchor = nil
        startPosition = nil
        endPosition = nil
        measurementState = .notStarted
        isAdjusting = false
        currentlyAdjusting = .none
        #endif
    }
    
    func stopMeasurement() {
        #if !os(visionOS)
        resetAnchors()
        isMeasuring = false
        #endif
    }
    
    // 添加公共方法，用于获取距离标签进行手动更新
    func getDistanceLabel() -> Entity? {
        return distanceLabel
    }
} 
