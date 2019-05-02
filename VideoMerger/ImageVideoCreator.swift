//
//  ImageVideoCreator.swift
//  VideoMerger
//
//  Created by Patrick Flanagan on 4/26/19.
//  Copyright © 2019 ORG_NAME. All rights reserved.
//

import UIKit
import AVFoundation

func filePath() -> URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    guard let documentDirectory = urls.first else {
        fatalError("documentDir Error")
    }
    //        let searchPaths1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    //        let documentDirectory1 = searchPaths1[0]
    //        let filePath1 = documentDirectory1.appending("output1.mov")
    //        let outputUrl1 = URL(fileURLWithPath: filePath1)

    return documentDirectory
}

class ImageVideoCreator {

    private static func pixelBuffer(fromImage image: CGImage, size: CGSize) -> CVPixelBuffer? {
        let options: CFDictionary = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true] as CFDictionary
        var pxbuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options, &pxbuffer)

        guard let buffer = pxbuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        guard let pxdata = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        context.concatenate(CGAffineTransform(rotationAngle: 0))
        context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        CVPixelBufferUnlockBaseAddress(buffer, [])

        return buffer
    }


    static func writeSingleImageToMovie(image: UIImage, movieLength: TimeInterval, outputFileURL: URL, completion: @escaping (Bool) -> ()) {

//        let fileManager = FileManager.default
//
//        if fileManager.fileExists(atPath: outputFileURL.path) {
//            try! fileManager.removeItem(at: outputFileURL)
//        }

        do {
            let imageSize = image.size

            let videoWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mov)
            let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                                AVVideoWidthKey: imageSize.width,
                                                AVVideoHeightKey: imageSize.height]
            let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)

            if !videoWriter.canAdd(videoWriterInput) {
                completion(false)
                return
            }
            videoWriterInput.expectsMediaDataInRealTime = true
            videoWriter.add(videoWriterInput)

            videoWriter.startWriting()
            let timeScale: Int32 = 600 // recommended in CMTime for movies.
            let startFrameTime = CMTimeMake(value: 0, timescale: 600)
            let endFrameTime = CMTimeMakeWithSeconds(movieLength, preferredTimescale: timeScale)
            videoWriter.startSession(atSourceTime: startFrameTime)

            guard let cgImage = image.cgImage else {
                completion(false)
                return
            }
            let buffer: CVPixelBuffer = self.pixelBuffer(fromImage: cgImage, size: imageSize)!

            while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
            let first = adaptor.append(buffer, withPresentationTime: startFrameTime)
            while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
            let second = adaptor.append(buffer, withPresentationTime: endFrameTime)

            print("\(first) \(second)")

            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                completion(true)
            }
        } catch {
            completion(false)
        }
    }
}
