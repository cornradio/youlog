import SwiftUI
import AVFoundation

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var camera = CameraModel()
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: { camera.takePicture() }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 65, height: 65)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                    .padding(4)
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: { camera.switchCamera() }) {
                        Image(systemName: "camera.rotate")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
        .onChange(of: camera.image) { _, newImage in
            if let image = newImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                let newItem = Item(timestamp: Date(), imageData: imageData)
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
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
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