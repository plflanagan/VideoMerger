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

//        let assetOrigin = CGPoint(x: view.center.x - view.frame.width) * 2.1, y: view.center.y * 3.67)
        let assetOrigin = CGPoint(
            x: view.frame.origin.x * ratioSize.width,
            y: view.frame.origin.y * ratioSize.height
        )

        print("view.frame: \(view.frame)")
        print("natural: \(assetTrack.naturalSize)")
        print("assetOrigin: \(assetOrigin)")
        print("assetSize: \(assetSize)")

        print("New Frame: (\(assetOrigin.x), \(assetOrigin.y), \(assetTrack.naturalSize.width * assetSize.width), \(assetTrack.naturalSize.height * assetSize.height))\n")

        // correct position:
//        var transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        var transform = CGAffineTransform(scaleX: assetSize.width, y: assetSize.height)
        transform = transform.translatedBy(x: assetOrigin.x, y: assetOrigin.y)
        transform = transform.scaledBy(x: 1 / assetSize.width, y: 1 / assetSize.height)


//        var transform = CGAffineTransform(scaleX: assetSize.width, y: assetSize.height)
//        var transform = CGAffineTransform(translationX: 1500, y: 1700)
//        var transform = CGAffineTransform(translationX: assetOrigin.x, y: assetOrigin.y)
//        var transform = CGAffineTransform(rotationAngle: 1.0)

//        transform = transform.translatedBy(x: 500, y: 300)
//        transform = transform.translatedBy(x: assetOrigin.x, y: assetOrigin.y)
//        transform = transform.rotated(by: 1.0)
//        transform = transform.scaledBy(x: assetSize.width, y: assetSize.height)


        transform = transform.rotated(by: atan2(view.transform.b, view.transform.a))
//        transform = transform.scaledBy(x: assetSize.width, y: assetSize.height)

        instruction.setTransform(transform, at: .zero) //move.concatenating(scale).concatenating(t)
    }
}

class ViewController: UIViewController {

    let videoView = UIView()
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pathUrl = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4") else {
            assertionFailure()
            return
        }

        view.addSubview(videoView)
        videoView.frame = CGRect(x: 16, y: 32, width: 380, height: 748) //affects video sizing/positioning...

        let image = UIImage(named: "image")
        imageView.image = image
        videoView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 500).isActive = true
        imageView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: 200).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: image!.size.width / 3).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: image!.size.height / 3).isActive = true

//        print(imageView.frame)
//        var transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
//        var transform = CGAffineTransform(translationX: 150, y: 0)
//        var transform = CGAffineTransform(rotationAngle: 1.0)

//        transform = transform.scaledBy(x: 1.3, y: 1.3)
//        transform = transform.rotated(by: 1.0)
//        transform = transform.translatedBy(x: 150, y: 0)


//        imageView.transform = transform
//        print(imageView.frame)

//        let firstAsset = AVAsset(url: pathUrl)
//        let firstAvView = PlayerViewFactory.makePlayerView(with: firstAsset)
//        videoView.addSubview(firstAvView)
//        firstAvView.translatesAutoresizingMaskIntoConstraints = false
//        firstAvView.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 500).isActive = true
//        firstAvView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: 0).isActive = true
//        firstAvView.widthAnchor.constraint(equalToConstant: 1280.0 / 2).isActive = true
//        firstAvView.heightAnchor.constraint(equalToConstant: 720 / 2).isActive = true
//        let firstRotate = CGAffineTransform(rotationAngle: -20)
//        firstAvView.transform = firstRotate
//        print("transform: \(firstAvView.transform)")
//
//
//        let secondAsset = AVAsset(url: pathUrl)
//        let secondAvView = PlayerViewFactory.makePlayerView(with: secondAsset)
//        videoView.addSubview(secondAvView)
//        secondAvView.translatesAutoresizingMaskIntoConstraints = false
//        secondAvView.topAnchor.constraint(equalTo: videoView.topAnchor).isActive = true
//        secondAvView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: image!.size.width / 4).isActive = true
//        secondAvView.widthAnchor.constraint(equalToConstant: 1280.0 / 2).isActive = true
//        secondAvView.heightAnchor.constraint(equalToConstant: 720.0 / 2).isActive = true
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

        DispatchQueue.main.async {
            self.composer = VideoComposer(view: self.videoView)
            self.composer?.createVideo() { exporter in
                self.didFinish(session: exporter)
            }
        }
    }

    func didFinish(session: AVAssetExportSession) {
        guard let url = session.outputURL else {
            assertionFailure()
            return
        }
        self.showVideo(videoUrl: url)
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
