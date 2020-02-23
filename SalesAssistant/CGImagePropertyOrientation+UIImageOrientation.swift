//
//  CGImagePropertyOrientation+UIImageOrientation.swift
//  SalesAssistant
//
//  Created by Douglas Maltby on 2/23/20.
//  Copyright © 2020 SAP. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
