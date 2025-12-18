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
            CameraOverlayView(camera: camera, selectedTag: $selectedTag, dismiss: dismiss)
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
    let camera: CameraModel
    @State private var orientation: UIDeviceOrientation = .portrait
    @State private var previewSize: CGSize = UIScreen.main.bounds.size
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
                .rotationEffect(rotationAngle, anchor: .center)
            
            if let ghostImage = camera.ghostImage {
                Image(uiImage: ghostImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: previewSize.width, height: previewSize.height)
                    .opacity(camera.ghostOpacity)
                    .ignoresSafeArea()
            }
            
            Color.black.opacity(0.3)
                .ignoresSafeArea()
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
    let camera: CameraModel
    @Binding var selectedTag: String?
    let dismiss: DismissAction
    
    var body: some View {
        VStack {
            TopToolbarView(camera: camera, dismiss: dismiss)
            TagSelectorView(selectedTag: $selectedTag)
            Spacer()
            BottomControlView(camera: camera)
        }
    }
}

// 顶部工具栏视图
private struct TopToolbarView: View {
    let camera: CameraModel
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
            Image(systemName: camera.ghostImage == nil ? "square.on.square" : "square.on.square.fill")
                .font(.title2)
                .foregroundColor(camera.ghostImage == nil ? .white : .yellow)
                .padding()
        }
        .popover(isPresented: $showingSettings) {
             VStack(spacing: 16) {
                Text("虚影设置")
                    .font(.headline)
                    .padding(.top)
                
                HStack(spacing: 20) {
                    Button(action: { showingImagePicker = true }) {
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title)
                            Text("选择照片")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if camera.ghostImage != nil {
                        Button(action: { camera.ghostImage = nil }) {
                            VStack {
                                Image(systemName: "trash")
                                    .font(.title)
                                    .foregroundColor(.red)
                                Text("清除虚影")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                if camera.ghostImage != nil {
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
            .frame(width: 250)
        }
        .sheet(isPresented: $showingImagePicker) {
            GhostPicker(image: $camera.ghostImage)
        }
    }
}

import PhotosUI

struct GhostPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

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

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    self?.parent.image = image as? UIImage
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
    let camera: CameraModel
    
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
    @Published var ghostOpacity: Double = 0.3
    
    override init() {
        super.init()
        // 从 UserDefaults 读取保存的设置
        delaySeconds = UserDefaults.standard.integer(forKey: "cameraDelaySeconds")
        isFrontCamera = UserDefaults.standard.bool(forKey: "cameraIsFront")
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


