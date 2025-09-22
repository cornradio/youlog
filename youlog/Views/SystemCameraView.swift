//
//  SystemCameraView.swift
//  youlog
//
//  Created by kasusa on 2025/9/21.
//


import SwiftUI
import SwiftData
import PhotosUI
import Photos
import AVKit
import AVFoundation
import PhotosUI
import SwiftUI

struct SystemCameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageDataSelected: (Data?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SystemCameraView
        
        init(_ parent: SystemCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                let settings = CompressionSettings.shared
                var finalImage = image
                
                // 如果开启了自动压缩，则进行压缩处理
                if settings.autoCompressSystemCamera {
                    finalImage = compressImage(image) ?? image
                }
                
                if let imageData = finalImage.jpegData(compressionQuality: 0.8) {
                    parent.onImageDataSelected(imageData)
                } else {
                    parent.onImageDataSelected(nil)
                }
            } else {
                parent.onImageDataSelected(nil)
            }
            parent.dismiss()
        }
        
        private func compressImage(_ image: UIImage) -> UIImage? {
            let settings = CompressionSettings.shared
            let targetWidth: CGFloat = settings.targetWidth
            let compressionQuality: CGFloat = settings.compressionQuality
            
            let originalSize = image.size
            
            var newSize: CGSize
            if originalSize.width > targetWidth {
                let ratio = targetWidth / originalSize.width
                newSize = CGSize(
                    width: targetWidth,
                    height: originalSize.height * ratio
                )
            } else {
                newSize = originalSize
            }
            
            // 使用 UIGraphicsImageRenderer 替代旧的方法
            let format = UIGraphicsImageRendererFormat()
            format.opaque = true
            format.scale = image.scale
            
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            let resizedImage = renderer.image { context in
                // 填充黑色背景
                UIColor.black.setFill()
                context.fill(CGRect(origin: .zero, size: newSize))
                
                // 设置高质量插值
                context.cgContext.interpolationQuality = .high
                
                // 绘制图片
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            // 应用质量压缩
            guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality),
                  let compressedImage = UIImage(data: compressedData) else {
                return nil
            }
            
            // 裁切右边和下面1px
            guard let cgImage = compressedImage.cgImage else { return compressedImage }
            
            let cropRect = CGRect(
                x: 0,
                y: 0,
                width: max(1, cgImage.width - 1),
                height: max(1, cgImage.height - 1)
            )
            
            if let croppedCGImage = cgImage.cropping(to: cropRect) {
                return UIImage(cgImage: croppedCGImage, scale: compressedImage.scale, orientation: compressedImage.imageOrientation)
            }
            
            return compressedImage
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}