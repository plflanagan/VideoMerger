//
//  VideoComposer.swift
//  VideoMerger
//
//  Created by Patrick Flanagan on 5/1/19.
//  Copyright © 2019 ORG_NAME. All rights reserved.
//

import UIKit
import AVFoundation

class VideoComposer {
    let composition = AVMutableComposition()
    let mainInstruction = AVMutableVideoCompositionInstruction()
    let duration: CMTime
    let videoSize: CGSize
    let viewMaskingImage: UIImage

    // use this to increase the quality of the video
    var viewSizeMultiplier: CGFloat = 5.0

    init(view: UIView) {

        viewMaskingImage = VideoComposer.getMaskingImage(of: view)

        // this determines the quality of the video
        //        videoSize = CGSize(width: view.frame.width * viewSizeMultiplier, height: view.frame.height * viewSizeMultiplier)

        videoSize = CGSize(width: 1772.0, height: 3840.0)
        viewSizeMultiplier = 1772.0 / view.frame.width

        print("view: \(videoSize.width / viewSizeMultiplier) - \(videoSize.height / viewSizeMultiplier)")
        print("video: \(videoSize)")
        print("multiplier: \(viewSizeMultiplier)\n")

        var minDuration: CMTime = CMTime(seconds: 15, preferredTimescale: 600)
        view.subviews.forEach { subview in
            subview.subviews.forEach({ subSubview in
                if let avView = subSubview as? AVPlayerView, let duration = avView.videoPlayer.currentItem?.duration {
                    minDuration = min(minDuration, duration)  // todo: video duration not being retrieved...
                }
            })
        }
        self.duration = minDuration
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: minDuration)

        // add all videos
        view.subviews.forEach { [weak self] subview in
            guard let `self` = self else {
                assertionFailure("unexpected")
                return
            }
            subview.subviews.reversed().forEach { subSubview in
                if let avView = subSubview as? AVPlayerView {
                    self.addVideo(of: avView)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.addImage(of: view)
        }
    }

    private static func getMaskingImage(of view: UIView) -> UIImage {
        let maskLayer = CALayer()
        maskLayer.frame = view.frame

        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)//view.frame

        let finalPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))//view.frame)

        // TODO: change to use canvasPositionView
//        view.subviews.forEach { subview in
            let path = UIBezierPath(rect: view.subviews[0].frame)
            finalPath.append(path.reversing())
//        }

        shapeLayer.path = finalPath.cgPath
        shapeLayer.borderColor = UIColor.white.withAlphaComponent(1).cgColor
        shapeLayer.borderWidth = 1
        maskLayer.addSublayer(shapeLayer)

        view.layer.mask = maskLayer

        let maskingImage = view.asImage()!

        view.layer.mask = nil

        return maskingImage
    }

    func createVideo(completion: @escaping (AVAssetExportSession) -> Void) {

        // make video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 60)
        videoComposition.renderSize = videoSize

        let frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)

        let imageLayer = CALayer()
        imageLayer.contents = viewMaskingImage.cgImage!
        imageLayer.frame = frame

        let parentLayer = CALayer()
        parentLayer.frame = frame

        let videoLayer = CALayer()
        videoLayer.frame = frame

        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(imageLayer)

        let otherLayer = CALayer()
        otherLayer.frame = frame

//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)


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

    private func addImage(of view: UIView) {
        guard let image = view.asImage() else {
            assertionFailure("no image")
            return
        }
//        let image = VideoComposer.getMaskingImage(of: view)

        let movieLength = TimeInterval(duration.seconds)

        let url = filePath().appendingPathComponent("image.description.mov")

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

            DispatchQueue.main.async {
                self.setTransform(on: imageVideoLayerInstruction, of: view, andOf: imageVideoTrack)
                self.mainInstruction.layerInstructions.append(imageVideoLayerInstruction)
            }
        }
        //            })
        //        }
    }

    private func setTransform(on instruction: AVMutableVideoCompositionLayerInstruction, of view: UIView, andOf assetTrack: AVAssetTrack) {

        let assetScaler = CGPoint(
            x: view.originalFrame.width * viewSizeMultiplier / assetTrack.naturalSize.width,
            y: view.originalFrame.height * viewSizeMultiplier / assetTrack.naturalSize.height
        )

        let ratioSize = CGSize(
            width: assetTrack.naturalSize.width / view.originalFrame.width,
            height: assetTrack.naturalSize.height / view.originalFrame.height
        )

        let topLeftPoint: CGPoint
        if let parentView = view.superview {
            topLeftPoint = parentView.convert(view.newTopLeft, to: nil)
        }
        else {
            topLeftPoint = CGPoint(x: view.newTopLeft.x, y: view.newTopLeft.y)
        }
        let assetOrigin = CGPoint(
            x: (topLeftPoint.x + 2) * ratioSize.width * assetScaler.x,
            y: (topLeftPoint.y + 38) * ratioSize.height * assetScaler.y
        )

        print("view.frame: \(view.originalFrame)")
        print("natural: \(assetTrack.naturalSize)")
        print("assetOrigin: \(assetOrigin)")
        print("assetSize: \(assetScaler)")
        print("New Frame: (\(assetOrigin.x), \(assetOrigin.y), \(assetTrack.naturalSize.width * assetScaler.x), \(assetTrack.naturalSize.height * assetScaler.y))\n")

        var transform = CGAffineTransform(translationX: assetOrigin.x, y: assetOrigin.y)

        transform = transform.rotated(by: atan2(view.transform.b, view.transform.a))
        transform = transform.scaledBy(x: assetScaler.x, y: assetScaler.y)

        instruction.setTransform(transform, at: .zero)
    }
}
