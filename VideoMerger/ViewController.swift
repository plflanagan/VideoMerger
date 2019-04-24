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
    let mainInstruction = AVMutableVideoCompositionInstruction()
    let duration: CMTime
    let videoSize: CGSize

    init(view: UIView) {

        videoSize = view.frame.size

        var minDuration: CMTime = CMTime(seconds: 15, preferredTimescale: 600)
        view.subviews.forEach { subview in
            if let avView = subview as? AVPlayerView, let duration = avView.videoPlayer.currentItem?.duration {
                minDuration = min(minDuration, duration)
            }
        }
        self.duration = minDuration
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: minDuration)

        view.subviews.reversed().forEach { subview in
            if let avView = subview as? AVPlayerView {
                addVideo(of: avView)

            }
            else if let imageView = subview as? UIImageView {
                addImage(of: imageView)
            }
            else {
                print("unhandled view type")
            }
        }
    }

    func createVideo(completion: @escaping (AVAssetExportSession) -> Void) {

        // make video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = videoSize

        export(videoComposition: videoComposition) { (session) in
            completion(session)
        }
    }

    private func export(videoComposition: AVMutableVideoComposition, completion: @escaping (AVAssetExportSession) -> Void) {
        // export
        let url = filePath().appendingPathComponent("output.mov")

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: url.path) {
            try! fileManager.removeItem(at: url)
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            assertionFailure()
            return
        }
        exporter.videoComposition = videoComposition
        exporter.outputFileType = .mov
        exporter.outputURL = url

        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                completion(exporter)
            }
        }
    }

    private func addVideo(of avView: AVPlayerView) {
        guard
            let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let asset = avView.videoPlayer.currentItem?.asset,
            let videoTrack = asset.tracks(withMediaType: .video).first
            else {
                assertionFailure()
                return
        }
        try! track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)

        // add layer instruction for first video
        let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)

        videoLayerInstruction.setTransform(avView.transform, at: .zero)

        mainInstruction.layerInstructions.append(videoLayerInstruction)
    }

    private func filePath() -> URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            fatalError("documentDir Error")
        }

        return documentDirectory
    }

    private func addImage(of imageView: UIImageView) {
        guard let image = imageView.image else {
            assertionFailure("no image")
            return
        }

        let movieLength = TimeInterval(duration.seconds)

        let url = filePath().appendingPathComponent("output1.mov")
//        let searchPaths1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentDirectory1 = searchPaths1[0]
//        let filePath1 = documentDirectory1.appending("output1.mov")
//        let outputUrl1 = URL(fileURLWithPath: filePath1)

        ImageVideoCreator.writeSingleImageToMovie(image: image, movieLength: movieLength, outputFileURL: url) { [weak self] success in
            print("success: \(success)")
            guard let `self` = self else {
                return
            }

            let imageAsset = AVAsset(url: url)

            guard let imageTrack = self.composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                assertionFailure()
                return
            }
            try! imageTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.duration), of: imageAsset.tracks(withMediaType: .video)[0], at: .zero)

            let imageVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: imageTrack)
            imageVideoLayerInstruction.setTransform(imageView.transform, at: .zero)

            self.mainInstruction.layerInstructions.append(imageVideoLayerInstruction)
        }
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pathUrl = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4") else {
            assertionFailure()
            return
        }

        let image = UIImage(named: "image")
        let imageView = UIImageView(image: image)
        view.addSubview(imageView)
        // size = 486 widh 154
        // full size = CGSize(width: 640, height: 480)?
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 486).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 154).isActive = true

        

        let firstAsset = AVAsset(url: pathUrl)
        let firstAvView = PlayerViewFactory.makePlayerView(with: firstAsset)
        view.addSubview(firstAvView)
        firstAvView.translatesAutoresizingMaskIntoConstraints = false
        firstAvView.topAnchor.constraint(equalTo: view.topAnchor, constant: 300).isActive = true
        firstAvView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        firstAvView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
        firstAvView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8).isActive = true

        let firstRotate = CGAffineTransform(rotationAngle: -20)
        let firstScale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        firstAvView.transform = firstRotate.concatenating(firstScale)



        let secondAsset = AVAsset(url: pathUrl)
        let secondAvView = PlayerViewFactory.makePlayerView(with: secondAsset)
        view.addSubview(secondAvView)
        secondAvView.translatesAutoresizingMaskIntoConstraints = false
        secondAvView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        secondAvView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        secondAvView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 100).isActive = true
        secondAvView.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 100).isActive = true

        let secondRotate = CGAffineTransform(rotationAngle: 50)
        let secondScale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        secondAvView.transform = secondRotate.concatenating(secondScale)



        let thirdAsset = AVAsset(url: pathUrl)
        let thirdAvView = PlayerViewFactory.makePlayerView(with: thirdAsset)
        view.addSubview(thirdAvView)
        thirdAvView.translatesAutoresizingMaskIntoConstraints = false
        thirdAvView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        thirdAvView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        thirdAvView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        thirdAvView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        let thirdMove = CGAffineTransform(translationX: 1000, y: 0)
        let thirdScale = CGAffineTransform(scaleX: 0.2, y: 0.2)
        let thirdRotate = CGAffineTransform(rotationAngle: 20)
        thirdAvView.transform = thirdMove.concatenating(thirdScale).concatenating(thirdRotate)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let composer = VideoComposer(view: view)

        composer.createVideo() { [weak self] exporter in
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

