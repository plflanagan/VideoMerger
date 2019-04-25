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
import Photos

private func filePath() -> URL {
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

class VideoComposer {
    let composition = AVMutableComposition()
    let mainInstruction = AVMutableVideoCompositionInstruction()
    let duration: CMTime
    let videoSize: CGSize

    // use this to increase the quality of the video
    var viewSizeMultiplier: CGFloat = 5.0

    init(view: UIView) {

        // this determines the quality of the video
//        videoSize = CGSize(width: view.frame.width * viewSizeMultiplier, height: view.frame.height * viewSizeMultiplier)
        videoSize = CGSize(width: 1772.0, height: 3840.0)
        viewSizeMultiplier = 1772.0 / view.frame.width

        print("view: \(videoSize.width / viewSizeMultiplier) - \(videoSize.height / viewSizeMultiplier)")
        print("video: \(videoSize)")
        print("multiplier: \(viewSizeMultiplier)\n")

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
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
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
        print("video")
        setTransform(on: videoLayerInstruction, of: avView, andOf: videoTrack)

        mainInstruction.layerInstructions.append(videoLayerInstruction)
    }

    private func addImage(of imageView: UIImageView) {
        guard let image = imageView.image else {
            assertionFailure("no image")
            return
        }

        let movieLength = TimeInterval(duration.seconds)

        let url = filePath().appendingPathComponent("output4.mov")

        ImageVideoCreator.writeSingleImageToMovie(image: image, movieLength: movieLength, outputFileURL: url) { [weak self] success in

            guard let `self` = self else {
                return
            }

            // TODO: This likely won't capture the video properly when file is created for first time.
            let imageAsset = AVAsset(url: url)

            let keys = ["playable", "readable", "composable", "tracks", "exportable"]
            var error: NSError? = nil

//            imageAsset.loadValuesAsynchronously(forKeys: keys, completionHandler: {
//                DispatchQueue.main.async {
//                    keys.forEach({ key in
//                        let status = imageAsset.statusOfValue(forKey: key, error: &error)
//                        switch status {
//                        case .loaded:
//                            print("loaded. \(error)")
//                        case .loading:
//                            print("loading. \(error)")
//                        case .failed:
//                            print("failed. \(error)")
//                        case .cancelled:
//                            print("cancelled. \(error)")
//                        case .unknown:
//                            print("unknown. \(error)")
//                        }
//                    })

                    guard
                        let imageTrack = self.composition.addMutableTrack(
                            withMediaType: .video,
                            preferredTrackID: kCMPersistentTrackID_Invalid),
                        let imageVideoTrack = imageAsset.tracks(withMediaType: .video).first
                        else {
                            assertionFailure()
                            return
                    }

                    try! imageTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: self.duration), of: imageVideoTrack, at: .zero)

                    let imageVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: imageTrack)

                    print("image")

                    self.setTransform(on: imageVideoLayerInstruction, of: imageView, andOf: imageVideoTrack)
                    self.mainInstruction.layerInstructions.append(imageVideoLayerInstruction)
                }
//            })
//        }
    }

    private func setTransform(on instruction: AVMutableVideoCompositionLayerInstruction, of view: UIView, andOf assetTrack: AVAssetTrack) {

        let parentSize = CGSize(
            width: videoSize.width / viewSizeMultiplier,
            height: videoSize.height / viewSizeMultiplier
        )

        let assetSize = CGSize(
            width: view.frame.width * viewSizeMultiplier / assetTrack.naturalSize.width,
            height: view.frame.height * viewSizeMultiplier / assetTrack.naturalSize.height
        )

        let ratioSize = CGSize(
            width: assetTrack.naturalSize.width / view.frame.width,
            height: assetTrack.naturalSize.height / view.frame.height
        )

        let assetOrigin = CGPoint(
            x: view.frame.origin.x * ratioSize.width,
            y: view.frame.origin.y * ratioSize.height
        )

        print("view.frame: \(view.frame)")
        print("natural: \(assetTrack.naturalSize)")
        print("assetOrigin: \(assetOrigin)")
        print("assetSize: \(assetSize)")

        print("New Frame: (\(assetOrigin.x), \(assetOrigin.y), \(assetTrack.naturalSize.width * assetSize.width), \(assetTrack.naturalSize.height * assetSize.height))\n")

        let move = CGAffineTransform(
            translationX: assetOrigin.x,
            y: assetOrigin.y
        )
        let scale = CGAffineTransform(
            scaleX: assetSize.width,
            y: assetSize.height
        )

        instruction.setTransform(move.concatenating(scale).concatenating(view.transform), at: .zero)
    }
}

class ViewController: UIViewController {

    let videoView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pathUrl = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4") else {
            assertionFailure()
            return
        }

        //(14 30; 347 752)
        view.addSubview(videoView)
//        view.translatesAutoresizingMaskIntoConstraints = false
        videoView.frame = CGRect(x: 14, y: 30, width: 347, height: 752)

        let image = UIImage(named: "image")
        let imageView = UIImageView(image: image)
        videoView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 0).isActive = true
        imageView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: 0).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: image!.size.width / 4).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: image!.size.height / 4).isActive = true



        let firstAsset = AVAsset(url: pathUrl)
        let firstAvView = PlayerViewFactory.makePlayerView(with: firstAsset)
        videoView.addSubview(firstAvView)
        firstAvView.translatesAutoresizingMaskIntoConstraints = false
        firstAvView.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 100).isActive = true
        firstAvView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: 50).isActive = true
        firstAvView.widthAnchor.constraint(equalToConstant: 1280.0 / 2).isActive = true
        firstAvView.heightAnchor.constraint(equalToConstant: 720 / 2).isActive = true
//        let firstRotate = CGAffineTransform(rotationAngle: -20)
//        firstAvView.transform = firstRotate



        let secondAsset = AVAsset(url: pathUrl)
        let secondAvView = PlayerViewFactory.makePlayerView(with: secondAsset)
        videoView.addSubview(secondAvView)
        secondAvView.translatesAutoresizingMaskIntoConstraints = false
        secondAvView.topAnchor.constraint(equalTo: videoView.topAnchor).isActive = true
        secondAvView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: image!.size.width / 4).isActive = true
        secondAvView.widthAnchor.constraint(equalToConstant: 1280.0 / 2).isActive = true
        secondAvView.heightAnchor.constraint(equalToConstant: 720.0 / 2).isActive = true
//        let secondRotate = CGAffineTransform(rotationAngle: 50)
//        secondAvView.transform = secondRotate



//        let thirdAsset = AVAsset(url: pathUrl)
//        let thirdAvView = PlayerViewFactory.makePlayerView(with: thirdAsset)
//        view.addSubview(thirdAvView)
//        thirdAvView.translatesAutoresizingMaskIntoConstraints = false
//        thirdAvView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
//        thirdAvView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        thirdAvView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2).isActive = true
//        thirdAvView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2).isActive = true
//        let thirdRotate = CGAffineTransform(rotationAngle: 20)
//        thirdAvView.transform = thirdRotate
    }

    var composer: VideoComposer?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        composer = VideoComposer(view: videoView)

        composer?.createVideo() { exporter in
            self.didFinish(session: exporter)
        }
    }

    func didFinish(session: AVAssetExportSession) {
        guard let url = session.outputURL else {
            assertionFailure()
            return
        }
        self.saveVideo(videoUrl: url)
    }

    let player = AVPlayerViewController()

    func showVideo(videoUrl: URL) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            let videoPlayer = AVPlayer(url: videoUrl)
            self.player.player = videoPlayer

            self.present(self.player, animated: true) {
                self.player.player?.play()
            }
        }
    }

    private func saveVideo(videoUrl: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
            print("exported")
        })
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
