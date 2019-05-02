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

class ViewController: UIViewController {

    let videoView = UIView()
    let imageView = UIImageView()
    var firstAvView: AVPlayerView?
    var composer: VideoComposer?
    let firstArea = UIView()
    let secondArea = UIView()


    override func viewDidLoad() {
        super.viewDidLoad()

        guard let pathUrl = Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4") else {
            assertionFailure()
            return
        }

        view.addSubview(videoView) // (14 30; 347 752)
        videoView.frame = CGRect(x: 16, y: 32, width: 380, height: 748)//CGRect(x: 16, y: 32, width: 380, height: 748) // 380 748 //affects video sizing/positioning...
        videoView.backgroundColor = .white

        firstArea.backgroundColor = .red
        firstArea.layer.masksToBounds = true
        videoView.addSubview(firstArea)
        firstArea.translatesAutoresizingMaskIntoConstraints = false
        firstArea.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 40).isActive = true
        firstArea.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: 30).isActive = true
        firstArea.widthAnchor.constraint(equalToConstant: videoView.frame.width / 4 * 3).isActive = true
        firstArea.heightAnchor.constraint(equalToConstant: videoView.frame.width / 4 * 3).isActive = true

        secondArea.backgroundColor = .orange
        secondArea.layer.masksToBounds = true
        videoView.addSubview(secondArea)
        secondArea.translatesAutoresizingMaskIntoConstraints = false
        secondArea.topAnchor.constraint(equalTo: firstArea.bottomAnchor, constant: 100).isActive = true
        secondArea.leadingAnchor.constraint(equalTo: firstArea.leadingAnchor).isActive = true
        secondArea.widthAnchor.constraint(equalTo: firstArea.widthAnchor).isActive = true
        secondArea.heightAnchor.constraint(equalTo: firstArea.widthAnchor).isActive = true


        let image = UIImage(named: "image")
        imageView.image = image
        imageView.layer.masksToBounds = true
        firstArea.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: firstArea.topAnchor, constant: 10).isActive = true
        imageView.leadingAnchor.constraint(equalTo: firstArea.leadingAnchor, constant: 10).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: image!.size.width / 3).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: image!.size.height / 3).isActive = true


        let firstAsset = AVAsset(url: pathUrl)
        firstAvView = PlayerViewFactory.makePlayerView(with: firstAsset)
        guard let firstAvView = firstAvView else {
            return
        }
        firstAvView.layer.masksToBounds = true
        secondArea.addSubview(firstAvView)
        firstAvView.translatesAutoresizingMaskIntoConstraints = false
        firstAvView.topAnchor.constraint(equalTo: secondArea.topAnchor, constant: -100).isActive = true
        firstAvView.leadingAnchor.constraint(equalTo: secondArea.leadingAnchor, constant: -100).isActive = true
        firstAvView.widthAnchor.constraint(equalToConstant: 1280.0 / 3).isActive = true
        firstAvView.heightAnchor.constraint(equalToConstant: 720 / 3).isActive = true
        let firstRotate = CGAffineTransform(rotationAngle: -20)
        firstAvView.transform = firstRotate

//        let secondAsset = AVAsset(url: pathUrl)
//        let secondAvView = PlayerViewFactory.makePlayerView(with: secondAsset)
//        videoView.addSubview(secondAvView)
//        videoView.sendSubviewToBack(secondA)
//        secondAvView.translatesAutoresizingMaskIntoConstraints = false
//        secondAvView.topAnchor.constraint(equalTo: videoView.topAnchor, constant: 200).isActive = true
//        secondAvView.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: image!.size.width / -3).isActive = true
//        secondAvView.widthAnchor.constraint(equalToConstant: 1280.0 / 2).isActive = true
//        secondAvView.heightAnchor.constraint(equalToConstant: 720.0 / 2).isActive = true
//        let secondRotate = CGAffineTransform(rotationAngle: 50)
//        secondAvView.transform = secondRotate
//
//        let videoViewImage = videoView.asImage()

//        let otherImage = UIImage(named: "Frame-2.png")
//        let imageView2 = UIImageView(image: otherImage)
//        videoView.addSubview(imageView2)
//        imageView2.translatesAutoresizingMaskIntoConstraints = false
//        imageView2.topAnchor.constraint(equalTo: videoView.topAnchor).isActive = true
//        imageView2.leadingAnchor.constraint(equalTo: videoView.leadingAnchor).isActive = true
//        imageView2.widthAnchor.constraint(equalToConstant: videoView.frame.width).isActive = true
//        imageView2.heightAnchor.constraint(equalToConstant: videoView.frame.height).isActive = true


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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

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
