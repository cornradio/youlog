import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = CameraModel()
    @Binding var selectedTag: String?
    
    var body: some View {
        ZStack {
            // 相机预览
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            // 半透明遮罩
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                // 顶部工具栏
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
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
                
                // 标签选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AppConstants.availableTags, id: \.self) { tag in
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
                
                Spacer()
                
                // 底部控制栏
                VStack(spacing: 20) {
                    // 拍摄按钮
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

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var image: UIImage?
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var isFlashOn = false
    
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
            
            // 默认使用后置摄像头
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
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
        
        // 切换相机位置
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
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


