//
//  ViewController.swift
//  VideoMerger
//
//  Created by Patrick Flanagan on 4/19/19.
//  Copyright © 2019 ORG_NAME. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class VideoComposer {
    let composition = AVMutableComposition()

    // make main video instruction
    let mainInstruction = AVMutableVideoCompositionInstruction()

    func overlapVideos(avAsset: AVAsset, completion: @escaping (AVAssetExportSession) -> Void) {

        // timeframe will match first video for this example
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: avAsset.duration)

        add(avAsset: avAsset)


//        guard let secondTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            assertionFailure()
//            return
//        }
//        try! secondTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: secondAsset.duration), of: secondAsset.tracks(withMediaType: .video)[0], at: .zero)
//
//        // add layer instruction for second video
//        let secondVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
//        let secondMove = CGAffineTransform(translationX: -500, y: -500)
//        let secondScale = CGAffineTransform(scaleX: 0.2, y: 0.2)
//
//        secondVideoLayerInstruction.setTransform(secondMove.concatenating(secondScale), at: .zero)
//
//        mainInstruction.layerInstructions.append(secondVideoLayerInstruction)
//
//
//        // make third video track and add to composition
//        let thirdAsset = AVAsset(url: pathUrl)
//
//        guard let thirdTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            assertionFailure()
//            return
//        }
//        try! thirdTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: thirdAsset.duration), of: thirdAsset.tracks(withMediaType: .video)[0], at: .zero)
//
//        // add layer instruction for third video
//        let thirdVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: thirdTrack)
//        let thirdMove = CGAffineTransform(translationX: 1000, y: 0)
//        let thirdScale = CGAffineTransform(scaleX: 0.2, y: 0.2)
//        let thirdRotate = CGAffineTransform(rotationAngle: 20)
//
//        thirdVideoLayerInstruction.setTransform(thirdMove.concatenating(thirdScale).concatenating(thirdRotate), at: .zero)
//
//        mainInstruction.layerInstructions.append(thirdVideoLayerInstruction)
//
//
//        // add image layer
//        let image = UIImage(named: "image")!
//
//        let movieLength = TimeInterval(firstAsset.duration.seconds)
//        let searchPaths1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentDirectory1 = searchPaths1[0]
//        let filePath1 = documentDirectory1.appending("output1.mov")
//        let outputUrl1 = URL(fileURLWithPath: filePath1)
//
//
//
//        ImageVideoCreator.writeSingleImageToMovie(image: image, movieLength: movieLength, outputFileURL: outputUrl1) { success in
//            print("success: \(success)")
//
//            // make first video track and add to composition
//            let imageAsset = AVAsset(url: outputUrl1)
//
//            guard let imageTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//                assertionFailure()
//                return
//            }
//            try! imageTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: firstAsset.duration), of: imageAsset.tracks(withMediaType: .video)[0], at: .zero)
//
//            // add layer instruction for first video
//            let imageVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: imageTrack)
//
//            // size = 486 widh 154
//            // full size = CGSize(width: 640, height: 480)?
//
//            let imageScale = CGAffineTransform(scaleX: 640 / 486, y: 486 / 154)
//
//            imageVideoLayerInstruction.setTransform(imageScale, at: .zero)
//
//            mainInstruction.layerInstructions.append(imageVideoLayerInstruction)
//
//        }



        // make video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 640, height: 480)


        // export
        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = searchPaths[0]
        let filePath = documentDirectory.appending("output.mov")
        let outputUrl = URL(fileURLWithPath: filePath)

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: filePath) {
            try! fileManager.removeItem(at: outputUrl)
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            assertionFailure()
            return
        }
        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mov
        exporter.outputURL = outputUrl

        exporter.exportAsynchronously {
            DispatchQueue.main.async { //[weak self] in
//                let endTime = DispatchTime.now()
//                print("time required: \((endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000 )s")
                completion(exporter)
            }
        }
    }

    private func add(avAsset: AVAsset) {

        guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            assertionFailure()
            return
        }
        try! track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: avAsset.duration), of: avAsset.tracks(withMediaType: .video)[0], at: .zero)

        // add layer instruction for first video
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let move = CGAffineTransform(translationX: 1000, y: 400)
        let scale = CGAffineTransform(scaleX: 0.2, y: 0.2)

        videoLayerInstruction.setTransform(move.concatenating(scale), at: .zero)

        mainInstruction.layerInstructions.append(videoLayerInstruction)
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pathUrl = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4") else {
            assertionFailure()
            return
        }

        // make second video track and add to composition
        let asset = AVAsset(url: pathUrl)

        VideoComposer().overlapVideos(avAsset: asset) { [weak self] exporter in
            self?.didFinish(session: exporter)
        }
    }

    func didFinish(session: AVAssetExportSession) {
        guard let url = session.outputURL else {
            assertionFailure()
            return
        }
        showVideo(videoUrl: url)
    }

    let player = AVPlayerViewController()

    func showVideo(videoUrl: URL) {

        let videoPlayer = AVPlayer(url: videoUrl)
        player.player = videoPlayer

        self.present(player, animated: true) {
            self.player.player?.play()
        }
    }

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
        do {
            let imageSize = image.size
            let videoWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mov)
            let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264,
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
            let halfMovieLength = Float64(movieLength/2.0) // videoWriter assumes frame lengths are equal.
            let startFrameTime = CMTimeMake(value: 0, timescale: timeScale)
            let endFrameTime = CMTimeMakeWithSeconds(halfMovieLength, preferredTimescale: timeScale)
            videoWriter.startSession(atSourceTime: startFrameTime)

            guard let cgImage = image.cgImage else {
                completion(false)
                return
            }
            let buffer: CVPixelBuffer = self.pixelBuffer(fromImage: cgImage, size: imageSize)!
            while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
            adaptor.append(buffer, withPresentationTime: startFrameTime)
            while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
            adaptor.append(buffer, withPresentationTime: endFrameTime)

            videoWriterInput.markAsFinished()
            videoWriter.finishWriting {
                // videoWriter.error
                completion(true)
            }
        } catch {
            completion(false)
        }
    }
}

