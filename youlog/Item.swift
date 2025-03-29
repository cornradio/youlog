//
//  Item.swift
//  youlog
//
//  Created by kasusa on 2025/3/28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var imageData: Data?
    var note: String?
    var location: LocationData?
    
    init(timestamp: Date, imageData: Data? = nil, note: String? = nil, location: LocationData? = nil) {
        self.timestamp = timestamp
        self.imageData = imageData
        self.note = note
        self.location = location
    }
}

struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var heading: Double
}
