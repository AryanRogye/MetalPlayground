//
//  DominantColorExtractionGPU.swift
//  MetalTesting
//
//  Created by Aryan Rogye on 8/29/25.
//

import SwiftUI

extension CGImage {
    /// Checks if the CGImage has a 32-bit RGBA pixel format.
    var isRGBA8: Bool {
        // Ensure there are 8 bits per color component.
        guard self.bitsPerComponent == 8 else { return false }
        
        // Ensure there are 32 bits per pixel (R+G+B+A).
        guard self.bitsPerPixel == 32 else { return false }
        
        // Ensure the alpha info is not `none` or `noneSkipFirst`/`noneSkipLast`.
        let alphaInfo = self.alphaInfo
        guard alphaInfo == .premultipliedLast || alphaInfo == .last else { return false }
        
        // For big-endian systems, RGB is the natural order.
        // For little-endian systems, BGR is the natural order.
        // We must check the byte order of the bitmap info.
        let bitmapInfo = self.bitmapInfo
        
        // We're looking for an RGBA layout, which is alpha last and big-endian byte order.
        let byteOrderMask: CGBitmapInfo = .byteOrder32Big
        
        // Check for RGBA (AlphaLast, BigEndian) or ABGR (AlphaLast, LittleEndian)
        // Since we are looking for RGBA explicitly, we check for .byteOrder32Big
        return bitmapInfo.contains(byteOrderMask)
    }
}

/**
 
 0) Input → CGImage (and normalize it)
    From UIImage use .cgImage; from NSImage create a CGImage (lock in the exact pixels you’ll feed to GPU).
    Normalize:
        Orientation → upright
        Color space → sRGB (or at least consistent)
        Pixel layout → 8-bit RGBA/BGRA

 1) Downsample on CPU first
    Shrink the image to something like 256×256 with vImage/CoreImage. It cuts GPU work massively without hurting the result.
 
 2) Make Metal Texture
    Choose MTLPixelFormat.bgra8Unorm.
    Usage: .shaderRead (input).
    Storage: .storageModeShared on Apple Silicon (simple readback later).
    Load via MTKTextureLoader or makeTexture(desc) + replaceRegion.
 
 3)
 */

class DominantColorExtractionGPU {
    
    /// 2 Different Extraction Methods 1 From Mean and another From Mode
    enum extractionMethod {
        case mean
        case mode
    }
    
    static let defaultExtractionMethod: extractionMethod = .mean
    
    // MARK: - Apply Transform To CGImage
    /// Function Will Apply The Given Transform onto the CGImage and return it
    private static func applyTransform(_ transform: CGAffineTransform, to image: CGImage) -> CGImage? {
        // 1. Calculate the new dimensions of the image after the transform.
        let originalRect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let transformedRect = originalRect.applying(transform)
        let newSize = transformedRect.size
        
        // We need integer dimensions for the bitmap context.
        let newWidth = Int(ceil(newSize.width))
        let newHeight = Int(ceil(newSize.height))
        
        // Ensure we have a valid size.
        guard newWidth > 0, newHeight > 0 else {
            print("Error: Transformed image has zero or negative size.")
            return nil
        }
        
        // 2. Create a new bitmap graphics context.
        // This will be our canvas for the new image.
        guard let colorSpace = image.colorSpace,
              let context = CGContext(
                data: nil,
                width: newWidth,
                height: newHeight,
                bitsPerComponent: image.bitsPerComponent,
                bytesPerRow: 0, // 0 lets Core Graphics calculate the optimal value.
                space: colorSpace,
                bitmapInfo: image.bitmapInfo.rawValue
              ) else {
            print("Error: Could not create a CGContext.")
            return nil
        }
        
        // 3. Apply the transform to the context.
        // All subsequent drawing will be affected by this.
        // We also need to translate the context to ensure the transformed
        // image is drawn within the new bounds.
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.concatenate(transform)
        context.translateBy(x: -CGFloat(image.width) / 2, y: -CGFloat(image.height) / 2)
        
        
        // 4. Draw the original image into the transformed context.
        // The drawing rectangle is the original image's bounds.
        context.draw(image, in: originalRect)
        
        // 5. Create a new CGImage from the context's content.
        let transformedImage = context.makeImage()
        
        return transformedImage
    }
    
    // MARK: - Force Image SRGB8
    public static func forceCGImageToSRGB(image: CGImage) -> CGImage? {
        let srgbColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let width = image.width
        let height = image.height
        let bitsPerComponent = image.bitsPerComponent
        let bytesPerRow = image.bytesPerRow
        let bitmapInfo = image.bitmapInfo
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: srgbColorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
    
    // MARK: - Convert To RGBA8
    /// Converts a CGImage to an RGBA8 (32 bits per pixel) format.
    ///
    /// - Parameter cgImage: The original CGImage.
    /// - Returns: A new CGImage in RGBA8 format, or nil if conversion fails.
    public static func convertToRGBA8(cgImage: CGImage) -> CGImage? {
        let width = cgImage.width
        let height = cgImage.height
        
        // 1. Define the RGBA8 format properties.
        let bitsPerComponent = 8
        let bytesPerRow = width * 4 // Each pixel is 4 bytes (R, G, B, A).
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        // It's crucial to use a color space that supports alpha, like sRGB.
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            print("Error: Failed to create sRGB color space.")
            return nil
        }
        
        // 2. Create the bitmap context with the RGBA8 properties.
        // This context will be our canvas for the new image.
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("Error: Failed to create CGContext.")
            return nil
        }
        
        // 3. Draw the original image into the new context.
        // Core Graphics handles the conversion during this drawing operation.
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        // 4. Create a new CGImage from the context's data.
        return context.makeImage()
    }
    
#if os(macOS)
    public static func getDominantColor(from image: NSImage) -> NSColor? {
        return nil // for now
    }
#endif

    
    // MARK: - iOS Dominant Color
#if os(iOS)
    public static func getDominantColor(from image: UIImage) -> UIColor? {
        
        /// Step 0. Get CGImage
        guard var cgImage = image.cgImage else {
            print("Couldnt Convert Image To CGImage")
            return nil
        }
        
        /// Normalize Steps:
        /// Upright Checks
        var transform: CGAffineTransform?
        if image.imageOrientation != .up {
            print("CGImage is Not Upright, Need to Transform")
            transform = computeTransformUpright(image: image, cgImage: cgImage)
        }
        if let transform = transform {
            if let transformedCGImage = applyTransform(transform, to: cgImage) {
                print("Applied Transformed CGImage")
                cgImage = transformedCGImage
            }
        }
        
        /// Color Space should be sRGB
        let colorSpace = cgImage.colorSpace
        if colorSpace?.name != CGColorSpace.sRGB {
            if let sRGB_Image = forceCGImageToSRGB(image: cgImage) {
                cgImage = sRGB_Image
            } else {
                print("Couldnt Convert CGImage To sRGB")
                return nil
            }
        }
        
        /// Make Sure Image is RGBA8
        if !cgImage.isRGBA8 {
            /// We Need to make it a RGBA8
            if let rgba8_image = convertToRGBA8(cgImage: cgImage) {
                cgImage = rgba8_image
            } else {
                print("Couldnt Convert CGImage To RGBA8")
                return nil
            }
        }


        return nil
    }
    
    /// Function Will Compute The Transform required to make the image upright
    private static func computeTransformUpright(image: UIImage, cgImage: CGImage) -> CGAffineTransform {
        var transform = CGAffineTransform.identity
        let width = cgImage.width
        let height = cgImage.height
        
        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        return transform
    }
    
#endif
}
