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
        .alert("相机权限", isPresented: $camera.alert) {
            Button("去设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("请在设置中允许访问相机")
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
            return .degrees(180)
        case .landscapeLeft:
            return .degrees(-90)
        case .landscapeRight:
            return .degrees(90)
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
                            .background(Color.blue)
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
        }
        .confirmationDialog("选择延迟时间", isPresented: $showingDelayPicker) {
            ForEach([0, 3, 5, 10,15], id: \.self) { seconds in
                Button("\(seconds)秒") {
                    camera.delaySeconds = seconds
                }
            }
            Button("取消", role: .cancel) {}
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
                        isSelected: selectedTag == nil ? tag == "全部" : selectedTag == tag,
                        action: {
                            selectedTag = tag == "全部" ? nil : tag
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
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            DispatchQueue.main.async {
                self.image = UIImage(data: imageData)
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
                .background(isSelected ? Color.blue : Color.white.opacity(0.3))
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


