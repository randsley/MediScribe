//
//  UIImage+RGB.swift
//  MediScribe
//
//  Converts UIImage to RGB bitmap data for mtmd
//

import UIKit
import CoreGraphics

extension UIImage {
    /// Converts the image to RGB24 bitmap data suitable for mtmd
    /// Returns (width, height, rgbData) tuple, or nil on failure
    func toRGBData() -> (width: Int, height: Int, data: Data)? {
        guard let cgImage = self.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 3
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        // Allocate buffer for RGB data
        var rgbData = Data(count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)

        guard let context = CGContext(
            data: &rgbData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        // Draw image into context (this converts to RGB)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (width: width, height: height, data: rgbData)
    }

    /// Resizes image to target size while maintaining aspect ratio
    /// Useful for preparing images for model input
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Determine scale factor to maintain aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)

        // Calculate new size
        let newWidth  = size.width  * scaleFactor
        let newHeight = size.height * scaleFactor

        let newSize = CGSize(width: newWidth, height: newHeight)

        // Create new image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
