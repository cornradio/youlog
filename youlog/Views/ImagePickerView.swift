//
//  ImagePickerView.swift
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

struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    let onImagesSelected: ([(Data, String?)]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 0 // 0 means no limit (multi-selection)
        config.selection = .ordered
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss picker immediately
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else { return }
            
            var processedImages: [(Data, String?)] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                
                let assetId = result.assetIdentifier
                
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let image = image as? UIImage {
                            let settings = CompressionSettings.shared
                            let data: Data?
                            
                            if settings.autoCompressAlbumImport {
                                data = settings.compressImage(image)
                            } else {
                                // 如果没开启自动压缩，也建议进行轻度处理以减小体积，或者由用户决定
                                // 这里维持之前的逻辑或使用较高质量
                                data = image.jpegData(compressionQuality: 0.9)
                            }
                            
                            if let data = data {
                                DispatchQueue.main.async {
                                    processedImages.append((data, assetId))
                                }
                            }
                        }
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onImagesSelected(processedImages)
            }
        }
    }
}