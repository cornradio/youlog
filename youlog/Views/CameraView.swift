import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = CameraModel()
    @Binding var selectedTag: String?
    
    var body: some View {
        ZStack {
            CameraPreviewView(camera: camera)
            VStack {
                CameraOverlayView(camera: camera, selectedTag: $selectedTag, dismiss: dismiss)
                    // .padding(.top, 40) // Ensure it's below the notch/dynamic island
                Spacer()
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
        .onChange(of: camera.image) { _, newImage in
            if let image = newImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                let newItem = Item(timestamp: Date(), imageData: imageData, tag: selectedTag)
                modelContext.insert(newItem)
                dismiss()
            }
        }
        .alert(NSLocalizedString("camera_permission", comment: ""), isPresented: $camera.alert) {
            Button(NSLocalizedString("go_to_settings", comment: "")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {
                dismiss()
            }
        } message: {
            Text(NSLocalizedString("please_allow_camera", comment: ""))
        }
    }
}

// 相机预览视图
private struct CameraPreviewView: View {
    @ObservedObject var camera: CameraModel
    @State private var orientation: UIDeviceOrientation = .portrait
    @State private var previewSize: CGSize = UIScreen.main.bounds.size
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
                .rotationEffect(rotationAngle, anchor: .center)
            
            if camera.isGhostEnabled, let ghostImage = camera.ghostImage {
                Image(uiImage: ghostImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: previewSize.width, height: previewSize.height)
                    .opacity(camera.ghostOpacity)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            orientation = UIDevice.current.orientation
            previewSize = UIScreen.main.bounds.size
        }
        .onRotate { newOrientation in
            orientation = newOrientation
           previewSize = UIScreen.main.bounds.size
        }
    }
    
    private var rotationAngle: Angle {
        switch orientation {
        case .portrait:
            return .degrees(0)
        case .portraitUpsideDown:
            return .degrees(0)
        case .landscapeLeft:
            return .degrees(0)
        case .landscapeRight:
            return .degrees(0)
        default:
            return .degrees(0)
        }
    }
}

// 相机覆盖视图
private struct CameraOverlayView: View {
    @ObservedObject var camera: CameraModel
    @Binding var selectedTag: String?
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 0) {
            TopToolbarView(camera: camera, dismiss: dismiss)
            TagSelectorView(selectedTag: $selectedTag)
            Spacer()
            BottomControlView(camera: camera)
        }
    }
}

// 顶部工具栏视图
private struct TopToolbarView: View {
    @ObservedObject var camera: CameraModel
    let dismiss: DismissAction
    @State private var showingDelayPicker = false
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            
            Button(action: { showingDelayPicker = true }) {
                HStack {
                    Image(systemName: "timer")
                    if camera.isCountingDown {
                        Text("\(camera.countdownNumber)")
                            .foregroundColor(.white)
                            .background(AppConstants.themeManager.currentTheme.color)
                            .cornerRadius(10)
                            .padding(.horizontal, 10)
                    } else {
                        Text(camera.delaySeconds > 0 ? "\(camera.delaySeconds)s" : "")
                    }
                }
                .font(.title2)
                .foregroundColor(.white)
                .padding()
            }
            
            Spacer()
            
            Button(action: { camera.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            
            Button(action: { camera.toggleFlash() }) {
                Image(systemName: camera.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
            
            GhostImageControlView(camera: camera)
        }
        .confirmationDialog(NSLocalizedString("select_delay", comment: ""), isPresented: $showingDelayPicker) {
            ForEach([0, 3, 5, 10, 15], id: \.self) { seconds in
                Button(String(format: NSLocalizedString("second", comment: ""), seconds)) {
                    camera.delaySeconds = seconds
                }
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
        }
    }
}

private struct GhostImageControlView: View {
    @ObservedObject var camera: CameraModel
    @State private var showingSettings = false
    @State private var showingImagePicker = false
    
    var body: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: camera.isGhostEnabled ? "square.on.square.fill" : "square.on.square")
                .font(.title2)
                .foregroundColor(camera.isGhostEnabled ? .yellow : .white)
                .padding()
        }
        .popover(isPresented: $showingSettings) {
             VStack(spacing: 16) {
                Text("虚影参考")
                    .font(.headline)
                    .padding(.top)
                
                 Toggle("开启虚影叠加", isOn: $camera.isGhostEnabled)
                     .tint(AppConstants.themeManager.currentTheme.color)
                     .padding(.horizontal)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("历史记录")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 新增按钮
                            Button(action: { showingImagePicker = true }) {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                    Text("添加")
                                        .font(.caption2)
                                }
                                .frame(width: 60, height: 60)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            ForEach(camera.ghostHistory, id: \.self) { fileName in
                                if let thumb = camera.getGhostThumbnail(fileName: fileName) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: thumb)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(camera.ghostImage != nil && camera.ghostHistory.firstIndex(of: fileName) == 0 ? Color.yellow : Color.clear, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                camera.selectGhost(fileName: fileName)
                                            }
                                        
                                        Button(action: {
                                            camera.removeGhostFromHistory(fileName: fileName)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                                .font(.caption)
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding(.horizontal)
                
                if camera.isGhostEnabled && camera.ghostImage != nil {
                    VStack(alignment: .leading) {
                        Text("透明度: \(Int(camera.ghostOpacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $camera.ghostOpacity, in: 0.1...0.9)
                            .tint(.blue)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .frame(width: 300)
        }
        .sheet(isPresented: $showingImagePicker) {
            GhostPicker(onImagePicked: { image in
                camera.addToHistory(image: image)
            })
        }
    }
}

import PhotosUI

struct GhostPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: GhostPicker

        init(_ parent: GhostPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    if let uiImage = image as? UIImage {
                        DispatchQueue.main.async {
                            self?.parent.onImagePicked(uiImage)
                        }
                    }
                }
            }
        }
    }
}

// 标签选择器视图
private struct TagSelectorView: View {
    @Binding var selectedTag: String?
    @StateObject private var tagManager = AppConstants.tagManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tagManager.availableTags, id: \.self) { tag in
                    TagButtonCam(
                        title: tag,
                        isSelected: selectedTag == nil ? tagManager.isAllTag(tag) : selectedTag == tag,
                        action: {
                            selectedTag = tagManager.isAllTag(tag) ? nil : tag
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// 底部控制视图
private struct BottomControlView: View {
    @ObservedObject var camera: CameraModel
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: { camera.takePicture() }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 75, height: 75)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 85, height: 85)
                }
            }
            .padding(.bottom, 30)
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var image: UIImage?
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var isFlashOn = false
    @Published var isPreviewPaused = false
    @Published var delaySeconds: Int = 0 {
        didSet {
            UserDefaults.standard.set(delaySeconds, forKey: "cameraDelaySeconds")
        }
    }
    @Published var isCountingDown = false
    @Published var countdownNumber: Int = 0
    @Published var isFrontCamera: Bool = false {
        didSet {
            UserDefaults.standard.set(isFrontCamera, forKey: "cameraIsFront")
        }
    }
    
    @Published var ghostImage: UIImage?
    @Published var ghostOpacity: Double = 0.3 {
        didSet {
            UserDefaults.standard.set(ghostOpacity, forKey: "cameraGhostOpacity")
        }
    }
    @Published var isGhostEnabled: Bool = false
    @Published var ghostHistory: [String] = [] // Filenames in Documents/ghosts/
    
    private let ghostsDir = "ghosts"
    
    override init() {
        super.init()
        // 创建 ghosts 目录内容
        ensureGhostsDirectory()
        
        // 从 UserDefaults 读取保存的设置
        delaySeconds = UserDefaults.standard.integer(forKey: "cameraDelaySeconds")
        isFrontCamera = UserDefaults.standard.bool(forKey: "cameraIsFront")
        
        let savedOpacity = UserDefaults.standard.double(forKey: "cameraGhostOpacity")
        if savedOpacity > 0 {
            ghostOpacity = savedOpacity
        }
        
        ghostHistory = UserDefaults.standard.stringArray(forKey: "cameraGhostHistory") ?? []
        
        // 默认不开启虚影，但如果有历史，可以点击开启
    }
    
    private func ensureGhostsDirectory() {
        let url = getGhostsDirectoryURL()
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    private func getGhostsDirectoryURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(ghostsDir)
    }
    
    func addToHistory(image: UIImage) {
        let fileName = "ghost_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(4)).jpg"
        let url = getGhostsDirectoryURL().appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.7) {
            try? data.write(to: url)
            
            // 加入历史并去重保持前 10 个
            var newHistory = ghostHistory
            newHistory.insert(fileName, at: 0)
            if newHistory.count > 10 {
                let toDelete = newHistory.removeLast()
                try? FileManager.default.removeItem(at: getGhostsDirectoryURL().appendingPathComponent(toDelete))
            }
            
            ghostHistory = newHistory
            UserDefaults.standard.set(ghostHistory, forKey: "cameraGhostHistory")
            
            selectGhost(fileName: fileName)
        }
    }
    
    func selectGhost(fileName: String) {
        let url = getGhostsDirectoryURL().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url) {
            ghostImage = UIImage(data: data)
            isGhostEnabled = true
        }
    }
    
    func removeGhostFromHistory(fileName: String) {
        let url = getGhostsDirectoryURL().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
        
        ghostHistory.removeAll { $0 == fileName }
        UserDefaults.standard.set(ghostHistory, forKey: "cameraGhostHistory")
        
        if ghostImage != nil && ghostHistory.isEmpty {
            ghostImage = nil
            isGhostEnabled = false
        }
    }
    
    func getGhostThumbnail(fileName: String) -> UIImage? {
        let url = getGhostsDirectoryURL().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                if status {
                    DispatchQueue.main.async {
                        self?.setUp()
                    }
                }
            }
        case .denied:
            DispatchQueue.main.async {
                self.alert = true
            }
            return
        default:
            return
        }
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            // 使用保存的摄像头方向
            let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            let input = try AVCaptureDeviceInput(device: device!)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            
            // 在后台线程启动会话
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func takePicture() {
        if delaySeconds > 0 {
            isCountingDown = true
            countdownNumber = delaySeconds
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if self.countdownNumber > 0 {
                    self.countdownNumber -= 1
                } else {
                    timer.invalidate()
                    self.isCountingDown = false
                    self.capturePhoto()
                }
            }
        } else {
            capturePhoto()
        }
    }
    
    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        // 暂停预览以显示拍摄效果
        DispatchQueue.main.async {
            self.isPreviewPaused = true
        }
        
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            DispatchQueue.main.async {
                self.image = UIImage(data: imageData)
                
                // 延迟恢复预览，让用户看到拍摄完成的效果
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isPreviewPaused = false
                }
            }
        }
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        // 移除现有输入
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)
        
        // 切换相机位置并更新状态
        isFrontCamera.toggle()
        let newPosition: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else { return }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            camera.preview.frame = uiView.frame
            
            // 根据暂停状态控制预览层的连接
            if camera.isPreviewPaused {
                camera.preview.connection?.isEnabled = false
            } else {
                camera.preview.connection?.isEnabled = true
            }
        }
    }
}

struct TagButtonCam: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppConstants.themeManager.currentTheme.color : Color.white.opacity(0.3))
                .foregroundColor(isSelected ? .white : .white)
                .cornerRadius(20)
        }
    }
}

// 添加屏幕旋转监听扩展
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}


